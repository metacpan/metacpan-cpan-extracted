#!/usr/bin/perl -w
use strict;

package App::Control::Apache;
use base qw(App::Control);

sub graceful {
    my $self = shift;
    die $self->status unless $self->running;
    if (kill ('USR1', $self->pid)) {
	return "$0: httpd gracefully restarted\n"
    }
    else {
	return "$0: httpd could not be restarted\n"
    }
}

sub configtest {
    my $self = shift;
    die $self->status unless $self->running;
    if (kill ('USR1', $self->pid)) {
	return "$0: httpd gracefully restarted\n"
    }
    else {
	return "$0: httpd could not be restarted\n"
    }
}

=head1 NAME

App::Control::Apache - App::Control subclass for apache

=head1 SYNOPSIS

 see App::Control

=head1 DESCRIPTION

The class implements additional methods for App::Control to emulate
apachectl.

=over

=item configtest

=item graceful

=back

=head1 SEE ALSO

L<App::Control>

=head1 AUTHORS

Chia-liang Kao <clkao@clkao.org>

=head1 COPYRIGHT

Copyright (C) 2002-5, Fotango Ltd.

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.

=cut

1;
