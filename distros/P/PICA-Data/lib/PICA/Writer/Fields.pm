package PICA::Writer::Fields;
use v5.14.1;

our $VERSION = '1.19';

use parent 'PICA::Writer::Base';

use Scalar::Util qw(reftype);
use PICA::Schema qw(clean_pica field_identifier);

sub write_record {
    my ($self, $record) = @_;
    $record = clean_pica($record) or return;

    my $fh     = $self->{fh};
    my $seen   = $self->{seen} // ($self->{seen} = {});
    my $schema = $self->{schema};

    foreach my $field (@$record) {
        my $id = field_identifier($schema ? $schema : (), $field);

        next if $seen->{$id};
        $seen->{$id} = 1;

        $fh->print($id);

        if ($schema) {
            my $def = $schema->{fields}{$id};
            my $label = $def ? $def->{label} // '' : '?';
            $fh->print("\t" . $label =~ s/[\r\n]+/ /mgr);
        }

        $fh->print("\n");
    }
}

1;
__END__

=head1 NAME

PICA::Writer::Fields - Summarize fields used in PICA+ records

=head2 DESCRIPTION

This writer shows information about fields used in PICA+ records. Every field
is only shown once. A L<PICA::Schema> can be provided with argument C<schema>
to shown field labels, if included in the schema.

=cut
