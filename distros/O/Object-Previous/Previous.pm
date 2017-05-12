package Object::Previous;

use strict;
use warnings;
use Carp;

require Exporter;
use base 'Exporter';

our $VERSION = "1.1012";
our @EXPORT = qw(previous_object); ## no critic

sub previous_object {};
sub import {
    if( @_==1 or $_[1] !~ m/(:?pure|perl|pl)/ ) {
        eval {
            require XSLoader;
            XSLoader::load('Object::Previous', $VERSION);
        };

        if( $@ ) {
            warn "couldn't load _xs version: $@";
            *previous_object = *previous_object_pl;

        } else {
            *previous_object = *previous_object_xs;
        }

    } else {
        splice @_, 1, 1;
        *previous_object = *previous_object_pl;
    }

    goto &Exporter::import;
}

sub previous_object_pl {
    my @foo = do { package DB; @DB::args=(); caller(2) }; ## no critic

    # NOTE: this doesn't work if, in that previous object, you were to do this:
    #
    #   unshift @_, "borked".
    #
    # The result is that you'd get "borked" instead of the blessed ref of the caller object

    # NOTE: I call this pure-perl vesion The Chromatic Way, but it's really the Devel::StackTrace way see:
    #  - http://perlmonks.org/?node_id=690713
    #  - http://perlmonks.org/?node_id=690795

    return $DB::args[0];
}

1;
