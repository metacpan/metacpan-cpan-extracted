#!/usr/bin/perl
use Syntax::Highlight::HTML;
print Syntax::Highlight::HTML->new->parse(join'',<>)
