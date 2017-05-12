
use strict;

package WWW::Scraper::Opcode::NEXT;
use base qw(WWW::Scraper::Opcode);
use vars qw($VERSION);

# new() Scraper::Opcode
#  $cls - Op class
#  $scaffold - current scaffold
#  $params - ref to array of params in the 'OP()' portion of the scaffold.
sub new {
    my ($cls, $scaffold, $params) = @_;
    my $self = bless {};

    $self->{'fieldsCaptured'} = [];
    $self->{'fieldsDiscovered'} = ['NEXT'];
    return $self;
}

sub scrape {
    my ($self, $scraper, $scaffold, $TidyXML, $hit) = @_;
    
    my (@ary, $dat) = (@$scaffold, ${$TidyXML->asString()});

    if ( ref $ary[1] )
    {
        my $datParser = $ary[1];
        my $url = ${$TidyXML->asString()};
        $url = WWW::Scraper::unescape_query($url) if $TidyXML->m_isTidyd();
        $scraper->{'_next_url'} = &$datParser($scraper, $hit, $url);                
        print STDERR  "NEXT_URL: $scraper->{'_next_url'}\n" if ($scraper->ScraperTrace('N'));
    }
    else
    {
        # A simple regex will not work here, since the "next" string may often
        # appear even when there's no <A>...</A> surrounding it. The problem occurs
        # when there is a <A>...</A> preceding it, *and* following it. Simple regex's
        # will find the first anchor, even though it's not the HREF for the "next" string.
        my $next_url_button = $ary[1];
        print STDERR  "next_url_button: $next_url_button\n" if ($scraper->ScraperTrace('N'));

        while ( 1 ) 
        {
            my ($sub_string, $attributes) = $TidyXML->getMarkedTextAndAttributes('A');
            last unless $sub_string;
            if ( $sub_string =~ m-$next_url_button-si )
            {
                my $url = $attributes->{'href'};
                if ( $url ) {
                   # Well, you learn something every day!
                   if ( my ($newName, $newValue) = ($url =~ m{&(.*?)=(.*)$}) and $url !~ m{\?} ) {
                      $url = $scraper->{'_last_url'};
                      $url =~ s{&$newName=[^&]*}{}g; # remove any earlier appearance of this parameter.
                      $url .= "&$newName=$newValue";
                   }
                    my $datParser = $ary[3];

                    $datParser = \&WWW::Scraper::null unless $datParser;
                    $scraper->{'_base_url'} =~ m-^(.*)/.*$-;
                    my $baseURL = $1;
                    $url = new URI::URL(&$datParser($scraper, $hit, $url), $scraper->{'_base_url'});
                    $url = $url->abs();
                    $url = WWW::Scraper::unescape_query($url);# if $TidyXML->m_isTidyd();
                    $scraper->{'_next_url'} = $url;
                    print STDERR  "NEXT_URL: $url\n" if ($scraper->ScraperTrace('U'));
                    last;
                }
            }
        }
    }
    return undef;
}


1;
