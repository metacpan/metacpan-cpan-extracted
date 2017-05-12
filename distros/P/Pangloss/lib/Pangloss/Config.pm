=head1 NAME

Pangloss::Config - config singleton for Pangloss.

=head1 SYNOPSIS

 use Pangloss::Config;

 # get config vars from %ENV (if not already set):
 my $C = Pangloss::Config->new( \%ENV );

 print "pangloss home is: $C->{PG_HOME}\n" if $C->{PG_DEBUG};

 # force parsing:
 $C->parse_hash( $some_hash );

=cut

package Pangloss::Config;

use strict;
use warnings::register;

use File::Spec::Functions qw( catfile catdir rel2abs );

use base qw( Pangloss::Object );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.3 $ '))[2];

our $CONFIG;
our @CONFIG_VARS = qw( PG_DEBUG PG_HOME PG_CONFIG_FILE
		       PG_TEMPLATE_DIR  PG_TEMPLATE_TYPE
		       PG_SESSION_TYPE  PG_SESSION_EXPIRY
		       PG_PIXIE_DSN PG_PIXIE_USER PG_PIXIE_PASS );

sub new {
    my $class = shift;
    return $CONFIG if $CONFIG;
    $CONFIG = bless {}, $class;
    $CONFIG->init( @_ ) || return;
    return $CONFIG;
}

sub init {
    my $self = shift;
    my $hash = shift || {};
    return $self->parse_hash( $hash );
}

sub config_vars {
    return @CONFIG_VARS;
}

sub parse_hash {
    my $self = shift;
    my $hash = shift || return;

    $self->emit( "initializing Pangloss config\n" );
    warn( "($$) initializing Pangloss config\n" ) if warnings::enabled;

    foreach my $cfg_var ($self->config_vars) {
	$self->{$cfg_var} =
	  defined $hash->{$cfg_var}
	    ? $hash->{$cfg_var}
	    : $self->get_default_for( $cfg_var );
    }

    return $self;
}

sub get_default_for {
    my $self    = shift;
    my $cfg_var = shift;
    my $method  = "get_default_$cfg_var";
    return $self->$method if $self->can( $method );
    return undef;
}

sub set_default_for {
    my $class   = shift;
    my $cfg_var = shift;
    my $val     = shift;
    my $method  = "get_default_$cfg_var";
    no strict 'refs';
    *{$method}  = \&$val;
    return $class;
}

#------------------------------------------------------------------------------
# Default values

sub get_default_PG_DEBUG          { 0 }
sub get_default_PG_HOME           { rel2abs('.') }
sub get_default_PG_TEMPLATE_TYPE  { 'petal' }
sub get_default_PG_SESSION_TYPE   { 'file_cache' }
sub get_default_PG_SESSION_EXPIRY { '15 minutes' }
sub get_default_PG_PIXIE_DSN      { 'dbi:mysql:dbname=pangloss' }

sub get_default_PG_CONFIG_FILE {
    my $self = shift;
    return catfile( $self->{PG_HOME}, 'conf', 'controller.yml' );
}

sub get_default_PG_TEMPLATE_DIR {
    my $self = shift;
    return catfile( $self->{PG_HOME}, 'web' );
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

Configuration hash for Pangloss, implemented as a singleton.

=head1 CONFIG VARS

 Config Variable     [ default value ]
 ----------------------------------------------------
 PG_DEBUG            [ 0 ]
 PG_HOME             [ /path/to/current/dir ]
 PG_CONFIG_FILE      [ $PG_HOME/conf/controller.yml ]
 PG_TEMPLATE_DIR     [ $PG_HOME/web ]
 PG_TEMPLATE_TYPE    [ petal ]
 PG_SESSION_TYPE     [ file_cache ]
 PG_SESSION_EXPIRY   [ 15 minutes ]
 PG_PIXIE_DSN        [ dbi:mysql:dbname=pangloss ]
 PG_PIXIE_USER       [ ]
 PG_PIXIE_PASS       [ ]

=head1 CONSTRUCTOR

=over 4

=item $class->new( [ $hash ] )

create a new Config singleton (unless one exists already) and return it.  If
the singleton is being created it is initialized with values from $hash,
otherwise the defaults are used.

=back

=head1 METHODS

=over 4

=item $obj = $obj->parse_hash( $hash )

set the config object's params from the hash given, or use the default value.

=item @vars = $obj->config_vars

get the list of config variables available.

=item $val = $obj->get_default_for( $config_var )

get the default value of the $config_var named.

=item $class = $class->set_default_for( $config_var => $code_ref )

set the default value of the $config_var to the $code_ref given.  The $code_ref
should expect the current object as its first param.

=back

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss>

=cut

