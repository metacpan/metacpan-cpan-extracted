#!/usr/bin/env perl

use v5.10;

use strict;
use warnings;

use Test::More;

use File::Basename;
use File::Spec;
use OPM::Installer::Utils::File;
use HTTP::Tiny;
use HTTP::Tiny::FileProtocol;

diag "Testing *::File version " . OPM::Installer::Utils::File->VERSION();

my $repo = File::Spec->rel2abs(
    File::Spec->catdir( dirname( __FILE__ ), 'repo' ),
);

my $repo_url = "file://$repo";

my $file = OPM::Installer::Utils::File->new(
    repositories      => [ $repo_url ],
    package           => 'TicketOverviewHooked',
    framework_version => '5.0.20',
    rc_config         => {},
);

isa_ok $file, 'OPM::Installer::Utils::File';

my $path = $file->resolve_path;
is -s $path, -s "$repo/TicketOverviewHooked-5.0.6.opm";

my %urls = qw(
  https://opar.perl-services.de/download/1424                 1
  https://localhost/download/1424                             1
  https://127.0.0.1/download/1424                             1
  http://ftp.app.org/pub/itsm/packages5/ITSMCore-5.0.19.opm   1
  thisIsATest.opm                                             0
  /tmp/test-1.1.1.opm                                         0
  file:///tmp/test-1.1.1.opm                                  1
);

for my $url ( sort keys %urls ) {
  my $result = $file->_is_url( $url );
  ok +( $urls{$url} ? $result : !$result ), "$url _is_url";
}

done_testing();
