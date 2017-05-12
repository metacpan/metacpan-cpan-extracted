rex-webui
=========

Simple web frontend for rex, using Mojolicious.



Quick Start
===========

Run the application:

  rex-webui daemon

and point your browser at http://localhost:8080

The webui.conf and SampleRexfile are copied into your working directory.

Next, build multiple Rexfiles (e.g. one per project) in the usual way (see http://rexify.org).

Register your rexfiles in webui.conf.



Installation
============

  perl Makefile.PL

  make

  make test

  sudo make install

If necessary, install the dependencies from the cpanfile using carton / cpanm.


