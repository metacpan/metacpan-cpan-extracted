package Redis::Client::Hash;
$Redis::Client::Hash::VERSION = '0.015';
# ABSTRACT: Work with Redis hashes

use Moose;
with 'Redis::Client::Role::Tied';

use namespace::sweep 0.003;
use Carp 'croak';


sub TIEHASH { 
    return shift->new( @_ );
}

sub FETCH { 
    my ( $self, $key ) = @_;

    return $self->_cmd( 'hget', $key );
}

sub STORE { 
    my ( $self, $key, $val ) = @_;

    return $self->_cmd( 'hset', $key, $val );
}

sub DELETE { 
    my ( $self, $key ) = @_;

    my $val = $self->FETCH( $key );

    if ( $self->_cmd( 'hdel', $key ) ) { 
        return $val;
    }

    return;
}

sub CLEAR { 
    my ( $self ) = @_;

    my @keys = $self->_cmd( 'hkeys' );

    foreach my $key( @keys ) { 
        $self->DELETE( $key );
    }
}

sub EXISTS { 
    my ( $self, $key ) = @_;

    return 1 if $self->_cmd( 'hexists', $key );
    return;
}

sub FIRSTKEY { 
    my ( $self ) = @_;

    my @keys = $self->_cmd( 'hkeys' );
    return if @keys == 0;

    $self->{keys} = \@keys;

    return $self->NEXTKEY;
}

sub NEXTKEY { 
    my ( $self ) = @_;

    return shift @{ $self->{keys} };
}


1;

__PACKAGE__->meta->make_immutable;

__END__

=pod

=head1 NAME

Redis::Client::Hash - Work with Redis hashes

=head1 VERSION

version 0.015

=head1 SYNOPSIS

    use Redis::Client;

    my $client = Redis::Client->new;
    tie my %hash, 'Redis::Client::Hash', key => 'my_hash', client => $client;

    my @keys = keys %hash;
    $hash{foo} = 42;
    print 1 if exists $hash{bar};

=head1 DESCRIPTION

This class provides a C<tie>d interface for Redis hashes. Redis hashes are mapped
to Perl hashes. Like Perl hashes, Redis hashes contain an unordered set of key-value
pairs. Any time the C<tie>d hash or one of its elements is evaluated, the corresponding
item will be fetched from the Redis store. Any time it is modified, the value will
be written to the Redis store.

=encoding utf8

=head1 INTERFACE

The following Perl builtins will work the way you expect on Redis hashes.

=over

=item C<delete>

Removes a key from the hash. (Note that this is not the same as setting the value
to C<undef>, in which case the key still exists.)

    delete $hash{foo};

=item C<exists>

Check if a key exists in the hash.

    print 1 if exists $hash{blargh};

=item C<keys>

Retrieves a list of all keys in the hash, in no particular order.

    my @keys = keys %hash;

=item C<values>

Retrieves a list of all values in the hash, in no particular order

    my @vals = values %hash;

=item C<each>

Iterate over key/value pairs from the hash.

    while( my ( $key, $val ) = each %hash ) { ... }

=back

=head1 SEE ALSO

=over

=item L<Redis::Client>

=back

=head1 EXTENDS

=over 4

=item * L<Moose::Object>

=back

=head1 CONSUMES

=over 4

=item * L<Redis::Client::Role::Tied>

=back

=head1 AUTHOR

Mike Friedman <friedo@friedo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Mike Friedman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
