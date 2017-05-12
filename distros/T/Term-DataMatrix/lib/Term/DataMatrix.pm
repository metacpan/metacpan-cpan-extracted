package Term::DataMatrix;
use strict;
use warnings;
our $VERSION = '0.01';

use Carp;
use Term::ANSIColor;
require Barcode::DataMatrix;

sub new {
    my($class, %args) = @_;
    bless {
	# Barcode::DataMatrix doesn't take any constructor params
        text_dmcode => Barcode::DataMatrix->new(),
        white_text  => colored('  ', delete $args{white} || 'on_white'),
        black_text  => colored('  ', delete $args{black} || 'on_black'),
        %args,
    }, $class;
}

sub plot {
    my($self, $text) = @_;
    croak 'Not enough arguments for plot()' unless $text;

    my $arref = $self->{text_dmcode}->barcode($text);
    $self->_add_blank($arref);
    $self->{stdoutbuf} = join "\n", map { join '', map {
	    $_ ? $self->{black_text} : $self->{white_text}
    } @$_ } @$arref;
}

sub _add_blank {
    my($self, $ref) = @_;
    unshift @$_, 0 and push @$_, 0 for @$ref;
    unshift @$ref, [(0) x scalar @{$ref->[0]}];
    push    @$ref, [(0) x scalar @{$ref->[0]}];
}

1;
__END__

=head1 NAME

Term::DataMatrix - Generate terminal base DataMatrix 2D Code

=head1 SYNOPSIS

  use Term::DataMatrix;
  print Term::DataMatrix->new->plot('Some text here.') . "\n";

=head1 DESCRIPTION

Term::DataMatrix is allows you to generate DataMatrix Code for your terminal.

Based on the code for L<Term::QRCode>.

=head1 METHODS

=over 4

=item new

    $dmcode = Term::DataMatrix->new();

The C<new()> constructor method instantiates a new Term::DataMatrix object.

=item plot($text)

    $text = $dmcode->plot("blah blah");

Create a DataMatrix Code text for terminal.

=back

=head1 AUTHOR

Dan Church E<lt>h3xx [a] gmx <d> comE<gt>

=head1 SEE ALSO

L<Term::QRCode>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
