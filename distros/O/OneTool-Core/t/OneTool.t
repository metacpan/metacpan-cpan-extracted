#!/usr/bin/perl

=head1 NAME

t/OneTool.t

=head1 DESCRIPTION

Tests for OneTool module

=cut

use strict;
use warnings;

use FindBin;
use Test::More;

use lib "$FindBin::Bin/../lib/";

require_ok('OneTool');

like($OneTool::VERSION, qr/\d+\.\d+/, "\$OneTool::VERSION => $OneTool::VERSION");

done_testing(2);

=head1 AUTHOR

Sebastien Thebert <contact@onetool.pm>

=cut
