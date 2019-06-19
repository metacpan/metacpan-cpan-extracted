package Pg::Explain;
use v5.6;
use strict;
use autodie;
use Carp;
use Pg::Explain::StringAnonymizer;

=head1 NAME

Pg::Explain - Object approach at reading explain analyze output

=head1 VERSION

Version 0.80

=cut

our $VERSION = '0.80';

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
    my $self = bless {}, $class;
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

    if ( $source =~ m{^\s*<explain xmlns="http://www.postgresql.org/2009/explain">}m ) {
        require Pg::Explain::FromXML;
        $self->{ 'top_node' } = Pg::Explain::FromXML->new()->parse_source( $source );
    }
    elsif ( $source =~ m{ ^ (\s*) \[ \s* \n .*? \1 \] \s* }xms ) {
        require Pg::Explain::FromJSON;
        $self->{ 'top_node' } = Pg::Explain::FromJSON->new()->parse_source( $source );
    }
    elsif ( $source =~ m{ ^ (\s*) - \s+ Plan: \s* \n }xms ) {
        require Pg::Explain::FromYAML;
        $self->{ 'top_node' } = Pg::Explain::FromYAML->new()->parse_source( $source );
    }
    else {
        require Pg::Explain::FromText;
        $self->{ 'top_node' } = Pg::Explain::FromText->new()->parse_source( $source );
    }

    $self->{ 'top_node' }->check_for_parallelism();

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
    return $self->top_node->as_text();
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
