package Scope::OnExit::Wrap;

use warnings;
use strict;

use base 'Exporter';

our $VERSION = '0.02';

our @EXPORT = qw(on_scope_exit);

our $_backend;

if (!$ENV{SCOPE_ONEXIT_WRAP_PP} && eval { require Scope::OnExit }) {
    Scope::OnExit->import;
    $_backend = 'XS';
} else {
    eval <<'EOT';
sub on_scope_exit (&) {
    my ($code) = @_;
    bless \$code, __PACKAGE__
}

sub DESTROY {
    my $self = shift;
    $$self->();
}

EOT
    die $@ if $@;
    $_backend = 'PP';
}

'ok'

__END__

=head1 NAME

Scope::OnExit::Wrap - run code on scope exit (with pure Perl fallback)

=head1 SYNOPSIS

  {
    my $var = foo();
    my $guard = on_scope_exit {
      do_something($var);
    };
    something_else();
  }  # scope exit: do_something($var) is run now

=head1 DESCRIPTION

This module is a thin wrapper around L<C<Scope::OnExit>|Scope::OnExit>, which
is written in C. If L<C<Scope::OnExit>|Scope::OnExit> is not available, it
provides its own pure Perl implementation equivalent to L<C<End>|End> (which
adds a tiny bit of overhead: an object is constructed and its destructor
invoked).

=head2 Functions

=over

=item on_scope_exit BLOCK

(This function is exported by default.)

Arranges for I<BLOCK> to be executed when the surrounding scope is exited
(whether it reaches the end normally, by L<C<last>|perlfunc/last>, by
L<C<return>|perlfunc/return>, or by L<throwing an exception|perlfunc/die>).

For compatibility with the XS and pure Perl implementations, you must save the
return value of C<on_scope_exit> in a lexical (L<C<my>|perlfunc/my>) variable,
which you then ignore (i.e. don't do anything with the variable afterwards).

(The XS code in L<C<Scope::OnExit>|Scope::OnExit> will register the block
directly and not return anything useful, but the pure Perl substitute will
return an object here whose destructor invokes the block.)

=back

=head1 SEE ALSO

L<Scope::OnExit>, L<End>

=head1 AUTHOR

Lukas Mai, C<< <l.mai at web.de> >>

=head1 COPYRIGHT & LICENSE

Copyright 2013 Lukas Mai.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
