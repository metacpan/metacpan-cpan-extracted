package Template::Plugin::Time::Duration;
use strict;

our $VERSION = '0.02';

require Template::Plugin;
use base qw(Template::Plugin);

use Time::Duration qw();

sub ago { shift; return Time::Duration::ago(@_) };

sub ago_exact { shift; return Time::Duration::ago_exact(@_) };

sub concise { shift; return Time::Duration::concise(@_) };

sub duration { shift; return Time::Duration::duration(@_); }

sub duration_exact { shift; return Time::Duration::duration_exact(@_); }

sub from_now { shift; return Time::Duration::from_now(@_) };

sub from_now_exact { shift; return Time::Duration::from_now_exact(@_) };

sub later { shift; return Time::Duration::later(@_) };

sub later_exact { shift; return Time::Duration::later_exact(@_) };

sub earlier { shift; return Time::Duration::earlier(@_) };

sub earlier_exact { shift; return Time::Duration::earlier_exact(@_) };

1;

=head1 NAME

Template::Plugin::Time::Duration - Time::Duration functions for Template Toolkit

=head1 SYNOPSIS

    [% USE time_dir = Time.Duration %]

    This thing happened [% time_dir.ago(some_seconds) %].

=head1 DESCRIPTION

This plugin allows you to use functions from Time::Duration in your templates.
It is very simple and hopefully requires little explanation.

=head1 FUNCTIONS

=head2 ago

=head2 ago_exact

=head2 concise

=head2 duration

=head2 duration_exact

=head2 from_now

=head2 from_now_exact

=head2 later

=head2 later_exact

=head2 earlier

=head2 earlier_exact

=head1 SEE ALSO

L<Time::Duration>

=head1 AUTHOR

Cory G Watson, C<< <gphat at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2010 Cold Hard Code, LLC

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
