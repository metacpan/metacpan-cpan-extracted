
use strict;

package WWW::Scraper::Opcode::MACRO; use base qw(WWW::Scraper::Opcode);

my $MacroScaffolds; # Static hash of macro names => scaffolds.
sub MacroScaffolds { $MacroScaffolds }

sub new {
    my ($cls, $scaffold, $params) = @_;
    return bless {'fieldsDiscovered' => undef};
}

sub scrape {
    my ($self, $scraper, $scaffold, $TidyXML, $hit) = @_;
    
    my ($macroName, $next_scaffold) = ($$scaffold[1], $$scaffold[2]);
    $MacroScaffolds->{$macroName} = $next_scaffold;
    return ($next_scaffold, undef);
}

1;
