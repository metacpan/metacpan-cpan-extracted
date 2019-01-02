package Ryu::Source;

use strict;
use warnings;

use parent qw(Ryu::Node);

our $VERSION = '0.035'; # VERSION

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

=cut

no indirect;

use Future;
use curry::weak;

use Log::Any qw($log);

# Implementation note: it's likely that many new methods will be added to this
# class over time. Most methods have an attempt at "scope-local imports" using
# namespace::clean functionality, this is partly to make it easier to copy/paste
# the code elsewhere for testing, and partly to avoid namespace pollution.

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
        use Encode qw(encode_utf8);
        use namespace::clean qw(encode_utf8);
        sub {
            encode_utf8($_)
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
        use Encode qw(decode_utf8 FB_QUIET);
        use namespace::clean qw(decode_utf8 FB_QUIET);
        my $data = '';
        sub {
            $data .= $_;
            decode_utf8($data, FB_QUIET)
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
    $self->SUPER::new(%args);
}

=head2 from

Creates a new source from things.

The precise details of what this method supports may be somewhat ill-defined at this point in time.
It is expected that the interface and internals of this method will vary greatly in versions to come.

=cut

sub from {
    my $class = shift;
    my $src = (ref $class) ? $class : $class->new;
    if(my $from_class = blessed($_[0])) {
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
            $src->{on_get} = sub {
                $src->emit($_) for @{$_[0]};
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

=head2 describe

Returns a string describing this source and any parents - typically this will result in a chain
like C<< from->combine_latest->count >>.

=cut

# It'd be nice if L<Future> already provided a method for this, maybe I should suggest it
sub describe {
    my ($self) = @_;
    ($self->parent ? $self->parent->describe . '=>' : '') . $self->label . '(' . $self->completed->state . ')';
}

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
    $self->completed->on_ready(sub {
        return if $src->is_ready;
        shift->on_ready($src->completed);
    });
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
    $self->completed->on_ready(sub {
        return if $src->is_ready;
        shift->on_ready($src->completed);
    });
    $self->each_while_source(sub {
        $src->emit($code->($_))
    }, $src);
}

=head2 print

Shortcut for C< ->each(sub { print }) >, except this will
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
    $self->completed->on_ready(sub {
        return if $src->is_ready;
        shift->on_ready($src->completed);
    });
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
        while(length(my $bytes = substr $in, 0, 16, '')) {
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
    $self->completed->on_ready(sub {
        return if $src->is_ready;
        shift->on_ready($src->completed);
    });
    $self->each_while_source(sub {
        $src->emit(blessed($_)
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

=cut

sub flat_map {
    use Scalar::Util qw(blessed weaken);
    use Ref::Util qw(is_plain_arrayref is_plain_coderef);
    use namespace::clean qw(blessed is_plain_arrayref is_plain_coderef weaken);

    my ($self, $code) = splice @_, 0, 2;

    # Upgrade ->flat_map(method => args...) to a coderef
    if(!is_plain_coderef($code)) {
        my $method = $code;
        my @args = @_;
        $code = sub { $_->$method(@args) }
    }

    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);

    weaken(my $weak_sauce = $src);
    my $add = sub  {
        my $v = shift;
        my $src = $weak_sauce or return;

        my $k = "$v";
        $log->tracef("Adding %s which will bring our count to %d", $k, 0 + keys %{$src->{waiting}});
        $src->{waiting}{$k} = $v->on_ready(sub {
            return unless my $src = $weak_sauce;
            delete $src->{waiting}{$k};
            $src->finish unless %{$src->{waiting}};
        })
    };

    $add->($self->completed);
    $self->each_while_source(sub {
        my $src = $weak_sauce or return;
        for ($code->($_)) {
            my $item = $_;
            if(is_plain_arrayref($item)) {
                $log->tracef("Have an arrayref of %d items", 0 + @$item);
                for(@$item) {
                    last if $src->is_ready;
                    $src->emit($_);
                }
            } elsif(blessed($item) && $item->isa(__PACKAGE__)) {
                $log->tracef("This item is a source");
                $add->($item->completed);
                $src->on_ready(sub {
                    return if $item->is_ready;
                    $log->tracef("Marking %s as ready because %s was", $item->describe, $src->describe);
                    shift->on_ready($item->completed);
                });
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
    $self->completed->on_ready(sub {
        return if $src->is_ready;
        shift->on_ready($src->completed);
    });
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
    $self->completed->on_ready(sub {
        return if $src->is_ready;
        shift->on_ready($src->completed);
    });
    $self->each_while_source(sub {
        $buffer .= $_;
        $src->emit(substr $buffer, 0, $size, '') while length($buffer) >= $size;
    }, $src);
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
    $self->completed->on_ready(sub {
        return if $src->is_ready;
        shift->on_ready($src->completed);
    });
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
    $self->completed->on_ready(sub {
        shift->on_ready($src->completed) unless $src->completed->is_ready
    });
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
    $self->completed->on_ready(sub {
        shift->on_ready($src->completed) unless $src->completed->is_ready
    });
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
    $self->completed->on_ready(sub {
        shift->on_ready($src->completed) unless $src->completed->is_ready
    });
    $self->each_while_source(sub {
        my ($item) = @_;
        $src->emit(sprintf $fmt, map $item->$_ // '', @methods)
    }, $src);
}

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
    $self->completed->on_ready(sub {
        shift->on_ready($src->completed) unless $src->completed->is_ready
    });
    my $item_handler = do {
        Scalar::Util::weaken(my $weak_self = $self);
        Scalar::Util::weaken(my $weak_src = $src);
        sub {
            my $self = $weak_self;
            my $src = $weak_src or return;
            if(@pending >= $args{high} and $self and not $self->is_paused($src)) {
                $self->pause($src);
            }
            $src->emit(shift @pending) while @pending and not $src->is_paused;
            $self->resume($src) if @pending < $args{low} and $self and $self->is_paused($src);
        }
    };
    $src->flow_control
        ->each($item_handler)->retain;
    $self->each_while_source(sub {
        push @pending, $_;
        $item_handler->()
    }, $src);
}

sub retain {
    my ($self) = @_;
    $self->{_self} = $self;
    $self->completed
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
    $self->completed->transform(done => sub { @data })
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
    $self->completed->transform(done => sub { \@data })
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
    $self->completed->transform(done => sub { $data })
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
    use Scalar::Util qw(blessed);
    use namespace::clean qw(blessed);
    my ($self, @sources) = @_;
    push @sources, sub { @_ } if blessed $sources[-1];
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
        return if $combined->completed->is_ready;
        shift->on_ready($combined->completed)
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
    use Scalar::Util qw(blessed);
    use namespace::clean qw(blessed);
    my ($self, @sources) = @_;
    push @sources, sub { @_ } if blessed $sources[-1];
    my $code = pop @sources;

    my $combined = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    my @value;
    my %seen;
    for my $idx (0..$#sources) {
        my $src = $sources[$idx];
        $src->each(sub {
            return if $combined->completed->is_ready;
            $value[$idx] = $_;
            $seen{$idx} ||= 1;
        });
    }
    $self->each(sub {
        $combined->emit([ $code->(@value) ]) if keys %seen;
    });
    $self->completed->on_ready($combined->completed);
    $self->completed->on_ready(sub {
        @value = ();
        return if $combined->is_ready;
        shift->on_ready($combined->completed);
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
            return if $combined->completed->is_ready;
            $combined->emit($_)
        });
    }
    Future->needs_all(
        map $_->completed, @sources
    )->on_ready($combined->completed)
     ->on_ready(sub { @sources = () })
     ->retain;
    $combined
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
    )->on_ready($src->completed)
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
    use Variable::Disposition qw(retain_future);
    use Scalar::Util qw(blessed);
    use namespace::clean qw(retain_future);
    my ($self, $condition, @args) = @_;

    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    my @active;
    $self->completed->on_ready(sub {
        retain_future(
            Future->needs_all(
                grep $_, @active
            )->on_ready(sub {
                $src->finish
            })
        );
    });

    $self->each_while_source(sub {
        my ($item) = $_;
        my $rslt = $condition->($item);
        retain_future(
            (blessed($rslt) && $rslt->isa('Future') ? $rslt : Future->done($rslt))->on_done(sub {
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
            })
        )
    }, $src)
}

=head2 ordered_futures

Given a stream of L<Future>s, will emit the results as each L<Future>
is marked ready. If any fail, the stream will fail.

This is a terrible name for a method, expect it to change.

=cut

sub ordered_futures {
    use Scalar::Util qw(refaddr weaken);
    use namespace::clean qw(refaddr weaken);

    my ($self) = @_;
    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    my %pending;
    weaken(my $upstream_completed = $self->completed);
    my $all_finished = 0;
    $upstream_completed->on_ready(sub {
        $all_finished = 1;
        $src->completed->done unless %pending or $src->completed->is_ready;
    });
    $self->each_while_source(sub {
        my $k = refaddr $_;
        $pending{$k} = 1;
        $log->tracef('Ordered futures has %d pending', 0 + keys %pending);
        $_->on_done($src->curry::weak::emit)
          ->on_fail($src->curry::weak::fail)
          ->on_ready(sub {
              delete $pending{$k};
              $log->tracef('Ordered futures now has %d pending after completion, upstream finish status is %d', 0 + keys(%pending), $all_finished);
              return if %pending;
              $src->completed->done if $all_finished and not $src->completed->is_ready;
          })
          ->retain
    }, $src);
}

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
    $self->completed->on_done(sub {
        $src->emit($_) for @items[sort { $keys[$a] cmp $keys[$b] } 0 .. $#items];
    })->on_ready(sub {
        return if $src->is_ready;
        shift->on_ready($src->completed);
    });
    $self->each_while_source(sub {
        push @items, $_;
        push @keys, $_->$code;
    }, $src);
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
    $self->completed->on_done(sub {
        $src->emit($_) for @items[sort { $keys[$a] <=> $keys[$b] } 0 .. $#items];
    })->on_ready(sub {
        return if $src->is_ready;
        shift->on_ready($src->completed);
    });
    $self->each_while_source(sub {
        push @items, $_;
        push @keys, $_->$code;
    }, $src);
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
    $self->completed->on_done(sub {
        $src->emit($_) for @items[sort { $keys[$b] cmp $keys[$a] } 0 .. $#items];
    })->on_ready(sub {
        return if $src->is_ready;
        shift->on_ready($src->completed);
    });
    $self->each_while_source(sub {
        push @items, $_;
        push @keys, $_->$code;
    }, $src);
}

=head2 rev_nsort_by

Emits items numerically sorted by the given key. This is a stable sort function.

See L</sort_by>.

=cut

sub rev_nsort_by {
    use sort qw(stable);
    my ($self, $code) = @_;
    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    my @items;
    my @keys;
    $self->completed->on_done(sub {
        $src->emit($_) for @items[sort { $keys[$b] <=> $keys[$a] } 0 .. $#items];
    })->on_ready(sub {
        return if $src->is_ready;
        shift->on_ready($src->completed);
    });
    $self->each_while_source(sub {
        push @items, $_;
        push @keys, $_->$code;
    }, $src);
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
    $self->completed->on_ready(sub {
        return if $src->is_ready;
        shift->on_ready($src->completed);
    });
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
    $self->completed->on_ready(sub {
        return if $src->is_ready;
        shift->on_ready($src->completed);
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
    $self->completed->on_ready(sub {
        return if $src->is_ready;
        shift->on_ready($src->completed);
    });
    my @pending;
    $self->each(sub {
        push @pending, $_;
        $src->emit(shift @pending) if @pending > $count;
    });
    $src
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
    $self->completed->on_ready(sub {
        return if $src->is_ready;
        shift->on_ready($src->completed);
    });
    # $self->completed->on_ready($src->completed);
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
    $self->completed->on_ready(sub {
        return if $src->is_ready;
        shift->on_ready($src->completed);
    });

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
    $self->completed->on_ready(sub {
        my $sf = $src->completed;
        return if $sf->is_ready;
        my $f = shift;
        return $f->on_ready($sf) unless $f->is_done;
        $src->emit(0);
        $sf->done;
    });
    $self->each(sub {
        return if $src->completed->is_ready;
        return unless $code->($_);
        $src->emit(1);
        $src->completed->done
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
    $self->completed->on_done(sub {
        return if $src->completed->is_ready;
        $src->emit(1);
        $src->completed->done
    });
    $self->each(sub {
        return if $src->completed->is_ready;
        return if $code->($_);
        $src->emit(0);
        $src->completed->done
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
    $self->completed->on_done(sub {
        $src->emit($count)
    })->on_ready(
        $src->completed
    );
    $self->each_while_source(sub { ++$count }, $src);
}

=head2 sum

Emits the numeric sum of items seen once the parent completes.

=cut

sub sum {
    my ($self) = @_;

    my $sum = 0;

    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    $self->completed->on_done(sub {
        $src->emit($sum)
    })->on_ready(
        $src->completed
    );
    $self->each_while_source(sub {
        $sum += $_
    }, $src);
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
    $self->completed->on_done(sub { $src->emit($sum / ($count || 1)) })
        ->on_ready($src->completed);
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
    $self->completed->on_done(sub { $src->emit($max) })
        ->on_ready($src->completed);
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
    $self->completed->on_done(sub { $src->emit($min) })
        ->on_ready($src->completed);
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
    $self->completed->on_done(sub {
        $src->emit({
            count => $count,
            sum   => $sum,
            min   => $min,
            max   => $max,
            mean  => ($sum / ($count || 1))
        })
    })
        ->on_ready($src->completed);
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
    use Scalar::Util qw(blessed);
    use List::Util qw(any);
    use namespace::clean qw(blessed);
    my $self = shift;

    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    $self->completed->on_ready(sub {
        return if $src->is_ready;
        shift->on_ready($src->completed);
    });
    $self->each_while_source((@_ > 1) ? do {
        my %args = @_;
        my $check = sub {
            my ($k, $v) = @_;
            if(my $ref = ref $args{$k}) {
                if($ref eq 'Regexp') {
                    return 0 unless defined($v) && $v =~ $args{$k};
                } elsif($ref eq 'ARRAY') {
                    return 0 unless defined($v) && any { $v eq $_ } @{$args{$k}};
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
            if(blessed $item) {
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
    use Scalar::Util qw(blessed);
    use namespace::clean qw(blessed);
    my ($self, @isa) = @_;

    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    $self->completed->on_ready(sub {
        return if $src->is_ready;
        shift->on_ready($src->completed);
    });
    $self->each_while_source(sub {
        my ($item) = @_;
        return unless blessed $item;
        $src->emit($_) if grep $item->isa($_), @isa;
    }, $src);
}

=head2 emit

Emits the given item.

=cut

sub emit {
    use Syntax::Keyword::Try;
    use namespace::clean qw(try catch finally);
    my $self = shift;
    my $completion = $self->completed;
    my @handlers = @{$self->{on_item} || []} or return $self;
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

=head2 each

=cut

sub each : method {
    my ($self, $code, %args) = @_;
    push @{$self->{on_item}}, $code;
    $self;
}

=head2 each_as_source

=cut

sub each_as_source : method {
    use Variable::Disposition qw(retain_future);
    use namespace::clean qw(retain_future);
    my ($self, @code) = @_;

    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    my @active;
    $self->completed->on_ready(sub {
        retain_future(
            Future->needs_all(
                grep $_, @active
            )->on_ready(sub {
                $src->finish
            })
        );
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


=head2 completed

Returns a L<Future> indicating completion (or failure) of this stream.

=cut

sub completed {
    my ($self) = @_;
    $self->{completed} //= $self->new_future(
        'completion'
    )->on_ready(
        $self->curry::weak::cleanup
    )
}

sub cleanup {
    my ($self) = @_;
    $log->tracef("Cleanup for %s (f = %s)", $self->describe, 0 + $self->completed);
    $self->parent->notify_child_completion($self) if $self->parent;
    delete @{$self}{qw(on_item)};
    $log->tracef("Finished cleanup for %s", $self->describe);
}

sub notify_child_completion {
    use Scalar::Util qw(refaddr);
    use List::UtilsBy qw(extract_by);
    use namespace::clean qw(refaddr extract_by);

    my ($self, $child) = @_;
    if(extract_by { refaddr($child) == refaddr($_) } @{$self->{children}}) {
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

    $log->warnf("Child %s (addr 0x%x) not found in list for %s", $child->describe, $self->describe);
    $log->tracef("* %s (addr 0x%x)", $_->describe, refaddr($_)) for @{$self->{children}};
    $self
}

=head2 await

Block until this source finishes.

=cut

sub await {
    my ($self) = @_;
    $self->prepare_await;
    my $f = $self->completed;
    $f->await until $f->is_ready;
    $self
}

=head2 finish

Mark this source as completed.

=cut

sub finish { $_[0]->completed->done unless $_[0]->completed->is_ready; $_[0] }

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
    my $f = $self->completed;
    my @rslt;
    $self->each(sub { push @rslt, $_ }) if defined wantarray;
    if(my $parent = $self->parent) {
        $parent->await
    }
    $f->transform(done => sub {
        @rslt
    })->get
}

for my $k (qw(then cancel fail on_ready transform is_ready is_done failure is_cancelled else)) {
    do { no strict 'refs'; *$k = $_ } for sub { shift->completed->$k(@_) }
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
    my $code = $parent->can('prepare_await');
    local @_ = ($parent);
    goto &$code;
}

=head2 chained

Returns a new L<Ryu::Source> chained from this one.

=cut

sub chained {
    use Scalar::Util qw(weaken);
    use namespace::clean qw(weaken);

    my ($self) = shift;
    if(my $class = ref($self)) {
        my $src = $class->new(
            new_future => $self->{new_future},
            parent     => $self,
            @_
        );
        weaken($src->{parent});
        push @{$self->{children}}, $src;
        $log->tracef("Constructing chained source for %s from %s (%s)", $src->label, $self->label, $self->completed->state);
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
    use Scalar::Util qw(refaddr);
    use List::UtilsBy qw(extract_by);
    use namespace::clean qw(refaddr extract_by);
    my ($self, $code, $src) = @_;
    $self->each($code);
    $src->completed->on_ready(sub {
        my $count = extract_by { refaddr($_) == refaddr($code) } @{$self->{on_item}};
        $log->tracef("->each_while_source completed on %s for refaddr 0x%x, removed %d on_item handlers", $self->describe, refaddr($self), $count);
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
    $self->completed->on_ready(sub {
        return if $src->is_ready;
        shift->on_ready($src->completed);
    });
    $self->each_while_source(sub {
        $code->($_, $src) for $_;
    }, $src);
}

=head2 new_future

Used internally to get a L<Future>.

=cut

sub new_future {
    my $self = shift;
    (
        $self->{new_future} //= $FUTURE_FACTORY
    )->($self, @_)
}

sub DESTROY {
    my ($self) = @_;
    return if ${^GLOBAL_PHASE} eq 'DESTRUCT';
    $log->tracef("Destruction for %s", $self->describe);
    $self->completed->cancel unless $self->completed->is_ready;
}

sub catch {
    use Scalar::Util qw(blessed);
    use namespace::clean qw(blessed);
    my ($self, $code) = @_;
    my $src = $self->chained(label => (caller 0)[3] =~ /::([^:]+)$/);
    $self->completed->on_fail(sub {
        my @failure = @_;
        my $sub = $code->(@failure);
        if(blessed $sub && $sub->isa('Ryu::Source')) {
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

Copyright Tom Molesworth 2011-2019. Licensed under the same terms as Perl itself.

