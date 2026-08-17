package Punk::Controller;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.14';

1;

__END__

=head1 NAME

Punk::Controller - base class for Punk controllers

=head1 SYNOPSIS

    package MyApp::Controller::Web::Book;
    use parent 'Punk::Controller';

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
