# This package contains some generalized functions for 
# dealing with databases and queries. It serves as the
# base module for all other Relations packages.

package Relations;
require Exporter;
require 5.004;

# You can run this file through either pod2man or pod2html to produce pretty
# documentation in manual or html file format (these utilities are part of the
# Perl 5 distribution).

# Copyright 2001 GAF-3 Industries, Inc. All rights reserved.
# Written by George A. Fitch III (aka Gaffer), gaf3@gaf3.com

# This program is free software, you can redistribute it and/or modify it under
# the same terms as Perl istelf

$Relations::VERSION='0.95';

@ISA = qw(Exporter);

@EXPORT = qw(
  rearrange
  delimit_clause
  as_clause 
  equals_clause
  comma_clause 
  assign_clause 
  add_as_clause 
  add_equals_clause
  add_comma_clause 
  add_assign_clause 
  set_as_clause 
  set_equals_clause
  set_comma_clause 
  set_assign_clause 
  to_array
  to_hash
  add_array
  add_hash
  get_input
  configure_settings
);

@EXPORT_OK = qw(
  rearrange
  delimit_clause
  as_clause 
  equals_clause
  comma_clause 
  assign_clause 
  add_as_clause 
  add_equals_clause
  add_comma_clause 
  add_assign_clause 
  set_as_clause 
  set_equals_clause
  set_comma_clause 
  set_assign_clause 
  to_array
  to_hash
  add_array
  add_hash
  get_input
  configure_settings
);

%EXPORT_TAGS = ();

# From here on out, be strict and clean.

use strict;



### Rearranges arguments from either the straight ordered format, or named format, 
### into their respective variables.

### This code was modified from the standard CGI module by Lincoln D. Stein

sub rearrange {

  ### First we're going to get whatever's sent and make sure there's 
  ### something to parse

  # Get how to order of the arguments and the arguments themselves.

  my ($order,@param) = @_;

  # Return unless there's something to parse.

  return () unless @param;

  ### Second, we're going to format whatever's sent in an array, with the  
  ### even members being the keys, and the odd members being the values.
  ### If the caller just sent the argument in the order the function 
  ### requires without names, we'll just return those values in their.
  ### sent order.
  
  # If the first parameter is a hash.

  if (ref($param[0]) eq 'HASH') {

    # Then we have to change it to an array, with the evens = keys, 
    # odds = values.

    @param = %{$param[0]};

  } 

  # If it's not a hash
  
  else {

    # Then return the values array as is, unless the first member of the array 
    # is preceeded by a '-', which would be indicated of a named parameters 
    # calling style, i.e. 'function(-name => $value)'. 

    return @param unless (defined($param[0]) && substr($param[0],0,1) eq '-');

  }

  ### Third, we're going to figure out the where each arguments value is to 
  ### go in the array returned.

  # Declare some locals (Howdy folks!) to figure out the order in which to 
  # return the argument values.

  my ($i,%pos);

  # Initialize count

  $i = 0;

  # Go through each value in the order array

  foreach (@$order) {

    # The order of this argument name is the current location of the counter.

    $pos{uc $_} = $i;

    # Increase the counter to the next position.

    $i++;

  }

  ### Fourth, we're going insert the argument values into the return array in
  ### their proper order, and then send the results array on it's way.

  # Declare the array that will return the argument values in there proper 
  # order.

  my (@result);

  # Preextend the results array to match the length of the order aray. I
  # guess this speeds things up a bit.

  $#result = $#$order;  # preextend

  # While there's arguments and values left to parse.

  while (@param) {

    # The argument's name is the even member (zero is even, right?)

    my $key = uc(shift(@param));

    # Take out the '-' preceeding the name of the argument

    $key =~ s/^\-//;

    # If we calculated a position for this argument name.

    if (exists $pos{$key}) {

      # Then store the arguments value at the arguments proper position in the
      # result array.

      $result[$pos{$key}] = shift(@param);

    } 

  }

  # Return the array of arugments' values.

  @result;

}



### This routine is used for concatenting hashes, arrays and (leaving alone) 
### strings to be used in different clauses within an SQL statement. 
### If sent a hash, the key-value pairs will be concatentated with the minor 
### string those pairs will be concatenated with the major string, and 
### that string returned. If an array is sent, the members of the array  
### will be concatenated with the major string, and that string returned. 
### If a string is sent, that string will be returned. 

sub delimit_clause {

  # Get delimitters passed

  my ($minor) = shift;
  my ($major) = shift;
  my ($reverse) = shift;

  # Declare the various form of the sent clause

  my (%clause,@clause,$clause);

  ### First, figure out whether we were passed a hash ref, an array ref 
  ### or string. 

  # Create a hash from the next argument hash reference, if next the 
  # argument is in fact a hash reference.

  %clause = %{$_[0]} if (ref($_[0]) eq 'HASH');

  # Create an array from the clause_info array reference,  if next the 
  # argument is in fact an array reference.

  @clause = @{$_[0]} if (ref($_[0]) eq 'ARRAY');

  # Create a string from clause_info string, unless we 
  # already determined it was a hash or array.

  $clause = $_[0] unless (%clause || @clause);

  ### Second concatenate, we're appropriate. Hash ref's use the key-value
  ### to establish a relationship, like equals, as, etc., and each pair 
  ### represents a piece of the clause, like something between and's in 
  ### a where clause. Array ref's have each member being a piece of the 
  ### clause. Strings are all the pieces of the clause concanated together.

  # Go through the keys and values, adding to the array to make it seem
  # we were really passed an array.

  foreach my $key (keys %clause) {

    # Unless we're supposed to reverse the order, like in a select or
    # from clause

    push @clause, $reverse ? "$clause{$key}$minor$key" : "$key$minor$clause{$key}";

  }

  # If the clause array has members, meaning we were passed an array 
  # ref of clause info, (or made to think that we were), concatenate 
  # the array into a string, as if we were really passed a string.

  $clause = join $major, @clause if (scalar @clause);

  # Return the string since that's all we were passed, (or made to think
  # we were).

  return $clause;

}



### Builds the meat for a select or from clause of an SQL 
### statement. 

sub as_clause {

  # Get the clause to be as'ed

  my ($as) = shift;

  # If there's something to delimit return the proper clause 
  # manimpulation
 
  return delimit_clause(' as ',',',1,$as) if defined($as);

  # If where here, than there's nothing to 
  # delimit. So return that.

  return '';

}



### Builds the meat for a where or having clause of an
### SQL statment. Concats with and, not or.

sub equals_clause {

  # Get the clause to be equals'ed

  my ($equals) = shift;

  # If there's something to delimit, return the proper 
  # clause manimpulation

  return delimit_clause('=',' and ',0,$equals) if defined($equals);

  # If where here, than there's nothing to 
  # delimit.

  return '';

}



### Builds the meat for a group by, order by, or limit 
### clause of an SQL statement. You can send it a hash,
### but the order could be changed. That's why you 
### should only send it an array or string.

sub comma_clause {

  # Get the clause to be comma'ed

  my ($comma) = shift;

  # If there's something to delimit, return the proper 
  # clause manimpulation
 
  return delimit_clause(',',',',0,$comma) if defined($comma);

  # If where here, than there's nothing to 
  # delimit.

  return '';

}



### Builds the meat for a set clause of an SQL
### statement.

sub assign_clause {

  # Get the clause to be assign'ed

  my ($assign) = shift;

  # If there's something to delimit, return the 
  # proper clause manimpulation

  return delimit_clause('=',',',0,$assign) if defined($assign);

  # If where here, than there's nothing to 
  # delimit.

  return '';

}



### Add the meat for a select or from clause of 
### an SQL statement.

sub add_as_clause {

  # Get the clause to be add as'ed

  my ($as) = shift;
  my ($add_as) = shift;

  # If there's something to add and there's 
  # something already there, return what's 
  # there, plus a comma, plus what's to be 
  # added.

  return $as . ',' . as_clause($add_as) if defined($add_as) && length($as);

  # If there's still something to add, but
  # nothing already there, return what's to 
  # be added.

  return as_clause($add_as) if defined($add_as);
  
  # If we're here than there's nothing
  # to be added so just return what's 
  # already there.

  return $as;

}



### Add the meat for a where or having clause of 
### an SQL statement.

sub add_equals_clause {

  # Get the clause to be add equals'ed

  my ($equals) = shift;
  my ($add_equals) = shift;

  # If there's something to add, and there's 
  # something already there, return what's there, 
  # plus an and, plus what's to be added.

  return $equals . ' and ' . equals_clause($add_equals) if defined($add_equals) && length($equals);

  # If we're here than there's nothing
  # already there so just return what's
  # to be added.

  return equals_clause($add_equals) if defined($add_equals);
  
  # If we're here than there's nothing
  # to be added so just return what's 
  # already there.

  return $equals;

}



### Add the meat for a order by, group by, or 
### limit clause of an SQL statement.

sub add_comma_clause {

  # Get the clause to be add comma'ed

  my ($comma) = shift;
  my ($add_comma) = shift;

  # If there's something to add and there's 
  # something already there, return what's 
  # there, plus a comma, plus what's to be 
  # added.

  return $comma . ',' . comma_clause($add_comma) if defined($add_comma) && length($comma);

  # If we're here than there's nothing
  # already there so just return what's
  # to be added.

  return comma_clause($add_comma) if defined($add_comma);

  # If we're here than there's nothing
  # to be added so just return what's 
  # already there.

  return $comma;

}



### Add the meat for a set caluse of an SQL statement.

sub add_assign_clause {

  # Get the clause to be add assign'ed

  my ($assign) = shift;
  my ($add_assign) = shift;

  # If there's something to add, and there's 
  # something already there, return what's there, 
  # plus a comma, plus what's to be added.

  return $assign . ',' . assign_clause($add_assign) if defined($add_assign) && length($assign);

  # If we're here than there's nothing
  # already there so just return what's
  # to be added.

  return assign_clause($add_assign) if defined($add_assign);

  # If we're here than there's nothing
  # to be added so just return what's 
  # already there.

  return $assign;

}



### Sets the meat for a set clause of an SQL statement.
### If there's something to be set, it overrides what's
### already there. If there's nothing to set, it'll 
### leave what's there alone.

sub set_as_clause {

  # Get the clause to be set as'ed

  my ($as) = shift;
  my ($set_as) = shift;

  # If there's something to set, just 
  # return what's to be set.

  return as_clause($set_as) if defined($set_as);
  
  # If we're here than there's nothing
  # to be set so just return what's 
  # already there.

  return $as;

}



### Sets the meat for a where or having clause of 
### an SQL statement. If there's something to be 
### set, it overrides what's already there. If 
### there's nothing to set, it'll leave what's there 
### alone.

sub set_equals_clause {

  # Get the clause to be set equals'ed

  my ($equals) = shift;
  my ($set_equals) = shift;

  # If there's something to set, just 
  # return what's to be set.

  return equals_clause($set_equals) if defined($set_equals);

  # If we're here than there's nothing
  # to be set so just return what's 
  # already there.

  return $equals;

}



### Sets the meat for a order by, group by, or 
### limit clause of an SQL statement. If there's 
### something to be set, it overrides what's
### already there. If there's nothing to set, it'll 
### leave what's there alone.

sub set_comma_clause {

  # Get the clause to be set comma'ed

  my ($comma) = shift;
  my ($set_comma) = shift;

  # If there's something to set,  
  # return what's to be set.

  return comma_clause($set_comma) if defined($set_comma);
  
  # If we're here than there's nothing
  # to be set so just return what's 
  # already there.

  return $comma;

}



### Sets the meat for a set clause of an SQL statement. 
### If there's something to be set, it overrides what's
### already there. If there's nothing to set, it'll 
### leave what's there alone.

sub set_assign_clause {

  # Get the clause to be set assign'ed

  my ($assign) = shift;
  my ($set_assign) = shift;

  # If there's something to set, 
  # return what's to be set.

  return assign_clause($set_assign) if defined($set_assign);
  
  # If we're here than there's nothing
  # to be set so just return what's 
  # already there.

  return $assign;

}



### Takes a delimitted string or array ref and 
### returns an array ref. If an array ref is sent, 
### a copy of the array is returned, not the 
### original array.

sub to_array {

  # Grab the value sent and what to split by only
  # if split was sent. Else split by a comma.

  my $value = shift;
  my $split = scalar @_ ? shift : ',';

  # Declare the return array. Set it to the $value
  # if $value's a ref, else split $value by commas.

  my @value = ref($value) ? @$value : split $split, $value;

  # Return the array refence
  
  return \@value;

}



### Takes a delimitted string, array ref or hash ref 
### and returns a hash ref. The hash reference will 
### have the individual values as keys with their 
### values set to true. If an hash ref is sent, a 
### copy of the hash is returned, not the original 
### hash.

sub to_hash {

  # Grab the value sent and what to split by only
  # if split was sent. Else split by a comma.

  my $value = shift;
  my $split = scalar @_ ? shift : ',';

  # Declare the hash to send back.

  my %value = ();

  # Unless it's a hash reference 

  unless (ref($value) eq 'HASH') {

    # Assume its a comma delimitted string or an
    # array ref and send it to to_array

    $value = to_array($value,$split);

    # Go through each one, settting the 
    # key's value to true.

    foreach my $key (@{$value}) {

      $value{$key} = 1;

    }

  } else {

    # Dump the sent hash into our hash

    %value = %$value;

  }

  # Return the hash refence
  
  return \%value;

}



### Takes two array refs and places one onto the 
### end of the other

sub add_array {

  # Grab the arrays sent. 

  my $value = shift;
  my $adder = shift;

  # Push the adder onto the value

  push @{$value},@{$adder};

  # Return the value
  
  return $value;

}



### Takes two hash refs and adds the key value pairs
### from one to the other.

sub add_hash {

  # Grab the hashes sent. 

  my $value = shift;
  my $adder = shift;

  # Go through each adder key 

  foreach my $add (keys %{$adder}) {

    $value->{$add} = $adder->{$add};

  }

  # Return the value
  
  return $value;

}



### Asks a question, gets input from the user,
### cleans the input, and return the input if
### given by the user, else returns the defaults
### value.

sub get_input {

  # Get the arguments sent.  

  my ($question,
      $default) = rearrange(['QUESTION',
                             'DEFAULT'],@_);

  # Ask the question, get the answer, and 
  # clean the answer.

  print "$question [$default]:";
  my $answer = <STDIN>;
  chomp $answer;

  # If an answer was given, return it, else
  # return the default.

  return length($answer) ? $answer : $default;

}



### Creates a default database settings module.
### Takes in the defaults, prompts the user for
### info. If the user sends info, that's used. 
### Once the settings are determined, it creates
### a Settings.pm file in the current direfctory.

sub configure_settings {

  # Get the defaults sent. These we be used if
  # the user just hits return for each one. 

  my ($def_database,
      $def_username,
      $def_password,
      $def_host,
      $def_port) = rearrange(['DATABASE',
                              'USERNAME',
                              'PASSWORD',
                              'HOST',
                              'PORT'],@_);

  # Declare the actual values to 

  my ($database,$username,$password,$host,$port,$confirm);

  # Prompt the user for each value

  print "
    Before we can get started, I need to know some
    info about your MySQL settings. Please fill in
    the blanks below. To accept the default values
    in the []'s, just hit return.
  ";

  print "
    MYSQL DATABASE NAME
    Make sure the database isn't the same as the name
    as an existing database of yours, since the this 
    script will delete that database when run.
  ";

  $database = get_input("\nDatabase name",$def_database);;

  print "
    MYSQL USERNAME AND PASSWORD
    Make sure the this username password account can
    create and destroy databases.
  ";

  $username = get_input("\nUsername",$def_username);;
  $password = get_input("\nPassword",$def_password);;

  print "
    MYSQL HOST AND PORT
    Make sure the computer running the demo can connect to
    this host and port, or this script will not function
    properly.
  ";

  $host = get_input("\nHost",$def_host);;
  $port = get_input("\nPort",$def_port);;

  # Let the user know the defaults.

  print "
    Using settings:
      database: $database
      username: $username
      password: $password
      host: $host
      port: $port
  ";

  # Double check with the user

  $confirm = get_input("\nCreate Settings.pm? (y/n)",'n');;

  die "Settings configuration aborted" unless $confirm =~ /^y/i;

  # Create a Settings.pm file

  open SETTINGS, ">Settings.pm";

  print SETTINGS "\$database = '$database';\n";
  print SETTINGS "\$username = '$username';\n";
  print SETTINGS "\$password = '$password';\n";
  print SETTINGS "\$host = '$host';\n";
  print SETTINGS "\$port = '$port';\n";

  close SETTINGS;

}

$Relations::VERSION;

__END__

=head1 NAME

Relations - Functions to Use with Databases and Queries

=head1 SYNOPSIS

  use Relations;

  $as_clause = as_clause({full_name => "concat(f_name,' ',l_name)",
                         {status    => "if(married,'Married','Single')"})

  $query = "select $as_clause from person";

  $avoid = to_hash("virus\tbug","\t");

  if ($avoid->{bug}) {

    print "Avoiding the bug...";

  }

  unless ($avoid->{code}) {

    print "Not avoiding the code...";

  }

=head1 ABSTRACT

This perl library contains functions for dealing with databases.
It's mainly used as the foundation for all the other 
Relations modules. It may be useful for people that deal with
databases in Perl as well.

The current version of Relations is available at

  http://www.gaf3.com

=head1 DESCRIPTION

=head2 WHAT IT DOES

Relations has functions for creating SQL clauses (like where, 
from etc.) from hashes, arrays and strings. It also has functions
for converting strings to arrays or hashes, if they're not hashes
or arrays already. It even has an argument parser, which is 
used quite heavily by the other Relations modules.

=head2 CALLING RELATIONS ROUTINES

All standard Relations routines use an ordered argument calling style, 
with the exception of the configure_settings() and get_input() functions 
which use an ordered, named, and hashed, argument calling style. This 
is because most routines have only a few arguments, and the code is 
easier to read with an ordered argument style. With the functions that
have many arguments, the code is easier to understand given a named or 
hashed argument style.

If you use the ordered argument calling style, such as

  $answer = get_input($question,$default);

the order matters, and you should consult the function defintions 
later in this document to determine the order to use.

If you use the named argument calling style, such as

  $answer = get_input(-question => $question,
                      -default  => $default);

the order does not matter, but the names, and minus signs preceeding them, do.
You should consult the function defintions later in this document to determine 
the names to use.

In the named arugment style, each argument name is preceded by a dash.  
Neither case nor order matters in the argument list. -question, -Question, and 
-QUESTION are all acceptable.  In fact, only the first argument needs to begin 
with a dash.  If a dash is present in the first argument, Relations assumes
dashes for the subsequent ones.

If you use the hashed argument calling style, such as

  $answer = get_input({question => $question,
                       default  => $default});

or

  $answer = get_input({-question => $question,
                       -default  => $default});

the order does not matter, but the names, and curly braces do, (minus signs are
optional). You should consult the function defintions later in this document to 
determine the names to use.

In the hashed arugment style, no dashes are needed, but they won't cause problems
if you put them in. Neither case nor order matters in the argument list. 
-question, -Question, and  -QUESTION are all acceptable.  If a hash is the first 
argument, Relations assumes that is the only argument that matters, and ignores 
any other arguments after the {}'s.

=head1 LIST OF RELATIONS FUNCTIONS

An example of each of these functions is provided in 'test.pl'. 

=head2 rearrange

  my (@arg_list) = rearrange($order,@param]);

Rearranges arguments from either the straight ordered format, or 
named format, into their respective variables. 

B<$order> - 
Array ref of argument names in their proper order. Names must
be capitalized.

B<@param> - 
Array of values to parse.

EXAMPLES

B<Using:>

  sub example {

    # Get the defaults sent.

    my ($first,
        $second,
        $third) = rearrange(['FIRST',
                             'SECOND',
                             'THIRD'],@_);
  }

B<Calling Ordered:>

  example('one','two','three');

B<Calling Named:>

  example(-first  => 'one',
          -second => 'two',
          -third  => 'three');

B<Calling Hashed:>

  example({first  => 'one',
           second => 'two',
           third  => 'three'});

  example({-first  => 'one',
           -second => 'two',
           -third  => 'three'});

=head2 delimit_clause

  delimit_clause($minor,$major,$reverse,$clause);

Creates a clause for a query from a hash ref, an array ref, or 
string. If sent a hash ref, the key-value pairs will be concatentated 
with the minor string and those pairs will be concatenated with the major 
string, and that string returned. If an array ref is sent, the members 
of the array with will be concatenated with the major string, and that 
string returned. If a string is sent, that string will be returned. 

B<$minor> - 
String to use to concatenate between the $clause hash ref key and 
value. 

B<$major> - 
String to use as the key-value pair if $clause is a hash ref, or 
array members if $clause is an array ref.

B<$reverse> - 
Value indicating whether to concatenate keys and values if $clause 
is a hash ref in key-value order ($reverse is false), or value-key
order ($reverse is true).

B<$clause> - 
Info to parse into a clause. Can be a hash ref, array ref, or 
string. 

=head2 as_clause

  as_clause($as);

Creates a 'select' or 'from' clause for a query from a hash ref, 
an array ref, or string. If sent a hash ref, the key-value pairs 
will be concatentated with an ' as ' between each value-key pair and 
those pairs will be concatenated with a ',' , and that string 
returned. If an array ref is sent, the members of the array with will 
be concatenated with a ',' and that string returned. If a string is 
sent, that string will be returned. 

B<$as> - 
Info to parse into a clause. Can be a hash ref, array ref, or 
string. 

EXAMPLES

B<Hash:>

as_clause({full_name => "concat(f_name,' ',l_name)",
          {status    => "if(married,'Married','Single')"})

returns: "concat(f_name,' ',l_name) as full_name,if(married,'Married','Single') as status"

B<Array:>

as_clause(['phone_num','address'])

returns: "phone_num,address"

B<String:>

as_clause("if(car='found','sweet','ug') as dude,sweet")

returns: "if(car='found','sweet','ug') as dude,sweet"

=head2 equals_clause

  equals_clause($equals);

Creates a 'where' or 'having' clause for a query from a hash ref, 
array ref, or string. If sent a hash ref, the key-value pairs will 
be concatentated with an '=' between each value-key pair and those 
pairs will be concatenated with a ' and ' , and that string returned. 
If an array ref is sent, the members of the array with will be 
concatenated with a ' and ' and that string returned. If a string is 
sent, that string will be returned. 

B<$equals> - 
Info to parse into a clause. Can be a hash ref, array ref, or 
string. 

EXAMPLES

B<Hash:>

equals_clause({man    => "'strong'",
              {woman  => "'confident'"})

returns: "man='strong' and woman='confident'"

B<Array:>

equals_clause(["Age > 40","Hair='grey'"])

returns: "Age > 40 and Hair='grey'"

B<String:>

equals_clause("reason is not null or intuition > 25")

returns: "reason is not null or intuition > 25"

=head2 comma_clause

  comma_clause($equals);

Creates a 'group by', 'order by' or 'limit' clause for a query from
an array ref or string. If an array is sent, the members of the array 
with will be concatenated with a ',' and that string returned. If 
a string is sent, that string will be returned. Yes, you can send a 
hash but the order won't be guarranteed, so don't do that.

B<$comma> - 
Info to parse into a clause. Can be an array ref, or string. 

EXAMPLES

B<Array:>

comma_clause(['fee','fie','foe','fum'])

returns: "fee,fie,foe,fum"

B<String:>

comma_clause("age desc,date")

returns: "age desc,date"

=head2 assign_clause

  assign_clause($assign);

Creates a 'set' clause for a query from a hash ref, array ref, or string. 
If sent a hash ref, the key-value pairs will be concatentated with an 
'=' between each value-key pair and those pairs will be concatenated with 
a ',' , and that string returned. If an array ref is sent, the members of 
the array with will be concatenated with a ',' and that string returned. 
If a string is sent, that string will be returned. 

B<$assign> - 
Info to parse into a clause. Can be a hash ref, array ref, or 
string. 

EXAMPLES

B<Hash:>

assign_clause({boy    => "'testing'",
              {girl   => "'trying'"})

returns: "boy='testing',girl='trying'"

B<Array:>

assign_clause(["Age=floor(12.34)","Hair='black'"])

returns: "Age=floor(12.34),Hair='black'"

B<String:>

assign_clause("reason=.5")

returns: "reason=.5"

=head2 add_as_clause

  add_as_clause($as,$add_as);

Adds more as clause info onto an existing as clause, or creates
a new as clause from what's to be added.

B<$as> - 
Existing as clause to add to. Must be a string.

B<$add_as> - 
As clause to add. Can be a hash ref, array ref or string.

See as_clause for more info.

=head2 add_equals_clause

  add_equals_clause($equals,$add_equals);

Adds more equals clause info onto an existing equals clause, or creates
a new equals clause from what's to be added.

B<$equals> - 
Existing equals clause to add to. Must be a string.

B<$add_equals> - 
Equals clause to add. Can be a hash ref, array ref or string.

See equals_clause for more info.

=head2 add_comma_clause

  add_comma_clause($comma,$add_comma);

Adds more comma clause info onto an existing comma clause, or creates
a new comma clause from what's to be added.

B<$comma> - 
Existing comma clause to add to. Must be a string.

B<$add_comma> - 
Comma clause to add. Can be a hash ref, array ref or string.

See comma_clause for more info.

=head2 add_assign_clause

  add_assign_clause($assign,$add_assign);

Adds more assign clause info onto an existing assign clause, or creates
a new assign clause from what's to be added.

B<$assign> - 
Existing assign clause to add to. Must be a string.

B<$add_assign> - 
Assign clause to add. Can be a hash ref, array ref or string.

See assign_clause for more info.

=head2 set_as_clause

  set_as_clause($as,$set_as);

Writes as clause info over an existing as clause, only if the
over writing clause is not empty.

B<$as> - 
Existing as clause to overwrite. Must be a string.

B<$set_as> - 
As clause to set. Can be a hash ref, array ref or string.

See as_clause for more info.

=head2 set_equals_clause

  set_equals_clause($equals,$set_equals);

Writes equals clause info over an existing equals clause, only if the
over writing clause is not empty.

B<$equals> - 
Existing equals clause to overwrite. Must be a string.

B<$set_equals> - 
Equals clause to set. Can be a hash ref, array ref or string.

See equals_clause for more info.

=head2 set_comma_clause

  set_comma_clause($comma,$set_comma);

Writes comma clause info over an existing comma clause, only if the
over writing clause is not empty.

B<$comma> - 
Existing comma clause to overwrite. Must be a string.

B<$set_comma> - 
Comma clause to set. Can be a hash ref, array ref or string.

See comma_clause for more info.

=head2 set_assign_clause

  set_assign_clause($assign,$set_assign);

Writes assign clause info over an existing assign clause, only if the
over writing clause is not empty.

B<$assign> - 
Existing assign clause to overwrite. Must be a string.

B<$set_assign> - 
Assign clause to set. Can be a hash ref, array ref or string.

See assign_clause for more info.

=head2 to_array

  to_array($value);

  to_array($value,$split);

Takes a delimitted string or array ref and returns an array ref.
If a delimitted string is sent, it splits the string by the 
$split. If $split is not sent, it splits by a comma.

B<$value> - 
Value to convert or just copy. Can be an array ref or delimitted 
string.

B<$split> - 
String to split $value by. If this is not sent a comma is assumed.

=head2 to_hash

  to_hash($value);

  to_hash($value,$split);

Takes a delimitted string, array ref or hash ref and returns 
a hash ref. The hash ref returned will have keys based on the string,
array ref, or hash ref, with the keyed values being 1. If a 
delimitted string is sent, it splits the string by $split into 
an array, and that array is used to add keys to a hash, with the 
values being 1 and the hash ref returned. If an array is sent, that 
array is used to add keys to a hash, with the values being 1 and the
hash ref returned. If a hash ref is sent, its just copied and 
returned.

B<$value> - 
Value to convert or just copy. Can be a hash ref, array ref or 
delimitted string.

B<$split> - 
String to split $value by. If this is not sent a comma is assumed.

=head2 add_array

  add_array($value,$adder);

Takes two array refs and places one onto the end of the other.
Does not take strings!

B<$value> - 
Array ref to be added to.

B<$adder> - 
Array ref to add.

=head2 add_hash

  add_hash($value,$adder);

Takes two hash ref and adds the key value pairs from one to the other.
Does not take strings or arrays!

B<$value> - 
Hash ref to be added to.

B<$adder> - 
Hash ref to add.

=head2 get_input

  $answer = get_input($question,$default);

  $answer = get_input(-question => $question,
                      -default  => $default);

Asks the user a question, cleans what the typed in, and returns the
value typed in if there is one, or the default value is the user
just hit return.

B<$question> - 
The question to ask the user.

B<$default> - 
The default answer to the question.

B<$answer> - 
If the user typed anything in, it'll be that, minus the newline. 
If the user didn't type anything in, it'll be the default value.

=head2 configure_settings

  configure_settings($database,
                     $username,
                     $password,
                     $host,
                     $port);

  configure_settings(-database => $database,
                     -username => $username,
                     -password => $password,
                     -host     => $host,
                     -port     => $port);

Creates a default database settings module. Takes in the defaults, 
prompts the user for info. If the user sends info, that's used. 
Once the settings a determine, it creates a 'Settings.pm' file in 
the current direfctory.

B<$database> - 
Default database name to use.

B<$username> and B<$password> - 
Default MySQL account to use to connect to the database. 

B<$host> and B<$port> - 
Default MySQL host and access port to use to connect to the database. 

=head1 CHANGES

Now to_array() and to_hash() make copies of sent arrays and hashes. 
This was done because the more complex modules, Relations-Display and
Relations-Report were sending references to their own arrays and 
those arrays were getting modified. Rather than inject a ton of 
special code to get around this, I figured I'd change just two 
functions.

You can also specify a delimitter for to_array() and to_hash(). I
did this mostly because I was bored. :)

=head1 TODO LIST

=head2 Think of more things to do. :)

=head1 OTHER RELATED WORK

=head2 Relations (Perl)

Contains functions for dealing with databases. It's mainly used as 
the foundation for the other Relations modules. It may be useful for 
people that deal with databases as well.

=head2 Relations-Query (Perl)

An object oriented form of a SQL select query. Takes hashes.
arrays, or strings for different clauses (select,where,limit)
and creates a string for each clause. Also allows users to add to
existing clauses. Returns a string which can then be sent to a 
database. 

=head2 Relations-Abstract (Perl)

Meant to save development time and code space. It takes the most common 
(in my experience) collection of calls to a MySQL database, and changes 
them to one liner calls to an object.

=head2 Relations-Admin (PHP)

Some generalized objects for creating Web interfaces to relational 
databases. Allows users to insert, select, update, and delete records from 
different tables. It has functionality to use tables as lookup values 
for records in other tables.

=head2 Relations-Family (Perl)

Query engine for relational databases.  It queries members from 
any table in a relational database using members selected from any 
other tables in the relational database. This is especially useful with 
complex databases: databases with many tables and many connections 
between tables.

=head2 Relations-Display (Perl)

Module creating graphs from database queries. It takes in a query through a 
Relations-Query object, along with information pertaining to which field 
values from the query results are to be used in creating the graph title, 
x axis label and titles, legend label (not used on the graph) and titles, 
and y axis data. Returns a graph and/or table built from from the query.

=head2 Relations-Report (Perl)

A Web interface for Relations-Family, Reations-Query, and Relations-Display. 
It creates complex (too complex?) web pages for selecting from the different 
tables in a Relations-Family object. It also has controls for specifying the 
grouping and ordering of data with a Relations-Query object, which is also 
based on selections in the Relations-Family object. That Relations-Query can 
then be passed to a Relations-Display object, and a graph and/or table will 
be displayed.

=head2 Relations-Structure (XML)

An XML standard for Relations configuration data. With future goals being 
implmentations of Relations in different languages (current targets are 
Perl, PHP and Java), there should be some way of sharing configuration data
so that one can switch application languages seamlessly. That's the goal
of Relations-Structure A standard so that Relations objects can 
export/import their configuration through XML. 

=cut