#!/bin/bash

mkdir -p /tmp/rrd-spider \
	&& cd /tmp/rrd-spider \
	&& wget -r -np -nd -nH -nv -A cgi http://rrd.me.uk/cgi-bin/rrd-browse.cgi

