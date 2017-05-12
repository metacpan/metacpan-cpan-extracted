Parse::WebCounter version 0.02
==============================

This Module parses web counter images using GD and supplies the numeric
value represented by the image. Useful if you have a cron keeping
track of the number of hits you are getting per day and you don't
have real logs to go by. You will need copies of the images
representing the individual digits, or a strip of all of them for
it to compare to as the module is not very bright it does a simple
image comparison as apposed to any sophisticated image analysis
(This is not designed, nor intended to be a Captcha solver)

INSTALLATION

To install this module type the following:

   perl Makefile.PL
   make
   make test
   make install

You will then need to create some reference images using your favourite
web counter. The t/id directory contains examples of these. If you are
using your own webcounter cgi you will probably find that it comes with
a strip image that it uses to generate the images itself, otherwise
you will need to generate and save them manually. You will find that
most web counters recognise arguments such as increase=<number> which 
you can use to force a nice 10 digit number eg.

   http://website.com/cgi-bin/webcount.cgi?link=blah&increase=1234567890

Save the image file in a nice convenient subdirectory as "strip.gif"
you can then load it up with 

   my $parser = new Parse::WebCounter(PATTERN=>"directory");



DEPENDENCIES

This module requires these other modules and libraries:

  GD - You need a version that will support the file format of your
       webcounter images this is usually gif format. Ideally you
       want GD version 2.16 which is the earliest version to
       re-introduce gif support

Additionally, the test suite requires:

	Test::More
        File::Spec
        Cwd

COPYRIGHT AND LICENCE

Peter Wise, www.vagnerr.com

Copyright (C) 2006 Peter Wise. All Rights Reserved

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

