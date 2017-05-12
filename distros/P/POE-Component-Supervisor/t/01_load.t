#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use_ok 'POE::Component::Supervisor::Supervised';
use_ok 'POE::Component::Supervisor::Handle';
use_ok 'POE::Component::Supervisor';

use_ok 'POE::Component::Supervisor::Handle::Proc';
use_ok 'POE::Component::Supervisor::Supervised::Proc';
