#!/usr/bin/env perl
package ErrorDoom; 

use Moose;
use Moose::Util::TypeConstraints;

with 'MooseX::Getopt::Usage';
with 'MooseX::Getopt::Usage::Role::Man';

has verbose => ( is => 'ro', isa => 'Bool' );

has doom => ( is => 'ro', isa => 'Int' );

subtype 'OnOffAuto'
    => as 'Str'
    => where { m/^on|off|auto$/i }
    => message { "value '$_' is not one of on,off,auto" };

has missile_launchers => ( is => 'rw', isa => 'OnOffAuto', default => 'auto' );

=pod

=head1 NAME

errors.pl - Used by basic.t to test error handling.

=cut

1;

package main;
ErrorDoom->new_with_options;
