use strict;
use warnings;
use utf8;
use Test::More;
use Test::Requires 'DBD::SQLite', 'Teng';

use DBI;
use File::Temp qw/tempdir/;
use File::Path qw/mkpath/;
use File::Spec;
use SQL::Translator;
use SQL::Translator::Producer::Teng;

{
    package t::Util::Teng;
    use parent 'Teng';
}

my $dir; {
    $dir = tempdir(CLEANUP => 1);
    push @INC, $dir;
    mkpath( File::Spec->catdir($dir, 't', 'Util', 'Teng') );
}

my $dbh = DBI->connect('dbi:SQLite::memory:','','',{RaiseError => 1, PrintError => 0, AutoCommit => 1});
my $source = do {local $/; open my $fh, '<', 't/data/sqlite.sql' or die $!; <$fh>};
for my $stmt (split /;/, $source) {
    next unless $stmt =~ /\S/;
    $dbh->do($stmt) or die $dbh->errstr;
}

my $translator = SQL::Translator->new;
$translator->parser('SQLite') or die $translator->error;
$translator->translate('t/data/sqlite.sql') or die $translator->error;
$translator->producer('Teng', package => 't::Util::Teng::Schema');
my $translate = $translator->translate;

{
    open my $fh, '>', File::Spec->catfile($dir, qw/t Util Teng/, 'Schema.pm') or die $!;
    print $fh $translate;
    close $fh;
}

my $db = t::Util::Teng->new(dbh => $dbh);
my $row = $db->insert(branch => {
    project => 'teng',
    branch  => 'master',
    ctime   => '2050-11-11 00:00:00',
});

isa_ok $row, 't::Util::Teng::Row::Branch';
is $row->project, 'teng';
my $insert_id = $row->branch_id;

my $row2 = $db->single(branch => {branch_id => $insert_id});
is $row2->project, 'teng';
is $row2->ctime, '2050-11-11 00:00:00';

done_testing;
