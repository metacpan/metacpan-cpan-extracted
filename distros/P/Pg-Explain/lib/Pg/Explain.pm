package Pg::Explain;
use v5.6;
use strict;
use autodie;
use Carp;
use Clone qw( clone );
use Data::Dumper;
use Pg::Explain::StringAnonymizer;
use Pg::Explain::FromText;
use Pg::Explain::FromYAML;
use Pg::Explain::FromJSON;
use Pg::Explain::FromXML;

=head1 NAME

Pg::Explain - Object approach at reading explain analyze output

=head1 VERSION

Version 0.96

=cut

our $VERSION = '0.96';

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

=cut

sub source_format  { my $self = shift; $self->{ 'source_format' }  = $_[ 0 ] if 0 < scalar @_; return $self->{ 'source_format' }; }
sub planning_time  { my $self = shift; $self->{ 'planning_time' }  = $_[ 0 ] if 0 < scalar @_; return $self->{ 'planning_time' }; }
sub execution_time { my $self = shift; $self->{ 'execution_time' } = $_[ 0 ] if 0 < scalar @_; return $self->{ 'execution_time' }; }
sub total_runtime  { my $self = shift; $self->{ 'total_runtime' }  = $_[ 0 ] if 0 < scalar @_; return $self->{ 'total_runtime' }; }
sub trigger_times  { my $self = shift; $self->{ 'trigger_times' }  = $_[ 0 ] if 0 < scalar @_; return $self->{ 'trigger_times' }; }

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
    my $self   = shift;
    my $source = $self->source;

    $source =~ s/^(["'])(.*)\1\r?\n/$2\n/gm;
    $source =~ s/\s*\+\r?\n/\n/g;
    return $source;
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
        $self->{ 'source' } = $args{ 'source' };
    }
    else {
        croak( 'One of (source, source_file) parameters has to be provided)' );
    }
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
        $self->{ 'source_format' } = 'XML';
        $parser = Pg::Explain::FromXML->new();
    }
    elsif ( $source =~ m{ ^ \s* \[ \s* \{ \s* "Plan" \s* : \s* \{ }xms ) {
        $self->{ 'source_format' } = 'JSON';
        $parser = Pg::Explain::FromJSON->new();
    }
    elsif ( $source =~ m{ ^ (\s*) - \s+ Plan: \s* \n }xms ) {
        $self->{ 'source_format' } = 'YAML';
        $parser = Pg::Explain::FromYAML->new();
    }
    else {
        $self->{ 'source_format' } = 'TEXT';
        $parser = Pg::Explain::FromText->new();
    }

    $parser->explain( $self );

    $self->{ 'top_node' } = $parser->parse_source( $source );

    $self->check_for_parallelism();

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

    if ( $self->planning_time ) {
        $textual .= "Planning time: " . $self->planning_time . " ms\n";
    }
    if ( $self->trigger_times ) {
        for my $t ( @{ $self->trigger_times } ) {
            $textual .= sprintf( "Trigger %s: time=%.3f calls=%d\n", $t->{ 'name' }, $t->{ 'time' }, $t->{ 'calls' } );
        }
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
     'top_node'               => {....},
     'planning_time'          => '12.34',
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
    $reply->{ 'top_node' }       = $self->top_node->get_struct;
    $reply->{ 'planning_time' }  = $self->planning_time if $self->planning_time;
    $reply->{ 'execution_time' } = $self->execution_time if $self->execution_time;
    $reply->{ 'total_runtime' }  = $self->total_runtime if $self->total_runtime;
    $reply->{ 'trigger_times' }  = clone( $self->trigger_times ) if $self->trigger_times;
    return $reply;
}

=head2 anonymize

Used to remove all individual values from the explain, while still retaining
all values that are needed to see what's wrong.

=cut

sub anonymize {
    my $self = shift;

    my $anonymizer = Pg::Explain::StringAnonymizer->new();
    $self->top_node->anonymize_gathering( $anonymizer );
    $anonymizer->finalize();
    $self->top_node->anonymize_substitute( $anonymizer );

    return;
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

1;    # End of Pg::Explain
