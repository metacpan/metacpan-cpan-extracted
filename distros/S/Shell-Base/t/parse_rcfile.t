#!/usr/bin/perl -w
# vim: set ft=perl:

use strict;

use Test::More;
use Shell::Base;
use File::Temp qw(tempfile);

plan tests => 8;

my ($tmpfh, $tmp) = tempfile("sbXXXXXX", UNLINK => 1);

print $tmpfh <<'TMP';
name ="Darren Chamberlain"
email= "darren@cpan.org"
Date = "Tue Mar 18 17:52:14 EST 2003"
TMP

close $tmpfh;   # Is closing this ok?

my %config = Shell::Base->parse_rcfile($tmp);
is(keys %config,     3,                                 "3 elements");
is($config{'name'},  '"Darren Chamberlain"',            "\$config{name} => $config{name}");
is($config{'email'}, '"darren@cpan.org"',               "\$config{email} => $config{email}");
is($config{'date'},  '"Tue Mar 18 17:52:14 EST 2003"',  "\$config{date} => $config{date}");
is($config{'Date'},  undef,                             "\$config{Date} => not defined");

package New::Package;
use base qw(Shell::Base);

sub parse_rcfile {
    my ($self, $rcfile) = @_;
    my @lines = ();
    my $c = 0;
    local *F;

    open F, $rcfile or die "Can't open $rcfile: $!";
    while (defined(my $l = <F>)) {
        chomp $l;
        push @lines, $l;
    }
    close F or die "Can't close $rcfile: $!";

    return map { ++$c => $_ } @lines;
}

package main;

%config = New::Package->parse_rcfile($tmp);
is($config{1} => 'name ="Darren Chamberlain"',           "$config{1} => 'name = \"Darren Chamberlain\"'");
is($config{2} => 'email= "darren@cpan.org"',             "$config{2} => 'email = \"darren\@cpan.org\"'");
is($config{3} => 'Date = "Tue Mar 18 17:52:14 EST 2003"', "$config{3} => 'Date = \"Tue Mar 18 17:52:14 EST 2003\"'");
