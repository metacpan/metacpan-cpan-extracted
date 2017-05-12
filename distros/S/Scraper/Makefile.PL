
# $Name:  $

use ExtUtils::MakeMaker;

{   package MM;
sub new {
    my $self = shift;
    
    my $isSearch226 = 0;
    eval { require WWW::Search; $isSearch226 = ( $WWW::Search::VERSION eq '2.26' ) };
    if ( $@ ) {
      warn "WWW::Search(2.28) is required for Scraper.\n";
    }
    if ( $isSearch226 ) {
        warn <<EOT;

>    Warning: You are using WWW::Search version 2.25.
>    That version of WWW::Search contains a bug in the POST method that
>    makes several Scraper modules fail. Unfortunately, the \$VERSION in
>    WWW::Search::Search.pm(2.25) reads "2.26", and the \$VERSION in 
>    WWW::Search::Search.pm(2.26) reads "2.28", so Scraper cannot simply
>    recommend that you "upgrade to 2.28" - that would be confusing.
>    Instead, we (Makefile.PL) recommend that you upgrade to WWW::Search(2.26)!
>    (ignore the subsequent message "prerequisite WWW::Search 2.28 not found")
    
EOT
    }
    $self->SUPER::new(@_);
}
}
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'	=> 'Scraper',
    'VERSION_FROM' => "lib/WWW/Scraper.pm", # finds $VERSION
    # test.pl uses this hash, also, to poll all modules we depend on
    'PREREQ_PM' => { 'WWW::Search' => 2.35
                    ,'LWP' => 5.48
                    ,'URI' => 0.0
                    ,'URI::URL' => 0.0
                    ,'URI::http' => 0.0
                    ,'HTML::Form' => 0.02
                    ,'HTML::TreeBuilder' => 0.0
                    ,'HTTP::Cookies' => 0.0
                    ,'HTTP::Request' => 0.0
                    ,'HTTP::Response' => 0.0
                    ,'HTTP::Status' => 0.0
                    ,'LWP::RobotUA' => 0.0
                    ,'LWP::UserAgent' => 0.0
                    ,'URI::Escape' => 0.0
                    ,'LWP::UserAgent' => 0.0
                    ,'Text::ParseWords' => 0.0
                    ,'Text::ParseWords' => 3.2
                    ,'Storable' => 0.6
                    ,'Tie::Persistent' => 0.901
                    ,'User' => 1.05
                    ,'XML::XPath' => 0.0

                   },
    ($] ge '5.005') ? (
                     'AUTHOR' => 'Glenn Wood http://search.cpan.org/search?mode=author&query=GLENNWOOD',
                     'ABSTRACT' => 'Scrape data from web search engines',
                    ) : (),
);

