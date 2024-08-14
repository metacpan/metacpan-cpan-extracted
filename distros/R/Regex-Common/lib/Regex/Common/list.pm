package Regex::Common::list;
use strict;
use warnings;
no warnings 'syntax';

use Regex::Common qw /pattern clean no_defaults/;

our $VERSION = 'v1.0.0'; # VERSION

sub gen_list_pattern {
    my ( $pat, $sep, $lsep ) = @_;
    $lsep = $sep unless defined $lsep;
    return "(?k:(?:(?:$pat)(?:$sep))*(?:$pat)(?k:$lsep)(?:$pat))";
}

my $defpat = '.*?\S';
my $defsep = '\s*,\s*';

pattern
  name   => [ 'list', "-pat=$defpat", "-sep=$defsep", '-lastsep' ],
  create => sub { gen_list_pattern( @{ $_[1] }{ -pat, -sep, -lastsep } ) },
  ;

pattern
  name   => [ 'list', 'conj', '-word=(?:and|or)' ],
  create => sub {
    gen_list_pattern( $defpat, $defsep, '\s*,?\s*' . $_[1]->{-word} . '\s*' );
  },
  ;

pattern
  name   => [ 'list', 'and' ],
  create => sub { gen_list_pattern( $defpat, $defsep, '\s*,?\s*and\s*' ) },
  ;

pattern
  name   => [ 'list', 'or' ],
  create => sub { gen_list_pattern( $defpat, $defsep, '\s*,?\s*or\s*' ) },
  ;

1;

__END__

=pod

=head1 NAME

Regex::Common::list -- provide regexes for lists

=head1 SYNOPSIS

    use Regex::Common qw /list/;

    while (<>) {
        /$RE{list}{-pat => '\w+'}/          and print "List of words";
        /$RE{list}{-pat => $RE{num}{real}}/ and print "List of numbers";
    }


=head1 DESCRIPTION

Please consult the manual of L<Regex::Common> for a general description
of the works of this interface.

Do not use this module directly, but load it via I<Regex::Common>.

=head2 C<$RE{list}{-pat}{-sep}{-lastsep}>

Returns a pattern matching a list of (at least two) substrings.

If C<-pat=I<P>> is specified, it defines the pattern for each substring
in the list. By default, I<P> is C<qr/.*?\S/>. In Regex::Common 0.02
or earlier, the default pattern was C<qr/.*?/>. But that will match
a single space, causing unintended parsing of C<a, b, and c> as a
list of four elements instead of 3 (with C<-word> being C<(?:and)>).
One consequence is that a list of the form "a,,b" will no longer be
parsed. Use the pattern C<qr /.*?/> to be able to parse this, but see
the previous remark.

If C<-sep=I<P>> is specified, it defines the pattern I<P> to be used as
a separator between each pair of substrings in the list, except the final two.
By default I<P> is C<qr/\s*,\s*/>.

If C<-lastsep=I<P>> is specified, it defines the pattern I<P> to be used as
a separator between the final two substrings in the list.
By default I<P> is the same as the pattern specified by the C<-sep> flag.

For example:

      $RE{list}{-pat=>'\w+'}                # match a list of word chars
      $RE{list}{-pat=>$RE{num}{real}}       # match a list of numbers
      $RE{list}{-sep=>"\t"}                 # match a tab-separated list
      $RE{list}{-lastsep=>',\s+and\s+'}     # match a proper English list

Under C<-keep>:

=over 4

=item $1

captures the entire list

=item $2

captures the last separator

=back

=head2 C<$RE{list}{conj}{-word=I<PATTERN>}>

An alias for C<< $RE{list}{-lastsep=>'\s*,?\s*I<PATTERN>\s*'} >>

If C<-word> is not specified, the default pattern is C<qr/and|or/>.

For example:

      $RE{list}{conj}{-word=>'et'}        # match Jean, Paul, et Satre
      $RE{list}{conj}{-word=>'oder'}      # match Bonn, Koln oder Hamburg

=head2 C<$RE{list}{and}>

An alias for C<< $RE{list}{conj}{-word=>'and'} >>

=head2 C<$RE{list}{or}>

An alias for C<< $RE{list}{conj}{-word=>'or'} >>

=head1 SEE ALSO

L<Regex::Common> for a general description of how to use this interface.

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior <glasswalk3r@yahoo.com.br>

=head1 LICENSE and COPYRIGHT

This software is copyright (c) 2024 of Alceu Rodrigues de Freitas Junior,
glasswalk3r at yahoo.com.br

This file is part of regex-common project.

regex-commonis free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

regex-common is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
regex-common. If not, see (http://www.gnu.org/licenses/).

The original project [Regex::Common](https://metacpan.org/pod/Regex::Common)
is licensed through the MIT License, copyright (c) Damian Conway
(damian@cs.monash.edu.au) and Abigail (regexp-common@abigail.be).

=cut
