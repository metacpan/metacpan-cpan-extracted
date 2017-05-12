package # hide from PAUSE indexer
    Perl6::GatherTake::LazyList;

=head1 NAME

C<Perl6::GatherTake::LazyList> - Lazy tied array for C<Perl6::GatherTake>.

=head1 SYNOPSIS

You shouldn't use this module. C<Perl6::GatherTake> does that transparently
for you.

    use Coro;
    use Coro::Channel;
    use Perl6::GatherTake::LazyList;

    my $queue = Coro::Channel->new(1);

    my $coro = async {
        for (1 .. 100){
            my $result;
            # do some heavy computations here
            $queue->put($result);
        }
    };

    my @results;
    tie @results, 'Perl6::GatherTake::LazyList', $coro, $queue;

=head1 DESCRIPTION

Tied array implementation for C<Perl6::GatherTake>. Again: don't use this
yourself unless you really know what you're doing (and you don't).

=head1 LICENSE

Same as C<Perl6::GatherTake>.

=head1 AUTHOR

Moritz Lenz, L<http://moritz.faui2k.org>, L<http://perl-6.de/>.
E-Mail E<lt>moritz@faui2k3.orgE<gt>.

=cut

use strict;
use warnings;
use Carp qw(confess cluck);
use Scalar::Util qw(refaddr);
#use Data::Dumper;

use Coro;
our %_ties;

our @ISA;

BEGIN {
    require Tie::Array;
    @ISA = qw(Tie::Array);
}

sub TIEARRAY {
    my ($class, $coro, $queue) = @_;
    my $self = bless {
        coro        => $coro,
        queue       => $queue,
        computed    => [],
        exhausted   => 0,
    }, $class;
    $_ties{$coro} = $self;

    $coro->on_destroy( sub { 
        #print "Exhausted iterator\n";
        $self->{exhausted} = 1 ;
        # this is tricky: the coro will not put another item into
        # the queue when it end, but _compute calls ->get(), thus
        # waits for one - which is a deadlock.
        # so we have to put another value, which _computed will remove
        $self->{queue}->put(undef);
    });

    return $self;
}

sub FETCH {
    my ($self, $index) = @_;
#    warn "Fetching item $index ($self->{exhausted})\n";
#    print Dumper $self->{computed};
    $self->_compute($index);
    return $self->{computed}->[$index];
}

sub STORE {
    my ($self, $index, $value) = @_;
    $self->_compute($index);
    $self->{computed}[$index] = $value;
}

# XXX this is ugly and wrong
sub FETCHSIZE {
    my $self = shift;
#    warn "# FETCHSIZE called\n";
    return ($self->{exhausted} ? 0 : 1) +  scalar @{$self->{computed}};
#    return 2;

#    while (!$self->{exhausted}){
#        $self->_compute();
#    }
#    return scalar @{$self->{computed}};
}

sub STORESIZE {
    # do nothing
}

sub EXISTS {
    my ($self, $index) = @_;
#    warn "EXISTS($index) called\n";
    $self->_compute($index);
    return @{$self->{computed}} > $index ? 1 : 0;
}

sub _compute {
    my $self = shift;
    return if $self->{exhausted};
#    print "Size: ", $self->{queue}->size, "\n";

#    local $Coro::idle = sub { $self->{queue}->put(undef) };


    if (@_){
        my $index = shift;
        while(@{$self->{computed}} <= $index && !$self->{exhausted}){
            push @{$self->{computed}}, $self->{queue}->get();
        }
    } else {
        push @{$self->{computed}}, $self->{queue}->get();
    }
    if ($self->{exhausted}){
        # see comment in sub TIEARRAY - the last item is pushed
        # by the on_destroy handler that also set the exhausted flag
        pop @{$self->{computed}};
    }
#    print Dumper $self->{computed};
}

sub UNTIE {
    my $self = shift;
    delete $self->{computed};
}

1;
