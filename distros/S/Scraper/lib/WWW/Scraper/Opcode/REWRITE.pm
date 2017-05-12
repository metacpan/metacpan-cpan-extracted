
use strict;

package WWW::Scraper::Opcode::REWRITE;
use base qw(WWW::Scraper::Opcode);

sub new { bless {'fieldsDiscovered' => []} }

sub scrape {
    my ($self, $scraper, $scaffold, $TidyXML, $hit) = @_;
    
    my $sub_string = ${$TidyXML->asString};
    my ($rg1,$rg2) = ($$scaffold[1],$$scaffold[2]);
    
    $sub_string =~ s{$rg1}{$rg2}gsi;

    return ($self->_next_scaffold($scaffold), $sub_string, $attributes);
}


1;
