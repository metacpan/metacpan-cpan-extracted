package Mojolicious::Plugin::DateTime;
use Mojo::Base 'Mojolicious::Plugin';
# ABSTRACT: Mojolicious plugin to DateTime module integration

our $VERSION = '0.02';

use DateTime;

sub register {
    my ( $self, $app ) = @_;

    # datetime method helper
    $app->helper(
        datetime => sub {
            my $self = shift;
            return DateTime->new(@_);
        }
    );

    # datetime short way
    $app->helper(
        dt => sub {
            return shift->datetime(@_);
        }
    );

    # datetime now method call
    $app->helper(
        now => sub {
            my $self = shift;
            return DateTime->now(@_);
        }
    )

}

1;

__END__
=encoding utf8

=head1 NAME

Mojolicious::Plugin::DateTime - Mojolicious DateTime module integration!

=head1 SYNOPSIS

    # mojolicious non-lite
    $self->plugin('datetime');

    # mojolicious lite
    pligin 'datetime'

=head1 DESCRIPTION

This mojolicious plugin create a simple way to get an integration with
L<DateTime> module.


=head1 METHODS

This plugin contains the following methods...

=head2 datetime

    # from controller
    my $dt = $c->datetime( year => 2014, month => 9, day => 28 );

    # from template
    %= datetime( year => 2014, month => 9, day => 28 ) 

Getting a new L<DateTime> object

=head2 dt

    # from controller
    my $dt = $c->dt( year => 2014, month => 9, day => 28 );

    # from template
    %= dt( year => 2014, month => 9, day => 28 ) 

Tiny way to call C<datetime> method

=head2 now

    # from controller
    my $dt = $c->now;
    my $dt = $c->now( time_zone => 'local' );

    # from template
    %= now
    %= now( time_zone => 'local' )

Shortcut to call C<<DateTime->now>> method

=head1 AUTHOR

Daniel Vinciguerra <daniel.vinciguerra@bivee.com.br>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mojolicious-plugin-datetime at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mojolicious-Plugin-DateTime>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 LICENSE AND COPYRIGHT

2014 (c) Daniel Vinciguerra.

This program is free software; you can redistribute it and/or modify it
under the same terms of Perl Programming Language itself.

=cut
