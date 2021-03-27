package Sub::Meta::Library;
use 5.010;
use strict;
use warnings;

our $VERSION = "0.09";

use Scalar::Util ();
use Sub::Meta;
use Sub::Identify;

my %INFO;
my %INDEX;

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
    my ($stash, $subname) = Sub::Identify::get_code_info($sub);
    $INDEX{$stash}{$subname} = $id;
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

sub get_by_stash_subname {
    my $class = shift;
    my ($stash, $subname) = @_;

    my $id = $INDEX{$stash}{$subname};
    return $INFO{$id} if $id;
    return;
}

sub get_all_subnames_by_stash {
    my $class = shift;
    my ($stash) = @_;

    my $data = $INDEX{$stash};
    return [ sort keys %$data ] if $data;
    return [ ]
}

sub get_all_submeta_by_stash {
    my $class = shift;
    my ($stash) = @_;

    my $data = $INDEX{$stash};
    return [ map { $INFO{$data->{$_}} } sort keys %$data ] if $data;
    return [ ]
}

sub remove {
    my $class = shift;
    my ($sub) = @_;

    unless (ref $sub && ref $sub eq 'CODE') {
        _croak "required coderef: $sub";
    }

    my $id = Scalar::Util::refaddr $sub;
    return delete $INFO{$id}
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

=head3 get_by_stash_subname($stash, $subname)

Get submeta by stash and subname. e.g. C<get_by_stash_subname('Foo::Bar', 'hello')>

=head3 get_all_subnames_by_stash($stash)

Get all subnames by stash. e.g. C<get_all_subnames_by_stash('Foo::Bar')>;

=head3 get_all_submeta_by_stash($stash)

Get all submeta by stash. e.g. C<get_all_submeta_by_stash('Foo::Bar')>

=head3 remove(\&sub)

Remove submeta of C<\&sub> from the library.

=head1 LICENSE

Copyright (C) kfly8.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

kfly8 E<lt>kfly@cpan.orgE<gt>

=cut
