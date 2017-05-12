package NgxQueue;
use strict;
use warnings;

our $VERSION = '0.02';

# load backend (XS or PP)
my $use_xs = 0;
if (!exists $INC{'NgxQueue/PP.pm'}) {
    my $pp = $ENV{PERL_ONLY};
    if (!$pp) {
        eval qq{
            require XSLoader;
            XSLoader::load __PACKAGE__, $VERSION;
        };
    }
    if (__PACKAGE__->can('new')) {
        $use_xs = 1;
    }
    else {
        require 'NgxQueue/PP.pm';
        push @NgxQueue::ISA, 'NgxQueue::PP';
    }
}
sub BACKEND() { $use_xs ? 'XS' : 'PP' }

1;

__END__

=head1 NAME

NgxQueue - Simple double linked list based nginx's ngx-queue.h

=head1 SYNOPSIS

    use NgxQueue;
    
    my $queue = NgxQueue->new;
    
    my $foo = NgxQueue->new('foo');
    my $bar = NgxQueue->new('bar');
    
    $queue->insert_tail( $foo );
    $queue->insert_tail( $bar );
    
    print $queue->head->data; # => foo
    print $queue->last->data; # => bar
    print $queue->head->next->data; # => bar
    
    $queue->foreach(sub {
        print $_->data;
    });
    # => foobar
    
    $foo->remove;
    
    $queue->foreach(sub {
        print $_->data;
    });
    # => bar

=head1 DESCRIPTION

B<This module interface is still fluid, and may change in the future.>

NgxQueue provides simple double linked list. Its implementation is based L<nginx|http://nginx.org/>'s ngx-queue.h

Using this module, you can remove a list node without list container reference.
This is useful especially for some network server implementations.

For example,

=over

=item 1. Your server object has main connection queue

=item 2. When new connection was accepted, server create a connection object, and queue it into the connection queue.

=item 3. When some error occurred, connection object can remove itself from server's connection queue without server object reference.

=back

This make your code more clean and simple.

=head1 LEAK NOTICE

Once NgxQueue object is added to other queue by C<insert_tail>, C<insert_head>, or C<insert_after>, its object refcount will be retained until removed.

So you should call C<remove> when destroying your container, otherwise it causes memory leak.

If you want to use single queue container, following container class will help:

    package MyQueueContainer;
    use strict;
    use warning;
    use parent 'NgxQueue';
    
    sub DESTROY {
        $_[0]->foreach(sub { $_->remove });
    }
    
    1;

=head1 METHODS

=head2 new($data)

    my $q = NgxQueue->new('some data');

Create new NgxQueue object. C<$data> is optional.

If you pass some C<$data>, the data is available by calling C<< $obj->data >>.

=head2 data

Get some data associated the object.

    my $data = $q->data;

=head2 empty

Check queue is empty.

    my $q = NgxQueue->new;
    $q->empty; # => true
    
    $q->insert_tail( NgxQueue->new('foo') );
    $q->empty; # => false

=head2 insert_head

Insert a queue where head of container

    my $q = NgxQueue->new;
    $q->insert_head( NgxQueue->new('foo'));
    $q->insert_head( NgxQueue->new('bar'));
    
    $q->foreach(sub { print $_->data }); # => barfoo

=head2 insert_after

Insert a queue_a where after the queue_b

    my $q = NgxQueue->new;
    my $queue_a = NgxQueue->new('a');
    $q->insert_head($queue_a);
    
    $queue_a->insert_after( NgxQueue->new('b') );
    
    $q->foreach(sub { print $_->data }); # => ab

=head2 insert_tail

Insert a queue where last of the container

    my $q = NgxQueue->new;
    $q->insert_tail( NgxQueue->new('foo') );
    $q->insert_tail( NgxQueue->new('bar') );
    
    $q->foreach(sub { print $_->data }); # => foobar

=head2 head

Get head of queue object from container.

    my $q = NgxQueue->new;
    $q->insert_head( NgxQueue->new('foo') );
    
    print $q->head->data; # => foo

=head2 last

Get last of queue object from container.

    my $q = NgxQueue->new;
    $q->insert_tail( NgxQueue->new('foo') );
    
    print $q->last->data; # => foo

=head2 next

Get next queue object from queue object.

    my $q = NgxQueue->new;
    
    my $foo = NgxQueue->new('foo');
    my $bar = NgxQueue->new('bar');
    
    $q->insert_tail( $foo );
    $q->insert_tail( $bar );
    
    print $foo->next->data; # => bar

=head2 prev

Get prev queue object from queue object.

    my $q = NgxQueue->new;
    
    my $foo = NgxQueue->new('foo');
    my $bar = NgxQueue->new('bar');
    
    $q->insert_tail( $foo );
    $q->insert_tail( $bar );
    
    print $bar->prev->data; # => foo

=head2 remove

Remove queue object from container.

    my $q = NgxQueue->new;
    my $foo = NgxQueue->new('foo');
    my $bar = NgxQueue->new('bar');
    my $buz = NgxQueue->new('buz');
    
    $q->insert_tail( $foo );
    $q->insert_tail( $bar );
    $q->insert_tail( $buz );
    
    $bar->remove;
    
    $q->foreach(sub { print $_->data }); # => foobuz

=head2 split

Split single container to double containers.

    my $q = NgxQueue->new;
    my $foo = NgxQueue->new('foo');
    my $bar = NgxQueue->new('bar');
    my $buz = NgxQueue->new('buz');
    my $bla = NgxQueue->new('bla');
    
    my $q2 = NgxQueue->new;
    $q->split($buz, $q2);
    
    $q->foreach(sub { print $_->data }); # => foobar
    $q2->foreach(sub { print $_->data }); # => buzbla

=head2 add

Combine two containers into one.

    my $q1 = NgxQueue->new;
    my $q2 = NgxQueue->new;
    
    $q1->insert_tail( NgxQueue->new('foo');
    $q1->insert_tail( NgxQueue->new('bar');
    
    $q2->insert_tail( NgxQueue->new('hoge') );
    $q2->insert_tail( NgxQueue->new('fuga') );
    
    $q1->add($q2);
    
    $q1->foreach(sub { print $_->data }); # => foobarhogefuga

=head2 foreach($block)

foreach loop for the container. Each object represented as C<$_> in the loop block.

=head1 FUNCTIONS

=head2 NgxQueue::BACKEND()

Return backend implementation: 'XS' or 'PP'

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

Masayuki Matsuki <songmu@cpan.org>

=head1 COPYRIGHT AND LICENSE

ngx-queue.h:

    /* 
     * Copyright (C) 2002-2013 Igor Sysoev
     * Copyright (C) 2011-2013 Nginx, Inc.
     * All rights reserved.
     *
     * Redistribution and use in source and binary forms, with or without
     * modification, are permitted provided that the following conditions
     * are met:
     * 1. Redistributions of source code must retain the above copyright
     *    notice, this list of conditions and the following disclaimer.
     * 2. Redistributions in binary form must reproduce the above copyright
     *    notice, this list of conditions and the following disclaimer in the
     *    documentation and/or other materials provided with the distribution.
     *
     * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
     * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
     * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
     * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
     * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
     * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
     * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
     * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
     * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
     * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
     * SUCH DAMAGE.
     */

Other part:

    Copyright (c) 2013 Daisuke Murase All rights reserved.
    
    This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
