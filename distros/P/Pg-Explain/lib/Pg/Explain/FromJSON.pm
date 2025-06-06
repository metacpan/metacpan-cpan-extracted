package Pg::Explain::FromJSON;

# UTF8 boilerplace, per http://stackoverflow.com/questions/6162484/why-does-modern-perl-avoid-utf-8-by-default/
use v5.18;
use strict;
use warnings;
use warnings qw( FATAL utf8 );
use utf8;
use open qw( :std :utf8 );
use Unicode::Normalize qw( NFC );
use Unicode::Collate;
use Encode qw( encode decode );

if ( grep /\P{ASCII}/ => @ARGV ) {
    @ARGV = map { decode( 'UTF-8', $_ ) } @ARGV;
}

# UTF8 boilerplace, per http://stackoverflow.com/questions/6162484/why-does-modern-perl-avoid-utf-8-by-default/

use base qw( Pg::Explain::From );
use JSON::MaybeXS;
use Carp;
use Pg::Explain::JIT;
use Pg::Explain::Buffers;

=head1 NAME

Pg::Explain::FromJSON - Parser for explains in JSON format

=head1 VERSION

Version 2.9

=cut

our $VERSION = '2.9';

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
    my $source = encode( 'UTF-8', shift );

    # We need to remove things before and/or after explain
    # To do this, first - split explain into lines...
    my @source_lines = split( /[\r\n]+/, $source );

    if ( 1 < scalar @source_lines ) {

        # If there are many lines, there could be line prefix...
        my $prefix = undef;

        # Now, find first line of explain, and cache it's prefix (some spaces ...)
        for my $l ( @source_lines ) {
            next unless $l =~ m{\A (\s*) \[ \s* \z }x;
            $prefix = $1;
        }

        if ( defined $prefix ) {

            # Now, extract lines with explain using known prefix
            my @use_lines = grep { /\A$prefix\[\s*\z/ ... /\A$prefix\]\s*\z/ } @source_lines;
            $source = join( "\n", @use_lines );
        }
    }

    # And now parse the json...
    my $struct = decode_json( $source );
    if (   ( 'ARRAY' eq ref $struct )
        && ( defined $struct->[ 0 ]->{ 'Plan' } ) )
    {
        # This structure is used by normal "explain" command
        $struct = $struct->[ 0 ];
    }
    elsif (( 'HASH' eq ref $struct )
        && ( defined $struct->{ 'Plan' } ) )
    {
        # This structure is used by auto-explain command
        # empty command block, so I can have simple else condition
    }
    else {
        croak( 'Unknown JSON parsed' );
    }

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

    $self->explain->query( $struct->{ 'Query Text' } ) if $struct->{ 'Query Text' };

    $self->explain->settings( $struct->{ 'Settings' } ) if ( $struct->{ 'Settings' } ) && ( 0 < scalar keys %{ $struct->{ 'Settings' } } );

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

Copyright 2008-2023 hubert depesz lubaczewski, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of Pg::Explain::FromJSON
