package PICA::Writer::XML;
use strict;
use warnings;

our $VERSION = '0.33';

use Scalar::Util qw(reftype);

use parent 'PICA::Writer::Base';

sub new {
    my $self = PICA::Writer::Base::new(@_);
    $self->{fh}->print("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
    $self->start if $self->{start} // 1;
    $self;
}

sub start {
    my $fh = $_[0]->{fh};
    $fh->print("<collection xlmns=\"info:srw/schema/5/picaXML-v1.0\">\n");
}

sub write_record {
    my ($self, $record) = @_;
    $record = $record->{record} if reftype $record eq 'HASH';

    my $fh = $self->{fh};

    my $i = 0;
    my $pica_sort = sub {
        my $f = shift;
        my $oc  = ($f->[1] eq '') ? '00' : $f->[1];
        $oc = ($f->[0] eq '101@') ? ++$i . $oc : $i . $oc;
        return [$oc.$f->[0], $f];
    };

    @$record = map $_->[1], sort { $a->[0] cmp $b->[0] } map { $pica_sort->($_) } @$record;
    $fh->print("<record>\n");
    foreach my $field (@$record) {
        # this may break on invalid tag/occurrence values
        $fh->print("  <datafield tag=\"$field->[0]\"" . ( 
                defined $field->[1] && $field->[1] ne '' ?
                " occurrence=\"$field->[1]\"" : ""
            ) . ">\n");
            for (my $i=2; $i<scalar @$field; $i+=2) {
                my $value = $field->[$i+1];
                $value =~ s/</&lt;/g;
                $value =~ s/&/&amp;/g;
                # TODO: disallowed code points (?)
                $fh->print("    <subfield code=\"$field->[$i]\">$value</subfield>\n");
            } 
        $fh->print("  </datafield>\n");
    }
    $fh->print("</record>\n");
}

sub end {
    $_[0]->{fh}->print("</collection>\n");
}

1;
__END__

=head1 NAME

PICA::Writer::XML - PICA+ XML format serializer

=head2 DESCRIPTION

See L<PICA::Writer::Base> for synopsis and details.

The counterpart of this module is L<PICA::Parser::XML>.

=head2 METHODS

In addition to C<write>, this writer also contains methods C<start> and C<end>
to emit an XML header with start tag C<< <collection> >> or an end tag,
respectively. The start method is automatically called on construction, unless
suppressed with option C<< start => 0 >>:

    my $writer = PICA::Writer::XML->new( fh => $file, start => 0 );
    $writer->write( $record ); # no <collection> start tag

The C<end> method does not close the underlying file handle.

=cut
