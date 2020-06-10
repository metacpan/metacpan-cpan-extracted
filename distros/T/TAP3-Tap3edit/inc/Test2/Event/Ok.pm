#line 1
package Test2::Event::Ok;
use strict;
use warnings;

our $VERSION = '1.302175';


BEGIN { require Test2::Event; our @ISA = qw(Test2::Event) }
use Test2::Util::HashBase qw{
    pass effective_pass name todo
};

sub init {
    my $self = shift;

    # Do not store objects here, only true or false
    $self->{+PASS} = $self->{+PASS} ? 1 : 0;
    $self->{+EFFECTIVE_PASS} = $self->{+PASS} || (defined($self->{+TODO}) ? 1 : 0);
}

{
    no warnings 'redefine';
    sub set_todo {
        my $self = shift;
        my ($todo) = @_;
        $self->{+TODO} = $todo;
        $self->{+EFFECTIVE_PASS} = defined($todo) ? 1 : $self->{+PASS};
    }
}

sub increments_count { 1 };

sub causes_fail { !$_[0]->{+EFFECTIVE_PASS} }

sub summary {
    my $self = shift;

    my $name = $self->{+NAME} || "Nameless Assertion";

    my $todo = $self->{+TODO};
    if ($todo) {
        $name .= " (TODO: $todo)";
    }
    elsif (defined $todo) {
        $name .= " (TODO)"
    }

    return $name;
}

sub extra_amnesty {
    my $self = shift;
    return unless defined($self->{+TODO}) || ($self->{+EFFECTIVE_PASS} && !$self->{+PASS});
    return {
        tag       => 'TODO',
        details   => $self->{+TODO},
    };
}

sub facet_data {
    my $self = shift;

    my $out = $self->common_facet_data;

    $out->{assert}  = {
        no_debug => 1,                # Legacy behavior
        pass     => $self->{+PASS},
        details  => $self->{+NAME},
    };

    if (my @exra_amnesty = $self->extra_amnesty) {
        unshift @{$out->{amnesty}} => @exra_amnesty;
    }

    return $out;
}

1;

__END__

#line 162
