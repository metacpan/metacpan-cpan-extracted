Net::uwsgi
==========

perl module for easy interaction with uWSGI servers or for manipulating uwsgi packets


Synopsys
--------

uWSGI interaction

```perl

use Net::uwsgi;
   
# call rpc function 'hello' passing 'roberta' and 'serena' as args
print uwsgi_rpc('ubuntu64.local:3031', 'hello', 'roberta', 'serena')."\n";
   
# raise uwsgi signal 17
uwsgi_signal('ubuntu64.local:3031', 17);
   
# get the '/etc/passwd' item from the cache named 'pippo'
print uwsgi_cache_get('pippo@ubuntu64.local:3031', '/etc/passwd');
   
# get the 'foobar' item from the default cache
print uwsgi_cache_get('ubuntu64.local:3031', 'foobar');
   
# the same but using unix sockets
print uwsgi_cache_get('/tmp/uwsgi.socket', 'foobar');
   
# update the cache
uwsgi_cache_update('pippo@ubuntu64.local:3031', 'test', 'test001');
   
# set a cache item (will fail as 'set' does not update already existent items)
uwsgi_cache_set('pippo@ubuntu64.local:3031', 'test', 'test001');
   
# delete a cache item
uwsgi_cache_del('pippo@ubuntu64.local:3031', 'test')
   
# fast check if an item exists
if (uwsgi_cache_exists('pippo@ubuntu64.local:3031', 'test')) {
   print "all fine here\n";
}
   
# spool a request in the uwsgi spooler
uwsgi_spool('ubuntu64.local:3031', {'test'=>'test001','argh'=>'boh','foo'=>'bar'});
```

uwsgi packets management

```perl

# encode an hash in uwsgi format (the first two values are modifier1 and modifier2)
my $pkt = uwsgi_pkt(0, 0, {'foo'=>'bar', 'author' => 'unbit'});

# encode an array
my $pkt = uwsgi_pkt(0, 0, ['one','two','three']);

# encode a string
my $pkt = uwsgi_pkt(0, 0, 'Hello World');

# parse a uwsgi header
my ($modifier1, $pktsize, $modifier2) = uwsgi_parse_header($pkt);

# parse a uwsgi packet into an hash reference

my $hash = uwsgi_parse_hash($pkt);

# parse a uwsgi packet into an array reference

my $array = uwsgi_parse_array($pkt);

# simply get the body of an uwsgi packet
my $body = uwsgi_parse_body($pkt);
