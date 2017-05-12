
use strict;

package WWW::Scraper::Opcode::TR;
use base qw(WWW::Scraper::Opcode);
use vars qw($VERSION);

# new() Scraper::Opcode
#  $cls - Op class
#  $scaffold - current scaffold
#  $params - ref to array of parames in the 'OP()' portion of the scaffold.
sub new {
    my ($cls, $scaffold, $params) = @_;
    my $self = bless {};
    my @scfld = @$scaffold;
    shift @scfld;
    my @fields;
    map { push @fields, $_ unless !$_ || ref($_) || m{^#} } @scfld;
    $self->{'fieldsCaptured'} = \@fields;
    $self->{'fieldsDiscovered'} = ['name','content'];
    return $self;
}

sub scrape {
    my ($self, $scraper, $scaffold, $TidyXML, $hit) = @_;
    
    my ($sub_string, $attributes) = $TidyXML->getMarkedTextAndAttributes('TR');
    return undef unless defined($sub_string);
    
    my @ary = @$scaffold;
    shift @ary;
    my $fldnam = shift @ary;
    if ( $fldnam && (ref($fldnam) ne 'ARRAY') ) {
        $hit->plug_elem($fldnam, ${$TidyXML->asString()}, $TidyXML);
    }

    return ($self->_next_scaffold($scaffold), $sub_string, $attributes);
}


1;
