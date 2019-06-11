package Search::QS;
$Search::QS::VERSION = '0.04';
use strict;
use warnings;

use Moose;

use Search::QS::Filters;
use Search::QS::Options;

# ABSTRACT: A converter between query string URI and search query


has filters => ( is => 'ro', isa => 'Search::QS::Filters',
    default => sub {
        return new Search::QS::Filters;
    }
);


has options => ( is => 'ro', isa => 'Search::QS::Options',
    default => sub {
        return new Search::QS::Options;
    }
);

sub parse {
    my $s = shift;
    my $v = shift;

    $s->filters->parse($v);
    $s->options->parse($v);
}

sub to_qs {
    my $s = shift;

    my $qs_filters = $s->filters->to_qs;
    my $qs_options = $s->options->to_qs;

    my $ret = '';
    $ret .= $qs_filters . '&' unless ($qs_filters eq '');
    $ret .= $qs_options . '&' unless ($qs_options eq '');
    # strip last &
    chop($ret);

    return $ret;

}


no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Search::QS - A converter between query string URI and search query

=head1 VERSION

version 0.04

=head1 SYNOPSIS

  use Search::QS;

  my $qs = new Search::QS;
  # parse query_string
  $qs->parse_qs($qs);
  # reconvert object to query_string
  print $qs->to_qs;

=head1 DESCRIPTION

This module converts a query string like This

  http://www.example.com?flt[Name]=Foo

into perl objects which rappresent a search.

In L</"filters()"> there are all flt (filter) elements.

In L</"options()"> there are query options like limit, start and sorting.

=head1 METHODS

=head2 filters()

Return an instance of L<Search::QS::Filters>

=head2 options()

Return an instance of L<Search::QS::Options>

=head2 parse($perl_struct)

$perl_struct is an HASHREF which represents a query string like
the one returned by L<URI::Encode/"url_params_mixed">.
It parses the $perl_struct and fills related objects in
L</"filters()"> and L</"options()">

=head2 to_qs()

Return a query string which represents current state of L<filters()>
and L<options()> elements

=head1 Examples

Here some Examples.

=over

=item C<?flt[Name]=Foo>

should be converted into

  Name = 'Foo'

=item C<?flt[Name]=Foo%&flt[Name]=$op:like>

should be converted into

  Name like 'Foo%'

=item C<?flt[age]=5&flt[age]=9&flt[Name]=Foo>

should be converted into

  (age = 5 OR age = 9) AND (Name = Foo)

=item C<?flt[FirstName]=Foo&flt[FirstName]=$or:1&flt[LastName]=Bar&flt[LastName]=$or:1>

should be converted into

  ( (FirstName = Foo) OR (LastName = Bar) )

=item C<?flt[c:one]=1&flt[c:one]=$and:1&flt[d:one]=2&flt[d:one]=$and:1&flt[c:two]=2&flt[c:two]=$and:2&flt[d:two]=3&flt[d:two]=$op:!=&flt[d:two]=$and:2&flt[d:three]=10>

should be converted into

  (d = 10) AND  ( (c = 1) AND (d = 2) )  OR  ( (c = 2) AND (d != 3) )

=back

=head1 SEE ALSO

L<Search::QS::Filters>, L<Search::QS::Filter>, L<Search::QS::Options>

=head1 AUTHOR

Emiliano Bruni <info@ebruni.it>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Emiliano Bruni.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
