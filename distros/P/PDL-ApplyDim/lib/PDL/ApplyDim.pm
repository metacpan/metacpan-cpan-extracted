package PDL::ApplyDim;

use v5.36;
our $VERSION = '0.002';
use Carp;
require Exporter;
our @ISA=qw(Exporter);
our @EXPORT=qw(apply_to apply_not_to);
no strict "refs";

sub PDL::apply_to($ndarray, $code, $dims, @extra_args){
    # if code is string, assume it is defined in caller's package
    $code="".caller. "::$code"                      #
	unless ref $code eq 'CODE' || $code =~/::/; #
    return $code->($ndarray->mv($dims, 0), @extra_args)->mv(0,$dims) unless ref $dims;
    return $code->($ndarray->reorder(_shuffle($dims, $ndarray->ndims)),
	    @extra_args)->reorder(_unshuffle($dims, $ndarray->ndims))
	if ref $dims eq "ARRAY";
    croak "Argument $dims is not scalar nor array";
}

*apply_to=\&PDL::apply_to;

sub PDL::apply_not_to($ndarray, $code, $dims, @extra_args){
    # if code is string, assume it is defined in caller's package
    $code="".caller. "::$code"                      #
	unless ref $code eq 'CODE' || $code =~/::/; #
    return $code->($ndarray->mv($dims, -1), @extra_args)->mv(-1,$dims) unless
	ref $dims;
    return $code->($ndarray->reorder(_shuffle_end($dims, $ndarray->ndims)),
	    @extra_args)->reorder(_unshuffle_end($dims, $ndarray->ndims))
	if ref $dims eq "ARRAY";
    croak "Argument $dims is not scalar nor array";
}

*apply_not_to=\&PDL::apply_not_to;


# ancillary routines

# reorder 0..$ndims-1 so @$dims go first
sub _shuffle($dims, $ndims){
    my %seen;
    $seen{$_}++ for my @shuffle=@$dims;
    $seen{$_}||push @shuffle, $_ for 0..$ndims-1;
    return @shuffle;
}

# reorder 0..$ndims-1 so the first dims
# go to positions @$dims. Undo the
# effects of _shuffle

sub _unshuffle($dims, $ndims){
    my %seen;
    my %unshuffle;
    $unshuffle{$dims->[$_]}=$_ for 0..@$dims-1;
    my $count=@$dims;
    (defined $unshuffle{$_}) || ($unshuffle{$_}=$count++) for 0..$ndims-1;
    return @unshuffle{0..$ndims-1};
}

# reorder 0..$ndims-1 so @$dims go last
sub _shuffle_end($dims, $ndims){
    my @shuffle=_shuffle($dims, $ndims);
    return @shuffle[@$dims..$ndims-1, 0..@$dims-1];
}

# reorder 0..$ndims-1 so the last dims
# go to positions @$dims. Undo the
# effects of _shuffle_end

sub _unshuffle_end($dims, $ndims){
    my $division=$ndims-@$dims;
    return map {($_+$division)%$ndims} _unshuffle($dims, $ndims);
}

1;

__END__

# ABSTRACT: Conjugate a function with a permutation of the dimensions of an ndarray
=head1 NAME

PDL::ApplyDim - shuffle before and after applying function

=head1 SYNOPSIS

    use PDL;
    use PDL::ApplyDim;
    my $nd=sequence(3,3);
    sub mult_columns($x, $dx, $m) { # multiply some columns of $x by $m
	$x->slice("0:-1:$dx")*=$m;
    }
    say $nd->apply_to(\&mult_columns, 1, 2, 3); #multiply even rows of $nd by 3
    say $nd->apply_not_to(\&mult_columns,0,2,3);# same

=head1 DESCRIPTION

Many operations in PDL act on the first dimension, so a very common
idiom is

    $pdl->mv($dim,0)->function($some, $extra, $args)->mv(0, $dim);

to move the dimension C<$dim> to the front, operate with the
function and the move the dimension back to its original place.
The idea is to hide the C<mv> operations and write this as

    $pdl->apply_to(\&function, $dim, $some, $extra, $args);

or

    apply_to($pdl, "function", $dim, $some, $extra, $args);

Similarly

    $pdl->apply_not_to(\&function, $dim, $some, $extra, $args);

moves the dimension to the back.

Besides a number, C<$dim> may also be an array reference, such as as
=C<[$d0, $d1...]>, to move the dimensions C<$d0, $d1...> to the
front or to the back instead of just a single dimension.

=head1 METHODS

=head2 apply_to($code, $dim, @extra_args)

Applies C<$code> to an ndarray after moving dimension C<$dim> to the
front, and then bringing the dimension back to its original position.
Code can be a string naming a PDL function or a reference to a subroutine that acts on an
ndarray. It may take extra arguments. If <$dim> is an array reference, moves
several dimensions.

=head2 apply_not_to($code, $dim, @extra_args)

Applies <$code> to an ndarray after moving dimension C<$dim> to the
end, and then bringing the dimension back to its original position.
Code can be a string naming a PDL function or a reference to a subroutine that acts on an
ndarray. It may take extra arguments. If <$dim> is an array reference, moves
several dimensions.

=head1 AUTHOR

W. Luis Mochan E<lt>mochan@fis.unam.mxE<gt>

=head1 COPYRIGHT

Copyright 2025- W. Luis Mochan

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# =head1 SEE ALSO

=cut
