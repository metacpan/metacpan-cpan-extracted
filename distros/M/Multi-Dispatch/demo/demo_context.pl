#! /usr/bin/env perl

use v5.22;
use warnings;

use Multi::Dispatch;

multi now :where({not defined wantarray}) () { say "It's ", scalar localtime }
multi now :where({not         wantarray}) () { return time }
multi now :where({            wantarray}) () { return scalar localtime }

now;
say scalar now;
say now;
say '___________';


multi right_now :where(VOID)   () { say "It's ", scalar localtime }
multi right_now :where(SCALAR) () { return time }
multi right_now :where(LIST)   () { return scalar localtime }

right_now;
say scalar right_now;
say right_now;
