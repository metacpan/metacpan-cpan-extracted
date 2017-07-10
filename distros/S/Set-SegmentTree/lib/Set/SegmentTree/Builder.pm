package Set::SegmentTree::Builder;

use strict;
use warnings;

our $VERSION = '0.06';

use Carp qw/croak confess carp/;
use IO::File;
use Time::HiRes qw/gettimeofday/;
use File::Map qw/map_file/;
use List::Util qw/reduce/;
use Set::SegmentTree::ValueLookup;
use Readonly;

Readonly our $INTERVAL_ID        => 0;
Readonly our $INTERVAL_MIN       => 1;
Readonly our $INTERVAL_MAX       => 2;
Readonly our $ELEMENTARY_MIN     => 0;
Readonly our $ELEMENTARY_MAX     => 1;
Readonly our $TRUE               => 1;
Readonly our $MS_IN_NS           => 1000;
Readonly our $INTERVALS_PER_NODE => 2;

#########################
my $cc  = 0;
my $icc = 0;
#########################

sub new_instance {
    my ( $class, $options ) = @_;
    return bless { locked => 0, segment_list => [], %{ $options || {} } },
        $class;
}

sub build {
    my ($self) = @_;
    $self->build_tree( @{ $self->{segment_list} } );
    return Set::SegmentTree->deserialize( $self->serialize );
}

sub new {
    my ( $class, @list ) = @_;
    my $options = {};
    if ( 'HASH' eq ref @list ) { $options = pop @list; }
    return $class->new_instance($options)->insert(@list);
}

sub insert {
    my ( $self, @list ) = @_;
    confess 'This tree already built. Make a new one' if $self->{locked};
    push @{ $self->{segment_list} }, @list;
    return $self;
}

sub serialize {
    my ($self) = @_;
    confess 'Cannot serialized unlocked tree' if !$self->{locked};

    my $t = Set::SegmentTree::ValueLookup->new(
        root    => $self->{tree},
        nodes   => $self->{nodelist},
        created => time
    );
    return $t->serialize;
}

sub to_file {
    my ( $self, $outfile ) = @_;
    if ( !$self->{locked} ) {
        carp 'you asked for to_file without building first. '
            . 'Building now. This is expensive.'
            . $self->build;
    }
    my $out = IO::File->new( $outfile, '>:raw' );
    $out->print( $self->serialize );
    undef $out;
    return -s $outfile;
}

sub endpoint {
    my ( $self, $offset, $which ) = @_;
    return $self->{elist}->[$offset]->[$which];
}

sub endpoints {
    my ( $self, @endpoints ) = @_;
    my @list = sort { $a <=> $b }
        map { ( $_->[$INTERVAL_MIN], $_->[$INTERVAL_MAX] ) } @endpoints;
    return @list;
}

sub place_intervals {
    my ( $self, @intervals ) = @_;
    foreach my $node ( @{ $self->{nodelist} } ) {
        next if exists $node->{low};
        $node->{segments} = [
            map { $_->[$INTERVAL_ID] } grep {
                       $node->{min} >= $_->[$INTERVAL_MIN]
                    && $node->{max} <= $_->[$INTERVAL_MAX];
            } @intervals
        ];
    }
    return;
}

sub build_elementary_list {
    my ( $self, @segment_list ) = @_;
    my ($elementary) = reduce {
        my ( $d, $c ) = ( $a, $a );
        if ( 'ARRAY' ne ref $a ) {
            $d = [ [ $c, $c ], $c ];
        }
        $c = pop @{$d};
        [ @{$d}, [ $c, $b ], [ $b, $b ], $b ];
    }
    $self->endpoints(@segment_list);
    pop @{$elementary};    # extra bit
    $self->{elist} = $elementary;
    return $elementary;
}

sub build_tree {
    my ( $self, @segment_list ) = @_;
    if ( $self->{locked} ) {
        croak 'This tree is immutable. Build a new one.';
    }
    $self->{locked} = 1;
    my $elementary = $self->build_elementary_list(@segment_list);

    if ( $self->{verbose} ) {
        warn "Building binary tree\n";
    }
    my $st = gettimeofday;
    $self->{tree} = $self->build_binary( 0, $#{$elementary} );
    if ( $self->{verbose} ) {
        my $et = gettimeofday;
        warn "took $cc calls "
            . sprintf( '%0.3f', ( ( $et - $st ) * $MS_IN_NS ) / $cc )
            . ' ms per ('
            . ( $et - $st )
            . " elap)\n";
        warn "placing intervals...\n";
    }
    my $ist = gettimeofday;
    $self->place_intervals(@segment_list);
    my $iet = gettimeofday;
    warn "took $icc segment placements "
        . sprintf( '%0.3f', ( ( $iet - $ist ) * $MS_IN_NS ) / $icc )
        . ' ms per ('
        . ( $iet - $ist )
        . " elapsed)\n"
        if $self->{verbose};
    return $self;
}

# from being offset into elementary list
# to being offset into elementary list
sub build_binary {
    my ( $self, $from, $to ) = @_;
    $cc++;
    my $mid = int( ( $to - $from ) / $INTERVALS_PER_NODE ) + $from;
    my $node = {
        min => $self->endpoint( $from, $ELEMENTARY_MIN ),
        max => $self->endpoint( $to,   $ELEMENTARY_MAX ),
    };

    if ( $from != $to ) {
        $node->{low}  = $self->build_binary( $from,    $mid );
        $node->{high} = $self->build_binary( $mid + 1, $to );
    }
    push @{ $self->{nodelist} }, $node;
    return $#{ $self->{nodelist} };
}

1;
__END__

=head1 NAME

Set::SegmentTree::Builder - Builder for Segment Trees in Perl

=head1 SYNOPSIS

  use Test::More;
  my $builder = Set::SegmentTree::Builder->new(
    @segment_list, 
    {option => ovalue}
    );
  $builder->insert([ start, end, segment_name ], [ ... ]);
  isa_ok $builder->build(), 'Set::SegmentTree';
  $builder->to_file('filename');

=head1 DESCRIPTION

wat? L<Segment Tree|https://en.wikipedia.org/wiki/Segment_tree>

In the use case where 

1) you have a series of potentially overlapping segments
1) you need to know which segments encompass any particular value
1) the access pattern is almost exclusively read biased
1) need to shift between pre-built segment trees

The Segment Tree data structure allows you to resolve any single value to the
list of segments which encompass it in O(log(n)+nk) 

=head1 SUBROUTINES/METHODS

=over 4

=item new

  constructor for a new builder

  accepts a list of segments

  segments are three element array refs like this

  [ low value, high value, string identifier ]

=item insert

  allows incremental building if you don't have them all at once 

=item build

  creates a new segment tree object
  pass a list of intervals
  returns the tree object

  This may take quite some time!

=item to_file

  save the tree to a file
  Writes a google flatbuffer style file

=back

=head1 DIAGNOSTICS

extensive logging if you construct with option { verbose => 1 }

=head1 CONFIGURATION AND ENVIRONMENT

Written to require very little configuration or environment

Reacts to no environment variables.

=head2 EXPORT

None

=head1 SEE ALSO

Set::FlatBuffer
Data::FlatTables
File::Map

=head1 INCOMPATIBILITIES

A system with variant endian maybe?

=head1 DEPENDENCIES

Google Flatbuffers

=head1 BUGS AND LIMITATIONS

Only works with FlatBuffers for serialization

Subject the limitations of Data::FlatTables

Only stores keys for you to use to index into other structures
I like uuids for that.

The values for ranging are evaluated in numeric context, so using
non-numerics probably won't work

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2017 by David Ihnen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.22.1 or,
at your option, any later version of Perl 5 you may have available.

=head1 VERSION

0.06

=head1 AUTHOR

David Ihnen, E<lt>davidihnen@gmail.comE<gt>

=cut
