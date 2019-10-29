#!/bin/bash
set -e
VERSION_FROM=lib/Net/Kafka.pm
perl -MPod::Markdown -e 'Pod::Markdown->new->filter(@ARGV)' $VERSION_FROM > README.md
pod2readme $VERSION_FROM README