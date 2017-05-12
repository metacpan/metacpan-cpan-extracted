
package WWW::Scraper::Dogpile;


#####################################################################

require Exporter;
@EXPORT = qw();
@EXPORT_OK = qw(trimTags);
@ISA = qw(WWW::Scraper Exporter);
$VERSION = sprintf("%d.%02d", q$Revision: 1.11 $ =~ /(\d+)\.(\d+)/);

use Carp ();
use WWW::Scraper(qw(2.27 generic_option));

use strict;

# Example query - http://search.lycos.com/main/default.asp?lpv=1&loc=searchhp&query=Perl
my $scraperRequest = 
        { 
            # This engine is driven from it's <form> page
            'type' => 'QUERY'
            
            # This is the basic URL on which to get the form to build the query.
            ,'url' => 'http://search.dogpile.com/texis/search?'

           # specify defaults, by native field names
           ,'nativeQuery' => 'q'
           ,'nativeDefaults' => { 'Fetch.x' => '1'
                                 ,'Fetch.y' => '1'
                                 ,'geo' => 'no'
                                 ,'fs' => 'The Web'
                                }
            
            # specify translations from canonical fields to native fields
           ,'fieldTranslations' =>
                   {
                       '*' =>
                           {    'skills'    => 'q'
                               ,'*'         => '*'
                           }
                   }
            # Miscellaneous options for the Scraper operation.
           ,'cookies' => 0
           # Some search engines don't connect every time - retry Dogpile this many times.
           ,'retry' => 1
       };

my $scraperFrame = 
[ 'HTML', 
  [ 
    [ 'NEXT', \&findNextForm ],
    [ 'HIT*',
      [  
#<font face="verdana, sans-serif" size="2">3. <a href="http://clickit.go2net.com/search?site=srch&cid=239134&area=srch.comm.overture&shape=textlink&cp=info.dogpl&rawto=http://www9.overture.com/d/sr/?xargs=02u3hs9yoaj1UKsTDChBjFX5spp%2FCTf0O0mIZQpChwe6VrSYKFGqbBUxe3QVP1vLuO1u%2By%2F%2BrzwffmnZHlqXIRERDIJSVEo%2BQKgSkuND9EaQXW6q7qVVfbZ7G%2B8e2jB2a0LBZtL01lzCaDRoyJWeahwcZA6Mji%2FDLv4brtMhri4nxMzwVJnUVAg7iuTtjsfPwUdK5185CSMVTgdQEaiTQN9bDlXpxcb0M9Jg%3D%3D">Retro 
#Radios, Turntables and Phones</a></font><br>
#<font face="verdana, sans-serif" size="2">View our selection of brand name turn 
#tables at discounted prices. Shop all the decorative and fun radios, record 
#players and more. Purchase securely online. http://www.fun-radios.com<br>
#</font>  <br>
                 [ 'REGEX', '<font face="verdana, sans-serif" size="2">(\d+)\.\s+.*?href="([^"]*)"[^>]*>(.*?)</a>.*?<br>(.*?)<br>', 'number', 'url', 'title', 'description' ]
#                ,[ 'A', 'go2netUrl', 'title' ]
#                ,[ 'SPAN', 'url' ]
#                ,[ 'RESIDUE', 'description', \&cleanUpLeadingTrailingBRs ]
      ]
    ]
  ]
];
 
sub cleanUpLeadingTrailingBRs {
    my ($self, $hit, $dat) = @_;
    $dat =~ s{^\s*<br>}{}si;
    $dat =~ s{<br><br>\s*$}{}si;
    return $dat;
}


# #######################################################################################
# Get the Next URL from a <form> on the page.
# Sometimes there's just a NEXT form, sometimes there's a PREV form and a NEXT form . . .
use HTML::Form;
sub findNextForm {
    my ($self, $hit, $dat) = @_;
    
    if ( $dat =~ m{(<FORM\s+action.*?">.*?next 10 engines.*?</FORM>)}si ) {
        my $form = HTML::Form->parse($1, $self->{'_base_url'});
        my $req = $form->make_request;
        return $req->uri;
    }
    return '';
}


sub testParameters {
    my ($self) = @_;

    return {
                 'SKIP' => &WWW::Scraper::TidyXML::isNotTestable('Dogpile')
                ,'testNativeQuery' => 'turntable'
                ,'expectedOnePage' => 9
                ,'expectedMultiPage' => 60
                ,'expectedBogusPage' => 1
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
    goto &Exporter::import;
}

# Access methods for the structural declarations of this Scraper engine.
sub scraperRequest { $scraperRequest }
sub scraperFrame { $_[0]->SUPER::scraperFrame($scraperFrame); }

1;


__END__
=pod

=head1 NAME

WWW::Scraper::Dogpile - Scrapes www.Dogpile.com


=head1 SYNOPSIS

    require WWW::Scraper;
    $search = new WWW::Scraper('Dogpile');


=head1 DESCRIPTION

This class is an Dogpile specialization of WWW::Search.
It handles making and interpreting Dogpile searches
F<http://www.Dogpile.com>.

=head1 AUTHOR and CURRENT VERSION

C<WWW::Scraper::Dogpile> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=cut


