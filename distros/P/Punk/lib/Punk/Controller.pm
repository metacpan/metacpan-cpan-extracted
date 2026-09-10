package Punk::Controller;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.48';

# `use Punk::Controller;` is the one-line preamble: it makes the caller a
# controller and turns on strict and warnings, which is what `use Punk::Model`
# does for a model and what every controller was writing by hand. The older
# `use parent 'Punk::Controller'` still works and is untouched - it just does
# not carry the pragmas, exactly as before.
sub import {
    my ($class) = @_;
    my $caller  = caller;
    # The pragmas are unconditional: they are the reason to write the one-line
    # form, and a caller that already inherits (through `use parent`, or a
    # second `use`) still wants them. Only the @ISA push is guarded, so it
    # cannot be applied twice or to main.
    if ( $caller ne 'main' && !$caller->isa($class) ) {
        no strict 'refs';
        push @{"${caller}::ISA"}, $class;
    }
    # Ordinary method calls, so the hint bits land in the scope being compiled
    # - the caller's file - rather than in this one.
    strict->import;
    warnings->import;
    return;
}

1;

__END__

=head1 NAME

Punk::Controller - base class for Punk controllers

=head1 SYNOPSIS

    package MyApp::Controller::Web::Book;
    use Punk::Controller;

    sub list {
        my ($c) = @_;
        my $page = $c->model('Book')->search({}, { limit => 20 });
        return $c->render('book/list', { books => $page->{rows} });
    }

    1;

=head1 DESCRIPTION

Controller methods are plain subs receiving the L<Punk::Context> - no
instance, no dispatch overhead; the coderef is resolved once at
C<to_app> and called directly per request. The base class marks the
package as a controller and is the natural home for shared helper subs
an app wants every controller to inherit.

C<use Punk::Controller> makes the caller a controller and turns on C<strict>
and C<warnings>, the way C<use Punk::Model> does for a model. The older form
still works and is unchanged:

    use parent 'Punk::Controller';   # same base class, no pragmas

so existing controllers need no edit; the one-line form is simply what the
scaffolder writes now.

Route targets name controllers relative to the application's
C<Controller::> namespace: C<'Web::Book#list'> in C<MyApp> resolves to
C<MyApp::Controller::Web::Book::list>. A fully qualified name (one
that already starts with the namespace) passes through unchanged.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
