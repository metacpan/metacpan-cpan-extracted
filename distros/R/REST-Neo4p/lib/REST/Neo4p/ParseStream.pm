use v5.10.1;
package REST::Neo4p::ParseStream;
use base Exporter;
use HOP::Stream qw/node promise/;

use strict;
use warnings;

BEGIN {
  $REST::Neo4p::ParseStream::VERSION = '0.4001';
}

our @EXPORT = qw/j_parse/;# j_parse_object j_parse_array /;

# lazy linked lists
# qry response in txn - "data":[{ "row" : [...]},...]
# qry response for qry - "data":[ [{...},...],... ]
# so - for txn response, j_parse_query_response returns hashes,
#      for qry response, j_parse_query_response returns arrays

sub j_parse {
  my $j = shift;
  state $state; # undef == first call?
  if ($j->incr_text =~ s/^\s*\[\s*//) {
    # batch (simple array of objects)
    return ['BATCH', j_parse_array($j)];
  }
  elsif ($j->incr_text =~ s/^\s*{\s*//) {
    # object
    my $type;
    use experimental 'smartmatch';
    given ($j->incr_text) {
      when (/^\s*"commit"/i) {
	$type = 'TXN';
      }
      when (/^\s*"columns"/i) {
	$type = 'QUERY';
      }
      default {
	$type = 'OBJECT';
      }
    }
    return [$type, j_parse_object($j)]
  }
  elsif ($j->incr_text =~ m/^\s*"[a-zA-Z_]+"/) {
    # after a stream, next key of object
    return ['OBJECT', j_parse_object($j)];
  }
  else {
    # problem
    return;
  }
}

# generic parse array stream
# return decoded json entities at the top level
# opening [ must be removed
# handle empty array too
sub j_parse_array {
  my $j = shift;
  my $po;
  $po = sub {
    my $elt;
    my $int_po = $po;
    state $last_text;
    my $done = eval {$j->incr_text =~ s/^\s*\]\s*//};
    return node(undef,undef) if $done;
    eval {
      $elt = $j->incr_parse;
    };
    if (defined $elt) {
      $last_text = $j->incr_text;
      if ($j->incr_text =~ m/^\]}\],/) { # JSON::XS <=3.04 transaction kludge 
	$j->incr_text =~ s/(\])(}\],)//;
	$done=1;
      }
      elsif ($elt eq 'transaction') { # JSON::XS 4.02 transaction kludge
	$j->incr_text = '"transaction"'.$j->incr_text;
	return node(undef,undef);
      }
      else {
	$j->incr_text =~ s/^(\s*,\s*)|(\s*\]\s*)//;
	$done = !!$2;
      }

    }
    elsif ($@) {
      if ($@ =~ /already started parsing/) {
	$elt = 'PENDING';
      }
      elsif ($@ =~ /must be an object or array/ &&
	    $last_text =~ /("[^"]+")/) {
	# txn kludge
	$j->incr_skip;
	$j->incr_text = $1.$j->incr_text;
	return node(undef,undef);
      }
      else {
	die "j_parse: $@";
      }
    }
    else {
      $elt = 'PENDING';
    }
    node(['ARELT'=>$elt], $done ? undef : promise { $po->() });
  };
  return $po;
}

# generic parse object to one level
# opening { must be removed
# when another stream is returned as the value, 
#  another call to j_parse_object has to wait until that stream is 
#  exhausted...
sub j_parse_object {
  my $j = shift;
  my $po;
  $po = sub {
    state $key;
    state $current = '';
    my ($text, $head,$obj);
    my $done;
    unless ($current eq 'PENDING') {
      my $m;
      use experimental 'smartmatch';
      eval {
	$j->incr_text =~ m/^(?:(\s*"([^"]+)"\s*:\s*)|(\s*}\s*))/; # look ahead
	$m = $2||$3;
	if ($m && ($m eq 'columns') && ($current eq 'RESULTS_STREAM')) {
	  # if this is a 'results' item, don't eat the 'columns',
	  # let the results stream do it
	  $m = undef;
	}
	else {
	  $j->incr_text =~ s/^(?:(\s*"([^"]+)"\s*:\s*)|(\s*}\s*))//; # consume
	}

      };

      if ($@ =~ /already started parsing/  || !$m) {
	# either another function instance is in the middle of parsing,
	# or no key was found (which is the same thing)
	# so report where this instance is:
	return node([$key => $current], promise { $po->() });
      }
      elsif ($@) {
	die "j_parse: incr parser error: $@";
      }
      $key = $m;
    }
    use experimental 'smartmatch';
    given ($key) {
      when ('columns') {
	eval {
	  $obj = $j->incr_parse;
	};
	die "j_parse: incr parser error: $@" if $@;
	$current = 'COMPLETE';
      }
      when (/commit/) {
	$j->incr_text =~ s/^"([^"]+)"\s*,?\s*//;
	$obj = $1;
	$current = 'COMPLETE';
      }
      when (/transaction/) {
	eval {
	  $obj = $j->incr_parse; # get txn info obj
	};
	die "j_parse: incr parser error: $@" if $@;
	$current = 'COMPLETE';
      }
      when ('data') {
	if ($j->incr_text =~ s/^\[\s*//) {
	  $obj = j_parse_array($j);
	  $current = 'DATA_STREAM';
	}
	else {
	  die "j_parse: expecting an array value for 'data' key";
	}
      }
      when ('results') {
	if ($j->incr_text =~ s/^\[\s*//) {
	  $j->incr_text =~ s/^\s*{\s*//;
	  eval {
	    $obj = j_parse_object($j);
	  };
	  die "j_parse: incr parser error: $@" if $@;
	  $current = 'RESULTS_STREAM';
	}
	elsif ($j->incr_text eq '') {
	  $current = 'DONE';
	  $done=1;
	}
      }
      when ('errors') {
	if ($j->incr_text=~ s/^\[\s*//) {
	  $obj = j_parse_array($j);
	  $current = 'ERRORS_STREAM';
	}
	elsif ($j->incr_text =~ s/^\s*\]\s*,?\s*//) {
	  $current = 'DONE';
	  $done=1;
	}
      }
      when (/}/) {
	if ($current eq 'DATA_STREAM') {
	  if ($j->incr_text =~ s/^\s*,\s*{//) {
	    # prepared for next results object
	    $obj = j_parse_object($j);
	    $key = 'results';
	    $current = 'RESULTS_STREAM';
	  }
	  elsif ($j->incr_text =~ s/^\s*\]\s*,?\s*//) {
	    $current = 'DONE';
	    $done=1;
	  }
	  elsif ($j->incr_text eq '') {
	    $current = 'DONE';
	    $done=1;
	  }
	}
	else {
	  $current = 'DONE';
	  $done=1;
	}
      }
      when (undef) {
	die "j_parse: No key found";
      }
      default {
	# why am I here?
	die "j_parse: Unexpected key '$key' in stream";
      }
    }
    if (defined $obj) {
      $head = [$key => $obj];
      $j->incr_text =~ s/^(?:(\s*,\s*)|(\s*}\s*))//;
      $done = !!$2;
    }
    else {
      $head = $done ? undef : [$key => $current = 'PENDING'];
    }
    return node($head, $done ? undef : promise { $po->() }) if $head;
    return node(undef, undef);
  };
  return $po;
}

=head1 NAME

REST::Neo4p::ParseStream - Parse Neo4j REST responses on the fly

=head1 SYNOPSIS

 Not for human consumption.
 This module is ignored by the Neo4j::Driver-based agent.

=head1 DESCRIPTION

This module helps L<REST::Neo4p> exploit the L<Neo4j|http://neo4j.org>
server's chunked transfer encoding of its JSON REST responses. It is
based on the fast L<JSON::XS> incremental parser and
L<MJD|https://metacpan.org/author/MJD>'s L<Higher Order
Perl|http://hop.perl.plover.com> ideas as implemented in
L<HOP::Stream>.

The goal is to be able to pull in objects from the server stream as
soon as they are available. In practice, this means specifically
finding and incrementally processing the potentially large arrays of
objects that are returned from cypher queries, transaction queries,
and batch requests.

Because of inconsistencies among the Neo4j response formats for each
of these functions, this module does a significant amount of
"hand-parsing". Currently the code will not be very robust to changes
in those response formats. If you find your query handling is breaking
with a new server version, L<make a
ticket|https://rt.cpan.org/Public/Bug/Report.html?Queue=REST-Neo4p>. In
the meantime, you should be able to keep things going (albeit more
slowly) by turning off streaming at the agent:

 use REST::Neo4p;
 REST::Neo4p->agent->no_stream;
 ...

=head1 SEE ALSO

L<REST::Neo4p>, L<REST::Neo4p::Query>, L<REST::Neo4p::Batch>,
L<HOP::Stream>, L<JSON::XS/"INCREMENTAL PARSING">.

=head1 AUTHOR

   Mark A. Jensen
   CPAN ID: MAJENSEN
   majensen -at- cpan -dot- org

=head1 LICENSE

Copyright (c) 2012-2021 Mark A. Jensen. This program is free software; you
can redistribute it and/or modify it under the same terms as Perl
itself.

=cut

1;
