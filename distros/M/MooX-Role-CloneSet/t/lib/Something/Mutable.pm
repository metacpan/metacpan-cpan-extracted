#!/usr/bin/perl
# SPDX-FileCopyrightText: Peter Pentchev <roam@ringlet.net>
# SPDX-License-Identifier: Artistic-2.0

package Something::Mutable;

use 5.012;
use strict;
use warnings;

use Moo;
use namespace::clean;

our $VERSION = v0.1.0;

extends 'Something';

has name => ( is => 'rw', );

1;
