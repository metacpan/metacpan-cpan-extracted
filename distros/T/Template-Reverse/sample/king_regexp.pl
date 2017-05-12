#!/usr/bin/env perl 
# try this!!
use lib qw(../lib);
use Template::Reverse;
use Template::Reverse::Converter::Regexp;
use Data::Dumper;
 
my $rev = Template::Reverse->new;
 
# generating patterns automatically!!
my $str1 = ['I',' ','am',' ', 'perl',' ','and',' ','smart']; # White spaces should be explained explicity.
my $str2 = ['I',' ','am',' ', 'khs' ,' ','and',' ','a',' ','perlmania']; # Use Parse::Lex or Parse::Token::Lite to make it easy.
my $parts = $rev->detect($str1, $str2);
 
my $reg = Template::Reverse::Converter::Regexp->new;
my $templates = $reg->Convert($parts);

my $str3 = "I am king of the world and a richest man";
 
# extract!!
foreach my $regexp (@{$templates}){
    if( $str3 =~ /$regexp/ ){
        print $1."\n";
    }
}

