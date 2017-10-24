package Net::HTTP::Spore::Role::UserAgent;
$Net::HTTP::Spore::Role::UserAgent::VERSION = '0.07';
# ABSTRACT: create UserAgent

use Moose::Role;
use LWP::UserAgent;

has api_useragent => (
    is      => 'rw',
    isa     => 'LWP::UserAgent',
    lazy    => 1,
    handles => [qw/request/],
    default => sub {
        my $self = shift;
        my $ua = LWP::UserAgent->new();
        $ua->agent( "Net::HTTP::Spore v" . $Net::HTTP::Spore::VERSION . " (Perl)" );
        $ua->env_proxy;
        $ua->max_redirect(0);
        return $ua;
    }
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::HTTP::Spore::Role::UserAgent - create UserAgent

=head1 VERSION

version 0.07

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
