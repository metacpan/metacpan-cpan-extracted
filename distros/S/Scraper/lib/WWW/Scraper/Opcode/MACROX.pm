
use strict;

package WWW::Scraper::Opcode::MACROX; use base qw(WWW::Scraper::Opcode::MACRO);

sub new {
    return bless {'fieldsDiscovered
    ' => undef};
}

sub scrape {
    my ($self, $scraper, $scaffold, $TidyXML, $hit) = @_;
    
    my $macroName = $$scaffold[1];
    return ($self->SUPER::MacroScaffolds->{$macroName}, undef);
}



1;
