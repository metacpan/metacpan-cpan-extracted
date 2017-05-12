#!/usr/bin/env perl
package Simple;

use Moose;
with 'MooseX::Getopt::Usage';
with 'MooseX::Getopt::Usage::Role::Man';

has doom => ( is => 'ro', isa => 'Int', required => 1 );
has stuff => ( is => 'rw', isa => 'String' );

sub getopt_usage_config {
    return (
        format => "%c : %r : %o : %a",
    );
}

=pod

=head1 DESCRIPTION

Make sure format strings %a, %r and %o expand properly.

=cut

1;

package main;
Simple->new_with_options;
