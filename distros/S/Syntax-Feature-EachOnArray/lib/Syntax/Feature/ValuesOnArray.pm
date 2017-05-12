package Syntax::Feature::ValuesOnArray; # so as not to confuse dzil?
our $VERSION = '0.04'; # VERSION
use strict;
use warnings;
use Syntax::Feature::EachOnArray ();
use Carp;
use Scalar::Util qw(reftype);

package Tie::ArrayAsHash;

sub avalues (\[@%]) {
    my $thing = shift;
    return values %$thing
        if reftype $thing eq 'HASH';
    confess "should be passed a HASH or ARRAY"
        unless reftype $thing eq 'ARRAY';

    my $thing_h = $Tie::ArrayAsHash::cache{$thing} ||= do {
        tie my %h, __PACKAGE__, $thing;
        \%h
    };

    values %$thing_h;
}

package Syntax::Feature::ValuesOnArray;

sub install {
    my $class = shift;
    my %args = @_;

    return unless $^V lt 5.12.0;
    no strict 'refs';
    *{"$args{into}::values"} = \&Tie::ArrayAsHash::avalues;
}

# XXX on uninstall, delete symbol

1;
# ABSTRACT: Emulate values(@array) on Perl < 5.12


__END__
=pod

=head1 NAME

Syntax::Feature::ValuesOnArray - Emulate values(@array) on Perl < 5.12

=head1 VERSION

version 0.04

=head1 SYNOPSIS

 # This can run on Perls older than 5.12 and have no effect on 5.12+
 use syntax 'values_on_array';

 my @a = (qw/a b c/);
 my @values = values @a;

=head1 DESCRIPTION

Beginning with 5.12, Perl supports values() on array. This syntax extension
emulates the support on older Perls.

=for Pod::Coverage ^(install)$

=head1 CAVEATS

No uninstall() yet.

=head1 SEE ALSO

L<syntax>

L<Syntax::Feature::EachOnArray>

L<Syntax::Feature::KeysOnArray>

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

