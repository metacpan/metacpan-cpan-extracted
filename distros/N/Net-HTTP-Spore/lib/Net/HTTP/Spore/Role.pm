package Net::HTTP::Spore::Role;
$Net::HTTP::Spore::Role::VERSION = '0.07';
# ABSTRACT: Role to easily add multiples Spore clients to your class

use MooseX::Role::Parameterized;
use Net::HTTP::Spore;

parameter spore_clients => (isa => 'ArrayRef[HashRef]', required => 1);

role {
    my $p       = shift;
    my $clients = $p->spore_clients;

    foreach my $client (@$clients) {
        my $name   = $client->{name};
        my $config = $client->{config};

        has $name => (
            is      => 'rw',
            isa     => 'Object',
            lazy    => 1,
            default => sub {
                my $self          = shift;
                my $client_config = $self->$config;
                my $client        = Net::HTTP::Spore->new_from_spec(
                    $client_config->{spec},
                    %{ $client_config->{options} },
                );
                foreach my $mw ( @{ $client_config->{middlewares} } ) {
                    my %options = %{$mw->{options} || {}};
                    $client->enable( $mw->{name}, %options);
                }
                $client;
            },
        );

        has $config => (
            is      => 'rw',
            isa     => 'HashRef',
            lazy    => 1,
            default => sub { {} },
        );
    }
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::HTTP::Spore::Role - Role to easily add multiples Spore clients to your class

=head1 VERSION

version 0.07

=head1 SYNOPSIS

  package my::app;
  use Moose;
  with Net::HTTP::Spore::Role =>
    { spore_clients => [ name => 'twitter', config => 'twitter_config' ] };

  ...

  my $app = my::app->new(twitter_config => $config->{spore}->{twitter_config});

=head1 DESCRIPTION

This is a role you can apply to your class. This role let you create a Spore client with a specific configuration.

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
