#!/usr/bin/env perl

use FindBin;
use lib "$FindBin::Bin/../";
use lib "$FindBin::Bin/../../../lib"; 
use Catalyst::ScriptRunner;

Catalyst::ScriptRunner->run('TestApp', 'Test');


1;
