package Pg::Explain::FromYAML;
use strict;
use base qw( Pg::Explain::From );
use YAML;
use Carp;

=head1 NAME

Pg::Explain::FromYAML - Parser for explains in YAML format

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

    unless ( $source =~ s{\A .*? ^ (\s*) ( - \s+ Plan: \s*\n )}{$1$2}xms ) {
        carp( 'Source does not match first s///' );
        return;
    }
    $prefix = $1;

    $source =~ s{ ^ ( \s* | [^\s-] [^\n] * ) \n .* \z }{}xms;

    my $struct = Load( $source );

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

1;    # End of Pg::Explain::FromYAML
