
use strict;

package WWW::Scraper::Opcode::A;
use base qw(WWW::Scraper::Opcode);
use vars qw($VERSION);

# new() Scraper::Opcode
#  $cls - Op class
#  $scaffold - current scaffold
#  $params - ref to array of parames in the 'OP()' portion of the scaffold.
sub new {
    my ($cls, $scaffold, $params) = @_;
    my $self = bless {};
    $self->{'fieldsDiscovered'} = ['name', 'content'];
    
    my @scfld = @$scaffold;
    shift @scfld;
    my @fields;
    map { push @fields, $_ unless !$_ || ref($_) || m{^#} } @scfld;
    $self->{'fieldsCaptured'} = \@fields;
    
    return $self;
}

sub scrape {
    my ($self, $scraper, $scaffold, $TidyXML, $hit) = @_;
    
    my ($sub_string, $attributes) = $TidyXML->getMarkedTextAndAttributes('A');
    return undef unless defined($sub_string);
    
    my $lbl = $$scaffold[1];
    my $datParser = $$scaffold[3];
    $datParser = \&WWW::Scraper::trimTags unless $datParser;
    my $dat = &$datParser($self, $hit, $sub_string);
    $hit->plug_elem($$scaffold[2], $dat) if defined $dat;

    my ($url) = new URI::URL($attributes->{'href'}, $scraper->{_base_url});
    $url = $url->abs();
    if ( $lbl eq 'url' ) {
       $url = WWW::Scraper::unescape_query($url) if $TidyXML->m_isTidyd();
       $hit->plug_url($url);
    }
    else {
       $hit->plug_elem($lbl, $url) if defined $url;
    }

    return ($self->_next_scaffold($scaffold), $sub_string, $attributes);
}


1;
