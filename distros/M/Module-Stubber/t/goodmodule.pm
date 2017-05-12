package goodmodule;
use strict;
use warnings;
use base qw(Exporter);
use Data::Dumper;

sub import {
	my @callinfo = caller();
	goto &Exporter::import;
}
sub goodmodule_true { "goodmodule" }
our @EXPORT = qw(goodmodule_true);

1;
