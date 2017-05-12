package Monitoring::TT::Identifier;

use strict qw{vars subs};
use warnings;
use utf8;

#####################################################################

=head1 NAME

Monitoring::TT::Identifier - Identify Functions

=head1 DESCRIPTION

Helper to indentify functions of a module

=cut

#####################################################################

=head1 METHODS

=head2 functions

    functions(name)

    returns list of functions

=cut

sub functions {
    my($name) = @_;
    # Get all the CODE symbol table entries
    my @functions = sort grep { /\A[^\W\d]\w*\z/mxso }
        grep { defined &{"${name}::$_"} }
        keys %{"${name}::"};
    return \@functions;
}

#####################################################################

=head1 AUTHOR

Sven Nierlein, 2013, <sven.nierlein@consol.de>

=cut

1;
