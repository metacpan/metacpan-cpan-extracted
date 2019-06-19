package Pg::Explain::FromXML;
use strict;
use base qw( Pg::Explain::From );
use XML::Simple;
use Carp;

=head1 NAME

Pg::Explain::FromXML - Parser for explains in XML format

=head1 VERSION

Version 0.80

=cut

our $VERSION = '0.80';

=head1 SYNOPSIS

It's internal class to wrap some work. It should be used by Pg::Explain, and not directly.

=head1 FUNCTIONS

=head2 normalize_node_struct

XML structure is different than JSON/YAML (after parsing), so we need to normalize it.
=cut

sub normalize_node_struct {
    my $self   = shift;
    my $struct = shift;

    my @keys = keys %{ $struct };
    for my $key ( @keys ) {
        my $new_key = $key;
        $new_key =~ s/-/ /g;
        $struct->{ $new_key } = delete $struct->{ $key } if $key ne $new_key;
    }

    my $subplans = [];
    if (   ( $struct->{ 'Plans' } )
        && ( $struct->{ 'Plans' }->{ 'Plan' } ) )
    {
        if ( 'HASH' eq ref $struct->{ 'Plans' }->{ 'Plan' } ) {
            push @{ $subplans }, $struct->{ 'Plans' }->{ 'Plan' };
        }
        else {
            $subplans = $struct->{ 'Plans' }->{ 'Plan' };
        }
    }
    $struct->{ 'Plans' } = $subplans;

    return $struct;
}

=head2 parse_source

Function which parses actual plan, and constructs Pg::Explain::Node objects
which represent it.

Returns Top node of query plan.

=cut

sub parse_source {
    my $self   = shift;
    my $source = shift;

    unless ( $source =~ s{\A .*? ^ \s* (<explain \s+ xmlns="http://www.postgresql.org/2009/explain">) \s* $}{$1}xms ) {
        carp( 'Source does not match first s///' );
        return;
    }
    unless ( $source =~ s{^ \s* </explain> \s* $ .* \z}{</explain>}xms ) {
        carp( 'Source does not match second s///' );
        return;
    }

    my $struct = XMLin( $source );

    my $top_node = $self->make_node_from( $struct->{ 'Query' }->{ 'Plan' } );

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

1;    # End of Pg::Explain::FromXML
