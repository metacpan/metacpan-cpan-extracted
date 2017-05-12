#! /usr/bin/perl -w
#*********************************************************************
#*** t/Singleton.t
#*** Copyright (c) 2002 by Markus Winand <mws@fatalmind.com>
#*** $Id: 01Singleton.t,v 1.1 2002-06-23 19:56:09 mws Exp $
#*********************************************************************
use strict;

package Count;

use ResourcePool::Singleton;
push @Count::ISA, qw(ResourcePool::Singleton);

sub new($$) {
        my $proto = shift;
        my $class = ref($proto) || $proto;
        my $self;

        $self = $class->SUPER::new(@_);
        if (!exists($self->{CNT})) {
                $self->{CNT} = $_[0];
                bless($self, $class);
        }

        return $self;
}

sub next($) {
        my ($self) = @_;
        return $self->{CNT}++;
}

package MAIN;

use Test;

BEGIN { plan tests => 11; };

my $cnt = new Count(0);
ok(defined $cnt);
ok($cnt->next == 0);
ok($cnt->next == 1);

my $cnt2 = new Count(0);
ok (defined $cnt2);
ok ($cnt == $cnt2);
ok ($cnt2->next == 2);

my $cnt3 = new Count(1);
ok (defined $cnt3);
ok ($cnt3 != $cnt);
ok ($cnt3->next == 1);

ok ($cnt2->next == 3);
ok ($cnt->next == 4);

