
package WWW::Scraper::CraigsList;

#####################################################################

use strict;
use vars qw($VERSION @ISA);
@ISA = qw(WWW::Scraper);
use WWW::Scraper(qw(3.02 generic_option addURL trimTags));
use WWW::Scraper::FieldTranslation;

$VERSION = sprintf("%d.%02d", q$Revision: 1.16 $ =~ /(\d+)\.(\d+)/);

# Craigs List differs from other search engines in a few ways.
# One of them is the results page is not tablulated, or data lined.
# It returns each job listing on a single line.
# This line can be parsed with a single regular expression, which is what we do.
#
# SAMPLE :
#
# <br>Apr&nbsp;24&nbsp;-&nbsp;<a href=/sfo/eng/959347.html>Senior&nbsp;Software&nbsp;Engineer</a>&nbsp(San&nbsp;Francisco)<font size=-1>&nbsp;(internet&nbsp;engineering&nbsp;jobs)</font></br>
#
#
# private

# NOTE: sometimes the response may read:
#
# craigslist: online community
#            craigslist
#            online community
#      The requested function is offline for maintenance.
#       Please try again a little later.
#
# NEW: by 2002.09.27
# Jobs - web-dev
# http://www.craigslist.org/cgi-bin/search?areaID=1&subAreaID=0&catAbbreviation=eng&cat=14&group=J&type_search=&query=Perl&new_cat=14
# Jobs - software/QA/DBA/etc jobs
# http://www.craigslist.org/cgi-bin/search?areaID=1&subAreaID=0&catAbbreviation=sof&cat=21&group=J&type_search=&query=Quality&new_cat=21    return {
# Car stuff
# http://www.craigslist.org/cgi-bin/search?areaID=1&subAreaID=0&catAbbreviation=car&cat=6&group=S&type_search=&query=honda+accord&new_cat=6&maxAsk=11000
# http://www.craigslist.org/cgi-bin/search?areaID=1&subAreaID=0&catAbbreviation=car&cat=6&group=S&type_search=&query=Honda&new_cat=6&maxAsk=
my $scraperRequest = 
   { 
      'type' => 'POST'       # Type of query generation is 'POST'
      # This is the basic URL on which to build the query.
     ,'url' => 'http://www.craigslist.org/cgi-bin/search?'
      # This is the Scraper attributes => native input fields mapping
      ,'nativeQuery' => 'query'
      ,'nativeDefaults' =>
                      {    'areaID'         => '1'
                          ,'subAreaID'      => '0'
                          ,'group'          => 'S'
                          ,'cat'            => 'all'
                          ,'new_cat'        => '6'
                          ,'catAbbreviation' => 'car'
                          ,'group'          => 'J'
                          ,'type_search'    => ''
                          ,'min_ask'        => '' # catAbbreviation='car'
                          ,'max_ask'        => '' # catAbbreviation='car'
                          ,'query'          => ''
                      }
#      ,'defaultRequestClass' => 'Job'
      ,'fieldTranslations' =>
             { '*' => 
                  {    '*'         => '*'
                      ,'skills'    => 'query'
#                          ,'payrate'   => \&translatePayrate
                      ,'locations' => new WWW::Scraper::FieldTranslation('CraigsList', 'Job', 'locations')
                  }
              }
      # Some more options for the Scraper operation.
     ,'cookies' => 0
   };

my $scraperFrame =
[ 'HTML', 
   [ 
       [ 'NEXT', 'Next ' ]
      ,[ 'BODY', '</FORM>', '' ,
          [ 
             [ 'COUNT', 'Found: (\d+)']
            ,[ 'HIT*' ,
                [  
# NEW: by 2002.09.27
#<p>&nbsp;May-18&nbsp;&nbsp;&nbsp;<a href=/sfc/mcy/11439880.html>=====&gt;&gt;2001 Honda XR 650L  - $3500</a>  (vallejo) &lt;&lt;<i><a href=/mcy/>cycles</a></i>
#<p>&nbsp;Sep-26&nbsp;&nbsp;&nbsp;<a href=/sfo/pen/eng/5905447.html>Plugged In Enterprises Web Producer </a> (East Palo Alto)
                   [ 'REGEX', '<p>\s*(&nbsp;)*(\w*?-\d+)[^<]*<a\s+href=([^>]+)>(.*?)</a>([^<]*)', 
                                   undef,       'date',        'url',       'title', 'location'
                   ]
                ]
             ]
          ]
      ]
   ]
];


sub testParameters {
    # 'POST' style scraperFrames can't be tested cause of a bug in WWW::Search(2.2[56]) !
    my $isNotTestable = WWW::Scraper::isGlennWood()?0:0;
# http://www.craigslist.org/cgi-bin/search?areaID=1&subAreaID=0&catAbbreviation=sof&cat=21&group=J&type_search=&query=Quality&new_cat=21    return {
    return {
                 'SKIP' => $isNotTestable
                ,'testNativeQuery' => 'Honda'
                ,'expectedOnePage' => 50
                ,'expectedMultiPage' => 100
                ,'expectedBogusPage' => 0
# http://www.craigslist.org/cgi-bin/search?areaID=1&subAreaID=0&catAbbreviation=car&group=S&type_search=&query=Honda&cat=6&minAsk=min&maxAsk=max
                ,'testNativeOptions' => {  'areaID'         => '1'
                                          ,'subAreaID'      => '0'
                                          ,'group'          => 'S'
                                          ,'cat'            => 'all'
                                          ,'new_cat'        => '6'
                                          ,'catAbbreviation' => 'car'
                                          ,'group'          => 'S'
                                          ,'type_search'    => ''
                                          ,'min_ask'        => 'min'
                                          ,'max_ask'        => 'max'
                                        }
                ,'usesPOST' => 1
           };
}

sub init {
    my ($self) = @_;
    $self->searchEngineHome('http://www.CraigsList.org');
    $self->searchEngineLogo('<font size=5><b>craigslist</b></font>');
    return $self;
}


# Access methods for the structural declarations of this Scraper engine.
sub scraperRequest { $scraperRequest }
sub scraperFrame { $_[0]->SUPER::scraperFrame($scraperFrame); }
sub scraperDetail{ undef }

1;
__END__

=pod

=head1 NAME

WWW::Scraper::CraigsList - Scrapes CraigsList


=head1 SYNOPSIS

    require WWW::Scraper;
    $search = new WWW::Scraper('CraigsList');


=head1 DESCRIPTION

This class is an CraigsList specialization of WWW::Search.
It handles making and interpreting CraigsList searches
F<http://www.CraigsList.com>.

This class exports no public interface; all interaction should
be done through WWW::Search objects.


=head1 OPTIONS

None at this time (2001.04.25)

=over 8

=item search_url=URL

Specifies who to query with the CraigsList protocol.
The default is at
C<http://www.CraigsList.com/cgi-bin/job-search>.

=item search_debug, search_parse_debug, search_ref
Specified at L<WWW::Search>.

=back


Internet/Web Engineering Category options:
 <null> - ALL JOBS
 art - web design jobs
 bus - business jobs
 mar - marketing jobs
 eng - internet engineering jobs
 etc - etcetera jobs
 wri - writing jobs
 sof - software jobs
 acc - finance jobs
 ofc - office jobs
 med - media jobs
 hea - health science jobs
 ret - retail jobs
 npo - nonprofit jobs
 lgl - legal jobs
 egr - engineering jobs
 sls - sales jobs
 sad - sys admin jobs
 tel - network jobs
 tfr - tv video radio jobs
 hum - human resource jobs
 tch - tech support jobs
 edu - education jobs
 trd - skilled trades jobs

Checkboxes - additive to search(?)

addOne   value=telecommuting - telecommute
addTwo   value=contract      - contract
addThree value=internship    - internships
addFour  value=part-time     - part-time
addFive  value=non-profit    - non-profit


=head1 SEE ALSO

To make new back-ends, see L<WWW::Search>,
or the specialized CraigsList searches described in options.


=head1 AUTHOR

C<WWW::Scraper::CraigsList> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

------------------------------------------------
             
Search.pm and Search::AltaVista.pm (of which CraigsList.pm is a derivative)
is Copyright (c) 1996-1998 University of Southern California.
All rights reserved.                                            

Redistribution and use in source and binary forms are permitted
provided that the above copyright notice and this paragraph are
duplicated in all such forms and that any documentation, advertising
materials, and other materials related to such distribution and use
acknowledge that the software was developed by the University of
Southern California, Information Sciences Institute.  The name of the
University may not be used to endorse or promote products derived from
this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.


=cut

