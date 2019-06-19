package Pg::Explain::FromJSON;
use strict;
use base qw( Pg::Explain::From );
use JSON;
use Carp;

=head1 NAME

Pg::Explain::FromJSON - Parser for explains in JSON format

=head1 VERSION

Version 0.80

=cut

our $VERSION = '0.80';

=head1 SYNOPSIS

It's internal class to wrap some work. It should be used by Pg::Explain, and not directly.

=head1 FUNCTIONS

=head2 parse_source

Function which parses actual plan, and constructs Pg::Explain::Node objects
which represent it.

Returns Top node of query plan.

=cut

sub parse_source {
    my $self   = shift;
    my $source = shift;
    my $prefix = '';

    # We need to remove things before and/or after explain
    # To do this, first - split explain into lines...
    my @source_lines = split( /[\r\n]+/, $source );
    my $prefix = '';

    # Now, find first line of explain, and cache it's prefix (some spaces ...)
    for my $l ( @source_lines ) {
        next unless $l =~ m{\A (\s*) \[ \s* \z }x;
        $prefix = $1;
    }

    # Now, extract lines with explain using known prefix
    my @use_lines = grep { /\A$prefix\[\s*\z/ .. /\A$prefix\]\s*\z/ } @source_lines;
    my $use_source = join( "\n", @use_lines );

    # And now parse the json...
    my $struct = from_json( $use_source );

    my $top_node = $self->make_node_from( $struct->[ 0 ]->{ 'Plan' } );

    return $top_node;
}

=head1 AUTHOR

hubert depesz lubaczewski, C<< <depesz at depesz.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<depesz at depesz.com>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Pg::Explain

=head1 COPYRIGHT & LICENSE

Copyright 2008-2015 hubert depesz lubaczewski, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of Pg::Explain::FromJSON
