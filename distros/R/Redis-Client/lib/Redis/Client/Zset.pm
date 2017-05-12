package Redis::Client::Zset;
$Redis::Client::Zset::VERSION = '0.015';
# ABSTRACT: Work with Redis ordered sets (zsets)

use Moose;
with 'Redis::Client::Role::Tied';

use namespace::sweep 0.003;
use Carp 'croak';


sub TIEHASH { 
    return shift->new( @_ );
}

sub FETCH { 
    my ( $self, $member ) = @_;

    return $self->_cmd( 'zscore', $member );
}

sub STORE { 
    my ( $self, $member, $score ) = @_;

    $self->_cmd( 'zadd', $score, $member );
    return $score;
}

sub DELETE { 
    my ( $self, $member ) = @_;

    my $score = $self->FETCH( $member );
    $self->_cmd( 'zrem', $member );

    return $score;
}

sub CLEAR { 
    my ( $self ) = @_;

    my @members = $self->_cmd( 'zrange', 0, -1 );

    foreach my $member( @members ) { 
        $self->DELETE( $member );
    }
}

sub EXISTS { 
    my ( $self, $member ) = @_;

    return 1 if defined $self->_cmd( 'zscore', $member );
    return 0;
}

sub FIRSTKEY { 
    my ( $self ) = @_;

    my @members = $self->_cmd( 'zrange', 0, -1 );
    return if @members == 0;

    $self->{members} = \@members;

    return $self->NEXTKEY;
}

sub NEXTKEY { 
    my ( $self ) = @_;

    return shift @{ $self->{members} };
}


1;


__PACKAGE__->meta->make_immutable;

__END__

=pod

=head1 NAME

Redis::Client::Zset - Work with Redis ordered sets (zsets)

=head1 VERSION

version 0.015

=head1 SYNOPSIS

    use Redis::Client;

    my $client = Redis::Client->new;
    tie my %set, 'Redis::Client::Zset', key => 'my_zset', client => $client;

    my @members = keys %zset;
    $zset{foo} = 0.6;
    print 1 if exists $zset{bar};

=head1 DESCRIPTION

This class provides a C<tie>d interface for Redis sorted sets (zsets). Redis 
zsets are mapped to Perl hashes. Like Perl hashes, Redis zsets contain an 
unordered group of "members" which are mapped to keys in the hash. The values 
in a hash tied to a Redis zset are numeric scores which control the sort order. 
Adding a value to a Redis set will cause the member to be created if it does 
not already exist. The value determines the new member's ordering with 
respect to the other members. 

Any time the hash is evaluated or the existence of a key is tested, the 
corresponding value will be fetched from the Redis store. Any time a key is 
added or deleted, the change will be written to the Redis store.

=encoding utf8

=head1 INTERFACE

The following Perl builtins will work the way you expect on Redis zsets.

=over

=item C<delete>

Removes a member from the zset. (Note that this is not the same as setting the value
to C<undef>, in which case the member still exists.)

    delete $zset{foo};

=item C<exists>

Check if a member exists in the zset.

    print 1 if exists $zset{blargh};

=item C<keys>

Retrieves a list of all members in the zset, in sorted order.

    my @members = keys %zset;

=item C<values>

Retrieves a list of all "values" in the zset. These are the numeric
scores associated with each member. The list is returned sorted.

    my @scores = values %zset;

=item C<each>

Iterate over key/value pairs from the hash. The keys are the members and
the values are the scores. The keys and values are returned in sorted 
order.

    while( my ( $key, $val ) = each %zset ) { ... }

=head1 CAVEATS

As of Redis 2.4, emptying a zset (with e.g. C<%zset = ( )> is equivalent
to deleting it from the store.

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
