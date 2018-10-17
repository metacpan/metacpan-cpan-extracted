package Parallel::Loops;

our $VERSION='0.10';

# For Tie::ExtraHash - This was the earliest perl version in which I found this
# class
use 5.008;

=head1 NAME

Parallel::Loops - Execute loops using parallel forked subprocesses

=encoding utf-8

=head1 SYNOPSIS

    use Parallel::Loops;

    my $maxProcs = 5;
    my $pl = Parallel::Loops->new($maxProcs);

    my @parameters = ( 0 .. 9 );

    # We want to perform some hefty calculation for each @input and
    # store each calculation's result in %output. For that reason, we
    # "tie" %output, so that changes to %output in any child process
    # (see below) are automatically transfered and updated in the
    # parent also.

    my %returnValues;
    $pl->share( \%returnValues );

    $pl->foreach( \@parameters, sub {
        # This sub "magically" executed in parallel forked child
        # processes

        # Lets just create a simple example, but this could be a
        # massive calculation that will be parallelized, so that
        # $maxProcs different processes are calculating sqrt
        # simultaneously for different values of $_ on different CPUs
        # (Do see 'Performance' / 'Properties of the loop body' below)

        $returnValues{$_} = sqrt($_);
    });
    foreach (@parameters) {
        printf "i: %d sqrt(i): %f\n", $_, $returnValues{$_};
    }

You can also use @arrays instead of %hashes, and/or while loops
instead of foreach:

    my @returnValues;
    $pl->share(\@returnValues);

    my $i = 0;
    $pl->while ( sub { $i++ < 10 }, sub {
        # This sub "magically" executed in parallel forked
        # child processes

        push @returnValues, [ $i, sqrt($i) ];
    });

And you can have both foreach and while return values so that $pl->share()
isn't required at all:

    my $maxProcs = 5;
    my $pl = Parallel::Loops->new($maxProcs);
    my %returnValues = $pl->foreach( [ 0..9 ], sub {
        # Again, this is executed in a forked child
        $_ => sqrt($_);
    });

=head1 DESCRIPTION

Often a loop performs calculations where each iteration of the loop
does not depend on the previous iteration, and the iterations really
could be carried out in any order.

This module allows you to run such loops in parallel using all the
CPUs at your disposal.

Return values are automatically transfered from children to parents via
%hashes or @arrays, that have explicitly been configured for that sort
of sharing via $pl->share(). Hashes will transfer keys that are
set in children (but not cleared or unset), and elements that are
pushed to @arrays in children are pushed to the parent @array too (but
note that the order is not guaranteed to be the same as it would have
been if done all in one process, since there is no way of knowing
which child would finish first!)

If you can see past the slightly awkward syntax, you're basically
getting foreach and while loops that can run in parallel without
having to bother with fork, pipes, signals etc. This is all handled
for you by this module.

=head2 foreach loop

    $pl->foreach($arrayRef, $childBodySub)

Runs $childBodySub->() with $_ set foreach element in @$arrayRef, except that
$childBodySub is run in a forked child process to obtain parallelism.
Essentially, this does something conceptually similar to:

    foreach(@$arrayRef) {
        $childBodySub->();
    }

Any setting of hash keys or pushing to arrays that have been set with
$pl->share() will automagically appear in the hash or array in the parent
process.

If you like loop variables, you can run it like so:

    $pl->foreach( \@input, sub {
            my $i = $_;
            .. bla, bla, bla ... $output{$i} = sqrt($i);
        }
    );

=head2 while loop

  $pl->while($conditionSub, $childBodySub [,$finishSub])

Essentially, this does something conceptually similar to:

  while($conditionSub->()) {
      $childBodySub->();
  }

except that $childBodySub->() is executed in a forked child process.
Return values are transfered via share() like in L</foreach loop> above.

=head3 While loops must affect condition outside $childBodySub

Note that incrementing $i in the $childBodySub like in this example
B<will not work>:

   $pl->while( sub { $i < 5 },
               sub {
                   $output{$i} = sqrt($i);
                   # Won't work!
                   $i++
               }
             );

Because $childBodySub is executed in a child, and so while $i would
be incremented in the child, that change would not make it to the
parent, where $conditionSub is evaluated. The changes that make
$conditionSub return false eventually I<must> take place outside
the $childBodySub so it is executed in the parent. (Adhering to
the parallel principle that one iteration may not affect any other
iterations - including whether to run them or not)

=head3 Optional $finishSub parameter

In order to track progress, an optional C<$finishSub> can be provided. It will
be called whenever a child finishes. The return value from the C<$conditionSub>
is remembered and provided to the C<$finishSub> as a reference:

    my $i = 0;
    my %returnValues = $pl->while (
        sub { $i++ < 10 ? $i : 0 },
        sub {
            return ($i, sqrt($i));
        },
        sub {
            my ($i) = @_;
            printf "Child %d has finished\n", $i;
        }
    );

=head2 share

  $pl->share(\%output, \@output, ...)

Each of the arguments to share() are instrumented, so that when a
hash key is set or array element pushed in a child, this is transfered
to the parent's hash or array automatically when a child is finished.

B<Note the limitation> Only keys being set like C<$hash{'key'} = 'value'> and
arrays elements being pushed like C<push @array, 'value'> will be transfered to
the parent. Unsetting keys, or setting particluar array elements with
$array[3]='value' will be lost if done in the children. Also, if two different
children set a value for the same key, a random one of them will be seen by the
parent.

In the parent process all the %hashes and @arrays are full-fledged, and you can
use all operations.  But only these mentioned operations in the child processes
make it back to the parent.

=head3 Array element sequence not defined

Note that when using share() for @returnValue arrays, the sequence of elements
in @returnValue is not guaranteed to be the same as you'd see with a normal
sequential while or foreach loop, since the calculations are done in parallel
and the children may end in an unexpected sequence.  But if you don't really
care about the order of elements in the @returnValue array then share-ing an
array can be useful and fine.

If you need to be able to determine which iteration generated what output, use
a hash instead.

=head2 Recursive forking is possible

Note that no check is performed for recursive forking: If the main
process encouters a loop that it executes in parallel, and the
execution of the loop in child processes also encounters a parallel
loop, these will also be forked, and you'll essentially have
$maxProcs^2 running processes. It wouldn't be too hard to implement
such a check (either inside or outside this package).

=head1 Exception/Error Handling / Dying

If you want some measure of exception handling you can use eval in the child
like this:

    my %errors;
    $pl->share( \%errors );
    my %returnValues = $pl->foreach( [ 0..9 ], sub {
        # Again, this is executed in a forked child
        eval {
            die "Bogus error"
                if $_ == 3;
            $_ => sqrt($_);
        };
        if ($@) {
            $errors{$_} = $@;
        }
    });

    # Now test %errors. $errors{3} should exist as the only element

Also, be sure not to call exit() in the child. That will just exit the child
and that doesn't work. Right now, exit just makes the parent fail no-so-nicely.
Patches to this that handle exit somehow are welcome.

=head1 Performance

=head2 Properties of the loop body

Keep in mind that a child process is forked every time while or foreach calls
the provided sub. For use of Parallel::Loops to make sense, each invocation
needs to actually do some serious work for the performance gain of parallel
execution to outweigh the overhead of forking and communicating between the
processes. So while sqrt() in the example above is simple, it will actually be
slower than just running it in a standard foreach loop because of the overhead.

Also, if each loop sub returns a massive amount of data, this needs to be
communicated back to the parent process, and again that could outweigh parallel
performance gains unless the loop body does some heavy work too.

=head2 Linux and Windows Comparison

On the same VMware host, I ran this script in Debian Linux and Windows XP
virtual machines respectively. The script runs a "no-op" sub in 1000 child
processes two in parallel at a time

    my $pl = Parallel::Loops->new(2);
    $pl->foreach( [1..1000], sub {} );

For comparison, that took:

   7.3 seconds on Linux
  43   seconds on Strawberry Perl for Windows
 240   seconds on Cygwin for Windows

=head2 fork() e.g. on Windows

On some platforms the fork() is emulated. Be sure to read perlfork.

=head2 Temporary files unless select() works - e.g. on Windows

E.g. on Windows, select is only supported for sockets, and not for pipes. So we
use temporary files to store the information sent from the child to the parent.
This adds a little extra overhead. See perlport for other platforms where there
are problems with select. Parallel::Loops tests for a working select() and uses
temporary files otherwise.

=head1 SEE ALSO

This module uses fork(). ithreads could have been possible too, but was not
chosen. You may want to check out:

When to use forks, when to use threads ...?
L<http://www.perlmonks.org/index.pl?node_id=709061>

The forks module (not used here)
L<http://search.cpan.org/search?query=forks>

threads in perlthrtut
L<http://perldoc.perl.org/perlthrtut.html>

=head1 DEPENDENCIES

I believe this is the only dependency that isn't part of core perl:

    use Parallel::ForkManager;

These should all be in perl's core:

    use Storable;
    use IO::Handle;
    use Tie::Array;
    use Tie::Hash;

=head1 BUGS / ENHANCEMENTS

No bugs are known at the moment. Send any reports to peter@morch.com.

Enhancements:

Optionally prevent recursive forking: If a forked child encounters a
Parallel::Loop it should be possible to prevent that Parallel::Loop instance to
also create forks.

Determine the number of CPUs so that new()'s $maxProcs parameter can be
optional. Could use e.g. Sys::Sysconf, UNIX::Processors or Sys::CPU.

Maybe use function prototypes (see Prototypes under perldoc perlsub).

Then we could do something like

    pl_foreach @input {
        yada($_);
    };
or

    pl_foreach $pl @input {
        yada($_);
    };

instead of

    $pl->foreach(\@input, sub {
        yada($_);
    });

and so on, where the first suggestion above means global variables (yikes!).
Unfortunately, methods aren't supported by prototypes, so this will never be
posssible:

    $pl->foreach @input {
        yada($_);
    };

An alternative pointed out by the perlmonks chatterbox could be to use
L<Devel::Declare|http://search.cpan.org/perldoc?Devel::Declare> "if I can stand
pain".

=head1 SOURCE REPOSITORY

See the git source on github L<https://github.com/pmorch/perl-Parallel-Loops>

=head1 COPYRIGHT

Copyright (c) 2008 Peter Valdemar Mørch <peter@morch.com>

All right reserved. This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

  Peter Valdemar Mørch <peter@morch.com>

=cut

use strict;
use warnings;

use Carp;
use IO::Handle;
use IO::Select;
use File::Temp qw(tempfile);
use Storable;
use Parallel::ForkManager;

sub new {
    my ($class, $maxProcs, %options) = @_;
    my $self = {
        maxProcs => $maxProcs,
        shareNr => 0,
        workingSelect => testWorkingSelect(),
    };
    return bless $self, $class;
}

sub testWorkingSelect {
    my $reader = IO::Handle->new();
    my $writer  = IO::Handle->new();
    pipe( $reader, $writer )
        or die "Couldn't open a pipe";
    $writer->autoflush(1);
    my $select = IO::Select->new();
    $select->add($reader);
    print $writer "test\n";

    # There should be data right away, so lets not risk blocking if it is
    # unreliable
    my @handles = $select->can_read(0);
    my $working = (scalar(@handles) == 1);

    close $reader;
    close $writer;

    return $working;
}

sub share {
    my ($self, @tieRefs) = @_;
    foreach my $ref (@tieRefs) {
        if (ref $ref eq 'HASH') {
            my %initialContents =  %$ref;
            # $storage will point to the Parallel::Loops::TiedHash object
            my $storage;
            tie %$ref, 'Parallel::Loops::TiedHash', $self, \$storage;
            %$ref = %initialContents;
            push @{$$self{tieObjects}}, $storage;
            push @{$$self{tieHashes}}, [$$self{shareNr}, $ref];
        } elsif (ref $ref eq 'ARRAY') {
            my @initialContents =  @$ref;
            # $storage will point to the Parallel::Loops::TiedArray object
            my $storage;
            tie @$ref, 'Parallel::Loops::TiedArray', $self, \$storage;
            @$ref = @initialContents;
            push @{$$self{tieObjects}}, $storage;
            push @{$$self{tieArrays}}, [$$self{shareNr}, $ref];
        } else {
            croak "Only unblessed hash and array refs are supported by share";
        }
        $$self{shareNr}++;
    }
}

sub in_child {
    my ($self) = @_;
    return $$self{forkManager} && $$self{forkManager}->is_child;
}

sub readChangesFromChild {
    my ($self, $childRdr, $childFinishSub) = @_;

    my $childOutput;

    if ($$self{workingSelect}) {
        local $/;
        $childOutput = <$childRdr>;
    } else {
        my $filename = <$childRdr>;
        open my $in, $filename
            or die "Couldn't open $filename";
        binmode $in;
        {
            local $/;
            $childOutput = <$in>;
        }
        close $in;
        unlink $filename;

    }
    die "Error getting result contents from child"
        if $childOutput eq '';

    my @output;
    eval {
        @output = @{ Storable::thaw($childOutput) };
    };
    if ($@) {
        die "Error interpreting result from child: $@";
    }
    my $error = shift @output;
    my $retval = shift @output;

    foreach my $set (@{$$self{tieHashes}}) {
        my ($outputNr, $h) = @$set;
        foreach my $k (keys %{$output[$outputNr]}) {
            $$h{$k} = $output[$outputNr]{$k};
        }
    }
    foreach my $set (@{$$self{tieArrays}}) {
        my ($outputNr, $a) = @$set;
        foreach my $v (@{$output[$outputNr]}) {
            push @$a, $v;
        }
    }
    if ($error) {
        die "Error from child: $error";
    }
    $childFinishSub->()
        if $childFinishSub;
    return @$retval;
}

sub printChangesToParent {
    my ($self, $error, $retval, $parentWtr) = @_;
    my $outputNr = 0;
    my @childInfo = ($error, $retval);
    foreach (@{$$self{tieObjects}}) {
        push @childInfo, $_->getChildInfo();
    }
    {
        local $SIG{PIPE} = sub {
            die "Couldn't print to pipe";
        };
        if ($$self{workingSelect}) {
            print $parentWtr Storable::freeze(\@childInfo);
        } else {
            my ($fh, $filename) = tempfile();
            binmode $fh;
            print $fh Storable::freeze(\@childInfo);
            close $fh;
            print $parentWtr $filename;
        }
    }
}

sub while {
    my ($self, $continueSub, $bodySub, $finishSub) = @_;
    my @retvals;

    # This is used if $$self{workingSelect}
    my $childCounter = 0;
    my $nrRunningChildren = 0;
    my $select = IO::Select->new();

    # Else this is used
    my %childHandles;

    my $fm = Parallel::ForkManager->new($$self{maxProcs});
    $$self{forkManager} = $fm;
    my %childFinishSubs;
    $fm->run_on_finish( sub {
        my ($pid) = @_;
        if ($$self{workingSelect}) {
            $nrRunningChildren--;
        } else {
            my $childRdr = $childHandles{$pid};
            push @retvals, $self->readChangesFromChild(
                $childRdr, $childFinishSubs{$childRdr}
            );
            close $childRdr;
        }
    });
    while (my $childData = $continueSub->()) {
        # Setup pipes so the child can send info back to the parent about
        # output data.
        my $parentWtr = IO::Handle->new();
        my $childRdr  = IO::Handle->new();
        pipe( $childRdr, $parentWtr )
            or die "Couldn't open a pipe";
        binmode $parentWtr;
        binmode $childRdr;
        $parentWtr->autoflush(1);

        if ($finishSub) {
            $childFinishSubs{$childRdr} = sub {
                $finishSub->($childData);
            };
        }

        if ($$self{workingSelect}) {
            # Read data from children that are ready. Block if maxProcs has
            # been reached, so that we are sure to close some file handle(s).
            my @ready = $select->can_read(
                $nrRunningChildren >= $$self{maxProcs} ?  undef : 0
            );
            for my $fh ( @ready ) {
                push @retvals, $self->readChangesFromChild(
                    $fh, $childFinishSubs{$fh}
                );
                $select->remove($fh);
                close $fh;
            }
        }

        my $pid = $fm->start( ++$childCounter );
        if ($pid) {
            # We're running in the parent...
            close $parentWtr;
            if ($$self{workingSelect}) {
                $nrRunningChildren++;
                $select->add($childRdr);
            } else {
                $childHandles{$pid} = $childRdr;
            }
            next;
        }

        # We're running in the child
        close $childRdr;

        my @retval;
        eval {
            @retval = $bodySub->();
        };
        my $error = $@;

        if (! defined wantarray) {
            # Lets not waste any energy printing stuff to the parent, if the
            # parent isn't going to use the return values anyway
            @retval = ();
        }

        $self->printChangesToParent($error, \@retval, $parentWtr);
        close $parentWtr;

        $fm->finish($childCounter);    # pass an exit code to finish
    }

    if ($$self{workingSelect}) {
        while (my @ready = $select->can_read()) {
            for my $fh (@ready) {
                push @retvals, $self->readChangesFromChild(
                    $fh, $childFinishSubs{$fh}
                );
                $select->remove($fh);
                close $fh;
            }
        }
    }

    $fm->wait_all_children;
    delete $$self{forkManager};
    return @retvals;
}

# foreach is implemented via while above
sub foreach {
    my ($self, $varRef, $arrayRef, $sub);
    if (ref $_[1] eq 'ARRAY') {
        ($self, $arrayRef, $sub) = @_;
    } else {
        # Note that this second usage is not documented (and hence not
        # supported). It isn't really useful, but this is how to use it just in
        # case:
        #
        # my $foo;
        # my %returnValues = $pl->foreach( \$foo, [ 0..9 ], sub {
        #     $foo => sqrt($foo);
        # });
        ($self, $varRef, $arrayRef, $sub) = @_;
    }
    my $i = -1;
    $self->while( sub { ++$i <= $#{$arrayRef} }, sub {
        # Setup either $varRef or $_, if no such given before calling $sub->()
        if ($varRef) {
            $$varRef = $arrayRef->[$i];
        } else {
            $_ = $arrayRef->[$i];
        }
        $sub->();
    });
}

package Parallel::Loops::TiedHash;
use Tie::Hash;
use base 'Tie::ExtraHash';

sub TIEHASH {
    my ( $class, $loops, $storageRef ) = @_;
    my $storage = bless [ {}, { loops => $loops, childKeys => {} } ], $class;
    $$storageRef = $storage;
    return $storage;
}

sub STORE {
    my ( $data, $key, $value ) = @_;

    my $hash  = $$data[0];
    my $extra = $$data[1];
    my $loops = $$extra{loops};

    if ( $loops->in_child() ) {
        $$extra{childKeys}{$key} = $value;
    }

    # warn sprintf "Setting $key to $value";
    $$hash{$key} = $value;
}

sub getChildInfo {
    my ($self, $outputNr) = @_;
    my $extra = $$self[1];
    return $extra->{childKeys};
}

package Parallel::Loops::TiedArray;
use Tie::Array;
use base 'Tie::Array';

sub TIEARRAY {
    my ( $class, $loops, $storageRef ) = @_;
    my $storage = bless { arr => [], loops => $loops, childArr => [] }, $class;
    $$storageRef = $storage;
    return $storage;
}

sub FETCHSIZE { scalar @{ $_[0]->{arr} } }
sub STORESIZE { $#{ $_[0]->{arr} } = $_[1] - 1 }
sub STORE     { $_[0]->{arr}->[ $_[1] ] = $_[2] }
sub FETCH     { $_[0]->{arr}->[ $_[1] ] }
sub CLEAR     { @{ $_[0]->{arr} } = () }
sub POP       { pop( @{ $_[0]->{arr} } ) }
sub SHIFT     { shift( @{ $_[0]->{arr} } ) }
sub UNSHIFT   { my $o = shift; unshift( @{ $o->{arr} }, @_ ) }
sub EXISTS    { exists $_[0]->{arr}->[ $_[1] ] }
sub DELETE    { delete $_[0]->{arr}->[ $_[1] ] }

sub PUSH {
    my $self = shift;

    if ( $$self{loops}->in_child() ) {
        push( @{ $self->{childArr} }, @_ );
    }

    push( @{ $self->{arr} }, @_ );
}

sub getChildInfo {
    my ($self) = @_;
    return $self->{childArr};
}

1;
