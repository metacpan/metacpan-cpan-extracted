
package WWW::Scraper::Beaucoup;


#####################################################################
use strict;
use vars qw(@ISA $VERSION);
@ISA = qw(WWW::Scraper);
$VERSION = sprintf("%d.%02d", q$Revision: 1.7 $ =~ /(\d+)\.(\d+)/);

use WWW::Scraper(qw(1.48 trimLFs trimLFLFs));

# SAMPLE
# http://www.Beaucoup.com/js/jobsearch-results.html?loc=CA-San+Jose+Area&cat=Computing%2FMIS-Software+Development&srch=Perl&job=1
my $scraperRequest = 
   { 
      'type' => 'FORM'       # Type of query generation is 'QUERY'
     # This is the basic URL on which to build the query.
     ,'url' => 'http://Beaucoup.com'
     # This is the Scraper attributes => native input fields mapping
     ,'nativeQuery' => 'q'
     ,'nativeDefaults' =>
                      {    'query'   => undef
#                          ,'phrases' => 'off'
#                          ,'rpp'     => '10'
#                          ,'cb'      => 'Beaucoup'
#                          ,'qtype'   => '0'
#                          ,'lang'    => '1'
#                          ,'timeout' => '4'
                          ,'Search.x' => 1
                          ,'Search.y' => 1
                      }
     ,'fieldTranslations' =>
             {
                 '*' =>
                     {    '*'             => '*'
                     }
             }
      # Some more options for the Scraper operation.
     ,'cookies' => 0
   };

my $scraperFrame =
[ 'HTML', 
    [ 
        # This page shows <B>1-10</B> out of a total of <B>20</B> results for:
        [ 'COUNT', 'There are (\d+) results for:' ]
       ,[ 'COUNT', '\d+-\d+ out of (\d+) for ' ]
       ,[ 'COUNT', '\d+-\d+ out of a total of (\d+) results for' ]
       ,[ 'NEXT', 'next' ]
       ,[ 'HIT*',
          [ 
['REGEX','\d+\.\s<a href="([^"]*)"[^>]*>(.*?)<br>(.*?)<br>', 'url', 'title','description']

#1. <a href="/j.php?rc=40&atag=2,,4,da&j=http%3A%2F%2Fgta.sky-scraper.net%2F&kw=scraper">sky-scraper.net: best sites for GRAND THEFT AUTO</a>
#<br>sky-scraper.net,  Visit Casino On Net and receive up to $200 sign up bonus. Home. Sat,  12 Apr 2003 GMT. ...
#<br><i>http://gta.sky-scraper.net/</i>  <b><font size=1>(Netscape)</font></b><br><small><a href="/j.php?rc=40&atag=2,,4,da&j=http%3A%2F%2Fgta.sky-scraper.net%2F&kw=scraper" target=_new>Open link in new window</a></small><br><br>
          ]
        ]
    ]
];


sub testParameters {
    my ($self) = @_;
    
    if ( ref $self ) {
        $self->{'isTesting'} = 1;
    }
    
    return {
                 'SKIP' => &WWW::Scraper::TidyXML::isNotTestable() 
                ,'testNativeQuery' => 'scraper'
                ,'expectedOnePage' => 5
                ,'expectedMultiPage' => 20
                ,'expectedBogusPage' => 2000
           };
}

# Access methods for the structural declarations of this Scraper engine.
sub scraperRequest { $scraperRequest }
sub scraperFrame { $_[0]->SUPER::scraperFrame($scraperFrame); }
sub scraperDetail{ undef }

1;

__END__
=pod

=head1 NAME

WWW::Scraper::Beaucoup - Scrapes Beaucoup's Super Search


=head1 SYNOPSIS

    use WWW::Scraper;
    use WWW::Scraper::Response::Job;

    $search = new WWW::Scraper('Beaucoup');

    $search->setup_query($query, {options});

    while ( my $response = $scraper->next_response() ) {
        # $response is a WWW::Scraper::Response::Job.
    }

=head1 DESCRIPTION

Beaucoup extends WWW::Scraper.

It handles making and interpreting Beaucoup searches of F<http://www.Beaucoup.com>.


=head1 OPTIONS

=over 8

=item loc

Many, many strings are allowed. Locations are categorized by state.
See Beaucoup.com for these option values ("3648 locations!" as of June 2001)

=item cat

      --- All Categories ---
      Clerical/Administrative
      Computing/MIS
      Customer Service/Support
      Education/Training
      Engineering
      Financial Services
      Government/Non Profit
      Health Care
      Human Resources
      Manufacturing/Business Operations
      Marketing/Advertising
      Media
      Other
      Professional Services
      Sales
      Travel/Hospitality

To this you need to add a "-" and the "job function", or
you may specify "All Job Functions in Category" by leaving off the "-" and "job function".
 
The options for job function are dependant on the Job Category, so
for some of the categories the functions are:

=back

=over 16

=item Clerical/Administrative

    Other

=item Computing/MIS

    Database Administration
    Internet Development
    Network/System Administration
    Other
    Quality Assurance/Testing
    Software Development
    Systems Analysis
    Technical Support/Help Desk

=item Customer Service/Support

    Other

=item Education/Training

  Colleges/Universities
  K to 12 Education
  Other
  Technical/Trade Schools
  Training   

=item Engineering

  Chemical
  Civil
  Design/Industrial
  Electrical/Hardware
  Mechanical
  Operations
  Other   

=item Financial Services

  Accounting
  Banking
  Finance
  Insurance
  Other
  Securities/Asset Management   

=item Government/Non Profit

    Other

=item Health Care
 
  Administration
  Medical
  Nursing
  Other
  Pharmaceutical   

=item Human Resources

    Other

=item Manufacturing/Business Operations
 
  Construction/Trades
  Facilities Management
  Logistics/Distribution
  Manufacturing
  Other
  Program/Project Management
  Purchasing   

=item Marketing/Advertising
 
  Advertising
  Market Research
  Marketing Communications
  Other
  Product Management
  Public Relations   

=item Media
 
  Broadcasting
  Graphic Arts/Design
  Journalism
  Other
  Publishing/Technical Writing   

=item Other

    Other

=item Professional Services
 
  Legal Services
  Management Consulting
  Other   

=item Sales
 
  Account Management
  Business Development
  Direct Sales
  Merchandising/Retail
  Other   

=item Travel/Hospitality
 
  Other
  Restaurant/Food Services
  Travel/Recreation/Lodging   

=back

=head1 AUTHOR

C<WWW::Scraper::Beaucoup> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


