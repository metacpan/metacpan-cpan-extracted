package Pg::Explain::FromText;
use strict;
use Carp;
use Pg::Explain::Node;

=head1 NAME

Pg::Explain::FromText - Parser for text based explains

=head1 VERSION

Version 0.80

=cut

our $VERSION = '0.80';

=head1 SYNOPSIS

It's internal class to wrap some work. It should be used by Pg::Explain, and not directly.

=head1 FUNCTIONS

=head2 new

Object constructor.

This is not really useful in this particular class, but it's to have the same API for all Pg::Explain::From* classes.

=cut

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    return $self;
}

=head2 parse_source

Function which parses actual plan, and constructs Pg::Explain::Node objects
which represent it.

Returns Top node of query plan.

=cut

sub parse_source {
    my $self   = shift;
    my $source = shift;

    my $top_node         = undef;
    my %element_at_depth = ();      # element is hashref, contains 2 keys: node (Pg::Explain::Node) and subelement-type, which can be: subnode, initplan or subplan.

    my @lines = split /\r?\n/, $source;

    my $costs_re   = qr{ \( cost=(?<estimated_startup_cost>\d+\.\d+)\.\.(?<estimated_total_cost>\d+\.\d+) \s+ rows=(?<estimated_rows>\d+) \s+ width=(?<estimated_row_width>\d+) \) }xms;
    my $analyze_re = qr{ \(
                            (?:
                                actual \s time=(?<actual_time_first>\d+\.\d+)\.\.(?<actual_time_last>\d+\.\d+) \s rows=(?<actual_rows>\d+) \s loops=(?<actual_loops>\d+)
                                |
                                actual \s rows=(?<actual_rows>\d+) \s loops=(?<actual_loops>\d+)
                                |
                                (?<never_executed> never \s+ executed )
                            )
                        \) }xms;

    LINE:
    for my $line ( @lines ) {

        # There could be stray " at the end. No idea why, but some people paste such explains on explain.depesz.com
        $line =~ s/"\z//;

        if (
            $line =~ m{
                \A
                (?<prefix>\s* -> \s* | \s* )
                (?<type>\S.*?)
                \s+
                (?:
                    $costs_re \s+ $analyze_re
                    |
                    $costs_re
                    |
                    $analyze_re
                )
                \s*
                \z
            }xms
           )
        {
            my $new_node = Pg::Explain::Node->new( %+ );
            if ( defined $+{ 'never_executed' } ) {
                $new_node->actual_loops( 0 );
                $new_node->never_executed( 1 );
            }
            my $element = { 'node' => $new_node, 'subelement-type' => 'subnode', };

            my $prefix_length = length $+{ 'prefix' };

            if ( 0 == scalar keys %element_at_depth ) {
                $element_at_depth{ $prefix_length } = $element;
                $top_node = $new_node;
                next LINE;
            }
            my @existing_depths = sort { $a <=> $b } keys %element_at_depth;
            for my $key ( grep { $_ >= $prefix_length } @existing_depths ) {
                delete $element_at_depth{ $key };
            }

            my $maximal_depth = ( sort { $b <=> $a } keys %element_at_depth )[ 0 ];
            my $previous_element = $element_at_depth{ $maximal_depth };

            $element_at_depth{ $prefix_length } = $element;

            if ( $previous_element->{ 'subelement-type' } eq 'subnode' ) {
                $previous_element->{ 'node' }->add_sub_node( $new_node );
            }
            elsif ( $previous_element->{ 'subelement-type' } eq 'initplan' ) {
                $previous_element->{ 'node' }->add_initplan( $new_node );
            }
            elsif ( $previous_element->{ 'subelement-type' } eq 'subplan' ) {
                $previous_element->{ 'node' }->add_subplan( $new_node );
            }
            elsif ( $previous_element->{ 'subelement-type' } =~ /^cte:(.+)$/ ) {
                $previous_element->{ 'node' }->add_cte( $1, $new_node );
                delete $element_at_depth{ $maximal_depth };
            }
            else {
                my $msg = "Bad subelement-type in previous_element - this shouldn't happen - please contact author.\n";
                croak( $msg );
            }

        }
        elsif ( $line =~ m{ \A (\s*) ((?:Sub|Init)Plan) \s* (?: \d+ \s* )? \s* (?: \( returns .* \) \s* )? \z }xms ) {
            my ( $prefix, $type ) = ( $1, $2 );

            my @remove_elements = grep { $_ >= length $prefix } keys %element_at_depth;
            delete @element_at_depth{ @remove_elements } unless 0 == scalar @remove_elements;

            my $maximal_depth = ( sort { $b <=> $a } keys %element_at_depth )[ 0 ];
            my $previous_element = $element_at_depth{ $maximal_depth };

            $element_at_depth{ length $prefix } = {
                'node'            => $previous_element->{ 'node' },
                'subelement-type' => lc $type,
            };
            next LINE;
        }
        elsif ( $line =~ m{ \A (\s*) CTE \s+ (\S+) \s* \z }xms ) {
            my ( $prefix, $cte_name ) = ( $1, $2 );

            my @remove_elements = grep { $_ >= length $prefix } keys %element_at_depth;
            delete @element_at_depth{ @remove_elements } unless 0 == scalar @remove_elements;

            my $maximal_depth = ( sort { $b <=> $a } keys %element_at_depth )[ 0 ];
            my $previous_element = $element_at_depth{ $maximal_depth };

            $element_at_depth{ length $prefix } = {
                'node'            => $previous_element->{ 'node' },
                'subelement-type' => 'cte:' . $cte_name,
            };

            next LINE;
        }
        elsif ( $line =~ m{ \A \s* (Planning|Execution) \s+ time: \s+ (\d+\.\d+) \s+ ms \s* \z }xmsi ) {
            my ( $type, $time ) = ( $1, $2 );
            next unless $top_node;
            $top_node->planning_time( $2 )  if 'planning' eq lc( $type );
            $top_node->execution_time( $2 ) if 'execution' eq lc( $type );
        }
        elsif ( $line =~ m{ \A \s* Trigger \s+ (.*) : \s+ time=(\d+\.\d+) \s+ calls=(\d+) \s* \z }xmsi ) {
            my ( $name, $time, $calls ) = ( $1, $2, $3 );
            next unless $top_node;
            $top_node->add_trigger_time(
                {
                    'name'  => $name,
                    'time'  => $time,
                    'calls' => $calls,
                }
            );
        }
        elsif ( $line =~ m{ \A (\s*) ( \S .* \S ) \s* \z }xms ) {
            my ( $infoprefix, $info ) = ( $1, $2 );
            my $maximal_depth = ( sort { $b <=> $a } grep { $_ < length $infoprefix } keys %element_at_depth )[ 0 ];
            next LINE unless defined $maximal_depth;
            my $previous_element = $element_at_depth{ $maximal_depth };
            next LINE unless $previous_element;
            $previous_element->{ 'node' }->add_extra_info( $info );
        }
    }
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

1;    # End of Pg::Explain::FromText
