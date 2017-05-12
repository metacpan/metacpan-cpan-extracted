package Return::MultiLevel;

use warnings;
use strict;

our $VERSION = '0.04';

use Carp qw(confess);
use Data::Munge qw(eval_string);
use parent 'Exporter';

our @EXPORT_OK = qw(with_return);

our $_backend;

if (!$ENV{RETURN_MULTILEVEL_PP} && eval { require Scope::Upper }) {
    eval_string <<'EOT';
sub with_return (&) {
    my ($f) = @_;
    my $ctx = Scope::Upper::HERE();
    my @canary =
        !$ENV{RETURN_MULTILEVEL_DEBUG}
            ? '-'
            : Carp::longmess "Original call to with_return"
    ;
    local $canary[0];
    $f->(sub {
        $canary[0]
            and confess
                $canary[0] eq '-'
                    ? ""
                    : "Captured stack:\n$canary[0]\n",
                "Attempt to re-enter dead call frame"
        ;
        Scope::Upper::unwind(@_, $ctx);
    })
}
EOT

    $_backend = 'XS';

} else {

    eval_string <<'EOT';
{
    my $_label_prefix = '_' . __PACKAGE__ . '_';
    $_label_prefix =~ tr/A-Za-z0-9_/_/cs;

    sub _label_at { $_label_prefix . $_[0] }
}

our @_trampoline_cache;

sub _get_trampoline {
    my ($i) = @_;
    my $label = _label_at $i;
    (
        $label,
        $_trampoline_cache[$i] ||= eval_string qq{
            sub {
                my \$rr = shift;
                my \$fn = shift;
                return &\$fn;
                $label: splice \@\$rr
            }
        },
    )
}

our $_depth = 0;

sub with_return (&) {
    my ($f) = @_;
    my ($label, $trampoline) = _get_trampoline $_depth;
    local $_depth = $_depth + 1;
    my @canary =
        !$ENV{RETURN_MULTILEVEL_DEBUG}
            ? '-'
            : Carp::longmess "Original call to with_return"
    ;
    local $canary[0];
    my @ret;
    $trampoline->(
        \@ret,
        $f,
        sub {
            $canary[0]
                and confess
                    $canary[0] eq '-'
                        ? ""
                        : "Captured stack:\n$canary[0]\n",
                    "Attempt to re-enter dead call frame"
            ;
            @ret = @_;
            goto $label;
        },
    )
}
EOT

    $_backend = 'PP';
}

'ok'

__END__

=head1 NAME

Return::MultiLevel - return across multiple call levels

=head1 SYNOPSIS

  use Return::MultiLevel qw(with_return);

  sub inner {
    my ($f) = @_;
    $f->(42);  # implicitly return from 'with_return' below
    print "You don't see this\n";
  }

  sub outer {
    my ($f) = @_;
    inner($f);
    print "You don't see this either\n";
  }

  my $result = with_return {
    my ($return) = @_;
    outer($return);
    die "Not reached";
  };
  print $result, "\n";  # 42

=head1 DESCRIPTION

This module provides a way to return immediately from a deeply nested call
stack. This is similar to exceptions, but exceptions don't stop automatically
at a target frame (and they can be caught by intermediate stack frames using
L<C<eval>|perlfunc/eval-EXPR>). In other words, this is more like
L<setjmp(3)>/L<longjmp(3)> than L<C<die>|perlfunc/die-LIST>.

Another way to think about it is that the "multi-level return" coderef
represents a single-use/upward-only continuation.

=head2 Functions

The following functions are available (and can be imported on demand).

=over

=item with_return BLOCK

Executes I<BLOCK>, passing it a code reference (called C<$return> in this
description) as a single argument. Returns whatever I<BLOCK> returns.

If C<$return> is called, it causes an immediate return from C<with_return>. Any
arguments passed to C<$return> become C<with_return>'s return value (if
C<with_return> is in scalar context, it will return the last argument passed to
C<$return>).

It is an error to invoke C<$return> after its surrounding I<BLOCK> has finished
executing. In particular, it is an error to call C<$return> twice.

=back

=head1 DEBUGGING

This module uses L<C<unwind>|Scope::Upper/unwind> from
L<C<Scope::Upper>|Scope::Upper> to do its work. If
L<C<Scope::Upper>|Scope::Upper> is not available, it substitutes its own pure
Perl implementation. You can force the pure Perl version to be used regardless
by setting the environment variable C<RETURN_MULTILEVEL_PP> to 1.

If you get the error message C<Attempt to re-enter dead call frame>, that means
something has called a C<$return> from outside of its C<with_return { ... }>
block. You can get a stack trace of where that C<with_return> was by setting
the environment variable C<RETURN_MULTILEVEL_DEBUG> to 1.

=head1 BUGS AND LIMITATIONS

You can't use this module to return across implicit function calls, such as
signal handlers (like C<$SIG{ALRM}>) or destructors (C<sub DESTROY { ... }>).
These are invoked automatically by perl and not part of the normal call chain.

=head1 AUTHOR

Lukas Mai, C<< <l.mai at web.de> >>

=head1 COPYRIGHT & LICENSE

Copyright 2013-2014 Lukas Mai.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
