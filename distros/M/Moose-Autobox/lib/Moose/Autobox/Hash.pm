package Moose::Autobox::Hash;
# ABSTRACT: the Hash role
use Moose::Role 'with';
use List::MoreUtils 0.07 ();
use namespace::autoclean;

our $VERSION = '0.16';

with 'Moose::Autobox::Ref',
     'Moose::Autobox::Indexed';

sub delete {
    my ($hash, $key) = @_;
    CORE::delete $hash->{$key};
}

sub merge {
    my ($left, $right) = @_;
    Carp::confess "You must pass a hashref as argument to merge"
        unless ref $right eq 'HASH';
    return { %$left, %$right };
}

sub hslice {
    my ($hash, $keys) = @_;
    return { map { $_ => $hash->{$_} } @$keys };
}

sub flatten {
    return %{$_[0]}
}

# ::Indexed implementation

sub at {
    my ($hash, $index) = @_;
    $hash->{$index};
}

sub put {
    my ($hash, $index, $value) = @_;
    $hash->{$index} = $value;
}

sub exists {
    my ($hash, $key) = @_;
    CORE::exists $hash->{$key};
}

sub keys {
    my ($hash) = @_;
    [ CORE::keys %$hash ];
}

sub values {
    my ($hash) = @_;
    [ CORE::values %$hash ];
}

sub kv {
    my ($hash) = @_;
    [ CORE::map { [ $_, $hash->{$_} ] } CORE::keys %$hash ];
}

sub slice {
    my ($hash, $keys) = @_;
    return [ @{$hash}{@$keys} ];
}

sub each {
    my ($hash, $sub) = @_;
    for my $key (CORE::keys %$hash) {
      $sub->($key, $hash->{$key});
    }
}

sub each_key {
    my ($hash, $sub) = @_;
    $sub->($_) for CORE::keys %$hash;
}

sub each_value {
    my ($hash, $sub) = @_;
    $sub->($_) for CORE::values %$hash;
}

sub each_n_values {
    my ($hash, $n, $sub) = @_;
    my @keys = CORE::keys %$hash;
    my $it = List::MoreUtils::natatime($n, @keys);

    while (my @vals = $it->()) {
        $sub->(@$hash{ @vals });
    }

    return;
}


# End Indexed

sub print   { CORE::print %{$_[0]} }
sub say     { CORE::print %{$_[0]}, "\n" }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Moose::Autobox::Hash - the Hash role

=head1 VERSION

version 0.16

=head1 SYNOPSIS

  use Moose::Autobox;

  print { one => 1, two => 2 }->keys->join(', '); # prints 'one, two'

=head1 DESCRIPTION

This is a role to describes a Hash value.

=head1 METHODS

=over 4

=item C<delete>

=item C<merge>

Takes a hashref and returns a new hashref with right precedence
shallow merging.

=item C<hslice>

Slices a hash but returns the keys and values as a new hashref.

=item C<flatten>

=back

=head2 Indexed implementation

=over 4

=item C<at>

=item C<put>

=item C<exists>

=item C<keys>

=item C<values>

=item C<kv>

=item C<slice>

=item C<each>

=item C<each_key>

=item C<each_value>

=item C<each_n_values>

=back

=over 4

=item C<meta>

=item C<print>

=item C<say>

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Moose-Autobox>
(or L<bug-Moose-Autobox@rt.cpan.org|mailto:bug-Moose-Autobox@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://lists.perl.org/list/moose.html>.

There is also an irc channel available for users of this distribution, at
L<C<#moose> on C<irc.perl.org>|irc://irc.perl.org/#moose>.

=head1 AUTHOR

Stevan Little <stevan.little@iinteractive.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
