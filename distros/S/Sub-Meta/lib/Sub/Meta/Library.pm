package Sub::Meta::Library;
use 5.010;
use strict;
use warnings;

our $VERSION = "0.07";

use Scalar::Util ();
use Sub::Meta;

my %INFO;

sub _croak { require Carp; goto &Carp::croak }

sub register {
    my $class = shift;
    my ($sub, $meta) = @_;
    unless ($sub && $meta) {
        _croak "arguments required coderef and submeta.";
    }

    unless (ref $sub && ref $sub eq 'CODE') {
        _croak "required coderef: $sub";
    }

    unless (Scalar::Util::blessed($meta) && $meta->isa('Sub::Meta')) {
        _croak "required an instance of Sub::Meta: $meta";
    }

    my $id = Scalar::Util::refaddr $sub;
    $INFO{$id} = $meta;
    return;
}

sub register_list {
    my $class = shift;
    my @args = @_ == 1 && ref $_[0] && ref $_[0] eq 'ARRAY' ? @{$_[0]} : @_;

    for (@args) {
        $class->register(@$_)
    }
    return;
}

sub get {
    my $class = shift;
    my ($sub) = @_;

    unless (ref $sub && ref $sub eq 'CODE') {
        _croak "required coderef: $sub";
    }

    my $id = Scalar::Util::refaddr $sub;
    return $INFO{$id}
}

1;
__END__

=encoding utf-8

=head1 NAME

Sub::Meta::Library - library of Sub::Meta

=head1 SYNOPSIS

    use Sub::Meta;
    use Sub::Meta::Library;

    sub hello { }

    my $meta = Sub::Meta->new(sub => \&hello);

    Sub::Meta::Library->register(\&hello, $meta);
    my $meta = Sub::Meta::Library->get(\&hello);

=head1 METHODS

=head2 register(\&sub, $meta)

Register submeta in refaddr of C<\&sub>.

=head2 register_list(ArrayRef[\&sub, $meta])

Register a list of coderef and submeta.

=head3 get(\&sub)

Get submeta of C<\&sub>.

=head1 LICENSE

Copyright (C) kfly8.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

kfly8 E<lt>kfly@cpan.orgE<gt>

=cut
