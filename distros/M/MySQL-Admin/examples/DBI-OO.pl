#!/usr/bin/perl -w
use strict;
use lib qw(../lib);
use DBI::Library;
use vars qw($db $m_sUser $host $password $m_hrSettings);
use MySQL::Admin;
use strict;
my $m_oCgi = MySQL::Admin->new();
$m_oCgi->init();
*m_hrSettings = \$MySQL::Admin::m_hrSettings;
print $m_oCgi->header;
my ( $dbi, $m_dbh ) = DBI::Library->new(
    {   name     => $m_hrSettings->{database}{name},
        host     => $m_hrSettings->{database}{host},
        user     => $m_hrSettings->{database}{user},
        password => $m_hrSettings->{database}{password},
    }
);
$dbi->addexecute(
    {   title       => 'select',
        description => 'show query',
        sql         => "select *from querys where `title` = ?",
        return      => "fetch_hashref",
    }
);
my $showQuery = $dbi->select('select');
local $/ = "<br/>\n";

foreach my $key ( keys %{$showQuery} ) {
    print "$key: ", $showQuery->{$key}, $/;
}
use showsource;
&showSource($0);

