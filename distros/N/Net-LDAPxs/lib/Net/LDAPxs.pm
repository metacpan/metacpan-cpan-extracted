#
# Copyright (c) 2008-2010 Pan Yu (xiaocong@vip.163.com). 
# All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#

package Net::LDAPxs;

use strict;

use Exporter;
use DynaLoader;
use vars qw($VERSION);
use vars qw($DEFAULT_LDAP_VERSION $DEFAULT_LDAP_PORT $DEFAULT_LDAP_SCHEME);
use Net::LDAPxs::Exception;

$VERSION = '1.31';

our @ISA = qw(Exporter DynaLoader);

our @EXPORT = ( );
our @EXPORT_OK = qw(
	new bind unbind search add compare delete modify moddn
);

bootstrap Net::LDAPxs;

$DEFAULT_LDAP_VERSION	= 3; 
$DEFAULT_LDAP_PORT		= 389; 
$DEFAULT_LDAP_SCHEME	= 'ldap'; 


my $error = {
		'die'	=> sub { require Carp; Carp::croak(@_); },
		'warn'	=> sub { require Carp; Carp::carp(@_); }
};

sub _error {
	my $error_code = shift;
	my $error_msg = shift;

	$error->{$error_code}($error_msg);
}

sub _check_options {
	my $arg_ref = shift;

	if (grep { /^-/ } keys %$arg_ref) {
		_error('die', "Leading - for options is NOT supported");
	}
	$arg_ref->{'port'} ||= $DEFAULT_LDAP_PORT;
	$arg_ref->{'version'} ||= $DEFAULT_LDAP_VERSION;
	$arg_ref->{'scheme'} ||= $DEFAULT_LDAP_SCHEME;
}

sub new {
	my $class = shift;
	my $host = shift;
	my $arg_ref = { @_ };

	_check_options($arg_ref);

	my $port = $arg_ref->{'port'};
	my $version = $arg_ref->{'version'};
	my $scheme = $arg_ref->{'scheme'};
	$arg_ref->{'host'} = $host;

	return _new($class, $arg_ref);
}

my %async = (0 => 0, 1 => 1);
sub bind {
	my $self = shift;
	my $binddn = shift;
	my $arg_ref = { @_ };

	my $opt;
	$opt->{binddn} = $binddn;
	$opt->{bindpw} = $arg_ref->{password} if defined $arg_ref->{password};
	$opt->{async} = $async{$arg_ref->{async} || 0};

	$self->_bind($opt);
}

sub unbind {
	shift->_unbind();
}

my %scope = ('base' => 0, 'one' => 1, 'sub' => 2, 'children' => 3);

sub search {
	my $self = shift;
	my $arg_ref = { @_ };

	my $opt;
	require Net::LDAPxs::Search;
	$opt->{base} = $arg_ref->{base};
	$opt->{filter} = $arg_ref->{filter} || '(objectClass=top)';
	$arg_ref->{async} = defined $arg_ref->{async} ? $arg_ref->{async} : 0;
	$opt->{async} = $async{$arg_ref->{async}};
	
	if (exists $arg_ref->{scope}) {
		my $scope = lc $arg_ref->{scope};
		$opt->{scope} = (exists $scope{$scope}) ? $scope{$scope} : 2;
	}else{
		$opt->{scope} = 2;
	}
	$opt->{sizelimit} ||= 0;
	$opt->{attrs} = $arg_ref->{attrs} if (defined $arg_ref->{attrs});
	# process control if present
	$opt->{control} = $arg_ref->{control} if (defined $arg_ref->{control}); 
	my $mesg = $self->_search($opt);

	# process callback if present
	if (defined $arg_ref->{callback}) {
		foreach my $entry ($mesg->entries) {
			$arg_ref->{callback}($mesg, $entry);
		}
	}
	return $mesg;
}

sub add {
	my $self = shift;
	my $dn = shift;
	my $arg_ref = { @_ };

	if (exists $arg_ref->{attrs}) {
		$self->_add($dn, $arg_ref->{attrs});
	}else{
		_error('die', "Option 'attrs' is required when using 'add' function");
	}
}

my %operation = ( 'add' => 0, 'delete' => 1, 'replace' => 2, 'increment' => 3 );
sub modify {
	my $self = shift;
	my $dn = shift;
	my $arg_ref = { @_ };
	my @options;

	# in order to be compatible with Net::LDAP
	$arg_ref = $arg_ref->{changes} if (exists $arg_ref->{changes});

	foreach my $op (qw(add delete replace increment)) {
		next unless exists $arg_ref->{$op};
		my ($key, $val);
		while (($key, $val) = each %{$arg_ref->{$op}}) {
			my $attrs;
			$attrs->{'changetype'} = $operation{$op};
			$attrs->{'type'} = $key;
			if (ref($val) eq 'ARRAY') {
				$attrs->{'vals'} = $val;
			}else{
				$attrs->{'vals'} = [ $val ];
			}
			push (@options, $attrs);
		}
	}
	$self->_modify($dn, \@options);
}

sub moddn {
	my $self = shift;
	my $dn = shift;
	my $arg_ref = { @_ };

	_error('die', "Option 'newrdn' is required") 
		unless exists $arg_ref->{newrdn};
	$arg_ref->{deleteoldrdn} ||= 1;

	$self->_moddn($dn, $arg_ref);
}

sub compare {
	my $self = shift;
	my $dn = shift;
	my $arg_ref = { @_ };

	$self->_compare($dn, $arg_ref->{attr}, $arg_ref->{value});
}

sub delete {
	my $self = shift;
	my $dn = shift;

	$self->_delete($dn);
}


1;

__END__

=head1 NAME

Net::LDAPxs - XS version of Net::LDAP

=head1 SYNOPSIS

  use Net::LDAPxs;

  $ldap = Net::LDAPxs->new('www.example.com');

  $ldap->bind('cn=Manager,dc=example,dc=com', password => 'secret');

  $mesg = $ldap->search( base   => 'ou=language,dc=example,dc=com',
                         filter => '(|(cn=aperture)(cn=shutter_speed))'
                       );

  @entries = $mesg->entries();

  foreach my $entry (@entries) {
      foreach my $attr ($entry->attributes()) {
          foreach my $val ($entry->get_value($attr)) {
              print "$attr, $val\n";
          }
      }
  }

  $ldap->unbind;

=head1 DESCRIPTION

Net::LDAPxs is using XS code to glue LDAP C API Perl code. The purpose of 
developing this module is to thoroughly improve the performance of Net::LDAP. 
According to the simple test using L<Devel::NYTProf>, it can enhance the 
performance by nearly 30 times.
In order to benefit the migration from Net::LDAP to Net::LDAPxs, functions and 
user interfaces of Net::LDAPxs keep the same as Net::LDAP, which means people 
who migrate from Net::LDAP to Net::LDAPxs are able to leave their code 
unchanged excepting altering the module name.

=head1 CONSTRUCTOR

=item new ( HOST, OPTIONS )

HOST can be a host name or an IP address without path information.

=over 4

=item port => ( number ) (Default: 389)

Port connect to the LDAP server.

=item scheme => 'ldap' | 'ldaps' | 'ldapi' (Default: ldap)

=back

B<Example>

  $ldap = Net::LDAPxs->new('www.example.com',
                           port    => '389',
                           scheme  => 'ldap',
                           version => 3
                          );

=head1 METHODS

Currently, not all methods of Net::LDAP are supported by Net::LDAPxs.
Here is a list of implemented methods.

=item bind ( DN, OPTIONS )

=over 4

=item async => 1

Perform the bind operation asynchronously.

B<Example>

  $mesg = $ldap->bind('cn=Manager,dc=example,dc=com', password => 'secret');
  die $mesg->errstr if $mesg->err;

=item unbind ( )

=back

B<Example>

  $ldap->unbind;

=item search ( ID, OPTIONS )

=over 4

=item base => ( DN )

A base option is a DN which is the start search point.

=item filter => ( a string )

A filter is a string which format complies the RFC1960. If no filter presents, the default value is (objectClass=top).

=back

B<Example>

  (cn=Babs Jensen)
  (!(cn=Tim Howes))
  (&(objectClass=Person)(|(sn=Jensen)(cn=Babs J*)))
  (o=univ*of*mich*)

=over 4

=item scope => 'base' | 'one' | 'sub'

The default value is 'sub' which means it will search all subtrees. 'base' means only 
search the base object. 'one' means only search one level below the base object.

=item sizelimit => ( number )

A sizelimit is the maximum number of entries will be returned as a result of the 
search. The default value is 0, denots no restriction is applied.

=item attrs => ( attributes )

A list of attributes to be returned for each entry. The value is normally a reference 
to an array which contains the preferred attributes.

=back

B<Example>

  $mesg = $ldap->search( base      => 'ou=language,dc=example,dc=com',
                         filter    => '(|(cn=aperture)(cn=shutter_speed))',
                         scope     => 'one',
                         sizelimit => 0,
                         attrs     => \@attrs
                       );
  die $mesg->errstr if $mesg->err;

=over 4

=item control => ( CONTROL )

A control is a reference to a HASH which may contain the three elements "type", "value" and "critical". 

For more information see L<Net::LDAPxs::Control>.

=back

B<Example>

  use Net::LDAPxs::Control;

  $ctrl = Net::LDAPxs::Control->new(
          type  => '1.2.840.113556.1.4.473',
          value => 'sn -cn',
          critical => 0
          );

  $msg = $ldap->search( base    => $base,
                        control => $ctrl );

=item compare ( DN, OPTIONS )

Compare values in an attribute in the entry given by DN on the server. DN is a string.
If the compare is failed, errstr() method can be used to fetch the reason for the failure.

=over 4

=item attrs => attributeType

The name of the attribute type to compare.

=item value => attributeValue

The attribute value to compare with.

=back

B<Example>

  $mesg = $ldap->compare( 'ou=people,dc=example,dc=com',
                          attr  => 'gidNumber',
                          value => '65534'
                        );
  die $mesg->errstr if $mesg->err;

=item add ( DN, OPTIONS )

Add a new entry to the LDAP directiory. DN is a string.

=over 4

=item attrs => VALUE

C<VALUE> should be a hash reference.

=back

B<Example>

  my %attrs = (
    uid => 'Lionel',
    cn  => 'Lionel',
    sn  => 'Luthor',
    uidNumber    => '65534',
    gidNumber    => '65534',
    homeDirectory => '/home/Lionel',
    loginShell  => '/bin/bash',
    objectClass => [qw(inetOrgPerson posixAccount top)]
  );

  $mesg = $ldap->add( 'uid=Lionel,ou=people,dc=example,dc=com',
                      attrs => \%attrs );
  die $mesg->errstr if $mesg->err;

=item delete ( DN )

Delete the entry given by C<DN> from the server. C<DN> is a string.

B<Example>

  $mesg = $ldap->delete( 'uid=Lionel,ou=people,dc=example,dc=com' );
  die $mesg->errstr if $mesg->err;

=item moddn ( DN, OPTIONS )

Rename the entry given by C<DN> which should be a string.

=over 4

=item newrdn => RDN

This value should be a new RDN to assign to C<DN>.

=item deleteoldrdn => 1

This option should be passed if the existing RDN is to be deleted.

=item newsuperior => NEWDN

If given this value should be the DN of the new superior for C<DN>.

=back

B<Example>

  $mesg = $ldap->moddn( uid=Lionel,ou=people,dc=example,dc=com, 
                        newrdn => 'uid=Peter' );
  die $mesg->errstr if $mesg->err;

=item modify ( DN, OPTIONS )

Modify the contents of the entry given by C<DN> which should be a string.

=over 4

=item add => { ATTR => VALUE, ... }

Add more attributes or values to the entry. C<VALUE> should be a
string if only a single value is wanted in the attribute, or a
reference to an array of strings if multiple values are wanted.

  %attrs = ( cn => ['buy', 'purchase'],
    description => 'to own something' );
  $mesg = $ldap->modify( $dn, add => \%attrs );
  die $mesg->errstr if $mesg->err;

=item delete => [ ATTR, ... ]

Delete complete attributes from the entry.

  # Delete attributes
  $mesg = $ldap->modify( $dn, delete => { description => [] } );
  die $mesg->errstr if $mesg->err;
  
  # Delete a group of attributes
  %attrs = (
      cn => ['Lex', 'Lionel'],
      sn => 'Luther'
  );
  $mesg = $ldap->modify( $dn, delete => \%attrs );

=item delete => { ATTR => VALUE, ... }

Delete individual values from an attribute. C<VALUE> should be a
string if only a single value is being deleted from the attribute, or
a reference to an array of strings if multiple values are being
deleted.

If C<VALUE> is a reference to an empty array or all existing values
of the attribute are being deleted, then the attribute will be
deleted from the entry.

  $mesg = $ldap->modify( $dn,
    delete => {
      description => 'List of members',
      member      => [
        'cn=member1,ou=people,dc=example,dc=com',    # Remove members
        'cn=member2,ou=people,dc=example,dc=com',
      ],
      seeAlso => [],   # Remove attribute
    }
  );

=item replace => { ATTR => VALUE, ... }

Replace any existing values in each given attribute with
C<VALUE>. C<VALUE> should be a string if only a single value is wanted
in the attribute, or a reference to an array of strings if multiple
values are wanted. A reference to an empty array will remove the
entire attribute. If the attribute does not already exist in the
entry, it will be created.

  $mesg = $ldap->modify( $dn,
    replace => {
      description => 'New List of members', # Change the description
      member      => [ # Replace whole list with these
        'cn=member1,ou=people,dc=example,dc=com',   
        'cn=member2,ou=people,dc=example,dc=com',
      ],
      seeAlso => [],   # Remove attribute
    }
  );

=item increment => { ATTR => VALUE, ... }

Atomically increment the existing value in each given attribute by the
provided C<VALUE>. The attributes need to have integer syntax, or be
otherwise "incrementable". Note this will only work if the server
advertizes support for LDAP_FEATURE_MODIFY_INCREMENT. 

  $mesg = $ldap->modify( $dn,
    increment => {
      uidNumber => 1 # increase the uidNumber by 1
    }
  );

=item changes => [ OP => [ ATTR => VALUE ], ... ]

This is an alternative to B<add>, B<delete>, B<replace> and B<increment>
where the whole operation can be given in a single argument. C<OP>
should be B<add>, B<delete>, B<replace> or B<increment>. C<VALUE> should
be either a string or a reference to an array of strings, as before.

Use this form if you want to control the order in which the operations
will be performed.

  $mesg = $ldap->modify( $dn,
    changes => [
      add => [
        description => 'A description',
        member      => $newMember,
      ],
      delete => { seeAlso => [] },
      add => { anotherAttribute => $value },
    ]
  );

=head1 DEVELOPMENT STAGE

This module is currently in production. The advanced features will be available soon.

=head1 BUGS and RECOMMENDATIONS

Any bugs and recommendation is welcome. Please send directly to my email address 
listed below. Bugs and functions will be updated at least every one month. 

=head1 ACKNOWLEDGEMENTS

A special thanks to Larry Wall <larry@wall.org> for convincing me that no 
development could be made to the Perl community without people's contribution.

=head1 AUTHOR

Pan Yu <xiaocong[AT]vip.163.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2010 by Pan Yu. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

