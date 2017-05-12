# $Id: Iterator.pm 2746 2007-10-19 16:36:50Z andy $
package Parallel::Iterator;

use warnings;
use strict;
use Carp;
use Storable qw( store_fd fd_retrieve dclone );
use IO::Handle;
use IO::Select;
use Config;

require 5.008;

our $VERSION = '1.00';
use base qw( Exporter );
our @EXPORT_OK = qw( iterate iterate_as_array iterate_as_hash );

use constant IS_WIN32 => ( $^O =~ /^(MS)?Win32$/ );

my %DEFAULTS = (
    workers => ( ( $Config{d_fork} && !IS_WIN32 ) ? 10 : 0 ),
    onerror  => 'die',
    nowarn   => 0,
    batch    => 1,
    adaptive => 0,
);

=head1 NAME

Parallel::Iterator - Simple parallel execution

=head1 VERSION

This document describes Parallel::Iterator version 1.00

=head1 SYNOPSIS

    use Parallel::Iterator qw( iterate );

    # A very expensive way to double 100 numbers...
    
    my @nums = ( 1 .. 100 );
    
    my $iter = iterate( sub {
        my ( $id, $job ) = @_;
        return $job * 2;
    }, \@nums );
    
    my @out = ();
    while ( my ( $index, $value ) = $iter->() ) {
        $out[$index] = $value;
    }
  
=head1 DESCRIPTION

The C<map> function applies a user supplied transformation function to
each element in a list, returning a new list containing the
transformed elements.

This module provides a 'parallel map'. Multiple worker processes are
forked so that many instances of the transformation function may be
executed simultaneously. 

For time consuming operations, particularly operations that spend most
of their time waiting for I/O, this is a big performance win. It also
provides a simple idiom to make effective use of multi CPU systems.

There is, however, a considerable overhead associated with forking, so
the example in the synopsis (doubling a list of numbers) is I<not> a
sensible use of this module.

=head2 Example

Imagine you have an array of URLs to fetch:

    my @urls = qw(
        http://google.com/
        http://hexten.net/
        http://search.cpan.org/
        ... and lots more ...
    );

Write a function that retrieves a URL and returns its contents or undef
if it can't be fetched:

    sub fetch {
        my $url = shift;
        my $resp = $ua->get($url);
        return unless $resp->is_success;
        return $resp->content;
    };

Now write a function to synthesize a special kind of iterator:

    sub list_iter {
        my @ar = @_;
        my $pos = 0;
        return sub {
            return if $pos >= @ar;
            my @r = ( $pos, $ar[$pos] );  # Note: returns ( index, value )
            $pos++;
            return @r;
        };
    }

The returned iterator will return each element of the array in turn and
then undef. Actually it returns both the index I<and> the value of each
element in the array. Because multiple instances of the transformation
function execute in parallel the results won't necessarily come back in
order. The array index will later allow us to put completed items in the
correct place in an output array.

Get an iterator for the list of URLs:

    my $url_iter = list_iter( @urls );

Then wrap it in another iterator which will return the transformed results:

    my $page_iter = iterate( \&fetch, $url_iter );

Finally loop over the returned iterator storing results:

    my @out = ( );
    while ( my ( $index, $value ) = $page_iter->() ) {
        $out[$index] = $value;
    }

Behind the scenes your program forked into ten (by default) instances of
itself and executed the page requests in parallel.

=head2 Simpler interfaces

Having to construct an iterator is a pain so C<iterate> is smart enough
to do that for you. Instead of passing an iterator just pass a reference
to the array:

    my $page_iter = iterate( \&fetch, \@urls );

If you pass a hash reference the iterator you get back will return key,
value pairs:

    my $some_iter = iterate( \&fetch, \%some_hash );

If the returned iterator is inconvenient you can get back a hash or
array instead:

    my @done = iterate_as_array( \&fetch, @urls );

    my %done = iterate_as_hash( \&worker, %jobs );

=head2 How It Works

The current process is forked once for each worker. Each forked child is
connected to the parent by a pair of pipes. The child's STDIN, STDOUT
and STDERR are unaffected.

Input values are serialised (using Storable) and passed to the workers.
Completed work items are serialised and returned.

=head2 Caveats

Parallel::Iterator is designed to be simple to use - but the underlying
forking of the main process can cause mystifying problems unless you
have an understanding of what is going on behind the scenes.

=head3 Worker execution enviroment

All code apart from the worker subroutine executes in the parent process
as normal. The worker executes in a forked instance of the parent
process. That means that things like this won't work as expected:

    my %tally = ();
    my @r = iterate_as_array( sub {
        my ($id, $name) = @_;
        $tally{$name}++;       # might not do what you think it does
        return reverse $name;
    }, @names );

    # Now print out the tally...
    while ( my ( $name, $count ) = each %tally ) {
        printf("%5d : %s\n", $count, $name);
    }

Because the worker is a closure it can see the C<%tally> hash from its
enclosing scope; but because it's running in a forked clone of the parent
process it modifies its own copy of C<%tally> rather than the copy for
the parent process.

That means that after the job terminates the C<%tally> in the parent
process will be empty.

In general you should avoid side effects in your worker subroutines.

=head3 Serialization

Values are serialised using L<Storable> to pass to the worker subroutine
and results from the worker are again serialised before being passed
back. Be careful what your values refer to: everything has to be
serialised. If there's an indirect way to reach a large object graph
Storable will find it and performance will suffer.

To find out how large your serialised values are serialise one of them
and check its size:

    use Storable qw( freeze );
    my $serialized = freeze $some_obj;
    print length($serialized), " bytes\n";

In your tests you may wish to guard against the possibility of a change
to the structure of your values resulting in a sudden increase in
serialized size:

    ok length(freeze $some_obj) < 1000, "Object too bulky?";

See the documetation for L<Storable> for other caveats.

=head3 Performance

Process forking is expensive. Only use Parallel::Iterator in cases where:

=over

=item the worker waits for I/O

The case of fetching web pages is a good example of this. Fetching a
page with LWP::UserAgent may take as long as a few seconds but probably
consumes only a few milliseconds of processor time. Running many
requests in parallel is a huge win - but be kind to the server you're
talking to: don't launch a lot of parallel requests unless it's your
server or you know it can handle the load.

=item the worker is CPU intensive and you have multiple cores / CPUs

If the worker is doing an expensive calculation you can parallelise that
across multiple CPU cores. Benchmark first though. There's a
considerable overhead associated with Parallel::Iterator; unless your
calculations are time consuming that overhead will dwarf whatever time
they take.

=back

=head1 INTERFACE 

=head2 C<< iterate( [ $options ], $worker, $iterator ) >>

Get an iterator that applies the supplied transformation function to
each value returned by the input iterator.

Instead of an iterator you may pass an array or hash reference and
C<iterate> will convert it internally into a suitable iterator.

If you are doing this you may wish to investigate C<iterate_as_hash> and
C<iterate_as_array>.

=head3 Options

A reference to a hash of options may be supplied as the first argument.
The following options are supported:

=over

=item C<workers>

The number of concurrent processes to launch. Set this to 0 to disable
forking. Defaults to 10 on systems that support fork and 0 (disable
forking) on those that do not.

=item C<nowarn>

Normally C<iterate> will issue a warning and fall back to single process
mode on systems on which fork is not available. This option supresses
that warning.

=item C<batch>

Ordinarily items are passed to the worker one at a time. If you are
processing a large number of items it may be more efficient to process
them in batches. Specify the batch size using this option.

Batching is transparent from the caller's perspective. Internally it
modifies the iterators and worker (by wrapping them in additional
closures) so that they pack, process and unpack chunks of work.

=item C<adaptive>

Extending the idea of batching a number of work items to amortize the
overhead of passing work to and from parallel workers you may also ask
C<iterate> to heuristically determine the batch size by setting the
C<adaptive> option to a numeric value.

The batch size will be computed as

    <number of items seen> / <number of workers> / <adaptive>

A larger value for C<adaptive> will reduce the rate at which the batch
size increases. Good values tend to be in the range 1 to 2.

You can also specify lower and, optionally, upper bounds on the batch
size by passing an reference to an array containing ( lower bound,
growth ratio, upper bound ). The upper bound may be omitted.

    my $iter = iterate(
        { adaptive => [ 5, 2, 100 ] },
        $worker, \@stuff );

=item C<onerror>

The action to take when an error is thrown in the iterator. Possible
values are 'die', 'warn' or a reference to a subroutine that will be
called with the index of the job that threw the exception and the value
of C<$@> thrown.

    iterate( {
        onerror => sub {
            my ($id, $err) = @_;
            $self->log( "Error for index $id: $err" );
        },
        $worker,
        \@jobs
    );

The default is 'die'.
    
=back

=cut

sub _massage_iterator {
    my $iter = shift;
    if ( 'ARRAY' eq ref $iter ) {
        my @ar  = @$iter;
        my $pos = 0;
        return sub {
            return if $pos >= @ar;
            my @r = ( $pos, $ar[$pos] );
            $pos++;
            return @r;
        };
    }
    elsif ( 'HASH' eq ref $iter ) {
        my %h = %$iter;
        my @k = keys %h;
        return sub {
            return unless @k;
            my $k = shift @k;
            return ( $k, $h{$k} );
        };
    }
    elsif ( 'CODE' eq ref $iter ) {
        return $iter;
    }
    else {
        croak "Iterator must be a code, array or hash ref";
    }
}

sub _nonfork {
    my ( $options, $worker, $iter ) = @_;

    return sub {
        while ( 1 ) {
            if ( my @next = $iter->() ) {
                my ( $id, $work ) = @next;
                # dclone so that we have the same semantics as the
                # forked version.
                $work = dclone $work if defined $work && ref $work;
                my $result = eval { $worker->( $id, $work ) };
                if ( my $err = $@ ) {
                    $options->{onerror}->( $id, $err );
                }
                else {
                    return ( $id, $result );
                }
            }
            else {
                return;
            }
        }
    };
}

# Does this sub look a bit long to you? :)
sub _fork {
    my ( $options, $worker, $iter ) = @_;

    my @workers      = ();
    my @result_queue = ();
    my $select       = IO::Select->new;
    my $rotate       = 0;

    return sub {
        LOOP: {
            # Make new workers
            while ( @workers < $options->{workers} && ( my @next = $iter->() ) )
            {

                my ( $my_rdr, $my_wtr, $child_rdr, $child_wtr )
                  = map IO::Handle->new, 1 .. 4;

                pipe $child_rdr, $my_wtr
                  or croak "Can't open write pipe ($!)\n";

                pipe $my_rdr, $child_wtr
                  or croak "Can't open read pipe ($!)\n";

                if ( my $pid = fork ) {
                    # Parent
                    close $_ for $child_rdr, $child_wtr;
                    push @workers, $pid;
                    $select->add( [ $my_rdr, $my_wtr, 0 ] );
                    _put_obj( \@next, $my_wtr );
                }
                else {
                    # Child
                    close $_ for $my_rdr, $my_wtr;

                    # Don't execute any END blocks
                    use POSIX '_exit';
                    eval q{END { _exit 0 }};

                    # Worker loop
                    while ( defined( my $job = _get_obj( $child_rdr ) ) ) {
                        my $result = eval { $worker->( @$job ) };
                        my $err = $@;
                        _put_obj(
                            [
                                $err
                                ? ( 'E', $job->[0], $err )
                                : ( 'R', $job->[0], $result )
                            ],
                            $child_wtr
                        );
                    }

                    # End of stream
                    _put_obj( undef, $child_wtr );
                    close $_ for $child_rdr, $child_wtr;
                    # We use CORE::exit for MP compatibility
                    CORE::exit;
                }
            }

            return @{ shift @result_queue } if @result_queue;
            if ( $select->count ) {
                eval {
                    my @rdr = $select->can_read;
                    # Anybody got completed work?
                    for my $r ( @rdr ) {
                        my ( $rh, $wh, $eof ) = @$r;
                        if ( defined( my $results = _get_obj( $rh ) ) ) {
                            my $type = shift @$results;
                            if ( $type eq 'R' ) {
                                push @result_queue, $results;
                            }
                            elsif ( $type eq 'E' ) {
                                $options->{onerror}->( @$results );
                            }
                            else {
                                die "Bad result type: $type";
                            }

                            # We operate a strict one in, one out policy
                            # - which avoids deadlocks. Having received
                            # the previous result send a new work value.
                            unless ( $eof ) {
                                if ( my @next = $iter->() ) {
                                    _put_obj( \@next, $wh );
                                }
                                else {
                                    _put_obj( undef, $wh );
                                    close $wh;
                                    @{$r}[ 1, 2 ] = ( undef, 1 );
                                }
                            }
                        }
                        else {
                            $select->remove( $r );
                            close $rh;
                        }
                    }
                };

                if ( my $err = $@ ) {
                    # Finish all the workers
                    _put_obj( undef, $_->[1] ) for $select->handles;

                    # And wait for them to exit
                    waitpid( $_, 0 ) for @workers;

                    # Rethrow
                    die $err;
                }

                redo LOOP;
            }
            waitpid( $_, 0 ) for @workers;
            return;
        }
    };
}

sub _batch_input_iter {
    my ( $code, $options ) = @_;

    if ( my $adapt = $options->{adaptive} ) {
        my $workers = $options->{workers} || 1;
        my $count = 0;

        $adapt = [ 1, $adapt, undef ]
          unless 'ARRAY' eq ref $adapt;

        my ( $min, $ratio, $max ) = @$adapt;
        $min = 1 unless defined $min && $min > 1;

        return sub {
            my @chunk = ();

            # Adapt batch size
            my $batch = $count / $workers / $ratio;
            $batch = $min if $batch < $min;
            $batch = $max if defined $max && $batch > $max;

            while ( @chunk < $batch && ( my @next = $code->() ) ) {
                push @chunk, \@next;
                $count++;
            }

            return @chunk ? ( 0, \@chunk ) : ();
        };
    }
    else {
        my $batch = $options->{batch};

        return sub {
            my @chunk = ();
            while ( @chunk < $batch && ( my @next = $code->() ) ) {
                push @chunk, \@next;
            }
            return @chunk ? ( 0, \@chunk ) : ();
        };
    }
}

sub _batch_output_iter {
    my $code  = shift;
    my @queue = ();
    return sub {
        unless ( @queue ) {
            if ( my ( undef, $chunk ) = $code->() ) {
                @queue = @$chunk;
            }
            else {
                return;
            }
        }
        return @{ shift @queue };
    };
    return $code;
}

sub _batch_worker {
    my $code = shift;
    return sub {
        my ( undef, $chunk ) = @_;
        for my $item ( @$chunk ) {
            $item->[1] = $code->( @$item );
        }
        return $chunk;
    };
}

sub iterate {
    my %options = ( %DEFAULTS, %{ 'HASH' eq ref $_[0] ? shift : {} } );

    croak "iterate takes 2 or 3 args" unless @_ == 2;

    my @bad_opt = grep { !exists $DEFAULTS{$_} } keys %options;
    croak "Unknown option(s): ", join( ', ', sort @bad_opt ), "\n"
      if @bad_opt;

    my $worker = shift;
    croak "Worker must be a coderef"
      unless 'CODE' eq ref $worker;

    my $iter = _massage_iterator( shift );

    if ( $options{onerror} =~ /^(die|warn)$/ ) {
        $options{onerror} = eval "sub { shift; $1 shift }";
    }

    croak "onerror option must be 'die', 'warn' or a code reference"
      unless 'CODE' eq ref $options{onerror};

    if ( $options{workers} > 0 && $DEFAULTS{workers} == 0 ) {
        warn "Fork not available; falling back to single process mode\n"
          unless $options{nowarn};
        $options{workers} = 0;
    }

    my $factory = $options{workers} == 0 ? \&_nonfork : \&_fork;

    if ( $options{batch} > 1 || $options{adaptive} ) {
        return _batch_output_iter(
            $factory->(
                \%options,
                _batch_worker( $worker ),
                _batch_input_iter( $iter, \%options )
            )
        );
    }
    else {
        # OK. Ready. Let's do it.
        return $factory->( \%options, $worker, $iter );
    }
}

=head2 C<< iterate_as_array >>

As C<iterate> but instead of returning an iterator returns an array
containing the collected output from the iterator. In a scalar context
returns a reference to the same array.

For this to work properly the input iterator must return (index, value)
pairs. This allows the results to be placed in the correct slots in the
output array. The simplest way to do this is to pass an array reference
as the input iterator:

    my @output = iterate_as_array( \&some_handler, \@input );

=cut

sub iterate_as_array {
    my $iter = iterate( @_ );
    my @out  = ();
    while ( my ( $index, $value ) = $iter->() ) {
        $out[$index] = $value;
    }
    return wantarray ? @out : \@out;
}

=head2 C<< iterate_as_hash >>

As C<iterate> but instead of returning an iterator returns a hash
containing the collected output from the iterator. In a scalar context
returns a reference to the same hash.

For this to work properly the input iterator must return (key, value)
pairs. This allows the results to be placed in the correct slots in the
output hash. The simplest way to do this is to pass a hash reference as
the input iterator:

    my %output = iterate_as_hash( \&some_handler, \%input );

=cut

sub iterate_as_hash {
    my $iter = iterate( @_ );
    my %out  = ();
    while ( my ( $key, $value ) = $iter->() ) {
        $out{$key} = $value;
    }
    return wantarray ? %out : \%out;
}

sub _get_obj {
    my $fd = shift;
    my $r  = fd_retrieve $fd;
    return $r->[0];
}

sub _put_obj {
    my ( $obj, $fd ) = @_;
    store_fd [$obj], $fd;
    $fd->flush;
}

1;
__END__

=head1 CONFIGURATION AND ENVIRONMENT
  
Parallel::Iterator requires no configuration files or environment variables.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-parallel-iterator@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Andy Armstrong  C<< <andy@hexten.net> >>

=head1 THANKS

Aristotle Pagaltzis for the END handling suggestion and patch.

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Andy Armstrong C<< <andy@hexten.net> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
