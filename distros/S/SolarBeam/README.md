SolarBeam
=========

Super effective Solr client in Perl that uses Mojolicious' event loop.

## Synopsis

```perl
use SolarBeam;

my $sb = SolarBeam->new(url => 'http://localhost:8983/solr/');

$sb->search('Hello World', sub {
  my $res = pop;
  print $res->ok;
  print $res->numFound;
  print $res->docs->[0]->{name};
});

$sb->search({author => 'Magnus Holm'}, sub {
  my $res = pop;
  # …
});

$sb->search(['author:(%name)^10', name => 'Magnus Holm'], sub {
  my $res = pop;
  # …
});

Mojo::IOLoop->start;
```

## Queries

### Raw

```perl
$sb->search('Hello AND World');
# This will search for: ?q=Hello AND World
```

### Fields

```perl
$sb->search({author => 'Magnus', topic => 'Perl'});
# This will search for ?q=(author:Magnus AND topic:Perl)
# All special characters except for * and ? will be escaped

$sb->search({author => \'Magnus', topic => \'Perl'});
# If you pass in a string reference, * and ? will also be escaped.
# Mnemonic: If you "escape" the string, *everything* will be escaped.
```

### Parameter

```perl
$sb->search(['(%query OR author:(%query)^5)', query => 'Magnus']);
# This will search for ?q=(Magnus or author:(Magnus)^5)
# All special characters except for * and ? will be escaped

$sb->search(['(%query OR author:(%query)^5)', query => \'Magnus']);
# If you pass in a string reference, * and ? will also be escaped.
# Mnemonic: If you "escape" the string, *everything* will be escaped.
```

