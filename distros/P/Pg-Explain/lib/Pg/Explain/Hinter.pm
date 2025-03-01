package Pg::Explain::Hinter;

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

use Pg::Explain::Hinter::Hint;

=head1 NAME

Pg::Explain::Hinter - Review Pg::Explain plans and return hints, if there are any

=head1 VERSION

Version 2.8

=cut

our $VERSION = '2.8';

=head1 SYNOPSIS

Given Pg::Explain plan, it will look at its nodes, and suggest what can be improved, if anything.

    my $hinter = Pg::Explain::Hinter->new( $plan );
    if ( $hinter->any_hints ) {
        print Dumper( $hinter->hints );
    } else {
        print "There are no hints for this plan.\n";
    }

Hints are Pg::Explain::Hinter::Hint objects.

=head1 FUNCTIONS

=head2 new

Object constructor.

=cut

sub new {
    my $class = shift;
    my $plan  = shift;
    croak( 'Given parameter is not Pg::Explain object!' ) unless 'Pg::Explain' eq ref $plan;
    my $self = bless {}, $class;
    $self->plan( $plan );
    $self->hints( [] );
    $self->calculate_hints();
    return $self;
}

=head2 plan

Accessor for plan inside hinter.

=cut

sub plan {
    my $self = shift;
    $self->{ 'plan' } = $_[ 0 ] if 0 < scalar @_;
    return $self->{ 'plan' };
}

=head2 hints

Accessor for hints inside hinter.

=cut

sub hints {
    my $self = shift;
    $self->{ 'hints' } = $_[ 0 ] if 0 < scalar @_;
    return $self->{ 'hints' };
}

=head2 any_hints

Returns 1 if there are any hints for provided plan, and undef if there are none.

=cut

sub any_hints {
    my $self = shift;
    return 1 if 0 < scalar @{ $self->hints };
    return;
}

=head2 calculate_hints

Main function checking if there are any things that could be hinted on.

=cut

sub calculate_hints {
    my $self = shift;
    return unless $self->plan->top_node->is_analyzed;

    for my $node ( $self->plan->top_node, $self->plan->top_node->all_recursive_subnodes ) {

        # If this node was not ran, we can't do anything about it.
        next unless $node->actual_loops;

        $self->check_hint_disk_sort( $node );
        $self->check_hint_indexable_seqscan_simple( $node );
        $self->check_hint_indexable_seqscan_multi_equal_and( $node );

    }

    return;
}

=head2 check_hint_disk_sort

Check if given node matches criteria for DISK_SORT hint

=cut

sub check_hint_disk_sort {
    my $self = shift;
    my $node = shift;
    return unless $node->type eq 'Sort';
    return unless $node->extra_info;
    for my $info ( @{ $node->extra_info } ) {
        next unless $info =~ m{\ASort Method:.*Disk:\s*(\d+)kB\s*\z};
        my $disk_used = $1;
        push @{ $self->{ 'hints' } }, Pg::Explain::Hinter::Hint->new(
            'node'    => $node,
            'type'    => 'DISK_SORT',
            'details' => [ $disk_used ],
        );
        last;
    }
    return;
}

=head2 check_hint_indexable_seqscan_simple

Check if given node matches criteria for INDEXABLE_SEQSCAN_SIMPLE hint

=cut

sub check_hint_indexable_seqscan_simple {
    my $self = shift;
    my $node = shift;

    return unless $node->type =~ m{\A(?:Parallel )?Seq Scan\z};
    return unless $node->estimated_row_width;
    return unless $node->total_rows_removed;
    return unless $node->extra_info;

    # At least 3 pages worth of data is processed
    return unless ( $node->total_rows + $node->total_rows_removed ) * $node->estimated_row_width > 3 * 8192;

    # At least 2/3rd of rows were removed
    return unless $node->total_rows_removed > $node->total_rows * 2;

    for my $line ( @{ $node->extra_info } ) {
        next unless $line =~ m{
            \A
            Filter: \s+ \(
                ("[^"]+"|[a-z0-9_]+)
                \s
                (=|<|>|>=|<=)
                \s
                (?:
                    ' (?: [^'] | '' ) * '
                    (?: :: (?: "[^"]+" | [a-z0-9_ ]+ ) )?
                    |
                    \d+
                )
            \)
            \z
        }xms;
        my ( $column_used, $operator ) = ( $1, $2 );
        push @{ $self->{ 'hints' } }, Pg::Explain::Hinter::Hint->new(
            'plan'    => $self->plan,
            'node'    => $node,
            'type'    => 'INDEXABLE_SEQSCAN_SIMPLE',
            'details' => [ $column_used, $operator ],
        );
        last;

    }
    my @filter_lines = grep { /^Filter:/ } @{ $node->extra_info };
    return if 1 != scalar @filter_lines;

}

=head2 check_hint_indexable_seqscan_multi_equal_and

Check if given node matches criteria for INDEXABLE_SEQSCAN_MULTI_EQUAL_AND hint

=cut

sub check_hint_indexable_seqscan_multi_equal_and {
    my $self = shift;
    my $node = shift;

    return unless $node->type =~ m{\A(?:Parallel )?Seq Scan\z};
    return unless $node->estimated_row_width;
    return unless $node->total_rows_removed;
    return unless $node->extra_info;

    # At least 3 pages worth of data is processed
    return unless ( $node->total_rows + $node->total_rows_removed ) * $node->estimated_row_width > 3 * 8192;

    # At least 2/3rd of rows were removed
    return unless $node->total_rows_removed > $node->total_rows * 2;

    # Filter: ((projet = 10317) AND (section = 29) AND (zone = 4))
    my $single_condition = qr{
        \(
        ("[^"]+"|[a-z0-9_]+)
        \s+
        =
        \s+
        (
            ' (?: [^'] | '' ) * '
            (?: :: (?: "[^"]+" | [a-z0-9_ ]+ ) )?
            |
            \d+
        )
        \)
    }xmso;

    for my $line ( @{ $node->extra_info } ) {
        next unless $line =~ m{
            \A
            Filter: \s+ \(
                (
                    ${single_condition}
                    (?:
                        \s+
                        AND
                        \s+
                        ${single_condition}
                    )+
                )
            \)
            \z
        }xms;
        my $all_conditions = $1;
        my @cols           = ();
        while ( $all_conditions =~ m{ ${single_condition} (?= \s+ AND \s+ | \z ) }xg ) {
            push @cols, { 'column' => $1, 'value' => $2 };
        }
        push @{ $self->{ 'hints' } }, Pg::Explain::Hinter::Hint->new(
            'plan'    => $self->plan,
            'node'    => $node,
            'type'    => 'INDEXABLE_SEQSCAN_MULTI_EQUAL_AND',
            'details' => [ sort { $a->{ 'column' } cmp $b->{ 'column' } } @cols ],
        );
        last;

    }
    my @filter_lines = grep { /^Filter:/ } @{ $node->extra_info };
    return if 1 != scalar @filter_lines;

}

=head1 AUTHOR

hubert depesz lubaczewski, C<< <depesz at depesz.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<depesz at depesz.com>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Pg::Explain::Node

=head1 COPYRIGHT & LICENSE

Copyright 2008-2023 hubert depesz lubaczewski, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of Pg::Explain::Hinter
