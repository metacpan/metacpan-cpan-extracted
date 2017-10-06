#!/usr/bin/env perl

use v5.10;

use strict;
use warnings;

use Test::More;

use File::Basename;
use File::Spec;
use OTRS::OPM::Installer::Utils::File;
use HTTP::Tiny;
use HTTP::Tiny::FileProtocol;

$OTRS::OPM::Installer::Utils::File::ALLOWED_SCHEME = 'file';
$OTRS::Repository::ALLOWED_SCHEME = 'file';
$OTRS::Repository::Source::ALLOWED_SCHEME = 'file';

my $repo = File::Spec->rel2abs(
    File::Spec->catdir( dirname( __FILE__ ), 'repo' ),
);

my $repo_url = "file://$repo";

my $file = OTRS::OPM::Installer::Utils::File->new(
    repositories => [ $repo_url ],
    package      => 'ActionDynamicFieldSet',
    otrs_version => 'hello',
    rc_config    => {},
);

isa_ok $file, 'OTRS::OPM::Installer::Utils::File';

my $path = $file->resolve_path;
is $path, undef;

done_testing();
