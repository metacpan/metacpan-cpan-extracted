package PICA::Writer::PPXML;
use v5.14.1;

our $VERSION = '1.08';

use Scalar::Util qw(reftype);
use XML::LibXML;
use constant NS => 'http://www.oclcpica.org/xmlns/ppxml-1.0';
use PICA::Path;

use parent 'PICA::Writer::Base';

sub new {
    my $self = PICA::Writer::Base::new(@_);
    $self->{doc}        = XML::LibXML::Document->new("1.0", "UTF-8");
    $self->{collection} = $self->{doc}->createElement("collection");
    $self->{doc}->addChild($self->{collection});
    $self;
}

sub write_record {
    my ($self, $record) = @_;
    $record = $record->{record} if reftype $record eq 'HASH';

    my $el_record = $self->{collection}->addNewChild("", "record");
    $el_record->setNamespace(NS, "ppxml");

    my $el_current = $el_record->addNewChild(NS, "global");
    $el_current->setAttribute("opacflag", "");
    $el_current->setAttribute("status",   "");

    my $tag;
    my $path;
    $path = PICA::Path->new('101@a');
    my @ilns = $path->record_subfields($record);

    $path = PICA::Path->new('203@0');
    my @epns = $path->record_subfields($record);
    my $y    = 0;
    foreach my $field (@$record)
    {    # so lange bis die Lokaldaten anfagen -> dann elem owner
        if ($field->[0] eq '101@') {

            # new element owner
            my $el_owner = $el_record->addNewChild(NS, "owner");
            $el_owner->setAttribute("iln", $ilns[$y]);

            # new element local
            my $el_local = $el_owner->addNewChild(NS, "local");
            $tag = _add_tag($el_local, $field->[0], $field->[1]);
            _add_subfields($tag, $field);

            # current element is now new element copy
            $el_current = $el_owner->addNewChild(NS, "copy");
            $el_current->setAttribute("occ",      "");
            $el_current->setAttribute("opacflag", "");
            $el_current->setAttribute("status",   "");
            $el_current->setAttribute("epn",      $epns[$y]);
            $y += 1;
            next;
        }
        $el_current->setAttribute("occ", _occ($field->[1]))
            if $el_current->hasAttribute('occ');
        $tag = _add_tag($el_current, $field->[0], $field->[1]);
        _add_subfields($tag, $field);
    }
}

sub _occ {
    my ($occ) = @_;
    $occ = (Scalar::Util::looks_like_number($occ)) ? $occ * 1 : '';
}

sub _add_tag {
    my ($el, $id, $occ) = @_;
    my $tag = $el->addNewChild(NS, "tag");
    $tag->setAttribute("id",  $id);
    $tag->setAttribute("occ", _occ($occ));
    return $tag;
}

sub _add_subfields {
    my ($el, $field) = @_;

    my $sf;
    for (my $i = 2; $i < @{$field}; $i += 2) {
        $sf = $el->addNewChild(NS, "subf");
        $sf->setAttribute("id", $field->[$i]);
        $sf->appendText($field->[$i + 1]);
    }
}

sub end {
    my ($self) = @_;
    $self->{doc}->toFH($self->{fh}, 2);
}

1;
__END__

=head1 NAME

PICA::Writer::PPXML - PicaPlus-XML format serializer

=head1 SYNOPSIS

    use PICA::Writer::PPXML;
    my $writer = PICA::Writer::PPXML->new( $fh );
    
    foreach my $record (@pica_records) {
        $writer->write($record);
    }
    
    $writer->end();

=head1 DESCRIPTION

PicaPlus-XML (PPXML) is a PICA+ XML format variant (namespace C<http://www.oclcpica.org/xmlns/ppxml-1.0>).

The counterpart of this module is L<PICA::Parser::PPXML>.

=head1 METHODS

See L<PICA::Writer::Base> for descrition of other methods.

=head2 end

Writes the document directly to a filehandle.

=cut
