#line 1
package Test2::Event::Skip;
use strict;
use warnings;

our $VERSION = '1.302175';


BEGIN { require Test2::Event::Ok; our @ISA = qw(Test2::Event::Ok) }
use Test2::Util::HashBase qw{reason};

sub init {
    my $self = shift;
    $self->SUPER::init;
    $self->{+EFFECTIVE_PASS} = 1;
}

sub causes_fail { 0 }

sub summary {
    my $self = shift;
    my $out = $self->SUPER::summary(@_);

    if (my $reason = $self->reason) {
        $out .= " (SKIP: $reason)";
    }
    else {
        $out .= " (SKIP)";
    }

    return $out;
}

sub extra_amnesty {
    my $self = shift;

    my @out;

    push @out => {
        tag       => 'TODO',
        details   => $self->{+TODO},
    } if defined $self->{+TODO};

    push @out => {
        tag       => 'skip',
        details   => $self->{+REASON},
        inherited => 0,
    };

    return @out;
}

1;

__END__

#line 127
