#!/usr/bin/env perl

use strict;
use warnings;

use RTx::ToGitHub;

exit RTx::ToGitHub->new_with_options->run;
