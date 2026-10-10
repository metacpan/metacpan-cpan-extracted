package Peta::NN::Optimizer;
# ABSTRACT: SGD with momentum, and Adam

# Turns a batch's gradients into parameter updates. It keeps the per-parameter
# state (momentum, or Adam's two moments) and leaves the arithmetic to the
# backend that owns the tensors.

use v5.36;

our $VERSION = '0.2610090';

my %DEFAULT = (
    sgd  => { lr => 0.1,   momentum => 0.9 },
    adam => { lr => 0.005, beta1 => 0.9, beta2 => 0.999, epsilon => 1e-8 },
    # both also take weight_decay => rate; default none
);

# params is a list of [holder, name]: the parameter tensor is $holder->{name}
# and its gradient, renewed by every backward pass, is $holder->{"g$name"}.
sub new ($class, %arg) {
    my $kind    = $arg{kind} // 'adam';
    my $default = $DEFAULT{$kind} or die "unknown optimizer '$kind'\n";
    my $self    = bless { %$default, %arg, kind => $kind, steps => 0 }, $class;
    my $backend = $self->{backend} // die "backend => is required\n";
    my @tensors = map { $_->[0]{ $_->[1] } } @{ $self->{params} };
    $self->{m} = [ map { $backend->zeros_like($_) } @tensors ];
    $self->{v} = [ map { $backend->zeros_like($_) } @tensors ] if $kind eq 'adam';
    return $self;
}

# One update. $scale multiplies every gradient: 1/batch-size turns a batch's
# summed gradient into its mean.
sub step ($self, $scale = 1) {
    my $backend = $self->{backend};
    my $t       = ++$self->{steps};
    my ($lr, $b1, $b2) = @$self{qw(lr beta1 beta2)};
    # Weight decay, decoupled from the gradient: every weight shrinks a little
    # at each step. Biases are left alone; shrinking them buys nothing.
    my $shrink = $self->{weight_decay} ? 1 - $lr * $self->{weight_decay} : undef;
    # Adam's bias correction for the zero-initialised moments, folded into the step size.
    my $rate = $self->{kind} eq 'adam' ? $lr * sqrt(1 - $b2**$t) / (1 - $b1**$t) : undef;

    for my $p (0 .. $#{ $self->{params} }) {
        my ($holder, $name) = @{ $self->{params}[$p] };
        my ($value,  $grad) = ($holder->{$name}, $holder->{"g$name"});
        $backend->decay($value, $shrink) if defined $shrink && $name ne 'b';
        if (defined $rate) {
            $backend->adam_update($value, $grad, $self->{m}[$p], $self->{v}[$p],
                                  $rate, $b1, $b2, $self->{epsilon}, $scale);
        }
        else {
            $backend->sgd_update($value, $grad, $self->{m}[$p], $lr, $self->{momentum}, $scale);
        }
    }
    return;
}

1;

__END__

=encoding utf-8

=head1 NAME

Peta::NN::Optimizer - SGD with momentum, and Adam

=head1 VERSION

version 0.2610090

=head1 SYNOPSIS

    my $opt = Peta::NN::Optimizer->new(kind => 'adam', lr => 0.005,
                                       backend => $backend, params => [ $net->params ]);
    $opt->step(1 / $batch_size);

=head1 METHODS

=head2 new

C<kind> is C<adam> (default) or C<sgd>; C<backend> and C<params>, a list of
C<[holder, name]>, are required. C<lr>, C<momentum>, C<beta1>, C<beta2>,
C<epsilon> and C<weight_decay> are optional.

=head2 step

C<step($scale)>: one update from the gradients the last backward pass left.
C<$scale> multiplies every gradient; 1/batch size turns a batch's summed
gradient into its mean.

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut
