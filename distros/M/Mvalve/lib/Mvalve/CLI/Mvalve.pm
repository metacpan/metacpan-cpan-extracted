# $Id: /mirror/coderepos/lang/perl/Mvalve/trunk/lib/Mvalve/CLI/Mvalve.pm 66262 2008-07-16T05:50:26.279608Z daisuke  $

package Mvalve::CLI::Mvalve;
use Moose;

extends 'MooseX::App::Cmd';

no Moose;

sub plugin_search_path { __PACKAGE__ }

1;
