package Redis::Client::Set;
$Redis::Client::Set::VERSION = '0.015';
# ABSTRACT: Work with Redis sets

use Moose;
with 'Redis::Client::Role::Tied';

use namespace::sweep 0.003;
use Carp 'croak';


sub TIEHASH { 
    return shift->new( @_ );
}

sub FETCH { 
    return;
}

sub STORE { 
    my ( $self, $member ) = @_;

    $self->_cmd( 'sadd', $member );
    return;
}

sub DELETE { 
    my ( $self, $member ) = @_;

    return $self->_cmd( 'srem', $member );
}

sub CLEAR { 
    my ( $self ) = @_;

    my @members = $self->_cmd( 'smembers' );

    foreach my $member( @members ) { 
        $self->DELETE( $member );
    }
}

sub EXISTS { 
    my ( $self, $member ) = @_;

    return 1 if $self->_cmd( 'sismember', $member );
    return 0;
}

sub FIRSTKEY { 
    my ( $self ) = @_;

    my @members = $self->_cmd( 'smembers' );
    return if @members == 0;

    $self->{members} = \@members;

    return $self->NEXTKEY;
}

sub NEXTKEY { 
    my ( $self ) = @_;

    return shift @{ $self->{members} };
}


__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=head1 NAME

Redis::Client::Set - Work with Redis sets

=head1 VERSION

version 0.015

=head1 SYNOPSIS

    use Redis::Client;

    my $client = Redis::Client->new;
    tie my %set, 'Redis::Client::Set', key => 'my_set', client => $client;

    my @members = keys %set;
    $set{foo} = undef;
    print 1 if exists $set{bar};

=head1 DESCRIPTION

This class provides a C<tie>d interface for Redis sets. Redis sets are mapped
to Perl hashes. Like Perl hashes, Redis sets contain an unordered group of 
"members" which are mapped to keys in the hash. The values in a hash tied to 
a Redis set are ALWAYS C<undef>. Adding a value to a Redis set will cause the
member to be created if it does not already exist, but the value will be 
discarded. 

Any time the hash is evaluated or the existence of a key is tested, the 
corresponding value will be fetched from the Redis store. Any time a key is 
added or deleted, the change will be written to the Redis store.

=encoding utf8

=head1 INTERFACE

The following Perl builtins will work the way you expect on Redis sets.

=over

=item C<delete>

Removes a member from the set. (Note that this is not the same as setting the value
to C<undef>, in which case the member still exists.)

    delete $set{foo};

=item C<exists>

Check if a member exists in the set.

    print 1 if exists $set{blargh};

=item C<keys>

Retrieves a list of all members in the set, in no particular order.

    my @members = keys %set;

=item C<values>

Retrieves a list of all "values" in the set. This will always be a 
list of C<undef>s. Not very useful.

    my @vals = values %set;

=item C<each>

Iterate over key/value pairs from the hash. The values will always be
C<undef>. 

    while( my ( $key, $val ) = each %set ) { ... }

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
