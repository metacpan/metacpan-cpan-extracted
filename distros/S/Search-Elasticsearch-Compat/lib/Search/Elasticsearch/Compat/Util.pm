package Search::Elasticsearch::Compat::Util;
$Search::Elasticsearch::Compat::Util::VERSION = '0.10';
use strict;
use warnings;
use Sub::Exporter -setup => { exports => ['filter_keywords'] };

#===================================
sub filter_keywords {
#===================================
    local $_ = shift;

    s{[^[:alpha:][:digit:] \-+'"*@\._]+}{ }g;

    return '' unless /[[:alpha:][:digit:]]/;

    s/\s*\b(?:and|or|not)\b\s*/ /gi;

    # remove '-' that don't have spaces before them
    s/(?<! )-/\ /g;

    # remove the spaces after a + or -
    s/([+-])\s+/$1/g;

    # remove + or - not followed by a letter, number or "
    s/[+-](?![[:alpha:][:digit:]"])/ /g;

    # remove * without 3 char prefix
    s/(?<![[:alpha:][:digit:]\-@\._]{3})\*/ /g;

    my $quotes = (tr/"//);
    if ( $quotes % 2 ) { $_ .= '"' }

    s/^\s+//;
    s/\s+$//;

    return $_;
}

# ABSTRACT: Provides the filter_keywords utility


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Search::Elasticsearch::Compat::Util - Provides the filter_keywords utility

=head1 VERSION

version 0.10

=head1 SYNOPSIS

    use Search::Elasticsearch::Compat::Util qw(filter_keywords);

    my $filtered = filter_keywords($unfiltered)

=head1 SUBROUTINES

=head2 filter_keywords()

This tidies up a string to be used as a query string in (eg)
L<Search::Elasticsearch::Compat/"search()"> so that user input won't cause a search query
to return an error.

It is not flexible at all, and may or may not be useful to you.

Have a look at L<Search::Elasticsearch::Compat::QueryParser> which gives you much more control
over your query strings.

The current implementation does the following:

=over

=item * Removes any character which isn't a letter, a number, a space or
  C<-+'"*@._>.

=item * Removes C<and>, C<or> and C<not>

=item * Removes any C<-> that doesn't have a space in front of it ( "foo -bar")
      is acceptable as it means C<'foo' but not with 'bar'>

=item * Removes any space after a C<+> or C<->

=item * Removes any C<+> or C<-> which is not followed by a letter, number
      or a double quote

=item * Removes any C<*> that doesn't have at least 3 letters before it, ie
      we only allow wildcard searches on words with at least 3 characters

=item * Closes any open double quotes

=item * Removes leading and trailing whitespace

=back

YMMV

=head1 LICENSE AND COPYRIGHT

Copyright 2009-2013 - 2011 Clinton Gormley.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Elasticsearch BV.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
