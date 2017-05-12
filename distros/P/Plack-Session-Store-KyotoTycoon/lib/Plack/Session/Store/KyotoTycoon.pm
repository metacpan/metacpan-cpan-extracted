package Plack::Session::Store::KyotoTycoon;

use 5.010;
use Cache::KyotoTycoon;
use Try::Tiny;
use Storable qw/nfreeze thaw/;
use MIME::Base64 qw(encode_base64 decode_base64);

# ABSTRACT: Plack::Session storage for Kyoto Tycoon

our $VERSION = '0.1'; # VERSION

use parent 'Plack::Session::Store';


sub new {
    my ($class, %params) = @_;

    $params{tycoon} = _verify_tycoon_connection;

    return bless {%params} => $class;
}


sub fetch {
    my ($self, $key) = @_;

    my @data;
    try {
        @data = $self->{tycoon}->get($key);
    }
    catch {
        $self->_verify_tycoon_connection;
        @data = $self->{tycoon}->get($key);
    };

    if (defined($data[0])) {
        my $sess = thaw(decode_base64($data[0]));
        $sess->{__expire} = $data[1];
        return $sess;
    }
    return;
}


sub store {
    my ($self, $key, $data, $expire) = @_;

    $data = encode_base64(nfreeze($data));
    $expire = 3600 unless $expire;
    my $replace;
    try {
        $replace = $self->{tycoon}->replace($key, $data, $expire);
    }
    catch {
        $self->_verify_tycoon_connection;
        $replace = $self->{tycoon}->replace($key, $data, $expire);
    };

    return $self->{tycoon}->set($key, $data, $expire)
        unless $replace;
    return;
}


sub remove {
    my ($self, $key) = @_;

    try { return $self->{tycoon}->remove($key); }
    catch {
        $self->_verify_tycoon_connection;
        return $self->{tycoon}->remove($key);
    }
    return;
}

sub _verify_tycoon_connection {
    my ($self) = @_;

    try { $self->{tycoon}->echo({ test => 1 }); }
    catch {
        $self->{tycoon} = Cache::KyotoTycoon->new(
            timeout => 2,
            exists $self->{tycoon_server}
            ? (host => $self->{tycoon_server})
            : (),
            exists $self->{tycoon_port} ? (port => $self->{tycoon_port}) : (),
        );
    };
    return;
}


1;    # End of Plack::Session::Store::KyotoTycoon

__END__

=pod

=head1 NAME

Plack::Session::Store::KyotoTycoon - Plack::Session storage for Kyoto Tycoon

=head1 VERSION

version 0.1

=head1 SYNOPSIS

See the docs for B<Plack::Session::Store::*> for details on how to use
this.

=head1 SUBROUTINES/METHODS

=head2 B<new ( %params )>

Parameters are tycoon_server and tycoon_port. See the B<Cache::KyotoTycoon> and
Kyoto Tycoon docs for details.

=head2 B<fetch ( $session_id )>

=head2 B<store ( $session_id, $session )>

=head2 B<remove ( $session_id )>

=head1 BUGS

Please report any bugs or feature requests on GitHub's issue tracker L<https://github.com/<github_user>/Plack::Session::Store::KyotoTycoon/issues>.
Pull requests welcome.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Plack::Session::Store::KyotoTycoon

You can also look for information at:

=over 4

=item * GitHub repository

L<https://github.com/<github_user>/Plack::Session::Store::KyotoTycoon>

=item * MetaCPAN

L<https://metacpan.org/module/Plack::Session::Store::KyotoTycoon>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Plack::Session::Store::KyotoTycoon>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Plack::Session::Store::KyotoTycoon>

=back

=head1 ACKNOWLEDGEMENTS

=over 4

=item * Lenz Gschwendtner (@norbu09), for being an awesome mentor and friend.

=back

=head1 AUTHOR

Lenz Gschwendtner <lenz@springtimesoft.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by springtimesoft LTD.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
