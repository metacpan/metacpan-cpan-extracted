#!/usr/bin/perl
use strict;
use warnings;
use vars qw($VERSION);
$VERSION = 1.2;
# $Id: 01-load.t,v 1.1 2007/05/07 12:00:55 ask Exp $
# $Source: /opt/CVS/SeSnowball/t/01-load.t,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.1 $
# $Date: 2007/05/07 12:00:55 $

use Test::More;
plan( tests => 1 );
use_ok('Lingua::Stem::Snowball::Se');

