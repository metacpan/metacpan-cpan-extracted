#!perl -T
use strict;
use warnings;

package Test::SubPipeline::PipePkg;

use Sub::Pipeline;

our $value = 0;
our $invocant = undef;

sub begin { $invocant = $_[0]; $value++; }
sub check { $value++; }
sub init  { $value++; }
sub run   { $value++; }
sub end   { $value++; Sub::Pipeline::Success->throw(value => $value); }

"tobacco =====(poison)===== lungs";
