package PostScript::Barcode::datamatrix;
use 5.010;
use utf8;
use strict;
use warnings FATAL => 'all';
use Moose qw(with has);
use PostScript::Barcode::Meta::Types qw();

with qw(PostScript::Barcode);

our $VERSION = '0.006';

has 'parse'    => (is => 'rw', isa => 'PostScript::Barcode::Meta::Types::Bool',);
has 'encoding' => (is => 'rw', isa => 'PostScript::Barcode::Meta::Types::Enum::datamatrix::encoding',);
has 'rows'     => (is => 'rw', isa => 'PostScript::Barcode::Meta::Types::Num',);
has 'columns'  => (is => 'rw', isa => 'PostScript::Barcode::Meta::Types::Num',);
has 'raw'      => (is => 'rw', isa => 'PostScript::Barcode::Meta::Types::Bool',);

1;

__END__

=encoding UTF-8

=head1 NAME

PostScript::Barcode::datamatrix - Data Matrix


=head1 VERSION

This document describes C<PostScript::Barcode::datamatrix> version C<0.006>.


=head1 SYNOPSIS

    use PostScript::Barcode::datamatrix qw();
    my $barcode = PostScript::Barcode::datamatrix->new(data => 'foo bar');
    $barcode->render;


=head1 DESCRIPTION

Attributes are described at
L<http://groups.google.com/group/postscriptbarcode/web/data-matrix>.


=head1 INTERFACE

=head2 Attributes

In addition to L<PostScript::Barcode/"Attributes">:

=head3 C<parse>

Type C<Bool>

=head3 C<encoding>

Type C<PostScript::Barcode::Meta::Types::Enum::datamatrix::encoding>

=head3 C<rows>

Type C<Num>

=head3 C<columns>

Type C<Num>

=head3 C<raw>

Type C<Bool>
