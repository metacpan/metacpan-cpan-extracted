package TestModule;
use strict;
use warnings;
use LWP::UserAgent;

# constants are subs, so we need to not mock them (at least for now)
use constant 'TEST_CONSTANT', 42;

# sub_one is not mocked, while sub_two is in SimpleMock::Mocks::TestModule
# (just for the test)
sub sub_one { 'one'; }
sub sub_two { 'two'; }

# used in test for SimpleMock::Model::SUBS
sub sub_three { 'three'; }
sub sub_four { 'four'; }
sub sub_five { 'five'; }
sub sub_six { 'six'; }

sub run_db_query {
    my ($placeholder_arg) = @_;
    my $dbh = DBI->connect('dbi:SQLite::memory:', '', '', { RaiseError => 1, PrintError => 0 });
    my $sth = $dbh->prepare('SELECT name, email FROM user where name like=?');
    $sth->execute($placeholder_arg);
    return $sth->fetchall_arrayref();
}

my $ua = LWP::UserAgent->new;
sub fetch_url {
    my ($url) = @_;
    return $ua->get($url);
}

1;
