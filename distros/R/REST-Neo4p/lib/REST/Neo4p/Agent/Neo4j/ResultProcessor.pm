package
  REST::Neo4p::Agent::Neo4j::Driver;

use REST::Neo4p::Exceptions;

our %result_processors;

# The parameters of each function is the parameter array @_ of the corresponing calling action function
# (see DriverActions.pm). $_ is set to the Neo4j::Driver::StatementResult object returned by the Cypher
# call made in the calling function.
# Each function returns a Perl data structure that corresponds to (possibly a subset of) the JSON that would
# have been returned by the old Neo4j REST endpoint.

$result_processors{get_node} = sub {
  my ($id, @other) = @_;
  my $r;
  if (!@other) {
    my @r = $_->list;
    REST::Neo4p::NotFoundException->throw unless @r;
    $r = $r[0]->get(0);
    return { metadata => { id => $r->id, labels => [$r->labels] },
	     self => 'node/'.$r->id,
	     data => $r->properties };
  }
  else {
    ($other[0] =~ /^labels|properties$/) && do {
      my @r = $_->list;
      REST::Neo4p::NotFoundException->throw unless @r;
      $r = $r[0]->get(0);
      return $r;
    };
    ($other[0] eq 'relationships') && do {
      my $ret = [];
      while (my $rec = $_->fetch) {
	$r = $rec->get(0);
	push @$ret, {
	  metadata => { id => $r->id, type => $r->type },
	  self => 'relationship/'.$r->id,
	  data => $r->properties,
	  start => 'node/'.$r->start_id,
	  end => 'node/'.$r->end_id,
	  type => $r->type
	 }
      }
      return $ret;
    };
  }
};

$result_processors{delete_node} = sub {
  return;
};

$result_processors{post_node} = sub {
  my ($utok, $content, $hdrs) = @_;
  my $r;
  if (!$utok || !@$utok) {
    my @r = $_->list;
    REST::Neo4p::NotFoundException->throw unless @r;
    $r = $r[0]->get(0);
    return {
      metadata => { id => $r->id, labels => [] },
      self => 'node/'.$r->id,
      data => {}
     };
  }
  else {
    my ($id, $ent, @rest) = @$utok;
    ($ent eq 'labels') && do {
      return;
    };
    ($ent eq 'relationships') && do {
      my @r = $_->list;
      REST::Neo4p::NotFoundException->throw unless @r;
      $r = $r[0]->get(0);
      return {
	  metadata => { id => $r-id, type => $r->type },
	  self => 'relationship/'.$r->id,
	  data => $r->properties,
	  start => 'node/'.$r->start_id,
	  end => 'node/'.$r->end_id,
	  type => $r->type
	 };
    };
  }
};

$result_processors{get_relationship} = sub {
  my ($id, @other) = @_;
  if (!@other) {
    ($id eq 'types') && do {
      return [ map { $_->get(0) } $_->list ];
    };
    do {
      my @r = $_->list;
      REST::Neo4p::NotFoundException->throw() unless @r;
      my $r = $r[0]->get(0);
      return {
	  metadata => { id => $r->id, type => $r->type },
	  self => 'relationship/'.$r->id,
	  data => $r->properties,
	  start => 'node/'.$r->start_id,
	  end => 'node/'.$r->end_id,
	  type => $r->type
	 };
    };
  }
  else {
    ($other[0] eq 'properties') && do {
      my @r = $_->list;
      REST::Neo4p::NotFoundException->throw unless @r;
      $r = $r[0]->get(0);
      return $r;
    };
    return;
  }
};

$result_processors{delete_relationship} = sub {
  return;
};

$result_processors{put_relationship} = sub {
  return;
};

$result_processors{get_labels} = sub {
  return [ map { $_->get(0) } $_->list ];
};

$result_processors{get_label} = sub {
  my $ret = [];
  while (my $rec = $_->fetch) {
    my $r = $rec->get(0);
    push @$ret, { metadata => { id => $r->id, labels => [$r->labels] },
		  self => 'node/'.$r->id,
		  data => $r->properties };
  }
  return $ret;
};

$result_processors{get_index} = sub {
  my ($ent, $idx, @other) = @_;
  if (!$idx) {
    my $ret = {};
    while (my $rec = $_->fetch) {
      my $props = $rec->data;
      my $type = $props->{'entityType'} // $props->{'type'} // '';
      if ($type =~ /$ent/i) {
	my $name = $rec->get('name');
	$ret->{$name} = (eval '$rec->get("config")' || {});
	$ret->{$name}{ template } = "index/$ent/$name/\{key\}/\{value\}";
      }
    }
    return $ret;
  }
  else {
    my $ret = [];
    while (my $rec = $_->fetch) {
      my $r = $rec->get(0);
      my @labels = (ref($r) =~ /Node/ ? (labels => [$r->labels]) : ());
      push @$ret, { metadata => { id => $r->id, @labels },
		    self => 'node/'.$r->id,
		    data => $r->properties };
    }
    REST::Neo4p::NotFoundException->throw unless @$ret;
    return $ret;
  }
};

$result_processors{delete_index} = sub {
  return;
};

$result_processors{post_index} = sub {
  my ($utok,$content,$hdrs) = @_;
  my ($ent, $idx, @other) = @$utok;
  if (!$idx) {
    return { template => "index/$ent/$$content{name}/\{key\}/\{value\}" };
  }
  else {
    my $n = $_->fetch->get(0);
    return unless ref $n;
    my $id = $n->id;
    return {
      metadata => { id => $id },
      self => "$ent/$id",
      ($n->properties ? (data => $n->properties) : ()),
      ($n->can(start_id) ? (
	start_id => $n->start_id,
	end_id => $n->end_id,
	type => $n->type
       ) : ()),
      indexed => "index/$ent/$idx/$$content{key}/$$content{value}/$id"
     };
  }
};

$result_processors{delete_schema_constraint} = sub {
  return;
};

$result_processors{post_schema_constraint} = sub {
  my ($utok,$content,$hdrs) = @_;
  my ($lbl, $type) = @$utok;
  return { label => $lbl, type => uc $type, property_keys => $content->{property_keys} };
};

$result_processors{get_schema_index} = sub {
  my ($lbl) = @_;
  return [ map { $_->get(0) } $_->list ];
};

$result_processors{delete_schema_index} = sub {
  return;
};

$result_processors{post_schema_index} = sub {
  my ($utok,$content,$hdrs) = @_;
  my ($lbl) = @$utok;
  return { label => $lbl, property_keys => $content->{property_keys} };  
};

1;
