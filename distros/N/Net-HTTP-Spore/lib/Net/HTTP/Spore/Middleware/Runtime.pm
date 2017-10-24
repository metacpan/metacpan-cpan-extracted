package Net::HTTP::Spore::Middleware::Runtime;
$Net::HTTP::Spore::Middleware::Runtime::VERSION = '0.07';
# ABSTRACT: add a new header with runtime

use Moose;
extends 'Net::HTTP::Spore::Middleware';
use Time::HiRes;

sub call {
    my ( $self, $req) = @_;

    my $start_time = [Time::HiRes::gettimeofday];

    $self->response_cb(
        sub {
            my $res = shift;
            my $req_time = sprintf '%.6f',
              Time::HiRes::tv_interval($start_time);
            $res->header('X-Spore-Runtime' => $req_time);
        }
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::HTTP::Spore::Middleware::Runtime - add a new header with runtime

=head1 VERSION

version 0.07

=head1 SYNOPSIS

    my $client = Net::HTTP::Spore->new_from_spec('twitter.json');
    $client->enable('Runtime');

    my $result = $client->public_timeline;
    say "request executed in ".$result->header('X-Spore-Runtime');

=head1 DESCRIPTION

Net::HTTP::Spore::Middleware::Runtime is a middleware that add a new header to the response's headers: X-Spore-Runtime. The value of the header is the time the request took to be executed.

=head1 AUTHORS

=over 4

=item *

Franck Cuny <franck.cuny@gmail.com>

=item *

Ash Berlin <ash@cpan.org>

=item *

Ahmad Fatoum <athreef@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
