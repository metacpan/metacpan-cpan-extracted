package Psonpath;

=pod

=head1 NAME

psonpath: a CLI that parses JSON data with JSONPath

=head1 DESCRIPTION

C<psonpath> is a very simple program, basically a CLI to the L<JSON::Path>
module.

It uses this module to parse JSON data passed to the program C<STDIN>, applies
the given JSONPath expression and if the result is valid, print it in a nice
formated way to C<STDOUT>, thanks to the L<Data::Printer> module.

=head1 SEE ALSO

=over

=item *

L<App::PipeFilter|https://metacpan.org/pod/App::PipeFilter> has also a CLI to
apply a JSONPath to JSON data, but with slight different objectives.

=item *

L<JSON::Path|https://metacpan.org/pod/JSON::Path> is the module that makes
C<psonpath> program possible.

=item *

L<JSONPath - XPath for JSON|https://goessner.net/articles/JsonPath/> is an
article about JSONPath. Useful to start learning how to use it.

=item *

L<Data::Printer|https://metacpan.org/pod/Data::Printer> provides the nice,
colored and formatted output to the JSONPath expression.

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>glasswalk3r@yahoo.com.brE<gt>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 of Alceu Rodrigues de Freitas Junior,
E<lt>glasswalk3r@yahoo.com.brE<gt>.

This file is part of psonpath project.

psonpath is free software: you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

psonpath is distributed in the hope that it will be useful, but
B<WITHOUT ANY WARRANTY>; without even the implied warranty of
B<MERCHANTABILITY> or B<FITNESS FOR A PARTICULAR PURPOSE>. See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along with
psonpath. If not, see L<http://www.gnu.org/licenses/>.

=cut

1;
