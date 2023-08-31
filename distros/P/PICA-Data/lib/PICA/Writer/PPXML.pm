package PICA::Writer::PPXML;
use v5.14.1;

our $VERSION = '2.12';

use Scalar::Util qw(reftype);
use XML::LibXML;
use PICA::Path;
use PICA::Data;    # qw(pica_holdings pica_items);

use parent 'PICA::Writer::XML';

sub namespace {
    'http://www.oclcpica.org/xmlns/ppxml-1.0';
}

sub write_field {
    my ($self, $field) = @_;

    my $writer = $self->{writer};

    $writer->startTag('tag', id => $field->[0], occ => 1 * $field->[1] || "");
    for (my $i = 3; $i < scalar @$field; $i += 2) {
        $writer->dataElement('subf', $field->[$i], id => $field->[$i - 1]);
    }
    $writer->endTag('tag');
}

sub write_record {
    my ($self, $record) = @_;
    $record = $record->{record} if reftype $record eq 'HASH';

    my $writer = $self->{writer};

    $writer->startTag('record');

    $writer->startTag('global', opacflag => "", status => "");
    $self->write_field($_) for grep {$_->[0] =~ /^0/} @$record;
    $writer->endTag('global');

    for my $holding (@{PICA::Data::pica_holdings($record)}) {
        $writer->startTag('owner', iln => $holding->{_id} // "");

        my @local = grep {$_->[0] =~ /^1/} @{$holding->{record}};
        if (@local) {
            $writer->startTag('local');
            $self->write_field($_) for @local;
            $writer->endTag('local');
        }

        for my $item (@{PICA::Data::pica_items($holding)}) {
            $writer->startTag(
                'copy',
                occ      => 1 * $item->{record}->[0][1],
                epn      => $item->{_id} // "",
                opacflag => "",
                status   => ""
            );
            $self->write_field($_) for @{$item->{record}};
            $writer->endTag('copy');
        }
        $writer->endTag('owner');
    }

    $writer->endTag('record');
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

See L<PICA::Writer::Base> for description of other methods.

=cut
