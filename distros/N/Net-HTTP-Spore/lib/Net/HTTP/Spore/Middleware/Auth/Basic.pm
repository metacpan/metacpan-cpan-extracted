package Net::HTTP::Spore::Middleware::Auth::Basic;
{
  $Net::HTTP::Spore::Middleware::Auth::Basic::VERSION = '0.06';
}

# ABSTRACT: middleware for Basic authentication

use Moose;
extends 'Net::HTTP::Spore::Middleware::Auth';

use MIME::Base64;

has username => (isa => 'Str', is => 'rw', predicate => 'has_username');
has password => (isa => 'Str', is => 'rw', predicate => 'has_password');

sub call {
    my ( $self, $req ) = @_;

    return unless $self->should_authenticate($req);

    if ( $self->has_username && $self->has_password ) {
        $req->header(
            'Authorization' => 'Basic '
              . MIME::Base64::encode(
                $self->username . ':' . $self->password, ''
              )
        );
    }
}

1;

__END__

=pod

=head1 NAME

Net::HTTP::Spore::Middleware::Auth::Basic - middleware for Basic authentication

=head1 VERSION

version 0.06

=head1 SYNOPSIS

    my $client = Net::HTTP::Spore->new_from_spec('github.json');
    $client->enable('Auth::Basic', username => 'xxx', password => 'yyy');

=head1 DESCRIPTION

Net::HTTP::Spore::Middleware::Auth::Basic is a middleware to handle Basic authentication mechanism.

=head1 AUTHORS

=over 4

=item *

franck cuny <franck@lumberjaph.net>

=item *

Ash Berlin <ash@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
