#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

use_ok( 'PkgForge::BuildCommand::Builder::RPM' );

use_ok( 'PkgForge::BuildCommand::Submitter::PkgSubmit' );

use_ok( 'PkgForge::BuildInfo' );

use_ok( 'PkgForge::BuildLog' );

use_ok( 'PkgForge::BuildCommand::Reporter::Email' );

use_ok( 'PkgForge::BuildCommand::Check::RPMLint' );

use_ok( 'PkgForge::PidFile' );

use_ok( 'PkgForge::Queue::Entry' );

use_ok( 'PkgForge::Queue' );

use_ok( 'PkgForge::Handler' );

use_ok( 'PkgForge::Handler::Buildd' );

use_ok( 'PkgForge::Handler::Incoming' );

use_ok( 'PkgForge::Handler::Initialise' );

use_ok( 'PkgForge::App::Buildd' );

use_ok( 'PkgForge::App::Incoming' );

use_ok( 'PkgForge::App::InitServer' );

use_ok( 'PkgForge::Daemon' );

use_ok( 'PkgForge::Daemon::Buildd' );

use_ok( 'PkgForge::Daemon::Incoming' );

done_testing;
