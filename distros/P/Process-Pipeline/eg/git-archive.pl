#!/usr/bin/env perl
use 5.22.1;
use warnings;
use experimental qw/ signatures postderef /;
use lib '../lib', 'lib';
use Process::Pipeline::DSL;

my $p = proc { "git", "archive", "--format=tar", "--prefix=Process-Pipeline/", "HEAD" }
        proc { set ">" => "Process-Pipeline.tar.gz"; "gzip" };

my $r = $p->start;
say $r->is_success ? "success" : "fail";
