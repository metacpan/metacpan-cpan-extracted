package RT::Extension::SavedSearchResults;

use 5.006;
use strict;
use warnings;

=head1 NAME

RT::Extension::SavedSearchResults - saved-searches with short urls on and offline.

=cut

our $VERSION = '1.1';

=head1 SYNOPSIS

    # id is taken from the last int of the id string. The following are equivilent.
    http://myrt.com/Search/SavedSearchResults.tsv?SavedSearchId=123
    http://myrt.com/Search/SavedSearchResults.tsv?SavedSearchId=RT::System-1-SavedSearch-8
 
    # Get output from saved-search and save to file.      
    RT$ ./local/plugins/RT-SavedSearchResults/bin/rt-saved-search-results.pl  8  yesterday.tsv
    
    # Use RT built-in tool to view a SavedSearch (stored in Attributes table)
    RT$ ./sbin/rt-attributes-viewer  8

=head1 INSTALL

    perl Makefile.PL
    make
    make install

    # Enable this plugin in your RT_SiteConfig.pm:
    Set(@Plugins, (qw/RT::Extension::SavedSearchResults/) );

=head1 DESCRIPTION

    This plugin transparently changes the "Search > Feeds > Spreadsheet" link
    into a short url.  Only happens when there is a SavedSearchId in the Feed URL.

    It also provides a way to dump results from a saved-search locally by
    creating a temporarily valid session.
     
    Useful for:

        * Commandline dumps of Saved-Searches
        * MS Excel External Data-Import Feeds
          (there don't like the long urls with the Format string provided by RT)

=head1 SUPPORT

    This module is designed to work with RT4 and above.

    Please report any bugs at either:
    L<http://search.cpan.org/dist/RT-Extension-SavedSearchResults/>
    L<https://github.com/coffeemonster/RT-Extension-SavedSearchResults>

=head1 LICENSE AND COPYRIGHT

    Copyright 2013 Alister West, C<< <alister at alisterwest.com> >>

    This program is free software; you can redistribute it and/or modify it
    under the same terms as perl itself L<http://dev.perl.org/licenses/>.

=head1 CHANGES

    1.1 - 2013/05/23 - CPANified.
    1.0 - 2013/05/17 - Created; tested with RT v4.0.12

=cut

1;
