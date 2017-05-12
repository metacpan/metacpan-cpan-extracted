
use strict;

package WWW::Scraper::Opcode::GRUB;
use base qw(WWW::Scraper::Opcode);
use vars qw($VERSION);

# new() Scraper::Opcode
#  $cls - Op class
#  $scaffold - current scaffold
#  $params - ref to array of params in the 'OP()' portion of the scaffold.
sub new {
    my ($cls, $scaffold, $params) = @_;
    my $self = bless {};
    return $self;
}

sub scrape {
    my ($self, $scraper, $scaffold, $TidyXML, $hit) = @_;

    my @grubFields = @$scaffold;
    shift @grubFields;
    for ( @grubFields ) {
        my $grubName = $_;
        my @grubUrls = $hit->$grubName();
        my $grubLevel = $hit->_grubLevel;
        my $grubUrl = $grubUrls[$grubLevel];
        if ( $grubUrl ) {
            my $url = new URI::URL($$grubUrl, $scraper->{_base_url});
            $grubUrl = $url->abs();
            $hit->_gotDetailPage(''); # gotDetailPage() helps JIT processing, but this is not JIT, it's "GRUB".
            $hit->_grubLevel($grubLevel+1);
            $hit->ScrapeDetailPage(\$grubUrl);
            $hit->_grubLevel($grubLevel);
        }
    }
    return undef;
}


1;
