
use strict;

package WWW::Scraper::Opcode::BODY;
use base qw(WWW::Scraper::Opcode);
use vars qw($VERSION);

# new() Scraper::Opcode
#  $cls - Op class
#  $scaffold - current scaffold
#  $params - ref to array of parames in the 'OP()' portion of the scaffold.
sub new {
    my ($cls, $scaffold, $params) = @_;
    my $self = bless {};
    $self->{'fieldsDiscovered'} = ['background','bgcolor'];
    return $self;
}

sub scrape {
    my ($self, $scraper, $scaffold, $TidyXML, $hit) = @_;
    
    # This if/else clauses handle the legacy versions of the 'BODY' opcode.
    my $sub_string = undef;
    if ( ref($$scaffold[1]) eq 'ARRAY' ) {
        # This else clause is the only real, new Opcode, version of the 'BODY' opcode.
        my ($sub_string, $attributes) = $TidyXML->getMarkedTextAndAttributes('BODY');
        return undef unless $attributes;
        
        return ($$scaffold[1], $sub_string, $attributes);
    }
    elsif ( $$scaffold[1] and $$scaffold[2] ) {
        ${$TidyXML->asString()} =~ s-$$scaffold[1](.*?)$$scaffold[2]--si; # Strip off the adminstrative clutter at the beginning and end.
        $sub_string = $1 || '';
    } elsif ( $$scaffold[1] ) {
        ${$TidyXML->asString()} =~ s-$$scaffold[1](.*)$-$1-si; # Strip off the adminstrative clutter at the beginning.
        $sub_string = $1 || '';
    } elsif ( $$scaffold[2] ) {
        ${$TidyXML->asString()} =~ s-^(.*?)$$scaffold[2]-$1-si; # Strip off the adminstrative clutter at the end.
        $sub_string = $1 || '';
    } else {
        return undef;
    }
    
    # Continuing for the legacy versions of the 'BODY' opcode.
    if ( $$scaffold[3] && ('ARRAY' ne ref $$scaffold[3]) ) # if next_scaffold is an array ref, then we'll recurse (below)
    {
        if ( $sub_string ) {
            my $binding = $$scaffold[3];
            my $datParser = $$scaffold[4];
            $datParser = \&WWW::Scraper::trimTags unless $datParser;
            if ( $binding eq 'url' )
            {
                my $url = new URI::URL(&$datParser($scraper, $hit, $sub_string), $scraper->{_base_url});
                $url = $url->abs();
                $hit->plug_url($url);
            } 
            elsif ( $binding) {
                my $dat = &$datParser($scraper, $hit, $sub_string);
                $hit->plug_elem($binding, $dat) if defined $dat;
            }
        }
    }

    return ($self->_next_scaffold($scaffold), $sub_string, undef);
}


1;
