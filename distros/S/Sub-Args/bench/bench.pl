#! /usr/bin/perl
use strict;
use warnings;
use Benchmark qw/cmpthese/;

cmpthese(100000, {
    'SM::A'      => sub {Mock::SMA->call({name => 'nekokak'})},
    'P::V'       => sub {Mock::PV->call(name => 'nekokak')},
    'S::A'       => sub {Mock::SA->call({name => 'nekokak'})},
    'S::A_fast'  => sub {Mock::SA->call_fast({name => 'nekokak'})},
});

package Mock::SMA;
use Smart::Args;

sub call {
    args my $self, my $name;
}

package Mock::PV;
use Params::Validate qw(:all);

sub call {
    shift;
    my %args = validate( @_, { name => 1});
}

package Mock::SA;
use Sub::Args;

sub call {
    shift;
    my $args = args({name => 1});
}

sub call_fast {
    shift;
    my $args = args({name => 1}, @_);
}

__END__
# v0.04
              Rate      P::V     SM::A      S::A S::A_fast
P::V       46729/s        --      -55%      -61%      -78%
SM::A     103093/s      121%        --      -13%      -52%
S::A      119048/s      155%       15%        --      -44%
S::A_fast 212766/s      355%      106%       79%        --

# use Internals::SvREADONLY
              Rate      P::V      S::A     SM::A S::A_fast
P::V       46729/s        --      -49%      -56%      -70%
S::A       91743/s       96%        --      -13%      -40%
SM::A     105263/s      125%       15%        --      -32%
S::A_fast 153846/s      229%       68%       46%        --

             Rate      P::V      S::A     SM::A S::A_fast
P::V      24691/s        --      -55%      -60%      -71%
S::A      54945/s      123%        --      -12%      -35%
SM::A     62500/s      153%       14%        --      -26%
S::A_fast 84746/s      243%       54%       36%        --
