#!/usr/local/bin/perl -w

require 5.004;

use strict;
#use diagnostics;
use Carp;
BEGIN {  unshift @INC, "../lib"; } 

use Parse::Template;
$|++;

$Parse::Template::CONFESS = 0;
eval {
  Parse::Template->new(
		       'TOP' => q!%%$_[0] < 3 ? '[' . TOP($_[0] + 1) . ']' : DIE() %%!,
		       'ERROR' => q!%% problem++ %%!,
		       'DIE' => q!%%die()%%!,
		      )->eval('TOP', 0);
};
__END__
exit;
$Parse::Template::CONFESS = 0;
print STDERR "---\n";
eval {
  Parse::Template->new(
		       'TOP' => q!%%$_[0] < 10 ? '[' . TOP($_[0] + 1) . ']' : ERROR() %%!,
		       'ERROR' => q!%% problem++ %%!,
		      )->eval('TOP', 0);
};

die;
