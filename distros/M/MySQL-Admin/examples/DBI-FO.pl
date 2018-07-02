#!/usr/bin/perl
use strict;
use lib qw(../lib);
use DBI::Library qw(:all );
use vars qw($db $m_sUser $host $password $m_hrSettings);
use MySQL::Admin qw(header init);
init('../config/settings.pl');
*m_hrSettings = \$MySQL::Admin::m_hrSettings;
print header;
my $m_dbh = initDB(
    {
        name     => $m_hrSettings->{database}{name},
        host     => $m_hrSettings->{database}{host},
        user     => $m_hrSettings->{database}{user},
        password => $m_hrSettings->{database}{password},
    }
);
addexecute(
    {
        title       => 'select',
        description => 'show query',
        sql         => "select *from querys where `title` = ?",
        return      => "fetch_hashref",
    }
);
my $showQuery = useexecute( 'select', 'select' );
local $/ = "<br/>\n";

foreach my $key ( keys %{$showQuery} ) {
    print "$key: ", $showQuery->{$key}, $/;
} ## end foreach my $key ( keys %{$showQuery...})
use showsource;
&showSource($0);
