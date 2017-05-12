
=pod

=head1 NAME

GetTidyXmlResults.pl - Get results, convert via TidyXML, and print to file.


=head1 SYNOPSIS

    perl GetTidyXmlResults.pl

=head1 DESCRIPTION

=head1 AUTHOR

C<GetTidyXmlResults.pl> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

use strict;
use lib './lib';
use WWW::Search::Scraper(qw(1.48));
use WWW::Search::Scraper::Request;
use vars qw($VERSION);
use diagnostics;

$VERSION = sprintf("%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/);

    select STDERR; $| = 1; select STDOUT; $| = 1; 

    my ($engine, $query, $debug, $options) = @ARGV;
    $engine = 'FlipDog'  unless $engine;
    $query =~ s/(['"])(.*)\1$/$2/;
    $debug = ''      unless $debug;
    print "GetTidyXmlResults parameters: engine:$engine, query='$query', debug=$debug, options='$options'\n";

    my $scraper = new WWW::Search::Scraper( $engine );
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

    my $request = new WWW::Search::Scraper::Request($scraper,$query,$options);
    $scraper->setScraperTrace($debug);
    
    $scraper->SetRequest($request);

    my $resultCount = 0;
    my $result = $scraper->next_response();

    open OUT, ">$engine.xml" or die "Can't open '$engine.xml' to write: $!";
    print OUT ${$scraper->_tidyXmlObject()->asString('/html')};
    close OUT;
    print "Done.\n";
