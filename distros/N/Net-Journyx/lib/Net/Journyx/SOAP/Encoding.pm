package Net::Journyx::SOAP::Encoding;
use strict;
use warnings;

use base 'XML::Compile::SOAP';

sub _dec_typed {
    my ($self, $node, $type, $index) = @_;

    my ($prefix, $local) = $type =~ m/^(.*?)\:(.*)/ ? ($1, $2) : ('',$type);
    return (shift)->SUPER::_dec_typed(@_) unless $prefix eq 'jxapi';

#    warn "manually decoding $type";

    my %res = ();
    my @childs = grep $_->isa('XML::LibXML::Element'), $node->childNodes;
    foreach my $children ( @childs ) {
        my $name = $children->nodeName;
#        warn "decoding $name of $type";
        if ( $name eq 'id' ) {
            $res{'_id'} = $self->_dec([$children], '', 0, 1);
        } else {
            $res{$name} = $self->_dec([$children], '', 0, 1);
        }
    }

    return { $local => \%res };
}

1;
