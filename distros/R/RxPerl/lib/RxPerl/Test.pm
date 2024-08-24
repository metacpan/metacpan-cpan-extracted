package RxPerl::Test;

use strict;
use warnings;

use RxPerl::SyncTimers ':all';

use Carp 'croak';
use Test2::V0;

use Exporter 'import';
our @EXPORT = qw/ obs_is cold /;

our $VERSION = "v6.29.7";

sub cold {
    my ($marble, $mapping) = @_;

    $marble =~ s/\-\z/\|/;
    $mapping //= {};

    # Syntax check
    croak 'Invalid syntax in marble diagram of cold' if $marble !~ /^((?:\((?:[a-z0-9|#])+?\))|[a-z0-9|#-])*\z/gx;
    pos $marble = 0;

    my @tokens = $marble =~ /[a-z0-9\(\)\-\|\#]/g;

    my @components;
    my $time = 0;
    my $have_waited = 0;
    my $in_brackets = 0;

    TOKEN: for (my $i = 0; $i < @tokens; $i++) {
        my $token = $tokens[$i];
        if ($token =~ /^[a-z0-9]\z/) {
            $token = $mapping->{$token} if exists $mapping->{$token};
            push @components, rx_of($token)->pipe(op_delay($time));
            $have_waited = $time;
            $time++ unless $in_brackets;
        } elsif ($token eq '(') {
            $in_brackets = 1;
        } elsif ($token eq ')') {
            $in_brackets = 0;
            $time++;
        } elsif ($token eq '-') {
            $time++;
        } elsif ($token eq '|') {
            if ($time > $have_waited) {
                push @components, rx_timer($time)->pipe(op_ignore_elements);
            }
            last TOKEN;
        } elsif ($token eq '#') {
            push @components, rx_concat(
                rx_timer($time)->pipe(op_ignore_elements),
                rx_throw_error,
            );
            last TOKEN;
        }
    }

    return rx_merge(@components);
}

sub get_timeline {
    my ($observable) = @_;

    my %timeline;

    RxPerl::SyncTimers->reset;

    $observable->subscribe({
        next     => sub {
            my ($value) = @_;

            my $time = $RxPerl::SyncTimers::time;
            push @{$timeline{$time}}, { next => $value };
        },
        error    => sub {
            my ($error) = @_;

            my $time = $RxPerl::SyncTimers::time;
            push @{$timeline{$time}}, { error => $error };
        },
        complete => sub {
            my $time = $RxPerl::SyncTimers::time;
            push @{$timeline{$time}}, {complete => undef};
        },
    });

    RxPerl::SyncTimers->start;

    return \%timeline;
}

sub obs_is {
    my ($o, $expected, $name) = @_;

    my ($marble, $mapping) = @$expected;

    return is(get_timeline($o), get_timeline(cold($marble, $mapping)), $name);
}

1;
