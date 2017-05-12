{
  "graphitePort": 2003,
  "graphiteHost": "graphite.local",
  "host" : "0.0.0.0",
  "port": 8125,
  "mgmt_address" : "0.0.0.0",
  "mgmt_port": 8126,
  "dumpMessages": true,
  "backends": [ "Graphite", "Console" ],
  "log" : {
    "backend" : "stdout",
    "level" : "LOG_WARN",
  }
}
