use strict;
use warnings;

package PIRTiny;
# ABSTRACT: PIR with Path::Tiny

# Dependencies
use Path::Tiny::Rule;
our @ISA = qw/Path::Tiny::Rule/;

use Path::Tiny ();

sub _objectify {
    my ( $self, $path ) = @_;
    return Path::Tiny::path($path);
}

sub _children {
    my $self = shift;
    my $path = shift;
    return map { [ $_->basename, $_ ] } $path->children;
}

sub _defaults {
    return ( $_[0]->SUPER::_defaults, _stringify => 0, );
}

sub _fast_defaults {
    return ( $_[0]->SUPER::_fast_defaults, _stringify => 0, );
}

