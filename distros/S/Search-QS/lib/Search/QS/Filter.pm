package Search::QS::Filter;
$Search::QS::Filter::VERSION = '0.01';
use v5.14;
use Moose;

# ABSTRACT: Incapsulation of a single filter element


has 'name'      => (is => 'rw');
has 'operator'  => (is => 'rw', default => '=');
has 'value'     => (is => 'rw', isa => 'ArrayRef', default => sub { return [] } );
has 'tag'       => (is => 'rw');
has 'andGroup'  => (is => 'rw');
has 'orGroup'   => (is => 'rw');


sub parse() {
    my $s   = shift;
    my $val = shift;

    if (ref($val) ne 'ARRAY') {
        push @{$s->value}, $val;
        return $s;
    }

    foreach (@$val) {
        #print $_ . "\n";
        given($_) {
            when(/^\$op/)   { $s->operator($s->_extract_double_dots($_)) }
            when(/^\$and/)  { $s->andGroup($s->_extract_double_dots($_)) }
            when(/^\$or/)   { $s->orGroup($s->_extract_double_dots($_)) }
            default         { push @{$s->value}, $_ }
        }
    }
    return $s;
}

sub to_qs() {
    my $s = shift;


    my $ret = '';

    foreach (@{$s->value}) {
        $ret .= $s->_to_qs_name . '=' . $_ . '&';
    }
    # remove last &
    chop($ret) if (length($ret) > 0);
    $ret.= '&' . $s->_to_qs_name . '=$op:' . $s->operator if ($s->operator ne '=');
    $ret.= '&' . $s->_to_qs_name . '=$and:' . $s->andGroup if ($s->andGroup);
    $ret.= '&' . $s->_to_qs_name . '=$or:' . $s->orGroup if ($s->orGroup);

    return $ret;
}

sub to_sql {
    my $s = shift;

    my $ret = '(';

    foreach (@{$s->value}) {
        $ret .= $s->name . ' ' . $s->operator . ' ' . $_ . ' OR ';
    }

    # strip last OR
    $ret = substr($ret,0, length($ret) - 4) if (length($ret) >0);
    $ret .=')';


    return $ret;
}

sub _to_qs_name  {
    my $s = shift;

    my $ret = 'flt[' . $s->name;
    $ret.=':' . $s->tag if ($s->tag);
    $ret.=']';

    return $ret;

}

sub _extract_double_dots {
    my $s   = shift;
    my $val = shift;

    my @ret = split(/:/, $val);

    return $ret[1];
}



no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Search::QS::Filter - Incapsulation of a single filter element

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  use Search::QS::Filter;

  my $flt = new Search::QS::Filter;
  # parse query_string
  $flt->parse($qs);
  # reconvert object to query_string
  print $flt->to_qs;

=head1 DESCRIPTION

This object incapsulate a single filter element. Think of it about a single
search element in an SQL string. Like

  fullname = "Joe"

it has a fied L<name()> "fullname", an L<operator()> "=" and a L<value()> "Joe".

=head1 METHODS

=head2 name()

The field name to search

=head2 operator()

The operator to use between field and value

=head2 value()

An ARRAYREF with values to search in field name. It should be expanded with OR
concatenation. As an example,

  fld[x]=1&fld[x]=2

after parsing produce

    name => 'x', values => [1,2]

and in SQL syntax must be written like

  x=1 or x=2

=head2 tag()

In field name it can be use ":" to separe field name by a tag. The idea is to
distinguish different operation with same field name.

As an example

  fld[a:1]=1&fld[a:1]=>&fld[a:2]=5&fld[a:2]=<

must be

  a>1 and a<5

=head2 andGroup()

If you set a field with $and:$groupvalue you set that this field in a AND group
with other fields with same $groupvalue

As an example to

  flt[d:1]=9&flt[d:1]=$and:1&flt[c:1]=2&flt[c:1]=$and:1&flt[d:2]=3&flt[d:2]=$and:2&flt[c:2]=1&flt[c:2]=$and:2

is traslated in

( d=9 AND c=2 ) OR ( d=3 and c=1 )

=head2 orGroup()

Like L<andGroup()> but for OR operator

=head2 parse($query_string)

Parse a query string and extract filter informations

=head2 to_qs()

Return a query string of the internal rappresentation of the object

=head2 to_sql

Return this object as a SQL search

=head1 AUTHOR

Emiliano Bruni <info@ebruni.it>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Emiliano Bruni.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
