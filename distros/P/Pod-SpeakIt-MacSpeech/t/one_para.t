#!/usr/bin/perl

use Test::More 'no_plan';

require "t/lib/speak_pod_file.pl";

speak_pod_file( 'one_para.pod' );