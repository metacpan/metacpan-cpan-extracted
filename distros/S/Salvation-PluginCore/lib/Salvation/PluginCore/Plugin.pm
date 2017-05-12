package Salvation::PluginCore::Plugin;

use strict;
use warnings;

use base 'Salvation::PluginCore::Object';

use Salvation::Method::Signatures;

sub start {};

method new( Salvation::PluginCore :core!, Str{1,} :base_name! ) {

    $self = $self -> SUPER::new();
    $self -> { 'core' } = $core;
    $self -> { 'base_name' } = $base_name;

    $self -> start();

    return $self;
}

method load_plugin( Str{1,} :base_name!, Str{1,} :infix! ) {

    return $self -> core() -> load_plugin(
        base_name => $base_name,
        infix => sprintf( '%s::%s', $self -> base_name(), $infix ),
    );
}

method core() {

    return $self -> { 'core' };
}

method base_name() {

    return $self -> { 'base_name' };
}

1;

__END__
