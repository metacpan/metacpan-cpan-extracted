package SPVM::AI::Util;

use 5.006;
use strict;
use warnings;

=head1 NAME

SPVM::AI::Util - AI Utilities for array operations, matrix operations, activate function, and cost function etc.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use SPVM::AI::Util;

    my $mat1 = SPVM::AI::Util->mat_newf([1.2f, 1.3, 1.4], 3, 2);
    my $mat2 = SPVM::AI::Util->mat_newf([1.5f, 1.1, 1.2], 3, 2);
    
    my $mat_add = SPVM::AI::Util->mat_addf($mat1, $mat2);

=head1 DESCRIPTION

SPVM::AI::Util is AI Utilities for array operations, matrix operations, activate function, and cost function etc.

This is SPVM module. You can write programing logic using SPVM Language or binding C/C++/cuda language.

=head1 STATIC METHODS

=head2 mat_newf

  sub mat_newf : SPVM::AI::Util::FloatMatrix ($values : float[], $rows_length: int, $columns_length : int)

Create new L<SPVM::AI::Util::FloatMatrix> object.

B<Arguments:>

1. Values. this value is set to C<values> field. Note that the reference is set to C<values> field not creating new array which elements is copied from argument array. Elements order is assumed as Column-Major order.

2. Row. This value is set to C<rows_length> field.

3. Column. This value is set to C<columns_length> field.

B<Return Value:>

L<SPVM::AI::Util::FloatMatrix> object.

B<Exception:>

1. If Values is not defined, a exception occurs.

2. If Values length is different from Row * Column, a exception occurs.

=head2 mat_new_zerof

  sub mat_new_zerof : SPVM::AI::Util::FloatMatrix ($rows_length: int, $columns_length : int)

Create new L<SPVM::AI::Util::FloatMatrix> object with zero value.

=head2 mat_new_identf

  sub mat_new_identf : SPVM::AI::Util::FloatMatrix ($dim : int)

Create new ident <SPVM::AI::Util::FloatMatrix> by specifing the dimention.

=head2 mat_transposef

  sub mat_transposef : SPVM::AI::Util::FloatMatrix ($mat : SPVM::AI::Util::FloatMatrix)

Transpose float matrix and return new L<SPVM::AI::Util::FloatMatrix> object.

=head2 mat_addf

  sub mat_addf : SPVM::AI::Util::FloatMatrix ($mat1 : SPVM::AI::Util::FloatMatrix, $mat2 : SPVM::AI::Util::FloatMatrix)

Add two float Matrix and return new L<SPVM::AI::Util::FloatMatrix> object.

=head2 mat_subf

  sub mat_subf : SPVM::AI::Util::FloatMatrix ($mat1 : SPVM::AI::Util::FloatMatrix, $mat2 : SPVM::AI::Util::FloatMatrix)

Subtract two float Matrix and return new L<SPVM::AI::Util::FloatMatrix> object.

=head2 mat_scamulf

  sub mat_scamulf : SPVM::AI::Util::FloatMatrix ($scalar : float, $mat1 : SPVM::AI::Util::FloatMatrix)

Scalar multiply float matrix and return new L<SPVM::AI::Util::FloatMatrix> object.

=head2 mat_mulf

  sub mat_mulf : SPVM::AI::Util::FloatMatrix ($mat1 : SPVM::AI::Util::FloatMatrix, $mat2 : SPVM::AI::Util::FloatMatrix)

Multiply two float Matrix and return new L<SPVM::AI::Util::FloatMatrix> object.

=head2 mat_strf

  sub mat_strf : string ($mat : SPVM::AI::Util::FloatMatrix)

Convert Matrix Content to String. Each column is joined 1 space and Each row is end with \n

1 3 5
2 4 6

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by Yuki Kimoto.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 AUTHOR

Yuki Kimoto, C<< <kimoto.yuki at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-spvm-ai-util at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=SPVM-AI-Util>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SPVM::AI::Util


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=SPVM-AI-Util>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SPVM-AI-Util>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/SPVM-AI-Util>

=item * Search CPAN

L<https://metacpan.org/release/SPVM-AI-Util>

=back
