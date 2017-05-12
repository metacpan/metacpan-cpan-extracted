#!/usr/bin/perl -w
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
#
# Copyright 2002-2017 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# Lesser General Public License Version 3 or the Perl Artistic License Version 2.0.

use strict;
use Test::More;
use Cwd;

BEGIN { plan tests => 37 }
BEGIN { require "./t/test_utils.pl"; }

our $Debug;

use SVN::S4::Getopt;
ok(1,'use');

$SVN::S4::Getopt::Debug = $Debug;

my $opt = new SVN::S4::Getopt;
ok(1,'new');

my %hash = $opt->hashCmd("di", "-r", "2:3", "--password", "PW", "frev", "frev2");
use Data::Dumper; print Dumper(\%hash) if $Debug;
ok ($hash{'--revision'}
    && $hash{revision}[0]  eq '2:3'
    && $hash{pathorurl}[0] eq 'frev'
    && $hash{pathorurl}[1] eq 'frev2'
    && $hash{password}[0]  eq 'PW');

my @cmd = $opt->formCmd("update", { quiet=>1, revision=>1234,
				    depth=>6, ignore_me=>1234,
				    path=>["p1","p2"] });
is_deeply (\@cmd,
	   ['update',
	    '--depth', 6,
	    '--quiet',
	    '--revision', 1234,
	    'p1', 'p2'],
	   "formCmd");

ck('add      --targets FILENAME --non-recursive --quiet --config-dir DIR --auto-props --no-auto-props --force PATH');
ck('blame    --revision REV --username USER --password PASS --no-auth-cache --non-interactive --config-dir DIR --verbose --force --extensions ARGS PATH');
ck('cat      --revision REV --username USER --password PASS --no-auth-cache --non-interactive --config-dir DIR PATH');
ck('checkout --revision REV --quiet --non-recursive --username USER --password PASS --no-auth-cache --non-interactive --ignore-externals --config-dir DIR URL PATH');
ck('cleanup  --diff3-cmd CMD --config-dir DIR PATH');
ck('commit   --message TEXT --file FILE --quiet --no-unlock --non-recursive --targets FILENAME --force-log --username USER --password PASS --no-auth-cache --non-interactive --encoding ENC --config-dir DIR PATH');
ck('copy     --message TEXT --file FILE --revision REV --quiet --username USER --password PASS --no-auth-cache --non-interactive --force-log --editor-cmd EDITOR --encoding ENC --config-dir DIR SRC DST');
ck('delete   --force --force-log --message TEXT --file FILE --quiet --targets FILENAME --username USER --password PASS --no-auth-cache --non-interactive --editor-cmd EDITOR --encoding ENC --config-dir DIR PATHORURL');
ck('diff     --revision REVS --old OLDPATH --new NEWPATH --extensions ARGS --non-recursive --diff-cmd CMD --notice-ancestry --username USER --password PASS --no-auth-cache --non-interactive --no-diff-deleted --config-dir DIR --change REV --summarize -u -b -w --ignore-eol-style PATHORURL');
ck('export   --revision REV --quiet --force --username USER --password PASS --no-auth-cache --non-interactive --non-recursive --config-dir DIR --native-eol EOL --ignore-externals PATHORURL PATH');
ck('help     --version --quiet --config-dir DIR SUBCOMMAND');
ck('import   --message TEXT --file FILE --quiet --non-recursive --username USER --password PASS --no-auth-cache --non-interactive --force-log --editor-cmd EDITOR --encoding ENC --config-dir DIR --auto-props --no-auto-props --ignore-externals PATH URL');
ck('info     --revision --recursive --targets FILENAME --incremental --xml --username USER --password PASS --no-auth-cache --non-interactive --config-dir DIR PATH');
ck('list     --revision REV --verbose --recursive --incremental --xml --username USER --password PASS --no-auth-cache --non-interactive --config-dir DIR PATH');
ck('lock     --targets FILENAME --message TEXT --file FILE --force-log --encoding ENC --username USER --password PASS --no-auth-cache --non-interactive --config-dir DIR --force PATH');
ck('log      --revision REV --quiet --verbose --targets FILENAME --stop-on-copy --incremental --limit NUM --xml --username USER --password PASS --no-auth-cache --non-interactive --config-dir DIR PATHORURL PATH');
ck('merge    --revision REV --non-recursive --quiet --force --dry-run --diff3-cmd CMD --ignore-ancestry --username USER --password PASS --no-auth-cache --non-interactive --config-dir DIR --extensions ARGS --change REV PATHORURL');
ck('mkdir    --message TEXT --file FILE --quiet --username USER --password PASS --no-auth-cache --non-interactive --editor-cmd EDITOR --encoding ENC --force-log --config-dir DIR PATHORURL');
ck('move     --message TEXT --file FILE --revision REV --quiet --force --username USER --password PASS --no-auth-cache --non-interactive --editor-cmd EDITOR --encoding ENC --force-log --config-dir DIR SRC DST');
ck('propdel  --quiet --recursive --revision REV --revprop --username USER --password PASS --no-auth-cache --non-interactive --config-dir DIR PROPNAME PATHORURL');
ck('propedit --revision REV --revprop --username USER --password PASS --no-auth-cache --non-interactive --encoding ENC --editor-cmd EDITOR --config-dir DIR PROPNAME PATHORURL');
ck('propget  --recursive --revision REV --revprop --strict --username USER --password PASS --no-auth-cache --non-interactive --config-dir DIR PROPNAME PATHORURL');
ck('proplist --verbose --recursive --revision REV --quiet --revprop --username USER --password PASS --no-auth-cache --non-interactive --config-dir DIR PROPNAME PATHORURL');
ck('propset  --file FILE --quiet --revision REV --targets FILENAME --recursive --revprop --username USER --password PASS --no-auth-cache --non-interactive --encoding ENC --force --config-dir DIR PROPNAME PATHORURL');
ck('resolved --targets FILENAME --recursive --quiet --config-dir DIR PATH');
ck('revert   --targets FILENAME --recursive --quiet --config-dir DIR PATH');
ck('status   --show-updates --verbose --non-recursive --quiet --no-ignore --username USER --password PASS --no-auth-cache --non-interactive --config-dir DIR --ignore-externals PATH');
ck('switch   --relocate --revision REV --non-recursive --quiet --diff3-cmd CMD --relocate FROM TO --username USER --password PASS --no-auth-cache --non-interactive --config-dir DIR PATH');
ck('unlock   --targets FILENAME --username USER --password PASS --no-auth-cache --non-interactive --config-dir DIR --force PATH');
ck('update   --revision REV --non-recursive --quiet --diff3-cmd CMD --username USER --password PASS --no-auth-cache --non-interactive --config-dir DIR --ignore-externals PATH');

ck_deep('co -N --username USER url@12345 PATH',
	{'--non-recursive' => 1,
	 '--username' => 1,
	 'url' => [ 'url', 'PATH' ],
	 'urlrev' => [ '12345', undef ],
	 'username' => [ 'USER' ]
	 });

ck_deep('co -N --username USER url@12345@ PATH',
	{'--non-recursive' => 1,
	 '--username' => 1,
	 'url' => [ 'url@12345@', 'PATH' ],
	 'urlrev' => [ undef, undef ],
	 'username' => [ 'USER' ]
	 });

ck_deep('merge -c -1234 FILENAME',
	{'pathorurl' => [ 'FILENAME' ],
	 'change' => [ '-1234' ],
	 '--change' => 1,
	 'pathorurlrev' => [ undef ],
	});

sub ck {
    my $cmd = shift;
    print "\t$cmd\n" if $Debug;
    my %hash = $opt->hashCmd(split /[ \t]+/, $cmd);
    use Data::Dumper; print Dumper(\%hash) if $Debug;
    ok (\%hash, "Hash for $cmd");
}

sub ck_deep {
    my $cmd = shift;
    my $deeply = shift;
    print "\t$cmd\n" if $Debug;
    my %hash = $opt->hashCmd(split /[ \t]+/, $cmd);
    use Data::Dumper; print Dumper(\%hash) if $Debug;
    is_deeply (\%hash, $deeply, "Hash for $cmd");
}
