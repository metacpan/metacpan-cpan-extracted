{
  "address": "0.0.0.0",
  "port": 40001,
  "mgmt_address": "0.0.0.0",
  "mgmt_port": 40002,

  "debug": false,
  "dumpMessages": false,
  "flushInterval": 1000,
  "flush_counters" : true,

  "log" : {
    "backend": "stdout",
    "level": "LOG_INFO",
  },

  "backends": [ "./backends/console", "./backends/graphite" ],
  "graphiteHost": "localhost",
  "graphitePort": 40003,
  "graphite": {
    "legacyNamespace": false
  }

}
