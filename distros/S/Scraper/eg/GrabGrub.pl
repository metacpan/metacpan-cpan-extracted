
=pod

=head1 NAME

GrabGrub.pl - "Grub" data from a local file source.


=head1 SYNOPSIS

    perl GrabGrub.pl

=head1 DESCRIPTION

    GrabGrub.pl

=head1 AUTHOR

C<GrabGrub.pl> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=head1 COPYRIGHT

Copyright (c) 2003 Glenn Wood  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

use strict;
use lib './lib';
use WWW::Scraper(qw(3.01), {'PRINT_VERSION'=>1});
my $VERSION = sprintf("%d.%02d", q$Revision: 1.00 $ =~ /(\d+)\.(\d+)/);

    # Instantiate the search engine interface.
    my $scraper = new WWW::Scraper( 'Grub', '' );

    # Loop through all results, printing "grubbed" results to differently named files.
    my $resultCount = 0;
    my $latestPageNumber = 0;
    while ( my $result = $scraper->next_response() ) {
        
        my ($filename) = ( ${$result->url} =~ m{/([^/]*)$} ); # Calculate a unique, meaningful filename.
        open OUT, ">grub_$filename";
        print OUT '<head></head><body><table>';
        my @sections = $result->section;
        for ( @sections ) {
            print OUT $$_."\n";
        }
        print OUT '</table></body>';
        close OUT;
    }
    
