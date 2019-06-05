package Search::QS;
$Search::QS::VERSION = '0.01';
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

version 0.01

=head1 SYNOPSIS

  use Search::QS;

  my $qs = new Search::QS;
  # parse query_string
  $qs->parse($qs);
  # reconvert object to query_string
  print $qs->to_qs;

=head1 DESCRIPTION

This module converts a query string like This

  http://www.example.com?flt[Name]=Foo

into perl objects which rappresent a search.

In L<filters()> there are all flt (filter) elements.

In L<options()> there are query options like limit, start and sorting.

=head1 METHODS

=head2 filters()
Return an instance of L<Search::QS::Filters>

=head2 options()
Return an instance of L<Search::QS::Options>

=head2 parse($query_string)
Parse the $query_string and fills related objects in L<filters()> and L<options()>

=head2 to_qs()
Return a query string which represents current state of L<filters()> and L<options()>
elements

=head1 AUTHOR

Emiliano Bruni <info@ebruni.it>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Emiliano Bruni.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
