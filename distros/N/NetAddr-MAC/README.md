NetAddr::MAC
------------

This is a module with functions for handling mac addresses. There are
already two or three MAC addressing functions in CPAN, the motivation
for this module is moderate functionality without Moose.

With that in mind, you can understand why I have cloned much of the really
useful functionality from the two or three existing similar modules on CPAN.

I've covered off all the mac address formats I deal with in my workplace
of mixed hardware. This module can decode just about anything that looks
reasonably like a mac address, and stringify into every format I have seen
used...

So sorry, I'm not really interesting in adding a templating function to
define your own mac address formats. You're welcome to either send in a
patch, extend this module or quickly write a function that wraps the 'raw'
output to whatever you want. Match and join are your friends :)

Hopefully this module is useful to you. So far I have been pleased with
the amount of feedback and patches people have sent in, this has been very
rewarding as well as providing a number of new features I have been able
to use myself.

Please fork and send contributions via Github at
https://github.com/djzort/NetAddr-MAC

-Dean

[![Build Status](https://travis-ci.org/djzort/NetAddr-MAC.svg?branch=master)](https://travis-ci.org/djzort/NetAddr-MAC)
[![CPAN version](https://badge.fury.io/pl/NetAddr-MAC.svg)](https://metacpan.org/pod/NetAddr::MAC)
