package Pg::Explain;

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

use Carp;
use Clone qw( clone );
use autodie;
use List::Util qw( sum uniq );
use Pg::Explain::StringAnonymizer;
use Pg::Explain::FromText;
use Pg::Explain::FromYAML;
use Pg::Explain::FromJSON;
use Pg::Explain::FromXML;

=head1 NAME

Pg::Explain - Object approach at reading explain analyze output

=head1 VERSION

Version 1.13

=cut

our $VERSION = '1.13';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Pg::Explain;

    my $explain = Pg::Explain->new('source_file' => 'some_file.out');
    ...

    my $explain = Pg::Explain->new(
        'source' => 'Seq Scan on tenk1  (cost=0.00..333.00 rows=10000 width=148)'
    );
    ...


=head1 FUNCTIONS

=head2 source_format

What is the detected format of source plan. One of: TEXT, JSON, YAML, OR XML.

=head2 planning_time

How much time PostgreSQL spent planning the query. In milliseconds.

=head2 total_buffers

All buffers used by query - for planning and execution. Mathematically: sum of planning_buffers and top_level->buffers.

=head2 planning_buffers

How much buffers PostgreSQL used for planning. Either undef or object of Pg::Explain::Buffers class.

=head2 execution_time

How much time PostgreSQL spent executing the query. In milliseconds.

=head2 total_runtime

How much time PostgreSQL spent working on this query. This was part of EXPLAIN OUTPUT only for PostgreSQL 9.3 or older.

=head2 trigger_times

Information about triggers that were called during execution of this query. Array of hashes, where each hash can contains:

=over

=item * name - name of the trigger

=item * calls - how many times it was called

=item * time - total time spent in all executions of this trigger

=back

=head2 jit

Contains information about JIT timings, as object of Pg::Explain::JIT class.

If there was no JIT info, it will return undef.

=head2 query

What query this explain is for. This is available only for auto-explain plans. If not available, it will be undef.

=head2 settings

If explain contains information about specific settings that were changed in Pg, this hashref will contain it.

If there are none - if will be undef.

=cut

sub source_format    { my $self = shift; $self->{ 'source_format' }    = $_[ 0 ] if 0 < scalar @_; return $self->{ 'source_format' }; }
sub planning_time    { my $self = shift; $self->{ 'planning_time' }    = $_[ 0 ] if 0 < scalar @_; return $self->{ 'planning_time' }; }
sub planning_buffers { my $self = shift; $self->{ 'planning_buffers' } = $_[ 0 ] if 0 < scalar @_; return $self->{ 'planning_buffers' }; }
sub execution_time   { my $self = shift; $self->{ 'execution_time' }   = $_[ 0 ] if 0 < scalar @_; return $self->{ 'execution_time' }; }
sub total_runtime    { my $self = shift; $self->{ 'total_runtime' }    = $_[ 0 ] if 0 < scalar @_; return $self->{ 'total_runtime' }; }
sub trigger_times    { my $self = shift; $self->{ 'trigger_times' }    = $_[ 0 ] if 0 < scalar @_; return $self->{ 'trigger_times' }; }
sub jit              { my $self = shift; $self->{ 'jit' }              = $_[ 0 ] if 0 < scalar @_; return $self->{ 'jit' }; }
sub query            { my $self = shift; $self->{ 'query' }            = $_[ 0 ] if 0 < scalar @_; return $self->{ 'query' }; }
sub settings         { my $self = shift; $self->{ 'settings' }         = $_[ 0 ] if 0 < scalar @_; return $self->{ 'settings' }; }

sub total_buffers {
    my $self = shift;
    if ( $self->top_node->buffers ) {
        return $self->top_node->buffers + $self->planning_buffers if $self->planning_buffers;
        return $self->top_node->buffers;
    }
    return $self->planning_buffers if $self->planning_buffers;
    return;
}

=head2 add_trigger_time

Adds new information about trigger time.

It will be available at $node->trigger_times (returns arrayref)

=cut

sub add_trigger_time {
    my $self = shift;
    if ( $self->trigger_times ) {
        push @{ $self->trigger_times }, @_;
    }
    else {
        $self->trigger_times( [ @_ ] );
    }
    return;
}

=head2 runtime

How long did the query run. Tries to get the value from various sources (total_runtime, execution_time, or top_node->actual_time_last).

=cut

sub runtime {
    my $self = shift;

    return $self->total_runtime // $self->execution_time // $self->top_node->actual_time_last;
}

=head2 node

Returns node with given id from current explain.

If there is second argument present, and it's Pg::Explain::Node object, it sets internal cache for this id and this node.

=cut

sub node {
    my $self = shift;
    my $id   = shift;
    return unless defined $id;
    my $node = shift;
    $self->{ 'node_by_id' }->{ $id } = $node if defined $node;
    return $self->{ 'node_by_id' }->{ $id };
}

=head2 source

Returns original source (text version) of explain.

=cut

sub source {
    return shift->{ 'source' };
}

=head2 source_filtered

Returns filtered source explain.

Currently there are only two filters:

=over

=item * remove quotes added by pgAdmin3

=item * remove + character at the end of line, added by default psql config.

=back

=cut

sub source_filtered {
    my $self = shift;

    my $filtered = '';

    # use default variable, to avoid having to type variable name in all regexps below
    for ( split /\r?\n/, $self->source ) {

        # Remove separator lines from various types of borders
        next if /^\+-+\+\z/;
        next if /^[-─═]+\z/;
        next if /^(?:├|╟|╠|╞)[─═]+(?:┤|╢|╣|╡)\z/;

        # Remove more horizontal lines
        next if /^\+-+\+\z/;
        next if /^└─+┘\z/;
        next if /^╚═+╝\z/;
        next if /^┌─+┐\z/;
        next if /^╔═+╗\z/;

        # Remove frames around, handles |, ║, │
        s/^(\||║|│)(.*)\1\z/$2/;

        # Remove quotes around lines, both ' and "
        s/^(["'])(.*)\1\z/$2/;

        # Remove "+" line continuations
        s/\s*\+\z//;

        # Remove "↵" line continuations
        s/\s*↵\z//;

        # Remove "query plan" header
        next if /^\s*QUERY PLAN\s*\z/;

        # Remove rowcount
        next if /^\(\d+ rows?\)\z/;

        # Accumulate filtered source
        $filtered .= $_ . "\n";
    }

    return $filtered;
}

=head2 new

Object constructor.

Takes one of (only one!) (source, source_file) parameters, and either parses it from given source, or first reads given file.

=cut

sub new {
    my $class = shift;
    my $self  = bless {}, $class;
    my %args;
    if ( 0 == scalar @_ ) {
        croak( 'One of (source, source_file) parameters has to be provided)' );
    }
    if ( 1 == scalar @_ ) {
        if ( 'HASH' eq ref $_[ 0 ] ) {
            %args = @{ $_[ 0 ] };
        }
        else {
            croak( 'One of (source, source_file) parameters has to be provided)' );
        }
    }
    elsif ( 1 == ( scalar( @_ ) % 2 ) ) {
        croak( 'One of (source, source_file) parameters has to be provided)' );
    }
    else {
        %args = @_;
    }

    if ( $args{ 'source_file' } ) {
        croak( 'Only one of (source, source_file) parameters has to be provided)' ) if $args{ 'source' };
        $self->{ 'source_file' } = $args{ 'source_file' };
        $self->_read_source_from_file();
    }
    elsif ( $args{ 'source' } ) {
        if ( Encode::is_utf8( $args{ 'source' } ) ) {
            $self->{ 'source' } = $args{ 'source' };
        }
        else {
            $self->{ 'source' } = decode( 'UTF-8', $args{ 'source' } );
        }
    }
    else {
        croak( 'One of (source, source_file) parameters has to be provided)' );
    }

    # Initialize jit to undef
    $self->{ 'jit' } = undef;

    # Initialize node_by_id hash to empty
    $self->{ 'node_by_id' } = {};

    return $self;
}

=head2 top_node

This method returns the top node of parsed plan.

For example - in this plan:

                           QUERY PLAN
 --------------------------------------------------------------
  Limit  (cost=0.00..0.01 rows=1 width=4)
    ->  Seq Scan on test  (cost=0.00..14.00 rows=1000 width=4)

top_node is Pg::Explain::Node element with type set to 'Limit'.

Generally every output of plans should start with ->top_node(), and descend
recursively in it, using subplans(), initplans() and sub_nodes() methods.

=cut

sub top_node {
    my $self = shift;
    $self->parse_source() unless $self->{ 'top_node' };
    return $self->{ 'top_node' };
}

=head2 parse_source

Internally (from ->BUILD()) called function which checks which parser to use
(text, json, xml, yaml), runs appropriate function, and stores top level
node in $self->top_node.

=cut

sub parse_source {
    my $self = shift;

    my $source = $self->source_filtered;

    my $parser;

    if ( $source =~ m{^\s*<explain xmlns="http://www.postgresql.org/2009/explain">}m ) {

        # Format used by both explain command and autoexplain module
        $self->{ 'source_format' } = 'XML';
        $parser = Pg::Explain::FromXML->new();
    }
    elsif ( $source =~ m{ ^ \s* \[ \s* \{ \s* "Plan" \s* : \s* \{ }xms ) {

        # Format used by explain command
        $self->{ 'source_format' } = 'JSON';
        $parser = Pg::Explain::FromJSON->new();
    }
    elsif ( $source =~ m{ ^ \s* \{ \s* "Query \s+ Text" \s* : \s* ".*", \s* "Plan" \s* : \s* \{ .* \} \s* \z }xms ) {

        # Format used by autoexplain module
        $self->{ 'source_format' } = 'JSON';
        $parser = Pg::Explain::FromJSON->new();
    }
    elsif ( $source =~ m{ ^ \s* - \s+ Plan: \s* \n }xms ) {

        # Format used by explain command
        $self->{ 'source_format' } = 'YAML';
        $parser = Pg::Explain::FromYAML->new();
    }
    elsif ( $source =~ m{ ^ \s* Query \s+ Text: \s+ ".*" \s+ Plan: \s* \n }xms ) {

        # Format used by autoexplain module
        $self->{ 'source_format' } = 'YAML';
        $parser = Pg::Explain::FromYAML->new();
    }
    else {
        # Format used by both explain command and autoexplain module
        $self->{ 'source_format' } = 'TEXT';
        $parser = Pg::Explain::FromText->new();
    }

    $parser->explain( $self );

    $self->{ 'top_node' } = $parser->parse_source( $source );

    $self->check_for_parallelism();

    $self->check_for_exclusive_time_fixes();

    return;
}

=head2 check_for_exclusive_time_fixes

Certain types of nodes (CTE Scans, and InitPlans) can cause issues with "naive" calculations of node exclusive time.

To fix that whole tree will be scanned, and, if neccessary, node->exclusive_fix will be modified.

=cut

sub check_for_exclusive_time_fixes {
    my $self = shift;
    $self->check_for_exclusive_time_fixes_cte();
    $self->check_for_exclusive_time_fixes_init();
}

=head2 check_for_exclusive_time_fixes_cte

Modifies node->exclusive_fix according to times that were used by CTEs.

=cut

sub check_for_exclusive_time_fixes_cte {
    my $self = shift;

    # Safeguard against endless loop in some edge cases.
    return unless defined $self->{ 'top_node' };

    # There is no point in checking if the plan is not analyzed.
    return unless $self->top_node->is_analyzed;

    # Find nodes that have any ctes in them
    my @nodes_with_cte = grep { $_->ctes && 0 < scalar keys %{ $_->ctes } } ( $self->top_node, $self->top_node->all_recursive_subnodes );

    # For each node with cte in it...
    for my $node ( @nodes_with_cte ) {

        # Find all nodes that are 'CTE Scan' - from given node, and all of its subnodes (recursively)
        my @cte_scans = grep { $_->type eq 'CTE Scan' } ( $node, $node->all_recursive_subnodes );
        next if 0 == scalar @cte_scans;

        # Iterate over defined ctes
        while ( my ( $cte_name, $cte_node ) = each %{ $node->ctes } ) {

            # Find all CTE Scans that were scanning current CTE
            my @matching_cte_scans = grep { $_->scan_on->{ 'cte_name' } eq $cte_name } @cte_scans;
            next if 0 == scalar @matching_cte_scans;

            # How much time did Pg spend in given CTE itself
            my $cte_total_time = $cte_node->total_inclusive_time;

            # How much time did all the CTE Scans used
            my $total_time_of_scans = sum( map { $_->total_inclusive_time // 0 } @matching_cte_scans );

            # Don't fail on divide by 0, and don't warn on undef
            next unless $total_time_of_scans;
            next unless $cte_total_time;

            # Subtract exclusive time proportionally.
            for my $scan ( grep { $_->total_inclusive_time } @matching_cte_scans ) {
                $scan->exclusive_fix( $scan->exclusive_fix - ( $scan->total_inclusive_time / $total_time_of_scans ) * $cte_total_time );
            }
        }
    }
    return;
}

=head2 check_for_exclusive_time_fixes_init

Modifies node->exclusive_fix according to times that were used by InitScans.

=cut

sub check_for_exclusive_time_fixes_init {
    my $self = shift;

    # Safeguard against endless loop in some edge cases.
    return unless defined $self->{ 'top_node' };

    # There is no point in checking if the plan is not analyzed.
    return unless $self->top_node->is_analyzed;

    # Find nodes that have any init plans in them
    my @nodes_with_init = grep { $_->initplans && 0 < scalar @{ $_->initplans } } ( $self->top_node, $self->top_node->all_recursive_subnodes );

    # Check them all, one by one, to build "init-plan-visibility" info
    for my $parent ( @nodes_with_init ) {

        # Nodes that see what initplan returned even if they don't refer to returned $*
        my @all_implicits      = map { $_->id } ( $parent, $parent->all_recursive_subnodes );
        my %skip_self_implicit = ();

        # Scan all initplans
        for my $idx ( 0 .. $#{ $parent->initplans } ) {
            my $initnode = $parent->initplans->[ $idx ];

            # There is no point in adjusting things for no-time.
            next unless $initnode->total_inclusive_time;

            # Place to store implicit and explicit nodes
            my @implicitnodes = ();
            my @explicitnodes = ();

            my $explicit_re;

            # If there is metainfo, we can build regexp to find nodes explicitly using this init
            if ( $parent->initplans_metainfo->[ $idx ] ) {

                # List of $* variables that this initplan returns
                my $returns_string  = $parent->initplans_metainfo->[ $idx ]->{ 'returns' };
                my @returns_numbers = ();
                for my $element ( split /,/, $returns_string ) {
                    push @returns_numbers, $element if $element =~ s/\A\$(\d+)\z/$1/;
                }
                my $returns = join( '|', @returns_numbers );

                # Regular expression to check in extra-info for nodes.
                $explicit_re = qr{\$(?:${returns})(?!\d)};
            }

            # Add current node, and it's kids to skip list
            for my $skip_node ( $initnode, $initnode->all_recursive_subnodes ) {
                $skip_self_implicit{ $skip_node->id } = 1;
            }

            # Iterate over all nodes that could have used data from this initplan
            for my $user_id ( grep { !$skip_self_implicit{ $_ } } @all_implicits ) {

                my $user = $self->node( $user_id );

                # Add node to implicit ones,always
                push @implicitnodes, $user;

                # If there is explicit_re, try to find what is using this int explicitly
                next unless $explicit_re;
                next unless $user->extra_info;
                my $full_extra_info = join( "\n", @{ $user->extra_info } );
                push @explicitnodes, $user if $full_extra_info =~ $explicit_re;
            }

            # Total times
            my $implicittime = sum( map { $_->total_exclusive_time // 0 } @implicitnodes ) // 0;
            my $explicittime = sum( map { $_->total_exclusive_time // 0 } @explicitnodes ) // 0;

            # Where to adjusct exclusive time
            my @adjust_these = ();
            my $ratio;
            if (   ( 0 < scalar @explicitnodes )
                && ( $explicittime > $initnode->total_inclusive_time ) )
            {
                @adjust_these = @explicitnodes;
                $ratio        = $initnode->total_inclusive_time / $explicittime;
            }
            elsif ( $implicittime > $initnode->total_inclusive_time ) {
                @adjust_these = @implicitnodes;
                $ratio        = $initnode->total_inclusive_time / $implicittime;
            }

            # Actually adjust exclusive times
            for my $node ( @adjust_these ) {
                next unless $node->total_exclusive_time;
                my $adjust = $ratio * $node->total_exclusive_time;
                $node->exclusive_fix( $node->exclusive_fix - $adjust );
            }
        }
    }

    return;
}

=head2 check_for_parallelism

Handles parallelism by setting "force_loops" if plan is analyzed and there are gather nodes.

Generally, for each 

=cut

sub check_for_parallelism {
    my $self = shift;

    # Safeguard against endless loop in some edge cases.
    return unless defined $self->{ 'top_node' };

    # There is no point in checking if the plan is not analyzed.
    return unless $self->top_node->is_analyzed;

    # @nodes will contain list of nodes to check if they are Gather
    my @nodes = ( [ 1, $self->top_node ] );

    while ( my $node_info = shift @nodes ) {

        my $workers = $node_info->[ 0 ];
        my $node    = $node_info->[ 1 ];

        # Set workers.
        $node->workers( $workers );

        # These sub-nodes don't get workers.
        push @nodes, map { [ $workers, $_ ] } @{ $node->initplans }   if $node->initplans;
        push @nodes, map { [ $workers, $_ ] } @{ $node->subplans }    if $node->subplans;
        push @nodes, map { [ $workers, $_ ] } values %{ $node->ctes } if $node->ctes;

        # If there are workers launched, set it as new workers value for recursive set.
        $workers = 1 + $node->workers_launched if defined $node->workers_launched;

        # These things get new workers
        push @nodes, map { [ $workers, $_ ] } @{ $node->sub_nodes } if $node->sub_nodes;
    }
    return;
}

=head2 _read_source_from_file

Helper function to read source from file.

=cut

sub _read_source_from_file {
    my $self = shift;

    open my $fh, '<', $self->{ 'source_file' };
    local $/ = undef;
    my $content = <$fh>;
    close $fh;

    delete $self->{ 'source_file' };
    $self->{ 'source' } = $content;

    return;
}

=head2 as_text

Returns parsed plan back as plain text format (regenerated from in-memory structure).

This is mostly useful for (future at the moment) anonymizations.

=cut

sub as_text {
    my $self = shift;

    my $textual = $self->top_node->as_text();

    if ( $self->planning_buffers ) {
        $textual .= "Planning:\n";
        my $buf_info = $self->planning_buffers->as_text;
        $buf_info =~ s/^/  /gm;
        $textual .= $buf_info . "\n";

    }
    if ( $self->planning_time ) {
        $textual .= "Planning time: " . $self->planning_time . " ms\n";
    }
    if ( $self->trigger_times ) {
        for my $t ( @{ $self->trigger_times } ) {
            $textual .= sprintf( "Trigger %s: time=%.3f calls=%d\n", $t->{ 'name' }, $t->{ 'time' }, $t->{ 'calls' } );
        }
    }
    if ( $self->jit ) {
        $textual .= $self->jit->as_text();
    }
    if ( $self->execution_time ) {
        $textual .= "Execution time: " . $self->execution_time . " ms\n";
    }
    if ( $self->total_runtime ) {
        $textual .= "Total runtime: " . $self->total_runtime . " ms\n";
    }

    return $textual;
}

=head2 get_struct

Function which returns simple, not blessed, hashref with all information about the explain.

This can be used for debug purposes, or as a base to print information to user.

Output looks like this:

 {
     'top_node'               => {...}
     'planning_time'          => '12.34',
     'planning_buffers'       => {...},
     'execution_time'         => '12.34',
     'total_runtime'          => '12.34',
     'trigger_times'          => [
        { 'name' => ..., 'time' => ..., 'calls' => ... },
        ...
     ],
 }

=cut

sub get_struct {
    my $self  = shift;
    my $reply = {};
    $reply->{ 'top_node' }         = $self->top_node->get_struct;
    $reply->{ 'planning_time' }    = $self->planning_time                if $self->planning_time;
    $reply->{ 'planning_buffers' } = $self->planning_buffers->get_struct if $self->planning_buffers;
    $reply->{ 'execution_time' }   = $self->execution_time               if $self->execution_time;
    $reply->{ 'total_runtime' }    = $self->total_runtime                if $self->total_runtime;
    $reply->{ 'trigger_times' }    = clone( $self->trigger_times )       if $self->trigger_times;
    $reply->{ 'query' }            = $self->query                        if $self->query;
    $reply->{ 'settings' }         = $self->settings                     if $self->settings;

    if ( $self->jit ) {
        $reply->{ 'jit' }                  = {};
        $reply->{ 'jit' }->{ 'functions' } = $self->jit->functions;
        $reply->{ 'jit' }->{ 'options' }   = clone( $self->jit->options );
        $reply->{ 'jit' }->{ 'timings' }   = clone( $self->jit->timings );
    }
    return $reply;
}

=head2 anonymize

Used to remove all individual values from the explain, while still retaining
all values that are needed to see what's wrong.

If there are any arguments, these are treated as strings, anonymized using
anonymizer used for plan, and are returned in the same order.

This is mainly useful to anonymize queries.

=cut

sub anonymize {
    my $self       = shift;
    my @extra_args = @_;

    my $anonymizer = Pg::Explain::StringAnonymizer->new();
    $self->top_node->anonymize_gathering( $anonymizer );
    $anonymizer->finalize();
    $self->top_node->anonymize_substitute( $anonymizer );

    return if 0 == scalar @extra_args;

    return map { $anonymizer->anonymize_text( $_ ) } @extra_args;
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

1;    # End of Pg::Explain
