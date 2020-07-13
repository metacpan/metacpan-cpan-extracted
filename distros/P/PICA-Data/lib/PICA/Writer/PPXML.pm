package PICA::Writer::PPXML;
use v5.14.1;

our $VERSION = '1.12';

use Scalar::Util qw(reftype);
use XML::LibXML;
use PICA::Path;

use parent 'PICA::Writer::XML';

our $ILN = PICA::Path->new('101@$a');
our $EPN = PICA::Path->new('203@$0');

sub namespace {
    'http://www.oclcpica.org/xmlns/ppxml-1.0';
}

sub write_field {
    my ($self, $field) = @_;

    my $writer = $self->{writer};

    $writer->startTag('tag', id => $field->[0], occ => 1 * $field->[1] || "");
    for (my $i = 2; $i < scalar @$field; $i += 2) {
        $writer->dataElement('subf', $field->[$i + 1], id => $field->[$i]);
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

    my @fields = grep {$_->[0] =~ /^[12]/} @$record;

    while (@fields) {
        my $iln;
        my @local;

       # collect level 1 fields up to the first level 2 field or the next 101@
        while (@fields and $fields[0][0] =~ /^1/) {
            if ($fields[0][0] eq '101@') {
                last if defined $iln;
                ($iln) = $ILN->match_subfields($fields[0]);
            }
            push @local, shift(@fields);
        }

        my %copy;
        while (@fields && $fields[0][0] =~ /^2/) {
            my $occ = 1 * $fields[0][1] // "";
            push @{$copy{$occ}}, shift @fields;
        }

        if (%copy) {
            for my $occ (sort keys %copy) {
                $self->write_owner($iln, \@local, $copy{$occ});
            }
        }
        else {
            $self->write_owner($iln, \@local);
        }
    }

    $writer->endTag('record');
}

sub write_owner {
    my ($self, $iln, $local, $copy) = @_;

    my $writer = $self->{writer};

    $writer->startTag('owner', iln => $iln // "");

    if (@$local) {
        $writer->startTag('local');
        $self->write_field($_) for @$local;
        $writer->endTag('local');
    }

    if ($copy) {
        my $occ = 1 * $copy->[0][1] // '';
        my ($epn)
            = map {$EPN->match_subfields($_)} grep {$_->[0] eq '203@'} @$copy;
        $writer->startTag(
            'copy',
            occ      => $occ,
            epn      => $epn,
            opacflag => "",
            status   => ""
        );
        $self->write_field($_) for @$copy;
        $writer->endTag('copy');
    }

    $writer->endTag('owner');
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
