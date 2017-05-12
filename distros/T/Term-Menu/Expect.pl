#!/usr/bin/perl
use strict;

#### Make Term::Menu Object ######
## Needed for the other tests
use Term::Menu;
my $menu = new Term::Menu (
	delim	=> "",
	spaces	=> 0,
	beforetext => "",
	aftertext => "test: ",
	nooptiontext => "",
	moreoptions => "",
	tries => 1,
	toomanytries => "",
	hidekeys => 1,
);

#### Ask for an answer and print ok or error ######
## Test what happens if the good answer is given
my $return = $menu->menu(
	ok	=>	["","a"],
);
if (defined $return and $return eq $menu->lastval and $return eq "ok") {
	print "ok\n";
} else {
	print "error\n";
	exit;
}

##### Ask for an answer and print ok or error again ######
## Test what happens if a bad answer is given
my @pos_keys = (0..9,'a'..'z','A'..'Z');
$return = $menu->menu(
	ok	=>	["",@pos_keys],
);
if(!defined $return and !defined $menu->lastval) {
	print "ok\n";
} else {
	print "error\n";
	# DON'T exit here!
}

##### Print a normal question and print ok or error again ######
## Test the normal question
$return = $menu->question("test: ");
chomp $return if defined $return;
chomp (my $lastval = $menu->lastval);
if(defined $return and $return eq $lastval and $return eq "abcdefg") {
	print "ok\n";
} else {
	print "error\n";
	exit;
}

###### Test the order #####
$menu->setcfg(
        delim => ")",
        hidekeys => 0,
);
$return = $menu->menu(
        ok1 => ["", "a"],
        ok2 => ["", "b"],
);
chomp $return if defined $return;
chomp (my $lastval = $menu->lastval);
if(defined($return) and $return eq $lastval and $return eq "ok2") {
        print "ok\n";
} else {
        print "error\n";
        exit;
}

##### Quit #####
## Quit Expect interface
$return = $menu->question("test: ");
chomp $return if defined $return;
if(defined $return and $return eq "quit") {
	exit;
} else {
	print "error\n";
	exit;
}

