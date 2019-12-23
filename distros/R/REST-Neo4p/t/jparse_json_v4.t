use v5.10.1;
use lib qw{t ../lib};
use Test::More;
use Test::Exception;

use REST::Neo4p::Exceptions;
use REST::Neo4p::ParseStream;
use HOP::Stream qw/drop/;
use JSON;
use ErrJ;
use strict;

my $j = $ErrJ::txn_short_resp;
# $j = $ErrJ::txn_baddata_resp;

my $jsonr = JSON->new->utf8;
my ($ERR,$res,$str,$rowstr,$obj);
my $ITER;
my $row_count;
use experimental 'smartmatch';

$jsonr->incr_parse($j);
eval { # capture j_parse errors
  $res = j_parse($jsonr);
  die 'j_parse: No text to parse' unless $res;
  die 'j_parse: JSON is not a query or txn response' unless $res->[0] =~ /QUERY|TXN/;
  for ($res->[0]) {
    /QUERY/ && do {
      $obj = drop($str = $res->[1]->());
      die 'j_parse: columns key not present' unless $obj && ($obj->[0] eq 'columns');
      # $self->{NAME} = $obj->[1];
      say "NAME:".$obj->[1];
      # $self->{NUM_OF_FIELDS} = scalar @{$obj->[1]};
      say "NUM_OF_FIELDS: ".(scalar @{$obj->[1]});
      $obj = drop($str);
      die 'j_parse: data key not present' unless $obj->[0] eq 'data';
      $rowstr = $obj->[1]->();
      # query iterator
      $ITER =  sub {
	# return unless defined $self->tmpf;
	my $row;
	my $item;
	$item = drop($rowstr);
	unless ($item) {
	  undef $rowstr;
	  return;
	}
	$row = $item->[1];
	if (ref $row) {
	  # return $self->_process_row($row);
	  say "process row at ".__LINE__;
	}
	else {
	  my $ret;
	  eval {
	    if ($row eq 'PENDING') {
	      if (0) {# $self->tmpf->read($buf, $BUFSIZE)) {
		# $jsonr->incr_parse($buf);
		$ret = $ITER->();
	      } else {
		$item = drop($rowstr);
		# $ret = $self->_process_row($item->[1]);
		say "process row at ".__LINE__;		
	      }

	    } else {
	      die "j_parse: barf(qry)"
	    }
	  };
	  if (my $e = Exception::Class->caught()) {
	    if ($e =~ /j_parse|json/i) {
	      $e = REST::Neo4p::StreamException->new(message => $e);
	      $ERR = $e;
	      # $self->{_error} = $e;
	      $e->throw; # if $self->{RaiseError};
	      return;
	    } else {
	      die $e;
	    }
	  }
	  return $ret;
	}
      };
      # error check
      last;
    };
    /TXN/ && do {
      $obj = drop($str = $res->[1]->());
      die 'j_parse: commit key not present' unless $obj && ($obj->[0] eq 'commit');
      $obj = drop($str);
      die 'j_parse: results key not present' unless $obj && ($obj->[0] eq 'results');
      my $res_str = $obj->[1]->();
      my $row_str;
      my $item = drop($res_str);
      $ITER = sub {
	# return unless defined $self->tmpf;
	my $row;
	unless ($item) {
	  undef $row_str;
	  undef $res_str;
	  return;
	}
	my $ret;
	eval {
	  if ($item->[0] eq 'columns') {
	    say "NAME:".$item->[1];
	    say "NUM_OF_FIELDS: ".(scalar @{$item->[1]});
	    # $self->{NAME} = $item->[1];
	    # $self->{NUM_OF_FIELDS} = scalar @{$item->[1]};
	    $item = drop($res_str); # move to data
	    die 'j_parse: data key not present' unless $item->[0] eq 'data';
	  }
	  if ($item->[0] eq 'data' && ref($item->[1])) {
	    $row_str = $item->[1]->();
	  }
	  if ($row_str) {
	    $row = drop($row_str);
	    if (ref $row && ref $row->[1]) {
	      # $ret =  $self->_process_row($row->[1]->{row});
	      say "process row at ".__LINE__;
	    } elsif (!defined $row) {
	      $item = drop($res_str);
	      $ret = $ITER->();
	    } else {
	      if ($row->[1] eq 'PENDING') {
		say $row->[1]. " at ".__LINE__;
		# $self->tmpf->read($buf, $BUFSIZE);
		# $jsonr->incr_parse($buf);
		# $ret = $ITER->();
	      } else {

		die "j_parse: barf(txn)";
	      }
	    }
	  } else {		# $row_str undef
	    $item = drop($res_str);
	    $item = drop($res_str) if $item->[1] =~ /STREAM/;
	  }
	  return if $ret || $ERR ; # ($self->err && $self->errobj->isa('REST::Neo4p::TxQueryException'));
	  if ($item && $item->[0] eq 'transaction') {
	    $item = drop($res_str) # skip
	  }
	  if ($item && $item->[0] eq 'errors') {
	    $DB::single=1;
	    my $err_str = $item->[1]->();
	    my @error_list;
	    while (my $err_item = drop($err_str)) {
	      my $err = $err_item->[1];
	      if (ref $err) {
		push @error_list, $err;
	      } elsif ($err eq 'PENDING') {
		# $self->tmpf->read($buf,$BUFSIZE);
		# $jsonr->incr_parse($buf);
		say "pending at ".__LINE__;
	      } else {
		die 'j_parse: error parsing txn error list';
	      }
	    }
	    my $e = REST::Neo4p::TxQueryException->new(
	      message => "Query within transaction returned errors (see error_list)\n",
	      error_list => \@error_list, code => '304'
	     ) if @error_list;
	    $item = drop($item);
	    $e->throw if $e;
	  }
	};
	if (my $e = Exception::Class->caught()) {
	  if (ref $e) {
	    # $self->{_error} = $e;
	    $ERR = $e;
	    $e->rethrow; # if $self->{RaiseError};
	  } elsif ($e =~ /j_parse|json/i) {
	    $e = REST::Neo4p::StreamException->new(message => $e);
	    # $self->{_error} = $e;
	    $ERR = $e;
	    $e->throw; # if $self->{RaiseError};
	    return;
	  } else {
	    die $e;
	  }
	}
	return $ret;

      };
      last;
    };
    # default
    REST::Neo4p::StreamException->throw( "j_parse: unknown item" );
  }
};
if (my $e = Exception::Class->caught('REST::Neo4p::LocalException')) {
  # $self->{_error} = $e;
  $ERR = $e;
  $e->rethrow ; #if ($self->{RaiseError});
  return;
} elsif ($e = Exception::Class->caught()) {
  if (ref $e) {
    $e->rethrow;
  } else {
    if ($e =~ /j_parse|json/i) {
      $e = REST::Neo4p::StreamException->new(message => $e);
      # $self->{_error} = $e;
      $ERR = $e;
      $e->throw ; # if $self->{RaiseError};
      return;
    } else {
      die $e;
    }
  }
}

lives_ok { $ITER->() } ;
throws_ok { $ITER->() } qr/transaction returned errors/;

done_testing;
1;
