This is the README file for Monitoring-Spooler, an daemon for
queueing and delivery of monitoring notifications.

## Description

Monitoring::Spooler is a handy queue manager for queueing
and delivery of monitoring notifications. It is able to
handle several groups of on-call personel and provides
an extensible plugin mechanism to connect it to virtually any
remote service which provides some kind of API.

Please also look at App::Standby which provides a remote control for
this and other notification tools and will help you manage
you notification qeues and on call-rotations easily.

## Installation

This package uses Dist::Zilla.

Use

dzil build

to create a release tarball which can be
unpacked and installed like any other EUMM
distribution.

perl Makefile.PL

make

make test

make install

## Documentation

Please see perldoc Monitoring::Spooler. Setup and configuration is covered there.

