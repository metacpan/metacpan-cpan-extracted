package Plack::Middleware::Scope::Session;
use strict;
use warnings;
use Scope::Session;
use parent qw( Plack::Middleware );

our $VERSION = '0.01';

sub call {
    my ( $self, $env ) = @_;
    my $res;

    Scope::Session::start{
        my $session = shift;
        $session->set_option( 'psgi.env' => $env );
        $res = $self->app->($env);
    };
    return $res;
}
1;
=head1 NAME

Plack::Middleware::Scope::Session - Global Cache and Option per Request.

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

Plack::Middleware::Scope::Session works like mod_perl's pnotes.

    builder {
        enable q|Plack::Middleware::Scope::Session|
    } 

if enable this, give your application a per-request cache 

    use Scope::Session;

    sub something_in_your_application{
        ...
        my $env = Scope::Session->get_option('psgi.env');
        Scope::Session->notes( 'SingletonPerRequest' , Plack::Request->new($env));

    }

=head1 METHODS

=head2 call

=head1 SEE ALSO

L<Scope::Session>,L<Plack::Middleware>

=head1 AUTHOR

Daichi Hiroki, C<< <hirokidaichi<AT>gmail.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2009 Daichi Hiroki.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

