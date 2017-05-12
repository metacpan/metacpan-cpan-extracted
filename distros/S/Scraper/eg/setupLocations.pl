
=pod

=head1 NAME

setupLocations.pl - Build "locations" translation tables for various scrapers.


=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

C<setupLocations.pl> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

use strict;
use WWW::Scraper::FieldTranslation;
use vars qw($VERSION);
$VERSION = sprintf("%d.%02d", q$Revision: 1.0 $ =~ /(\d+)\.(\d+)/);

my %ScraperLocations =
(
     'Brainpower.Job.locations' =>
    {
        'CA-Cupertino'     => { 'pre' => {'state'=> [5, 6]}
                            ,'post'=> {'state'=> 'California', 'city' => ['Cupertino']}
                           }
       ,'CA-San Jose'      => { 'pre' => {'state'=> [5, 6]}
                               ,'post'=> {'state'=> 'California', 'city' => ['San Jose']}
                              }
       ,'CA-Mountain View' => { 'pre' => {'state'=> [5, 6]}
                               ,'post'=> {'state'=> 'California', 'city' => ['Mountain View']}
                              }
       ,'CA-Santa Clara'   => { 'pre' => {'state'=> [5, 6]}
                               ,'post'=> {'state'=> 'California', 'city' => ['Santa Clara']}
                              }
       ,'CA-Sunnyvale'     => { 'pre' => {'state'=> [5, 6], {'acode' => ['650', '408']}}
#                               ,'post'=> {'state'=> 'California', 'city' => ['Sunnyvale']}
                              }
    }
    ,'Dice.Job.locations' =>
    {
        'CA-San Jose'      => { 'pre' => {'state'=> ['CA'], 'acode' => '408'}
                               ,'post'=> {'location'=> 'CA-408'}
                              }
       ,'CA-Mountain View' => { 'pre' => {'state'=> ['CA'], 'acode' => '650'}
                               ,'post'=> {'location'=> 'CA-650-Mountain View'}
                              }
       ,'CA-Cupertino'     => { 'pre' => {'state'=> ['CA'], 'acode' => ['650', '408']}
                               ,'post'=> {'location'=> 'CA-(\d+-)?Cupertino'}
                              }
       ,'CA-Sunnyvale'     => { 'pre' => {'state'=> ['CA'], 'acode' => ['650', '408']}
                               ,'post'=> {'location'=> 'CA-(\d+-)?Sunnyvale'}
                              }
       ,'CA-Santa Clara'   => { 'pre' => {'state'=> ['CA'], 'acode' => '650'}
                               ,'post'=> {'location'=> 'CA-(\d+-)?Santa Clara'}
                              }
    }
    ,'BAJobs.Job.locations' =>
    {
        'CA-San Jose'      => { 'pre' => {'countyIDs'=> '8'}
#                               ,'post'=> {'location'=> 'CA-408'}
                              }
       ,'CA-Mountain View' => { 'pre' => {'countyIDs'=> '8'}
#                               ,'post'=> {'location'=> 'CA-650-Mountain View'}
                              }
       ,'CA-Cupertino'     => { 'pre' => {'countyIDs'=> '8'}
#                               ,'post'=> {'location'=> 'CA-(\d+-)?Cupertino'}
                              }
       ,'CA-Sunnyvale'     => { 'pre' => {'countyIDs'=> '8'}
#                               ,'post'=> {'location'=> 'CA-(\d+-)?Sunnyvale'}
                              }
       ,'CA-Santa Clara'   => { 'pre' => {'countyIDs'=> '8'}
#                               ,'post'=> {'location'=> 'CA-(\d+-)?Santa Clara'}
                              }
    }
    ,'CraigsList.Job.locations' =>
    {
        'CA-San Jose'      => { 'pre' => {'areaID'=> ['1'], 'subAreaID' => '0'}
#                               ,'post'=> {'location'=> 'CA-408'}
                              }
       ,'CA-Mountain View' => { 'pre' => {'areaID'=> ['1'], 'subAreaID' => '0'}
#                               ,'post'=> {'location'=> 'CA-650-Mountain View'}
                              }
       ,'CA-Cupertino'     => { 'pre' => {'areaID'=> ['1'], 'subAreaID' => '0'}
#                               ,'post'=> {'location'=> 'CA-(\d+-)?Cupertino'}
                              }
       ,'CA-Sunnyvale'     => { 'pre' => {'areaID'=> ['1'], 'subAreaID' => '0'}
#                               ,'post'=> {'location'=> 'CA-(\d+-)?Sunnyvale'}
                              }
       ,'CA-Santa Clara'   => { 'pre' => {'areaID'=> ['1'], 'subAreaID' => '0'}
#                               ,'post'=> {'location'=> 'CA-(\d+-)?Santa Clara'}
                              }
    }
    ,'Monster.Job.locations' =>
    {
        'CA-San Jose'      => { 'pre' => {'lid'=> [356]}
                               ,'post'=> {'location' => ['US-CA-San Jose', 'US-CA-Silicon Valley/San Jose']}
                              }
       ,'CA-Mountain View' => { 'pre' => {'lid'=> [356]}
                               ,'post'=> {'location' => ['US-CA-Mountain View', 'US-CA-Silicon Valley/Mountain View']}
                              }
       ,'CA-Cupertino'     => { 'pre' => {'lid'=> [356]}
                               ,'post'=> {'location' => ['US-CA-Cupertino', 'US-CA-Silicon Valley/Cupertino']}
                              }
       ,'CA-Sunnyvale'     => { 'pre' => {'lid'=> [356]}
                               ,'post'=> {'location' => ['US-CA-Sunnyvale', 'US-CA-Silicon Valley/Sunnyvale']}
                              }
       ,'CA-Santa Clara'   => { 'pre' => {'lid'=> [356]}
                               ,'post'=> {'location' => ['US-CA-Santa Clara', 'US-CA-Silicon Valley/Santa Clara']}
                              }
    }
);

    for my $scraperName ( keys %ScraperLocations ) {

        $scraperName =~ m/^(.*)\.(.*)\.(.*)$/;
        my $FT = new WWW::Scraper::FieldTranslation( $1, $2, $3 );
        my $Fields = $ScraperLocations{$scraperName};
        
        for ( keys %$Fields ) {
            $FT->setTranslation( $_, $$Fields{$_} );
        }
    }

