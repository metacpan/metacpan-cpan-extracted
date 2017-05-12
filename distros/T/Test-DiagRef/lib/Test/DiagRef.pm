use strict;
use warnings;
package Test::DiagRef;
{
  $Test::DiagRef::VERSION = '1.132080';
}
# ABSTRACT: detailed diagnostics for your reference tracking tests

use Exporter 5.57 'import';
our @EXPORT = 'diag_ref';

use Test::More ();

BEGIN {
    *diag = \&Test::More::diag;
}

sub diag_ref ($)
{
    my $ref = shift;

    return unless defined $ref;

    unless (ref $ref) {
	diag 'value is a scalar';
	return
    }

    if (eval { require Devel::FindRef }) {
	diag Devel::FindRef::track($ref)
    } else {
	diag '(Install Devel::FindRef for a detailed report)'
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Test::DiagRef - Detailed diagnostics for your reference tracking tests

=head1 VERSION

version 1.132080

=head1 SYNOPSIS

    use Test::More tests => 1;
    use Test::DiagRef;
    use Scalar::Util 'weaken';

    my $obj = MyClass->new();

    weaken(my $ref = $obj);

    # Delete $obj
    undef $obj; # Uncomment this line to show a leak

    is($ref, undef, 'no leak') or diag_ref $ref;

=head1 DESCRIPTION

L<Test::DiagRef> is an utility module for writing tests for memory
leaks. It will not check for memory leaks himself (that's your job as a test
author), but at least provide an advanced report if your test found one.

The only sub exported is C<diag_ref($ref)>. It is expected to be used where
L<Test::More>'s C<diag> is used: to provide advanced diagnostics when a test
failed. The given C<$ref> will be explored.

L<Devel::FindRef> is the module that provides the detailed report. But it is
loaded on demand, only if C<$ref> is defined. This saves ressources if your
test did not detect a leak.

The runtime dependency on C<Devel::FindRef> is optional. If it is not
installed when the test found a leak, C<diag_ref> will just report a message
suggesting to install it. This ensures that using C<Test::DiagRef> has low
dependancy impact on your own CPAN (or DarkPAN) distribution. You can safely
use C<Test::DiagRef> for development, and still keep it in the test suite of
the distribution.

=head1 SEE ALSO

=over 4

=item *

L<Devel::FindRef>

=item *

The C<diag> sub in L<Test::More>.

=back

=head1 AUTHOR

Olivier Mengué, L<mailto:dolmen@cpan.org>

=head1 COPYRIGHT & LICENCE

Copyright E<copy> 2013 Olivier MenguE<eacute>.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl 5 itself.

=cut

# vim: set et sw=4 sts=4 :
