package PDF::QRCode;
use Text::QRCode;
use Sub::Util qw(set_subname);
our $VERSION = '0.1.0';
=pod

=begin markdown

![](https://github.com/oetiker/pdf-qrcode/workflows/Unit%20Tests/badge.svg?branch=main)

=end markdown


=head1 NAME

PDF::QRCode - add qrcode method to a PDF::API2 or PDF::Builder.

=head1 SYNOPSIS

 use PDF::API2; # or PDF::Builder
 use PDF::QRCode;

 my $pdf = PDF::API2->new(-file=>'qr.pdf');
 $pdf->mediabox('a4');
 my $gfx = $pdf->page->gfx;
 $gfx->qrcode(x => 100, y => 100, 
    level => 'L', size => 40, text => 'Hello World');
 $pdf->save;

=head1 DESCRIPTION

The L<PDF::QRCode> module monkey patches the 'qrcode' method into the
L<PDF::API2::Content> or L<PDF::Builder::Content> class, so that you can use it directly from there. See the example above
 
=head2 $gfx->qrcode(%cfg)

Adds a qr code to the given gfx content. It expects the following parameters:

=over

=item x

horizontal position

=item y

vertical position

=item size

width/height

=item text

the content of the qrcode

=item level (optional)

qr code level C<L>, C<M>, C<Q>, C<H>

=back

=cut

my $qrcode = sub {
    my $ct = shift;
    my %cfg = ref $_[0] eq 'HASH' ? %$_[0] : (@_);
    $ct->save();
    $ct->translate($cfg{x},$cfg{y});
    my $code = Text::QRCode->new(
        level => $cfg{level} || 'L', # L M Q H
        mode => '8-bit',
        casesensitive => '1'
    )->plot($cfg{text});
    my $width = scalar @$code;
    my $scale = $cfg{size}/$width;
    $ct->scale($scale,$scale);
    my $oy = 0;
    for my $row (@$code) {
        my $ox = 0;
        for my $dot (@$row) {
            if ($dot eq '*') {
                $ct->add($ox,$oy,1,-1,'re');
            }
            $ox++;
        }
        $oy--;
    }
    $ct->fill();
    $ct->restore();
};

sub _monkey_patch {
  my ($class, %patch) = @_;
  no strict 'refs';
  no warnings 'redefine';
  *{"${class}::$_"} = set_subname("${class}::$_", $patch{$_}) for keys %patch;
}

my $loaded;
if ($INC{'PDF/API2/Content.pm'}) {
    $loaded = 1;
    _monkey_patch 'PDF::API2::Content', 'qrcode', $qrcode;
}

if ($INC{'PDF/Builder/Content.pm'}) {
    $loaded = 1;
    _monkey_patch 'PDF::Builder::Content', 'qrcode', $qrcode;
}

if (not $loaded) {
    die __PACKAGE__ . " not loaded since neither PDF::API2 nor PDF::Builder is present. Make sure to 'use' one of them before 'using' this package.\n";
}
1;

=head1 AUTHOR

S<Tobias Oetiker, E<lt>tobi@oetiker.chE<gt>>

=head1 COPYRIGHT

Copyright OETIKER+PARTNER AG 2020

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10 or,
at your option, any later version of Perl 5 you may have available.

=cut