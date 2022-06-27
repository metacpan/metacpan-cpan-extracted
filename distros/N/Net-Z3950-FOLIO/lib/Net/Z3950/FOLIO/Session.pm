package Net::Z3950::FOLIO::Session;

use strict;
use warnings;

use Cpanel::JSON::XS qw(decode_json encode_json);
use Net::Z3950::FOLIO::Config;
use Net::Z3950::FOLIO::ResultSet;


sub _throw { return Net::Z3950::FOLIO::_throw(@_); }


sub new {
    my $class = shift();
    my($ghandle, $name) = @_;

    return bless {
	ghandle => $ghandle,
	name => $name,
	resultsets => {}, # indexed by setname
    }, $class;
}


sub reloadConfigFile {
    my $this = shift();
    my $ghandle = $this->{ghandle};

    $this->{cfg} = new Net::Z3950::FOLIO::Config($ghandle->{cfgbase}, split(/\|/, $this->{name}));
}


sub login {
    my $this = shift(); 
    my $ghandle = $this->{ghandle};
    my($user, $pass) = @_;

    my $cfg = $this->{cfg};
    my $login = $cfg->{login} || {};
    my $username = $user || $login->{username};
    my $password = $pass || $login->{password};
    _throw(1014, "credentials not supplied")
	if !defined $username || !defined $password;

    my $url = $cfg->{okapi}->{url} . '/bl-users/login';
    my $req = $this->_makeHTTPRequest(POST => $url);
    $req->content(qq[{ "username": "$username", "password": "$password" }]);
    # warn "req=", $req->content();
    my $res = $ghandle->{ua}->request($req);
    # warn "res=", $res->content();
    _throw(1014, $res->content())
	if !$res->is_success();

    $this->{token} = $res->header('X-Okapi-token');
}


sub rerunSearch {
    my $this = shift();
    my($setname) = @_;

    my $cql = $this->{cql};
    my $rs = new Net::Z3950::FOLIO::ResultSet($this, $setname, $cql);
    $this->{resultsets}->{$setname} = $rs;

    my $chunkSize = $this->{cfg}->{chunkSize} || 10;
    $this->doSearch($rs, 0, $chunkSize);
    return $rs->totalCount();
}


sub doSearch {
    my $this = shift();
    my $ghandle = $this->{ghandle};
    my($rs, $offset, $limit) = @_;

    my $okapiCfg = $this->{cfg}->{okapi};
    my $qf = $this->{cfg}->{queryFilter};
    my $cql = $rs->{cql};
    if ($qf) {
	$cql = $cql ? "($cql) and ($qf)" : $qf;
    }
    my $sortspec = $this->{sortspec};
    if ($sortspec) {
	$cql = "($cql) sortby $sortspec";
	warn "search: added sortspec, yielding '$cql'";
    }

    my $url = $okapiCfg->{url};
    my $graphqlUrl = $okapiCfg->{graphqlUrl};
    my $req = $this->_makeHTTPRequest(POST => ($graphqlUrl || $url) . '/graphql');
    $req->header('X-Okapi-Url' => $url) if $graphqlUrl;

    my %variables = ();
    # warn "searching for $cql";
    $variables{cql} = $cql if $cql;
    $variables{offset} = $offset if $offset;
    $variables{limit} = $limit if $limit;
    my %body = (
	query => $this->{cfg}->{graphql},
	variables => \%variables,
    );
    $req->content(encode_json(\%body));
    my $res = $ghandle->{ua}->request($req);
    _throw(3, $res->content()) if !$res->is_success();

    my $obj = decode_json($res->content());
    # warn "result: ", Net::Z3950::FOLIO::Record::_formatJSON($obj);
    my $data = $obj->{data} or _throw(1, "no data in response");
    my $isi = ($data->{search_instances} ||
	       $data->{instance_storage_instances});
    if (!$isi) {
	my $errors = $obj->{errors};
	_throw(1, join(', ', map { $_->{message} } @$errors)) if $errors;
	_throw(1, "no instance_storage_instances in response data " . $res->content());
    }
    $rs->totalCount($isi->{totalRecords} + 0);
    $rs->insertRecords($offset, $isi->{instances});

    return $rs;
}


sub _getSRSRecords {
    my $this = shift();
    my($rs, $offset, $limit) = @_;

    my $okapiCfg = $this->{cfg}->{okapi};
    my @ids = ();
    for (my $i = 0; $i < $limit && $offset + $i < $rs->totalCount(); $i++) {
	my $rec = $rs->record($offset + $i);
	push @ids, $rec->id();
    }

    my $req = $this->_makeHTTPRequest(POST => $okapiCfg->{url} . '/source-storage/source-records?idType=INSTANCE');
    $req->content(encode_json(\@ids));
    my $res = $this->{ghandle}->{ua}->request($req);
    my $content = $res->content();
    _throw(3, $content) if !$res->is_success();

    # warn "got content ", $content;
    my $json = decode_json($content);
    my $srs = $json->{sourceRecords};
    return map { _JSON2MARC($_->{parsedRecord}->{content}) } @$srs;
}


# We would like to use MARC::Record->new_from_json() for this (from
# MARC::File::JSON), but that uses a different JSON encoding from the
# one used for FOLIO's SRS records, so we have to do it by hand.
#
sub _JSON2MARC {
    my($content) = shift();

    my $marc = new MARC::Record();
    $marc->leader($content->{leader});
    my $fields = $content->{fields};
    my $n = @$fields;
    for (my $i = 0; $i < $n; $i++) {
	my $field = $fields->[$i];
	my @keys = keys %$field;
	warn "field #", ($i+1), " of $n has ", scalar(@keys), " fields" if @keys != 1;
	foreach my $key (@keys) {
	    my $value = $field->{$key};
	    if ($key =~ /^00/) {
		$marc->append_fields(new MARC::Field($key, $value));
	    } else {
		# *sigh* I have to gather an array of single-key hashes into one hash
		my @subfields;
		for (my $j = 0; $j < @{$value->{subfields}}; $j++) {
		    foreach my $k2 (keys %{ $value->{subfields}->[$j] }) {
			push @subfields, $k2, $value->{subfields}->[$j]->{$k2};
		    }
		}
		if (@subfields) {
		    $marc->append_fields(new MARC::Field($key, $value->{ind1}, $value->{ind2}, @subfields));
		}
	    }
	}
    }

    return $marc;
}


sub sortSpecs2CQL {
    my $this = shift();
    my($sequence) = @_;

    my @res = ();
    foreach my $item (@$sequence) {	
	push @res, $this->_singleSortSpec2CQL($item);
    }

    my $spec = join(' ', @res);
    return $spec;
}


sub _singleSortSpec2CQL {
    my $this = shift();
    my($item) = @_;
    my $indexMap = $this->{cfg}->{indexMap};

    my $set = $item->{ATTRSET};
    if ($set ne Net::Z3950::FOLIO::ATTRSET_BIB1() && lc($set) ne 'bib-1') {
	# Unknown attribute set (anything except BIB-1)
	_throw(121, $set);
    }

    my @modifiers = (
	[ missing => _translateSortParam($item->{MISSING}, 213, {
	    1 => 'missingFail',
	    2 => 'missingLow',
	})],
	[ relation => _translateSortParam($item->{RELATION}, 214, {
	    0 => 'ascending',
	    1 => 'descending',
	})],
	[ case => _translateSortParam($item->{CASE}, 215, {
	    0 => 'respectCase',
	    1 => 'ignoreCase',
        })],
    );

    my($accessPoint, $cqlIndex, $entry);
    my $attrs = $item->{SORT_ATTR};
    foreach my $attr (@$attrs) {
	my $type = $attr->{ATTR_TYPE};
	_throw(237, "sort-attribute of type $type (only 1 is supported)") if defined $type && $type != 1;

	$accessPoint = $attr->{ATTR_VALUE};
	$entry = $indexMap->{$accessPoint};
	_throw(207, "undefined sort-index $accessPoint") if !defined $entry;
	if (ref $entry) {
	    $cqlIndex = $entry->{cql};
	} else {
	    $cqlIndex = $entry;
	    $entry = undef;
	}
	last;
    }

    my $res = $cqlIndex;

    my $omitList = $entry ? $entry->{omitSortIndexModifiers} : [];
    foreach my $modifier (@modifiers) {
	my($name, $value) = @$modifier;
	if (!$omitList || ! grep { $_ eq $name } @$omitList) {
	    $res .= "/sort.$value";
	} else {
	    # warn "omitting '$name' sort-modifier for access-point $accessPoint ($cqlIndex)";
	}
    };

    return $res;
}


sub _translateSortParam {
    my($zval, $diag, $map) = @_;

    my $cqlVal = $map->{$zval};
    _throw($diag, $zval) if !$cqlVal;
    return $cqlVal;
}


sub _makeHTTPRequest() {
    my $this = shift();
    my(%args) = @_;

    my $req = new HTTP::Request(%args);
    $req->header('X-Okapi-tenant' => $this->{cfg}->{okapi}->{tenant});
    $req->header('Content-type' => 'application/json');
    $req->header('Accept' => 'application/json');
    $req->header('X-Okapi-token' => $this->{token}) if $this->{token};
    return $req;
}


1;
