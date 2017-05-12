package author::Util;

use strict;
use warnings;
use Exporter 5.57 qw/import/;
use Data::Dump qw/dump/;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Perl::PrereqScanner::NotQuiteLite;
use Path::Tiny;
use Time::HiRes qw/time/;
use Time::Piece;
use Log::Handler;
use Package::Abbreviate;

our @EXPORT = qw/
  dump log path say scan tmpdir
  load_competitors setup_benchmarkers
/;

my $ROOT = path("$FindBin::Bin/../");
my $START = time;

my $LOGGER = Log::Handler->new(
  screen => { maxlevel => "info", minlevel => "alert", message_layout => "%T [%L] %m", timeformat => '%H:%M:%S' },
  file => { maxlevel => "notice", minlevel => "notice", message_layout => "%T [%L] %m", filename => tmpdir('log')->child('scan.log'), timeformat => '%H:%M:%S' }
,
  file => { maxlevel => "warn", minlevel => "error", message_layout => "%T [%L] %m", filename => tmpdir('log')->child('scan.err'), timeformat => '%H:%M:%S' },
);

sub say (@) { print @_, "\n" }
sub scan { Perl::PrereqScanner::NotQuiteLite->new->scan_file(@_) }

sub tmpdir {
  my $name = shift;
  my $dir = $ROOT->child("tmp/$name");
  $dir->mkpath unless -d $dir;
  $dir;
}

sub log (@) { $LOGGER->log(@_) }

sub load_scanners {
  my %modules;

  $modules{'Perl::PrereqScanner::NotQuiteLite'} = 'scan_file';

  if (eval "require Perl::PrereqScanner") {
    $modules{'Perl::PrereqScanner'} = 'scan_file';
  } else { say "Perl::PrereqScanner is not installed" }

  if (eval "require Perl::PrereqScanner::Lite") {
    $modules{'Perl::PrereqScanner::Lite'} = 'scan_file';
  } else { say "Perl::PrereqScanner::Lite is not installed" }

  if (eval "require Module::ExtractUse") {
    $modules{'Module::ExtractUse'} = 'extract_use';
  } else { say "Module::ExtractUse is not installed" }

  \%modules;
}

sub setup_benchmarkers {
  my $target = shift;
  my $scanners = load_scanners();
  my %benchmarkers;
  my $pkg_abbr = Package::Abbreviate->new(20);
  for my $scanner (keys %$scanners) {
    my $method = $scanners->{$scanner};
    $benchmarkers{$pkg_abbr->abbr($scanner)} = sub {
      my $p = $scanner->new;
      $p->$method($target);
    };
  }
  \%benchmarkers;
}

END {
  say "----------------------------------";
  say("START: ".Time::Piece->new($START)->strftime('%Y-%m-%d %H:%M:%S'));
  say("END: ".Time::Piece->new->strftime('%Y-%m-%d %H:%M:%S'));
}

1;
