package PICA::Writer::XML;
use strict;
use warnings;

our $VERSION = '1.00';

use Scalar::Util qw(reftype);
use XML::Writer;

use parent 'PICA::Writer::Base';

sub new {
    my $self = PICA::Writer::Base::new(@_);
    $self->{writer} = XML::Writer->new(OUTPUT => $self->{fh}, DATA_MODE => 1, DATA_INDENT => 2);
    $self->{writer}->xmlDecl('UTF-8');
    $self->{writer}->startTag('collection', xmlns => 'info:srw/schema/5/picaXML-v1.0');
    $self;
}


sub write_record {
    my ($self, $record) = @_;
    $record = $record->{record} if reftype $record eq 'HASH';

    my $writer = $self->{writer};
    my $schema = $self->{schema} // { field => { } };

    my $i = 0;
    my $pica_sort = sub {
        my $f = shift;
        my $oc  = (!defined $f->[1] or $f->[1] eq '') ? '00' : $f->[1];
        $oc = ($f->[0] eq '101@') ? ++$i . $oc : $i . $oc;
        return [$oc.$f->[0], $f];
    };

    @$record = map $_->[1], sort { $a->[0] cmp $b->[0] } map { $pica_sort->($_) } @$record;
    $writer->startTag('record');
    foreach my $field (@$record) {
        my $id = $field->[0];
        my @attr = (tag => $field->[0]);
        if ( defined $field->[1] && $field->[1] ne '') {
            push @attr, occurrence => $field->[1];
            $id = "$id/".$field->[1];
        }
        my $fielddef = $schema->{fields}{$id};
        my $sfdef;
        if ($fielddef) {
            foreach (qw(label url pica3)) {
                if (defined $fielddef->{$_}) {
                    push @attr, $_ => $fielddef->{$_};
                }
            }
            $sfdef = $fielddef->{subfields};
        }
        $writer->startTag('datafield', @attr );
        for (my $i=2; $i<scalar @$field; $i+=2) {
            my $code = $field->[$i];
            my $value = $field->[$i+1];
            my @attr = (code => $code);
            if ($sfdef && $sfdef->{$code}) {
                foreach (qw(label url pica3)) {
                    if (defined $sfdef->{$code}{$_}) {
                        push @attr, $_ => $sfdef->{$code}{$_};
                    }
                }
            }
            $writer->dataElement('subfield', $value, @attr);
        } 
        $writer->endTag('datafield');
    }
    $writer->endTag('record');
}

sub end {
    my $self = shift;
     $self->{writer}->endTag('collection');
     $self->{writer}->end();
}

1;
__END__

=head1 NAME

PICA::Writer::XML - PICA+ XML format serializer

=head2 DESCRIPTION

See L<PICA::Writer::Base> for synopsis and details. In addition a
L<PICA::Schema> can be provided to include schema information in the XML
records for human-readable documentation:

    my $writer = PICA::Writer::XML->new( fh => $file, schema => $schema );

The counterpart of this module is L<PICA::Parser::XML>.

=head2 METHODS

In addition to C<write>, this writer also contains C<end> method to finish 
creating the XML document und check for well-formedness.

    my $writer = PICA::Writer::XML->new( fh => $file );
    $writer->write( $record );
    $writer->end();

The C<end> method does not close the underlying file handle.

=cut
