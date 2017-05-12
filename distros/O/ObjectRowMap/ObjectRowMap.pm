#!/bin/false

#  Copyright (c) 2002 Craig Welch
#
#  You may distribute under the terms of either the GNU General Public
#  License or the Artistic License, as specified in the Perl README file.

package ObjectRowMap;

use warnings;
use strict;

our $VERSION = '0.11';

use DBI;

my $ormapMeta;
if (!defined($ormapMeta)) {
	$ormapMeta = {};
}

END {
	foreach my $k (keys(%{$ormapMeta})) {
		if (exists($ormapMeta->{$k}{'dbh'})) {
			my $dbh = $ormapMeta->{$k}{'dbh'};
			$dbh->disconnect();
		}
	}
};

sub new {
	my $class = shift;
	my $self = bless {},$class;
	$self->init();
	return $self;
}

sub init { 
	my $self = shift;
	my $r = ref($self);
	my $sm = $self->ormapProperties($r);
	$self->{'ormap'} = {'fieldsc'=>{}};

	if (!exists($sm->{'usePrepareCached'})) {
		$self->{'ormap'}{'usePrepareCached'} = 0;
	}
	else {
		$self->{'ormap'}{'usePrepareCached'} = $sm->{'usePrepareCached'};
	}
	if (!exists($sm->{'debug'})) {
		$self->{'ormap'}{'debug'} = 0;
	}
	else {
		$self->{'ormap'}{'debug'} = $sm->{'debug'};
	}
	if (!exists($sm->{'commitOnSave'})) {
		$self->{'ormap'}{'commitOnSave'} = 1;
	}
	else {
		$self->{'ormap'}{'commitOnSave'} = $sm->{'commitOnSave'};
	}

	my $ormdbh;
	if (exists($ormapMeta->{$r}{'dbh'})) {
		$ormdbh = $ormapMeta->{$r}{'dbh'};
	}

	if (exists($sm->{'dbh'}) and defined($sm->{'dbh'})) {
		$self->{'ormap'}{'dbh'} = $sm->{'dbh'};
	}
	elsif (defined($ormdbh) and ($ormdbh->ping())) {
		$self->{'ormap'}{'dbh'} = $ormapMeta->{$r}{'dbh'};
	}
	else {
		$self->{'ormap'}{'dbh'} = DBI->connect(@{$sm->{'dbhConnectArgs'}});
		$ormapMeta->{$r}{'dbh'} = $self->{'ormap'}{'dbh'};
	}

	foreach my $k (sort(keys(%{$sm->{'persistFields'}}))) {
		#if ($self->{'ormap'}{'debug'}) {
			#print STDERR "ObjectRowMap:Debug:init - PersistField $k\n";
		#}
		$self->{'ormap'}{'fields'}{$k} = $sm->{'fields'}{$k};
		push @{$self->{'ormap'}{'persistFields'}}, $k;
	}
	$self->{'ormap'}{'objIsNew'} = 1;
	$self->{'ormap'}{'table'} = $sm->{'table'};
	$self->{'ormap'}{'keyFields'} = $sm->{'keyFields'};
	$self->clearChanged();
	1;
}

sub postSelectFieldString {
	my $self = shift;
	my @fields = @{$self->{'ormap'}{'persistFields'}};
	return join(',',@fields);
	}

sub allAsList {
	my $self = shift;
	my $sql = "SELECT ".$self->postSelectFieldString()." FROM ".$self->{'ormap'}{'table'};
	return $self->listFromQuery($sql);
}

sub listFromQuery {
	my $self = shift;
	my $sql = shift;
	my $r = ref($self);
	my $dbh = $self->{'ormap'}{'dbh'};
	my @fields = @{$self->{'ormap'}{'persistFields'}};
	if ($self->{'ormap'}{'debug'}) {
		print STDERR "ObjectRowMap:Debug:allAsList - SQL: $sql\n";
	}
	my $uda = $dbh->selectall_arrayref($sql);
	my @toreturn;
	for my $si (1..scalar(@{$uda})) {
		my $i = $si - 1;
		my @ud = @{$uda->[$i]};
		my $hashload = {};
		foreach my $k (0..$#ud) {
			$hashload->{$fields[$k]} = $ud[$k];
		}
		my $newself = $r->new();
		$newself->loadFromHash($hashload);
		$newself->{'ormap'}{'objIsNew'} = 0;
		push @toreturn, $newself;
	}
	return @toreturn;
}

sub load {
	my $self = shift;
	my $dbh = $self->{'ormap'}{'dbh'};
	my @fields = @{$self->{'ormap'}{'persistFields'}};
	my $sql = "SELECT ".$self->postSelectFieldString()." FROM ".$self->{'ormap'}{'table'};
	my @wheres = ();
	foreach my $k (@{$self->{'ormap'}{'keyFields'}}) {
		if (defined($self->{'ormap'}{'fields'}{$k})) {
			push @wheres, " $k = '".$self->{'ormap'}{'fields'}{$k}."'";
		}
	}
	if (scalar(@wheres) > 0) {
		$sql .= " WHERE ".join(' and ', @wheres);
	}
	#because diff versions of dbi have diff versions of selectall_hashref...
	if ($self->{'ormap'}{'debug'}) {
		print STDERR "ObjectRowMap:Debug:load - SQL: $sql\n";
	}
	my $uda = $dbh->selectall_arrayref($sql);
	my @ud = @{$uda->[0]};
	my $hashload = {};
	foreach my $k (0..$#ud) {
		$hashload->{$fields[$k]} = $ud[$k];
	}
	$self->loadFromHash($hashload);
	$self->{'ormap'}{'objIsNew'} = 0;
	1;
}

sub loadFromHash {
	my $self = shift;
	my $hashload = shift;
	my $r = ref($self);
	foreach my $k (keys(%{$hashload})) {
		my $method = 'postLoad_'.$k;
		if (defined($r->can("$method"))) {
			$self->{'ormap'}{'fields'}{$k} = $self->$method($hashload->{$k});
		}
		else {
			$self->{'ormap'}{'fields'}{$k} = $hashload->{$k};
		}
	}
	$self->clearChanged();
	1;
}

sub save {
	my $self = shift;
	my $r = ref($self);
	my @fields = @{$self->{'ormap'}{'persistFields'}};
	my @keys = ();
	my @qms = ();
	my @vals = ();
	my $sql = "";
	foreach my $k (@fields) {
		if (($self->{'ormap'}{'fieldsc'}{$k}) && (defined($self->{'ormap'}{'fields'}{$k}))) {
			push @keys, $k;
			push @qms, '?';
			my $method = 'preSave_'.$k;
			if (defined($r->can("$method"))) {
				push @vals, $self->$method($self->{'ormap'}{'fields'}{$k});
			}
			else {
				push @vals, $self->{'ormap'}{'fields'}{$k};
			}
		}
	}
	if (scalar(@keys) < 1) {
		#nothing to save
		return 1;
	}
	if ($self->{'ormap'}{'objIsNew'}) {
		#insert syntax
		$sql = "INSERT INTO ".$self->{'ormap'}{'table'}." (".join(',',@keys).") VALUES (".join(',',@qms).')';
	}
	else {
		#update syntax
		$sql = "UPDATE ".$self->{'ormap'}{'table'}." SET ";
		foreach my $ki (0..$#keys) {
			$sql .= " ".$keys[$ki]." = ?,";
		}
		chop $sql; #rm trailing ','
		my @wheres = ();
		foreach my $k (@{$self->{'ormap'}{'keyFields'}}) {
			if (defined($self->{'ormap'}{'fields'}{$k}) and not ($self->{'ormap'}{'fieldsc'}{$k})) {
				push @wheres, " $k = '".$self->{'ormap'}{'fields'}{$k}."'";
			}
			#else {
			#	print "Not update $k $self->{'ormap'}{'fieldsc'}{$k}\n";
			#}
		}
		if (scalar(@wheres) > 0) {
			$sql .= " WHERE ".join(' and ', @wheres);
		}
		else {
			return 0; #we don't update if no key fields defined...
		}
	}
	my $dbh = $self->{'ormap'}{'dbh'};
	my $sth;
	if ($self->{'ormap'}{'debug'}) {
		print STDERR "ObjectRowMap:Debug:save - SQL: $sql\n";
	}
	if ($self->{'ormap'}{'usePrepareCached'}) {
		$sth = $dbh->prepare_cached($sql);
	}
	else {
		$sth = $dbh->prepare($sql);
	}
	#$res is rows affected
	my $res = $sth->execute(@vals);
	$sth->finish();
	if ($self->{'ormap'}{'commitOnSave'}) {
		$dbh->commit();
	}
	return $res;
}

sub delete {
	my $self = shift;
	my @wheres = ();
	my @fields = @{$self->{'ormap'}{'persistFields'}};
	my $sql = "";
	$sql = "DELETE FROM ".$self->{'ormap'}{'table'};
	foreach my $k (@{$self->{'ormap'}{'keyFields'}}) {
		if (defined($self->{'ormap'}{'fields'}{$k})) {
			push @wheres, " $k = '".$self->{'ormap'}{'fields'}{$k}."'";
		}
	}
	if (scalar(@wheres) > 0) {
		$sql .= " WHERE ".join(' and ', @wheres);
	}
	else {
		return 0; #we don't delete if no key fields defined...
	}
	my $dbh = $self->{'ormap'}{'dbh'};
	my $sth;
	if ($self->{'ormap'}{'debug'}) {
		print STDERR "ObjectRowMap:Debug:delete - SQL: $sql\n";
	}
	$sth = $dbh->prepare($sql);
	my $res = $sth->execute();
	$sth->finish();
	if ($self->{'ormap'}{'commitOnSave'}) {
		$dbh->commit();
	}
	return $res;
}

sub clearChanged {
	my $self = shift;
	foreach my $k (keys(%{$self->{'ormap'}{'fields'}})) {
		$self->{'ormap'}{'fieldsc'}{$k} = 0;
	}
	1;
}

sub get {
	my $self = shift;
	my $field = $_[0];
	my $r = ref($self);
	my $method = 'get_'.$field;
	if (defined($r->can("$method"))) {
		return $self->$method($self->{'ormap'}{'fields'}{$field});
	} 
	else {
		return $self->{'ormap'}{'fields'}{$field};
	}
}

sub set {
	my $self = shift;
	my $field = $_[0];
	$self->{'ormap'}{'fieldsc'}{$field} = 1;
	my $r = ref($self);
	my $method = 'set_'.$field;
	if (defined($r->can("$method"))) {
		shift; #don't need the field name
		$self->{'ormap'}{'fields'}{$field} = $self->$method(@_);
	} 
	else {
		$self->{'ormap'}{'fields'}{$field} = $_[1];
	}
	1;
}

1;

=head1 NAME

ObjectRowMap - Simple perl object to DBI persistence engine

=head1 DESCRIPTION

ObjectRowMap is a Perl module which works with the DBI module to provide
a simple means to store a customized style of perl objects to anything with
a DBI module and generally SQL 92 (or later) syntax

=head1 ObjectRowMap

=begin docbook
<!-- The following blank =head1 is to allow us to use purely =head2 headings -->
<!-- This keeps the POD fairly simple with regards to Pod::DocBook -->

=end docbook

=head1

=head2 Version

Version 0.11.

=head2 Author and Contact Details

The author is Craig Welch.  He can be contacted via email to
Craig_Welch2 AT yahoo.com


=head2 Basic Usage

ObjectRowMap must be inherited from to be of use, attempting to use it directly will not have the desired effect, whatever that might be.  Create instances of your inheriting class.

1. Required - Create a new class which uses and inherits from Object Row Map

use vars qw( @ISA );
use ObjectRowMap;
push @ISA, 'ObjectRowMap';

2. Required - Define a method called ormapProperties() in your new class to control the behaviour of ObjectRowMap

There are a lot of clever things you could do here to handle connection pooling, obtaining database passwords, whatever is your pleasure.  At the end of all that, you have to return a hash with the following (some portions are optional)

Elements are flagged "req - required, reqor - required or, op - optional" in the list below:  'required' means just that, 'required or' means that it or the next (previous) is required (should be clear), 'optional' means just that (default provided)

{ 'table'=>'tablename','keyFields'=>['key','fields','(req)'],'usePrepareCached'=>'0 or 1, do I use prepare_cache instead of prepare, (op) (def 0)','dbhConnectArgs'=>['array ref of args to do dbh connection','(reqor)'],'dbh'=>'existing dbh (reqor)','persistFields'=>{'hash'=>'of','fields'=>'to','persist'=>'and','initial'=>'values,'(req)'=>''},'debug'=>1,'commitOnSave'=>1 }

Simple Example:

sub ormapProperties {
	return { 'table'=>'ormtester','keyFields'=>['login','uid'],'dbhConnectArgs'=>["DBI:mysql:dbname=orm",'root','',{'AutoCommit'=>0}],'persistFields'=>{'login'=>'','uid'=>'','password'=>'','gecos'=>''},'debug'=>1,'commitOnSave'=>1};
}

Some Explanation where it might be helpful-
dbh - if you are handling your own dbh, put it here and don't bother with dbhConnectArgs
keyFields - the fields which inidividually or together define a unique instance
dhbConnectArgs - if you don't handle your own dbh connection, you can just return exactly the arguments you would have sent to DBI::connect and it will do it for you.  It maintains a single dbh per persistent class, in this case, do not define a dbh
persistFields - a hash of the fields you wish to persist and their initial values, you must also define key fields here.  Instances of will automatically handle get and set for these (see below)
debug - if true, you'll see the sql which will be executed
commitOnSave - if true ObjectRowMap calls commit() at the end of save().  You can handle your own transactions if you passed in your own dbh.  If you want to do this you will want to make this false.  Otherwise it should be true or save will do you little good...

3. External Requirements - setup your database (or other dbi source) and get the connection going.  The column names that you care about must have the same names as your entries in 'persistFields'

You are now done with the required components

4. How it will work:

Create a brand new never before seen instance and persist it:

my $orm = new ObjectRowMap::Test();
$orm->set('login'=>'me');
$orm->set('gecos'=>'Myself');
$orm->set('uid'=>1);
$orm->set('password'=>'mypass');
print $orm->get('gecos')."\n";
$orm->save();

Load an existing instance, and just get info from it:

my $orm = new OrmTester();
$orm->set('login'=>'me');
$orm->load();
print $orm->get('gecos')."\n";

Load an existing instance, change, and update it:

my $orm = new OrmTester();
$orm->set('login'=>'me');
$orm->load();
$orm->set('gecos'=>'StillMe');
$orm->set('password'=>'mynewpass');
$orm->save();

Load an existing instance and delete it:

my $orm = new OrmTester();
$orm->set('login'=>'me');
$orm->load();
$orm->delete();

=head2 Additional Explanation and some advanced topics

All of these are object methods (including the ones which return multiple other objects - this is because of how ObjectRowMap handles things internally...)  The only class method is 'new'

load() - loads rest of object if "enough" values (e.g. key values) already set
save() - smart update of database from object, or inserts a new object (only changed fields)
loadFromHash() = for efficient loads from database with your own external query, mostely for internal use by allAsList and listFromQuery, no load from database will occur, all fields better be defined (very "raw")
allAsList() returns all instances of an object as an array (think about it, could be bad if you have a million records.  May build a more sophistocated iteration based possiblity later.  For working with "groups" of objects, see "listFromQuery")
listFromQuery() you provide the query, I provide the list of objects.  The order and contents of the field part of the select are VERY important, you should use postSelectFieldString to get the query portion which follows the "SELECT" in your custom query
postSelectFieldString() - see listFromQuery above

You can intercept a get or set for any field by defining YourPackage::get_fieldname() or YourPackage::set_fieldname().  This means your callers would still simply use $orm->set() and $orm->get() just like otherwise, but your "special" interceptor will be detected and called.  The idea is that you can just drop in (or out) an interceptor without having to either change client code or define an accessor method for each field.  How these work is a little asymmetric (like get and set themselves)-
$orm->set('field'=>'value') - YourPackage::set_fieldname() is called with ('value'), whatever you RETURN is stored in the correct place and success (1) is returned to the caller (you can do more storing of your own if you wish, of course, and ignore this - it's for convenience)
$orm->get('field') - YourPackage::get_fieldname() is called with the value which would have been stored by a previous set (whether you override set or not is immaterial) and what you RETURN is returned to the caller.  Again, you are free to ignore this and just store things whever you want - since only $self->{'ormap'} is reserved, you have plenty of name space.

pre-database processing for a field can be done by providing YourPackage::preSave_fieldname() (what you return is inserted instead of the actual field value, the actual field value is not modified in the process (unless you do it, of course)), YourPackage::postLoad_fieldname() will be called after a load with the raw database value (the field is not set before or after the call if you define this, it is up to you if you define it) - these are useful for pre and post processing related to special storage in database, things like encryption of values in the database, binary ip address storeage, date formats (some examples in ObjectRowMap::Test)

You can use get and set for any non-persistant fields you desire and they are stored and saved the same as the persistent fields (the set_fieldname and get_fieldname interceptors will also work) - the only thing is that there is presently no automatic initialization during construction so you would have to do that yourself (and see the caveat below about overriding the default constructor) (and, of course, such fields are ignored during load and save, but then, that's what you want or you would make them persistent fields...)

Of course, other than the methods discussed above and those below in Caveats, you can define your own methods.  Actual values are not stored at the top of the self hash and where they are is an implementation detail which may change, so you should use $self->get() and $self->set() just like your callers

A word about keys - an update will fail if at least one key for the object has not remained unchanged since the last load (for the where clause) (as it should... otherwise you would "miss" your instance's row and/or (if no keys defined) "hit" every row in the database (peek at how save builds the where clause if this doesn't make sense)).  This also means that you cannot change all keys with a single load/set/save sequence - you will have to save between changing each key.    You must define enough of your keys to achieve uniqueness before a load, otherwise you just get the first row returned.  It supports multiple keys but has no idea how many are required for uniqueness, it will use all that it has which are defined (you can initialize them to undef to make full use of this behaviour)...

=head2 DBI/DBD/Database compatibility

Uses a minimal portion of SQL 92, should work with practically any DBD module which correctly implements 'ping', it's been tested with mysql and postgress, but I can't imagine why it would not work with nearly anything

=head2 Caveats and Limitations

You must call $self->ObjectRowMap::init() at construction if you override default constructor.  At present the contructor ignores anything you may pass to it.
$self->{'ormap'} is a reserved element of the self hash
YourClass->ormapMeta{} is a reserved class level variable

set and get only work for one field and field/value respectively.  This is to keep things as relatively clean and efficient as they are

don't define methods for load, save, loadFromHash, allAsList, listFromQuery or clearChanged unless you have read the code and know what you are doing

Instances are not thread synchronized and if you simply provide connection strings
for ObjectRowMap to create database handles, it will only use one per class.  This means
that in a multi-threaded implementation there could be a problem with multiple threads
using the same dbh at the same time.  If you synchronize access by class or handle your database handles yourself in a threadsafe way you should be OK.  It would not be hard to make it threadsafe by default, I may at some point.  If you are really paranoid, you would want a semaphore per object and override/lock for all "set's", if you are just smartly-cautious all you have to worry about is synchronization of database handles.

It's really simple.  This is a caveat and a limitation. It's been extremely useful to me but since it doesn't handle multiple-table objects or anything but 1:1 relationships (automatically, that is, you could do some things on your own within it's framework to accomplish that...), it will require more work on your part to handle these more complex things.  I wrote it in a few hours after having re-written similar custom functionality over and over on a project and found it was just fine for my needs so I never extended it - feel free, or you can ask for specific additions or my thoughts on them - I've got a plan for more complex objects, but haven't written code for it.

=cut

1;
