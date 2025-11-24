# RRD-Fetch

A Perl module to fetch data from a RRD file.

## Install

```
perl Makefile.PL
make
make test
make install
```

FreeBSD

```
pkg install p5-App-cpanminus rrdtool
cpanm RRD::Fetch
```

Debian

```
apt-get install rrdtool cpanminus
cpanm RRD::Fetch
```

## Example

Get the max 1min from t/data/ucd_load.rrd for between 20251001
and 20251012 for each day.

```
rrd_fetch -f t/data/ucd_load.rrd -F 12 -s 20251001 -p --ds -c MAX | jq '."max"[]."1min"'
```

Get the average 1min from t/data/ucd_load.rrd for between 20251001
and 20251012 for each day.

```
rrd_fetch -f t/data/ucd_load.rrd -F 12 -s 20251001 -p --ds -c AVERAGE | jq '."mean"[]."1min"'
```

Grab 1min for between 20251001 to 20251012.

```
rrd_fetch -f t/data/ucd_load.rrd -s 20251001 -e 'start+12d' | jq '."data"."1min"'
```
