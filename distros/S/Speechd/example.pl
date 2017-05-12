#!/usr/bin/perl

     use strict;
     use warnings;

     use Speechd;

     my $rate = 0;
     my $vol = 0;
     my $pitch = 0;
     my $lang = "en";
     my $voice = "MALE1";

     my $sd = Speechd->new(
        'rate' => $rate,
        'volume' => $vol,
        'lang' => $lang,
        'voice' => $voice,
     );

     $sd->connect();

     while (1) {
        print "Enter text to speak:\n";
        my $text = <>;
        $sd->say($text);
        my $message = $sd->msg();
        print $message;
        chomp $text;
        $text = lc($text);
        last if $text eq "goodbye";
     }

     $sd->disconnect();

     exit 0;
