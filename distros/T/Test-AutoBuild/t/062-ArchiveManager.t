# -*- perl -*-

use Test::More tests => 13;
use warnings;
use strict;
use Log::Log4perl;

BEGIN {
  use_ok("Test::AutoBuild::ArchiveManager");
}

Log::Log4perl::init("t/log4perl.conf");


SIMPLE: {
    my $result = MyArchiveManager->new(archives => [],
				       options => {
					   foo => "bar"
					   });
    isa_ok($result, "MyArchiveManager");

    is($result->option("foo"), "bar", "option foo has value bar");
    is($result->option("eek"), undef, "option eek has not value");

    $result->option("foo", "wizz");
    is($result->option("foo"), "wizz", "option foo now has value bar");
}

LIST: {
    my $now = time;
    my $less_than_one_week_ago = $now - (60*60*24*6);
    my $more_than_one_week_ago = $now - (60*60*24*8);
    my $man = MyArchiveManager->new(archives => [MyArchive->new(key => 1, created => $more_than_one_week_ago),
						 MyArchive->new(key => 2, created => $less_than_one_week_ago),
						 MyArchive->new(key => 3, created => $now)]);

    my @valid = $man->list_archives;
    is($#valid, 2, "two valid archives");
    is($valid[0]->key, 1, "valid archive has key 1");
    is($valid[1]->key, 2, "valid archive has key 2");
    is($valid[2]->key, 3, "valid archive has key 3");

    my @invalid = $man->list_invalid_archives;
    is($#invalid, 0, "one invalid archive");
    is($invalid[0]->key, 1, "invalid archive has key 2");

    my $prev = $man->get_previous_archive;
    isa_ok($prev, "MyArchive");
    is($prev->key, 2, "previous archive has key 2");
}

package MyArchiveManager;

use base qw(Test::AutoBuild::ArchiveManager);

sub init {
    my $self = shift;
    my %params = @_;

    $self->SUPER::init(@_);

    $self->{archives} = $params{archives};
}

sub list_archives {
    my $self = shift;
    return @{$self->{archives}};
}

package MyArchive;

use base qw(Test::AutoBuild::Archive);


sub size {
    my $self = shift;
    return 0;
}
