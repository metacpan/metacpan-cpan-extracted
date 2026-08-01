# Net-Connection-Sort

This sorts a array of Net::Connection objects.

Currently the sort types below are supported.

```
host_f - Host, foreign
host_fl - Host, foreign then local
host_l - Host, local
host_lf - Host, local then foreign
pid - Process ID
port_f - Port, foreign, numeric
port_fa - Port, foreign, alpha
port_l - Port, local, numeric
port_la - Port, local, alpha
proto - Network connection protocol
ptr_f - PTR, foreign
ptr_l - PTR, local
state - Connection state
uid - User ID
unsorted - Leaves the order as is
user - Username
```

The alpha port types sort on the service name where there is one. Ports
without a service name sort after those with one, numerically.

Setting invert to true reverses the order returned by any of them.

See `perldoc Net::Connection::Sort` for the full documentation.
