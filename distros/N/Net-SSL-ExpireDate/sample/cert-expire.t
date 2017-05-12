#!/usr/bin/env perl
# -*- mode: cperl; -*-
use Test::Base;
use Net::SSL::ExpireDate;
use Regexp::Common qw(net);

my $Check_Duration;
# $Check_Duration = '15 years';

plan tests => 1 * blocks;

run {
    my $block = shift;
    my $ed = Net::SSL::ExpireDate->new( build_arg($block->name) );
    is($ed->is_expired($Check_Duration) && $ed->expire_date->iso8601,
       undef,
       $block->name);
};

sub build_arg {
    my ($v) = @_;
    if ($v =~ m{^(file)://(.+)}) {
        return $1 => $2;
    } elsif ($v =~ m{^(https)://([^/]+)}) {
        return $1 => $2;
    } elsif ($v =~ m{^$RE{net}{domain}{-nospace}{-keep}$}) {
        return 'https' => $1;
    } elsif (-r $v) {
        return 'file' => $v;
    } else {
        croak "$v: assume file. but cannot read.";
    }
}

__END__
=== rt.cpan.org
=== www.google.com
