Net-Dogstatsd
=============

DESCRIPTION
-----------
This module provides a simple Perl client to 'dogstatsd', a daemon provided with
the Datadog agent software. The purpose of dogstatsd is to aggregate the sending
of metrics to the Datadog service.  dogstatsd is very similar to statsd, but
supports additional metric types, as well as adding informational tags to
metrics (which makes for easy "slicing and dicing" of your metrics within the
Datadog graphs/dashboards.

Datadog (http://www.datadoghq.com/) is a service that will "Capture metrics and
events, then graph, filter, and search to see what's happening and how systems
interact. Datadog is a service for IT, Operations and Development teams who write
and run applications at scale, and want to turn the massive amounts of data
produced by their apps, tools and services into actionable insight."


Test coverage: [![Coverage Status](https://coveralls.io/repos/jpinkham/net-dogstatsd/badge.png?branch=master)](https://coveralls.io/r/jpinkham/net-dogstatsd?branch=master)

Build status:  [![Build Status](https://travis-ci.org/jpinkham/net-dogstatsd.png)](https://travis-ci.org/jpinkham/net-dogstatsd)



Available metric types:

 * counter

Counters can be incremented and decremented by any amount, via the increment()
and decrement() methods.

 * gauge

Gauges measure the value of something over time.

Submit them with the gauge() method.

 * histogram

Histograms measure the statistical distribution of a set of values.

Submit them with the histogram() method.

 * timer

Timers measure the duration of an activity. They are a special
type of histogram.

Submit them with the timer() method.

 * set

Sets are special versions of a counter, for tracking unique items in a group.

Submit them with the sets() method.


NOTES
-----
Choose metric names wisely! The first portion of the metric name will determine
the (auto-created) dashboard where the metric will appear. You can end up with
a large amount of auto-created dashboards if you use many different names in
the first portion of the metric name. You will have to contact Datadog to remove 
any dashboards that are auto-created, that you do not want.

Examples:

    -Metric Name-                         -Dashboard-
    testmetric.requests                   testmetric
    traffic.pages_per_second              traffic
    testmetric.cs.customer_contacts       testmetric


All metric names, values, and tags are converted to lower case before
sending. This was done to prevent multiple instances of the same metric/tag name
but with varying case. 

One or more tags can be optionally specified with any metric.

Tags that contain more than 1 colon (:) will not be allowed. Even though Datadog
allows this, the results when trying to graph by tag are confusing/unexpected.

Also, whitespace (and other special characters) in tags and metric names are
automatically replaced with "_". Warnings are printed whenever characters are
replaced in the metric name. Datadog will make similar changes for you
automatically, but this happens silently and, as a result, can make it harder to
find the resulting metrics within your dashboards.

INSTALLATION
------------

To install this module, run the following commands:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

SUPPORT AND DOCUMENTATION
-------------------------

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Net::Dogstatsd

You can also look for information at:

 * [GitHub's request tracker (report bugs here)]
	(https://github.com/jpinkham/net-dogstatsd/issues)

 * [AnnoCPAN, Annotated CPAN documentation]
	(http://annocpan.org/dist/Net-Dogstatsd)

 * [CPAN Ratings]
	(http://cpanratings.perl.org/d/Net-Dogstatsd)

 * [MetaCPAN]
	(https://metacpan.org/release/Net-Dogstatsd/)


LICENSE AND COPYRIGHT
---------------------

Copyright (C) 2015 Jennifer Pinkham

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License version 3 as published by the Free
Software Foundation.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program. If not, see http://www.gnu.org/licenses/

