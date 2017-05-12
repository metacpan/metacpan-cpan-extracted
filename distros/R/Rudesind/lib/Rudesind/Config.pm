package Rudesind::Config;

use strict;

use Config::Auto;
use File::Spec;
use Path::Class;


my @Required = qw( root_dir data_dir );

my %Default = ( uri_root   => '/Rudesind',
                image_uri_root   => '',
                raw_image_subdir => '/images',
                max_upload =>  (1024 ** 2) * 1000,
                view       => 'default',
                temp_dir   => File::Spec->tmpdir,
                charset    => 'UTF-8',
                admin_password  => undef,
                gallery_columns => 3,
                thumbnail_max_height  => 200,
                thumbnail_max_width   => 200,
                image_page_max_height => 400,
                image_page_max_width  => 500,
                error_mode => 'fatal',
              );

$Default{session_directory} =
    Path::Class::dir( $Default{temp_dir}, 'Rudesind-sessions' )->stringify;

foreach my $f ( @Required, keys %Default )
{
    no strict 'refs';
    *{$f} = sub { $_[0]->{$f} };
}

sub new
{
    my $class = shift;
    my $file = shift;

    unless ($file)
    {
        my @files = ( '/etc/Rudesind.conf',
                      '/etc/Rudesind/Rudesind.conf',
                      '/opt/Rudesind/Rudesind.conf',
                    );

        unshift @files, $ENV{RUDESIND_CONFIG} if defined $ENV{RUDESIND_CONFIG};

        unshift @files, Path::Class::file( $ENV{HOME}, '.Rudesind.conf' )
            if $ENV{HOME};

        foreach my $f (@files)
        {
            if ( -r $f )
            {
                $file = $f;
                last;
            }
        }

        die "No config file found.  Maybe you should set the RUDESIND_CONFIG env variable.\n"
            unless defined $file;
    }

    local $Config::Auto::DisablePerl = 1;
    my $config = Config::Auto::parse($file);

    foreach my $f (@Required)
    {
        die "No value supplied for the $f field in the config file at $f.\n"
            unless exists $config->{$f};
    }

    $config->{uri_root} =~ s{/$}{};

    return bless { %Default,
                   %$config,
                   config_file => $file,
                 }, $class;
}

sub config_file { $_[0]->{config_file} }

sub comp_root
{
    my $self = shift;

    my $view = $self->view();

    if ( $view eq 'default' )
    {
        return $self->main_comp_root;
    }
    else
    {
        my $dir = $self->root_dir;

        return [ [ main    => $self->main_comp_root ],
                 [ default => "$dir/default" ],
               ];
    }
}

sub main_comp_root
{
    my $self = shift;

    my $view = $self->view();

    my $dir = $self->root_dir;

    return "$dir/$view";
}

sub image_dir
{
    my $self = shift;

    return Path::Class::dir( $self->root_dir(), $self->raw_image_subdir );
}

sub image_cache_dir
{
    my $self = shift;

    my $dir = $self->image_dir;
    my $image_dir_name = File::Basename::basename( $self->raw_image_subdir );

    $dir =~ s/\Q$image_dir_name\E/image-cache/;

    return $dir;
}


1;

__END__

=pod

=head1 NAME

Rudesind::Config - A class to provide access to configuration file values

=head1 SYNOPSIS

  use Rudesind::Config;

  my $config = Rudesind::Config;

  print $config->uri_root;

=head1 DESCRIPTION

This class provides an interface for reading the contents of a
Rudesind configuration file.

=head1 CONSTRUCTOR

When its C<new()> method is called, it looks for a configuration file
in the following locations:

=over 4

=item * $ENV{RUDESIND_CONFIG}

=item * $ENV{HOME}/.Rudesind.conf

=item * /etc/Rudesind.conf

=item * /etc/Rudesind/Rudesind.conf

=item * /opt/Rudesind/Rudesind.conf

=back

If no file is found, it will die.  If the file it finds does not
contain a required parameter, it will also die.

=head1 METHODS

This class provides a method for each parameter in the configuration
file, as well as a number of additional methods.

=head2 Required Parameters

=over 4

=item * root_dir

=item * data_dir

=back

=head2 Other Parameters

=over 4

=item * uri_root

Defaults to F</Rudesind>.

=item * image_uri_root

Defaults to an empty string.

=item * raw_image_subdir

Defaults to F</images>.

=item * view

Defaults to "default".

=item * temp_dir

Defaults to C<< File::Spec->tmpdir >>.

=item * charset

Defaults to "UTF-8".

=item * admin_password

Defaults to C<undef>.

=item * gallery_columns

Defaults to 3.

=item * thumbnail_max_height

Defaults to 200.

=item * thumbnail_max_width

Defaults to 200.

=item * image_page_max_height

Defaults to 400.

=item * image_page_max_width

Defaults to 500.

=item * error_mode

Defaults to "fatal".

=back

=head2 Additional Methods

This class provides the following additional methods:

=over 4

=item * config_file()

Returns the filesystem path to the configuration file the object
represents.

=item * comp_root()

Returns either a string or an array reference which can be passed to
the C<HTML::Mason::Interp> constructor.  The component root is based
on the value of the "view" parameter.

=item * main_comp_root()

Returns the filesystem path to the first component root (in case there
is more than one).  If there is only one, this is the same as calling
C<comp_root()>.

=item * image_dir()

Returns the filesystem path to the raw image directory.

=item * image_cache_dir()

Returns the filesystem path to the image cache directory.

=back

=cut
