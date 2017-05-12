package PostScript::Barcode::azteccode;
use 5.010;
use utf8;
use strict;
use warnings FATAL => 'all';
use Moose qw(with has);
use PostScript::Barcode::Meta::Types qw();

with qw(PostScript::Barcode);

our $VERSION = '0.006';

has 'parse'      => (is => 'rw', isa => 'PostScript::Barcode::Meta::Types::Bool',);
has 'eclevel'    => (is => 'rw', isa => 'PostScript::Barcode::Meta::Types::Num',);
has 'ecaddchars' => (is => 'rw', isa => 'PostScript::Barcode::Meta::Types::Num',);
has 'layers'     => (is => 'rw', isa => 'PostScript::Barcode::Meta::Types::Num',);
has 'format'     => (is => 'rw', isa => 'PostScript::Barcode::Meta::Types::Enum::azteccode::format',);
has 'readerinit' => (is => 'rw', isa => 'PostScript::Barcode::Meta::Types::Bool',);
has 'raw'        => (is => 'rw', isa => 'PostScript::Barcode::Meta::Types::Bool',);

1;

__END__

=encoding UTF-8

=head1 NAME

PostScript::Barcode::azteccode - Aztec Code


=head1 VERSION

This document describes C<PostScript::Barcode::azteccode> version C<0.006>.


=head1 SYNOPSIS

    use PostScript::Barcode::azteccode qw();
    my $barcode = PostScript::Barcode::azteccode->new(data => 'foo bar');
    $barcode->render;


=head1 DESCRIPTION

Attributes are described at
L<http://groups.google.com/group/postscriptbarcode/web/aztec-code>.


=head1 INTERFACE

=head2 Attributes

In addition to L<PostScript::Barcode/"Attributes">:

=head3 C<parse>

Type C<Bool>

=head3 C<eclevel>

Type C<Num>

=head3 C<ecaddchars>

Type C<Num>

=head3 C<layers>

Type C<Num>

=head3 C<format>

Type C<PostScript::Barcode::Meta::Types::Enum::azteccode::format>

=head3 C<readerinit>

Type C<Bool>

=head3 C<raw>

Type C<Bool>
