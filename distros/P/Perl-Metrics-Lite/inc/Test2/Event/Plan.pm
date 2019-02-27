#line 1
package Test2::Event::Plan;
use strict;
use warnings;

our $VERSION = '1.302073';


BEGIN { require Test2::Event; our @ISA = qw(Test2::Event) }
use Test2::Util::HashBase qw{max directive reason};

use Carp qw/confess/;

my %ALLOWED = (
    'SKIP'    => 1,
    'NO PLAN' => 1,
);

sub init {
    if ($_[0]->{+DIRECTIVE}) {
        $_[0]->{+DIRECTIVE} = 'SKIP'    if $_[0]->{+DIRECTIVE} eq 'skip_all';
        $_[0]->{+DIRECTIVE} = 'NO PLAN' if $_[0]->{+DIRECTIVE} eq 'no_plan';

        confess "'" . $_[0]->{+DIRECTIVE} . "' is not a valid plan directive"
            unless $ALLOWED{$_[0]->{+DIRECTIVE}};
    }
    else {
        confess "Cannot have a reason without a directive!"
            if defined $_[0]->{+REASON};

        confess "No number of tests specified"
            unless defined $_[0]->{+MAX};

        confess "Plan test count '" . $_[0]->{+MAX}  . "' does not appear to be a valid positive integer"
            unless $_[0]->{+MAX} =~ m/^\d+$/;

        $_[0]->{+DIRECTIVE} = '';
    }
}

sub sets_plan {
    my $self = shift;
    return (
        $self->{+MAX},
        $self->{+DIRECTIVE},
        $self->{+REASON},
    );
}

sub callback {
    my $self = shift;
    my ($hub) = @_;

    $hub->plan($self->{+DIRECTIVE} || $self->{+MAX});

    return unless $self->{+DIRECTIVE};

    $hub->set_skip_reason($self->{+REASON} || 1) if $self->{+DIRECTIVE} eq 'SKIP';
}

sub terminate {
    my $self = shift;
    # On skip_all we want to terminate the hub
    return 0 if $self->{+DIRECTIVE} && $self->{+DIRECTIVE} eq 'SKIP';
    return undef;
}

sub summary {
    my $self = shift;
    my $max = $self->{+MAX};
    my $directive = $self->{+DIRECTIVE};
    my $reason = $self->{+REASON};

    return "Plan is $max assertions"
        if $max || !$directive;

    return "Plan is '$directive', $reason"
        if $reason;

    return "Plan is '$directive'";
}

1;

__END__

#line 160
