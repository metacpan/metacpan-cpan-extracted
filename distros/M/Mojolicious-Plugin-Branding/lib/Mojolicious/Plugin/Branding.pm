package Mojolicious::Plugin::Branding;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::File qw< path >;
use Mojolicious::Static;
use Carp qw< croak >;

{ our $VERSION = '0.002' }

package Mojolicious::Plugin::Branding::IndividualRole;
use Mojo::Base -role;
use Mojo::File qw< path >;
has 'by_brand' => sub { return +{} };

around template_name => sub {
   my ($orig, $self, $options) = @_;
   my $name = $self->$orig($options) // return undef;
   
   # turn into a relative file
   if ((my $namepath = path($name))->is_abs) {
      my @parts = grep { length($_ // '') } $namepath->to_array->@*;
      return undef unless @parts;
      $name = Mojo::File->new(@parts)->to_string;
   }

   if (defined(my $brand = $options->{variant})) {
      if (defined(my $list = $self->by_brand->{$brand})) {
         for my $templates_dir (@$list) {
            my $path = $templates_dir->child($name);
            return $path->to_abs->to_string if -r $path;
         }
      }
   }
   return $name;
};

sub add_brands {
   my ($self, $href) = @_;
   my $by_brand = $self->by_brand;
   for my $brand (keys(%$href)) {
      my $aref = $by_brand->{$brand} //= [];
      my %present = map { $_ => 1 } @$aref;
      for my $path (@{$href->{$brand}}) {
         next if $present{$path}++;
         push @$aref, $path;
      }
   }
   return $self;
}

around template_path => sub {
   my ($orig, $self, $options) = @_;
   my $name = $self->template_name($options) // return undef;
   return $name if path($name)->is_abs;
   return $self->$orig($options);
};

around template_handler => sub {
   my ($orig, $self, $options) = @_;
   if (defined(my $brand = $options->{variant})) {
      for my $handler (sort { $a cmp $b } keys %{$self->handlers}) {
         my %options = ($options->%*, handler => $handler);
         my $name = $self->template_name(\%options) // next;
         return $handler if path($name)->is_abs;
      }
   }
   return $self->$orig($options);
};

package Mojolicious::Plugin::Branding;

sub _resolve_path {
   my ($self, $home, $path) = @_;
   return unless defined($path);
   if (! eval { $path->isa('Mojo::File') }) {
      croak 'invalid path, either Mojo::File or plain string accepted'
         if ref($path);
      croak 'invalid empty path' unless length($path);
      my $p = path($path);
      $path = $p->is_abs ? $p : $home->rel_file($path);
   }
   return unless -d $path;

   my %retval;
   for my $key (qw< templates public >) {
      my $sub_path = $path->child($key);
      $retval{$key} = $sub_path if -d $sub_path;
   }
   return unless scalar(keys(%retval)); # at least one sub_path exists

   $retval{brand} = $path->basename;
   return \%retval;
}

sub _resolve_paths {
   my ($self, $home, $paths) = @_;

   # some validation of $conf
   return unless defined($paths);
   $paths = [ $paths ] unless ref($paths) eq 'ARRAY';

   return [
      grep { defined($_) }
      map { $self->_resolve_path($home, $_) } $paths->@*
   ];
}

sub _register_global {
   my ($self, $app, $conf) = @_;

   my $paths = $self->_resolve_paths($app->home, $conf);

   my %dirs_for = (templates => [], public => []);
   for my $spec (@$paths) {
      push @{$dirs_for{$_}}, $spec->{$_} // () for keys(%dirs_for);
   }

   unshift @{$app->renderer->paths}, @{$dirs_for{templates}};
   unshift @{$app->static->paths},   @{$dirs_for{public}};

   return;
}

sub _register_individual {
   my ($self, $app, $conf) = @_;

   return unless defined($conf);
   croak 'individual requires a hash reference or nothing/undef'
      if ref($conf) ne 'HASH';

   # the key indicating the brand inside the stash
   my $key = $conf->{stash_key} // 'variant';

   my $specs = $self->_resolve_paths($app->home, $conf->{paths});
   my (%templates_for, %publics_for);
   for my $spec (@$specs) {
      if (defined($spec->{templates})) {
         my $aref = $templates_for{$spec->{brand}} //= [];
         push @$aref, $spec->{templates};
      }
      if (defined($spec->{public})) {
         my $aref = $publics_for{$spec->{brand}} //= [];
         push @$aref, $spec->{public};
      }
   }

   # take care of templates
   if (scalar(keys(%templates_for))) {
      my $renderer = $app->renderer;

      # compose the $role, but only once. This makes sure that registering
      # the plugin multiple times does not spoil everything.
      my $role = 'Mojolicious::Plugin::Branding::IndividualRole';
      $renderer->with_roles($role) unless Role::Tiny::does_role($renderer, $role);

      # add_brands makes sure to merge the new items with the previous ones
      $renderer->add_brands(\%templates_for);
   }

   # take care of static stuff
   my $static = $app->static;
   my $prefix = $static->prefix;
   my $asset_dir = $static->asset_dir;
   my %static_for =
      map {
         $_ => Mojolicious::Static->new(
            paths     => $publics_for{$_},
            classes   => [],
            extra     => {},
            prefix    => $prefix,
            asset_dir => $asset_dir,
         );
      }
      keys(%publics_for);

   $app->hook(before_dispatch => sub {
      my $c = shift;
      return if $c->res->code; # honor previous hooks' work

      my $brand = $c->stash($key) // return;
      $c->stash(variant => $brand) if $key ne 'variant';
      my $static = $static_for{$brand} // return;
      $c->app->plugins->emit_hook(after_static => $c)
         if $static->dispatch($c);
      return;
   });
}

sub register {
   my ($self, $app, $conf) = @_;
   $self->_register_global($app, $conf->{global} // []);
   $self->_register_individual($app, $conf->{individual} // {});
   return $self;
};

1;
