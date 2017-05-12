package Query::Abstract::Driver::ArrayOfHashes;

our $VERSION = '0.01';

use v5.10;
use strict;
use warnings;

use Data::Dumper;

use base 'Query::Abstract::Driver::Base';

my %TESTERS = (
    'eq'   => sub { lc($_[0]) eq lc($_[1]) },
    'ne'   => sub { lc($_[0]) ne lc($_[1]) },
    'lt'   => sub { lc($_[0]) lt lc($_[1]) },
    'le'   => sub { lc($_[0]) le lc($_[1]) },
    'gt'   => sub { lc($_[0]) gt lc($_[1]) },
    'ge'   => sub { lc($_[0]) ge lc($_[1]) },
    '<'    => sub { $_[0] < $_[1] },
    '>'    => sub { $_[0] > $_[1] },
    '<='   => sub { $_[0] <= $_[1] },
    '>='   => sub { $_[0] >= $_[1] },
    'in'   => sub { scalar( grep { lc($_[0]) eq lc($_)} @{$_[1]} ) },
    'like' => sub {
        my ($value, $pattern) = @_;
        $pattern = join( '%', map { quotemeta($_) } split('\%', $pattern, -1 ) );
        $pattern =~ s/\%/.*/;
        return $value =~ m/^$pattern$/i;
    },

);

sub convert_query {
    my ($self, %query) = @_;

    my $tester_sub = $self->convert_filter( $query{where} );
    my $sort_sub   = $self->convert_sort( $query{sort_by} );

    return sub {
        my $array = shift;
        return [ sort $sort_sub grep {$tester_sub->($_)}  @$array];
    }
}


sub convert_filter {
    my ( $self, $where ) = @_;

    my @field_testers;
    for ( my $i = 0; $i < @$where; $i += 2 ) {
        my $field = $where->[$i];
        my $condition = $where->[$i+1];
        my ($oper, $restriction) = %$condition;

        push @field_testers, sub { $TESTERS{$oper}->( $_[0]->{$field}, $restriction ) }
    }

    return sub {
        my $hash = shift;
        @field_testers == grep { $_->($hash) } @field_testers
    };
}

sub convert_sort {
    my ( $self, $sort_by ) = @_;
    my @comparators;
    foreach my $sort_rule ( @$sort_by ) {
        my ($field, $order) = split(/\s+/, $sort_rule, 2);
        $order ||='ASC';

        my $field_comparator = uc($order) eq 'DESC'
            ? sub { $_[1]->{$field} cmp $_[0]->{$field} }
            : sub { $_[0]->{$field} cmp $_[1]->{$field} };

        push @comparators, $field_comparator;
    }

    return sub {
        foreach my $compar (@comparators) {
            my $res = $compar->($a, $b);
            return $res if $res != 0;
        }
        return 0;
    }
}

1;