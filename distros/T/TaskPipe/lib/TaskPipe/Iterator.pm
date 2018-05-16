package TaskPipe::Iterator;

use Moose;
with 'MooseX::ConfigCascade';


has 'next' => (is => 'rw', isa => 'CodeRef');
has 'reset' => (is => 'rw', isa => 'CodeRef');
has 'count' => (is => 'rw', isa => 'CodeRef', default => sub{sub{return -1}});


=head1 NAME

TaskPipe::Iterator - generic class for TaskPipe Iterators

=head1 DESCRIPTION

If you are creating an iterator, you can either get a new instance 
of a generic iterator and then supply the subs:

    my $iterator = TaskPipe::Iterator->new(

        next => sub{ 
                     #...
                },

        count => sub {
                     #...
                },

        reset => sub {
                    # ...
                }

     );

or you can inherit from L<TaskPipe::Iterator> and override the subs. All 3 subs must be provided - however

=head1 SUBS

=head2 next

This sub should iterate the record pointer and return the next record

=head2 reset

This sub should reset the record pointer to the first record.

=head2 count

Optional. If you know how many records you are expecting, then this sub should return this value. Including C<count> offers a small performance boost by using the parent thread to execute the last record instead of idling. If the total number of records is not known in advance (often the case with iterators) then this sub should return -1. A sub that returns -1 is the default - so you can just omit this attribute if you don't have a way to calculate the total number of results.

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut


__PACKAGE__->meta->make_immutable;
1;

