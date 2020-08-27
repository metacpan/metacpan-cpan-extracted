#!/usr/bin/perl
#
# very simplistic script to extract all text from OPUS xml files ....

while (<>){
    chomp;
    s/<\/s>/\n/;
    s/<[^\>]+>//g;
    s/^ *//;s/ *$//;
    s/&gt;/>/g;
    s/&lt;/</g;
    s/&apos;/'/g;
    s/&quot;/"/g;
    s/&amp;/&/g;
    print $_,' ';
}
