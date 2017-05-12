package Stack::Persistent;

use 5.008;
use strict;
use warnings;

use File::Spec;
use Cache::FastMmap;

our @ISA = qw();
our $VERSION = '0.04';

# ------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------

sub new {
    my $proto = shift;
    my %params = @_;
    my $class = ref($proto) || $proto;

    my $self = {};

    $self->{handle} = undef;
    $self->{initialize} = 0;
    $self->{num_pages} = 64;
    $self->{page_size} = "64k";
    $self->{expiration} = 0;
    $self->{cachefile} = File::Spec->catfile('tmp', 'stack-persistent.cache');

    bless($self, $class);

    my ($k, $v);
    local $_;

    if (defined($v = delete $params{'-initialize'})) {

        $self->{initialize} = $v;

    }

    if (defined($v = delete $params{'-pages'})) {

        $self->{num_pages} = $v;

    }

    if (defined($v = delete $params{'-size'})) {

        $self->{page_size} = $v;

    }

    if (defined($v = delete $params{'-expiration'})) {

        $self->{expiration} = $v;

    }

    if (defined($v = delete $params{'-filename'})) {

        $self->{cachefile} = $v;

    }

    $self->{handle} = Cache::FastMmap->new(init_file => $self->{initialize},
                                           num_pages => $self->{num_pages},
                                           page_size => $self->{page_size},
                                           expire_time => $self->{expiration},
                                           share_file => $self->{cachefile},
                                           unlink_on_exit => 0);

    $self->{handle}->purge();

    return $self;

}

sub push {
    my ($self, $stack, $data) = @_;

    my ($ckey, $skey, $counter);

    $skey = $stack . ':counter';
    $counter = $self->{handle}->get($skey) || 0;
    $self->{handle}->remove($skey);

    $counter++;
    $ckey = $stack . ':' . $counter;

    $self->{handle}->set($ckey, $data);
    $self->{handle}->set($skey, $counter);

}

sub pop {
    my ($self, $stack) = @_;

    my ($ckey, $skey, $data, $counter);

    $skey = $stack . ':counter';
    $counter = $self->{handle}->get($skey) || 0;

    $ckey = $stack . ':' . $counter;
    $data = $self->{handle}->get($ckey);

    $self->{handle}->remove($skey);
    $self->{handle}->remove($ckey);

    $counter--;
    $self->{handle}->set($skey, $counter);

    return($data);

}

sub peek {
    my ($self, $stack) = @_;

    my ($ckey, $skey, $data, $counter);

    $skey = $stack . ':counter';
    $counter = $self->{handle}->get($skey) || 0;

    $ckey = $stack . ':' . $counter;
    $data = $self->{handle}->get($ckey);

    return($data);

}

sub items {
    my ($self, $stack) = @_;

    my ($skey, $counter);

    $skey = $stack . ':counter';
    $counter = $self->{handle}->get($skey) || 0;

    return($counter);

}

sub clear {
    my ($self, $stack) = @_;

    my ($skey, $ckey, $counter);

    $skey = $stack . ':counter';
    $counter = $self->{handle}->get($skey) || 0;

    for (; $counter > 0; $counter--) {
        
        $ckey = $stack . ':' . $counter;
        $self->{handle}->remove($ckey);

    }

    $self->{handle}->set($skey, $counter);

}

sub dump {
    my ($self, $stack) = @_;

    my $item;
    my @items = $self->{handle}->get_keys(2);

    foreach $item (@items) {

        if ($stack eq substr($item->{key}, 0, index($item->{key}, ':'))) {

            printf("key: %s; last_access: %s; expiration: %s; flags: %s\n",
                   $item->{key}, $item->{last_access}, $item->{expire_time},
                   $item->{flags});
            printf("    value: %s\n", $item->{value});

        }

    }

    return 0;

}

sub handle {
    my $self = shift;

    return($self->{handle});

}
    
1;

__END__

=head1 NAME

Stack::Persistent - A persistent stack

=head1 SYNOPSIS

This module implements a named, persistent stack for usage by programs that 
need to recover the items on a  stack when something unexpected happens.
The stack is LIFO based.

=head1 DESCRIPTION

This module can be used as follows:

 use Stack::Persistent;

 $stack = Stack::Persistent->new();

 $stack->push('default', 'some really cool stuff');
 printf("There are %s items on the stack\n", $stack->items('default'));
 printf("My data is: %s\n", $stack->pop('default'));

The main purpose of this module was to have a persistent stack that 
could survive the restart of a program. Multiple, named stacks can be 
maintained. 

=head1 METHODS

=over 4

=item new

There are several named parameters that can be used with this method. Since
this module use Cache::FastMmap to manage the backing store. You should read 
that modules documentation. They are the following:

=over 4

=item -initialize

This initializes the stacks backing cache. You will not want to do this if 
your program needs to retireve items after a restart. The default is to not
initialize.

=item -pages

What the number of pages for your stacks backing cache should be. The 
default is 64.

=item -size

The size of those pages in bytes. The default is 64KB.

=item -expiration

The expiration of item with the stacks cache.

=item -filename

The name of the file that is being used. The default is 
/tmp/stack-persistent.cache.

=item Example

 $stack = Stack::Persistent->new(-filename => '/tmp/stack.cache');

=back

=item push

Push a data element onto the  named stack. 

=over 4

=item Example

 $stack->push('default', $data);

=back

=item pop

Remove a data element from the top of a named stack. Once an element has
been "popped" it is no longer avaiable within the cache.

=over 4

=item Example

 $data = $stack->pop('default');

=back

=item peek

Retrieve the data element from the top of the stack. The data element is not 
removed from the stack. To remove an element, you need to use pop().

=over 4

=item Example

 $data = $stack->peek('default');

=back

=item items

Return the number of data elements that are currently on the stack.

=over 4

=item Example

 $items1 = $stack->items('default');
 $items2 = $stack->items('worker');

=back

=item clear

Remove all data elements from the stack. Once a stack has
been "cleared" there are no data elements left within the cache.

=over 4

=item Example

 $stack->clear('default');

=back

=item dump

Dump all the backing cache for the stack. This is can be used for debugging 
purposes.

=over 4

=item Example

 $stack->dump('default');

=back

=head1 ACCESSORS

=over 4

=item handle

This accessor returns the underling handle for Cache::FastMmap. You can then
use any of methods that are available to that module.

=over 4

=item Example

 $handle = $stack->handle;
 $handle->purge();

=back

=head1 EXPORT

None by default.

=head1 SEE ALSO

 Cache::FastMmap

=head1 AUTHOR

Kevin L. Esteb, E<lt>kesteb@wsipc.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
