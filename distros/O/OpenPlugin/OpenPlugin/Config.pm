package OpenPlugin::Config;

# $Id: Config.pm,v 1.28 2003/04/28 17:43:48 andreychek Exp $

use strict;
use Cwd            qw();
use Data::Dumper   qw( Dumper );
use File::Basename qw();
use Log::Log4perl  qw( get_logger );
use OpenPlugin::Plugin;

@OpenPlugin::Config::ISA     = qw( OpenPlugin::Plugin );
$OpenPlugin::Config::VERSION = sprintf("%d.%02d", q$Revision: 1.28 $ =~ /(\d+)\.(\d+)/);

# Package var to keep track of files read in.  Is there a better way to do
# this?
#%OpenPlugin::ConfigFiles     = {};

my $logger = get_logger();

########################################
# CLASS METHODS
########################################

# This is the only place where we should have to specify information
# that is normally in the driver map. Otherwise we have a
# bootstrapping problem...

my %CONFIG_CLASS = (
   conf => 'OpenPlugin::Config::Conf',
   ini  => 'OpenPlugin::Config::Ini',
   perl => 'OpenPlugin::Config::Perl',
   xml  => 'OpenPlugin::Config::XML',
);


sub get_config_driver {
    my ( $class, $config_src, $config_type ) = @_;
    unless ( $config_type ) {
        ( $config_type ) = $config_src =~ /\.(\w+)\s*$/;
    }
    return $CONFIG_CLASS{ lc $config_type };
}


# Even if they're given a relative path, config implementations should
# use this to get the full configuration directory and filename so
# that 'Include' directives work as expected

sub find_config_location {
    my ( $class, $initial_filename, $other_root_dir ) = @_;
    $logger->info( "Finding configuration location from ($initial_filename)" );

    return ( "", "" ) unless $initial_filename;

    # Get initial config dir, and untaint
    my $initial_dir  = File::Basename::dirname( $initial_filename );
    ( $initial_dir ) = $initial_dir =~ m/^(.*)$/ if -d $initial_dir;

    # Get the config file name, and untaint
    my $config_file  = File::Basename::basename( $initial_filename );
    ( $config_file ) = $config_file =~ m/^(.*)$/ if -f $initial_filename;

    # Get the current working directory, and untaint
    my $current_dir  = Cwd::cwd;
    ( $current_dir ) = $current_dir =~ m/^(.*)$/ if -d $current_dir;

    chdir( $initial_dir );

    # Get path to the current dir, and untaint
    my $config_dir   = Cwd::cwd;
    ( $config_dir ) = $config_dir =~ m/^(.*)$/ if -d $config_dir;

    chdir( $current_dir );
    unless ( -f join( '/', $config_dir, $config_file ) ) {
        if ( -f join( '/', $other_root_dir, $config_file ) ) {
            $config_dir = $other_root_dir;
        }
    }
    return ( $config_dir, $config_file );
}

sub read {
    my ( $self, $data ) = @_;

    my ( $full_filename, $config );
    if( ref $data ne "HASH" ) {
        $full_filename ||= join( '/', $self->{_m}{dir}, $self->{_m}{filename} );
        $logger->info( "Trying to read file ($full_filename)" );

        my $config_class =
                OpenPlugin::Config->get_config_driver( $full_filename,
                                                       $self->{_m}{type} );
        unless ( $config_class ) {
            die "Config is of unknown type! (Type: $self->{_m}{type} )";
        }

        # The config drivers are defined at the top of this file, and are not
        # tainted
        eval "require $config_class";
        $config = $config_class->get_config( $full_filename );
    }
    else {
        $config = $data;
    }
    foreach my $key ( keys %{ $config } ) {
        $self->{$key} = $config->{$key};
    }

    # Now see if there are any settings for 'Include'
    if ( $self->{include} ) {
        foreach my $src ( $self->get( 'include', 'src' ) ) {
            next unless ( $src );
            $logger->info( "Including file ($src)." );
            $self->include( $src ) ;
        }
    }

    $logger->info( "Config file ($full_filename) read into object ok" );

    return $self;
}


########################################
# PLUGIN INTERFACE
########################################

sub type { return 'config' }

sub write            {}

sub meta_config_dir  { return $_[0]->{_m}{dir} }
sub meta_config_file { return $_[0]->{_m}{filename} }
sub OP               { return $_[0]->{_m}{OP} }

sub init {
    my ( $self, $params ) = @_;

    my $src = $params->{src};
    my $dir = $params->{dir};

    my ( $config_dir, $filename ) = $self->find_config_location( $src, $dir );

    # Keep track of what has been read in
    $self->{_m}{filename} = $filename;
    $self->{_m}{dir}      = $config_dir;
    $self->{_m}{type}     = $params->{type};
    $self->{_m}{OP}{_toggle}{$filename} = 1;
    return $self;
}


sub sections {
    my ( $self ) = @_;
    return grep ! /^_m$/, sort keys %{ $self };
}

sub get {
    my ( $self, $section, @p ) = @_;
    my ( $sub_section, $param ) = ( $p[1] ) ? ( $p[0], $p[1] ) : ( undef, $p[0] );
    my $item = ( $sub_section )
                 ? $self->{ $section }{ $sub_section }{ $param }
                 : $self->{ $section }{ $param };
    return $item unless ( ref $item eq 'ARRAY' );
    return wantarray ? @{ $item } : $item->[0];
}

sub set {
    my ( $self, $section, @p ) = @_;
    my ( $sub_section, $param, $value ) = ( $p[2] ) ? ( $p[0], $p[1], $p[2] ) : ( undef, $p[0], $p[1] );
    return $self->{ $section }{ $sub_section }{ $param } = $value  if ( $sub_section );
    return $self->{ $section }{ $param } = $value
}


sub delete {
    my ( $self, $section, @p ) = @_;
    my ( $sub_section, $param ) = ( $p[1] ) ? ( $p[0], $p[1] ) : ( undef, $p[0] );
    if ( $sub_section ) {
        $logger->info( "Deleting ($param) from sub-section ($section)($sub_section)" );
        return delete $self->{ $section }{ $sub_section }{ $param };
    }
    elsif ( $param ) {
        $logger->info( "Deleting ($param) from section ($section)" );
        return delete $self->{ $section }{ $param };
    }
    else {
        $logger->info( "Deleting section ($section)" );
        return delete $self->{ $section };
    }
}


# Allow a configuration to 'include' another configuration file -- it
# might be one of a different type too, so an INI file can include an
# XML file, etc.

sub include {
    my ( $self, $config_src ) = @_;

    # History tends to "repeat" itself if we don't learn it the first time ;-)
    if ( $self->OP->{_toggle}{$config_src} ) {
        $logger->warn("Attempt to include ($config_src), which is already loaded!");
        return;
    }

    # Flag this so we can tell we started processing this config
    $self->OP->{_toggle}{$config_src} = 1;

    # Find out what type of configuration this is and read it in
    my $config_class = $self->get_config_driver( $config_src );
    unless ( $config_class ) {
        die "Configuration ($config_src) cannot be included -- no valid ",
            "configuration class found.\n";
    }
    $logger->info( "Trying to use class ($config_class) for included ",
                   "config ($config_src)" );
    eval "require $config_class";

    my $include_config = OpenPlugin::Plugin->new( "config", $self, {
                                        src => $config_src,
                                        dir => $self->meta_config_dir })->read;

    if( $logger->is_debug ) {
        $logger->debug( "Included config: ", Dumper( $include_config ) );
    }

    $logger->info( "Sections of included config: ", join( ', ', $include_config->sections ) );
    foreach my $section ( $include_config->sections ) {
        $logger->info( "Entering section ($section) of included config" );
        next unless ( ref $include_config->{ $section } eq 'HASH' );
        foreach my $param ( keys %{ $include_config->{ $section } } ) {

            # This section has a subsection, and $param is the subsection title

            if ( ref $include_config->{ $section }{ $param } eq 'HASH' ) {
                $logger->info( "($section)($param) is a hashref -- read in one at a time" );
                foreach my $sub_param ( keys %{ $include_config->{ $section }{ $param } } ) {
                    $self->set( $section, $param, $sub_param,
                                $include_config->get( $section, $param, $sub_param ) );
                }
            }
            else {
                $logger->info( "($section)($param) is a value" );
                $self->set( $section, $param, $include_config->get( $section, $param ) );
            }
        }
    }
    return $include_config;
}

1;

__END__

=pod

=head1 NAME

OpenPlugin::Config - Plugin for reading and writing config data

=head1 SYNOPSIS

 # Load in the config file config.conf
 my $OP = OpenPlugin->new( config => { src    => '/path/to/config.conf' });

 # Pass in the config file type as an argument
 my $OP = OpenPlugin->new( config => { src    => '/etc/config',
                                       type   => 'conf' });

 # Pass in the configuration data as an argument
 my $OP = OpenPlugin->new( config => { config => \%config_data });

 # Retrieve settings which have been loaded by any of the above methods
 $username = $OP->config->{datasource}{main}{username};
 $session_config = $OP->config->{plugin}{session};

=head1 DESCRIPTION

A configuration file is a method of providing a predefined set of data to an
application.  Represented as an Apache-style conf file, it might look like:

 <Section>
    <one>
        key     = value
        another = value-another
    </one>
    <two>
        key     = value-two
        another = value-another-two
    </two>
 </Section>

This plugin's job is to accept a config file, and make it available for
programs to access.  Reading in and using the above file would look like:

 my $OP = OpenPlugin->new( config => { src => 'sample_config.conf' } );
 print $OP->config->{'Section'}{'one'}{'key'};     # print's "value"
 print $OP->config->{'Section'}{'two'}{'another'}; # print's "value-another-two"

The driver used to read the file is based on the file's extension.  If your
config file has a C<.conf> extension, the C<conf> driver will be used.  If this
isn't what you want, you can pass in an explicit "type" as a parameter to tell
the Config plugin what driver to use.

=head1 METHODS

B<read( [ $source, ...  ])>

This function is used to load a configuration.  This can be done by passing in
a file, or a hash reference containing the data.

It is called for you when you instanciate a new OpenPlugin object.

Returns: config object.

B<write( $destination )>

Writes the current configuration data out to $destination.

Returns: true if configuration written successfully, false if not.

B<meta_config_dir()>

Returns: the directory from which your configuration was read.

B<meta_config_file()>

Returns: the filename from which your configuration was read.

B<sections()>

Return a list of the top-level sections in the configuration. In the
future this may include sub-sections as well.

B<get( $section, $param )>

B<get( $section, $sub_section, $param )>

Returns: the value for C<$param> in either C<$section> or C<$section>
and C<$sub_section> if C<$sub_section> is specified.

B<set( $section, $param, $value )>

B<set( $section, $sub_section, $param, $value )>

Sets the parameter C<$param> to value C<$value> in either C<$section>
or C<$section> and C<$sub_section> if C<$sub_section> is specified.

Returns: the value set.

B<delete( $section )>

B<delete( $section, $param )>

B<delete( $section, $sub_section )>

B<delete( $section, $sub_section, $param )>

Deletes the C<$section>, a parameter in C<$section>, C<$sub_section>
of C<$section> or a parameter in C<$sub_section> of C<$section>.

Returns: whatever was deleted.

B<get_config_driver( $config_src [, $config_type ] )>

Retrieves the driver used for a particular configuration
source. Generally we can tell what type of driver is necessary from
the file extension, but you can force a type by passing in the
optional second argument.

Returns: class matching the configuration type. If the config type is
unknown, returns undef.

=head1 BUGS

None known.

=head1 TO DO

Currently, you can include at most one file.  Parts of the Config plugin,
particularly the include logic, should be rewritten to be a bit more flexible
(such as to handle more than one included file, etc).  One way to do this might
be to use Hash::Merge.

=head1 SEE ALSO

See the individual driver documentation for settings and parameters specific to
that driver.

=head1 COPYRIGHT

Copyright (c) 2001-2003 Eric Andreychek. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Eric Andreychek <eric@openthought.net>

Chris Winters <chris@cwinters.com>

=cut
