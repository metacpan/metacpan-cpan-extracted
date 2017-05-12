package Process::Results;
use strict;
use Carp 'croak';
use B;
use JSON::Tiny;

# debug tools
# use Debug::ShowStuff ':all';
# use Debug::ShowStuff::ShowVar;

# version
our $VERSION = '0.2';

# config
my $tab = "\t";


#------------------------------------------------------------------------------
# pod
#

=head1 NAME

Process::Results - standardized structure for returning results of a process

=head1 SYNOPSIS

 use Process::Results;
 
 my $results = Process::Results->new();
 
 some_subroutine(results=>$results) {
    ...
 }
 
 if ($results->success) {}
 else {}
 
 more...

=head1 OVERVIEW

Getting the details about the results of a subroutine call can be challenging.
It's easy enough for a subroutine to indicate if it succeeded or not, or to
simply die or croak. Communicating more detail, however, can get complicated.
What was the cause of the failure? What was the input value that caused it?
Maybe there were B<multiple> problems, any of which could have independently
caused a failure.

Furthermore, it's not just failures that need communicating. Maybe there were
results of the process that need to be communicated back to the caller, in
addition to the success or failure of the operation.

Process::Results provides a standardized way for caller and subroutine to
communicate complex details of an operation. A Process::Results object is
passed into the subroutine call, which can then store results information in
the object. The sub doesn't even have to return the object because the caller
still has a reference to it.

Keep in mind that a process doesn't have to return the results object, so your
sub can still return success, failure, or some other value without the caller
having to check the Results object. In many cases, a successful process doesn't
need to provide any details - it's only on failure that details are needed.

At its simplest, a Results object is just an empty hash. By default, an empty
hash indicates success, which can be checked with the success method:

 $results->success()

If you prefer, you can check for failure, which just returns the opposite of
success():

 $results->failure()

If you prefer that the results object defaults to false, just add a 'success'
option when creating the new object:

 $results = Process::Results->new(success=>0);
 $results->success(); # returns false

In a more complex situation, the results object might contain one or more
messages in the errors array. Such an object would look like this:

 {
   errors => [
      { id=>'file-open-error', path=>'/tmp/output.txt' },
      { id=>'missing-param', param_name=>'email' },
   ]
 }

The presence of any elements in C<errors> means that the process failed, so
C<$results-E<gt>success()> returns false. A complete explanation of the
structure of a results object is in the next section.

=head2 Structure

A complete structure of a results object looks like this:

 {
   success => 0,
   errors => [
      { id=>'file-open-error', path=>'/tmp/output.txt' },
      { id=>'missing-param', param_name=>'email' },
   ],
   warnings => [
      # more messages here
   ],
   notes => [
      # more messages here
   ],
   details => {
      # a hash that can contain anything you want
   }
 }

The C<success> and C<errors> properties are redundant: the presence of any
errors indicates failure. If both properties are present, C<success> overrides
C<errors>.

Errors indicate that the process failed. Warnings do not indicate a failure,
but do indicate that something went wrong. Notes are simply information about
the process and don't mean anything was wrong at all.

=head2 Message objects

Each message is a hash reference. Each message object must have the C<id>
property. Other properties can provide details about the message, for example
a problematic input param. You can create message objects with the
C<error()>, C<warning()>, and C<note()> methods:

 $results->error('file-not-found');
 $results->warning('very-long-loop');
 $results->warning('new-id');

More on those details below.

=head1 METHODS

=cut

#
# pod
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# new
#

=head2 new()

C<Process::Results->new()> creates a new Process::Results object. By default,
the object is an empty hash.

 my $results = Process::Results->new(); # returns empty, blessed hashref

B<Options>

=over

=item * success

The C<success> option sets an explicit success or failure for the new object.
By default, you might want your results object to fail by default. In that case
you could do the following:

 $results = Process::Results->new(success=>0);
 
 # stuff happens, but nothing affects the results object

 $results->success(); # returns false

=item * json

You can pass in a json string which will be parsed and used to populate the new
object. For example:

 $results = Process::Results->new(json=>'{"errors":[{"id":"no-file"}]}');

produces this structure:

 {
   errors => [
      {
         id => "no-file"
      }
   ]
 }

=item * results

C<new()> can return an existing results object if the C<results> option is
sent. This option is handy when you want to ensure that your subroutine has a
results object regardless of whether or not one was passed in. For example,
consider the following sub:

 sub mysub {
   my ($param, %opts) = @_;
   my $results = Process::Results->new(results=>$opts{'results'});
   
   # [do stuff]
 }

In that example, the caller can send in a results object with the options hash.
If it does so, that result object is used. If no such option is sent, the sub
has a new results object to use.

If the C<results> object is sent, all other options are ignored.

=back

=cut

sub new {
	my ($class, %opts) = @_;
	my ($results);
	
	# TESTING
	# println subname(); ##i
	
	# if another results object was sent in options, return that
	if ( $opts{'results'} ) {
		if (UNIVERSAL::isa $opts{'results'}, 'Process::Results') {
			return $opts{'results'};
		}
	}
	
	# if json was sent, parse it
	if ( $opts{'json'} ) {
		$results = JSON::Tiny::decode_json($opts{'json'});
	}
	
	# else just create empty hashref
	else {
		$results = {};
	}
	
	# set explicit success if it was sent
	if (exists $opts{'success'}) {
		$results->{'success'} = $opts{'success'}? 1 : 0;
	}
	
	# bless object
	$results = bless($results, $class);
	
	# return
	return $results;
}
#
# new
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# messages
#

=head2 error(), warning(), note()

Each of these methods creates a message object (which is just a hashref) for
their respective category.  The single required param is an id for the message.
The id can be any defined string that you want. For example, the following code
creates an error object with the id "do-not-find-file".

 $results->error('do-not-find-file');

That code creates a message object, stored in the C<errors> array, with the
following structure:

 {
   'id' => 'do-not-find-file'
 }

A message object can hold any other properties you want. Those properties
should give the details of the message. Those properties can be set with
additional params to the method call.  So, for example, the following code
sets an error with the id "do-not-find-file", along with indicating the path
that does not have the file:

 $results->error('do-not-find-file', path=>$file_path);

which would result in an object like this:

 {
   'id' => 'do-not-find-file',
   'path' => '/tmp/data.txt'
 }

The message method returns the message object, so if you prefer you can set
those properties directly in the message object, like this:

 $msg = $results->error('do-not-find-file');
 $msg->{'path'} = $file_path;

=cut

sub message {
	my ($results, $type, $id, %opts) = @_;
	my ($msg);
	
	# TESTING
	# println subname(); ##i
	
	# ensure resutls object has message type
	$results->{$type} ||= [];
	
	# build message object
	$msg = { id=>$id, %opts };
	
	# add to array
	push @{$results->{$type}}, $msg;
	
	# return message
	return $msg;
}

sub error   { return shift->message('errors', @_) }
sub warning { return shift->message('warnings', @_) }
sub note    { return shift->message('notes', @_) }
#
# messages
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# success
#

=head2 success()

C<$results-E<gt>success()> returns true or false to indicate the success state of
the process. Success is determined in one of two ways: if the C<success>
property is defined, then the boolean value of that property is returned.
Else, if there are any messages in the C<errors> array, then false is returned,
else true is returned. C<success()> always returns either 1 or 0.

Here are some examples of some results objects and what C<success()> returns:

 # empty hash returns true
 {}
 
 # defined, false value of the success property returns false
 { 'success'=>0 }
 
 # errors array with at least one message returns false
 {
   'errors'=>[
      {'id'=>'do-not-find-file'}
   ],
 }
 
 # If there is a conflict between explicit success and the errors array, then
 # the explicit success is returned. That's confusing, so try to avoid that.
 {
   'success'=>1,
   'errors'=>[
      {'id'=>'do-not-find-file'}
   ],
 }

=cut

sub success {
	my ($results) = @_;
	
	# if success has been explcitly defined, use that
	if (defined $results->{'success'}) {
		return $results->{'success'} ? 1 : 0;
	}
	
	# else calculate success from errors array
	else {
		my $errs = $results->{'errors'};
		
		if ( $errs && UNIVERSAL::isa($errs, 'ARRAY')) {
			if (@$errs)
				{ return 0 }
			else
				{ return 1 }
		}
		else {
			return 1;
		}
	}
}
#
# success
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# failure
#

=head2 failure()

C<$results-E<gt>failure()> simply returns the boolean opposite of
C<$results-E<gt>success()>. C<$results-E<gt>failure()> always returns 1 or 0.

=cut

sub failure {
	return $_[0]->success ? 0 : 1;
}
#
# failure
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# succeed, fail
#

=head2 succeed(), fail()

C<$results-E<gt>succeed()> and C<$results-E<gt>fail()> explicitly set the
success state of the results object. All they do is set the C<success>
property to 1 (C<succeed>) or 0 (C<fail>).

=cut

sub succeed {
	$_[0]->{'success'} = 1;
}

sub fail {
	$_[0]->{'success'} = 0;
}

#
# succeed, fail
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# unsucceed, unfail
#

=head2 unsucceed(), unfail()

C<$results-E<gt>unsucceed()> and C<$results-E<gt>unfail()> do the same thing:
delete the C<success> proeperty.

=cut

sub unsucceed {
	delete $_[0]->{'success'};
}

sub unfail {
	delete $_[0]->{'success'};
}

#
# succeed, fail
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# json
#

=head2 json()

C<$results-E<gt>json()> returns a JSON representation of the results object.
That's all, it takes no params, it just returns a JSON string.

OK, one minor thing to note is that the C<success> property is set to the JSON
value of C<true> or C<false>. Other then that, nothing complicated.

=cut

sub json {
	my ($results) = @_;
	my ($success, %calc);
	
	# make a copy of the object
	%calc = %$results;
	
	# set success property
	if (defined $calc{'success'}) {
		$calc{'success'} =
			$calc{'success'} ?
			JSON::Tiny::true() :
			JSON::Tiny::false();
	}
	
	# return
	return to_json(\%calc);
}
#
# json
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# to_json
# private method
#
sub to_json {
	my ($object) = @_;
	my ($json);
	
	# TESTING
	# println subname(); ##i
	
	# intialize string
	$$json = '';
	
	# output object
	to_json_object($object, 0, $json);
	
	# return
	return $$json;
}
#
# to_json
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# to_json_object
# private method
#
sub to_json_object {
	my ($object, $depth, $json) = @_;
	
	# TESTING
	# println subname(); ##i
	
	# hash
	if ( UNIVERSAL::isa $object, 'HASH' ) {
		to_json_hash($object, $depth, $json);
	}
	
	# array
	elsif ( UNIVERSAL::isa $object, 'ARRAY' ) {
		to_json_array($object, $depth, $json);
	}
	
	# JSON::Tiny::_Bool
	elsif ( UNIVERSAL::isa $object, 'JSON::Tiny::_Bool' ) {
		if ( $object )
			{ $$json .= 'true' }
		else
			{ $$json .= 'false' }
	}
	
	# other unknown object
	elsif (ref $object) {
		croak 'unknown-object-type: unable to parse object type ' . ref($object);
	}
	
	# else scalar
	else {
		$$json .= json_quote($object);
	}
}
#
# to_json_object
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# to_json_hash
# private method
#
sub to_json_hash {
	my ($hash, $depth, $json) = @_;
	my (@keys, $depth_local);
	
	# TESTING
	# println subname(); ##i
	
	# indent
	$depth_local = $depth+1;
	
	# begin hash
	$$json .= "{\n";
	
	# array of keys to output
	@keys = hash_keys($hash);
	
	# loop through keys
	for (my $idx=0; $idx < @keys; $idx++) {
		my $key = $keys[$idx];
		
		# output key
		$$json .= ($tab x $depth_local) . json_quote($key) . ' : ';
		
		# output value
		to_json_object($hash->{$key}, $depth_local, $json);
		
		# add comma if this isn't the last element
		if ($idx < (@keys-1))
			{ $$json .= ',' }
		
		# close key
		$$json .= "\n";
	}
	
	# end hash
	$$json .= ($tab x $depth) . "}";
}
#
# to_json_hash
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# hash_keys
# private method
#
our @first_keys = (
	'success',
	'success-explicit',
);

sub hash_keys {
	my ($hash) = @_;
	my (%all, @rv);
	
	# TESTING
	# println subname(); ##i
	
	# build hash of keys
	@all{keys %$hash} = ();
	
	# first keys
	foreach my $first (@first_keys) {
		if ( exists $all{$first} ) {
			delete $all{$first};
			push @rv, $first;
		}
	}
	
	# append rest of keys to @keys
	push @rv, keys(%all);
	
	# return
	return @rv;
}
#
# hash_keys
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# to_json_array
# private method
#
sub to_json_array {
	my ($array, $depth, $json) = @_;
	my ($depth_local);
	
	# TESTING
	# println subname(); ##i
	
	# indent
	$depth_local = $depth+1;
	
	# begin array
	# $$json .= ($tab x $depth) . "[\n";
	$$json .= "[\n";
	
	# loop through elements
	for (my $idx=0; $idx < @$array; $idx++) {
		# indent
		$$json .= ($tab x $depth_local);
		
		# output value
		to_json_object($array->[$idx], $depth_local, $json);
		
		# add comma if this isn't the last element
		if ($idx < (@$array-1))
			{ $$json .= ',' }
		
		# close key
		$$json .= "\n";
	}
	
	# end array
	$$json .= ($tab x $depth) . "]";
}
#
# to_json_array
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# json_quote
# private method
#
sub json_quote {
	my ($val) = @_;
	
	# if it's undef, return null
	if (! defined $val)
		{ return 'null' }
	
	# if it's a number, return as is
	if ( is_number($val) )
		{ return $val }
	
	# else return quoted
	return encode_string($val);
}
#
# json_quote
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# encode_string
# private method
# This code is copied rote from JSON::Tiny.
#
my %ESCAPE = (
	'"'     => '"',
	'\\'    => '\\',
	'/'     => '/',
	'b'     => "\x08",
	'f'     => "\x0c",
	'n'     => "\x0a",
	'r'     => "\x0d",
	't'     => "\x09",
	'u2028' => "\x{2028}",
	'u2029' => "\x{2029}"
);

my %REVERSE = map { $ESCAPE{$_} => "\\$_" } keys %ESCAPE;

sub encode_string {
	my $str = shift;
	$str =~ s!([\x00-\x1f\x{2028}\x{2029}\\"/])!$REVERSE{$1}!gs;
	return "\"$str\"";
}
#
# encode_string
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# is_number
# private method
# This code is copied rote from JSON::Tiny.
#
sub is_number {
	my ($value) = @_;
	
	# return true if number
	return 1
		if B::svref_2object(\$value)->FLAGS & (B::SVp_IOK | B::SVp_NOK)
		&& 0 + $value eq $value
		&& $value * 0 == 0;
	
	# else return false
	return 0;
}
#
# is_number
#------------------------------------------------------------------------------




# return
1;

__END__


#------------------------------------------------------------------------------
# closing pod
#

=head1 TERMS AND CONDITIONS

Copyright (c) 2016 by Miko O'Sullivan. All rights reserved. This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself. This software comes with NO WARRANTY of any kind.

=head1 AUTHOR

Miko O'Sullivan
F<miko@idocs.com>

=head1 VERSION

Version: 0.01

=head1 HISTORY

=over

=item * Version 0.01 Aug 9, 2016

Initial release.

=item * Version 0.02 Aug 15, 2016

Adding Process::Results::Holder to Process::Results.

=back

=cut

#
# closing pod
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# module info
# This info is used by a home-grown CPAN module builder. This info has no use
# in the wild.
#
{
	# include in CPAN distribution
	include : 1,
	
	# allow modules
	allow_modules : {
	},
	
	# test scripts
	test_scripts : {
		'Results/tests/tests.pl' : 1,
	},
}
#
# module info
#------------------------------------------------------------------------------
