#!/usr/bin/perl -w
use strict;
use CPANPLUS;
use Data::Dumper;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Module::CPANTS::Generator::Backpan;
use Module::CPANTS::Generator::Files;
use Module::CPANTS::Generator::ModuleInfo;
use Module::CPANTS::Generator::Pod;
use Module::CPANTS::Generator::Prereq;
use Module::CPANTS::Generator::Testers;
use Module::CPANTS::Generator::Unpack;
use Module::CPANTS::Generator::Uses;
use Storable;
use Template;

my $version = "0.20030806";

my $unpacked = "$FindBin::Bin/../unpacked/";

my $cpanplus = CPANPLUS::Backend->new(conf => {verbose => 0, debug => 0});
$cpanplus->reload_indices(update_source => 1);

# delete entire cpants data

my $data = {};
eval {
  $data = retrieve("cpants.store");
};
delete $data->{cpants};
store($data, "cpants.store");

if (-d $unpacked) {
  print "* Using existing unpacked CPAN\n";
} else {
  print "* Unpacking CPAN...\n";
  my $u = Module::CPANTS::Generator::Unpack->new;
  $u->cpanplus($cpanplus);
  $u->directory($unpacked);
  $u->unpack;
}

print "* Generating POD info...\n";
my $p = Module::CPANTS::Generator::Pod->new;
$p->directory($unpacked);
$p->generate; # works

print "* Generating Uses info...\n";
my $u = Module::CPANTS::Generator::Uses->new;
$u->cpanplus($cpanplus);
$u->directory($unpacked);
$u->generate;

print "* Generating CPAN testers info...\n";
my $t = Module::CPANTS::Generator::Testers->new;
$t->directory($unpacked);
$t->generate; # works

print "* Generating module info...\n";
my $m = Module::CPANTS::Generator::ModuleInfo->new;
$m->cpanplus($cpanplus);
$m->directory($unpacked);
$m->generate; # works

print "* Generating Backpan info...\n";
my $b = Module::CPANTS::Generator::Backpan->new;
$b->cpanplus($cpanplus);
$b->directory($unpacked);
$b->generate; # works

print "* Generating module prerequisites...\n";
$p = Module::CPANTS::Generator::Prereq->new;
$p->cpanplus($cpanplus);
$p->directory($unpacked);
$p->generate; # works

print "* Generating file info...\n";
my $f = Module::CPANTS::Generator::Files->new;
$f->directory($unpacked);
$f->generate; # works

print "* Generating CPANTS.pm...\n";
my $cpants = retrieve("cpants.store") || die;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Indent = 0;
$data = 'my ' . Data::Dumper->Dump([$cpants->{cpants}], [qw(cpants)]);

my $vars = {
  cpants => $data,
  version => $version,
};

my $tt = Template->new();
$tt->process('Module-CPANTS/lib/Module/CPANTS.tt', $vars, 'Module-CPANTS/lib/Module/CPANTS.pm')
  || die $tt->error(), "\n";

print "* All done\n";
