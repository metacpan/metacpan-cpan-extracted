#!/usr/bin/perl

use strict;
use warnings;
use File::Temp qw/tempfile/;
use Pod::Literate;
use Test::More tests=>6;

sub randword { my ($L)=@_; $L//=6; return join('',map {chr(int(97+rand(26)))} (1..$L)) }

subtest 'target set/get'=>sub {
	plan tests=>1;
	my $literate=Pod::Literate->new();
	my $name=randword();
	$literate->targetSet($name);
	is($literate->target(),$name,'round trip');
};

subtest 'section set/get'=>sub {
	plan tests=>1;
	my $literate=Pod::Literate->new();
	my ($name,$text)=(randword(),randword(64));
	$literate->sectionAppend($name,$text);
	is($literate->section($name),$text,'round trip');
};

subtest 'section reference matching'=>sub {
	plan tests=>2;
	my ($re);
	my $doc="one #< ONE ># one\ntwo #<TWO># two\n";
	$re=Pod::Literate::sectionRegexp('ONE'); $doc=~s/$re/AAA/g;
	is($doc,"one AAA one\ntwo #<TWO># two\n",'Replacement one');
	$re=Pod::Literate::sectionRegexp('TWO'); $doc=~s/$re/BBB/g;
	is($doc,"one AAA one\ntwo BBB two\n",'Replacement two');
};

subtest 'section references in code'=>sub {
	plan tests=>1;
	my $code=join("\n",
		q|#< bol >#|,
		q|  #< spaces >#|,
		q|#< dual A >##<dualB>#|,
		q|if(#< conditionA >#) { #<actionA># }|,
	);
	my %expect=map {$_=>1} ('bol','spaces','dual A','dualB','conditionA','actionA');
	my %seen=map {$_=>1} Pod::Literate::codeSectionNames($code);
	is_deeply(\%seen,\%expect,'All matched names');
};

subtest 'indentation'=>sub {
	plan tests=>5;
	my $uf=\&Pod::Literate::unindent;
	my $if=\&Pod::Literate::indent;
	#
	is(&$uf("space\n  one\n    two\n"),  "space\n  one\n    two\n",'Unindent:  Zero spaces');
	is(&$uf("  space\n  one\n    two\n"),"space\none\n  two\n",    'Unindent:  Two spaces');
	is(&$uf("\tspace\n\tone\n\t\ttwo\n"),"space\none\n\ttwo\n",    'Unindent:  One tab');
	#
	is(&$if("one\ntwo\nfoo\n",'  '),      "  one\n  two\n  foo\n",      'Indent:  Two spaces');
	is(&$if("one\n  two\n    foo\n","\t"),"\tone\n\t  two\n\t    foo\n",'Indent:  Tab');
};

subtest 'Tangling'=>sub {
	plan tests=>1;
	my ($tfh,$tfn)=tempfile(undef,UNLINK => 1);
	close($tfh);
	my $doc=qq|
=pod

=for literate target:$tfn

Some text.

=begin literate Header

	#!/usr/bin/perl
	use strict; use warnings;

=end literate

=for literate Say something in2resting

	print "Hello world!\\n";

=for literate .

=begin literate $tfn

	#< Header >#
	#< Say something in2resting >#

=end literate

=cut
|;
	#
	my $literate=Pod::Literate->new();
	$literate->accept_targets('literate');
	$literate->expand_verbatim_tabs(0);
	$literate->parse_string_document($doc);
	#
	my $result;
	{ open(my $fh,'<',$tfn); local($/); $result=<$fh>; close($fh); }
	is($result,
q|#!/usr/bin/perl
use strict; use warnings;
print "Hello world!\n";|,'Generated script');
};

