package Reaction::UI::Skin;

use Reaction::Class;

# declaring dependencies
use Reaction::UI::LayoutSet;
use Reaction::UI::RenderingContext;
use File::ShareDir;
use File::Basename;
use Config::Any;

use aliased 'Path::Class::Dir';

use namespace::clean -except => [ qw(meta) ];


has '_layout_set_cache'   => (is => 'ro', default => sub { {} });
has '_widget_class_cache'   => (is => 'ro', default => sub { {} });

has 'name' => (is => 'ro', isa => 'Str', required => 1);
has 'skin_dir' => (is => 'rw', isa => Dir, lazy_fail => 1);

has 'widget_search_path' => (
  is => 'rw', isa => 'ArrayRef', required => 1, default => sub { [] }
);

has 'view' => (
  is => 'ro', required => 1, weak_ref => 1,
  handles => [ qw(layout_set_class) ],
);

has 'super' => (
  is => 'rw', isa => Skin, required => 0, predicate => 'has_super',
);

sub BUILD {
  my ($self, $args) = @_;
  $self->_find_skin_dir($args);
  $self->_load_skin_config($args);
}
sub _find_skin_dir {
  my ($self, $args) = @_;
  my $skin_name = $self->name;
  if ($skin_name =~ s!^/(.*?)/!!) {
    my $dist = $1;
    $args->{skin_base_dir} = eval {
        Dir->new(File::ShareDir::dist_dir($dist))
           ->subdir('skin');
    };
    if ($@) {
        # No installed Reaction
        my $file = __FILE__;
        my $dir = Dir->new(dirname($file));
        my $skin_base;
        while ($dir->parent) {
            if (-d $dir->subdir('share') && -d $dir->subdir('share')->subdir('skin')) {
                $skin_base = $dir->subdir('share')->subdir('skin');
                last;
            }
            $dir = $dir->parent;
        }
        confess "could not find skinbase by recursion. ended up at $dir, from $file"
          unless $skin_base;
        $args->{skin_base_dir} = $skin_base; 
    }
  }
  my $base = $args->{skin_base_dir}->subdir($skin_name);
  confess "No such skin base directory ${base}"
    unless -d $base;
  $self->skin_dir($base);
};
sub _load_skin_config {
  my ($self, $args) = @_;
  my $class = ref($self) || $self;
  my $base = $self->skin_dir;
  my $lst = sub { (ref $_[0] eq 'ARRAY') ? $_[0] : [$_[0]] };
  my @files = (
    $args->{skin_base_dir}->file('defaults.conf'), $base->file('skin.conf')
  );
  # we get [ { $file => $conf }, ... ]
  my %cfg = (map { %{(values %{$_})[0]} }
              @{Config::Any->load_files({
                files => [ grep { -e $_ } map { $_->stringify } @files ],
                use_ext => 1,
              })}
            );
  if (my $super_name = $cfg{extends}) {
    my $super = $class->new(
      name => $super_name,
      view => $self->view,
      skin_base_dir => $args->{skin_base_dir},
    );
    $self->super($super);
  }
  if (exists $cfg{widget_search_path}) {
    $self->widget_search_path($lst->($cfg{widget_search_path}));
  }
  # For some reason this conditional doesn't work correctly without
  # the "my @x". Answers on a postcard.
  unless (my @x = $self->full_widget_search_path) {
    confess "No widget_search_path in defaults.conf or skin.conf"
            .($self->has_super
              ? " and no search path provided from super skin "
                .$self->super->name
              : "");
  }
}
sub create_layout_set {
  my ($self, $name) = @_;
  $self->_create_layout_set($name, [], $self);
};
sub _create_layout_set {
  my ($self, $name, $tried, $top_skin) = @_;
  if (my $path = $self->layout_path_for($name)) {
    return $self->layout_set_class->new(
             $self->layout_set_args_for($name),
             source_file => $path,
             top_skin => $top_skin,
           );
  }
  $tried = [ @{$tried}, $self->our_path_for_type('layout') ];
  if ($self->has_super) {
    return $self->super->_create_layout_set($name, $tried, $top_skin);
  }
  confess "Couldn't find layout set file for ${name}, tried "
          .join(', ', @$tried);
};
sub layout_set_args_for {
  my ($self, $name) = @_;
  return (
    name => $name,
    skin => $self,
    ($self->has_super ? (next_skin => $self->super) : ()),
    $self->view->layout_set_args_for($name),
  );
};
sub layout_path_for {
  my ($self, $layout) = @_;
  my $file_name = join(
    '.', $layout, $self->view->layout_set_file_extension
  );
  my $path = $self->our_path_for_type('layout')
                  ->file($file_name);
  return (-e $path ? $path : undef);
};
sub search_path_for_type {
  my ($self, $type) = @_;
  return [
    $self->our_path_for_type($type),
    ($self->has_super
      ? @{$self->super->search_path_for_type($type)}
      : ()
    )
  ];
};
sub our_path_for_type {
  my ($self, $type) = @_;
  return $self->skin_dir->subdir($type)
};
sub full_widget_search_path {
  my ($self) = @_;
  return (
    @{$self->widget_search_path},
    ($self->has_super ? $self->super->full_widget_search_path : ())
  );
};
sub widget_class_for {
  my ($self, $layout_set) = @_;
  my $base = blessed($self);
  my $widget_type = $layout_set->widget_type;
  return $self->_widget_class_cache->{$widget_type} ||= do {

    my @search_path = $self->full_widget_search_path;
    my @haystack = map {join('::', $_, $widget_type)} @search_path;

    foreach my $class (@haystack) {
      #if the class is already loaded skip the call to Installed etc.
      return $class if Class::MOP::is_class_loaded($class);
      next unless Class::Inspector->installed($class);

      my $ok = eval { Class::MOP::load_class($class) };
      confess("Failed to load widget '${class}': $@") if $@;
      return $class;
    }
    confess "Couldn't locate widget '${widget_type}' for layout "
      ."'${\$layout_set->name}': tried: ".join(", ", @haystack);
  };
};

__PACKAGE__->meta->make_immutable;


1;
