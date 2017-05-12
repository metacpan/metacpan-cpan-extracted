#!/usr/bin/perl
use strict;
use warnings;
use File::Slurp;
use Template::Alloy;
use File::Find;
use Data::Dumper;
use Locale::PO;
use Encode;
use Storable;
use MLDBM::Sync;
use MLDBM qw(MLDBM::Sync::SDBM_File Storable);
use Fcntl qw(:DEFAULT :flock);

my $fname;
my $dir;
my $unknown_msgid_db;

for (my $i = 0 ; $i < @ARGV ; ++$i) {
	if ($ARGV[$i] =~ /^-/) {
		$ARGV[$i] =~ /^-dir/ && do {
			$dir = $ARGV[$i + 1];
			++$i;
		};
		$ARGV[$i] =~ /^-umdb/ && do {
			$unknown_msgid_db = $ARGV[$i + 1];
			++$i;
		};
	} else {
		$fname = $ARGV[$i];
	}
}

die <<USAGE unless $fname and $dir;
tt-scan-make-pot.pl [options] -dir <templates> outfilename
  -umdb <unknown_msgid_db>
USAGE

my @templates;

find(
	sub {
		my $lname = "$File::Find::dir/$_";
		push @templates, $lname if $lname =~ /\.(tt|html)$/;
	},
	$dir
);

my %msgids;

my $ltdir = (split '/', $dir)[-1];

for my $tmpl (@templates) {
	my $fname = "$ltdir/" . substr ($tmpl, 1 + length $dir);
	my $text      = read_file($tmpl, binmode => ':utf8');
	my $parsed    = Template::Alloy->dump_parse_tree($text);
	my @singulars = $parsed =~ m{\['m', \['(.*?)'[\],]}sg;
	push @singulars, $parsed =~ m{\['ml', \['(.*?)'[\],]}sg;
	my @plurals = $parsed =~ m{\['mn', \['(.*?)'[\],]}sg;
	push @plurals, $parsed =~ m{\['mnl', \['(.*?)'[\],]}sg;
	for (@singulars) {
		$msgids{$_}{source}{$fname} = undef;
		$msgids{$_}{form} = 'singular';
	}
	for (@plurals) {
		$msgids{$_}{source}{$fname} = undef;
		$msgids{$_}{form} = 'plural';
	}
}

if ($unknown_msgid_db) {
	my $sync_obj = tie (my %dbm, 'MLDBM::Sync', $unknown_msgid_db, O_CREAT | O_RDWR, 0666) or warn "$!";
	$sync_obj->Lock;
	for my $msgid (keys %dbm) {
		if (not exists $msgids{$msgid}) {
			$msgids{$msgid}{source}{unknown} = undef;
			$msgids{$msgid}{form} = $dbm{$msgid};
		}
	}
	$sync_obj->UnLock;
}

my @msgids = (
	new Locale::PO(
		-msgid  => '',
		-msgstr => "Project-Id-Version: \\n"
		  . "PO-Revision-Date: 1970-01-01 01:01 +0100\\n"
		  . "POT-Creation-Date: 1970-01-01 01:01 +0100\\n"
		  . "Last-Translator: name <name\@email.name>\\n"
		  . "Language-Team: \\n"
		  . "Language: English\\n"
		  . "MIME-Version: 1.0\\n"
		  . "Content-Type: text/plain; charset=UTF-8\\n"
		  . "Content-Transfer-Encoding: 8bit\\n"
		  . "Plural-Forms: nplurals=2; plural=(n != 1);\\n"
	)
);
for my $msgid (sort keys %msgids) {
	my @sources = keys %{$msgids{$msgid}{source}};
	my $lm;
	if ($msgids{$msgid}{form} eq 'plural') {
		$lm = Locale::PO->new(
			-msgid        => $msgid,
			-msgid_plural => $msgid,
			-msgstr_n     => {0 => '', 1 => ''},
		);
	} else {
		$lm = Locale::PO->new(
			-msgid  => $msgid,
			-msgstr => '',
		);
	}
	$lm->reference(join "\n", @sources);
	push @msgids, $lm;
}

Locale::PO->save_file_fromarray($fname, \@msgids);
