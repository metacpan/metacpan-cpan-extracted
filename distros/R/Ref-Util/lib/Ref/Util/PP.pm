package Ref::Util::PP;
$Ref::Util::PP::VERSION = '0.204';
# ABSTRACT: pure-Perl version of Ref::Util

use strict;
use warnings;
use Carp         ();
use Scalar::Util ();
use Exporter 5.57 'import';

use constant _FORMAT_REFS_WORK => ("$]" >= 5.007);
use constant _RX_NEEDS_MAGIC   => (Scalar::Util::reftype(qr/^/) ne 'REGEXP');

our %EXPORT_TAGS = ( 'all' => [qw<
    is_ref
    is_scalarref
    is_arrayref
    is_hashref
    is_coderef
    is_regexpref
    is_globref
    is_formatref
    is_ioref
    is_refref

    is_plain_ref
    is_plain_scalarref
    is_plain_arrayref
    is_plain_hashref
    is_plain_coderef
    is_plain_globref
    is_plain_formatref
    is_plain_refref

    is_blessed_ref
    is_blessed_scalarref
    is_blessed_arrayref
    is_blessed_hashref
    is_blessed_coderef
    is_blessed_globref
    is_blessed_formatref
    is_blessed_refref
>] );
our @EXPORT      = ();
our @EXPORT_OK   = ( @{ $EXPORT_TAGS{'all'} } );

sub _using_custom_ops () { 0 }

if (_RX_NEEDS_MAGIC) {
    require B;
    *_is_regexp = sub {
        no warnings 'uninitialized';
        return 0 if ref($_[0]) eq '';
        my $o = B::svref_2object($_[0]) or return 0;
        return 0 if Scalar::Util::blessed($o) ne 'B::PVMG';

        my $m = $o->MAGIC;
        while ($m) {
            return 1 if $m->TYPE eq 'r';
            $m = $m->MOREMAGIC;
        }

        return 0;
    };
}

# ----
# -- is_*
# ----

sub is_ref($) { length ref $_[0] }

sub is_scalarref($) {
    no warnings 'uninitialized';
    Carp::croak("Too many arguments for is_scalarref") if @_ > 1;
    my $reftype = Scalar::Util::reftype( $_[0] );
    ( $reftype eq 'SCALAR' || $reftype eq 'VSTRING' )
        && (!_RX_NEEDS_MAGIC || !_is_regexp($_[0]));
}

sub is_arrayref($) {
    no warnings 'uninitialized';
    Carp::croak("Too many arguments for is_arrayref") if @_ > 1;
    Scalar::Util::reftype( $_[0] ) eq 'ARRAY';
}

sub is_hashref($) {
    no warnings 'uninitialized';
    Carp::croak("Too many arguments for is_hashref") if @_ > 1;
    Scalar::Util::reftype( $_[0] ) eq 'HASH';
}

sub is_coderef($) {
    no warnings 'uninitialized';
    Carp::croak("Too many arguments for is_coderef") if @_ > 1;
    Scalar::Util::reftype( $_[0] ) eq 'CODE';
}

sub is_regexpref($) {
    no warnings 'uninitialized';
    Carp::croak("Too many arguments for is_regexpref") if @_ > 1;
    _RX_NEEDS_MAGIC ? _is_regexp( $_[0] )
        : re::is_regexp( $_[0] );
}

sub is_globref($) {
    no warnings 'uninitialized';
    Carp::croak("Too many arguments for is_globref") if @_ > 1;
    Scalar::Util::reftype( $_[0] ) eq 'GLOB';
}

sub is_formatref($) {
    _FORMAT_REFS_WORK
        or
        Carp::croak("is_formatref() isn't available on Perl 5.6.x and under");

    no warnings 'uninitialized';
    Carp::croak("Too many arguments for is_formatref") if @_ > 1;
    Scalar::Util::reftype( $_[0] ) eq 'FORMAT';
}

sub is_ioref($) {
    no warnings 'uninitialized';
    Carp::croak("Too many arguments for is_ioref") if @_ > 1;
    Scalar::Util::reftype( $_[0] ) eq 'IO';
}

sub is_refref($) {
    no warnings 'uninitialized';
    Carp::croak("Too many arguments for is_refref") if @_ > 1;
    Scalar::Util::reftype( $_[0] ) eq 'REF';
}

# ----
# -- is_plain_*
# ----

sub is_plain_ref($) {
    Carp::croak("Too many arguments for is_plain_ref") if @_ > 1;
    ref $_[0] && !Scalar::Util::blessed( $_[0] );
}

sub is_plain_scalarref($) {
    Carp::croak("Too many arguments for is_plain_scalarref") if @_ > 1;
    !defined Scalar::Util::blessed( $_[0] )
        && ( ref( $_[0] ) eq 'SCALAR' || ref( $_[0] ) eq 'VSTRING' );
}

sub is_plain_arrayref($) {
    Carp::croak("Too many arguments for is_plain_arrayref") if @_ > 1;
    !defined Scalar::Util::blessed( $_[0] )
        && ref( $_[0] ) eq 'ARRAY';
}

sub is_plain_hashref($) {
    Carp::croak("Too many arguments for is_plain_hashref") if @_ > 1;
    !defined Scalar::Util::blessed( $_[0] )
        && ref( $_[0] ) eq 'HASH';
}

sub is_plain_coderef($) {
    Carp::croak("Too many arguments for is_plain_coderef") if @_ > 1;
    !defined Scalar::Util::blessed( $_[0] )
        && ref( $_[0] ) eq 'CODE';
}

sub is_plain_globref($) {
    Carp::croak("Too many arguments for is_plain_globref") if @_ > 1;
    !defined Scalar::Util::blessed( $_[0] )
        && ref( $_[0] ) eq 'GLOB';
}

sub is_plain_formatref($) {
    _FORMAT_REFS_WORK
        or
        Carp::croak("is_plain_formatref() isn't available on Perl 5.6.x and under");

    Carp::croak("Too many arguments for is_plain_formatref") if @_ > 1;
    !defined Scalar::Util::blessed( $_[0] )
        && ref( $_[0] ) eq 'FORMAT';
}

sub is_plain_refref($) {
    Carp::croak("Too many arguments for is_plain_refref") if @_ > 1;
    !defined Scalar::Util::blessed( $_[0] )
        && ref( $_[0] ) eq 'REF';
}

# ----
# -- is_blessed_*
# ----

sub is_blessed_ref($) {
    Carp::croak("Too many arguments for is_blessed_ref") if @_ > 1;
    defined Scalar::Util::blessed( $_[0] );
}

sub is_blessed_scalarref($) {
    Carp::croak("Too many arguments for is_blessed_scalarref") if @_ > 1;
    my $reftype = Scalar::Util::reftype( $_[0] );
    defined Scalar::Util::blessed( $_[0] )
        && ($reftype eq 'SCALAR' || $reftype eq 'VSTRING')
        && (!_RX_NEEDS_MAGIC || !_is_regexp( $_[0] ));
}

sub is_blessed_arrayref($) {
    Carp::croak("Too many arguments for is_blessed_arrayref") if @_ > 1;
    defined Scalar::Util::blessed( $_[0] )
        && Scalar::Util::reftype( $_[0] ) eq 'ARRAY';
}

sub is_blessed_hashref($) {
    Carp::croak("Too many arguments for is_blessed_hashref") if @_ > 1;
    defined Scalar::Util::blessed( $_[0] )
        && Scalar::Util::reftype( $_[0] ) eq 'HASH';
}

sub is_blessed_coderef($) {
    Carp::croak("Too many arguments for is_blessed_coderef") if @_ > 1;
    defined Scalar::Util::blessed( $_[0] )
        && Scalar::Util::reftype( $_[0] ) eq 'CODE';
}

sub is_blessed_globref($) {
    Carp::croak("Too many arguments for is_blessed_globref") if @_ > 1;
    defined Scalar::Util::blessed( $_[0] )
        && Scalar::Util::reftype( $_[0] ) eq 'GLOB';
}

sub is_blessed_formatref($) {
    _FORMAT_REFS_WORK
        or
        Carp::croak("is_blessed_formatref() isn't available on Perl 5.6.x and under");

    Carp::croak("Too many arguments for is_blessed_formatref") if @_ > 1;
    defined Scalar::Util::blessed( $_[0] )
        && Scalar::Util::reftype( $_[0] ) eq 'FORMAT';
}

sub is_blessed_refref($) {
    Carp::croak("Too many arguments for is_blessed_refref") if @_ > 1;
    defined Scalar::Util::blessed( $_[0] )
        && Scalar::Util::reftype( $_[0] ) eq 'REF';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Ref::Util::PP - pure-Perl version of Ref::Util

=head1 VERSION

version 0.204

=head1 SYNOPSIS

    use Ref::Util;

=head1 DESCRIPTION

This module provides a pure-Perl implementation of the functions in
L<Ref::Util>.

Ref::Util:PP will be used automatically if Ref::Util is installed on a
system with no C compiler, but you can force its usage by setting either
C<$Ref::Util::IMPLEMENTATION> or the C<PERL_REF_UTIL_IMPLEMENTATION>
environment variable to C<PP>.

=head1 AUTHORS

=over 4

=item *

Sawyer X <xsawyerx@cpan.org>

=item *

Aaron Crane <arc@cpan.org>

=item *

Vikenty Fesunov <vyf@cpan.org>

=item *

Gonzalo Diethelm <gonzus@cpan.org>

=item *

Karen Etheridge <ether@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Sawyer X.

This is free software, licensed under:

  The MIT (X11) License

=cut
