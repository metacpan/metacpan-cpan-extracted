package Plack::Session::Store::Echo;

use strict;
use warnings;

use parent 'Plack::Session::Store';


our $VERSION = '1.00';


sub new    { return bless({}, shift()); }

sub fetch  { return {}; }

sub store  { }

sub remove { }


1;


__END__

=head1 NAME

Plack::Session::Store::Echo - Echo store for Plack::Middleware::Session

=head1 SYNOPSIS

    use Plack::Builder;

    my $app = sub {
        return [200, ['Content-Type' => 'text/plain'], ['Hello!']];
    };

    builder {
        enable 'Session', state => 'Cookie', store => 'Echo';
        $app;
    };

=head1 DESCRIPTION

Sometimes you want only mark new client with cookie and don't want to store
something in your sessions, so you can use this one. For any session identifier
this store tells that the session exists.

This is a subclass of L<Plack::Session::Store> and implements its full
interface.

=head1 SEE ALSO

L<Plack::Middleware::Session>.

=head1 SUPPORT

=over 4

=item * Repository

L<http://github.com/dionys/plack-session-store-echo>

=item * Bug tracker

L<http://github.com/dionys/plack-session-store-echo/issues>

=back

=head1 AUTHOR

Denis Ibaev C<dionys@cpan.org>.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

See L<http://dev.perl.org/licenses/> for more information.

=cut
