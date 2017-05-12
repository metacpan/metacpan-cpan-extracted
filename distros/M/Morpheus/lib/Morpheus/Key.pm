package Morpheus::Key;
{
  $Morpheus::Key::VERSION = '0.46';
}
use strict;

# ABSTRACT: class representing config key


use overload
    'eq' => sub { @_ = upgrade(@_); ${$_[0]} eq ${$_[1]} },
    'lt' => \&less,
    'le' => sub { @_ = upgrade(@_); $_[0] lt $_[1] or $_[0] eq $_[1] },
    'gt' => sub { @_ = upgrade(@_); $_[1] lt $_[0] },
    'ge' => sub { @_ = upgrade(@_); $_[1] lt $_[0] or $_[0] eq $_[1] }, #ATTN 'not $x < $y' does not mean '$x >= $y'

    '""' => sub { ${$_[0]} },
    '@{}' => \&parts;

use base qw(Exporter);
our @EXPORT_OK = qw(key);

sub new {
    my $class = shift;
    my $key = shift;
    
    $key =~ s{/+}{/}g;
    $key =~ s{^/*}{/}; #TODO: support relative keys?
    $key =~ s{/+$}{};

    bless \$key => $class;
}

sub upgrade {
    map { ref $_ ? $_ : __PACKAGE__->new($_) } @_;
}

sub less ($$) {
    @_ = upgrade(@_);
    my ($key1, $key2) = @_;
    $key1 = "$key1";
    $key2 = "$key2";
    return length $key1 < length $key2 && substr($key2, 0, 1 + length $key1) eq "$key1/";
}

sub parts ($) {
    my ($key) = @_;
    $key = "$key";
    $key =~ s{^/}{};
    return [split qr{/}, $key];
}

sub key {
    __PACKAGE__->new($_[0]);
}

1;

__END__
=pod

=head1 NAME

Morpheus::Key - class representing config key

=head1 VERSION

version 0.46

=head1 SYNOPSIS

    use Morpheus::Key qw(key);

    $key = Morpheus::Key->new("/foo/bar/x");
    $key = key("/foo/bar/y");

    say "key: $key";
    say "parts: ", join '/', @{ $key->parts };

    key("/foo/bar") ge key("/foo"); # true

    key("/foo") gt key("/bar"); # false
    key("/bar") gt key("/foo"); # also false

=head1 DESCRIPTION

Morpheus configuration tree looks very much like a file system with directory structure and files. The names of these "directories" and "files" are called I<configuration keys>. They are either represented by a string of the form C</namespace/subnamespace/...> (like a file path) or by the C<Morpheus::Key> object. In fact Morpheus always casts the string key representation into an object to simplify its further usage.

Morpheus::Key class provides the following features:

=head2 Normalization

The string representation of a key has a disadvantage that unequal strings may refer to the same namespace. Morpheus::Key class does a normalization of the key string so that equal namespaces were represented by equal strings. That normalization includes:

=over

=item *

Removal of a trailing slash if present ("/a/b/c/" -> "/a/b/c").

=item *

Removal of repeated slashes ("/a//b///c" -> "/a/b/c").

=item *

Appending of a leading "/" if it is missing ("a/b" -> "/a/b"). We plan to remove this normalization step in the future as soon as we introduce a notion of "relative" keys.

=back

We also consider the idea of making configuration keys case insensitive, but at the moment the key case is completely preserved.

=head2 Comparison operators

It is often required to check if two namespaces are equal or one namespace is a part of another one. Morpheus::Key class overloads the following operators to help do so: eq, ne, lt, le, gt, ge. Note that the set of configuration keys is only partially ordered, that is both $key1 ge $key2 and $key1 le $key2 may be false. Consider $key1 = "/a/b" and $key2 = "/a/c" for instance.

=head2 Transparent access to string key representation

Morpheus::Key objects return their string representation when stringified.

=head2 Splitting into namespace parts

C<< $key->parts >> return an arrayref of key parts.

=head1 AUTHOR

Andrei Mishchenko <druxa@yandex-team.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

