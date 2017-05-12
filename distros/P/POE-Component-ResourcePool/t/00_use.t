#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use ok 'POE::Component::ResourcePool::Resource';
use ok 'POE::Component::ResourcePool::Request';
use ok 'POE::Component::ResourcePool';

use ok 'POE::Component::ResourcePool::Resource::Semaphore';
use ok 'POE::Component::ResourcePool::Resource::Collection';
use ok 'POE::Component::ResourcePool::Resource::TryList';

