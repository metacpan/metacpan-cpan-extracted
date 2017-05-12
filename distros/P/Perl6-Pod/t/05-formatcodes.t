#===============================================================================
#
#  DESCRIPTION:  Test format codes
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zag@cpan.org>
#===============================================================================


package main;
use strict;
use warnings;
use Data::Dumper;
use v5.10;
use Regexp::Grammars;
use  Perl6::Pod::Codeactions;
use Perl6::Pod::Grammars;
use Test::More tests => 16;    # last test to print

sub parse_para {
    my $src = shift;
    use Perl6::Pod::Utl;
    return Perl6::Pod::Utl::parse_para($src);
}

my @grammars;
#### test L<>
is parse_para('L<http://example.com>')->[0]->{scheme},'http:', 'L: scheme http://example.com';
#=pod 
my $t1 = parse_para('L<http://example.com/test#test>')->[0];
#print Dumper $t1;exit;
is $t1->{section}, 'test', 'L: section';
ok $t1->{is_external}, 'L: external';

$t1 = parse_para('L<#test>')->[0];
is $t1->{section}, 'test', 'L: only section';

$t1 = parse_para('L<text | #test>')->[0];
is $t1->{alt_text}, 'text', 'L: alternate text';

$t1  = parse_para('L<mailto:devnull@rt.cpan.org>')->[0];
is $t1->{scheme},'mailto:','L: mailto';

$t1 = parse_para('L<issn:1087-903X>')->[0];
is $t1->{scheme},'issn:','L: issn';

$t1 = parse_para('L<OK |file://sdsd/config#test>')->[0];
is $t1->{scheme},'file:','L: file';

$t1 = parse_para('L<file:./cpan.org >
B<sd > L<< haname | http:perl.html  >>')->[0];
is $t1->{scheme},'file:','L: L<> L<|>';
$t1 = parse_para('L<B<test1>|http://example.com> test')->[0];
is $t1->{alt_text}, 'B<test1>','nested formatting codes';

$t1 = parse_para('X< array >')->[0];
is $t1->{text}, $t1->{entry}, 'X<array>';
is $t1->{text}, 'array', 'check text X<array>';
$t1 = parse_para('X< arrays | array1, array2; use array >')->[0];
is @{$t1->{entries}}, 2, "more than one entries";
is $t1->{text}, 'arrays', 'check text: X< arrays | array1, array2; use array >';
$t1 = parse_para('X<| array1, array2; use array >')->[0];
is $t1->{text},'', 'empty text';
$t1 = parse_para('P<http://example.com>')->[0];
is $t1->{'scheme'},'http:', 'P: scheme';

