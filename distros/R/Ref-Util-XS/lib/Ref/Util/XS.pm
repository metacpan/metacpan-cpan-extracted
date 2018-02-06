package Ref::Util::XS;
# ABSTRACT: XS implementation for Ref::Util
$Ref::Util::XS::VERSION = '0.117';
use strict;
use warnings;
use XSLoader;

use Exporter 5.57 'import';

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

our @EXPORT_OK   = ( @{ $EXPORT_TAGS{'all'} } );

XSLoader::load('Ref::Util::XS', $Ref::Util::XS::{VERSION} ? ${ $Ref::Util::XS::{VERSION} } : ());

if (_using_custom_ops()) {
  for my $op (@{$EXPORT_TAGS{all}}) {
    no strict 'refs';
    *{"B::Deparse::pp_$op"} = sub {
      my ($deparse, $bop, $cx) = @_;
      my @kids = $deparse->deparse($bop->first, 6);
      my $sib = $bop->first->sibling;
      if (ref $sib ne 'B::NULL') {
        push @kids, $deparse->deparse($sib, 6);
      }
      my $prefix
        = (
          exists &{"$deparse->{curstash}::$op"}
          && \&{"$deparse->{curstash}::$op"} == \&{__PACKAGE__.'::'.$op}
        )
        ? '' : (__PACKAGE__.'::');
      return "$prefix$op(" . join(", ", @kids) . ")";
    };
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Ref::Util::XS - XS implementation for Ref::Util

=head1 VERSION

version 0.117

=head1 SYNOPSIS

    use Ref::Util;
    # Don't use Ref::Util::XS directly!

    if (is_arrayref($something) {
        print for @$something;
    }
    elsif (is_hashref($something)) {
        print for sort values %$something;
    }

=head1 DESCRIPTION

Ref::Util::XS is the XS implementation of Ref::Util, which provides several
functions to help identify references in a more convenient way than the
usual approach of examining the return value of C<ref>.

You should use L<Ref::Util::XS> by installing L<Ref::Util> itself: if the system
you install it on has a C compiler available, C<Ref::Util::XS> will be
installed and used automatically, providing a significant speed boost to
everything that uses C<Ref::Util>.

See L<Ref::Util> for full documentation of the available functions.

=head1 THANKS

The following people have been invaluable in their feedback and support.

=over 4

=item * Yves Orton

=item * Steffen Müller

=item * Jarkko Hietaniemi

=item * Mattia Barbon

=item * Zefram

=item * Tony Cook

=item * Sergey Aleynikov

=back

=head1 AUTHORS AND MAINTAINERS

=over 4

=item * Aaron Crane

=item * Vikentiy Fesunov

=item * Sawyer X

=item * Gonzalo Diethelm

=item * Karen Etheridge

=item * Graham Knop

=item * p5pclub

=back

=head1 LICENSE

This software is made available under the MIT Licence as stated in the
accompanying LICENSE file.

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

=item *

Graham Knop <haarg@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Sawyer X.

This is free software, licensed under:

  The MIT (X11) License

=cut
