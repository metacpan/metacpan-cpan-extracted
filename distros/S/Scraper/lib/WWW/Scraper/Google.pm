
package WWW::Scraper::Google;


#####################################################################

require Exporter;
@EXPORT = qw();
@EXPORT_OK = qw(trimTags);
@ISA = qw(WWW::Scraper Exporter);
$VERSION = sprintf("%d.%02d", q$Revision: 1.23 $ =~ /(\d+)\.(\d+)/);

use Carp ();
use WWW::Scraper(qw(3.02 generic_option addURL trimTags));

use strict;

my $scraperRequest = 
{
     'fieldTranslations' => {
               '*' => {
                   '*' => '*'
                 }
             },
#http://www.google.com/search?hl=en&lr=&ie=UTF-8&oe=utf-8&safe=active&q=turntable&btnG=Google+Search                 'SKIP' => '' 
     'nativeDefaults' => {
            'q' => '',
            #'as_eq' => 'turntable',
            #'oe' => 'utf-8',
            #'as_q' => '',
            'lr' => '',
            'hl' => 'en',
            'btnG' => 'Google Search',
            'safe' => 'active',
            #'as_epq' => 'google com',
            #'as_sitesearch' => '',
            #'as_oq' => '',
            'ie' => 'UTF-8'
               },
     'nativeQuery' => 'q',
     'url' => 'http://www.google.com/search?',
     'cookies' => 0,
     'type' => 'QUERY',
     'defaultRequestClass' => undef
   };

my $scraperFrame =
[ 'HTML', 
  [ 
    [ 'NEXT', '[^>]>Next<' ], # Google keeps changing their formatting, so watch out!
    [ 'COUNT', '[,0-9]+</b> of about <b>([,0-9]+)</b>'] ,
    [ 'TABLE', '#4' ],
    [ 'DIV',
       [
              [ 'HIT*',
                [  
                  [ 'AN', 'url', 'title' ],
                  #[ 'REGEX', '<font size=-1>(.*?)<br>', 'sampleText'],
                  [ 'REGEX', 'Description:(.*?)<br>', 'description'],
                  [ 'REGEX', '<b>...</b>\s*(.*?)<br>', 'description'],
                  [ 'BODY',  'Category:', '<br>',
                    [
                      [ 'AN', 'categoryURL',  'category' ]
                    ]
                  ],
                  [ 'AN', 'cachedURL',  undef ],
                  [ 'AN', 'similarPagesURL', undef ]
                ]
              ]
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
        'SKIP' => '' 
            ,'testNativeQuery' => 'search scraper'
            ,'expectedOnePage' => 9
            ,'expectedMultiPage' => 41
            ,'expectedBogusPage' => 1
            ,'testNativeOptions' =>
                {
                   'q' => 'turntable',
                   'lr' => '',
                   'hl' => 'en',
                   'btnG' => 'Google Search',
                   'safe' => 'active',
                   'ie' => 'UTF-8'
                }
           };
}


sub import
{
    my $package = shift;

    my @exports = grep { "HASH" ne ref($_) } @_;
    my @options = grep { "HASH" eq ref($_) } @_;

    foreach (@options)
    {
        if ( $_->{'scraperBaseURL'} ) {
            $scraperRequest->{'url'} = $_->{'scraperBaseURL'};
        }
    }

    @_ = ($package, @exports);
    goto &WWW::Scraper::import;
}

# Access methods for the structural declarations of this Scraper engine.
sub scraperRequest { $scraperRequest }
sub scraperFrame { $_[0]->SUPER::scraperFrame($scraperFrame); }

1;


__END__
=pod

=head1 NAME

WWW::Scraper::Google - Scrapes www.Google.com

=head1 Caveat Kleptor

Please note that using the Google Scraper module (may) be a violation of Google's "Terms of Service",
of which your humble author has been repeatedly reminded. The TOS is not as easy to locate as some
of these correspondents have suggested (without a smile), but you can find the TOS at http://www.google.com/terms_of_service.html

Briefly, the relevant part is the "No Automated Querying" section.
It's a kind of "do as I say, not as I do" dictum.
Your author has tried to divine exactly what it means.  On the surface it's pretty clear,
but if you follow the thread you will realize that it doesn't lead to a place any of us want to be.
However, Google Inc's desire is clear enough. 
They do not want to be *abused* for the exclusive benefit of someone else.

Scraper is not a tool well suited for this kind of abuse. It is designed to be generally
configurable and, as such, it is not particularly efficient. It obeys the "robot.txt"
rules published by the web-server. It would require some effort on a user's part to
cirumvent this feature. The Google.pm does not do a "meta-search" on Google.  Even if your 
humble author removed Google.pm from the Scraper suite, it would be trivially easy for 
someone to build a Google module for Scraper (their format is very simple compared to others).

I believe that Google Inc. understands a little interloping (in moderation) is beneficial to all.
I should note that Google Inc. has not notified your author of any concern on their part.
This has been done by third parties who, for whatever reasons of their own, feel it necessary
to interject themselves in others' disputes, even when no such dispute exists.

Keep in mind that this is Google's livelihood. Should your use of Scraper be your hobby, or even 
part of your livelihood, remember it never helps to hit someone where they live. They will defend
themselves to the death (even if that death is yours).

Scraper is a handy little tool for getting to stuff you can't get to otherwise. 
Let's keep it that way!

=head1 SYNOPSIS

    require WWW::Scraper;
    $search = new WWW::Scraper('Google');

=head1 DESCRIPTION

This class is an Google specialization of WWW::Search.
It handles making and interpreting Google searches
F<http://www.Google.com>.

=head1 INTERESTING

Go to http://www.Google.com and search for "search scraper"; as in 

http://www.Google.com/search?q=search+scraper&sourceid=opera&num=0&ie=utf-8&oe=utf-8

Interesting top hits !

=head1 AUTHOR and CURRENT VERSION


C<WWW::Scraper::Google> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=cut


