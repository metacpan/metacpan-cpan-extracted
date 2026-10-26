package Mojolicious::Plugin::Branding;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::File qw< path >;
use Carp qw< croak >;
use Scalar::Util qw< blessed >;

{ our $VERSION = '0.004' }

package Mojolicious::Plugin::Branding::IndividualBaseRole;
use Mojo::Base -role;
use Carp qw< croak >;
requires qw< paths _create_from >;
has '_brand_name';
has _spec_for => sub { return +{} };
has _cache_for => sub { return +{} };
has '_stash_key';

sub _add_brand {
   my ($self, $name, $spec) = @_;
   croak "invalid specification for brand '$name'"
      if defined($spec) && ref($spec) ne 'HASH';
   my $s4 = $self->_spec_for;
   delete($s4->{$name});
   $self->_spec_for->{$name} = $spec if defined($spec);
   delete($self->_cache_for->{$name});
   return $self;
}

sub _add_brands {
   my $self = shift;
   my %brands = @_ == 1 ? %{$_[0]} : @_;
   $self->_add_brand($_, $brands{$_}) for keys(%brands);
   return $self;
}

sub _item_for {
   my ($self, $c) = @_;

   # do not allow sub-items inside sub-item
   return if defined($self->_brand_name);

   # cope with missing/non-existing brands
   my $brand = $c->stash->{$self->_stash_key} // return;
   my $spec = $self->_spec_for->{$brand} or return;

   return unless @{$spec->{paths}} || $spec->{ignore_app_paths};
   return $self->_cache_for->{$brand} //= do {
      my @paths = @{$spec->{paths}};
      push @paths, @{$self->paths} unless $spec->{ignore_app_paths};
      $self->_create_from($brand, \@paths);
   };
}

package Mojolicious::Plugin::Branding::IndividualStaticRole;
use Mojo::Base -role;
with 'Mojolicious::Plugin::Branding::IndividualBaseRole';

around serve => sub {
   my ($orig, $self, $c, $path) = @_;
   my $static = $self->_item_for($c);
   return $static->serve($c, $path) if defined($static);
   return $self->$orig($c, $path);
};

sub _create_from {
   my ($self, $brand, $paths) = @_;

   return ref($self)->new(
      (
         map { $_ => $self->$_ } qw<
            asset_dir
            classes
            extra
            prefix
         >
      ),
      paths      => $paths,
      _brand_name => $brand,
   );
}

package Mojolicious::Plugin::Branding::IndividualRendererRole;
use Mojo::Base -role;
use Mojo::Cache;
with 'Mojolicious::Plugin::Branding::IndividualBaseRole';

around render => sub {
   my ($orig, $self, $c) = @_;
   my $renderer = $self->_item_for($c);
   return $renderer->render($c) if defined($renderer);
   return $self->$orig($c);
};

sub _create_from {
   my ($self, $brand, $paths) = @_;

   return ref($self)->new(
      (
         map { $_ => $self->$_ } qw<
            handlers
            helpers
            classes
            default_format
            default_handler
            encoding
         >
      ),
      paths      => $paths,
      _brand_name => $brand,

      # get a separate cache to avoid different brands to tread on
      # one another
      cache => ref($self->cache)->new(max_keys => $self->cache->max_keys),
   );
}

package Mojolicious::Plugin::Branding;

sub __values_from_constrained_hash {
   my $href = shift;
   my $msg = shift;
   my %hash = %$href;
   my @retval;
   for my $item (@_) {
      my ($key, $default) = @$item;
      push @retval, delete($hash{$key}) // $default;
   }
   croak "$msg: @{[ sort keys %hash ]}" if %hash;
   return @retval;
}

sub __isa {
   my ($target, $class) = @_;
   return blessed($target) && $target->isa($class);
}

sub _resolve_dir {
   my ($self, $home, $path, $msg) = @_;
   return unless defined($path);
   croak "invalid empty path ($msg)" unless length($path);
   croak "invalid path, either Mojo::File or plain string accepted ($msg)"
      if ref($path) && ! __isa($path, 'Mojo::File');
   my $candidate = path($path);
   $candidate = $home->child($path) unless $candidate->is_abs;
   return $candidate if -r $candidate && -d _;
   return;
}

sub _normalize_sub_spec {
   my ($self, $title, $key, $src, $home) = @_;
   $src //= {};
   $src = { paths => $src } if ref($src) ne 'HASH';
   my ($paths, $ignore) = __values_from_constrained_hash($src,
      "unknown keys in $key for $title",
      [ paths => []], [ignore_app_paths => 0]);
   $paths = [ $paths ] if ref($paths) ne 'ARRAY';
   return {
      ignore_app_paths => !!$ignore,
      paths => [ map { $self->_resolve_dir($home, $_, "$title, $key") } @$paths ],
   };
}

sub _normalize_brand_spec {
   my ($self, $title, $spec, $home) = @_;
   return undef unless defined($spec);
   $spec = [ $spec ]
      if (! ref($spec)) || __isa($spec, 'Mojo::File');
   $spec = { paths => $spec } if ref($spec) eq 'ARRAY';

   # here we demand that we have a hash reference
   croak "invalid specification for $title" if ref($spec) ne 'HASH';

   my ($common, $templates, $public) = __values_from_constrained_hash($spec,
      "unknown keys in $title",
      [paths => []], [templates => {}], [public => {}]);
   $templates = $self->_normalize_sub_spec($title, templates => $templates, $home);
   $public = $self->_normalize_sub_spec($title, public => $public, $home);

   my %spec = (
      templates => $templates,
      public => $public,
   );

   $common = [ $common ] if ref($common) ne 'ARRAY';
   for my $path ($common->@*) {
      my $upper = $self->_resolve_dir($home, $path, $title) // next;
      for my $key (qw< templates public >) {
         my $child = $self->_resolve_dir($upper, $key, "$title, $key") // next;
         push @{$spec{$key}{paths}}, $child;
      }
   }

   return \%spec;
}

sub _normalize_global {
   my ($self, $app, $conf) = @_;
   my $spec = $self->_normalize_brand_spec('global', $conf, $app->home) // return;
   croak 'ignore_app_paths not allowed in the global context'
      if $spec->{templates}{ignore_app_paths}
      || $spec->{public}{ignore_app_paths};
   return $spec;
}

sub _register_normalized_global {
   my ($self, $app, $spec) = @_;
   return unless defined($spec);
   unshift @{$app->renderer->paths}, @{$spec->{templates}{paths}};
   unshift @{$app->static->paths},   @{$spec->{public}{paths}};
   return;
}

sub _register_individual {
   my ($self, $app, $conf) = @_;

   return unless defined($conf);
   croak 'individual requires a hash reference or nothing/undef'
      if ref($conf) ne 'HASH';

   my ($brands, $key) = __values_from_constrained_hash($conf,
      'unknown keys in individual', [brands => {}], [stash_key => undef]);

   croak 'invalid brands in individual' if ref($brands) ne 'HASH';
   return unless defined($key) || scalar(keys(%$brands));

   my $home = $app->home;
   $brands = {
      map { $_ => $self->_normalize_brand_spec("brand '$_'", $brands->{$_}, $home) }
      keys(%$brands)
   };

   # an empty brand that ignores the application has no files at all,
   # probably its directories are missing on this installation
   for my $name (sort keys(%$brands)) {
      next unless defined($brands->{$name});
      for my $key (qw< templates public >) {
         my $spec = $brands->{$name}{$key};
         $app->log->warn(qq{Branding: brand "$name" has no $key }
               . 'directories and ignores the application ones')
            if $spec->{ignore_app_paths} && ! @{$spec->{paths}};
      }
   }

   # this will be needed later, but we're going to make sure that the
   # role is only composed once and this is also useful here to check that
   # the stash_key is only set once or always to the same value.
   my $static = $app->static;
   my $static_role = 'Mojolicious::Plugin::Branding::IndividualStaticRole';

   if (Role::Tiny::does_role($static, $static_role)) {
      my $registered_key = $static->_stash_key;
      $key //= $registered_key;
      croak "stash_key '$key' conflicts with '$registered_key', set previously"
         if $key ne $registered_key;
   }
   else { # first time here
      $static->with_roles($static_role);

      $key //= 'branding.brand';
      $static->_stash_key($key);

      $app->helper(brand => sub {
         my $c = shift;
         return $c->stash($key) if @_ == 0;
         $c->stash($key => shift);
         return $c;
      });

      # this is another thing that we only want to do once
      $app->renderer
         ->with_roles('Mojolicious::Plugin::Branding::IndividualRendererRole')
         ->_stash_key($key);
   }

   my %b4 = (templates => {}, public => {});
   for my $name (keys(%$brands)) {
      my $value = $brands->{$name};
      for my $key (qw< templates public >) {
         $b4{$key}{$name} = defined($value) ? $value->{$key} : undef;
      }
   }
   $app->renderer->_add_brands($b4{templates});
   $static->_add_brands($b4{public});

   return;
}

sub register {
   my ($self, $app, $conf) = @_;
   my ($global, $individual) = __values_from_constrained_hash($conf // {},
      'unknown keys in configuration',
      [global => undef], [individual => {}]);

   # Validation and normalizations are needed before usage, so we do this
   # in the following order:
   # - validate/normalize global
   # - validate/normalize individual
   # - install individual
   # - install global
   my $global_spec = $self->_normalize_global($app, $global);
   $self->_register_individual($app, $individual);
   $self->_register_normalized_global($app, $global_spec);
   return $self;
}

1;
