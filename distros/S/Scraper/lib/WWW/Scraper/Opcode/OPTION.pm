
use strict;

package WWW::Scraper::Opcode::OPTION;
use base qw(WWW::Scraper::Opcode);
use vars qw($VERSION);

# new() Scraper::Opcode
#  $cls - Op class
#  $scaffold - current scaffold
#  $params - ref to array of params in the 'OP()' portion of the scaffold.
sub new {
    my ($cls, $scaffold, $params) = @_;
    my $self = bless {};
    $self->{'fieldsDiscovered'} = ['value','caption'];
    return $self;
}

sub scrape {
    my ($self, $scraper, $scaffold, $TidyXML, $hit) = @_;
    
    my $sub_string = $TidyXML->asString;
    return undef unless $$sub_string =~ s{<OPTION(\s+[^>]*)>(.*?)(<OPTION|</OPTION|$)}{$3}si;
    
    my $caption = $2;
    chomp $caption;
    $hit->caption(\$caption);
    
    my $attributes = $TidyXML->Attributes($1);
    
    $hit->value(\$attributes->{'value'});

    return ($self->_next_scaffold($scaffold), $sub_string, $attributes);
}


1;
