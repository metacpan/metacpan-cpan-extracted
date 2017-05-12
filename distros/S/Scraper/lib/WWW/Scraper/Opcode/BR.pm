
use strict;

package WWW::Scraper::Opcode::BR;
use base qw(WWW::Scraper::Opcode);
use vars qw($VERSION);

# new() Scraper::Opcode
#  $cls - Op class
#  $scaffold - current scaffold
#  $params - ref to array of parames in the 'OP()' portion of the scaffold.
sub newX {
    my ($cls, $scaffold, $params) = @_;
    my $self = bless {};
    $self->{'fieldsDiscovered'} = ['content'];
    return $self;
}

sub scrape {
    my ($self, $scraper, $scaffold, $TidyXML, $hit) = @_;
    
    my $sub_string = ${$TidyXML->asString()};
    return undef unless $sub_string =~ s{(<BR>(.*?))<BR>}{}gsi;
    my $dat = $2;
    $hit->description(\$dat);

    return ($self->_next_scaffold($scaffold), $sub_string, undef);
}


1;
