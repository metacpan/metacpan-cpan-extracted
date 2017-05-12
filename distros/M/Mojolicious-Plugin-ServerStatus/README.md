Mojolicious::Plugin::ServerStatus
---------------------------------

This is a [Mojolicious](http://mojolicio.us) plugin to show server status, like Apache's
mod\_status. It displays server status information
in multiprocess Mojolicious servers such as morbo and hypnotoad.

It is based on [Plack::Middleware::ServerStatus::Lite](https://metacpan.org/pod/Plack::Middleware::ServerStatus::Lite).

This module changes status only before and after executing the applications,
so it cannot monitor keepalive session and network I/O wait.

#### Installation ####

    cpanm Mojolicious::Plugin::ServerStatus

or manually:

    perl Makefile.PL
    make test
    make install

#### Synopsis ####

```perl
       plugin 'ServerStatus' => {
           path => '/server-status',
           allow => [ '127.0.0.1', '192.168.0.0/16' ],
       };
```


     % curl http://server:port/server-status
     Uptime: 1234567789
     Total Accesses: 123
     BusyWorkers: 2
     IdleWorkers: 3
     --
     pid status remote_addr host user method uri protocol ss
     20060 A 127.0.0.1 localhost:10001 - GET / HTTP/1.1 1
     20061 .
     20062 A 127.0.0.1 localhost:10001 - GET /server-status HTTP/1.1 0
     20063 .
     20064 .

     # JSON format
     % curl http://server:port/server-status?json
     {"Uptime":"1332476669","BusyWorkers":"2",
      "stats":[
        {"protocol":null,"remote_addr":null,"pid":"78639","user":"-",
         "status":".","method":null,"uri":null,"host":null,"ss":null},
        {"protocol":"HTTP/1.1","remote_addr":"127.0.0.1","pid":"78640","user":"-",
         "status":"A","method":"GET","uri":"/","host":"localhost:10226","ss":0},
        ...
     ],"IdleWorkers":"3"}


For extra information, please refer to [the full documentation for Mojolicious::Plugin::ServerStatus](https://metacpan.org/pod/Mojolicious::Plugin::ServerStatus) on CPAN.

#### Author ####

fu kai (iakuf {at} 163.com)

#### License ####

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

