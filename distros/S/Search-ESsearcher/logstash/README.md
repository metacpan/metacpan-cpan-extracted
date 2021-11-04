# Installing

Just dump the stuff in your logstash dir and update the host setting
for the IP to listen on as well as set the ports as desired.

# Notes

## Postfix

These come from
[whyscream/postfix-grok-patterns](https://github.com/whyscream/postfix-grok-patterns).

51-filter-postfix-aggregate.conf is set to off by default as in
testing I found it to be buggy. It will often times result in lines
being skipped.

This one does have GeoIP processing though.
