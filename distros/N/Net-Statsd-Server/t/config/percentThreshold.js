{
  "address": "0.0.0.0",
  "port": 40001,
  "mgmt_address": "0.0.0.0",
  "mgmt_port": 40002,

  "debug": false,
  "dumpMessages": false,
  "flushInterval": 1000,
  "percentThreshold" : [ 95, 98, 99 ],

  "log" : {
    "backend": "stdout",
    "level": "LOG_INFO",
  },

  "backends": [ "./backends/graphite" ],
  "graphiteHost": "localhost",
  "graphitePort": 40003,
  "graphite": {
    "legacyNamespace": false
  },

}
