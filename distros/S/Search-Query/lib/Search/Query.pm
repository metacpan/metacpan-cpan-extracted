package Search::Query;

use warnings;
use strict;
use Search::Query::Parser;
use Carp;
use File::Find;
use File::Spec;
use Data::Dump qw( dump );
use Module::Pluggable
    search_path => ['Search::Query::Dialect'],
    sub_name    => 'dialects';

our $VERSION = '0.307';

=head1 NAME

Search::Query - polyglot query parsing

=head1 SYNOPSIS

 use Search::Query;
 
 my $parser = Search::Query->parser();
 my $query  = $parser->parse('+hello -world now');
 print $query;  # same as print $query->stringify;

=cut

=head1 DESCRIPTION

This class provides documentation and class methods.

Search::Query started as a fork of the excellent Search::QueryParser module
and was then rewritten to provide support for alternate query dialects.

=head1 METHODS

=head2 parser

Returns a Search::Query::Parser object. See the documentation
for L<Search::Query::Parser> for supported query syntax and how
to customize the Parser.

=cut

sub parser {
    my $class = shift;
    return Search::Query::Parser->new(@_);
}

=head2 get_query_class( I<name> )

Returns a Search::Query::Dialect-based class name corresponding
to I<name>. I<name> defaults to 'Native'.

=cut

sub get_query_class {
    my $class = shift;
    my $name = shift or croak "query_class name required";

    return $name if $name =~ m/^Search::Query::Dialect::/;

    for my $dialect ( $class->dialects ) {
        if ( $dialect =~ m/::$name$/i ) {
            eval "require $dialect";
            croak $@ if $@;
            return $dialect;
        }
    }

    croak "No such Dialect available: $name";
}

=head2 get_dialect( I<name> )

Alias for get_query_class().

=cut

*get_dialect = \&get_query_class;

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-search-query at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Search-Query>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Search::Query


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Search-Query>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Search-Query>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Search-Query>

=item * Search CPAN

L<http://search.cpan.org/dist/Search-Query/>

=back


=head1 ACKNOWLEDGEMENTS

This module started as a fork of Search::QueryParser by
Laurent Dami.

=head1 COPYRIGHT & LICENSE

Copyright 2010 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;    # End of Search::Query
