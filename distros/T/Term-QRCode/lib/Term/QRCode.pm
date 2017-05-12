package Term::QRCode;
use strict;
use warnings;
our $VERSION = '0.01';

use Carp;
use Term::ANSIColor;
use Text::QRCode;

sub new {
    my($class, %args) = @_;
    bless {
        text_qrcode => Text::QRCode->new(delete $args{params} || +{}),
        white_text  => colored('  ', delete $args{white} || 'on_white'),
        black_text  => colored('  ', delete $args{black} || 'on_black'),
        %args,
    }, $class;
}

sub plot {
    my($self, $text) = @_;
    croak 'Not enough arguments for plot()' unless $text;

    my $arref = $self->{text_qrcode}->plot($text);
    $self->_add_blank($arref);
    $self->{stdoutbuf} = join "\n", map { join '', map { $_ eq '*' ? $self->{black_text} : $self->{white_text} } @$_ } @$arref;
}

sub _add_blank {
    my($self, $ref) = @_;
    unshift @$_, ' ' and push @$_, ' ' for @$ref;
    unshift @$ref, [(' ') x scalar @{$ref->[0]}];
    push    @$ref, [(' ') x scalar @{$ref->[0]}];
}

1;
__END__

=head1 NAME

Term::QRCode - Generate terminal base QR Code

=head1 SYNOPSIS

  use Term::QRCode;
  print Term::QRCode->new->plot('Some text here.') . "\n";

=head1 DESCRIPTION

Term::QRCode is allows you to generate QR Code for your terminal.

=head1 METHODS

=over 4

=item new

    $qrcode = Term::QRCode->new(%params);

The C<new()> constructor method instantiates a new Term::QRCode object.

    Term::QRCode->new(
        params => {}, # for Text::QRCode params
    );

=item plot($text)

    $text = $qrcode->plot("blah blah");

Create a QR Code text for terminal.

=back

=head1 AUTHOR

Kazuhiro Osawa E<lt>yappo <at> shibuya <döt> plE<gt>

=head1 ORIGINAL CODE

L<http://data.gyazo.com/1868c31229b41a11abd505b076fb7276.png> by nipotan

=head1 SEE ALSO

L<Text::QRCode>

=head1 REPOSITORY

  svn co http://svn.coderepos.org/share/lang/perl/Term-QRCode/trunk Term-QRCode

Term::QRCode is Subversion repository is hosted at L<http://coderepos.org/share/>.
patches and collaborators are welcome.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
