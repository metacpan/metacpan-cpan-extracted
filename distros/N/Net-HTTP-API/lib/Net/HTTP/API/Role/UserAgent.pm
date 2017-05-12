package Net::HTTP::API::Role::UserAgent;
BEGIN {
  $Net::HTTP::API::Role::UserAgent::VERSION = '0.14';
}

# ABSTRACT: create UserAgent

use Moose::Role;
use LWP::UserAgent;

has api_useragent => (
    is      => 'rw',
    isa     => 'LWP::UserAgent',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $ua   = $self->meta->get_api_option('useragent');
        return $ua->() if $ua;
        $ua = LWP::UserAgent->new();
        $ua->agent(
            "Net::HTTP::API " . $Net::HTTP::API::VERSION . " (Perl)");
        $ua->env_proxy;
        return $ua;
    }
);

1;


__END__
=pod

=head1 NAME

Net::HTTP::API::Role::UserAgent - create UserAgent

=head1 VERSION

version 0.14

=head1 SYNOPSIS

=head1 DESCRIPTION

=head2 ATTRIBUTES

=over 4

=item B<api_useragent>

=back

=head1 AUTHOR

franck cuny <franck@lumberjaph.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

