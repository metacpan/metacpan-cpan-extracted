package Redis::Client::List;
$Redis::Client::List::VERSION = '0.015';
# ABSTRACT: Work with Redis lists

use Moose;
with 'Redis::Client::Role::Tied';

use namespace::sweep 0.003;
use Carp 'croak';

sub TIEARRAY { 
    return shift->new( @_ );
}


sub FETCH { 
    my ( $self, $idx ) = @_;

    return $self->_cmd( 'lindex', $idx );
}

sub STORE { 
    my ( $self, $idx, $val ) = @_;

    return $self->_cmd( 'lset', $idx, $val );
}

sub FETCHSIZE { 
    my ( $self ) = @_;

    return $self->_cmd( 'llen' );
}

sub STORESIZE { 
    croak q{Can't modify the size of a Redis list. Use push or unshift.};
}

sub EXTEND { 
}

sub EXISTS { 
    my ( $self, $idx ) = @_;

    return 1 if $self->FETCHSIZE > $idx;
    return;
}

sub DELETE { 
    my ( $self, $idx ) = @_;

    return $self->STORE( $idx, undef );
}

sub CLEAR { 
    my ( $self ) = @_;

    return $self->_cmd( 'ltrim', 0, 0 );
}

sub PUSH { 
    my ( $self, @args ) = @_;

    return $self->_cmd( 'rpush', @args );
}

sub POP { 
    my ( $self ) = @_;

    return $self->_cmd( 'rpop' );
}

sub UNSHIFT { 
    my ( $self, @args ) = @_;

    return $self->_cmd( 'lpush', @args );
}

sub SHIFT { 
    my ( $self ) = @_;

    return $self->_cmd( 'lpop' );
}

sub SPLICE { 
    croak q{splice is not implemented for Redis lists.};
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Redis::Client::List - Work with Redis lists

=head1 VERSION

version 0.015

=head1 SYNOPSIS

    use Redis::Client;
    
    my $client = Redis::Client->new;
    tie my @list, 'Redis::Client::List', key => 'my_list', client => $client;

    @list = ( 1, 2, 3 );
    push @list, 4, 5, 6;
    my $val  = $list[0];     # 1
    my $val2 = pop @list;    # 6

=head1 DESCRIPTION

This class provides a C<tie>d interface to Redis lists. Redis lists are mapped to 
Perl arrays. Like Perl arrays, a Redis list contains an ordered sequence of 
values. Any time the list or an element from the list is evaluated, its current
value will be fetched from the Redis store. Any time the C<tie>d array or an element 
of  the C<tie>d array is changed, its new value will be written to the Redis store.

=encoding utf8

=head1 INTERFACE

The following Perl builtins will work the way you expect on Redis lists.

=over

=item C<exists>

Returns a true value if the size of the Redis list has an index this high.

    print 'List has at least 43 elements' if exists $list[42];

=item C<delete>

Deletes the item stored at an index, setting its value to C<undef>. It 
does NOT shift the rest of the list down. 

    delete $list[3];    # sets to undef

=item C<push>

Adds elements to the end of the list, using the Redis C<RPUSH> command.

    push @list, 'foo', 'bar', 'baz';

=item C<pop>

Removes the last element of the list and returns it, using the Redis
C<RPOP> command.

    my $last = pop @list;

=item C<shift>

Removes an element from the beginning of the list and shifts the remaining
elements down, using the Redis C<LPOP> command.

    my $first = shift @list;

=item C<unshift>

Adds elements to the beginning of a list, using the Redis C<LPUSH>
command.

    unshift @list, 'quux', 'narf';

=back

=head1 CAVEATS

The C<splice> operator is not yet supported for Redis lists.

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
