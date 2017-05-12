#!/usr/bin/perl
use strict;
use warnings;
use Benchmark qw(:all :hireswallclock);

require "egObjectLocalVars.pl";     # avoid CPAN indexing of .pm

my $egObjectLocalVars = egObjectLocalVars->new;

my %many_objs;
sub create {
    my $class = shift;
    push @{$many_objs{$class}}, $class->new;
}

sub destroy {
    my $class = shift;
    @{$many_objs{$class}} = ();
}

sub churn {
    my ($obj, $n) = @_;
    $n = 1 if $n < 1;
    while ($n--) {
        $obj->set_prop1(1);
        $obj->prop1;
    }
    return; 
}

sub cycle {
    my $obj = shift->new;
    $obj->crunch(shift);
}

print "\nOBJECT CREATE, ACCESS INSIDE, DESTROY: 1 CYCLE\n";
timethese ( 100000, {
    'Object::LocalVars'     => sub { cycle("egObjectLocalVars",1) },
});

    

