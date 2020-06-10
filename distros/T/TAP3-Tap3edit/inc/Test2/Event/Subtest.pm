#line 1
package Test2::Event::Subtest;
use strict;
use warnings;

our $VERSION = '1.302175';

BEGIN { require Test2::Event::Ok; our @ISA = qw(Test2::Event::Ok) }
use Test2::Util::HashBase qw{subevents buffered subtest_id subtest_uuid};

sub init {
    my $self = shift;
    $self->SUPER::init();
    $self->{+SUBEVENTS} ||= [];
    if ($self->{+EFFECTIVE_PASS}) {
        $_->set_effective_pass(1) for grep { $_->can('effective_pass') } @{$self->{+SUBEVENTS}};
    }
}

{
    no warnings 'redefine';

    sub set_subevents {
        my $self      = shift;
        my @subevents = @_;

        if ($self->{+EFFECTIVE_PASS}) {
            $_->set_effective_pass(1) for grep { $_->can('effective_pass') } @subevents;
        }

        $self->{+SUBEVENTS} = \@subevents;
    }

    sub set_effective_pass {
        my $self = shift;
        my ($pass) = @_;

        if ($pass) {
            $_->set_effective_pass(1) for grep { $_->can('effective_pass') } @{$self->{+SUBEVENTS}};
        }
        elsif ($self->{+EFFECTIVE_PASS} && !$pass) {
            for my $s (grep { $_->can('effective_pass') } @{$self->{+SUBEVENTS}}) {
                $_->set_effective_pass(0) unless $s->can('todo') && defined $s->todo;
            }
        }

        $self->{+EFFECTIVE_PASS} = $pass;
    }
}

sub summary {
    my $self = shift;

    my $name = $self->{+NAME} || "Nameless Subtest";

    my $todo = $self->{+TODO};
    if ($todo) {
        $name .= " (TODO: $todo)";
    }
    elsif (defined $todo) {
        $name .= " (TODO)";
    }

    return $name;
}

sub facet_data {
    my $self = shift;

    my $out = $self->SUPER::facet_data();

    $out->{parent} = {
        hid      => $self->subtest_id,
        children => [map {$_->facet_data} @{$self->{+SUBEVENTS}}],
        buffered => $self->{+BUFFERED},
    };

    return $out;
}

sub add_amnesty {
    my $self = shift;

    for my $am (@_) {
        $am = {%$am} if ref($am) ne 'ARRAY';
        $am = Test2::EventFacet::Amnesty->new($am);

        push @{$self->{+AMNESTY}} => $am;

        for my $e (@{$self->{+SUBEVENTS}}) {
            $e->add_amnesty($am->clone(inherited => 1));
        }
    }
}


1;

__END__

#line 160
