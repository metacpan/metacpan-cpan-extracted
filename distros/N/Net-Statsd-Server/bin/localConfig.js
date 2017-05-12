#/*
#
# Required Variables:
#
#   port:             StatsD listening port [default: 8125]
#
# Graphite Required Variables:
#
# (Leave these unset to avoid sending stats to Graphite.
#  Set debug flag and leave these unset to run in 'dry' debug mode -
#  useful for testing statsd clients without a Graphite server.)
#
#   graphiteHost:     hostname or IP of Graphite server
#   graphitePort:     port of Graphite server
#
# Optional Variables:
#
#   backends:         an array of backends to load. Each backend must exist
#                     as Perl module. If a single word is specified as backend
#                     (example: "Console") then the "Net::Statsd::Server::Backend::Console"
#                     will be loaded. Otherwise you can load an arbitrary class
#                     ("My::Statsd::Backend").
#
#   debug:            debug flag [default: false]
#   address:          address to listen on over UDP [default: 0.0.0.0]
#   port:             port to listen for messages on over UDP [default: 8125]
#   mgmt_address:     address to run the management TCP interface on
#                     [default: 0.0.0.0]
#   mgmt_port:        port to run the management TCP interface on [default: 8126]
#   debugInterval:    interval to print debug information [ms, default: 10000]
#   dumpMessages:     log all incoming messages
#   flushInterval:    interval (in ms) to flush to Graphite
#   percentThreshold: for time information, calculate the Nth percentile(s)
#                     (can be a single value or list of floating-point values)
#                     [%, default: 90]
#   keyFlush:         log the most frequently sent keys [object, default: undefined]
#     interval:       how often to log frequent keys [ms, default: 0]
#     percent:        percentage of frequent keys to log [%, default: 100]
#     log:            location of log file for frequent keys [default: STDOUT]
#   deleteIdleStats:  don't send values to graphite for inactive counters, sets,
#                     gauges, or timers as opposed to sending 0. For gauges,
#                     this unsets the gauge (instead of sending the previous value).
#                     Can be indivdually overriden. [default: false]
#   deleteGauges:     don't send values to graphite for inactive gauges, as opposed
#                     to sending the previous value [default: false]
#   deleteTimers:     don't send values to graphite for inactive timers, as opposed
#                     to sending 0 [default: false]
#   deleteSets:       don't send values to graphite for inactive sets, as opposed
#                     to sending 0 [default: false]
#   deleteCounters:   don't send values to graphite for inactive counters, as opposed
#                     to sending 0 [default: false]
#   prefixStats:      prefix to use for the statsd statistics data for this running
#                     instance of statsd [default: statsd]
#                     applies to both legacy and new namespacing
#   deleteCounters:   don't send values to graphite for inactive counters,
#                     as opposed to sending 0 [default: false]
#
#   console:
#     prettyprint:    whether to prettyprint the console backend
#                     output [true or false, default: true]
#
#   log:              log settings [object, default: undefined]
#     backend:        where to log: stdout or syslog [string, default: stdout]
#     application:    name of the application for syslog [string, default: statsd]
#     level:          log level for [node-]syslog [string, default: LOG_INFO]
#
#   graphite:
#     legacyNamespace:  use the legacy namespace [default: true]
#     globalPrefix:     global prefix to use for sending stats to graphite [default: "stats"]
#     prefixCounter:    graphite prefix for counter metrics [default: "counters"]
#     prefixTimer:      graphite prefix for timer metrics [default: "timers"]
#     prefixGauge:      graphite prefix for gauge metrics [default: "gauges"]
#     prefixSet:        graphite prefix for set metrics [default: "sets"]
#
#   file:
#     name:           name of the logfile for the File backend
#
#   repeater:         an array of hashes of the for host: and port:
#                     that details other statsd servers to which the received
#                     packets should be "repeated" (duplicated to).
#                     e.g. [ { host: '10.10.10.10', port: 8125 },
#                            { host: 'observer', port: 88125 } ]
#
#   repeaterProtocol: whether to use udp4 or udp4 for repeaters.
#                     ["udp4" or "udp6", default: "udp4"]
# */
{

  "address" : "0.0.0.0",
  "port": 8125,

  "mgmt_address" : "0.0.0.0",
  "mgmt_port": 8126,

  "debug" : false,
  "dumpMessages" : false,

  "flushInterval" : 10000,  # ms

  "log" : {
    "backend" : "syslog",  # or "stdout"
    "level" : "LOG_INFO",  # "warn" to be less verbose
  },

  # Available backends are: Graphite, Console, File
  "backends": [ "Graphite", "Console" ],

  # File backend config example
  #"file" : {
  #  "name" : "/var/tmp/statsd-flush.log",
  #},

  #"keyFlush" : {
  #  "interval" : 10000,   # ms
  #  "percent" : 25,
  #  "log" : "/var/tmp/statsd-top.log",
  #},

  # statsd will periodically flush its metrics to Graphite
  # Be sure to include the Graphite backend above
  "graphitePort": 2003,
  "graphiteHost": "localhost", # your.graphite.host
  "graphite": {
    "legacyNamespace" : false
  },

  ## Repeater backend is not implemented yet
  #"repeater": [ { "host": "10.1.2.3", "port": 8125 } ],
  #"repeaterProtocol": "udp4"

}
