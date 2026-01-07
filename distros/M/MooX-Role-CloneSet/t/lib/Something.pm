#!/usr/bin/perl
# SPDX-FileCopyrightText: Peter Pentchev <roam@ringlet.net>
# SPDX-License-Identifier: Artistic-2.0

package Something;

use 5.012;
use strict;
use warnings;

use Moo;
use namespace::clean;

our $VERSION = v0.1.0;

with 'MooX::Role::CloneSet';

has name => ( is => 'ro', );

has color => ( is => 'ro', );

1;
