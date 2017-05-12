use strict;
use warnings;

package Monitor::MetricsAPI::Tutorial;
$Monitor::MetricsAPI::Tutorial::VERSION = '0.900';
=head1 NAME

Monitor::MetricsAPI::Tutorial - Getting Started with MetricsAPI

=head1 WHAT IS METRICSAPI?

Monitor::MetricsAPI aims to provide a simple (interface and usability wise)
approach to instrumenting your event-driven Perl applications. Beyond telling
it what address and port to listen to, and giving it a bunch of names for
things you want to track, there isn't much you need to deal with to gain much
greater insight into the operation of your applications.

=head1 REQUIREMENTS

The direct dependencies of this library are not extensive (though these direct
dependencies do pull in a fair amount of additional dependencies). At minimum
you will need the following:

=over

=item * AnyEvent

Both the library, and the execution model of the application or service you are
hoping to instrument. One-off glue scripts that exist in the process table
sporadically and for seconds at a time are not the target consumers of this
library. Long running applications, background services and daemons, and
always-on servers that use an event model (any supported by AnyEvent, which is
thankfully just about all of them in Perl) - those can potentially benefit.

=item * Twiggy and Dancer2

Twiggy is an easily embedded, event-driven Plack/PSGI HTTP server for Perl and
is used to run the HTTP API server. Dancer2 is used to build and service the
individual API routes. Both are reliable, fast, and pretty lightweight.

=item * Monitoring Tools

Monitor::MetricsAPI makes it (really) easy to instrument your application and
serve out its metrics, but it is not responsible for helping you make sense of
all the data. For that you should use a monitoring service that can consume the
API this library provides and give you a bunch of pretty graphs, send out alert
emails/pages, and maybe even build up failure prediction models.

Anything from the old warhorse of Nagios, to the flashy new kids on the block
like Sensu would work. Advanced monitoring systems like Circonus would be a
great choice, too.

=back

=head1 INSTRUMENTING FOR FUN AND PROFIT

=head2 What exactly is "instrumenting"?

Instrumenting refers to the addition of code to your application for the sole
purpose of tracking its events and behavior, as opposed to code which provides
functionality, and making that data available outside the application in one
manner or another so that it can be analyzed. The data can help to reveal
problems or inefficiencies that might otherwise go undetected.

=head2 How does it affect my application?

From the application developer's perspective, Monitor::MetricsAPI is a Perl
module like any other that you use into your own code, most likely early on
when you're setting up all your other event loop listeners, timers, callbacks,
etc. You name a bunch of things you want to track and what they are, then
elsewhere in your application code you note when those trackable events occur.
"I just received a new message via UDP." "I just discarded a packet." "I just
created 3 new user records." "I am restarting 'now()'." And so on.

From the operator's perspective, Monitor::MetricsAPI provides an HTTP API which
can spit out JSON showing some or all of the values the application developer
has decided to track. "There are 5,617 users connected right now." "15 packets
have been dropped." "I last received a ping from the database connection pooler
at <timestamp>."

=head2 How is this different from using log files?

Event logging is all well and good, and most applications should probably be
doing it, even if they also provide metrics instrumentation. And it is possible
that many of the things you may decide to instrument could also be included in
a comprehensive error and event logging mechanism.

But what if your service runs individual instances across 50 different servers
and you want to know right now how many messages each one is in the process of
parsing and acting upon? Or you want to see how many worker threads have been
spawned, and how close to the maximum limit of workers each process currently
is? Or you want to know if a process received a HUP signal and is reloading its
runtime configuration?

Sure, some of these can be reconstructed from log files but in many cases there
are things you might want to know about your application's current state before
it reaches a log, or aggregated stats that would require a bunch of log parsing
to figure out (How many messages since the last restart? Average processing
time for the last 500 requests?) Seems a lot easier to be able to just do:

    $ curl http://myserver:8200/metric/workers/current
    { "metrics": {
        "workers": {
          "current": 17
        }
      }
    }

Or even better, get back everything your application tracks about its worker
threads in one go:

    $ curl http://myserver:8200/metrics/workers
    { "metrics": {
        "workers": {
          "current": 17,
          "limit": 20,
          "reap_after": "5m",
          "last_reaped": "2015-07-23T17:22:51Z"
        }
      }
    }

[Note that the API actually returns a few more details in every response that
are omitted from the examples above for brevity.]

And because you can get these metrics back in JSON at any time you wish simply
by calling the API, instead of having to consume logs or wait for your program
to complete and print out a summary, they're far easier to integrate into
external, active monitoring tools like Nagios, Circonus, Sensu, Zabbix, etc.

=head1 ADDING METRICS TO YOUR APPLICATION

=head2 Creating a Collector

The I<collector> is a Monitor::MetricsAPI object you create in your application
which is used to manage the HTTP API server and keep track of all the metrics
you define, so called because it is what collects all your metrics.

Adding Monitor::MetricsAPI to your event-based Perl application is very easy:

    use AnyEvent;
    use Monitor::MetricsAPI;

    my $c = AnyEvent->condvar;

    my $collector = Monitor::MetricsAPI->create(
        listen  => '<address>:<port>', # defaults to localhost:8200
        metrics => {
            # ... define a bunch of metrics, or populate them
            #     from your application config ...
        }
    );

    # ... set up all of your application's event listeners ...

    $c->recv;

And now your application has an embedded HTTP server running on the specified
interface and port that serves up the metrics API.

=head2 Accessing the Collector

You may have noticed in the previous example that we've created a $collector
variable at the top level of our application. The natural assumption would then
follow that everywhere else in your application which you wish to track and
interact with your metrics is going to need to receive this $collector variable
somehow and you'll be doomed to passing it around constantly (or adding an
attribute to your $app object, or something like the same).

Monitor::MetricsAPI tries to simplify this for you by tracking the collector as
a single, globally-accessible class variable. When you create the very first
collector instance during your application's initialization, the collector is
stored (using MooseX::ClassAttribute) in the Monitor::MetricsAPI class. You can
then access it at any time, from anywhere else in your application, without
having to pass a single object reference around everywhere.

To simplify things even further, Monitor::MetricsAPI presents the same methods
to you whether you are using an instance object or the class attribute. Thus,
the two following methods of retrieving a metric's value are completely
interchangeable:

    $collector->metric('users/total')->value;
    Monitor::MetricsAPI->metric('users/total')->value;

If you're going to perform multiple metrics operations in close proximity and
want to save a few characters on each metric() call, you can also retrieve the
collector from the class with:

    my $coll = Monitor::MetricsAPI->collector;

Additionally, if you call Monitor::MetricsAPI->create( ... ) more than once,
you will receive the same collector object back each time. Any new metrics
which you define in the subsequent create() calls will be merged into the
original collector, and if you specify a "listen" address and port which are
not already bound by the API server, they will be used to create another server
that runs simultaneously.

The only catch: you cannot have multiple, distinct collectors in a single
application, each with their own unique sets of metrics. (IMHO, that seems like
such a strange, fringe, unlikely, unwieldly, and quirky thing to want anyway,
I'm happy to forgo that feature to make accessing the collector so much simpler
for the vast majority, if not totality, of uses.)

=head2 Configuring Metrics at Startup

During collector construction, you may provide a data structure which defines
all or some of the metrics you wish to expose about your application. This
structure defines a hierarchical categorization, making it easy to group many
related metrics together in a sensible, and (hopefully) self-documenting
manner. I hope you like nested hash references.

A simple metrics definition for a service which receives incoming messages of
some sort, processes them, and sends responses back - all with a worker thread
pool - might look like the following:

    { messages => {
        incoming => {
          total      => 'counter',
          rejected   => 'counter',
          processing => 'gauge',
          latest     => 'timestamp'
        },
        outgoing => {
          total          => 'counter',
          suppressed     => 'counter',
          response_codes => {
            2xx => 'counter',
            3xx => 'counter',
            4xx => 'counter',
            403 => 'counter',
            404 => 'counter',
            5xx => 'counter'
          },
        },
      },
      workers => {
        current => 'gauge',
        limit   => 'gauge'
      }
    }

This structure has defined two top-level metric groups: "messages" and
"workers." The workers group contains two gauge metrics, but the messages group
is broken down further into two subgroups: "incoming" and "outgoing." The
incoming group contains four metrics, and the outgoing group contains both two
metrics and another subgroup: "response_codes."

You can nest these metric groups as deeply as you wish, though you may start to
find that addressing them will be a bit unwieldy if you get a few dozen groups
down and the metric names are reaching hundreds of characters. This library
will not prevent you from making those mistakes if you really insist.

=head2 Adding Metrics On-the-Fly

Maybe you have a huge number of metrics and you don't want your application's
main setup sub to be 10,000 lines long (and you haven't figured out that you
can put all this in a config file and get it to the collector constructor via
the wonderful Config::* modules). Or maybe you just prefer a somewhat more
adhoc approach to things.

You may add new metric definitions to your collector at any time during your
application's life-cycle, as long as you do so before you attempt to add data
to the metric. Simply call the add_metric() method on your collector as so:

    $collector->add_metric($name, $type);

Or if you're creating a callback metric (one which invokes a subroutine of your
choosing every time the metric is requested via the API, or anywhere in your
application that calls value() on the metric object):

    $collection->add_metric($name, 'callback', sub { ... });

In-flight metric definition is particularly useful for callback metrics, since
it allows you to capture variables that may not exist until your application
has started doing "things."

=head2 Giving Value to Your Metrics

You should now have at least some metrics defined. But you still need to
provide the data that makes those metrics mean something.

How you provide values to a metric can vary slightly depending on the type of
metric you are tracking. For the full details, please make sure to read the
documentation provided by L<Monitor::MetricsAPI::Metric> and its submodules.
In most applications, the counter and gauge metrics are likely to be most
prevalent, and manipulating their values is quite easy:

    # For a gauge metric which tracks a single point-in-time value:
    $collector->metric($name)->set($value);

    # For a counter metric which increments every time something occurs:
    $collector->metric($name)->add($num_times_something_happened);

This may be done anywhere in your application that you have access to your
collector object. What if you can't easily pass that object around everywhere?
Monitor::MetricsAPI keeps track of the collector object globally, and lets you
access it via class methods, as so:

    # Setting the value on an existing metric via the class method:
    Monitor::MetricsAPI->metric($name)->set($value);

    # Creating a new metric via the class method:
    Monitor::MetricsAPI->add_metric($name, $type);

The syntax for using both the object and the class method is identical, for
your convenience.

=head1 VIEWING COLLECTED METRICS

=head2 What are metrics actually named?

You've done the work of defining your metrics, and that involved a bunch of
curly braces around curly braces around curly braces. It's curly braces all the
way down. But how do you mangle that kind of notation into the method calls for
updating your metrics in your application, or viewing them via the HTTP API?

Earlier in this tutorial, you may have noticed the curl commands we used. The
names of your metrics get flattened into a slash-delimited string with every
containing group included as part of the name. You will need to use this full
path whenever you refer to a metric, to avoid any ambiguity when you have a
dozen different metric groups that each have a "total" they're tracking.

So a metric defined like this:

    { protocols => { tcp => { rx_packets => 'counter' } } }

Becomes a metric name like this:

    protocols/tcp/rx_packets

=head2 Viewing a single metric

Individual metrics may be retrieved via the HTTP API using their full name by
issuing a GET to the following URI:

    http://<addr>:<port>/metric/<metricname>

Thus, the metric "users/total" is viewed at:

    http://<addr>:<port>/metric/users/total

Providing an invalid metric name, a partial name, or the name of a group of
metrics to this API endpoint will result in an error.

=head2 Viewing a group of metrics

Entire groups of metrics may be retrieved via the HTTP API in a similar manner,
by using the group name and the "metrics" endpoint instead of "metric":

    http://<addr>:<port>/metrics/protocols

You may also provide the full name of a single metric to this API endpoint, and
you will receive only that metric's value in the response. The advantage to the
single "metric" endpoint is that you are guaranteed to only have one, specific
metric in the API's output (in case that ever matters), as passing a metric
group path to that endpoint will result in an error.

=head2 Viewing all metrics at once

For the reckless, or just those testing out their application, you may also
retrieve a complete dump of all metrics in a single API call by using the "all"
endpoint:

    http://<addr>:<port>/all

=head3 WARNING

Retrieving all of your application's metrics at once is more computationally
expensive than retrieving just the subset you actually need at a given time -
assuming you don't actually need all of them. Additionally, if you have defined
callback metrics, using the "all" endpoint will invoke every one of them. If
they perform non-trivial data gathering, that can impact your application's
performance.

It is strongly recommended that for production monitoring, you retrieve only
the specific metrics via the "metric" or "metrics" API endpoints that you need
with each call, and that you exercise particular care with any callback metrics
you define to minimize their performance side effects. Retrieving non-callback
metrics is very lightweight, but does take a number of operations proportional
to the number of metrics you have defined.

Feel free to throw all caution to the wind during development and testing.

=head1 INTEGRATING WITH MONITORING SYSTEMS

This section of the tutorial has not been written yet.

=head1 AUTHORS

Jon Sime <jonsime@gmail.com>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2015 by OmniTI Computer Consulting, Inc.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

1;
