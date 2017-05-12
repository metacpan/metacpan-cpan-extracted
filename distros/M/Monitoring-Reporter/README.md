This is the README file for Monitoring-Reporter,
a responsive Monitoring Dashboard.

## Description

Monitoring-Reporter provides a responsive
HTML5/CSS Monitoring Dashboard.

Please have a close look at the Plugins in the
namespace Monitoring::Reporter::Web::Plugin and
the coresponding documentation in conf/mreporter.conf.dist.
Please note how the Plugin names are mapped to the
appropriate configuration keys.

## Installation

This section describe how to install this packages. Please see the next section
on how to set ip up and get it running.

### From CPAN

This package is available from CPAN. You can install it using your standard
CPAN client, e.g.

  cpanm Monitoring::Reporter

or

  cpan install Monitoring::Reporter

Although I'd recommend using distribution packages and installing those.

### From Debian Packages

There are packages for Debian (squeeze and wheezy) as well as Ubuntu LTS (precise).

  echo "deb http://packages.gauner.org/ squeeze main contrib non-free" >>/etc/apt/sources.list
  wget -q -O- http://packages.gauner.org/C85AEFAC.key | apt-key add -
  apt-get update
  apt-get install libmonitoring-reporter-perl

### From Source

This package uses Dist::Zilla.

Use

dzil build

to create a release tarball which can be
unpacked and installed like any other EUMM
distribution.

perl Makefile.PL

make

make test

make install

## Configuration

Once the package is installed you need to set up some kind of PSGI adapter to
make the application accessible. This documentation will show one way of doing
that using Apache and Starman but you can use any PSGI adapter and webserver
you like.

Install starman and make it listen on e.g. port 5001 and serve the PSGI file at
/usr/bin/mreporter-web.psgi.

Then create a new apache vhost that contains the required proxy settings:

  <IfModule mod_proxy.c>
    <Location /mreporter>
      Allow from all
      ProxyPass http://localhost:5001/
      ProxyPassReverse http://localhost:5001/
    </Location>
  </IfModule>

After starting startman and restarting Apache the application should be available
at http://localhost/mreporter/.

## Documentation

Please see perldoc Monitoring::Reporter.

## Examples

![Monitoring::Reporter on Desktop](examples/mreporter-desktop.png)

![Monitoring::Reporter on Mobile](examples/mreporter-small.png)

![Monitoring::Reporter on Big Screens](examples/mreporter-tv.png)

![Monitoring::Reporter w/ no active triggers](examples/mreporter-ok.png)

Here is [an static snapshot of the Monitoring::Reporter demo page](examples/mreporter-static.html).

## Resources

The following resources may prove helpful when dealing with the
Monitoring database schema:

* https://www.zabbix.com/documentation/1.8/api/
* http://git.zabbixzone.com/zabbix1.8/.git/tree
* https://metacpan.org/pod/Monitoring::Livestatus

