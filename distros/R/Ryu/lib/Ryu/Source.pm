package Ryu::Source;

use strict;
use warnings;

use parent qw(Ryu::Node);

our $VERSION = '4.001'; # VERSION
our $AUTHORITY = 'cpan:TEAM'; # AUTHORITY

=head1 NAME

Ryu::Source - base representation for a source of events

=head1 SYNOPSIS

 my $src = Ryu::Source->new;
 my $chained = $src->map(sub { $_ * $_ })->prefix('value: ')->say;
 $src->emit($_) for 1..5;
 $src->finish;

=head1 DESCRIPTION

This is probably the module you'd want to start with, if you were going to be
using any of this. There's a disclaimer in L<Ryu> that may be relevant at this
point.

=head2 Quick start

You'd normally want to start by creating a L<Ryu::Source> instance:

 my $src = Ryu::Source->new;

If you're dealing with L<IO::Async> code, use L<Ryu::Async> to ensure that you
get properly awaitable L<Future> instances:

 $loop->add(my $ryu = Ryu::Async->new);
 my $src = $ryu->source;

Once you have a source, you'll need two things:

=over 4

=item * items to put into one end

=item * processing to attach to the other end

=back

For the first, call L</emit>:

 use Future::AsyncAwait;
 # 1s drifting periodic timer
 while(1) {
  await $loop->delay_future(after => 1);
  $src->emit('');
 }

For the second, this would be L</each>:

 $src->each(sub { print "Had timer tick\n" });

So far, not so useful - the power of this type of reactive programming is in the
ability to chain and combine disparate event sources.

At this point, L<https://rxmarbles.com> is worth a visit - this provides a clear
visual demonstration of how to combine multiple event streams using the chaining
methods. Most of the API here is modelled after similar principles.

First, the L</map> method: this provides a way to transform each item into
something else:

 $src->map(do { my $count = 0; sub { ++$count } })
     ->each(sub { print "Count is now $_\n" })

Next, L</filter> provides an equivalent to Perl's L<grep> functionality:

 $src->map(do { my $count = 0; sub { ++$count } })
     ->filter(sub { $_ % 2 })
     ->each(sub { print "Count is now at an odd number: $_\n" })

You can stack these:

 $src->map(do { my $count = 0; sub { ++$count } })
     ->filter(sub { $_ % 2 })
     ->filter(sub { $_ % 5 })
     ->each(sub { print "Count is now at an odd number which is not divisible by 5: $_\n" })

or:

 $src->map(do { my $count = 0; sub { ++$count } })
     ->map(sub { $_ % 3 ? 'fizz' : $_ })
     ->map(sub { $_ % 5 ? 'buzz' : $_ })
     ->each(sub { print "An imperfect attempt at the fizz-buzz game: $_\n" })

=cut

no indirect;
use sort qw(stable);

use Scalar::Util ();
use Ref::Util ();
use List::Util ();
use List::UtilsBy;
use Encode ();
use Syntax::Keyword::Try;
use Future;
use Future::Queue;
use curry::weak;

use Ryu::Buffer;

use Log::Any qw($log);

=head1 GLOBALS

=head2 $FUTURE_FACTORY

This is a coderef which should return a new L<Future>-compatible instance.

Example overrides might include:

 $Ryu::Source::FUTURE_FACTORY = sub { Mojo::Future->new->set_label($_[1]) };

=cut

our $FUTURE_FACTORY = sub {
    Future->new->set_label($_[1])
};

=head2 %ENCODER

An encoder is a coderef which takes input and returns output.

=cut

our %ENCODER = (
    utf8 => sub {
        sub {
            Encode::encode_utf8($_)
        }
    },
    json => sub {
        require JSON::MaybeXS;
        my $json = JSON::MaybeXS->new(@_);
        sub {
            $json->encode($_)
        }
    },
    csv => sub {
        require Text::CSV;
        my $csv = Text::CSV->new(@_);
        sub {
            die $csv->error_input unless $csv->combine(@$_);
            $csv->string
        }
    },
    base64 => sub {
        require MIME::Base64;
        sub {
            MIME::Base64::encode_base64($_, '');
        }
    },
);
# The naming of this one is a perennial source of confusion in Perl,
# let's just support both
$ENCODER{'UTF-8'} = $ENCODER{utf8};

our %DECODER = (
    utf8 => sub {
        my $data = '';
        sub {
            $data .= $_;
            Encode::decode_utf8($data, Encode::FB_QUIET)
        }
    },
    json => sub {
        require JSON::MaybeXS;
        my $json = JSON::MaybeXS->new(@_);
        sub {
            $json->decode($_)
        }
    },
    csv => sub {
        require Text::CSV;
        my $csv = Text::CSV->new(@_);
        sub {
            die $csv->error_input unless $csv->parse($_);
            [ $csv->fields ]
        }
    },
    base64 => sub {
        require MIME::Base64;
        sub {
            MIME::Base64::decode_base64($_);
        }
    },
);
$DECODER{'UTF-8'} = $DECODER{utf8};

=head1 METHODS

=head2 new

Takes named parameters, such as:

=over 4

=item * label - the label used in descriptions

=back

Note that this is rarely called directly, see L</from>, L</empty> and L</never> instead.

=cut

sub new {
    my ($self, %args) = @_;
    $args{label} //= 'unknown';
    $args{on_item} //= [];
    $args{on_batch} //= [];
    $self->SUPER::new(%args);
}

=head2 from

Creates a new source from things.

The precise details of what this method supports may be somewhat ill-defined at this point in time.
It is expected that the interface and internals of this method will vary greatly in versions to come.

At the moment, the following inputs are supported:

=over 4

=item * arrayref - when called as C<< ->from([1,2,3]) >> this will emit the values from the arrayref,
deferring until the source is started

=item * L<Future> - given a L<Future> instance, will emit the results when that L<Future> is marked as done

=item * file handle - if provided a filehandle, such as C<< ->from(\*STDIN) >>, this will read bytes and
emit those until EOF

=back

=cut

sub from {
    my $class = shift;
    my $src = (ref $class) ? $class : $class->new;
    if(my $from_class = Scalar::Util::blessed($_[0])) {
        if($from_class->isa('Future')) {
            $_[0]->on_ready(sub {
                my ($f) = @_;
                if($f->failure) {
                    $src->fail($f->from_future);
                } elsif(!$f->is_cancelled) {
                    $src->finish;
                } else {
                    $src->emit($f->get);
                    $src->finish;
                }
            })->retain;
            return $src;
        } else {
            die 'Unknown class ' . $from_class . ', cannot turn it into a source';
        }
    } elsif(my $ref = ref($_[0])) {
        if($ref eq 'ARRAY') {
            my $data = $_[0];
            $src->{on_get} = sub {
                while($data->@*) {
                    $src->emit(shift $data->@*);
                }
                $src->finish;
            };
            return $src;
        } elsif($ref eq 'GLOB') {
            if(my $fh = *{$_[0]}{IO}) {
                my $code = sub {
                    while(read $fh, my $buf, 4096) {
                        $src->emit($buf)
                    }
                    $src->finish
                };
                $src->{on_get} = $code;
                return $src;
            } else {
                die "have a GLOB with no IO entry, this is not supported"
            }
        }
        die "unsupported ref type $ref";
    } else {
        die "unknown item in ->from";
    }
}

=head2 empty

Creates an empty source, which finishes immediately.

=cut

sub empty {
    my ($class) = @_;

    $class->new(label => (caller 0)[3] =~ /::([^:]+)$/)->finish
}

=head2 never

An empty source that never finishes.

=cut

sub never {
    my ($class) = @_;

    $class->new(label => (caller 0)[3] =~ /::([^:]+)$/)
}

=head1 METHODS - Instance

=cut

=head2 encode

Passes each item through an encoder.

The first parameter is the encoder to use, the remainder are
used as options for the selected encoder.

Examples:

 $src->encode('json')
 $src->encode('utf8')
 $src->encode('base64')

=cut

sub encode {
    my ($self, $type) = splice @_, 0, 2;
    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    my $code = ($ENCODER{$type} || $self->can('encode_' . $type) or die "unsupported encoding $type")->(@_);
    $self->each_while_source(sub {
        $src->emit($code->($_))
    }, $src);
}

=head2 decode

Passes each item through a decoder.

The first parameter is the decoder to use, the remainder are
used as options for the selected decoder.

Examples:

 $src->decode('json')
 $src->decode('utf8')
 $src->decode('base64')

=cut

sub decode {
    my ($self, $type) = splice @_, 0, 2;
    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    my $code = ($DECODER{$type} || $self->can('decode_' . $type) or die "unsupported encoding $type")->(@_);
    $self->each_while_source(sub {
        $src->emit($code->($_))
    }, $src);
}

=head2 print

Shortcut for C<< ->each(sub { print }) >>, except this will
also save the initial state of C< $\ > and use that for each
call for consistency.

=cut

sub print {
    my ($self) = @_;
    my $delim = $\;
    $self->each(sub { local $\ = $delim; print });
}

=head2 say

Shortcut for C<< ->each(sub { print "$_\n" }) >>.

=cut

sub say {
    my ($self) = @_;
    $self->each(sub { local $\; print "$_\n" });
}

=head2 hexdump

Convert input bytes to a hexdump representation, for example:

 00000000 00 00 12 04 00 00 00 00 00 00 03 00 00 00 80 00 >................<
 00000010 04 00 01 00 00 00 05 00 ff ff ff 00 00 04 08 00 >................<
 00000020 00 00 00 00 7f ff 00 00                         >........<

One line is emitted for each 16 bytes.

Takes the following named parameters:

=over 4

=item * C<continuous> - accumulates data for a continuous stream, and
does not reset the offset counter. Note that this may cause the last
output to be delayed until the source completes.

=back

=cut

sub hexdump {
    my ($self, %args) = @_;

    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    my $offset = 0;
    my $in = '';
    $self->each_while_source(sub {
        my @out;
        if($args{continuous}) {
            $in .= $_;
            return if length($in) < 16;
        } else {
            $in = $_;
            $offset = 0;
        }
        while(length(my $bytes = substr $in, 0, List::Util::min(length($in), 16), '')) {
            my $encoded = join '', unpack 'H*' => $bytes;
            $encoded =~ s/[[:xdigit:]]{2}\K(?=[[:xdigit:]])/ /g;
            my $ascii = $bytes =~ s{[^[:print:]]}{.}gr;
            $src->emit(sprintf '%08x %-47.47s %-18.18s', $offset, $encoded, ">$ascii<");
            $offset += length($bytes);
            return if $args{continuous} and length($in) < 16;
        }
    }, $src);
}

=head2 throw

Throws something. I don't know what, maybe a chair.

=cut

sub throw {
    my $src = shift->new(@_);
    $src->fail('...');
}

=head2 debounce

Not yet implemented.

Requires timing support, see implementations such as L<Ryu::Async> instead.

=cut

sub debounce {
    my ($self, $interval) = @_;
    ...
}

=head2 chomp

Chomps all items with the given delimiter.

Once you've instantiated this, it will stick with the delimiter which was in force at the time of instantiation.
Said delimiter follows the usual rules of C<< $/ >>, whatever they happen to be.

Example:

 $ryu->stdin
     ->chomp("\n")
     ->say

=cut

sub chomp {
    my ($self, $delim) = @_;
    $delim //= $/;
    $self->map(sub {
        local $/ = $delim;
        chomp(my $line = $_);
        $line
    })
}

=head2 map

A bit like L<perlfunc/map>.

Takes a single parameter - the coderef to execute for each item. This should return
a scalar value which will be used as the next item.

Often useful in conjunction with a C<< do >> block to provide a closure.

Examples:

 $src->map(do {
   my $idx = 0;
   sub {
    [ @$_, ++$idx ]
   }
 })

=cut

sub map : method {
    my ($self, $code) = @_;

    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    $self->each_while_source(sub {
        $src->emit(Scalar::Util::blessed($_)
            ? (scalar $_->$code)
            : !ref($code)
            ? $_->{$code}
            : scalar $_->$code
        )
    }, $src);
}

=head2 flat_map

Similar to L</map>, but will flatten out some items:

=over 4

=item * an arrayref will be expanded out to emit the individual elements

=item * for a L<Ryu::Source>, passes on any emitted elements

=back

This also means you can "merge" items from a series of sources.

Note that this is not recursive - an arrayref of arrayrefs will be expanded out
into the child arrayrefs, but no further.

Failure on any input source will cause this source to be marked as failed as well.

=cut

sub flat_map {
    my ($self, $code) = splice @_, 0, 2;

    # Upgrade ->flat_map(method => args...) to a coderef
    if(!Ref::Util::is_plain_coderef($code)) {
        my $method = $code;
        my @args = @_;
        $code = sub { $_->$method(@args) }
    }

    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);

    Scalar::Util::weaken(my $weak_sauce = $src);
    my $add = sub {
        my $v = shift;
        my $src = $weak_sauce or return;

        my $k = "$v";
        $src->{waiting}{$k} = $v->on_ready(sub {
            my ($f) = @_;
            return unless my $src = $weak_sauce;

            # Any failed input source should propagate failure immediately
            if($f->is_failed) {
                # Clear out our waitlist, since we don't want to hold those references any more
                delete $src->{waiting};
                $src->fail($f->failure) unless $src->is_ready;
                return;
            }

            delete $src->{waiting}{$k};
            $src->finish unless %{$src->{waiting}};
        });
        $log->tracef("Added %s which will bring our count to %d", $k, 0 + keys %{$src->{waiting}});
    };

    $add->($self->_completed);
    $self->each_while_source(sub {
        my $src = $weak_sauce or return;
        for ($code->($_)) {
            my $item = $_;
            if(Ref::Util::is_plain_arrayref($item)) {
                $log->tracef("Have an arrayref of %d items", 0 + @$item);
                for(@$item) {
                    last if $src->is_ready;
                    $src->emit($_);
                }
            } elsif(Scalar::Util::blessed($item) && $item->isa(__PACKAGE__)) {
                $log->tracef("This item is a source");
                $src->on_ready(sub {
                    return if $item->is_ready;
                    $log->tracef("Marking %s as ready because %s was", $item->describe, $src->describe);
                    shift->on_ready($item->_completed);
                });
                $add->($item->_completed);
                $item->each_while_source(sub {
                    my $src = $weak_sauce or return;
                    $src->emit($_)
                }, $src)->on_ready(sub {
                    undef $item;
                });
            }
        }
    }, $src);
    $src
}

=head2 split

Splits the input on the given delimiter.

By default, will split into characters.

Note that each item will be processed separately - the buffer won't be
retained across items, see L</by_line> for that.

=cut

sub split : method {
    my ($self, $delim) = @_;
    $delim //= qr//;

    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    $self->each_while_source(sub { $src->emit($_) for split $delim, $_ }, $src);
}

=head2 chunksize

Splits input into fixed-size chunks.

Note that output is always guaranteed to be a full chunk - if there is partial input
at the time the input stream finishes, those extra bytes will be discarded.

=cut

sub chunksize : method {
    my ($self, $size) = @_;
    die 'need positive chunk size parameter' unless $size && $size > 0;

    my $buffer = '';
    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    $self->each_while_source(sub {
        $buffer .= $_;
        $src->emit(substr $buffer, 0, $size, '') while length($buffer) >= $size;
    }, $src);
}

=head2 batch

Splits input into arrayref batches of a given size.

Note that the last item emitted may have fewer elements (or none at all).

 $src->batch(10)
  ->map(sub { "Next 10 (or fewer) items: @$_" })
  ->say;

=cut

sub batch : method {
    my ($self, $size) = @_;
    die 'need positive batch parameter' unless $size && $size > 0;

    my $buffer = '';
    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    my @batch;
    $self->each_while_source(sub {
        push @batch, $_;
        while(@batch >= $size and my (@items) = splice @batch, 0, $size) {
            $src->emit(\@items)
        }
    }, $src, cleanup => sub {
        $src->emit([ splice @batch ]) if @batch;
    });
}

=head2 by_line

Emits one item for each line in the input. Similar to L</split> with a C<< \n >> parameter,
except this will accumulate the buffer over successive items and only emit when a complete
line has been extracted.

=cut

sub by_line : method {
    my ($self, $delim) = @_;
    $delim //= $/;

    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    my $buffer = '';
    $self->each_while_source(sub {
        $buffer .= $_;
        while($buffer =~ s/^(.*)\Q$delim//) {
            $src->emit($1)
        }
    }, $src);
}

=head2 prefix

Applies a string prefix to each item.

=cut

sub prefix {
    my ($self, $txt) = @_;
    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    $self->each_while_source(sub {
        $src->emit($txt . $_)
    }, $src);
}

=head2 suffix

Applies a string suffix to each item.

=cut

sub suffix {
    my ($self, $txt) = @_;
    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    $self->each_while_source(sub {
        $src->emit($_ . $txt)
    }, $src);
}

=head2 sprintf_methods

Convenience method for generating a string from a L</sprintf>-style format
string and a set of method names to call.

Note that any C<undef> items will be mapped to an empty string.

Example:

 $src->sprintf_methods('%d has name %s', qw(id name))
     ->say
     ->await;

=cut

sub sprintf_methods {
    my ($self, $fmt, @methods) = @_;
    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    $self->each_while_source(sub {
        my ($item) = @_;
        $src->emit(sprintf $fmt, map $item->$_ // '', @methods)
    }, $src);
}

=head2 ignore

Receives items, but ignores them entirely.

Emits nothing and eventually completes when the upstream L<Ryu::Source> is done.

Might be useful for keeping a source alive.

=cut

sub ignore {
    my ($self) = @_;
    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    $self->_completed->on_ready(sub {
        shift->on_ready($src->_completed) unless $src->_completed->is_ready
    });
    return $src;
}

=head2 buffer

Accumulate items while any downstream sources are paused.

Takes the following named parameters:

=over 4

=item * C<high> - once at least this many items are buffered, will L</pause>
the upstream L<Ryu::Source>.

=item * C<low> - if the buffered count drops to this number, will L</resume>
the upstream L<Ryu::Source>.

=back

=cut

sub buffer {
    my $self = shift;
    my %args;
    %args = @_ != 1
    ? @_
    : (
        low  => $_[0],
        high => $_[0],
    );
    $args{low} //= $args{high};
    $args{low} //= 10;
    $args{high} //= $args{low};

    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    $src->{pause_propagation} = 0;
    my @pending;
    $self->_completed->on_ready(sub {
        shift->on_ready($src->_completed) unless $src->_completed->is_ready or @pending;
    });
    my $fc = $src->flow_control;
    my $item_handler = do {
        Scalar::Util::weaken(my $weak_self = $self);
        Scalar::Util::weaken(my $weak_src = $src);
        sub {
            my $self = $weak_self;
            my $src = $weak_src or return;
            if(@pending >= $args{high} and $self and not $self->is_paused($src)) {
                $self->pause($src);
            }
            $src->emit(shift @pending)
                while @pending
                and not($src->is_paused)
                and @{$self->{children}};
            $self->resume($src) if @pending <= $args{low} and $self->is_paused($src);

            return if @pending;

            # It's common to have a situation where the parent chain completes while we're
            # paused waiting for the queue to drain. In this situation, we want to propagate
            # completion only once the queue is empty.
            $self->_completed->on_ready($src->_completed)
                if $self->_completed->is_ready and not $src->_completed->is_ready;
        }
    };
    $src->_completed->on_ready(sub {
        $self->resume($src) if $self and $self->is_paused($src);
    });
    $fc->each($item_handler)->retain;
    $self->each(my $code = sub {
        push @pending, $_;
        $item_handler->()
    });
    $self->_completed->on_ready(sub {
        my ($f) = @_;
        return if @pending;
        my $addr = Scalar::Util::refaddr($code);
        my $count = List::UtilsBy::extract_by { $addr == Scalar::Util::refaddr($_) } @{$self->{on_item}};
        $f->on_ready($src->_completed) unless $src->is_ready;
        $log->tracef("->buffer completed on %s for refaddr 0x%x, removed %d on_item handlers", $self->describe, Scalar::Util::refaddr($self), $count);
    });
    $src;
}

sub remove_handler {
    my ($self, $code) = @_;
    my $addr = Scalar::Util::refaddr($code);
    my $count = List::UtilsBy::extract_by {
        $addr == Scalar::Util::refaddr($_)
    } @{$self->{on_item}};
    $log->tracef(
        "Removing handler on %s with refaddr 0x%x, matched %d total",
        $self->describe,
        Scalar::Util::refaddr($self),
        $count
    );
    return $self;
}

sub retain {
    my ($self) = @_;
    $self->{_self} = $self;
    $self->_completed
        ->on_ready(sub { delete $self->{_self} });
    $self
}

=head2 as_list

Resolves to a list consisting of all items emitted by this source.

=cut

sub as_list {
    my ($self) = @_;
    my @data;
    $self->each(sub {
        push @data, $_
    });
    $self->_completed->transform(done => sub { @data })
}

=head2 as_arrayref

Resolves to a single arrayref consisting of all items emitted by this source.

=cut

sub as_arrayref {
    my ($self) = @_;
    my @data;
    $self->each(sub {
        push @data, $_
    });
    $self->_completed->transform(done => sub { \@data })
}

=head2 as_string

Concatenates all items into a single string.

Returns a L<Future> which will resolve on completion.

=cut

sub as_string {
    my ($self) = @_;
    my $data = '';
    $self->each(sub {
        $data .= $_;
    });
    $self->_completed->transform(done => sub { $data })
}

=head2 as_queue

Returns a L<Future::Queue> instance which will
L<Future::Queue/push> items whenever the source
emits them.

The queue will be marked as finished when this source is completed.

Parameters passed to this method will be given to the L<Future::Queue>
constructor:

 use Future::AsyncAwait qw(:experimental(suspend));
 my $queue = $src->as_queue(
  max_items => 100
 );
 SUSPEND { print "Waiting for more items\n" }
 while(my @batch = await $queue->shift_atmost(10)) {
  print "Had batch of @{[ 0 + @batch ]} items\n";
 }

=cut

sub as_queue {
    my ($self, %args) = @_;
    my $queue = Future::Queue->new(
        prototype => $self->curry::weak::new_future,
        %args
    );

    if($args{max_items}) {
        my $f;
        $self->each($self->$curry::weak(sub {
            my ($self) = @_;
            unless(
                (my $f = $queue->push($_))->is_ready
                    and not $self->is_paused
            ) {
                $f->on_ready(sub { $self->resume });
                $self->pause;
            }
            return;
        }));
    } else {
        # Avoid the extra overhead when we know there isn't going to be any
        # upper limit on accepted items.
        $self->each(sub {
            $queue->push($_);
            return;
        });
    }
    $self->completed->on_ready(sub { $queue->finish });
    return $queue;
}

=head2 as_buffer

Returns a L<Ryu::Buffer> instance, which will
L<Ryu::Buffer/write> any emitted items from this
source to the buffer as they arrive.

Intended for stream protocol handling - individual
sized packets are perhaps better suited to the
L<Ryu::Source> per-item behaviour.

Supports the following named parameters:

=over 4

=item * C<low> - low waterlevel for buffer, start accepting more bytes
once the L<Ryu::Buffer> has less content than this

=item * C<high> - high waterlevel for buffer, will pause the parent stream
if this is reached

=back

The backpressure (low/high) values default to undefined, meaning
no backpressure is applied: the buffer will continue to fill
indefinitely.

=cut

sub as_buffer {
    my ($self, %args) = @_;
    my $low = delete $args{low};
    my $high = delete $args{high};
    # We're creating a source but keeping it to ourselves here
    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);

    my $buffer = Ryu::Buffer->new(
        new_future => $self->{new_future},
        %args,
        on_change => sub {
            my ($self) = @_;
            $src->resume if $low and $self->size <= $low;
        }
    );

    Scalar::Util::weaken(my $weak_sauce = $src);
    Scalar::Util::weaken(my $weak_buffer = $buffer);
    $self->each_while_source(sub {
        my $src = $weak_sauce or return;
        my $buf = $weak_buffer or do {
            $src->finish;
            return;
        };
        $buf->write($_);
        $src->pause if $high and $buf->size >= $high;
        $src->resume if $low and $buf->size <= $low;
    }, $src);
    return $buffer;
}

=head2 as_last

Returns a L<Future> which resolves to the last value received.

=cut

sub as_last {
    my ($self) = @_;
    my $v;
    $self->each(sub {
        $v = $_;
    });
    $self->_completed->transform(done => sub { $v })
}

=head2 as_void

Returns a L<Future> which resolves to an empty list.

=cut

sub as_void {
    my ($self) = @_;
    $self->_completed->transform(done => sub { () })
}

=head2 combine_latest

Takes the most recent item from one or more L<Ryu::Source>s, and emits
an arrayref containing the values in order.

An item is emitted for each update as soon as all sources have provided
at least one value. For example, given 2 sources, if the first emits C<1>
then C<2>, then the second emits C<a>, this would emit a single C<< [2, 'a'] >>
item.

=cut

sub combine_latest : method {
    my ($self, @sources) = @_;
    push @sources, sub { @_ } if Scalar::Util::blessed $sources[-1];
    my $code = pop @sources;

    my $combined = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    unshift @sources, $self if ref $self;
    my @value;
    my %seen;
    for my $idx (0..$#sources) {
        my $src = $sources[$idx];
        $src->each_while_source(sub {
            $value[$idx] = $_;
            $seen{$idx} ||= 1;
            $combined->emit([ $code->(@value) ]) if @sources == keys %seen;
        }, $combined);
    }
    Future->needs_any(
        map $_->completed, @sources
    )->on_ready(sub {
        @value = ();
        return if $combined->_completed->is_ready;
        shift->on_ready($combined->_completed)
    })->retain;
    $combined
}

=head2 with_index

Emits arrayrefs consisting of C<< [ $item, $idx ] >>.

=cut

sub with_index {
    my ($self) = @_;
    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    my $idx = 0;
    $self->each_while_source(sub {
        $src->emit([ $_, $idx++ ])
    }, $src);
}

=head2 with_latest_from

Similar to L</combine_latest>, but will start emitting as soon as
we have any values. The arrayref will contain C<< undef >> for any
sources which have not yet emitted any items.

=cut

sub with_latest_from : method {
    my ($self, @sources) = @_;
    push @sources, sub { @_ } if Scalar::Util::blessed $sources[-1];
    my $code = pop @sources;

    my $combined = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    my @value;
    my %seen;
    for my $idx (0..$#sources) {
        my $src = $sources[$idx];
        $src->each(sub {
            return if $combined->_completed->is_ready;
            $value[$idx] = $_;
            $seen{$idx} ||= 1;
        });
    }
    $self->each(sub {
        $combined->emit([ $code->(@value) ]) if keys %seen;
    });
    $self->_completed->on_ready($combined->_completed);
    $self->_completed->on_ready(sub {
        @value = ();
        return if $combined->is_ready;
        shift->on_ready($combined->_completed);
    });
    $combined
}

=head2 merge

Emits items as they are generated by the given sources.

Example:

 $numbers->merge($letters)->say # 1, 'a', 2, 'b', 3, 'c'...

=cut

sub merge : method {
    my ($self, @sources) = @_;

    my $combined = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    unshift @sources, $self if ref $self;
    for my $src (@sources) {
        $src->each(sub {
            return if $combined->_completed->is_ready;
            $combined->emit($_)
        });
    }
    Future->needs_all(
        map $_->completed, @sources
    )->on_ready($combined->_completed)
     ->on_ready(sub { @sources = () })
     ->retain;
    $combined
}

=head2 emit_from

Emits items as they are generated by the given sources.

Example:

 my $src = Ryu::Source->new;
 $src->say;
 $src->emit_from(
  $numbers,
  $letters
 );

=cut

sub emit_from : method {
    my ($self, @sources) = @_;

    for my $src (@sources) {
        $src->each_while_source(sub {
            return if $self->_completed->is_ready;
            $self->emit($_)
        }, $self);
    }
    $self
}

=head2 apply

Used for setting up multiple streams.

Accepts a variable number of coderefs, will call each one and gather L<Ryu::Source>
results.

=cut

sub apply : method {
    my ($self, @code) = @_;

    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    my @pending;
    for my $code (@code) {
        push @pending, map $code->($_), $self;
    }
    Future->needs_all(
        map $_->completed, @pending
    )->on_ready($src->_completed)
     ->retain;
    # Pass through the original events
    $self->each_while_source(sub {
        $src->emit($_)
    }, $src)
}

=head2 switch_str

Given a condition, will select one of the alternatives based on stringified result.

Example:

 $src->switch_str(
  sub { $_->name }, # our condition
  smith => sub { $_->id }, # if this matches the condition, the code will be called with $_ set to the current item
  jones => sub { $_->parent->id },
  sub { undef } # and this is our default case
 );

=cut

sub switch_str {
    my ($self, $condition, @args) = @_;

    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    my @active;
    $self->_completed->on_ready(sub {
        Future->needs_all(
            grep $_, @active
        )->on_ready(sub {
            $src->finish
        })->retain
    });

    $self->each_while_source(sub {
        my ($item) = $_;
        my $rslt = $condition->($item);
        (Scalar::Util::blessed($rslt) && $rslt->isa('Future') ? $rslt : Future->done($rslt))->on_done(sub {
            my ($data) = @_;
            my @copy = @args;
            while(my ($k, $v) = splice @copy, 0, 2) {
                if(!defined $v) {
                    # Only a single value (or undef)? That's our default, just use it as-is
                    return $src->emit(map $k->($_), $item)
                } elsif($k eq $data) {
                    # Key matches our result? Call code with the original item
                    return $src->emit(map $v->($_), $item)
                }
            }
        })->retain
    }, $src)
}

=head2 ordered_futures

Given a stream of L<Future>s, will emit the results as each L<Future>
is marked ready.

If any L<Future> in the stream fails, that will mark this source as failed,
and all remaining L<Future> instances will be cancelled. To avoid this behaviour
and leave the L<Future> instances active, use:

 $src->map('without_cancel')
     ->ordered_futures

See L<Future/without_cancel> for more details.

Takes the following named parameters:

=over 4

=item * C<high> - once at least this many unresolved L<Future> instances are pending,
will L</pause> the upstream L<Ryu::Source>.

=item * C<low> - if the pending count drops to this number, will L</resume>
the upstream L<Ryu::Source>.

=back

This method is also available as L</resolve>.

=cut

sub ordered_futures {
    my ($self, %args) = @_;
    my $high = delete $args{high};
    my $low = (delete $args{low}) // $high // 0;
    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    my %pending;
    my $src_completed = $src->_completed;

    my $all_finished;
    $self->_completed->on_ready(sub {
        $all_finished = shift;
        $all_finished->on_ready($src_completed) unless %pending or $src_completed->is_ready;
    });

    $src_completed->on_ready(sub {
        my @pending = values %pending;
        %pending = ();
        for(@pending) {
            $_->cancel if $_ and not $_->is_ready;
        }
    });
    my $paused = 0;
    $self->each(sub {
        my $f = $_;
        my $k = Scalar::Util::refaddr $f;
        # This will keep a copy of the Future around until the
        # ->is_ready callback removes it
        $pending{$k} = $f;
        $log->tracef('Ordered futures has %d pending', 0 + keys %pending);
        if(!$paused and $high and keys(%pending) >= $high) {
            $src->pause;
            ++$paused;
        }
        $f->on_done(sub {
            my @pending = @_;
            while(@pending and not $src_completed->is_ready) {
                $src->emit(shift @pending);
            }
        })
          ->on_fail(sub { $src->fail(@_) unless $src_completed->is_ready; })
          ->on_ready(sub {
              delete $pending{$k};
              if($paused and keys(%pending) <= $low) {
                  $src->resume;
                  --$paused;
              }
              $log->tracef('Ordered futures now has %d pending after completion, upstream finish status is %d', 0 + keys(%pending), $all_finished);
              return if %pending;
              $all_finished->on_ready($src_completed) if $all_finished and not $src_completed->is_ready;
          })
    });
    return $src;
}

=head2 resolve

A synonym for L</ordered_futures>.

=cut

*resolve = *ordered_futures;

=head2 concurrent

=cut

sub concurrent {
    my ($self) = @_;
    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    $self->each_while_source(sub {
        $_->on_done($src->curry::weak::emit)
          ->on_fail($src->curry::weak::fail)
          ->retain
    }, $src);
}

=head2 distinct

Emits new distinct items, using string equality with an exception for
C<undef> (i.e. C<undef> is treated differently from empty string or 0).

Given 1,2,3,undef,2,3,undef,'2',2,4,1,5, you'd expect to get the sequence 1,2,3,undef,4,5.

=cut

sub distinct {
    my $self = shift;

    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    my %seen;
    my $undef;
    $self->each_while_source(sub {
        if(defined) {
            $src->emit($_) unless $seen{$_}++;
        } else {
            $src->emit($_) unless $undef++;
        }
    }, $src);
}

=head2 distinct_until_changed

Removes contiguous duplicates, defined by string equality.

=cut

sub distinct_until_changed {
    my $self = shift;

    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    my $active;
    my $prev;
    $self->each_while_source(sub {
        if($active) {
            if(defined($prev) ^ defined($_)) {
                $src->emit($_)
            } elsif(defined($_)) {
                $src->emit($_) if $prev ne $_;
            }
        } else {
            $active = 1;
            $src->emit($_);
        }
        $prev = $_;
    }, $src);
    $src
}

=head2 sort_by

Emits items sorted by the given key. This is a stable sort function.

The algorithm is taken from L<List::UtilsBy>.

=cut

sub sort_by {
    use sort qw(stable);
    my ($self, $code) = @_;
    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    my @items;
    my @keys;
    $self->_completed->on_done(sub {
    })->on_ready(sub {
        return if $src->is_ready;
        shift->on_ready($src->_completed);
    });
    $self->each_while_source(sub {
        push @items, $_;
        push @keys, $_->$code;
    }, $src, cleanup => sub {
        my ($f) = @_;
        return unless $f->is_done;
        $src->emit($_) for @items[sort { $keys[$a] cmp $keys[$b] } 0 .. $#items];
    });
}

=head2 nsort_by

Emits items numerically sorted by the given key. This is a stable sort function.

See L</sort_by>.

=cut

sub nsort_by {
    use sort qw(stable);
    my ($self, $code) = @_;
    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    my @items;
    my @keys;
    $self->each_while_source(sub {
        push @items, $_;
        push @keys, $_->$code;
    }, $src, cleanup => sub {
        return unless shift->is_done;
        $src->emit($_) for @items[sort { $keys[$a] <=> $keys[$b] } 0 .. $#items];
    });
}

=head2 rev_sort_by

Emits items sorted by the given key. This is a stable sort function.

The algorithm is taken from L<List::UtilsBy>.

=cut

sub rev_sort_by {
    use sort qw(stable);
    my ($self, $code) = @_;
    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    my @items;
    my @keys;
    $self->each_while_source(sub {
        push @items, $_;
        push @keys, $_->$code;
    }, $src, cleanup => sub {
        return unless shift->is_done;
        $src->emit($_) for @items[sort { $keys[$b] cmp $keys[$a] } 0 .. $#items];
    });
}

=head2 rev_nsort_by

Emits items numerically sorted by the given key. This is a stable sort function.

See L</sort_by>.

=cut

sub rev_nsort_by {
    my ($self, $code) = @_;
    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    my @items;
    my @keys;
    $self->each_while_source(sub {
        push @items, $_;
        push @keys, $_->$code;
    }, $src, cleanup => sub {
        return unless shift->is_done;
        $src->emit($_) for @items[sort { $keys[$b] <=> $keys[$a] } 0 .. $#items];
    });
}

=head2 extract_all

Expects a regular expression and emits hashrefs containing
the named capture buffers.

The regular expression will be applied using the m//gc operator.

Example:

 $src->extract_all(qr{/(?<component>[^/]+)})
 # emits { component => '...' }, { component => '...' }

=cut

sub extract_all {
    my ($self, $pattern) = @_;
    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    $self->each_while_source(sub {
        $src->emit(+{ %+ }) while m/$pattern/gc;
    }, $src);
}

=head2 skip

Skips the first N items.

=cut

sub skip {
    my ($self, $count) = @_;
    $count //= 0;

    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    $self->_completed->on_ready(sub {
        return if $src->is_ready;
        shift->on_ready($src->_completed);
    });
    $self->each(sub {
        $src->emit($_) unless $count-- > 0;
    });
    $src
}

=head2 skip_last

Skips the last N items.

=cut

sub skip_last {
    my ($self, $count) = @_;
    $count //= 0;

    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    $self->_completed->on_ready(sub {
        return if $src->is_ready;
        shift->on_ready($src->_completed);
    });
    my @pending;
    $self->each(sub {
        push @pending, $_;
        $src->emit(shift @pending) if @pending > $count;
    });
    $src
}

=head2 skip_until

Skips the items that arrive before a given condition is reached.

=over 4

=item * Either a L<Future> instance (we skip all items until it's marked as `done`), or a coderef,
which we call for each item until it first returns true

=back

=cut

sub skip_until {
    my ($self, $condition) = @_;

    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    $self->each_while_source(do {
        if(ref($condition) eq 'CODE') {
            my $reached = 0;
            sub { return $src->emit($_) if $reached ||= $condition->($_); }
        } elsif(Scalar::Util::blessed($condition) && $condition->isa('Future')) {
            $condition->on_ready($src->$curry::weak(sub {
                my ($src, $cond) = @_;
                return if $src->is_ready;
                $src->fail($cond->failure) if $cond->is_failed;
                $src->cancel if $cond->is_cancelled
            }));
            sub { $src->emit($_) if $condition->is_done; }
        } else {
            die 'unknown type for condition: ' . $condition;
        }
    }, $src);
}

=head2 take_until

Passes through items that arrive until a given condition is reached.

Expects a single parameter, which can be one of the following:

=over 4

=item * a L<Future> instance - we will skip all items until it's marked as C<done>

=item * a coderef, which we call for each item until it first returns true

=item * or a L<Ryu::Source>, in which case we stop when that first emits a value

=back

=cut

sub take_until {
    my ($self, $condition) = @_;

    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    if(Scalar::Util::blessed($condition) && $condition->isa('Ryu::Source')) {
        $condition->_completed->on_ready(sub {
            $log->warnf('Condition completed: %s and %s', $condition->describe, $src->describe);
            return if $src->is_ready;
            $log->warnf('Mark as ready');
            shift->on_ready($src->_completed);
        });
        $condition->first->each(sub {
            $src->finish unless $src->is_ready
        });
        return $self->each_while_source($src->curry::emit, $src);
    } else {
        return $self->each_while_source(do {
            if(ref($condition) eq 'CODE') {
                my $reached = 0;
                sub { return $src->emit($_) unless $reached ||= $condition->($_); }
            } elsif(Scalar::Util::blessed($condition) && $condition->isa('Future')) {
                $condition->on_ready($src->$curry::weak(sub {
                    my ($src, $cond) = @_;
                    return if $src->is_ready;
                    $src->fail($cond->failure) if $cond->is_failed;
                    $src->cancel if $cond->is_cancelled
                }));
                sub { $src->emit($_) unless $condition->is_done; }
            } else {
                die 'unknown type for condition: ' . $condition;
            }
        }, $src);
    }
}

=head2 take

Takes a limited number of items.

Given a sequence of C< 1,2,3,4,5 > and C<< ->take(3) >>, you'd get 1,2,3 and then the stream
would finish.

=cut

sub take {
    my ($self, $count) = @_;
    $count //= 0;
    return $self->empty unless $count > 0;

    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    $self->each_while_source(sub {
        $log->tracef("Still alive with %d remaining", $count);
        $src->emit($_);
        return if --$count;
        $log->tracef("Count is zero, finishing");
        $src->finish
    }, $src);
}

=head2 first

Returns a source which provides the first item from the stream.

=cut

sub first {
    my ($self) = @_;

    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    $self->each_while_source(sub {
        $src->emit($_);
        $src->finish
    }, $src);
}

=head2 some

Applies the given code to each item, and emits a single item:

=over 4

=item * 0 if the code never returned true or no items were received

=item * 1 if the code ever returned a true value

=back

=cut

sub some {
    my ($self, $code) = @_;

    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    $self->_completed->on_ready(sub {
        my $sf = $src->_completed;
        return if $sf->is_ready;
        my $f = shift;
        return $f->on_ready($sf) unless $f->is_done;
        $src->emit(0);
        $sf->done;
    });
    $self->each(sub {
        return if $src->_completed->is_ready;
        return unless $code->($_);
        $src->emit(1);
        $src->_completed->done
    });
    $src
}

=head2 every

Similar to L</some>, except this requires the coderef to return true for
all values in order to emit a C<1> value.

=cut

sub every {
    my ($self, $code) = @_;

    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    $self->_completed->on_done(sub {
        return if $src->_completed->is_ready;
        $src->emit(1);
        $src->_completed->done
    });
    $self->each(sub {
        return if $src->_completed->is_ready;
        return if $code->($_);
        $src->emit(0);
        $src->_completed->done
    });
    $src
}

=head2 count

Emits the count of items seen once the parent source completes.

=cut

sub count {
    my ($self) = @_;

    my $count = 0;

    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    $self->each_while_source(sub { ++$count }, $src, cleanup => sub {
        return unless shift->is_done;
        $src->emit($count)
    });
}

=head2 sum

Emits the numeric sum of items seen once the parent completes.

=cut

sub sum {
    my ($self) = @_;

    my $sum = 0;

    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    $self->each_while_source(sub {
        $sum += $_
    }, $src, cleanup => sub {
        return unless shift->is_done;
        $src->emit($sum)
    });
}

=head2 mean

Emits the mean (average) numerical value of all seen items.

=cut

sub mean {
    my ($self) = @_;

    my $sum = 0;
    my $count = 0;

    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    $self->each(sub { ++$count; $sum += $_ });
    $self->_completed->on_done(sub { $src->emit($sum / ($count || 1)) })
        ->on_ready($src->_completed);
    $src
}

=head2 max

Emits the maximum numerical value of all seen items.

=cut

sub max {
    my ($self) = @_;

    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    my $max;
    $self->each(sub {
        return if defined $max and $max > $_;
        $max = $_;
    });
    $self->_completed->on_done(sub { $src->emit($max) })
        ->on_ready($src->_completed);
    $src
}

=head2 min

Emits the minimum numerical value of all seen items.

=cut

sub min {
    my ($self) = @_;

    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    my $min;
    $self->each(sub {
        return if defined $min and $min < $_;
        $min = $_;
    });
    $self->_completed->on_done(sub { $src->emit($min) })
        ->on_ready($src->_completed);
    $src
}

=head2 statistics

Emits a single hashref of statistics once the source completes.

This will contain the following keys:

=over 4

=item * count

=item * sum

=item * min

=item * max

=item * mean

=back

=cut

sub statistics {
    my ($self) = @_;

    my $sum = 0;
    my $count = 0;
    my $min;
    my $max;

    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    $self->each(sub {
        $min //= $_;
        $max //= $_;
        $min = $_ if $_ < $min;
        $max = $_ if $_ > $max;
        ++$count;
        $sum += $_
    });
    $self->_completed->on_done(sub {
        $src->emit({
            count => $count,
            sum   => $sum,
            min   => $min,
            max   => $max,
            mean  => ($sum / ($count || 1))
        })
    })
        ->on_ready($src->_completed);
    $src
}

=head2 filter

Applies the given parameter to filter values.

The parameter can be a regex or coderef. You can also
pass (key, value) pairs to filter hashrefs or objects
based on regex or coderef values.

Examples:

 $src->filter(name => qr/^[A-Z]/, id => sub { $_ % 2 })

=cut

sub filter {
    my $self = shift;

    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    $self->each_while_source((@_ > 1) ? do {
        my %args = @_;
        my $check = sub {
            my ($k, $v) = @_;
            if(my $ref = ref $args{$k}) {
                if($ref eq 'Regexp') {
                    return 0 unless defined($v) && $v =~ $args{$k};
                } elsif($ref eq 'ARRAY') {
                    return 0 unless defined($v) && List::Util::any { $v eq $_ } @{$args{$k}};
                } elsif($ref eq 'CODE') {
                    return 0 for grep !$args{$k}->($_), $v;
                } else {
                    die "Unsure what to do with $args{$k} which seems to be a $ref";
                }
            } else {
                return !defined($args{$k}) if !defined($v);
                return defined($args{$k}) && $v eq $args{$k};
            }
            return 1;
        };
        sub {
            my $item = shift;
            if(Scalar::Util::blessed $item) {
                for my $k (keys %args) {
                    my $v = $item->$k;
                    return unless $check->($k, $v);
                }
            } elsif(my $ref = ref $item) {
                if($ref eq 'HASH') {
                    for my $k (keys %args) {
                        my $v = $item->{$k};
                        return unless $check->($k, $v);
                    }
                } else {
                    die 'not a ref we know how to handle: ' . $ref;
                }
            } else {
                die 'not a ref, not sure what to do now';
            }
            $src->emit($item);
        }
    } : do {
        my $code = shift;
        if(my $ref = ref($code)) {
            if($ref eq 'Regexp') {
                my $re = $code;
                $code = sub { /$re/ };
            } elsif($ref eq 'CODE') {
                # use as-is
            } else {
                die "not sure how to handle $ref";
            }
        }
        sub {
            my $item = shift;
            $src->emit($item) if $code->($item);
        }
    }, $src);
}

=head2 filter_isa

Emits only the items which C<< ->isa >> one of the given parameters.
Will skip non-blessed items.

=cut

sub filter_isa {
    my ($self, @isa) = @_;

    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    $self->each_while_source(sub {
        my ($item) = @_;
        return unless Scalar::Util::blessed $item;
        $src->emit($_) if grep $item->isa($_), @isa;
    }, $src);
}

=head2 emit

Emits the given item.

=cut

sub emit {
    my $self = shift;
    my $completion = $self->_completed;
    my @handlers = $self->{on_item}->@*
        or return $self;
    for (@_) {
        die 'already completed' if $completion->is_ready;
        for my $code (@handlers) {
            try {
                $code->($_);
            } catch {
                my $ex = $@;
                $log->warnf("Exception raised in %s - %s", (eval { $self->describe } // "<failed>"), "$ex");
                $completion->fail($ex, source => 'exception in on_item callback');
                die $ex;
            }
        }
    }
    $self
}

=head2 emit_batch

=cut

sub emit_batch {
    my $self = shift;
    my $completion = $self->_completed;
    if(my @handlers = $self->{on_batch}->@*) {
        for (@_) {
            die 'already completed' if $completion->is_ready;
            for my $code (@handlers) {
                try {
                    $code->($_);
                } catch {
                    my $ex = $@;
                    $log->warnf("Exception raised in %s - %s", (eval { $self->describe } // "<failed>"), "$ex");
                    $completion->fail($ex, source => 'exception in on_batch callback');
                    die $ex;
                }
            }
        }
    }

    # Support item-at-a-time callbacks if we have any
    return $self unless $self->{on_item}->@*;
    for my $batch (@_) {
        $self->emit($_) for $batch->@*;
    }
    return $self;
}

=head2 each

=cut

sub each : method {
    my ($self, $code, %args) = @_;
    push @{$self->{on_item}}, $code;
    $self;
}

=head2 each_batch

=cut

sub each_batch : method {
    my ($self, $code, %args) = @_;
    push @{$self->{on_batch}}, $code;
    $self;
}

=head2 each_as_source

=cut

sub each_as_source : method {
    my ($self, @code) = @_;

    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    my @active;
    $self->_completed->on_ready(sub {
        Future->needs_all(
            grep $_, @active
        )->on_ready(sub {
            $src->finish
        })->retain
    });

    $self->each_while_source(sub {
        my @pending;
        for my $code (@code) {
            push @pending, $code->($_);
        }
        push @active, map $_->completed, @pending;
        $src->emit($_);
    }, $src)
}

sub cleanup {
    my ($self) = @_;
    $log->tracef("Cleanup for %s (f = %s)", $self->describe, 0 + $self->_completed);
    $_->cancel for values %{$self->{cancel_on_ready} || {}};
    $self->parent->notify_child_completion($self) if $self->parent;
    splice $self->{on_item}->@*;
    delete @{$self->{cancel_on_ready}}{keys %{$self->{cancel_on_ready}}};
    $log->tracef("Finished cleanup for %s", $self->describe);
}

sub notify_child_completion {
    my ($self, $child) = @_;
    my $addr = Scalar::Util::refaddr($child);
    if(List::UtilsBy::extract_by { $addr == Scalar::Util::refaddr($_) } @{$self->{children}}) {
        $log->tracef(
            "Removed completed child %s, have %d left",
            $child->describe,
            0 + @{$self->{children}}
        );
        return $self if $self->is_ready;
        return $self if @{$self->{children}};

        $log->tracef(
            "This was the last child, cancelling %s",
            $self->describe
        );
        $self->cancel;
        return $self;
    }

    $log->warnf("Child %s (addr 0x%x) not found in list for %s", $child->describe, $addr, $self->describe);
    $log->tracef("* %s (addr 0x%x)", $_->describe, Scalar::Util::refaddr($_)) for @{$self->{children}};
    $self
}

=head2 await

Block until this source finishes.

=cut

sub await {
    my ($self) = @_;
    $self->prepare_await;
    my $f = $self->_completed;
    $f->await until $f->is_ready;
    $self
}

=head2 next

Returns a L<Future> which will resolve to the next item emitted by this source.

If the source completes before an item is emitted, the L<Future> will be cancelled.

Note that these are independent - they don't stack, so if you call C<< ->next >>
multiple times before an item is emitted, each of those would return the same value.

See L<Ryu::Buffer> if you're dealing with protocols and want to extract sequences of
bytes or characters.

To access the sequence as a discrete stream of L<Future> instances, try L</as_queue>
which will provide a L<Future::Queue>.

=cut

sub next : method {
    my ($self) = @_;
    my $f = $self->new_future(
        'next'
    )->on_ready($self->$curry::weak(sub {
        my ($self, $f) = @_;
        my $addr = Scalar::Util::refaddr($f);
        List::UtilsBy::extract_by { Scalar::Util::refaddr($_) == $addr } @{$self->{on_item} || []};
        delete $self->{cancel_on_ready}{$f};
    }));
    $self->{cancel_on_ready}{$f} = $f;
    push @{$self->{on_item}}, sub {
        $f->done(shift) unless $f->is_ready;
    };
    return $f;
}

=head2 finish

Mark this source as completed.

=cut

sub finish { $_[0]->_completed->done unless $_[0]->_completed->is_ready; $_[0] }

sub refresh { }

=head1 METHODS - Proxied

The following methods are proxied to our completion L<Future>:

=over 4

=item * then

=item * is_ready

=item * is_done

=item * failure

=item * is_cancelled

=item * else

=back

=cut

sub get {
    my ($self) = @_;
    my $f = $self->_completed;
    my @rslt;
    $self->each(sub { push @rslt, $_ }) if defined wantarray;
    if(my $parent = $self->parent) {
        $parent->await
    }
    $f->transform(done => sub {
        @rslt
    })->get
}

for my $k (qw(then fail on_ready transform is_ready is_done is_failed failure else)) {
    do { no strict 'refs'; *$k = $_ } for sub { shift->_completed->$k(@_) }
}
# Cancel operations are only available through the internal state, since we don't want anything
# accidentally cancelling due to Future->wait_any(timeout, $src->_completed) or similar constructs
for my $k (qw(cancel is_cancelled)) {
    do { no strict 'refs'; *$k = $_ } for sub { shift->{completed}->$k(@_) }
}

=head1 METHODS - Internal

=head2 prepare_await

Run any pre-completion callbacks (recursively) before
we go into an await cycle.

Used for compatibility with sync bridges when there's
no real async event loop available.

=cut

sub prepare_await {
    my ($self) = @_;
    (delete $self->{on_get})->() if $self->{on_get};
    return unless my $parent = $self->parent;
    my $code = $parent->can('prepare_await') or return;
    local @_ = ($parent);
    goto &$code;
}

=head2 chained

Returns a new L<Ryu::Source> chained from this one.

=cut

sub chained {
    my ($self) = shift;
    if(my $class = ref($self)) {
        my $src = $class->new(
            new_future => $self->{new_future},
            parent     => $self,
            @_
        );
        Scalar::Util::weaken($src->{parent});
        push @{$self->{children}}, $src;
        $log->tracef("Constructing chained source for %s from %s (%s)", $src->label, $self->label, $self->_completed->state);
        return $src;
    } else {
        my $src = $self->new(@_);
        $log->tracef("Constructing chained source for %s with no parent", $src->label);
        return $src;
    }
}

=head2 each_while_source

Like L</each>, but removes the source from the callback list once the
parent completes.

=cut

sub each_while_source {
    my ($self, $code, $src, %args) = @_;
    $self->each($code);
    $src->_completed->on_ready(sub {
        my $addr = Scalar::Util::refaddr($code);
        my $count = List::UtilsBy::extract_by { $addr == Scalar::Util::refaddr($_) } @{$self->{on_item}};
        $log->tracef("->each_while_source completed on %s for refaddr 0x%x, removed %d on_item handlers", $self->describe, Scalar::Util::refaddr($self), $count);
    });
    $self->_completed->on_ready(sub {
        my ($f) = @_;
        $args{cleanup}->($f, $src) if exists $args{cleanup};
        $f->on_ready($src->_completed) unless $src->is_ready or !($args{finish_source} // 1);
    });
    $src
}

=head2 map_source

Provides a L</chained> source which has more control over what it
emits than a standard L</map> or L</filter> implementation.

 $original->map_source(sub {
  my ($item, $src) = @_;
  $src->emit('' . reverse $item);
 });

=cut

sub map_source {
    my ($self, $code) = @_;

    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    $self->_completed->on_ready(sub {
        return if $src->is_ready;
        shift->on_ready($src->_completed);
    });
    $self->each_while_source(sub {
        $code->($_, $src) for $_;
    }, $src);
}

sub DESTROY {
    my ($self) = @_;
    return if ${^GLOBAL_PHASE} eq 'DESTRUCT';
    $log->tracef("Destruction for %s", $self->describe);
    $self->_completed->cancel unless $self->_completed->is_ready;
}

sub catch {
    my ($self, $code) = @_;
    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    $self->_completed->on_fail(sub {
        my @failure = @_;
        my $sub = $code->(@failure);
        if(Scalar::Util::blessed $sub && $sub->isa('Ryu::Source')) {
            $sub->each_while_source(sub {
                $src->emit($_)
            }, $src);
        } else {
            $sub->fail(@failure);
        }
    });
    $self->each_while_source(sub {
        $src->emit($_)
    }, $src);
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2011-2024. Licensed under the same terms as Perl itself.

