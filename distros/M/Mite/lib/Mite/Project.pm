package Mite::Project;

use feature ':5.10';
use Mouse;
with qw(
    Mite::Role::HasConfig
    Mite::Role::HasDefault
);

use Method::Signatures;
use Path::Tiny;
use Carp;

use Mite::Source;
use Mite::Class;

has sources =>
  is            => 'ro',
  isa           => 'HashRef[Mite::Source]',
  default       => sub { {} };

method classes() {
    my %classes = map { %{$_->classes} }
                  values %{$self->sources};
    return \%classes;
}

# Careful not to create a class.
method class($name) {
    return $self->classes->{$name};
}

# Careful not to create a source.
method source($file) {
    return $self->sources->{$file};
}

method add_sources(@sources) {
    for my $source (@sources) {
        $self->sources->{$source->file} = $source;
    }
}

method source_for($file) {
    # Normalize the path.
    $file = path($file)->realpath;

    return $self->sources->{$file} ||= Mite::Source->new(
        file    => $file,
        project => $self
    );
}


# This is the shim Mite.pm uses when compiling.
method inject_mite_functions(:$package, :$file) {
    my $source = $self->source_for($file);
    my $class  = $source->class_for($package);

    no strict 'refs';
    *{ $package .'::has' } = func( $name, %args ) {
        if( my $is_extension = $name =~ s{^\+}{} ) {
            $class->extend_attribute(
                name    => $name,
                %args
            );
        }
        else {
            require Mite::Attribute;
            my $attribute = Mite::Attribute->new(
                name    => $name,
                %args
            );
            $class->add_attribute($attribute);
        }

        return;
    };

    *{ $package .'::extends' } = func(@classes) {
        $class->extends(\@classes);

        return;
    };

    return;
}

method write_mites() {
    for my $source (values %{$self->sources}) {
        $source->compiled->write;
    }

    return;
}

method load_files(ArrayRef $files, $inc_dir?) {
    local $ENV{MITE_COMPILE} = 1;
    local @INC = @INC;
    unshift @INC, $inc_dir if defined $inc_dir;
    for my $file (@$files) {
        my $pm_file = path($file)->relative($inc_dir);
        require $pm_file;
    }

    return;
}

method find_pms($dir=$self->config->data->{source_from}) {
    return $self->_recurse_directory(
        $dir,
        func($path) {
            return if -d $path;
            return unless $path =~ m{\.pm$};
            return if $path =~ m{\.mite\.pm$};
            return 1;
        }
    );
}

method load_directory($dir=$self->config->data->{source_from}) {
    $self->load_files( [$self->find_pms($dir)], $dir );

    return;
}

method find_mites($dir=$self->config->data->{compiled_to}) {
    return $self->_recurse_directory(
        $dir,
        func($path) {
            return if -d $path;
            return 1 if $path =~ m{\.mite\.pm$};
            return;
        }
    );
}

method clean_mites($dir=$self->config->data->{compiled_to}) {
    for my $file ($self->find_mites($dir)) {
        path($file)->remove;
    }

    return;
}

method clean_shim() {
    return $self->_project_shim_file->remove;
}

# Recursively gather all the pm files in a directory
method _recurse_directory(Str $dir, CodeRef $check) {
    my @pm_files;

    my $iter = path($dir)->iterator({ recurse => 1, follow_symlinks => 1 });
    while( my $path = $iter->() ) {
        next unless $check->($path);
        push @pm_files, $path;
    }

    return @pm_files;
}

method init_project($project_name) {
    $self->config->make_mite_dir;

    $self->write_default_config(
        $project_name
    ) if !-e $self->config->config_file;

    return;
}

method add_mite_shim() {
    my $shim_file = $self->_project_shim_file;
    $shim_file->parent->mkpath;

    my $shim_package = $self->config->data->{shim};
    $shim_file->spew(<<"OUT");
{
    package $shim_package;
    BEGIN { our \@ISA = qw(Mite::Shim); }
}

OUT

    my $src_shim = $self->_find_mite_shim;
    $shim_file->append( $src_shim->slurp );

    return $shim_file;
}

method _project_shim_file() {
    my $config = $self->config;
    my $shim_package = $config->data->{shim};
    my $shim_dir     = $config->data->{source_from};

    my $shim_file = $shim_package;
    $shim_file =~ s{::}{/}g;
    $shim_file .= ".pm";
    return path($shim_dir, $shim_file);
}

method _find_mite_shim() {
    for my $dir (@INC) {
        # Avoid code refs in @INC
        next if ref $dir;

        my $shim = path($dir, "Mite", "Shim.pm");
        return $shim if -e $shim;
    }

    croak <<"ERROR";
Can't locate Mite::Shim in \@INC.  \@INC contains:
@{[ map { "  $_\n" } grep { !ref($_) } @INC ]}
ERROR
}

method write_default_config(Str $project_name, %args) {
    my $libdir = path('lib');
    $self->config->write_config({
        project         => $project_name,
        shim            => $project_name.'::Mite',
        source_from     => $libdir.'',
        compiled_to     => $libdir.'',
        %args
    });
    return;
}

1;
