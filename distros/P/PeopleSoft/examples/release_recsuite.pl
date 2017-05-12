#!/usr/bin/perl
#
# Copyright (c) 2003 William Goedicke. All rights reserved. This
# program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

use PeopleSoft::EPM;
use PeopleSoft;
use strict;
use Data::Dumper;

my $dbh = get_dbh('sysadm','PASSWD','eproto88');

# If you're still wedged for a particular map 
# check pf_ods_status = 'I' in PS_PF_DL_CONTROL

release_recsuite('001', 'PF_DL_RUN', $dbh);
release_recsuite('002', 'PF_DL_RUN', $dbh);
release_recsuite('003', 'PF_DL_RUN', $dbh);

$dbh->disconnect;
exit;
