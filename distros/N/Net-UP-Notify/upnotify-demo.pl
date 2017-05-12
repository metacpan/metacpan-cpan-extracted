#!/usr/bin/perl
#
#up-notify demo example program
#Copyright (C) 2004 Paul Timmins, All rights reserved. 
#This program is free software; you can redistribute it and/or 
#modify it under the same terms as Perl itself.
#
#
#Please change the subscriber ID to something valid. 
#It's not nice to hammer nextel with phony addresses.
#Thank you!

use Net::UP::Notify;
      
      $blah=new Net::UP::Notify;
      $blah->subscriberid("1111111111-999999999_atlsnup2.adc.nexteldata.net");
      $blah->location("http://www.perl.com");
      $blah->description("Perl.Com");
      print $blah->send;

