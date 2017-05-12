#!/usr/bin/perl
use strict;
use warnings;
use lib 't';

use File::Temp qw/tempfile/;
use Test::More tests => 20;

our ($section_1, $section_2, $section_3, $section_4, %options);

sub handle_item {
	my ($options, $description) = m/^(.*?)\n\n(.*)/s;
	my (@options, $longest);
	$longest = "";
	for my $option ($options =~ m/\G((?:-\w|--\w+))(?:,\s*)?/g) {
		push @options, $option;
		$longest = $option if length $option > length $longest
	}
	$longest =~ s/^-*//;
	$options{$longest} = {
		options => \@options,
		description => $description,
	};
}

sub run_parser {
	Pod::Constants->import(
		section_1 => \$section_1,
		-trim     => 1,
		section_2 => \$section_2,
		section_3 => sub { tr/[a-z]/[A-Z]/; $section_3 = $_ },
		section_4 => sub { eval },
		'GUI parameters'  => sub {
			Pod::Constants::delete_hook('*item')
		},
		'command line parameters' => sub {
			Pod::Constants::add_hook('*item' => \&handle_item)
		});
}

use_ok('Pod::Constants');
run_parser;

ok $Pod::Constants::VERSION, "Pod::Constants sets its own VERSION";

# to avoid a warning
if ( 0 ) { $Cheese::foo = $ReEntrancyTest::wohoo = $Cheese::quux; }
eval 'use Cheese';

is($section_1, "Down with Pants!\n\n", "no trim from main");
is($section_2, "42", "with trim from main");
is($section_3, "CLANK_EST", "sub");
is($section_4, "touche", "eval");
is($Cheese::foo, "detcepxe", "From module");
is($ReEntrancyTest::wohoo, "Re-entrancy works!", "From module");
is($Cheese::quux, "Blah.", "From module(2)");
like(`$^X -c t/Cheese.pm 2>&1`, qr/syntax OK/, "perl -c module");
like(`$^X -c t/cheese.pl 2>&1`, qr/syntax OK/, "perl -c script");

# test the examples on the man page :)
package Pod::Constants;
Pod::Constants->import (SYNOPSIS => sub {
    $main::section_1 = join "\n", map { s/^ //; $_ } split /\n/, $_
});

package main;
# why define your test results when you can read them in from POD?
$section_1 =~ s/myhash\)/myhash, %myhash2)/;
$section_1 =~ s/myhash;/myhash, "%myhash\'s value after the above:" => sub { %myhash2 = eval };/;

my ($fh, $file) = tempfile 'pod-constants-testXXXX', TMPDIR => 1, UNLINK => 1;
print $fh <<"EOF";
package TestManPage;
$section_1;
1
EOF
close $fh;

$INC{'TestManPage.pm'} = $file;
require $file;

is $TestManPage::myvar, 'This string will be loaded into $myvar',"man page example 1";
is $TestManPage::VERSION, $Pod::Constants::VERSION, "man page example 2";
ok $TestManPage::VERSION, "man page example 2 cross-check";
is $TestManPage::myarray[2], 'For example, this is $myarray[2].', "man page example 3";

my $ok = 0;
while (my ($k, $v) = each %TestManPage::myhash) {
    if (exists $TestManPage::myhash2{$k}) { $ok ++ };
    if ($v eq $TestManPage::myhash2{$k}) { $ok ++ };
}

is $ok, 4, "man page example 4";
is scalar keys %TestManPage::myhash, 2, "man page example 4 cross-check";
is $TestManPage::html, '<p>This text will be in $html</p>', "man page example 5";

# supress warnings
$TestManPage::myvar = $TestManPage::html = undef;
@TestManPage::myarray = ();

is $options{foo}->{options}->[0], "-f", "Pod::Constants::add_hook";
ok !exists $options{gtk}, 'Pod::Constants::remove_hook';

=head2 section_1

Down with Pants!

=head2 section_2

42

=head2 section_3

clank_est

=head2 section_4

$section_4 = "touche"

=cut

=head1 command line parameters

the following command line parameters are supported

=item -f, --foo

This does something cool.

=item -h, --help

This also does something pretty cool.

=head1 GUI parameters

the following GUI parameters are supported

=item -g, --gtk

Use a GTK+ look-and-feel

=item -q, --qt

Use a Qt look-and-feel

=cut
