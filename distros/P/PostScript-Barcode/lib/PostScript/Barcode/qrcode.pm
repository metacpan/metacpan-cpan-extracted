package PostScript::Barcode::qrcode;
use 5.010;
use utf8;
use strict;
use warnings FATAL => 'all';
use Moose qw(with has);
use PostScript::Barcode::Meta::Types qw();

with qw(PostScript::Barcode);

our $VERSION = '0.006';

has 'parse'   => (is => 'rw', isa => 'PostScript::Barcode::Meta::Types::Bool',);
has 'eclevel' => (is => 'rw', isa => 'PostScript::Barcode::Meta::Types::Enum::qrcode::eclevel',);
has 'version' => (is => 'rw', isa => 'PostScript::Barcode::Meta::Types::Enum::qrcode::version',);
has 'format'  => (is => 'rw', isa => 'PostScript::Barcode::Meta::Types::Enum::qrcode::format',);
has 'raw'     => (is => 'rw', isa => 'PostScript::Barcode::Meta::Types::Bool',);

1;

__END__

=encoding UTF-8

=head1 NAME

PostScript::Barcode::qrcode - QR code


=head1 VERSION

This document describes C<PostScript::Barcode::qrcode> version C<0.006>.


=head1 SYNOPSIS

    use PostScript::Barcode::qrcode qw();
    my $barcode = PostScript::Barcode::qrcode->new(data => 'foo bar');
    $barcode->render;


=head1 DESCRIPTION

Attributes are described at
L<http://groups.google.com/group/postscriptbarcode/web/Code+39-2>.


=head1 INTERFACE

=head2 Attributes

In addition to L<PostScript::Barcode/"Attributes">:

=head3 C<parse>

Type C<Bool>

=head3 C<eclevel>

Type C<PostScript::Barcode::Meta::Types::Enum::qrcode::eclevel>

=head3 C<version>

Type C<PostScript::Barcode::Meta::Types::Enum::qrcode::version>

=head3 C<format>

Type C<PostScript::Barcode::Meta::Types::Enum::qrcode::format>

=head3 C<raw>

Type C<Bool>
