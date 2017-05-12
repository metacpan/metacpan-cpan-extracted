#! /bin/bash

. ./tapper-autoreport --import-utils

SUITEVERSION=2.01

uname -a | grep -q Linux  # example for ok exit code
ok $? "we run on Linux"

done_testing
