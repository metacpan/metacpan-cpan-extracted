#line 1
package Test2::API::Stack;
use strict;
use warnings;

our $VERSION = '1.302073';


use Test2::Hub();

use Carp qw/confess/;

sub new {
    my $class = shift;
    return bless [], $class;
}

sub new_hub {
    my $self = shift;
    my %params = @_;

    my $class = delete $params{class} || 'Test2::Hub';

    my $hub = $class->new(%params);

    if (@$self) {
        $hub->inherit($self->[-1], %params);
    }
    else {
        require Test2::API;
        $hub->format(Test2::API::test2_formatter()->new)
            unless $hub->format || exists($params{formatter});

        my $ipc = Test2::API::test2_ipc();
        if ($ipc && !$hub->ipc && !exists($params{ipc})) {
            $hub->set_ipc($ipc);
            $ipc->add_hub($hub->hid);
        }
    }

    push @$self => $hub;

    $hub;
}

sub top {
    my $self = shift;
    return $self->new_hub unless @$self;
    return $self->[-1];
}

sub peek {
    my $self = shift;
    return @$self ? $self->[-1] : undef;
}

sub cull {
    my $self = shift;
    $_->cull for reverse @$self;
}

sub all {
    my $self = shift;
    return @$self;
}

sub clear {
    my $self = shift;
    @$self = ();
}

# Do these last without keywords in order to prevent them from getting used
# when we want the real push/pop.

{
    no warnings 'once';

    *push = sub {
        my $self = shift;
        my ($hub) = @_;
        $hub->inherit($self->[-1]) if @$self;
        push @$self => $hub;
    };

    *pop = sub {
        my $self = shift;
        my ($hub) = @_;
        confess "No hubs on the stack"
            unless @$self;
        confess "You cannot pop the root hub"
            if 1 == @$self;
        confess "Hub stack mismatch, attempted to pop incorrect hub"
            unless $self->[-1] == $hub;
        pop @$self;
    };
}

1;

__END__

#line 220
