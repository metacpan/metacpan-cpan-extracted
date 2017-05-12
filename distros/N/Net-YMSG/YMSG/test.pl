#!/usr/bin/perl 
$body="<hello> how are you";
$body=~s/<(.*)>//g;
print $body;

