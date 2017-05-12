#!/usr/bin/perl

use strict;
use lib './blib/lib/';

die "Please run \"perl Build.PL && ./Build\" first\n" unless -d './blib/lib/';

## Choose readline module
print
"Which readline module do you want to use ?
a) Zoid
b) Perl
c) Gnu
choiche [a]: ";

my $a = <STDIN>;
chomp $a;
$a ||= 'a';

# load readline
$ENV{PERL_RL} = 
	($a eq 'a') ? 'Zoid' :
	($a eq 'b') ? 'Perl' :
	($a eq 'c') ? 'Gnu'  : die "No such choiche: $a\n" ;

print "\$ENV{PERL_RL} = '$ENV{PERL_RL}'\n";

eval 'use Term::ReadLine';
die $@ if $@;

## Application start
my $term = new Term::ReadLine 'Simple Perl eval';

print 'using readline package: '.$term->ReadLine."\n";

$term->addhistory($_) for
	q/system 'ls -al'/,
	q/system 'ls'/,
	q/3*3/ ;

my $prompt = "Enter an expression: ";
if (eval "use Env::PS1; 1") {
	$ENV{PS1} = '\C{red}Enter an expression \u\$\C{reset} ';
	tie $prompt, 'Env::PS1', 'PS1';
}

my $OUT = $term->OUT || \*STDOUT;
while ( defined ($_ = $term->readline($prompt)) ) {
	my $res = eval($_);
	warn $@ if $@;
	print $OUT $res, "\n" unless $@;
	$term->addhistory($_)
		if /\S/ and ! $term->Attribs->{autohistory};
}

__END__

=head1 NAME

example.pl - a simple readline application

=head1 DESCRIPTION

This script implements the most simple eval loop around a readline input.
It start with giving the user a choiche which readline module to use,
off course real applications would not do this and just suppose the user to
set his environment correctly.

=cut
