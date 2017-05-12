package Parley::App::Error;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Parley::Version;  our $VERSION = $Parley::VERSION;

use Perl6::Export::Attrs;

sub has_errors :Export(:methods) {
    my ($c) = @_;

    return (exists $c->stash->{view}{error}{messages});
}

sub has_died :Export(:methods) {
    my ($c) = @_;

    return (
        exists $c->stash->{view}{error}{type}
           and $c->stash->{view}{error}{type} eq 'die'
    );
}


sub parley_warn :Export(:methods) {
    my ($c, $error_msg) = @_;

    # if we don't have an error "type" set it to warning
    $c->stash->{view}{error}{type} ||= q{warning};

    # push the incoming error onto the "error stack"
    push @{ $c->stash->{view}{error}{messages} },
        $error_msg;
}

sub parley_die :Export(:methods) {
    my ($c, $error_msg) = @_;

    # die overrides existing types
    $c->stash->{view}{error}{type} = q{die};

    # push the incoming error onto the "error stack"
    push @{ $c->stash->{view}{error}{messages} },
        $error_msg;
}

1;
