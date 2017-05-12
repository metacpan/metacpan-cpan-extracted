package OpenInteract::Config;

# $Id: Config.pm,v 1.7 2002/04/23 13:01:33 lachoy Exp $

use strict;
use OpenInteract::Error;
require Exporter;

# AUTOLOAD not being used any longer... see below
#use vars qw( $AUTOLOAD );
#$AUTOLOAD = '';

@OpenInteract::Config::ISA       = qw( Exporter );
$OpenInteract::Config::VERSION   = sprintf("%d.%02d", q$Revision: 1.7 $ =~ /(\d+)\.(\d+)/);
@OpenInteract::Config::EXPORT_OK = qw( _w DEBUG );
my %CONFIG_TYPES = (
   'perl' => 'OpenInteract::Config::PerlFile',
   'ini'  => 'OpenInteract::Config::IniFile',
);

use constant DEBUG => 0;

# Interface: subclasses should override these

sub read_config { return $_[0]; }
sub save_config { return undef; }


# Create a new config object. This is a factory method: rather than
# creating new objects of the class OpenInteract::Config, we use the
# variable $type and create an object based on it.

sub instance {
    my ( $pkg, $type, @params ) = @_;

    # Backwards compatibility fix -- this probably won't be here forever.

    $type ||= 'perl';
    my $class = $CONFIG_TYPES{ $type };
    die "No configuration class corresponding to type ($type)" unless ( $class );
    eval "require $class";
    if ( $@ ) {
        die "Configuration class ($class) cannot be used. Error: $@";
    }
    my $data = $class->read_config( @params );
    return bless( $data, $class );
}


sub read_file {
    my ( $class, $filename ) = @_;
    DEBUG && _w( 1, "Config trying to read file [$filename]" );
    open( CONF, $filename )
          || die "Cannot open [$filename] for reading: $!\n";
    my @lines = <CONF>;
    close( CONF );
    return \@lines;
}

# Copy items from the default action into all the other actions --
# this method doesn't quite belong here but since we don't have
# anything dealing strictly with action information... One possibility
# is to create a ActionTable module which does stuff like this and
# operates on $R

sub flatten_action_config {
    my ( $self ) = @_;
    my $default_action = $self->{action_info}{default} || $self->{action}{_default_action_info_};
    my @names = ();
    foreach my $action_key ( keys %{ $self->{action} } ) {
        next if ( $action_key eq 'default' or $action_key =~ /^_/ );
        foreach my $def ( keys %{ $default_action } ) {
            $self->{action}{ $action_key }{ $def } ||= $default_action->{ $def };
        }

        # Also ensure that the action information knows its own key

        $self->{action}{ $action_key }{name} = $action_key;
        push @names, $action_key;
    }
    return \@names;
}


# Set a parameter

sub param_set {
    my ( $self, $config, $value ) = @_;
    $config = lc $config;
    $self->{ $config } = $value if ( $value );
    return $self->{ $config };
}


# Get the value of a key

sub get {
    my ( $self, @p ) = @_;
    my @configs = ();
    foreach my $conf ( @p ) {
        push @configs, $self->param_set( $conf );
    }
    if ( scalar @configs == 1 ) {
        return $configs[0];
    }
    return @configs;
}


# Allow you to set multiple values at once

sub set {
    my ( $self, $p ) = @_;
    my %configs = ();
    my $count = 0;
    my $last_conf = '';           # hack to return one value if only one passed in
    foreach my $conf ( keys %{ $p } ) {
        $configs{ $conf } = $self->param_set( $conf, $p->{ $conf } );
        $last_conf = $conf;
        $count++;
    }
    if ( $count == 1 ) {
        return $configs{ $last_conf };
    }
    return %configs;
}


# Do a macro expansion on the directory names -- this SHOULD be done
# only once (on read, or by request) and then the information in the
# config object would be stable

sub get_dir {
    my ( $self, $dir_tag ) = @_;
    my $dir_hash = $self->{dir};
    $dir_tag =~ s/_dir$//;
    my $dir = $dir_hash->{ lc $dir_tag };
    DEBUG && _w( 1, "get_dir(): start out with <<$dir>>" );
    return undef if ( ! $dir );
    while ( $dir =~ m|^\$([\w\_]+)/| ) {
        my $orig_lookup = $1;
        my $lookup_dir = lc $orig_lookup;
        DEBUG && _w( 1, " get_dir(): found lookup dir of <<$lookup_dir>>" );
        return undef if ( ! $dir_hash->{ $lookup_dir } );
        $dir =~ s/^\$$orig_lookup/$dir_hash->{ $lookup_dir }/;
        DEBUG && _w( 1, " get_dir(): new directory: <<$dir>>" );
    }
    return $dir;
}



sub is_file_valid {
    my ( $self, $filename ) = @_;

    unless ( -f $filename ) {
        my $msg = 'Cannot read configuration file!';
        my $system_msg = "No valid filename ($filename) for reading configuration information!";
        OpenInteract::Error->set({ user_msg   => $msg,
                                   type       => 'config',
                                   system_msg => $system_msg,
                                   method     => 'read_config',
                                   extra      => { filename => $filename } });
        die $msg;
    }
    return 1;
}

# Allow you to call config keys as methods -- we should probably get
# rid of this and force you to use it as a hashref...

# AUTOLOAD no longer supported -- please email Chris if you have an
# issue with this.

#sub AUTOLOAD {
#  my ( $self, @params ) = @_;
#  my $request = $AUTOLOAD;
#  $request =~ s/.*://;
#  DEBUG && _w( 1, "Trying to fulfill request ($request) from AUTOLOAD" );
#  return $self->param_set( $request, @params);
#}


sub _w {
    return unless ( DEBUG >= shift );
    my ( $pkg, $file, $line ) = caller;
    my @ci = caller(1);
    warn "$ci[3] ($line) >> ", join( ' ', @_ ), "\n";
}

1;

__END__

=pod

=head1 NAME

OpenInteract::Config -- centralized configuration information

=head1 SYNOPSIS

 use OpenInteract::Config;

 my $config = OpenInteract::Config::PerlFile->new();
 $config->read_file( '/path/to/dbi-config.info' );
 $config->{debugging} = 1;

 my $dbh = DBI->connect( $config->{db_dsn},
                         $config->{db_username},
                         $config->{db_password}
                         { RaiseError => 1 } );

 if ( my $debug = $config->{DEBUG} ) {
     print $LOG "Trace level $debug: fetching user $user_id...";
     if ( my $user = $self->fetch( $user_id ) ) {
         print $LOG "successful fetching $user_id\n";
     }
     else {
         print $LOG "No such user with ID $user_id";
     }
 }

=head1 DESCRIPTION

Allows you to embed a configuration object that responds
to get/set requests. Different from just using key/value
pairs within your object since you do not have to worry
about writing get/set methods, cluttering up your AUTOLOAD
routine, or things like that. It also allows us to create
configuration objects per module, or even per module instance,
as well as create one for the entire program/project by putting
it in the always-accessible Request object.

Very simple interface and idea: information held in key/value
pairs. You can either retrieve the information using the I<get()>
method or by referring to the config object like a hashref. For
instance, to retrieve the information related to DBI, you could do:

 my ( $dsn, $uid, $pass ) = ( $config->{db_dsn},
                              $config->{db_username},
                              $config->{db_password} );

or you could do:

 my ( $dsn, $uid, $pass ) = $config->get( 'db_dsn', 'db_username', 'db_password' );

Setting values is similarly done:

 my $font_face = $config->{font_face} = 'Arial, Helvetica';

or:

 my $font_face = $config->set( font_face => 'Arial, Helvetica' );

Note that you might want to use the get/set method calls
more frequently for the sake of clarity. Or not. TMTOWTDI.

=head2 METHODS

A description of each method follows:

B<instance( $type, @params )>

Unknown. Depends on what is being configured.

Create the Config object. Just bless an anonymous hash and stick every
name/value pair passed into the method into the hash.

Note: we should probably lower case all arguments passed in, but
getting/setting parameters and values should only be done via the
interface. So, in theory, we should not allow the user to set
B<any>thing here...

Parameters:

=over 4

=item *

B<type> ($)

Type of configuration file to create. Currently the only supported
type is 'perl', which keeps the configuration information in a perl
data structure.

=back

B<Returns>: Configuration object.

B<flatten_action_config()>

Copies information from the default action into all the other action
(except the default action and those beginning with '_', which are
presumably private.)

Returns: an arrayref of action keys (tags) for which information was
set.

B<param_set( $key, [ $value ] )>

The first parameter is the config key, the optional second parameter
is the value we would like to set the key to.  Simply set the value if
it is passed in, then return whatever the value is.

Possible modifications: allow the use of a third parameter, 'force',
that enables you to blank out a value. Currently this is not possible.

B<get( @keys )>

Return a list of values for each $key passed in. If only one key is
passed in, we return a single value, not a list consisting of a single
value.

Possible modifications: use I<wantarray> to see if we should return a
list.

B<set( %params )>

Parameters are config key => config/value pairs

Set the config key to its value for each pair passed in.  Return a
hash of the new key/value pairs, or a single value if only one pair
was passed in.

Possible modifications: Use I<wantarray> to see if we should return a
hash or a single value. Use 'force' parameter to ensure that blank (or
undef) values passed in are reflected properly.

B<get_dir( 'directory-tag' )>

Retrieves the directory name for 'directory-tag', which
within the Config object may depend on other settings.
For instance, you could have:

 $c->set( 'base_dir', '/home/cwinters/work/cw' );
 $c->set( 'html_dir', '$BASE_DIR/html' );
 $c->set( 'image_dir', '$HTML_DIR/images' );

and call:

 $c->get_dir( 'image_dir' );

and receive:

 '/home/cwinters/work/cw/html/images'

in return.

We should probably generalize this to other types of settings, but
this Config object is probably on its last legs anyway.

=head1 ABSTRACT METHODS

These are methods meant to be overridden by subclasses, so they do not
really do anything here. Useful for having a template to see what
subclasses should do, however.

B<read_config()>

Abstract method for subclasses to override with their own means of
reading in config information (from DBI, file, CGI, whatever).

Returns: $config_obj on success; undef on failure

B<save_config()>

Abstract method for subclasses to override with their
own means of writing config to disk/eleswhere.

Returns: true on success; undef on failure.

=head1 TODO

B<Permanent Configuration Values>

Future work should include setting configuration values permanently
for future uses of the module. We could instantiate the configuration
object with an argument giving it a file to read the keys/values
from. A DESTROY routine could then save all changed values to the
file. This would also allow us to change looks very easily...

=head1 BUGS

B<Remove Configuration Values>

Need to determine a way to remove a value for a configuration
item. Since we test for the existence of a value to determine if we
are getting or setting, a non-existent value will simply return what
is there.  Not a big deal currently.

See I<Possible modifications> entries for both I<set()> and
I<param_set()>.

=head1 COPYRIGHT

Copyright (c) 2001-2002 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters <chris@cwinters.com>

=cut
