# -*- perl -*-
#
#
#   DBD::mSQL1::Install - Determine settings of installing DBD::mSQL1
#

use strict;

require Config;
require File::Basename;
require ExtUtils::MakeMaker;


package DBD::mSQL1::Install;

@DBD::mSQL1::Install::ISA = qw(DBD::mSQL::Install);


sub new {
    my($class, $dbd_version, $nodbd_version) = @_;
    my($old, $self);

    if (@_ != 3) {
	die 'Usage: new($dbd_version, $nodbd_version)';
    }
    if (ref($class)) {
	$old = $class;
	$class = ref($class);
    } else {
	$old = {};
    }

    my $self = {
	'install'       => exists($old->{'install'}) ? $old->{'install'} : 1,
	'install_nodbd' => exists($old->{'install_nodbd'}) ?
	    $old->{'install_nodbd'} : 1,
	'dbd_driver'    => $old->{'dbd_driver'}   ||  'mSQL1',
	'nodbd_driver'  => $old->{'nodbd_driver'} ||  'Msql1',
	'description'   => $old->{'description'}  ||  'mSQL 1',
	'dbd_version'   => $dbd_version,
	'nodbd_version' => $nodbd_version,
	'test_db'       => $old->{'test_db'}      ||  'test',
	'test_host'     => $old->{'test_host'}    ||  'localhost',
	'test_user'     => $old->{'test_user'}    ||  undef,
	'test_pass'     => $old->{'test_pass'}    ||  undef,
	'files'         => {
	    'dbd/bundle.pm.in'      => 'mSQL1/lib/Bundle/DBD/mSQL1.pm',
	    'dbd/dbdimp.c'          => 'mSQL1/dbdimp.c',
	    'dbd/dbd.xs.in'         => 'mSQL1/mSQL1.xs',
	    'dbd/dbd.pm.in'         => 'mSQL1/lib/DBD/mSQL1.pm',
	    'tests/00base.t'        => 'mSQL1/t/00base.t',
	    'tests/10dsnlist.t'     => 'mSQL1/t/10dsnlist.t',
	    'tests/20createdrop.t'  => 'mSQL1/t/20createdrop.t',
	    'tests/30insertfetch.t' => 'mSQL1/t/30insertfetch.t',
	    'tests/40bindparam.t'   => 'mSQL1/t/40bindparam.t',
	    'tests/40listfields.t'  => 'mSQL1/t/40listfields.t',
	    'tests/40blobs.t'       => 'mSQL1/t/40blobs.t',
	    'tests/40nulls.t'       => 'mSQL1/t/40nulls.t',
	    'tests/40numrows.t'     => 'mSQL1/t/40numrows.t',
	    'tests/50chopblanks.t'  => 'mSQL1/t/50chopblanks.t',
	    'tests/50commit.t'      => 'mSQL1/t/50commit.t',
	    'tests/60leaks.t'       => 'mSQL1/t/60leaks.t',
	    'tests/ak-dbd.t'        => 'mSQL1/t/ak-dbd.t',
	    'tests/dbdadmin.t'      => 'mSQL1/t/dbdadmin.t',
#	    'tests/dbisuite.t'      => 'mSQL1/t/dbisuite.t',
	    'tests/lib.pl'          => 'mSQL1/t/lib.pl'
	    },
	'files_nodbd' => {
	    'tests/akmisc.t'        => 'mSQL1/t/akmisc.t',
	    'tests/msql1.t'         => 'mSQL1/t/msql1.t',
	    'tests/msql2.t'         => 'mSQL1/t/msql2.t',
	    'nodbd/nodbd.pm.in'     => 'mSQL1/lib/Msql1.pm',
	    'nodbd/statement.pm.in' => 'mSQL1/lib/Msql1/Statement.pm',
	    }
    };

    $self->{'lc_dbd_driver'} = lc $self->{'dbd_driver'};
    $self->{'uc_dbd_driver'} = uc $self->{'dbd_driver'};
    $self->{'lc_nodbd_driver'} = lc $self->{'nodbd_driver'};
    $self->{'uc_nodbd_driver'} = uc $self->{'nodbd_driver'};
    $self->{'test_dsn'} = sprintf("DBI:%s:database=%s%s",
				  $self->{'dbd_driver'},
				  $self->{'test_db'},
				  $self->{'test_host'} ?
				      (';host=' . $self->{'test_host'}) : '');

    bless($self, $class);
    $self;
}


1;
