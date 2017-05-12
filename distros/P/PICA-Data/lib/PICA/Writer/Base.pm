package PICA::Writer::Base;
use strict;
use warnings;

our $VERSION = '0.31';

use Scalar::Util qw(blessed openhandle reftype);
use Carp qw(croak);

sub new {
    my $class = shift;
    my (%options) = @_ % 2 ? (fh => @_) : @_;

    my $self = bless \%options, $class;

    my $fh = $self->{fh} // \*STDOUT;
    if (!ref $fh) {
        if ( open(my $handle, '>:encoding(UTF-8)', $fh) ) {
            $fh = $handle; 
        } else {
            croak "cannot open file for writing: $fh\n";
        }
    } elsif (reftype $fh eq 'SCALAR' and !blessed $fh) {
        open(my $handle, '>>', $fh);
        $fh = $handle; 
    } elsif (!openhandle($fh) and !(blessed $fh && $fh->can('print'))) {
        croak 'expect filehandle or object with method print!'
    }    
    $self->{fh} = $fh;

    $self;
}

sub write {
    my $self = shift;
    $self->write_record($_) for @_;
}

sub write_record {
    my ($self, $record) = @_;
    $record = $record->{record} if reftype $record eq 'HASH';

    my $fh = $self->{fh};

    foreach my $field (@$record) {
        $fh->print($field->[0]);
        if (defined $field->[1] and $field->[1] ne '') {
            $fh->print(sprintf("/%02d",$field->[1]));
        }
        $fh->print(' ');
        for (my $i=2; $i<scalar @$field; $i+=2) {
            $self->write_subfield($field->[$i], $field->[$i+1]);
        }
        $fh->print($self->END_OF_FIELD);
    }
    $fh->print($self->END_OF_RECORD);
}

1;
__END__

=head1 NAME

PICA::Writer::Base - Base class of PICA+ writers

=head1 SYNOPSIS

    use PICA::Writer::Plain;
    my $writer = PICA::Writer::Plain->new( $fh );

    foreach my $record (@pica_records) {
        $writer->write($record);
    }

    use PICA::Writer::Plus;
    $writer = PICA::Writer::Plus->new( $fh );
    ...

    use PICA::Writer::XML;
    $writer = PICA::Writer::XML->new( $fh );
    ...

=head1 DESCRIPTION

This abstract base class of PICA+ writers should not be instantiated directly.
Use one of the following subclasses instead:

=over 

=item L<PICA::Writer::Plain>

=item L<PICA::Writer::Plus>

=item L<PICA::Writer::XML>

=back

=head1 METHODS

=head2 new( [ $fh | fh => $fh ] )

Create a new PICA writer, writing to STDOUT by default. The optional C<fh>
argument can be a filename, a handle or any other blessed object with a
C<print> method, e.g. L<IO::Handle>.

L<PICA::Data> also provides a functional constructor C<pica_writer>.

=head2 write ( @records )

Writes one or more records, given as hash with key 'C<record>' or as array
reference with a list of fields, as described in L<PICA::Data>.

=head2 write_record ( $record ) 

Writes one record.

=head1 SEEALSO

See L<Catmandu::Exporter::PICA> for usage of this module within the L<Catmandu>
framework (recommended). 

Alternative (outdated) PICA+ writers had been implemented as L<PICA::Writer>
and L<PICA::XMLWriter> included in the release of L<PICA::Record>.

=cut
