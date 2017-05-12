#! /usr/bin/perl
#
# Sample shared secret configuration for Net::Radius::Server
#
# Copyright © 2006, Luis E. Muñoz
#
# This file defines a 'secret' provider method that returns a simple shared
# secret.
#
# $Id: def-secret.pl 74 2007-04-21 17:13:14Z lem $

use strict;
use warnings;

sub { 'secret' }
