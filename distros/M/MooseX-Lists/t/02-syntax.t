#! /usr/bin/perl
# $Id: 02-syntax.t,v 1.2 2010/01/14 08:00:01 dk Exp $

use strict;
use warnings;
use Moose;
use MooseX::Lists;
use Test::More tests => 1;

has_list a  => (isa => 'ArrayRef', is => 'rw');
has_list h  => (isa => 'HashRef',  is => 'rw');
has_list a2 => (is => 'rw');

ok( main->new, 'object');
