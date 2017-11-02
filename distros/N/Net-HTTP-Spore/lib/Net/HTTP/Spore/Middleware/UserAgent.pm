package Net::HTTP::Spore::Middleware::UserAgent;
$Net::HTTP::Spore::Middleware::UserAgent::VERSION = '0.09';
# ABSTRACT: middleware to change the user-agent value

use Moose;
extends qw/Net::HTTP::Spore::Middleware/;

has useragent => (is => 'ro', isa => 'Str', required => 1);

sub call {
    my ($self, $req) = @_;

    $req->header('User-Agent' => $self->useragent);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::HTTP::Spore::Middleware::UserAgent - middleware to change the user-agent value

=head1 VERSION

version 0.09

=head1 SYNOPSIS

    my $client = Net::HTTP::Spore->new_from_spec('twitter.json');
    $client->enable('UserAgent', useragent => 'Mozilla/5.0 (X11; Linux x86_64; rv:2.0b4) Gecko/20100818 Firefox/4.0b4');

=head1 DESCRIPTION

Net::HTTP::Spore::Middleware::UserAgent change the default value of the useragent.

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
