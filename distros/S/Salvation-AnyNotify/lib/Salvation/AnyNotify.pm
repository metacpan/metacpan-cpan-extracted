package Salvation::AnyNotify;

use strict;
use warnings;

use base 'Salvation::PluginCore';

use Salvation::Method::Signatures;

our $VERSION = 0.01;
our $AUTOLOAD;

sub AUTOLOAD {

    my ( $self, @args ) = @_;
    my $autoload = $AUTOLOAD;

    return $self -> { $autoload } if exists $self -> { $autoload };

    my $plugin = ( $autoload =~ m/^.*::(.+?)$/ )[ 0 ];
    my $object = $self -> load_plugin( infix => 'Plugin', base_name => $plugin );

    die( "Failed to load plugin: ${plugin}" ) unless defined $object;

    return $self -> { $autoload } = $object;
}

1;

__END__
