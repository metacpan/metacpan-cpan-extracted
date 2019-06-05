package Search::QS::Filters;
$Search::QS::Filters::VERSION = '0.01';
use v5.14;
use Moose;
use Search::QS::Filter;

use feature 'switch';

extends 'Set::Array';

# ABSTRACT: A collection of L<Search::QS::Filter>


sub parse() {
    my $s       = shift;
    my $struct  = shift;


    while (my ($k,$v) = each $struct) {
        given($k) {
			when (/^flt\[(.*?)\]/)   { $s->_parse_filter($1, $v) }
		}
    }
}

sub _parse_filter {
    my $s   = shift;
    my $kt  = shift;
    my $val = shift;

    my ($key, $tag) = split(/:/,$kt);

    my $fltObj = new Search::QS::Filter(name => $key, tag => $tag);
    $fltObj->parse($val);
    $s->push($fltObj);
}

sub to_qs() {
    my $s = shift;
    return join('&', map($_->to_qs, $s->compact() ));
}

sub to_sql() {
    my $s = shift;
    my $groups = $s->as_groups;

    my $and = '';
    while (my ($k, $v) = each $groups->{and}) {
        $and .= ' ( ' . join (' AND ', map($_->to_sql, @$v)) . ' ) ';
        $and .= ' OR ';
    }
    # strip last OR
    $and = substr($and, 0, length($and)-4) if (length($and) >0);

    my $or = '';
    while (my ($k, $v) = each $groups->{or}) {
        $or .= ' ( ' . join (' OR ', map($_->to_sql, @$v)) . ' ) ';
        $or .= ' AND ';
    }
    # strip last AND
    $or = substr($or, 0, length($or)-5) if (length($or) >0);

    my $ret = join(' AND ', map($_->to_sql, @{$groups->{nogroup}}));

    $ret .= (length($ret) > 0 ? ' AND ' : '') . $and  if ($and);
    $ret .= (length($ret) > 0 ? ' AND ' : '') . $or if ($or);

    return $ret;
}
sub as_groups() {
    my $s = shift;
    my (%and, %or, @nogroup);
    $s->foreach(sub {
        given($_) {
            when (defined $_->andGroup) {push @{$and{$_->andGroup}}, $_}
            when (defined $_->orGroup) {push @{$or{$_->orGroup}}, $_}
            default {push @nogroup, $_}
        }
    });
    return { and => \%and, or => \%or, nogroup => \@nogroup};
}


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Search::QS::Filters - A collection of L<Search::QS::Filter>

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  use Search::QS::Filters;

  my $flts = new Search::QS::Filters;
  # parse query_string
  $flts->parse($qs);
  # reconvert object to query_string
  print $flts->to_qs;

=head1 DESCRIPTION

This object incapsulate multiple filter elements as a collection of
L<Search::QS::Filter>

=head1 METHODS

=head2 parse($query_string)

Parse a query string and extract filter informations

=head2 to_qs()

Return a query string of the internal rappresentation of the object

=head2 to_sql

Return this object as a SQL search

=head2 as_groups()

Return an HASHREF with 3 keys:

=over

=item and

An HASHREF with keys the andGroup keys and elements the filters with the
same andGroup key

=item or

An HASHREF with keys the orGroup keys and elements the filters with the
same orGroup key

=item @nogroup

An ARRAYREF with all filters non in a and/or-Group.

=back

=head1 AUTHOR

Emiliano Bruni <info@ebruni.it>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Emiliano Bruni.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
