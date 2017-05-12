use strict;
package WWW::Scraper::ScraperDiscovery;

#####################################################################

use base qw(WWW::Scraper Exporter);
# This is an appropriate VERSION calculation to use for CVS revision numbering.
use vars qw($VERSION);
$VERSION = sprintf("%d.%02d", q$Revision: 1.0 $ =~ /(\d+).(\d+)/);

use WWW::Scraper(qw(3.00 generic_option trimLFs trimTags removeScriptsInHTML));

use strict;

my $scraperRequest = 
        { 
            # This engine's method is QUERY
            'type' => 'QUERY'
            
            # This is the basic URL on which to get the form to build the query.
            ,'url' => 'http://google.com'

           # specify defaults, by native field names
           ,'nativeQuery' => undef
           ,'nativeDefaults' => {'rootUrl' => '1' }
            
            # specify translations from canonical fields to native fields
           ,'defaultRequestClass' => undef
           ,'fieldTranslations' =>
                   {
                       '*' =>
                           {
                                '*'         => '*'
                           }
                   }
            # Miscellaneous options for the Scraper operation.
           ,'cookies' => 0
       };

sub generateQuery {
    my ($self) = @_;
    $scraperRequest->{'url'} = $self->{'native_query'};
    return $scraperRequest->{'url'};
}

my $scraperFrame =
       [ 'HTML',
         [ 
            [ 'HIT*', 'ScraperDiscovery::FORM',
              [
                [ 'FORM',
                  [
                    [ 'HIT*', 'ScraperDiscovery::INPUT',
                      [
                        [ 'INPUT' ]
                      ]
                    ]
                   ,[ 'HIT*', 'ScraperDiscovery::SELECT',
                      [
                         [ 'SELECT', 
                           [
                             [ 'HIT*', 'ScraperDiscovery::OPTION',
                               [
                                 [ 'OPTION' ]
                               ]
                             ]
                           ]
                         ]
                      ]
                    ]
                  ]
                ],
              ]
            ],
         ]
       ];

my $scraperFrame1 =
       [ 'HTML',
         [ 
            [ 'HIT*', 'ScraperDiscovery::FORM',
              [
                [ 'FORM',
                  [
                    [ 'HIT*', 'ScraperDiscovery::INPUT',
                      [
                        [ 'INPUT' ]
                      ]
                    ]
                   ,[ 'HIT*', 'ScraperDiscovery::SELECT',
                      [
                         [ 'SELECT', 
                           [
                             [ 'HIT*', 'ScraperDiscovery::OPTION',
                               [
                                 [ 'OPTION' ]
                               ]
                             ]
                           ]
                         ]
                      ]
                    ]
                  ]
                ],
              ]
            ],
         ]
       ];

my $scraperFrame2 =
       [ 'HTML',
         [ 
            [ 'HIT*', 'ScraperDiscovery::BODY',
              [
                [ 'BODY',
                  [
                    [ 'HIT*', 'ScraperDiscovery::NEXT',
                      [ 'DISCOVERNEXT' ]
                    ]
                   ,[ 'MACRO', 'TABLELOOP', 
                      [
                        [ 'HIT*', 'ScraperDiscovery::TABLE',
                          [
                            [ 'TABLE' ]
                           ,[ 'HIT*', 'ScraperDiscovery::TR',
                              [
                                 [ 'TR', 
                                   [
                                     [ 'HIT*', 'ScraperDiscovery::TD',
                                       [
                                          [ 'A', 'url', 'urlCaption' ]
                                         ,[ 'A', 'url', 'urlCaption' ]
                                         ,[ 'A', 'url', 'urlCaption' ]
                                         ,[ 'A', 'url', 'urlCaption' ]
                                         ,[ 'TD' ]
                                         ,[ 'MACROX', 'TABLELOOP' ]
                                       ]
                                     ]
                                   ]
                                 ]
                              ]
                            ]
                          ]
                        ]
                      ]
                    ]
                  ]
                ],
              ]
            ],
         ]
       ];


sub init {
    my ($self, $subclass, $native_query, $native_options) = @_;
    
    if ( $native_options->{'SCRAPERREQUEST'} ) {
        $self->SetScraperRequest($native_options->{'SCRAPERREQUEST'});
    } else {
        $self->SetScraperRequest($scraperRequest);
    }

    if ( $native_options->{'PHASE'} ) {
        my $phase = $native_options->{'PHASE'};
        $self->SetScraperFrame($scraperFrame1) if $phase == 1;
        $self->SetScraperFrame($scraperFrame2) if $phase == 2;
    } else {
        $self->SetScraperFrame($scraperFrame1);
    }
    
    $self->SetScraperDetail(undef);
    return $self->SUPER::init($subclass, $native_query);
}

1;

__END__
=pod

=head1 NAME

WWW::Scraper::ScraperDiscovery - discovers forms and inputs on a HTML page.


=head1 SYNOPSIS

    use WWW::Scraper;
    $scraper = new WWW::Scraper('ScraperDiscovery',{'url' => 'http://someplace.com/formInQuestion.html'});

See F<eg/ScraperDiscovery.pl>

=head1 DESCRIPTION

This class is an experimental exploration of "Scraper Discovery".

=head1 AUTHOR and CURRENT VERSION

C<WWW::Scraper::ScraperDiscovery> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=head1 COPYRIGHT

Copyright (c) 2002 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=cut

