
use strict;

package WWW::Scraper::Opcode::FORM;
use base qw(WWW::Scraper::Opcode);
use vars qw($VERSION);

# new() Scraper::Opcode
#  $cls - Op class
#  $scaffold - current scaffold
#  $params - ref to array of params in the 'OP()' portion of the scaffold.
sub new {
    return bless {'fieldsDiscovered' => ['name','action','method'] };
}

sub scrape {
    my ($self, $scraper, $scaffold, $TidyXML, $hit) = @_;
    
    my ($sub_string, $attributes) = $TidyXML->getMarkedTextAndAttributes('FORM');
    return undef unless $attributes;

    return ($self->_next_scaffold($scaffold), $sub_string, $attributes);
}


1;
