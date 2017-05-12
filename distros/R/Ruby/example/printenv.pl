#!/usr/bin/perl


use Ruby;
use Ruby qw(rb_const);

rb_const(ENV)->each(sub{
	puts $_[0] . " = " . $_[1];
});
