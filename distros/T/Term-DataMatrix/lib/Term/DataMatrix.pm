package Term::DataMatrix 1.000000;
use 5.012;
use warnings;

require Barcode::DataMatrix;
use Carp qw/ croak /;
use fields qw/
    black
    black_text
    text_dmcode
    white
    white_text
/;
use Term::ANSIColor qw/ colored /;

=head1 NAME

Term::DataMatrix - Generate terminal-based Data Matrix 2D barcodes

=head1 SYNOPSIS

    require Term::DataMatrix;

    print Term::DataMatrix->new->plot('Some text here.') . "\n";

=head1 DESCRIPTION

Term::DataMatrix generates Data Matrix 2D barcodes on the terminal.

=head1 METHODS

=head2 C<new()>

    my $dmcode = Term::DataMatrix->new( %options );

Instantiate a new L<Term::DataMatrix> object. Key/value pair arguments may be
provided to set up the initial state. The following options are recognized:

   KEY                     DEFAULT
   -----------             --------------------
   black                   'on_black'
   black_text              Term::ANSIColor::colored('  ', $black)
   text_dmcode             Barcode::DataMatrix->new
   white                   'on_white'
   white_text              Term::ANSIColor::colored('  ', $white)

=over

=item black, white

What color to make the foreground (black) and the background (white) of the generated
barcode. See L<Term::ANSIColor> for recognized colors.

=item black_text, white_text

What colored text to use for each of the foreground (black) and background
(white) pixels of the generated barcode. Can be used to stretch the barcode
width-wise.

=item text_dmcode

What object to use as the barcode's data generator. See L<Barcode::DataMatrix>.

=back

=cut

sub new {
    my ($class, %args) = @_;
    my Term::DataMatrix $self = fields::new($class);
    %{$self} = (%{$self}, %args);

    # Barcode::DataMatrix doesn't take any constructor params
    $self->{text_dmcode} //= Barcode::DataMatrix->new;
    $self->{white_text} //= colored('  ', $self->{white} // 'on_white');
    $self->{black_text} //= colored('  ', $self->{black} // 'on_black');
    return $self;
}

=head2 C<plot($text)>

    $barcode = $dmcode->plot('blah blah');

Create a Data Matrix barcode text for terminal.

=cut

sub plot {
    my ($self, $text) = @_;
    unless ($text) {
        croak('Not enough arguments for plot()');
    }

    my $arref = $self->{text_dmcode}->barcode($text);
    _add_blank($arref);
    return join "\n", map { join '', map {
	    $_ ? $self->{black_text} : $self->{white_text}
    } @{$_} } @{$arref};
}

sub _add_blank {
    my ($ref) = @_;
    # Add a column of all 0 to every row
    foreach my $row (@{$ref}) {
        unshift @{$row}, 0;
        push @{$row}, 0;
    }
    # Add a row of all 0 to the beginning
    unshift @{$ref}, [(0) x scalar @{$ref->[0]}];
    # Add a row of all 0 to the end
    push @{$ref}, [(0) x scalar @{$ref->[0]}];
    return;
}

=head1 AUTHOR

Dan Church E<lt>h3xx [a] gmx <d> comE<gt>

=head1 SEE ALSO

L<Term::QRCode>
L<https://en.wikipedia.org/wiki/Data_Matrix>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AVAILABILITY

The latest version of this library is likely to be available from CPAN as well
as:

L<https://codeberg.org/h3xx/perl-Term-DataMatrix>

=cut

1;
