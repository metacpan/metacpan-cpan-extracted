package Ryu::Async;
# ABSTRACT: IO::Async support for Ryu stream management
use strict;
use warnings;

our $VERSION = '0.006';

=head1 NAME

Ryu::Async - use L<Ryu> with L<IO::Async>

=head1 SYNOPSIS

 #!/usr/bin/env perl
 use strict;
 use warnings;
 
 use IO::Async::Loop;
 use Ryu::Async;
 
 use Log::Any::Adapter qw(Stdout), log_level => 'trace';
 
 my $loop = IO::Async::Loop->new;
 $loop->add(
 	my $ryu = Ryu::Async->new
 );
 
 {
 	my $timer = $ryu->timer(
 		interval => 0.10,
 	)->take(10)
 	 ->each(sub { print "tick\n" });
 	warn $timer->describe;
 	$timer->get;
 }

=head1 DESCRIPTION

This is an L<IO::Async::Notifier> subclass for interacting with L<Ryu>.

=cut

use parent qw(IO::Async::Notifier);

use IO::Async::Timer::Periodic;
use IO::Async::Stream;
use Ryu::Source;
use curry::weak;

use Log::Any qw($log);

=head1 METHODS

=cut

=head2 from

Creates a new L<Ryu::Source> from a thing.

The exact details of this are likely to change in future, but a few things that are expected to work:

 $ryu->from($io_async_stream_instance)
     ->by_line
     ->each(sub { print "Line: $_\n" });
 $ryu->from([1..1000])
     ->sum
     ->each(sub { print "Total was $_\n" });

=cut

sub from {
    use Scalar::Util qw(blessed weaken);
    use namespace::clean qw(blessed weaken);
    my $self = shift;

    if(my $class = blessed $_[0]) {
        if($class->isa('IO::Async::Stream')) {
            return $self->from_stream($_[0]);
        } else {
            die "Unable to determine appropriate source for $class";
        }
    }

    my $src = $self->source(label => 'from');
    if(my $ref = ref $_[0]) {
        if($ref eq 'ARRAY') {
            my @pending = @{$_[0]};
            my $code;
            $code = sub {
                if(@pending) {
                    $src->emit(shift @pending);
                    $self->loop->later($code);
                } else {
                    $src->finish;
                    weaken($_) for $src, $code, $self;
                }
            };
            $code->();
            return $src;
        } else {
            die "Unknown type $ref"
        }
    }

    my %args = @_;
    if(my $dir = $args{directory}) {
        opendir my $handle, $dir or die $!;
        my $code;
        $code = sub {
            if(defined(my $item = readdir $handle)) {
                $src->emit($item) unless $item eq '.' or $item eq '..';
                $self->loop->later($code);
            } else {
                weaken($code);
                closedir $handle or die $!;
                $src->finish
            }
        };
        $code->();
        return $self;
    }
    die "unknown stuff";
}

=head2 from_stream

Create a new L<Ryu::Source> from an L<IO::Async::Stream> instance.

Note that a stream which is not already attached to an L<IO::Async::Notifier>
will be added as a child of this instance.

=cut

sub from_stream {
    use Scalar::Util qw(blessed weaken);
    use namespace::clean qw(blessed weaken);
    my ($self, $stream) = @_;

    my $src = $self->source(label => 'from');
    $stream->configure(
        on_read => sub {
            my ($stream, $buffref, $eof) = @_;
            $log->tracef("Have %d bytes of data, EOF = %s", length($$buffref), $eof ? 'yes' : 'no');
            my $data = substr $$buffref, 0, length $$buffref, '';
            $src->emit($data);
            $src->finish if $eof && !$src->completed->is_ready;
        }
    );
    unless($stream->parent) {
        $self->add_child($stream);
        $src->completed->on_ready(sub {
            $self->remove_child($stream) if $stream->parent;
        });
    }
    return $src;
}

=head2 from_stream

Create a new L<Ryu::Source> that wraps STDIN.

As with other L<IO::Async::Stream> wrappers, this will emit data as soon as it's available,
as raw bytes.

Use L<Ryu::Source/by_line> and L<Ryu::Source/decode> to split into lines and/or decode from UTF-8.

=cut

sub stdin {
    my ($self) = @_;
    return $self->from_stream(
        IO::Async::Stream->new_for_stdin
    )
}

=head2 timer

Provides a L<Ryu::Source> which emits an empty string at selected intervals.

Takes the following named parameters:

=over 4

=item * interval - how often to trigger the timer, in seconds (fractional values allowed)

=item * reschedule - type of rescheduling to use, can be C<soft>, C<hard> or C<drift> as documented
in L<IO::Async::Timer::Periodic>

=back

Example:

 $ryu->timer(interval => 1, reschedule => 'hard')
     ->combine_latest(...)

=cut

sub timer {
    my ($self, %args) = @_;
    my $src = $self->source(label => 'timer');
    $self->add_child(
        my $timer = IO::Async::Timer::Periodic->new(
            reschedule => 'hard',
            %args,
            on_tick => $src->curry::weak::emit(''),
        )
    );
    Scalar::Util::weaken($timer);
    $src->on_ready($self->_capture_weakself(sub {
        my ($self) = @_;
        return unless $timer;
        $timer->stop if $timer->is_running;
        $self->remove_child($timer)
    }));
    $timer->start;
    $src
}

=head2 source

Returns a new L<Ryu::Source> instance.

=cut

sub source {
    my ($self, %args) = @_;
    my $label = delete($args{label}) // (caller 1)[3];
    $label =~ s/^Net::Async::/Na/g;
    $label =~ s/^IO::Async::/Ia/g;
    $label =~ s/^Web::Async::/Wa/g;
    $label =~ s/^Tickit::Async::/Ta/g;
    $label =~ s/::([^:]*)$/->$1/;
    Ryu::Source->new(
        new_future => $self->loop->curry::weak::new_future,
        label      => $label,
        %args,
    )
}

1;

__END__

=head1 SEE ALSO

=over 4

=item * L<Ryu>

=item * L<IO::Async>

=back

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2011-2017. Licensed under the same terms as Perl itself.

