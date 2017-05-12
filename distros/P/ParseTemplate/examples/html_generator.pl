#!/usr/local/bin/perl -w

require 5.004; 
use strict;
use Parse::Template;

my $T = new Parse::Template('HTML' => '%%"<$part>" . $N . HEAD() . $N . BODY() . $N . "</$part>$N"%%',
			    'HEAD' => '%%"<$part>" . $N . "</$part>$N"%%',
			    'BODY' => '<BODY>%%$N . CONTENT() . "$N</BODY>"%%',
			    'CONTENT' => '<p>A very simple document: %%ORDERED_LIST(0)%%',
			    'ORDERED_LIST' =>
			    q!%%$_[0] < 4 ? "$N<OL><li>$_[0]" . ORDERED_LIST($_[0] + 1) . "<li>$_[0]$N</OL>$N" : ''%%!,
			   );
$T->env('N' => "\n");
print $T->eval('HTML');

my $ELT_CONTENT = q!%%join '', @_%%!;
my $HTML_T1 = new Parse::Template(
			    'DOC' => '%%H1(B("text in bold"), I("text in italic"))%%',
			    'H1' => qq!<H1>$ELT_CONTENT</H1>!,
			    'B' => qq!<b>$ELT_CONTENT</b>!,
			    'I' => qq!<i>$ELT_CONTENT</i>!,
			   );

print $HTML_T1->eval('DOC'), "\n";

$ELT_CONTENT = q!%%"<$part>" . join('', @_) . "</$part>"%%!;
my $HTML_T2 = new Parse::Template(
			    'DOC' => '%%H1(B("text in bold"), I("text in italic"))%%',
			    'H1' => qq!$ELT_CONTENT!,
			    'B' => qq!$ELT_CONTENT!,
			    'I' => qq!$ELT_CONTENT!,
			   );
print $HTML_T2->eval('DOC'), "\n";

my $DOC = q!H1(B("text in bold"), I("text in italic"))!;

$ELT_CONTENT = q!%%"<$part>" . join('', @_) . "</$part>"%%!;
my $HTML_T3 = new Parse::Template(
				  'DOC' => qq!%%$DOC%%!,
				  map { $_ => $ELT_CONTENT } qw(H1 B I)
				 );
print $HTML_T3->eval('DOC'), "\n";


$ELT_CONTENT = q!%%shift(@_); "<$part>" . join('', @_) . "</$part>"%%!;
my $HTML_T4 = new Parse::Template(map { $_ => $ELT_CONTENT } qw(H1 B I));
print $HTML_T4->H1(
		   $HTML_T4->B("text in bold"), 
		   $HTML_T4->I("text in italic")
	    ), "\n";

