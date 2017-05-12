#!/usr/bin/perl
use Syntax::Highlight::Shell;
print Syntax::Highlight::Shell->new->parse(join'',<>)
