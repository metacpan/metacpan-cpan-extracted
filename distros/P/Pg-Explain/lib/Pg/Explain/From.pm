package Pg::Explain::From;

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

use Pg::Explain::Node;
use Pg::Explain::Buffers;
use Carp;

=head1 NAME

Pg::Explain::From - Base class for parsers of non-text explain formats.

=head1 VERSION

Version 2.6

=cut

our $VERSION = '2.6';

=head1 SYNOPSIS

It's internal class to wrap some work. It should be used by Pg::Explain, and not directly.

=head1 FUNCTIONS

=head2 new

Object constructor.

=cut

sub new {
    my $class = shift;
    my $self  = bless {}, $class;
    return $self;
}

=head2 explain

Get/Set master explain object.

=cut

sub explain { my $self = shift; $self->{ 'explain' } = $_[ 0 ] if 0 < scalar @_; return $self->{ 'explain' }; }

=head2 parse_source

Function which parses actual plan, and constructs Pg::Explain::Node objects
which represent it.

Returns Top node of query plan.

=cut

sub parse_source {
    my $self = shift;
    croak( 'This method ( parse_source ) should be overriden in child class!' );
}

=head2 normalize_node_struct

Simple function to let subclasses change the real keys that should be used when parsing structure.

This is (currently) useful only for XML parser.

=cut

sub normalize_node_struct {
    my $self   = shift;
    my $struct = shift;
    return $struct;
}

=head2 make_node_from

Converts single node from structure obtained from source into Pg::Explain::Node class.

Recurses when necessary to get subnodes.

=cut

sub make_node_from {
    my $self   = shift;
    my $struct = shift;

    $struct = $self->normalize_node_struct( $struct );

    my $use_type = $struct->{ 'Node Type' };
    if ( $use_type eq 'ModifyTable' ) {
        $use_type = $struct->{ 'Operation' };
        if ( $struct->{ 'Relation Name' } ) {
            $use_type .= ' on ' . $struct->{ 'Relation Name' };
            $use_type .= ' ' . $struct->{ 'Alias' } if ( $struct->{ 'Alias' } ) && ( $struct->{ 'Alias' } ne $struct->{ 'Relation Name' } );
        }

    }
    elsif ( $use_type eq 'Aggregate' ) {
        my $strategy = $struct->{ 'Strategy' } || 'Plain';
        $use_type = 'HashAggregate'  if $strategy eq 'Hashed';
        $use_type = 'GroupAggregate' if $strategy eq 'Sorted';
        $use_type = 'MixedAggregate' if $strategy eq 'Mixed';
    }
    if ( ( $struct->{ 'Scan Direction' } || '' ) eq 'Backward' ) {
        $use_type .= ' Backward';
    }

    my $new_node = Pg::Explain::Node->new(
        'type'                   => $use_type,
        'estimated_startup_cost' => $struct->{ 'Startup Cost' },
        'estimated_total_cost'   => $struct->{ 'Total Cost' },
        'estimated_rows'         => $struct->{ 'Plan Rows' },
        'estimated_row_width'    => $struct->{ 'Plan Width' },
        'actual_time_first'      => $struct->{ 'Actual Startup Time' },
        'actual_time_last'       => $struct->{ 'Actual Total Time' },
        'actual_rows'            => $struct->{ 'Actual Rows' },
        'actual_loops'           => $struct->{ 'Actual Loops' },
    );
    $new_node->explain( $self->explain );

    if (   ( defined $struct->{ 'Actual Startup Time' } )
        && ( !$struct->{ 'Actual Loops' } ) )
    {
        $new_node->never_executed( 1 );
    }

    if ( $struct->{ 'Node Type' } =~ m{\A(?:Seq Scan|Bitmap Heap Scan)$} ) {
        $new_node->scan_on(
            {
                'table_name'  => $struct->{ 'Relation Name' },
                'table_alias' => $struct->{ 'Alias' },
            }
        );
    }
    elsif ( $struct->{ 'Node Type' } eq 'Function Scan' ) {
        $new_node->scan_on(
            {
                'function_name'  => $struct->{ 'Function Name' },
                'function_alias' => $struct->{ 'Alias' },
            }
        );
    }
    elsif ( $struct->{ 'Node Type' } eq 'Bitmap Index Scan' ) {
        $new_node->scan_on(
            {
                'index_name' => $struct->{ 'Index Name' },
            }
        );

    }
    elsif ( $struct->{ 'Node Type' } =~ m{\AIndex(?: Only)? Scan(?: Backward)?\z} ) {
        $new_node->scan_on(
            {
                'table_name'  => $struct->{ 'Relation Name' },
                'table_alias' => $struct->{ 'Alias' },
                'index_name'  => $struct->{ 'Index Name' },
            }
        );
    }
    elsif ( $struct->{ 'Node Type' } eq 'CTE Scan' ) {
        $new_node->scan_on(
            {
                'cte_name'  => $struct->{ 'CTE Name' },
                'cte_alias' => $struct->{ 'Alias' },
            }
        );
    }
    elsif ( $struct->{ 'Node Type' } eq 'Subquery Scan' ) {
        $new_node->scan_on(
            {
                'subquery_name' => $struct->{ 'Alias' },
            }
        );
    }
    elsif ( $struct->{ 'Node Type' } eq 'WorkTable Scan' ) {
        $new_node->scan_on(
            {
                'worktable_name'  => $struct->{ 'CTE Name' },
                'worktable_alias' => $struct->{ 'Alias' },
            }
        );
    }

    if ( $struct->{ 'Group Key' } ) {
        my $key = join( ', ', @{ $struct->{ 'Group Key' } } );
        $new_node->add_extra_info( 'Group Key: ' . $key );
    }

    if ( $struct->{ 'Grouping Sets' } ) {
        for my $set ( @{ $struct->{ 'Grouping Sets' } } ) {
            for my $hk ( @{ $set->{ 'Hash Keys' } } ) {
                $new_node->add_extra_info( 'Hash Key: ' . join( ', ', @{ $hk } ) );
            }
            for my $gk ( @{ $set->{ 'Group Keys' } } ) {
                $new_node->add_extra_info( 'Group Key: (' . join( ', ', @{ $gk } ) . ')' );
            }
        }
    }

    $new_node->add_extra_info( 'Workers Planned: ' . $struct->{ 'Workers Planned' } ) if $struct->{ 'Workers Planned' };
    if ( $struct->{ 'Workers Launched' } ) {
        $new_node->workers_launched( $struct->{ 'Workers Launched' } );
        $new_node->add_extra_info( 'Workers Launched: ' . $struct->{ 'Workers Launched' } );
    }

    if ( $struct->{ 'Recheck Cond' } ) {
        $new_node->add_extra_info( 'Recheck Cond: ' . $struct->{ 'Recheck Cond' } );
        if ( $struct->{ 'Rows Removed by Index Recheck' } ) {
            $new_node->add_extra_info( 'Rows Removed by Index Recheck: ' . $struct->{ 'Rows Removed by Index Recheck' } );
        }
    }

    if ( $struct->{ 'Join Filter' } ) {
        $new_node->add_extra_info( 'Join Filter: ' . $struct->{ 'Join Filter' } );
        if ( $struct->{ 'Rows Removed by Join Filter' } ) {
            $new_node->add_extra_info( 'Rows Removed by Join Filter: ' . $struct->{ 'Rows Removed by Join Filter' } );
        }
    }

    $new_node->add_extra_info( 'Index Cond: ' . $struct->{ 'Index Cond' } ) if $struct->{ 'Index Cond' };

    if ( $struct->{ 'Filter' } ) {
        $new_node->add_extra_info( 'Filter: ' . $struct->{ 'Filter' } );
        if ( defined $struct->{ 'Rows Removed by Filter' } ) {
            $new_node->add_extra_info( 'Rows Removed by Filter: ' . $struct->{ 'Rows Removed by Filter' } );
        }
    }

    if ( $struct->{ 'Node Type' } eq 'Sort' ) {
        if ( 'ARRAY' eq ref $struct->{ 'Sort Key' } ) {
            $new_node->add_extra_info( 'Sort Key: ' . join( ', ', @{ $struct->{ 'Sort Key' } } ) );
        }
        if ( $struct->{ 'Sort Method' } ) {
            $new_node->add_extra_info(
                sprintf 'Sort Method: %s %s: %dkB',
                $struct->{ 'Sort Method' }, $struct->{ 'Sort Space Type' }, $struct->{ 'Sort Space Used' }
            );
        }
    }

    $new_node->add_extra_info( 'Heap Fetches: ' . $struct->{ 'Heap Fetches' } ) if $struct->{ 'Heap Fetches' };

    my @heap_blocks_info = ();
    for my $type ( qw( exact lossy ) ) {
        my $key = ucfirst( $type ) . ' Heap Blocks';
        next unless $struct->{ $key };
        push @heap_blocks_info, sprintf '%s=%s', $type, $struct->{ $key };
    }
    $new_node->add_extra_info( 'Heap Blocks: ' . join( ' ', @heap_blocks_info ) ) if 0 < scalar @heap_blocks_info;

    my $buffers = Pg::Explain::Buffers->new( $struct );
    $new_node->buffers( $buffers ) if $buffers;

    if ( $struct->{ 'Conflict Resolution' } ) {
        $new_node->add_extra_info( 'Conflict Resolution: ' . $struct->{ 'Conflict Resolution' } );
        if ( $struct->{ 'Conflict Arbiter Indexes' } ) {
            $new_node->add_extra_info( 'Conflict Arbiter Indexes: ' . join( ', ', @{ $struct->{ 'Conflict Arbiter Indexes' } } ) );
        }
        if ( $struct->{ 'Conflict Filter' } ) {
            $new_node->add_extra_info( 'Conflict Filter: ' . $struct->{ 'Conflict Filter' } );
            if ( defined $struct->{ 'Rows Removed by Conflict Filter' } ) {
                $new_node->add_extra_info( 'Rows Removed by Conflict Filter: ' . $struct->{ 'Rows Removed by Conflict Filter' } );
            }
        }
    }

    $new_node->add_extra_info( 'Tuples Inserted: ' . $struct->{ 'Tuples Inserted' } ) if defined $struct->{ 'Tuples Inserted' };

    $new_node->add_extra_info( 'Conflicting Tuples: ' . $struct->{ 'Conflicting Tuples' } ) if defined $struct->{ 'Conflicting Tuples' };

    if ( $struct->{ 'Plans' } ) {
        my @plans;
        if ( 'HASH' eq ref $struct->{ 'Plans' } ) {
            push @plans, $struct->{ 'Plans' };
        }
        else {
            @plans = @{ $struct->{ 'Plans' } };
        }
        for my $subplan ( @plans ) {
            my $subnode             = $self->make_node_from( $subplan );
            my $parent_relationship = $subplan->{ 'Parent Relationship' } // '';
            if ( $parent_relationship eq 'InitPlan' ) {
                if ( $subplan->{ 'Subplan Name' } =~ m{ \A \s* CTE \s+ (\S+) \s* \z }xsm ) {
                    $new_node->add_cte( $1, $subnode );
                }
                elsif ( $subplan->{ 'Subplan Name' } =~ m{ \A InitPlan \s+ (\d+) \s+ \(returns \s+ ( .* )\) \z}xms ) {
                    $new_node->add_initplan(
                        $subnode,
                        {
                            'name'    => $1,
                            'returns' => $2,
                        }
                    );
                }
                else {
                    $new_node->add_initplan( $subnode );
                }
            }
            elsif ( $parent_relationship eq 'SubPlan' ) {
                $new_node->add_subplan( $subnode );
            }
            else {
                $new_node->add_sub_node( $subnode );
            }
        }
    }

    return $new_node;

}

=head1 AUTHOR

hubert depesz lubaczewski, C << <depesz at depesz.com> >>

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

1;    # End of Pg::Explain::From
