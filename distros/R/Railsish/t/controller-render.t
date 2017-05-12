#!/usr/bin/env perl -w
use strict;
use Test::More "no_plan";

use lib qw(lib t/SimpleApp);

package FooController;
use Railsish::Controller;

package main;
can_ok("FooController", qw(render render_xml render_json redirect_to));



