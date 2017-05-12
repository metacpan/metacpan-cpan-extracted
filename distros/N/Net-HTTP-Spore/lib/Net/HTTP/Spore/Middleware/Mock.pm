package Net::HTTP::Spore::Middleware::Mock;
{
  $Net::HTTP::Spore::Middleware::Mock::VERSION = '0.06';
}

# ABSTRACT: Simple Mocker for Spore middlewares

use Moose;
extends 'Net::HTTP::Spore::Middleware';

has tests => ( isa => 'HashRef', is => 'ro', required => 1 );

sub call {
    my ( $self, $req ) = @_;

    my $finalized_request = $req->finalize;
    foreach my $r ( keys %{ $self->tests } ) {
        next unless $r eq $finalized_request->uri->path;
        my $res = $self->tests->{$r}->($req);
        return $res if defined $res;
    }
}

1;

__END__

=pod

=head1 NAME

Net::HTTP::Spore::Middleware::Mock - Simple Mocker for Spore middlewares

=head1 VERSION

version 0.06

=head1 SYNOPSIS

    my $mock_server = {
        '/path/i/want/to/match' => sub {
            my $req = shift;
            ...
            $req->new_response(200, ['Content-Type' => 'text/plain'], 'ok');
        }
    };

    my $client = Net::HTTP::Spore->new_from_spec('spec.json');
    $client->enable('Mock', tests => $mock_server);
    my $res = $client->my_rest_method();
    is $res->status, 200;
    is $res->body, 'ok';

=head1 DESCRIPTION

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
