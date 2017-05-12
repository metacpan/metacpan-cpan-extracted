package Net::Riak::Role::Hosts;
{
  $Net::Riak::Role::Hosts::VERSION = '0.1702';
}

use Moose::Role;
use Net::Riak::Types qw(RiakHost);

has host => (
    is      => 'rw',
    isa     => RiakHost,
    coerce  => 1,
    default => 'http://127.0.0.1:8098',
);

sub get_host {
    my $self = shift;

    my $choice;
    my $rand = rand;

    for (@{$self->host}) {
        $choice = $_->{node};
        ($rand -= $_->{weight}) <= 0 and last;
    }
    $choice;
}

1;

__END__

=pod

=head1 NAME

Net::Riak::Role::Hosts

=head1 VERSION

version 0.1702

=head1 AUTHOR

franck cuny <franck@lumberjaph.net>, robin edwards <robin.ge@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
