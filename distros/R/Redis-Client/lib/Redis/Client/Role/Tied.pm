package Redis::Client::Role::Tied;
$Redis::Client::Role::Tied::VERSION = '0.015';
# ABSTRACT: Role for tied things that talk to Redis

use Moose::Role;
use Carp 'croak';
use Scalar::Util 'blessed';

has key     => ( is => 'ro', isa => 'Str', required => 1 );
has client  => ( is => 'ro', isa => 'Redis::Client', required => 1 );

sub BUILD { 
    my ( $self ) = @_;
    my $class = blessed $self;

    my ( $c_type ) = ( $class =~ m{::(\w+)$} );
    my $type = $self->client->type( $self->key );

    unless ( $type eq lc $c_type ) { 
        die sprintf "Redis key %s is a %s. Try using Redis::Client::%s instead", $self->key, $type, ucfirst $type;
    }
}

sub _cmd { 
    my ( $self, $cmd, @args ) = @_;

    $self->client->$cmd( $self->{key}, @args );
}

1;

__END__

=pod

=head1 NAME

Redis::Client::Role::Tied - Role for tied things that talk to Redis

=head1 VERSION

version 0.015

=head1 DESCRIPTION

This role contains common functionality used by the Redis::Client C<tie> classes.

=encoding utf8

=head1 SEE ALSO

=over

=item L<Redis::Client>

=item L<Redis::Client::String>

=item L<Redis::Client::List>

=item L<Redis::Client::Hash>

=item L<Redis::Client::Set>

=item L<Redis::Client::Zset>

=back

=head1 AUTHOR

Mike Friedman <friedo@friedo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Mike Friedman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
