package Pg::Explain::FromYAML;

# UTF8 boilerplace, per http://stackoverflow.com/questions/6162484/why-does-modern-perl-avoid-utf-8-by-default/
use v5.18;
use strict;
use warnings;
use warnings qw( FATAL utf8 );
use utf8;
use open qw( :std :utf8 );
use Unicode::Normalize qw( NFC );
use Unicode::Collate;
use Encode qw( decode );

if ( grep /\P{ASCII}/ => @ARGV ) {
    @ARGV = map { decode( 'UTF-8', $_ ) } @ARGV;
}

# UTF8 boilerplace, per http://stackoverflow.com/questions/6162484/why-does-modern-perl-avoid-utf-8-by-default/

use base qw( Pg::Explain::From );
use YAML;
use Carp;
use Pg::Explain::JIT;
use Pg::Explain::Buffers;

=head1 NAME

Pg::Explain::FromYAML - Parser for explains in YAML format

=head1 VERSION

Version 1.11

=cut

our $VERSION = '1.11';

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

    # If this is plan from auto-explain
    if ( $source =~ s{ \A (\s*) Query \s+ Text : \s+ " ( [^\n]* ) " \s* \n }{}xms ) {
        my ( $prefix, $query ) = ( $1, $2 );

        # Change prefix to two spaces in all lines
        $source =~ s{^$prefix}{  }gm;

        # Add - to first line (should be Plan:)
        $source =~ s{ \A \s \s }{- }xms;

        $query =~ s/\\n/\n/g;
        $query =~ s/\\r/\r/g;
        $query =~ s/\\t/\t/g;
        $query =~ s/\\(.)/$1/g;
        $self->explain->query( $query );

    }

    unless ( $source =~ s{\A .*? ^ (\s*) ( - \s+ Plan: \s*\n )}{$1$2}xms ) {
        carp( 'Source does not match first s///' );
        return;
    }

    $source =~ s{ ^ ( \s* | [^\s-] [^\n] * ) \n .* \z }{}xms;

    my $struct = Load( $source )->[ 0 ];

    my $top_node = $self->make_node_from( $struct->{ 'Plan' } );

    if ( $struct->{ 'Planning' } ) {
        $self->explain->planning_time( $struct->{ 'Planning' }->{ 'Planning Time' } );
        my $buffers = Pg::Explain::Buffers->new( $struct->{ 'Planning' } );
        $self->explain->planning_buffers( $buffers ) if $buffers;
    }
    elsif ( $struct->{ 'Planning Time' } ) {
        $self->explain->planning_time( $struct->{ 'Planning Time' } );
    }
    $self->explain->execution_time( $struct->{ 'Execution Time' } ) if $struct->{ 'Execution Time' };
    $self->explain->total_runtime( $struct->{ 'Total Runtime' } )   if $struct->{ 'Total Runtime' };
    if ( $struct->{ 'Triggers' } ) {
        for my $t ( @{ $struct->{ 'Triggers' } } ) {
            my $ts = {};
            $ts->{ 'calls' }    = $t->{ 'Calls' }        if defined $t->{ 'Calls' };
            $ts->{ 'time' }     = $t->{ 'Time' }         if defined $t->{ 'Time' };
            $ts->{ 'relation' } = $t->{ 'Relation' }     if defined $t->{ 'Relation' };
            $ts->{ 'name' }     = $t->{ 'Trigger Name' } if defined $t->{ 'Trigger Name' };
            $self->explain->add_trigger_time( $ts );
        }
    }
    $self->explain->jit( Pg::Explain::JIT->new( 'struct' => $struct->{ 'JIT' } ) ) if $struct->{ 'JIT' };

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

Copyright 2008-2021 hubert depesz lubaczewski, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of Pg::Explain::FromYAML
