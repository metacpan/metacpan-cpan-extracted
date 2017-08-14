package PerlX::AsyncAwait::Compiler;

use strictures 2;
use base qw(PerlX::Generator::Compiler);

sub top_keyword { '(?:async_sub|async_do)' }
sub yield_keyword { 'await' }

1;
