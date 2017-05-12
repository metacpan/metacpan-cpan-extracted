#!/bin/sh

find lib -type 'f' | xargs perl script/rclass_back_to_moose.pl
