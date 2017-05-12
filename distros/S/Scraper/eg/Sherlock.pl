=pod

=head1 NAME

Sherlock.pl - scrape search engines via Sherlock plugin(s)


=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

C<Sherlock.pl> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

use WWW::Search::Scraper (1.34) ;

    $| = 1; # Hot-pipe!
    my $stdout = select STDERR;
    $| = 1; # Hot-pipe error messages, too!
    select $stdout;
    
    my $scraper = new WWW::Search::Scraper('Sherlock');
    $scraper->sherlockPlugin('http://sherlock.mozdev.org/yahoo.src'); # or 'file:Sherlock/yahoo.src';
    
    $scraper->native_query('Greeting Cards', {'search_debug' => 1});
    
    while ( my $result = $scraper->next_result() ) {
        print "NAME: '".$result->name()."'\n";
        print "URL: '".$result->url()."'\n";
        print "RELEVANCE: '".$result->relevance()."'\n";
        print "PRICE: '".$result->price()."'\n";
        print "AVAIL: '".$result->avail()."'\n";
        print "EMAIL: '".$result->email()."'\n";
        print "DETAIL: '".$result->detail()."'\n";
    }

