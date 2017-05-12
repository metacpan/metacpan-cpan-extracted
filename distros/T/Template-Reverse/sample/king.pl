#!/usr/bin/env perl 
# try this!!
use lib qw(../lib);
use Template::Reverse;
use Template::Reverse::Converter::TT2;
use Data::Dumper;
 
my $rev = Template::Reverse->new;
 
# generating patterns automatically!!
my $str1 = ['I',' ','am',' ', 'perl',' ','and',' ','smart']; # White spaces should be explained explicity.
my $str2 = ['I',' ','am',' ', 'khs' ,' ','and',' ','a',' ','perlmania']; # Use Parse::Lex or Parse::Token::Lite to make it easy.
my $parts = $rev->detect($str1, $str2);
 
my $tt2 = Template::Reverse::Converter::TT2->new;
my $templates = $tt2->Convert($parts); # equals to ['I am [% value %] and ',' and [% value %]']

my $str3 = "I am king of the world and a richest man";
 
# extract!!
use Template::Extract;
my $ext = Template::Extract->new;

foreach my $tmpl (@{$templates}){
    my $value = $ext->extract($tmpl, $str3);
    print $value->{value}."\n"; # output : {'value'=>'king of the world'}
}
 
