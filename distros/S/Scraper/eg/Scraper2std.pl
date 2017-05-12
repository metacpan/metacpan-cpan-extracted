
=pod

=head1 NAME

Scraper.pl - Scrape data from a search engine.


=head1 SYNOPSIS

    perl Scraper.pl

=head1 DESCRIPTION

    Scraper.pl <engineName> <query> <limit>

=over 1

=item engineName

The name of the search engine module (e.g., eBay, Google)

=item query

The query. Use quotes if query contains spaces.

=item limit

Limit the result count. Defaults to 21.

=back

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
use WWW::Scraper(qw(2.27));
use WWW::Scraper::Request;
my $VERSION = sprintf("%d.%02d", q$Revision: 1.01 $ =~ /(\d+)\.(\d+)/);


    select STDERR; $| = 1; select STDOUT; $| = 1; 

    my ($engine, $query, $limit) = @ARGV;
    $query =~ s/(['"])(.*)\1$/$2/; # Remove quotes from query if user used them.

    $limit = 21 unless $limit;
    print "Scraper parameters: engine:$engine, query='$query', limit='$limit'\n";

    # Instantiate the search engine interface.
    my $scraper = new WWW::Scraper( $engine );

    # Build a Request object and assign it to the interface.
    my $request = new WWW::Scraper::Request($scraper,$query);
    $scraper->SetRequest($request);

    # Loop through all results, printing to STDOUT.
    my $resultCount = 0;
    my $latestPageNumber = 0;
    while ( my $result = $scraper->next_response() ) {
        
        $resultCount += 1;
        print "#----------------------------------------------------------------------------------------------------\n";
        print $result->toString();
        print "\n";
        last unless --$limit;
    }
    
    print "Engine reported an 'approximate result count' of ".$scraper->approximate_result_count().".\n";
    print "\n$resultCount results listed.\n";

