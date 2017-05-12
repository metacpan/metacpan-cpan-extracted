#!/usr/bin/perl

use strict;
use warnings;

use Net::LDAP::ASN qw(LDAPRequest LDAPResponse);
use Net::LDAP::Gateway;
use Data::Dumper;
use Net::LDAP::Gateway::Constant qw(:all);

$Data::Dumper::Useqq = 1;
$Data::Dumper::Purity = 1;

my @message = ( { asn1 => [ bindRequest => { version        => 3,
					     name           => 'cn=foo, o=internet',
					     authentication => { simple => 'password' },
					   }
			  ],
		  perl => [ LDAP_OP_BIND_REQUEST, { version  => 3,
						    dn       => 'cn=foo, o=internet',
						    method   => LDAP_AUTH_SIMPLE,
						    password => 'password'
						  }
			  ],
		  peek => 'cn=foo, o=internet',
		},

# 		{ asn1 => [ bindRequest => { version        => 3,
# 					     name           => 'cn=foo, o=internet',
# 					     authentication =>
# 					     { sasl => { mechanism   => 'foo',
# 							 credentials => 'credentials data'
# 						       }
# 					     }
# 					   }
# 			  ],
# 		  perl => [ LDAP_OP_BIND_REQUEST, { version          => 3,
# 						    dn               => 'cn=foo, o=internet',
# 						    method           => LDAP_AUTH_SASL,
# 						    sasl_mechanism   => 'foo',
# 						    sasl_credentials => 'credentials data'
# 						  }
# 			  ]
# 		},

		{ asn1 => [ 'unbindRequest' => {} ],
		  perl => [ LDAP_OP_UNBIND_REQUEST, {} ]
		},

		{ asn1 => [ searchRequest => { baseObject   => 'cn=bar, o=org',
					       scope        => 0,
					       timeLimit    => 300,
					       sizeLimit    => 200,
					       typesOnly    => 0,
					       derefAliases => 1,
					       filter =>
					       { and =>
						 [ { present => 'objectClass' },
						   { equalityMatch =>
						     { assertionValue => 'aval',
						       attributeDesc => 'adesc'
						     }
						   }
						 ]
					       },
					       attributes => [qw(objectClass givenName)],
					     }
			  ],
		  perl => [ LDAP_OP_SEARCH_REQUEST, { base_dn       => 'cn=bar, o=org',
						      scope         => LDAP_SCOPE_BASE_OBJECT,
						      deref_aliases => LDAP_DEREF_ALIASES_IN_SEARCHING,
						      size_limit    => 200,
						      time_limit    => 300,
						      filter        => [ LDAP_FILTER_AND,
									 [ LDAP_FILTER_PRESENT, 'objectClass'],
									 [ LDAP_FILTER_EQ, 'adesc', 'aval' ] ],
						      attributes    => [qw(objectClass givenName)]
						    }
			  ],
		  peek => 'cn=bar, o=org',
		},
		{ asn1 => [ searchRequest => { baseObject   => 'cn=bar, o=org',
					       scope        => 2,
					       derefAliases => 3,
					       sizeLimit    => 0,
					       timeLimit    => 0,
					       typesOnly    => 0,
					       filter       => { present => 'objectClass' },
					       attributes   => [],
					     }
			  ],
		  perl => [ LDAP_OP_SEARCH_REQUEST, { base_dn       => 'cn=bar, o=org',
						      scope         => LDAP_SCOPE_WHOLE_SUBTREE,
						      deref_aliases => LDAP_DEREF_ALIASES_ALWAYS,
						      filter        => [ LDAP_FILTER_PRESENT, 'objectClass'],
						    }
			  ],
		  peek => 'cn=bar, o=org'
		},
		{ asn1 => [ modifyRequest => { object => ('cn=paco,o=bar' x 500),
					       modification =>
					       [ { modification =>
						   { type => 'foo',
						     vals => ['hello']
						   },
						   operation => 2
						 }
					       ]
					     }
			  ],
		  perl => [ LDAP_OP_MODIFY_REQUEST, { dn => ('cn=paco,o=bar' x 500),
						      changes =>
						      [ { operation => LDAP_MODOP_REPLACE,
							  attribute => 'foo',
							  values => ['hello']
							}
						      ]
						    }
			  ],
		  peek => ('cn=paco,o=bar' x 500)
		},
		{ asn1 => [ modifyRequest => { object => 'cn=paco,o=bar',
					       modification =>
					       [ { modification =>
						   { type => 'foo',
						     vals => [ 'hello' ]
						   },
						   operation => 2
						 },
						 { modification => { type => 'bar',
								     vals => [ 'bye', 'really']
								   },
						   operation => 0
						 },
						 { modification => { type => 'doz',
								     vals => [ 'coz', 'muu' ]
								   },
						   operation => 1
						 },
						 { modification => { type => 'yyy',
								     vals => []
								   },
						   operation => 1
						 }
					       ]
					     }
			  ],
		  perl => [ LDAP_OP_MODIFY_REQUEST, { dn => 'cn=paco,o=bar',
						     changes =>
						     [ { operation => LDAP_MODOP_REPLACE,
							 attribute => 'foo',
							 values => [ 'hello' ],
						       },
						       { operation => LDAP_MODOP_ADD,
							 attribute => 'bar',
							 values => ['bye', 'really'],
						       },
						       { operation => LDAP_MODOP_DELETE,
							 attribute => 'doz',
							 values => ['coz', 'muu'],
						       },
						       { operation => LDAP_MODOP_DELETE,
							 attribute => 'yyy',
							 values => [],
						       }
						     ]
						   }
			 ],
		  peek => 'cn=paco,o=bar'
		},
		{ asn1 => [ addRequest => { objectName => 'cn=paco,o=bar',
					    attributes =>
					    [ { type => 'bar',
                                                vals => [ 'bye', 'really' ]
                                              }
                                            ]
					  }
			  ],
		  perl => [ LDAP_OP_ADD_REQUEST, { bar => [ 'bye', 'really' ],
						   dn => 'cn=paco,o=bar'
						 }
			  ],
		  peek => 'cn=paco,o=bar'
		},
		{ asn1 => [ delRequest => 'ou=foo,o=org' ],
		  perl => [ LDAP_OP_DELETE_REQUEST, { dn => 'ou=foo,o=org' } ],
		  peek => 'ou=foo,o=org'
		},
		{ asn1 => [ modDNRequest =>
			    { entry => 'cn=Modify Me,dc=example,dc=com',
			      deleteoldrdn => 1,
			      newSuperior => 'o=mama,o=org',
			      newrdn => 'cn=The New Me'
			    }
			  ],
		  perl => [ LDAP_OP_MODIFY_DN_REQUEST,
			    { new_superior => 'o=mama,o=org',
			      new_rdn => 'cn=The New Me',
			      delete_old_rdn => 1,
			      dn => 'cn=Modify Me,dc=example,dc=com'
			    }
			  ],
		  peek => 'cn=Modify Me,dc=example,dc=com'
		},
		{ asn1 => [ compareRequest => { entry => 'ou=foo,o=org',
						ava => { attributeDesc => 'foo',
							 assertionValue => 'koko'
						       }
					      }
			  ],
		  perl => [ LDAP_OP_COMPARE_REQUEST,
			    { dn => 'ou=foo,o=org',
			      attribute => 'foo',
			      value => 'koko'

			    }
			  ],
		  peek => 'ou=foo,o=org',
		},
		{ asn1 => [ abandonRequest => 2 ],
		  perl => [ LDAP_OP_ABANDON_REQUEST,
			    { message_id => 2 }
			  ],
		  peek => 2
		},
		{ asn1 => [ abandonRequest => 58675 ],
		  perl => [ LDAP_OP_ABANDON_REQUEST,
			    { message_id => 58675 }
			  ],
		  peek => 58675
		},
		{ asn1 => [ extendedReq => { requestName => '16.4.3',
					     requestValue => 'mi casa, telefono'
					   }
			  ],
		  perl => [ LDAP_OP_EXTENDED_REQUEST,
			    { oid => '16.4.3',
			      value => 'mi casa, telefono'
			    }
			  ]
		},
		{ asn1 => [ bindResponse => { resultCode => 1,
					      matchedDN => "o=foo",
					      errorMessage => "Bar",
					      serverSaslCreds => "vito",
					      referral => [ 'done', 'max' ]
					    }
			  ],
		  perl => [ LDAP_OP_BIND_RESPONSE,
			    { result => LDAP_OPERATIONS_ERROR,
			      matched_dn => 'o=foo',
			      message => 'Bar',
			      sasl_credentials => 'vito',
			      referrals => [ 'done', 'max' ]
			    }
			  ],
		  peek => LDAP_OPERATIONS_ERROR
		},
		{ asn1 => [ searchResEntry => { objectName => 'ou=bar,o=foo',
						attributes =>
						[ { type => 'moo',
						    vals => [ 'miau', 'dont' ] } ] } ],
		  perl => [ LDAP_OP_SEARCH_ENTRY_RESPONSE,
			    { dn => 'ou=bar,o=foo',
			      moo => ['miau', 'dont' ] } ],
		  peek => 'ou=bar,o=foo'
		},
		{ asn1 => [ searchResRef => [ qw(foo bar doz miaou)] ],
		  perl => [ LDAP_OP_SEARCH_REFERENCE_RESPONSE,
			    { uris => [ qw(foo bar doz miaou) ] } ],
		},
		{ asn1 => [ searchResDone => { resultCode => 2,
					       matchedDN => '',
					       errorMessage => 'Super-Coco' } ],
		  perl => [ LDAP_OP_SEARCH_DONE_RESPONSE,
			    { result => LDAP_PROTOCOL_ERROR,
			      matched_dn => '',
			      message => 'Super-Coco' } ],
		  peek => LDAP_PROTOCOL_ERROR
		},
		{ asn1 => [ extendedResp => { resultCode => 3,
					      matchedDN => 'ou=doom,o=com',
					      errorMessage => 'Tiriron',
					      referral => [ 'quo', 'vadis' ],
					      responseName => 'my name',
					      response => ('my value' x 1000),
					    } ],
		  perl => [ LDAP_OP_EXTENDED_RESPONSE,
			    { result => LDAP_TIME_LIMIT_EXCEEDED,
			      matched_dn =>  'ou=doom,o=com',
			      message => 'Tiriron',
			      referrals => [ 'quo', 'vadis' ],
			      name => 'my name',
			      value => ('my value' x 1000) } ],
		  peek => LDAP_TIME_LIMIT_EXCEEDED
		},
                { asn1 => [ searchRequest => { timeLimit => 0,
                                               baseObject => 'ou=hola',
                                               filter => { substrings => { substrings => [ { initial => '3118' } ],
                                                                           type => 'vfsid'
                                                                         } },
                                               sizeLimit => 0,
                                               typesOnly => 0,
                                               derefAliases => 0,
                                               attributes => [],
                                               scope => 2
                                             }, ],
		  perl => [ LDAP_OP_SEARCH_REQUEST, { base_dn       => 'ou=hola',
						      filter        => [ LDAP_FILTER_SUBSTRINGS, 'vfsid', 3118, undef ],
						      deref_aliases => LDAP_DEREF_ALIASES_NEVER,
                                                      scope         => LDAP_SCOPE_WHOLE_SUBTREE } ],
		  peek => 'ou=hola',
                },

		# TODO:
		# - intermediate response tests
	      );

my @control = ( { asn1 => { type => '12.3.4.5' },
		  perl => { type => '12.3.4.5' } },
		{ asn1 => { type => '1.2.3.4',
			    critical => 1 },
		  perl => { type => '1.2.3.4',
			    criticality => 1 } },
		{ asn1 => { type => '2.1.2',
			    value => 'hello control' },
		  perl => { type => '2.1.2',
			    value => 'hello control' } },
		{ asn1 => { type => '3.1.2',
			    critical => 1,
			    value => 'bye control' },
		  perl => { type => '3.1.2',
			    criticality => 1,
			    value => 'bye control' } },
	      );

for my $req (@message) {
    my $msgid = int rand 100000;
    print "packing $msgid $req->{asn1}[0]\n";

    my $perl = $req->{perl};
    my $asn1 = $req->{asn1};
    unshift @$perl, $msgid;

    my $packer;
    if ($asn1->[0] =~ /^([a-z]+Res(p(onse)?)?|searchRes.*)$/) {
	# print "using response packer\n";
	$asn1 = [ protocolOp => { $asn1->[0] => $asn1->[1] } ];
	$packer = $LDAPResponse;
    }
    else {
	$packer = $LDAPRequest;
    }

    my @c = grep int(rand 1.5), @control;
    if (@c) {
        push @$asn1, controls => [map $_->{asn1}, @c];
        push @$perl, [map $_->{perl}, @c];
    }

    my $packed = $packer->encode(@$asn1, messageID => $msgid);
    $req->{packed} = $packed;
    unless (defined $packed) {
	print "error: ", $packer->error, "\n";
    }
}

open OUT, '>', 't/messages.pl' or die "unable to open messages.pl";
print OUT Data::Dumper->Dump([\@message], [qw(message)]);

__END__
