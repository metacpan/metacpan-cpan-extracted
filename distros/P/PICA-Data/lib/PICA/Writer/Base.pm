package PICA::Writer::Base;
use v5.14.1;

our $VERSION = '2.12';

use Scalar::Util qw(blessed openhandle reftype);
use PICA::Schema qw(clean_pica);
use Term::ANSIColor;
use Encode qw(decode);
use Carp   qw(croak);

sub new {
    my $class = shift;
    my (%options) = @_ % 2 ? (fh => @_) : @_;

    my $self = bless \%options, $class;

    my $fh = $self->{fh} // \*STDOUT;
    if (!ref $fh) {
        if (open(my $handle, '>:encoding(UTF-8)', $fh)) {
            $fh = $handle;
        }
        else {
            croak "cannot open file for writing: $fh\n";
        }
    }
    elsif (reftype $fh eq 'SCALAR' and !blessed $fh) {
        if (length $$fh) {
            $$fh = decode("UTF-8", $$fh);
        }
        open(my $handle, '>>:encoding(UTF-8)', $fh);
        $fh = $handle;
    }
    elsif (!openhandle($fh) and !(blessed $fh && $fh->can('print'))) {
        croak 'expect filehandle or object with method print!';
    }
    $self->{fh} = $fh;

    $self;
}

sub write {
    my $self = shift;
    $self->write_record($_) for @_;
    $self;
}

sub write_identifier {
    my ($self, $field) = @_;

    my $fh  = $self->{fh};
    my %col = %{$self->{color} // {}};

    $fh->print($col{tag} ? colored($field->[0], $col{tag}) : $field->[0]);

    if ($field->[1] > 0) {
        my $occ = sprintf("%02d", $field->[1]);
        $fh->print(($col{syntax} ? colored('/', $col{syntax}) : '/')
            . ($col{occurrence} ? colored($occ, $col{occurrence}) : $occ));
    }
}

sub write_record {
    my ($self, $record) = @_;
    $record = clean_pica(
        $record,
        allow_empty_subfields => 1,
        ignore_empty_records  => 1
    ) or return;
    return unless @$record;

    my $fh = $self->{fh};
    $self->write_field($_) for @$record;
    $fh->print($self->END_OF_RECORD);
}

sub write_field {
    my ($self, $field) = @_;

    $self->write_start_field($field);

    for (my $i = 3; $i < scalar @$field; $i += 2) {
        $self->write_subfield($field->[$i - 1], $field->[$i]);
    }

    $self->{fh}->print($self->END_OF_FIELD);
}

sub annotation {
    my ($self, $field) = @_;

    return unless $self->{annotate} // @$field % 2;
    return @$field % 2 ? $field->[$#$field] : " ";
}

sub write_start_field {
    my ($self, $field) = @_;

    # ignore annotation by default
    $self->write_identifier($field);
    $self->{fh}->print(' ');
}

sub write_subfield {
    my ($self, $code, $value) = @_;
    $self->{fh}->print($self->SUBFIELD_INDICATOR . $code . $value);
}

sub end {
    my $self = shift;
    close $self->{fh} if $self->{fh} ne \*STDOUT;
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

=item L<PICA::Writer::PPXML>

=item L<PICA::Writer::JSON>

=item L<PICA::Writer::Generic>

=item L<PICA::Writer::Patch>

=back

=head1 METHODS

=head2 new( [ $fh | fh => $fh ] [ %options ] )

Create a new PICA writer, writing to STDOUT by default. The optional C<fh>
argument can be a filename, a handle or any other blessed object with a
C<print> method, e.g. L<IO::Handle>.

L<PICA::Data> also provides a functional constructor C<pica_writer>.

=head2 write ( @records )

Writes one or more records, given as hash with key 'C<record>' or as array
reference with a list of fields, as described in L<PICA::Data>. Records
are syntactically validated with L<PICA::Schema>'s C<clean_pica>.

=head2 write_record ( $record ) 

Writes one record.

=head2 end

Finishes writing by closing the file handle (unless writing to STDOUT).

=head1 OPTIONS

=head2 color

Syntax highlighting can be enabled for L<PICA::Writer::Plain> and
L<PICA::Writer::Plus> using color names from L<Term::ANSIColor>, e.g.

    pica_writer('plain', color => {
      tag => 'blue',
      occurrence => 'magenta',
      code => 'green',
      value => 'white',
      syntax => 'yellow',
    })

=head2 annotate

Writer L<PICA::Writer::Plain> and L<PICA::Writer::Plus> includes optional field
annotations. Set this option to true to enforce field annotations (set to an
empty space if missing) or to false to ignore them.

=head1 SEE ALSO

See L<PICA::Parser::Base> for corresponding parser modules.

See L<Catmandu::Exporter::PICA> for usage of this module within the L<Catmandu>
framework (recommended). 

Alternative (outdated) PICA+ writers had been implemented as L<PICA::Writer>
and L<PICA::XMLWriter> included in the release of L<PICA::Record>.

=cut
