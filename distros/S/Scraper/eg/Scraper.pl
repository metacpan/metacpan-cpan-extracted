
=pod

=head1 NAME

Scraper.pl - Scrape data from a search engine.


=head1 SYNOPSIS

    perl Scraper.pl

=head1 DESCRIPTION

=head1 AUTHOR

C<Scraper.pl> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

use strict;
use lib './lib';
use WWW::Scraper(qw(3.02), {'PRINT_VERSION'=>1});
use WWW::Scraper::Request;
use vars qw($VERSION);
use diagnostics;

$VERSION = sprintf("%d.%02d", q$Revision: 1.12 $ =~ /(\d+)\.(\d+)/);

    select STDERR; $| = 1; select STDOUT; $| = 1; 

    my ($engine, $query, $debug, $options) = @ARGV;
    $engine = 'eBay'  unless $engine;
    $query =~ s/(['"])(.*)\1$/$2/;
    $debug = 'U'      unless $debug;
    $options = '' unless defined $options; # This prevents error message from diagnostics.pm

    print "Scraper parameters: engine:$engine, query='$query', debug=$debug, options='$options'\n";

    my $scraper = new WWW::Scraper( $engine );
    $scraper->artifactFolder('tmp');
    my $limit = 21;

    # Most Scraper sub-classes will define their own testParameters . . .
    # Calling testParameters() also sets up testing conditions for the module.
    # See Dogpile.pm for the most mature example of how to set your testParameters.
    if ( my $testParameters = $scraper->testParameters() ) {
        $query = $testParameters->{'testNativeQuery'} unless $query;
        $options = $testParameters->{'testNativeOptions'};
        $options = {} unless $options;
        $limit = $testParameters->{'expectedMultiPage'};
        if ( $testParameters->{'SKIP'} ) {
            warn "$engine marked untestable: $testParameters->{'SKIP'}\n";
        }
    }

    my $request = new WWW::Scraper::Request($scraper,$query,$options);
    $scraper->setScraperTrace($debug);
    
#    $scraper->native_query($query,$options); # This let's us test pre-v2.00 modules from here, too.

#    $request->locations([ 'CA-San Jose'
#                         ,'CA-Mountain View'
#                         ,'CA-Sunnyvale'
#                         ,'CA-Cupertino'
##                         ,'CA-Costa Mesa'
#                         ]);

    $scraper->SetRequest($request);

    if ( $debug eq 'H' ) {
        my $fname = $query;
        $fname =~ s{\s}{_}g;
        open HTML, ">$engine\_$fname.html" or die "Can't open output '$engine.$fname.html': $!";
        print HTML "<html><head></head><body><table>\n";
    }

    my $resultCount = 0;
    my $latestPageNumber = 0;
    while ( my $result = $scraper->next_response() ) {
        if ( $scraper->artifactFolder && ($scraper->pageNumber != $latestPageNumber) ) {
            $latestPageNumber = $scraper->pageNumber();
            open OUT, ">tmp/$engine"."_pg_$latestPageNumber.htm" || warn "Can't open 'tmp/$engine"."_pg_$latestPageNumber.htm' to write: $!";
            print OUT $scraper->response->content;
            close OUT;
        }
        $resultCount += 1;
        print "#----------------------------------------------------------------------------------------------------\n";
        print $result->toString();
        print "\n";
        if ( $debug eq 'H' ) {
            my $html = $result->toHTML();

            print HTML $html;
        }
        last unless --$limit;
    }
    
    if ( $debug eq 'H') {
        print HTML "</table></body></html>\n";
        close HTML;
    }

    print "Engine reported an 'approximate result count' of ".$scraper->approximate_result_count().".\n";
    print "Content Analysis: '".${$scraper->ContentAnalysis()}."'\n" if $limit > 0;

    print "\n$resultCount results found".($limit?", short of the expected":', successfully completing the test').".\n";

