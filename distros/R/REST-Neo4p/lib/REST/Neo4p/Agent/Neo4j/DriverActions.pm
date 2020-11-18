package
  REST::Neo4p::Agent::Neo4j::Driver;

use v5.10;
use lib '../../../../../lib'; #testing
use REST::Neo4p::Agent::Neo4j::ResultProcessor;
use REST::Neo4p::Exceptions;
use URI::Escape;
use MIME::Base64 qw/encode_base64url/;
use Scalar::Util qw/looks_like_number/;
use Try::Tiny;
use strict;
use warnings;

our %result_processors;
my $SAFE_TOK = qr{[^[!#\$&()*+,/:;<=>@\]^`{|}~\\]+}; # allows %?-_'".

my @action_tokens = qw/node label labels relationship types index schema constraint cypher transaction/;

my @available_actions =
  qw{
      get_data
      delete_data
      post_data
      put_data
      post_cypher
      post_transaction
      delete_transaction
      get_propertykeys
      get_node
      delete_node
      post_node
      put_node
      get_relationship
      get_relationship_types
      delete_relationship
      put_relationship
      get_labels
      get_label
      get_index
      delete_index
      post_index
      get_node_index
      delete_node_index
      post_node_index
      get_relationship_index
      delete_relationship_index
      post_relationship_index
      get_schema_constraint
      delete_schema_constraint
      post_schema_constraint
      put_schema_constraint
      get_schema_index
      delete_schema_index
      post_schema_index
      put_schema_index
  };

# args:
# get|delete : my @url_components = @args;
# post|put : my ($url_components, $content, $addl_headers) = @args;

# throw local errors in place
# capture neo4j / query errors and dispatch from a single routine (= run_in_session) 

# note: most actions will return silently if called in void context. The result is then available in last_result(),
# and is not processed. If called in a non-void context, the result is processed (via ResultProcessors) into a
# json/Perl format suitable for parsing by REST::Neo4p
# 

# data

sub available_actions {
  my $self = shift;
  return @available_actions;
}

sub get_data {
  my $self = shift;
  my @args = @_;
  my ($action, $args) = _parse_action(\@args);
  unless ($action) {
    REST::Neo4p::NotFoundException->throw(code => 404, message => "get_data: action unrecognized");
  }
  my $dispatch = "get_$action";
  $self->$dispatch(@$args);
}

sub delete_data {
  my $self = shift;
  my @args = @_;
  my ($action, $args) = _parse_action(\@args);
  unless ($action) {
    REST::Neo4p::NotFoundException->throw(code => 404, message => "delete_data: action unrecognized");
  }
  my $dispatch = "delete_$action";
  $self->$dispatch(@$args);
}

sub post_data {
  my $self = shift;
  my @args = @_;
  my ($action, $args) = _parse_action($args[0]);
  unless ($action) {
    REST::Neo4p::NotFoundException->throw(code => 404, message => "post_data: action unrecognized");
  }
  my $dispatch = "post_$action";
  $self->$dispatch(@args);
}

sub put_data {
  my $self = shift;
  my @args = @_;
  my ($action, $args) = _parse_action($args[0]);
  unless ($action) {
    REST::Neo4p::NotFoundException->throw(code => 404, message => "put_data: action unrecognized");
  }
  my $dispatch = "put_$action";
  $self->$dispatch(@args);
}

sub _parse_action {
  my ($args) = @_;
  my @action;
  while (@$args) {
    if (! ref($$args[0]) && grep /^$$args[0]$/,@action_tokens) {
      push @action, shift(@$args);
    }
    else {
      last;
    }
  }
  return (join('_',@action),$args);
}

sub _quote_maybe {
  my @ret = map {
    (/^['"].*['"]$/ || looks_like_number $_) ? $_ : "'$_'"
  } @_;
  wantarray ? @ret : $ret[0];
}

sub _throw_unsafe_tok {
  return 1 if (!defined $_[0] || ref $_[0]);
  REST::Neo4p::LocalException->throw("token $_[0] is unsafe") unless ($_[0] =~ /^$SAFE_TOK$/);
  return;
}

sub post_cypher {
  my $self = shift;
  my ($ary, $qry, $addl_headers) = @_;
  # $ary not used
  my $result = $self->run_in_session( $qry->{query}, $qry->{params} // () );
  return $result;
}

# Keep track of transactions with a cache hash and an arbitrary
# sequence. Neo4j::Driver doesn't maintain the actual transaction
# id of the server, but uses the Session to isolate transactions
# So the transaction number in the returned (partial) "commit" url
# is a kludge (the index in the cache)

sub post_transaction {
  my $self = shift;
  my ($ary, $qry_h, $addl_headers) = @_;
  state $txn = 0;
  if (!@$ary) { # begin
    try {
      $txn++;
      $self->{_txns}{$txn} = $self->session->begin_transaction;
      return { commit => "transaction/$txn/commit", errors => [] };
    } catch {
      $txn--;
      return { errors => [$_] };
    };
  }
  elsif ($ary->[1] && ($ary->[1] eq 'commit')) { # commit
    my $tx = delete $self->{_txns}->{$$ary[0]};
    unless (defined $tx) {
      REST::Neo4p::LocalException->throw("Transaction has vanished\n");
    }
    try {
      $tx->commit;
      return { results => [], errors => [] }; # would there ever be a non-trival return from a commit?
    } catch {
      REST::Neo4p::Neo4jException->throw($_);
    };
  }
  else { # run
    my $tx = $self->{_txns}{$$ary[0]};
    my $stmt = $qry_h->{statements}->[0]->{statement};
    my $params = $qry_h->{statements}->[0]->{parameters};
    my $result = $self->run_in_transaction($tx, $stmt, $params);
    return $result;
  }
}

sub delete_transaction {
  my $self = shift;
  my ($txn) = @_;
  unless (defined $txn) {
    REST::Neo4p::LocalException->throw("delete_transaction requires txn number as arg 1\n");
  }
  my $tx = delete $self->{_txns}->{$txn};
  unless (defined $tx) {
    REST::Neo4p::LocalException->throw("Transaction has vanished\n");
  }
  $tx->rollback;
  return;
}

# propertykeys

sub get_propertykeys {
  my $self = shift;
  my $result = $self->run_in_session('call db.propertyKeys()');
  if ($result) {
    return if !defined wantarray;
    return $self->{_decoded_content} = [ map { $_->get(0) } $result->list ];
  }
}

# node

sub get_node {
  my $self = shift;
  _throw_unsafe_tok($_) for @_;
  my ($id,@other) = @_;
  my $result;
  unless (defined $id) {
    REST::Neo4p::LocalException->throw("get_node requires id as arg1\n");    
  }
  if (!@other) {
    $result = $self->run_in_session('match (n) where id(n)=$id return n', {id => 0+$id});
  }
  else {
    for ($other[0]) {
      /^labels$/ && do {
	$result = $self->run_in_session('match (n) where id(n)=$id return labels(n)', { id => 0+$id });
	last;
      };
      /^properties$/ && do {
	if (!defined $other[1]) {
	  $result = $self->run_in_session('match (n) where id(n)=$id return properties(n)', {id => 0+$id});
	}
	else {
	  $result = $self->run_in_session('match (n) where id(n)=$id return n[$prop]', {id => 0+$id, prop => $other[1]});
	}
	last;
      };
      /^relationships$/ && do {
	my $ptn='';
	my $type_cond = '';
	for ($other[1]) {
	  /^all$/ && do {
	    $ptn = '(n)-[r]-()';
	    last;
	  };
	  /^in$/ && do {
	    $ptn = '(n)<-[r]-()';
	    last;
	  };
	  /^out$/ && do {
	    $ptn = '(n)-[r]->()';	    
	    last;
	  };
	  REST::Neo4p::LocalException->throw("get_node relationships action '$other[1]' is unknown\n");
	}
	if ($other[2]) {
	  my @types = split /&/,$other[2];
	  $type_cond = 'and type(r) in ['.join(',',_quote_maybe(@types)).']';
	}
	$result = $self->run_in_session(
	  "match $ptn where id(n)=\$id $type_cond return r",
	  { id => 0+$id }
	 );
	last;
      };
      REST::Neo4p::LocalException->throw("get_node action '$other[2]' is unknown\n");
    }
  }
  if ($result) {
    return if !defined wantarray;
    local $_ = $result;
    return $result_processors{get_node}->(@_);
  }
}

sub delete_node {
  my $self = shift;
  my ($id,@other) = @_;
  my $result;
  _throw_unsafe_tok($_) for @_;
  unless (defined $id) {
    REST::Neo4p::LocalExeception->throw("delete_node requires id as arg1\n");    
  }
  if (!@other) {
    $result = $self->run_in_session('match (n) where id(n)=$id delete n', {id => 0+$id});
  }
  else {
    for ($other[0]) {
      /^properties$/ && do {
	if ($other[1]) {
	  $result = $self->run_in_session("match (n) where id(n)=\$id remove n.$other[1]",{id => 0+$id});
	}
	else {
	  $result = $self->run_in_session('match (n) where id(n)=$id set n = {}',{id => 0+$id})
	}
	last;
      };
      /^labels$/ && do {
	$result = $self->run_in_session("match (n) where id(n)=\$id remove n:$other[1]",{id => 0+$id});
	last;
      };
      REST::Neo4p::LocalException->throw("delete_node action '$other[0]' is unknown\n");
    }
  }
  if ($result) {
    return if !defined wantarray;
    local $_ = $result;
    return $result_processors{delete_node}->(@_);
  }
}

sub post_node {
  my $self = shift;
  my ($url_components,$content,$addl_headers) = @_;
  my $result;
  if (!$url_components || !@$url_components) {
    if (!$content) {
      $result = $self->run_in_session('create (n) return n');
    }
    else {
      my $set_clause = '';
      if (scalar(keys %$content)) {
	_throw_unsafe_tok($_) for keys %$content;
#	_throw_unsafe_tok($_) for values %$content;	
	#	my @assigns = map { "n.$_ = "._quote_maybe($$content{$_}) } sort keys %$content;
	my @assigns = map { "n.$_ = \$$_" } sort keys %$content;
	$set_clause = "set ".join(',', @assigns);
      }
      $result = $self->run_in_session("create (n) $set_clause return n",$content);
    }
  }
  else {
    _throw_unsafe_tok($_) for @$url_components;
    my ($id, $ent, @rest) = @$url_components;
    REST::Neo4p::LocalException->throw("'$id' doesn't look like a node id") unless $id =~ /^[0-9]+$/;
    for ($ent) {
      /^labels$/ && do {
	my @lbls = (ref $content ? @$content : $content);
	$result = $self->run_in_session('match (n) where id(n)=$id set n:'.join(':',@lbls),
					{ id => 0+$id });
	last;
      };
      /^relationships$/ && do {
	my ($to_id) = $content->{to} =~ m|node/([0-9]+)$|;
	unless (defined $to_id) {
	  REST::Neo4p::LocalException->throw("Can't parse 'to' node id from content\n");
	}
	unless ($content->{type}) {
	  REST::Neo4p::LocalException->throw("Create relationship requires 'type' value in content\n");
	}
	my $set_clause = '';
	if (my $props = $content->{data}) {
	  _throw_unsafe_tok($_) for keys %$props;	  
	  _throw_unsafe_tok($_) for values %$props;
	  my @assigns = map { "r.$_="._quote_maybe($$props{$_}) } sort keys %$props;
	  $set_clause = "set ".join(',', @assigns);
	}
	my $type=$content->{type};
	$result = $self->run_in_session(
	  "match (n), (m) where id(n)=\$fromid and id(m)=\$toid create (n)-[r:$type]->(m) $set_clause return r",
	  {fromid=>0+$id, toid=>0+$to_id}
	 ); 
	last;
      };
      # else
      do {
	REST::Neo4p::NotImplException->throw("post action '$_' not implemented for nodes in agent\n");
	last;
      };
    }
  }
  if ($result) {
    return if !defined wantarray;
    local $_ = $result;
    return $result_processors{post_node}->(@_);
  }
}

sub put_node {
  my $self = shift;
  my ($url_components,$content,$addl_headers) = @_;
  unless (defined $url_components) {
    REST::Neo4p::LocalExeception->throw("put_node requires [\$id,...] as arg1\n");
  }
  _throw_unsafe_tok($_) for @$url_components;
  my ($id,$ent,@rest) = @$url_components;
  REST::Neo4p::LocalException->throw("'$id' doesn't look like a node id") unless $id =~ /^[0-9]+$/;
  my $result;
  for ($ent) {
    /^properties$/ && do {
      if (defined $rest[0]) {
	REST::Neo4p::LocalException->throw('call with put_node([<id>,\'properties\',<prop>],$content) needs content to be plain scalar (the value of <prop>)') if ref($content);
	$result = $self->run_in_session("match (n) where id(n)=\$id set n.$rest[0]=\$value return n", {id => 0+$id, value => $content});
      }
      else {
	_throw_unsafe_tok($_) for keys %$content;
	_throw_unsafe_tok($_) for values %$content;	
	my @assigns = map { "n.$_="._quote_maybe($$content{$_}) } sort keys %$content;
	my $set_clause = "set ".join(',', @assigns);
	$result = $self->run_in_session("match (n) where id(n)=\$id $set_clause return n", {id => 0+$id});
      }
      last;
    };
    /^labels$/ && do {
      # this action needs to remove all labels from node, and add
      # those that are in the call arguments.
      _throw_unsafe_tok($_) for @$content;
      $result = $self->run_in_session('match (n) where id(n)=$id return labels(n)',{id => 0+$id});
      my $rec = $result->fetch;
      if ($rec) {
	for my $lbl (@{$rec->get(0)}) {
	  $self->run_in_session('match (n) where id(n)=$id remove n:'.$lbl,{id => 0+$id});
	}
      }
      $result = $self->run_in_session('match (n) where id(n)=$id set n:'.join(':',@$content),{id => 0+$id});
      last;
    };
    # else
    do {
      REST::Neo4p::NotImplException->throw("put action '$_' not implemented for nodes in agent\n");
      last;
    };
  }
}

# relationship

sub get_relationship {
  my $self = shift;
  _throw_unsafe_tok($_) for @_;
  my ($id,@other) = @_;
  my $result;
  unless (defined $id) {
    REST::Neo4p::LocalExeception->throw("get_relationship requires id as arg1\n");
  }
  if (!@other) {
    for ($id) {
      /^[0-9]+$/ && do {
	$result = $self->run_in_session('match ()-[r]->() where id(r)=$id return r', {id => 0+$id});
	last;
      };
      /^types$/ && do {
	$result = $self->run_in_session('call db.relationshipTypes()');
	last;
      };
#      REST::Neo4p::LocalException->throw("get_relationship action '$id' is unknown\n");
    }
  }
  else {
    for ($other[0]) {
      /^properties$/ && do {
	if (!defined $other[1]) {
	  $result = $self->run_in_session('match ()-[r]->() where id(r)=$id return properties(r)',{id => 0+$id});
	}
	else {
	  $result = $self->run_in_session('match ()-[r]->() where id(r)=$id return r[$prop]',{id => 0+$id, prop => $other[1]});
	}
	last;
      };
      REST::Neo4p::LocalException->throw("get_relationship action '$other[0]' is unknown\n");      
    }
  }
  if ($result) {
    return if !defined wantarray;
    local $_ = $result;
    return $result_processors{get_relationship}->(@_);
  }
}

sub delete_relationship {
  my $self = shift;
  _throw_unsafe_tok($_) for @_;
  my ($id,@other) = @_;
  my $result;
  unless (defined $id) {
    REST::Neo4p::LocalExeception->throw("delete_relationship requires id as arg1\n");    
  }
  if (!@other) {
    $result = $self->run_in_session('match ()-[r]->() where id(r)=$id delete r', {id => 0+$id});
  }
  else {
    for ($other[0]) {
      /^properties$/ && do {
	if ($other[1]) {
	  $result = $self->run_in_session("match ()-[r]->() where id(r)=\$id remove r.$other[1]",{id => 0+$id});
	}
	else {
	  $result = $self->run_in_session('match ()-[r]->() where id(r)=$id set r = {}',{id => 0+$id})
	}
	last;
      };
      REST::Neo4p::LocalException->throw("delete_relationship action '$other[0]' is unknown\n");
    }
  }
  if ($result) {
    return if !defined wantarray;
    local $_ = $result;
    return $result_processors{delete_relationship}->(@_);
  }
}

# sub post_relationship {
#  my $self = shift;
# }

sub put_relationship {
  my $self = shift;
  my ($url_components,$content,$addl_headers) = @_;
  unless (defined $url_components) {
    REST::Neo4p::LocalExeception->throw("put_node requires [\$id,...] as arg1\n");
  }
  _throw_unsafe_tok($_) for @$url_components;
  my ($id,$ent,@rest) = @$url_components;
  REST::Neo4p::LocalException->throw("'$id' doesn't look like a relationship id") unless $id =~ /^[0-9]+$/;
  REST::Neo4p::LocalException->throw("action for '$id' not specified in arrayref") unless defined $ent;
  my $result;
  for ($ent) {
    /^properties$/ && do {
      if (defined $rest[0]) {
	REST::Neo4p::LocalException->throw('call with put_relationship([<id>,\'properties\',<prop>],$content) needs content to be plain scalar (the value of <prop>)') if ref($content);
	$result = $self->run_in_session("match ()-[r]->() where id(r)=\$id set r.$rest[0]=\$value return r", {id => 0+$id, value => $content});
      }
      else {
	_throw_unsafe_tok($_) for keys %$content;
	_throw_unsafe_tok($_) for values %$content;
	my @assigns = map { "r.$_="._quote_maybe($$content{$_}) } sort keys %$content;
	my $set_clause = "set ".join(',', @assigns);
	$result = $self->run_in_session("match ()-[r]->() where id(r)=\$id $set_clause return r", {id => 0+$id});
      }
      last;
    };
    # else
    do {
      REST::Neo4p::NotImplException->throw("put action '$_' not implemented for relationships in agent\n");
      last;
    };
  }
}

# labels

sub get_labels {
  my $self = shift;
  my $result = $self->run_in_session('call db.labels()');
  if ($result) {
    return if !defined wantarray;
    local $_ = $result;
    return $result_processors{get_labels}->(@_);
  }
}

sub get_label {
  my $self = shift;
  _throw_unsafe_tok($_) for @_;
  my ($lbl, @other) = @_;
  my $result;
  REST::Neo4p::LocalException->throw("get_label requires label as arg1\n") unless defined $lbl;
  my $params = $other[-1];
  if (ref $params eq 'HASH') {
    my @cond;
    for my $p (sort keys %$params) {
      push @cond, "n.$p=\$$p";
      $params->{$p} = uri_unescape($params->{$p});
      $params->{$p} =~ s/^["']//;
      $params->{$p} =~ s/["']$//;
      $params->{$p}+=0 if looks_like_number $params->{$p};
    }
    my $where_clause = 'where '.join(' and ',@cond);
    $result = $self->run_in_session("match (n:$lbl) $where_clause return n", $params)
  }
  else {
    $result = $self->run_in_session("match (n:$lbl) return n");
  }
  if ($result) {
    return if !defined wantarray;
    local $_ = $result;
    return $result_processors{get_label}->(@_);
  }
}

# sub delete_labels{
#   my $self = shift;
# }

# sub post_labels {
#   my $self = shift;
# }

# sub put_labels {
#   my $self = shift;
# }

# indexes

sub get_index {
  my $self = shift;
  my ($ent, $idx, @other) = @_;
  _throw_unsafe_tok($_) for ($ent, $idx);
  my $result;

  if (!$idx) {
    # TODO: returns all indexes - should filter based on $ent
    $result = $self->is_version_4 ?
      $self->run_in_session('call db.indexes() yield name, type, entityType where type = "FULLTEXT" and entityType = $ent return entityType, name, type',{ent => uc $ent}) :
      $self->run_in_session('call db.index.explicit.list()');
  }
  else {
    # find things
    my $params = $other[-1];
    my $seek;
    if ($self->is_version_4) {
      $seek =  ($ent eq 'node' ? 'queryNodes' : 'queryRelationships');
    }
    else {
      $seek = ($ent eq 'node' ? 'seekNodes' : 'seekRelationships');
    }
    # kludge
    if (!ref($params) && $params =~ /[?]/) {
      my ($k,$v) = $params =~ /^.*\?(.*)=(.*)$/;
      $params = { $k => $v };
    }
    if (!ref $params) { # key/value

      my ($key, $value) = @other;
      unless (defined $key && defined $value) {
	REST::Neo4p::LocalException->throw("get_index : can't interpret parameters for either key-value or query search\n");
      }
      $value = uri_unescape($value);
      $value +=0 if looks_like_number $value;
      if ($self->is_version_4) {
	my $yld = ($ent eq 'node' ? 'node' : 'relationship');
	my $hkey = encode_base64url($key,'');
	$result = $self->run_in_session(
	  "call db.index.fulltext.$seek(\$idx,\$key) yield $yld
           where ${yld}[\$valprop] = \$value return $yld",
	  { idx => $idx, key => $hkey, valprop => "_xi_${hkey}",
	    value => $value });
      }
      else {
	$result = $self->run_in_session("call db.index.explicit.$seek(\$idx,\$key,\$value)",
					{ idx => $idx, key => $key, value => $value });
      }
    }
    elsif (ref $params eq 'HASH') { # query
      if ($self->is_version_4) {
	REST::Neo4p::LocalException->throw("get_index : refusing a fulltext query on emulated explicit index; create a true fulltext index instead\n")
      }
      unless (defined $params->{query}) {
	REST::Neo4p::LocalException->throw("get_index : key 'query' required in param hash");
      }
      my $search = ($ent eq 'node' ? 'searchNodes' : 'searchRelationships');
      my $query = uri_unescape($params->{query});
      $result = $self->run_in_session("call db.index.explicit.$search(\$idx,\$query)",
				      { idx => $idx, query => $query });
    }
    else {
      REST::Neo4p::LocalException->throw("get_index : can't interpret parameters for either key-value or query search\n");
    }
  }
  if ($result) {
    return if !defined wantarray;
    local $_ = $result;
    return $result_processors{get_index}->(@_);
  }
}

sub delete_index {
  my $self = shift;
  _throw_unsafe_tok($_) for @_;
  my ($ent, $idx, @other) = @_;
  my $result;
  REST::Neo4p::LocalException->throw("delete_index required index name at arg 2\n")
      unless defined $idx;
  if (!@other) {
    if ($self->is_version_4) {
      # cleanup helper label and properties and remove index
      my $tx = $self->session->begin_transaction;
      # problem in vanilla cypher - cannot _set_ map values using computed keys
      # - you can _get_ values only
      # collect all the distinct keys over the indexed nodes
            
      if ($ent eq 'node') {
	$result = $tx->run("match (a:__${idx}__index) return distinct a.__${idx}__keys");
      }
      else {
	$result = $tx->run("match ()-[r]->() where exists(r.__${idx}__keys) return distinct r.__${idx}__keys");
      }
      my (%k,%remove);
      for my $k ($result->list()) {
	$k{$_}++ for split(/\s+/,$k);
      }
      my @k = map { "_xi_$_" } keys %k;
      @remove{@k} = (undef) x scalar @k;
      # now \%remove is a parameter that can remove all the index's value props
      if ($ent eq 'node') {
	$tx->run("match (a:__${idx}__index) set a += \$rm remove a.__${idx}__keys",
		 { rm => \%remove });
      }
      else { #relationship
	$tx->run("match ()-[r]->() where exists(r.__${idx}__keys) set r += \$rm remove r.__${idx}__keys",
		 { rm => \%remove });
      }
      $tx->commit;
      $result = $self->run_in_session('call db.index.fulltext.drop($idx)', {idx => $idx});
    }
    else {
      $result = $self->run_in_session('call db.index.explicit.drop($idx)',{idx => $idx});
    }
  }
  else {
    my $id = pop @other;
    my ($k, $v) = @other;
    if ($self->is_version_4) {
      my $ptn  = ($ent eq 'node' ? '(n)' : '()-[n]->()');
      my $hkey = encode_base64url($k,'');
      $result = $self->run_in_session(
	"match $ptn where id(n)=\$id return n.__${idx}__keys", {id => 0+$id}
       );
      my $keys = $result->single()->get(0);
      $keys =~ s/$hkey//; # remove this key
      $result = $self->run_in_session(
	"match $ptn where id(n)=\$id set n.__${idx}__keys = \$keys remove n._xi_${hkey} ", { id => $id, keys=>$keys } );
      if ($keys =~ /^\s*$/) { # last key removed
	$result = $self->run_in_session(
	  "match $ptn where id(n)=\$id remove n.__${idx}__keys ".($ent eq 'node' ? "remove n:__${idx}__index" : ""), { id => $id }
	 );
      }
    }
    else {
      my $remove = ($ent eq 'node' ? 'removeNode' : 'removeRelationship');
      my $ptn = ($ent eq 'node' ? '(n)' : '()-[n]->()');
      my $args = (defined $k ? '$idx, n, $key' : '$idx, n' );
      $result = $self->run_in_session(
	"match $ptn where id(n)=\$id call db.index.explicit.$remove( $args )
         yield success return n",
	{idx => $idx, id => 0+$id, (defined $k ? (key => $k) : ())});
    }
  }
  if ($result) {
    return if !defined wantarray;
    local $_ = $result;
    return $result_processors{delete_index}->(@_);
  }
}

sub post_index {
  my $self = shift;
  my ($url_components, $content, $addl_parameters) = @_;
  my $result;
  REST::Neo4p::LocalException->throw('post_index requires arrayref of url components as arg1') unless (defined $url_components and ref($url_components) eq 'ARRAY');
  REST::Neo4p::LocalException->throw('post_index requires content hashref as arg2') unless (defined $content and ref($content) eq 'HASH');
  # kludge
  if ($url_components->[1] && $url_components->[1] =~ /[?]/) {
    my ($nm,$pm,$val) = $url_components->[1] =~ /^(.*)\?(.*)=(.*)$/;
    $addl_parameters->{$pm} = $val;
    $url_components->[1] = $nm;
  }
  _throw_unsafe_tok($_) for @$url_components;
  my ($ent, $idx, @other) = @$url_components;
  if ($content && $content->{value}) {
    $content->{value} += 0 if looks_like_number $content->{value};
  }
  if (! defined $idx) { # create index
    REST::Neo4p::LocalException->throw("post_index create index requires 'name' key in \$content hash\n") unless defined $content->{name};
    if ($self->is_version_4) {
      if ($ent eq 'relationship') {
	REST::Neo4p::LocalException->throw("post_index (Neo4j v4.0+) create relationship index requres 'type' key in \$content hash\n") unless defined $content->{type};
      }
      my $type = ($ent eq 'node') ? 'Node' : 'Relationship';
      $result = $self->run_in_session("call db.index.fulltext.create${type}Index(\$name, [\$token], [\$prop], {analyzer:'whitespace'}) return 1", {
	name => $content->{name},
	token => $content->{type} // "__$$content{name}__index",
	prop => "__$$content{name}__keys"
       });
    }
    else {
      my $for = ($ent eq 'node') ? 'forNodes' : 'forRelationships';
      $result = $self->run_in_session("call db.index.explicit.$for(\$name)",$content);
    }
  }
  else {
    REST::Neo4p::LocalException->throw("post_index add to index requires 'key','value'keys in \$content hash\n") unless (defined $content->{key} && defined $content->{value});
    if (defined $content->{uri}) { # add entity
      my ($id) = $content->{uri} =~ /(?:node|relationship)\/([0-9]+)$/;
      REST::Neo4p::LocalException->throw("need a node or relationship uri for 'uri' key value in \$content hash\n") unless defined $id;
      delete $content->{uri};
      $content->{id} = 0+$id;
      $content->{idx} = $idx;
      my $ptn = ($ent eq 'node' ? '(n)' : '()-[n]->()');
      my $lbl = ($ent eq 'node' ? "set n:__${idx}__index" : '');
      my $add = ($ent eq 'node' ? 'addNode' : 'addRelationship');
      if ($self->is_version_4) {
	my $hkey = encode_base64url($content->{key},'');
	my $xi_prop = "_xi_$hkey";
	$content->{xi_hkey} = $hkey;
	$result = $self->run_in_session("match $ptn where id(n)=\$id $lbl set n += { __${idx}__keys: case n['__${idx}__keys'] when null then \$xi_hkey else n['__${idx}__keys']+' '+\$xi_hkey end, $xi_prop:\$value } return 1", $content);
      }
      else {
	$result = $self->run_in_session("match $ptn where id(n)=\$id call db.index.explicit.$add(\$idx,n,\$key,\$value) yield success with n, success return case success when true then n else false end as result", $content);
      }
    }
    elsif (defined $content->{properties} or
	     defined $content->{type}) { # merge entity
      my $props = delete $content->{properties};
      my $seek;
      if ($self->is_version_4) {
	$seek =  ($ent eq 'node' ? 'queryNodes' : 'queryRelationships');
      } else {
	$seek = ($ent eq 'node' ? 'seekNodes' : 'seekRelationships');
      }
      # first, check index with key:value
      eval {
	if ($self->is_version_4) {
	  my $yld = ($ent eq 'node' ? 'node' : 'relationship');
	  my $hkey = encode_base64url($content->{key},'');
	  $result = $self->run_in_session(
	    "call db.index.fulltext.$seek(\$idx,\$hkey) yield $yld
           where ${yld}[\$valprop] = \$value return $yld",
	    { idx => $idx, hkey => $hkey, valprop => "_xi_${hkey}",
	      value => $$content{value} });
	}
	else {
	  $result = $self->run_in_session("call db.index.explicit.$seek(".join(', ', map { _quote_maybe($_) } ($idx, $$content{key}, $$content{value})).")");
	}
	$result = undef unless $result->has_next;
      };
      if ($result) { # found it
	if (defined $addl_parameters && ($addl_parameters->{uniqueness} eq 'create_or_fail')) {
	  REST::Neo4p::ConflictException->throw("found entity with create_or_fail specified");
	}
	else {
	  return if !defined wantarray;
	  local $_ = $result;
	  return $result_processors{post_index}->(@_);
	}
      }
      # didn't find it, create it
      my $set_clause = '';
      if (scalar(keys %$props)) {
	_throw_unsafe_tok($_) for keys %$props;	    
	_throw_unsafe_tok($_) for values %$props;
	my @assigns = map { "n.$_="._quote_maybe($$props{$_}) } sort keys %$props;
	$set_clause = "set ".join(',', @assigns);
      }
      for ($ent) {
	/^node$/ && do {
	  $result = $self->run_in_session("create (n) $set_clause return n");
	  $content->{id} = 0+$result->fetch->get(0)->id;
	  if ($self->is_version_4) {
	    my $hkey = encode_base64url($content->{key},'');
	    my $xi_prop = "_xi_$hkey";
	    $content->{xi_hkey} = $hkey;
	    $result = $self->run_in_session(
	      "match (n) where id(n)=\$id set n:__${idx}__index ".
		"set n.__${idx}__keys = \$xi_hkey ".
		"set n += { `${xi_prop}`:\$value } return true", $content);
	  }
	  else {
	    $result = $self->run_in_session("match (n) where id(n)=\$id call db.index.explicit.addNode('$idx',n,\$key,\$value) yield success return success", $content);
	  }
	  if ($result->peek->get(0)) {
	    $result = $self->run_in_session('match (n) where id(n)=$id return n',$content);
	  }
	  last;
	};
	/^relationship/ && do {
	  my ($start) = $content->{start} =~ /node\/([0-9]+)$/;
	  my ($end) = $content->{end} =~ /node\/([0-9]+)$/;
	  my $type = $content->{type};
	  REST::Neo4p::LocalException->throw("post_index create relationship requires 'start' and 'end' keys\n")
	      unless (defined $start and defined $end and defined $type);
	  $content->{start} = 0+$start;
	  $content->{end} = 0+$end;
	  $result = $self->run_in_session("match (s), (t) where id(s)=\$start and id(t)=\$end create (s)-[n:$type]->(t) $set_clause return n", $content);
	  $content->{id} = 0+$result->fetch->get(0)->id;
	  if ($self->is_version_4) {
	    my $hkey = encode_base64url($content->{key},'');
	    my $xi_prop = "_xi_$hkey";
	    $content->{xi_hkey} = $hkey;
	    $result = $self->run_in_session(
	      "match ()-[r]->() where id(r)=\$id ".
		"set r.__${idx}__keys = \$xi_hkey ".
		"set r += {`${xi_prop}`:\$value} return true", $content);
	  }
	  else {
	    $result = $self->run_in_session("match ()-[r]->() where id(r)=\$id call db.index.explicit.addRelationship('$idx',r,\$key,\$value) yield success return success", $content);
	  }
	  if ($result->peek->get(0)) {
	    $result = $self->run_in_session('match ()-[r]->() where id(r)=$id return r',$content);
	  }
	  last;
	};
	do {
	  REST::Neo4p::LocalException->throw("'$ent' is not an indexable entity\n");
	};
      }
    }
    else {
      REST::Neo4p::LocalException->throw("\$content must have either 'uri' or 'properties' keys\n");
    }
  }
  if ($result) {
    return if !defined wantarray;
    local $_ = $result;
    return $result_processors{post_index}->(@_);
  }
}

sub get_relationship_types { shift->get_relationship("types",@_) }
sub get_node_index { shift->get_index("node",@_) }
sub get_index_node { shift->get_node_index(@_) }
sub delete_node_index { shift->delete_index("node",@_) }
sub delete_index_node { shift->delete_node_index(@_) }
sub post_node_index { unshift @{$_[1]},'node'; shift->post_index(@_) }
sub post_index_node { shift->post_node_index(@_) }
#sub put_node_index { shift->put_index("node",@_) }

sub get_relationship_index { shift->get_index("relationship",@_) }
sub get_index_relationship { shift->get_relationship_index(@_) }
sub delete_relationship_index { shift->delete_index("relationship",@_) }
sub delete_index_relationship { shift->delete_relationship_index(@_) }
sub post_relationship_index { unshift @{$_[1]},'relationship'; shift->post_index(@_) }
sub post_index_relationship { shift->post_relationship_index(@_) }
#sub put_relationship_index { shift->put_index("relationship",@_) }

# constraint

sub get_schema_constraint {
  my $self = shift;
  _throw_unsafe_tok($_) for @_;
  my ($lbl, $type, $prop) = @_;
  my @constraints;
  my $result;
  $result = $self->run_in_session('call db.constraints()');
  if ($result) {
    while (my $rec = $result->fetch) {
      my ($node_label,$reln_type,$x_prop, $u_prop) =
      $rec->get($self->is_version_4 ? 'description' : 0) =~
      /CONSTRAINT ON (?:\( (?:$SAFE_TOK):($SAFE_TOK) \)|\(\)-\[(?:$SAFE_TOK):($SAFE_TOK)\]-\(\)) ASSERT (?:exists\((?:$SAFE_TOK)\.($SAFE_TOK)|\(?(?:$SAFE_TOK)\.($SAFE_TOK)\)? IS UNIQUE)/;
      if (defined $node_label) {
	if (defined $x_prop) {
	  push @constraints, {
	    property_keys => [ $x_prop ],
	    label => $node_label,
	    type => "NODE_PROPERTY_EXISTENCE"
	   };
	}
	elsif (defined $u_prop) {
	  push @constraints, {
	    property_keys => [ $u_prop ],
	    label => $node_label,
	    type => "UNIQUENESS"
	   };
	}
	else {
	  warn "unrecognized constraint: '".$rec->get(0)."'";
	}
      }
      elsif (defined $reln_type) {
	if (defined $x_prop) {
	  push @constraints, {
	    property_keys => [ $x_prop ],
	    relationshipType => $reln_type,
	    type => "RELATIONSHIP_PROPERTY_EXISTENCE"
	   };
	}
	else {
	  warn "unrecognized constraint: '".$rec->get(0)."'";
	}
      }
      else {
	warn "unrecognized constraint: '".$rec->get(0)."'";
      }
    }
    no warnings 'uninitialized';
    return [ grep { (!$lbl || ($_->{label} eq $lbl)) &&
		      (!$prop || ($_->{property_keys}[0] eq $prop)) &&
		      (!$type || ( $_->{type} =~ /$type/i )) } @constraints ];
  }
}

sub delete_schema_constraint {
  my $self = shift;
  _throw_unsafe_tok($_) for @_;
  my ($lbl, $type, $prop) = @_;
  unless (defined $prop) {
    REST::Neo4p::LocalException->throw("delete_schema_constraint requires label, constraint type, and property as args\n");
  }
  if ($type eq 'uniqueness') {
    $type = "n.$prop is unique";
  }
  elsif ($type eq 'existence') {
    $type = "exists(n.$prop)";
  }
  else {
    REST::Neo4p::LocalException->throw("type arg must be 'uniqueness' or 'existence', not '$type'\n");
  }
  my $result = $self->run_in_session("drop constraint on (n:$lbl) assert $type");
  if ($result) {
    return if !defined wantarray;
    local $_ = $result;
    return $result_processors{delete_schema_constraint}->(@_);
  }
}

sub post_schema_constraint {
  my $self = shift;
  my ($url_components, $content) = @_;
  my ($lbl, $type) = @$url_components;
  unless (defined $type) {
    REST::Neo4p::LocalException->throw("post_schema_constraint requires label and constraint type as elts of arg1\n");
  }
  unless (defined $content && $content->{property_keys}) {
    REST::Neo4p::LocalException->throw("post_schema_constraint requires key 'property_keys' in \$content arg\n");
  }
  _throw_unsafe_tok($_) for @_;
  my $prop = $content->{property_keys}[0];
  _throw_unsafe_tok($prop);
  if ($type eq 'uniqueness') {
    $type = "n.$prop is unique";
  }
  elsif ($type eq 'existence') {
    $type = "exists(n.$prop)";
  }
  else {
    REST::Neo4p::LocalException->throw("type arg must be 'uniqueness' or 'existence', not '$type'\n");
  }
  my $result = $self->run_in_session("create constraint on (n:$lbl) assert $type");
  if ($result) {
    return if !defined wantarray;
    local $_ = $result;
    return $result_processors{post_schema_constraint}->(@_);
  }
}

# sub put_schema_constraint { }

# schema index

sub get_schema_index {
  my $self = shift;
  my ($lbl) = @_;
  unless (defined $lbl) {
    REST::Neo4p::LocalException->throw("get_schema_index requires label as arg1\n");
  }
  my ($maj, $min, $pat, $mile) = $self->neo4j_version;
  my $q;
  if ($maj > 3) {
    $q = 'call db.indexes() yield labelsOrTypes as labels, properties where $lbl in labels return { label:$lbl, property_keys:properties }';
  }
  elsif ($maj==3 && $min>=5) { # patch
    $q = 'call db.indexes() yield tokenNames as labels, properties where $lbl in labels return { label:$lbl, property_keys:properties }';
  }
  else {
    $q = 'call db.indexes() yield label, properties where label = $lbl return { label:$lbl, property_keys:properties }';
  }
  my $result = $self->run_in_session($q, {lbl => $lbl});
  if ($result) {
    return if !defined wantarray;
    local $_ = $result;
    return $result_processors{get_schema_index}->(@_);
  }
}

sub delete_schema_index {
  my $self = shift;
  my ($lbl, $prop) = @_;
  unless ( defined $lbl && defined $prop) {
    REST::Neo4p::LocalException->throw("delete_schema_index requires label at arg1 and property at arg2\n");
  }
  my $result = $self->run_in_session("drop index on :${lbl}(${prop})");
  if ($result) {
    return if !defined wantarray;
    local $_ = $result;
    return $result_processors{delete_schema_index}->(@_);
  }
}

sub post_schema_index {
  my $self = shift;
  my ($url_components, $content) = @_;
  my ($lbl) = @$url_components;
  unless (defined $lbl) {
    REST::Neo4p::LocalException->throw("post_schema_index requires label as first elt of arg1\n");
  }
  unless (defined $content && $content->{property_keys}) {
    REST::Neo4p::LocalException->throw("post_schema_index requires key 'property_keys' in \$content arg\n");
  }
  my $result;
  for my $prop ( @{$$content{property_keys}} ) {
    $result = $self->run_in_session("create index on :${lbl}(${prop})");
  }
  if ($result) {
    return if !defined wantarray;
    local $_ = $result;
    return $result_processors{post_schema_index}->(@_);
  }
}

# sub put_schema_index { }

####
1;
