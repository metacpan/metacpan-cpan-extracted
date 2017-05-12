package Net::LDAP::Express;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.12';

use Carp ;

use base 'Net::LDAP' ;
use constant DEBUG => 0 ;

# Preloaded methods go here.
sub new {
  my $class  = shift ;
  my %args = @_ ;

  croak "Not an object method" if ref $class ;

  my %myParms = _new_parms() ;
  my @myParmNames = keys %myParms ;
  foreach my $parm (grep $myParms{$_} eq 'req',@myParmNames) {
    croak "$parm parameter is required" unless $args{$parm} ;
  }

  my $host = $args{host} ;

  # Keep parameters that are local to this class, and pass to
  # Net::LDAP::new all the rest
  my %localparms ;
  @localparms{@myParmNames} =
    delete @args{@myParmNames} ;

  # Test for onlyattrs not overlapping with searchextras; in
  # case they do, warn
  if (defined $localparms{onlyattrs} and
      defined $localparms{searchextras}) {
    carp "Useless use of parameter onlyattrs with searchextras" if $^W ;
  }

  # try connection
  my $ldap = $class->SUPER::new($host,%args) ;
  croak "Cannot connect to $host: $@" if $@ ;

  # bind if necessary
  if ($localparms{bindDN}) {
    my @bindArgs = ($localparms{bindDN}) ;
    push @bindArgs,('password',$localparms{bindpw})
      if defined $localparms{bindpw} ;
    my $msg = $ldap->bind(@bindArgs) ;
    if ($msg->is_error) {
      $ldap->_seterr($msg) ;
      croak "Cannot bind: ".$msg->error ;
    }
  }

  # Prepare object and return
  ##! I should use accessors here... maybe building a code string
  ##! and then passing it to eval.
  while (my ($parm,$value) = each %localparms) {
    $ldap->{"net_ldap_express_$parm"} = $value ;
  }
  return $ldap ;
}

{
  my @lasterr   = (0,'') ;
  my %errcache = @lasterr ;
  sub error   { return $lasterr[1] }
  sub errcode { return $lasterr[0] }
  sub _seterr {
    my $ldap = shift ;
    # _seterr sets error code an name in the error cache
    # If it is passed one argument, then it should be an object in the
    # Net::LDAP::Message class
    # If it is passed two arguments, then they are an error code and
    # an error name respectively

    # Redefine @_ if $_[0] is a Net::LDAP::Message
    if (ref $_[0]) {
      my $msg = shift ;
      @_ = ($msg->code,$msg->error) ;
    }
    # Get error code
    $lasterr[0] = shift ;

    # Update cache, if needed
    $errcache{$lasterr[0]} = shift unless exists $errcache{$lasterr[0]} ;

    # Get error message from cache
    $lasterr[1] = $errcache{$lasterr[0]} ;

    carp "LDAP ERROR @lasterr" if $^W;

    return @lasterr ;
  }
}

sub add_many {
  my $ldap = shift ;
  my @parms = @_ ;
  my $msg ;

  # Iterate over the entries, return those that succeeded
  my @success ;
  while (my $e = shift @parms) {
    eval { $e->isa('Net::LDAP::Entry') } ;
    if ($@) {
      carp "Invalid input: $@" if $^W ;
      $ldap->_seterr(-1,'Invalid input') ;
      return \@success ;
    }

    $msg = $ldap->SUPER::add($e) ;
    if ($msg->is_error) {
      $ldap->_seterr($msg) ;
      return \@success ;
    }
    push @success,$e ;
  }

  $ldap->_seterr(0) ;
  return \@success ;
}

sub delete_many {
  my $ldap = shift ;
  my @parms = @_ ;
  my $msg ;

  my @success ;
  while (my $e = shift @parms) {
    eval { $e->isa('Net::LDAP::Entry') } ;
    if ($@) {
      carp "Invalid input: $@" if $^W ;
      $ldap->_seterr(-1,'Invalid input') ;
      return \@success ;
    }

    $msg = $ldap->SUPER::delete($e) ;
    if ($msg->is_error) {
      $ldap->_seterr($msg) ;
      return \@success ;
    }

    push @success,$e ;
  }

  $ldap->_seterr(0) ;
  return \@success ;
}

sub search {
  my $ldap = shift ;
  my $query ;

  # If search is passed an odd number of parameters, we assume that
  # the first is a query string; anyway, we'll override it if a
  # "filter" parameter is specified
  if (@_%2) {
    $query = shift ;
  }

  # Load defaults from _makesearchparms, override them with the values
  # in @_.
  my %parms = ($ldap->_makesearchparms,@_) ;

  # What about filters?
  $parms{filter} ||= $ldap->_makefilter($query) ;

  return $ldap->SUPER::search(%parms) ;
}

sub simplesearch {
  my $ldap    = shift ;
  my ($query) = @_ ;
  my %parms = $ldap->_makesearchparms;

  # Set filter
  $parms{filter} = $ldap->_makefilter($query) ;

  my $msg = $ldap->SUPER::search(%parms) ;
  if ($msg->is_error) {
    $ldap->_seterr($msg) ;
    return undef ;
  }

  $ldap->_seterr(0) ;

  return $ldap->_sort_by ?
    [$msg->sorted(@{$ldap->_sort_by})] :
      [$msg->entries] ;
}


sub rename {
  my $ldap = shift ;
  my ($e,$rdn) = @_ ;

  my $msg = $ldap->moddn($e,
			 newrdn       => $rdn,
			 deleteoldrdn => 'yes') ;
  if ($msg->is_error) {
    $ldap->_seterr($msg) ;
    return undef ;
  }

  return $ldap->_seterr(0) ;
  return $e ;
}


sub update {
  my $ldap  = shift ;
  my @parms = @_ ;
  my @success ;
  my $msg ;

  while (my $e = shift @parms) {
    eval { $e->isa('Net::LDAP::Entry') } ;
    if ($@) {
      carp "Invalid input: $@" if $^W ;
      $ldap->_seterr(-1,'Invalid input') ;
      return \@success ;
    }

    $msg = $e->update($ldap) ;

    if ($msg->is_error) {
      # Don't complain if error code is 82
      # (that means: the entry hasn't been modified)
      unless ($msg->code == 82) {
	$ldap->_seterr($msg) ;
	return \@success ;
      }
    }

    push @success,$e ;
  }

  $ldap->_seterr(0) ;
  return \@success ;
}


########################################################################
# These methods should be considered PRIVATE!
BEGIN {
  sub _new_parms {
    return (
	    host         => 'req',
	    base         => 'req',
	    searchattrs  => 'req',
	    bindDN       => 'opt',
	    bindpw       => 'opt',
	    searchbool   => 'opt',
	    searchmatch  => 'opt',
	    searchextras => 'opt',
	    onlyattrs    => 'opt',
	    sort_by      => 'opt',
	   )
  }

  carp __PACKAGE__.": Dynamically building accessors at compile time"
    if $^W and DEBUG ;

  {
    no strict 'refs' ;
    my %myParms = _new_parms() ;
    foreach my $attr (keys %myParms) {
      my $subname = "_$attr" ;
      my $parm    = "net_ldap_express_$attr" ;
      *$subname = sub {
	my $ldap = shift ;
	return $ldap->{$parm} if @_ == 0 ;
	return $ldap->{$parm} = shift ;
      } ;
    }
  }
}

sub _makefilter {
  my $ldap = shift ;
  my ($query) = @_ ;

  my $bool  = $ldap->_searchbool  ? $ldap->_searchbool  : '|'  ;
  my $match = $ldap->_searchmatch ;

  my $op    = '~=' ;

  if ($match) {
    $op = '=' if $match eq 'substr' or $match eq 'exact' ;
    $query = qq/*$query*/ if $match eq 'substr';
  }

  my @attrs = @{$ldap->_searchattrs} ;

  my $filter ;
  if (@attrs == 1) {
    $filter = qq/($attrs[0]$op$query)/ ;
  } else {
    $filter = "($bool".
              join("",map("($_$op$query)",@attrs)).
	      ")" ;
  }

  #carp "Search filter is $filter" if DEBUG ;
  return $filter ;
}

sub _makesearchparms {
  my $ldap = shift ;

  unless (exists $ldap->{net_ldap_express_searchparms}) {
    my %parms ;

    # Set search base
    $parms{base} = $ldap->_base ;

    # Retrieve onlyattrs, or all; add searchextras if needed
    my $attrs = $ldap->_onlyattrs ? $ldap->_onlyattrs : ['*'] ;

    if (my $extras = $ldap->_searchextras) {
      push @$attrs,@$extras ;
    }

    # Now what if one specifies also sort_by, and the attributes are not
    # in $attrs? The sorting would fail...  First, let's see if the
    # first element of @$attrs is a '*', in that case just skip
    if (my $sortattrs = $ldap->_sort_by) {
      unless ($attrs->[0] eq '*') {
	# We have to compare each @$sortattrs element with the elements
	# of @$attrs; better to have some precompiled patterns handy.
	my @qrattrs = map qr/^$_$/i,@$attrs ;
	foreach my $attr (@$sortattrs) {
	  push @$attrs,$attr unless grep $attr =~ $_ ,@qrattrs ;
	}
      }
    }

    # Now we can assign the resulting $attrs to $parms{attrs}...
    $parms{attrs} = $attrs ;

    $ldap->{net_ldap_express_searchparms} = \%parms ;
  }

  return %{$ldap->{net_ldap_express_searchparms}} ;
}


1;
__END__

=head1 NAME

Net::LDAP::Express - Simplified interface for Net::LDAP

=head1 WARNING

With version 0.10 the return value for the C<error> method has slightly
changed; on no-error condition (error code 0) it returns a null string,
and not C<undef> any more. Code that simply checked for boolean true/false
value will continue to work as expected, but code that relied on C<undef>
and the C<defined> function won't!
B<Please let me know if this behaviour breaks
any existing application!>. Thanks.

=head1 SYNOPSIS

  use Net::LDAP::Express;

  eval {
    my $ldap =
      Net::LDAP::Express->new(host => 'localhost',
			      bindDN => 'cn=admin,ou=People,dc=me',
			      bindpw => 'secret',
			      base   => 'ou=People,dc=me',
			      searchattrs => [qw(cn uid loginname)],
			      %parms) ; # params for Net::LDAP::new
  } ;

  if ($@) {
    die "Can't connect to ldap server: $@" ;
  }

  my $filter = '(|(loginname=~bronto)(|(cn=~bronto)(uid=~bronto)))' ;
  my $entries ;
  # These all return the same array of Net::LDAP::Entry objects
  $entries = $ldap->search(filter => $filter) ; # uses new()'s base
  $entries = $ldap->search(base   => 'ou=People,dc=me',
                           filter => $filter) ;
  $entries = $ldap->simplesearch('bronto') ; # uses new()'s searchattrs

  # Now elaborate results:
  foreach my $entry (@$entries) {
    modify_something_in_this($entry) ;
  }

  # You often want to update a set of entries
  foreach my $entry (@$entries) {
    die "Error updating entry" unless defined $ldap->update($entry) ;
  }

  # but I think you'll prefer this way:
  my $result = $ldap->update(@$entries) ;
  unless (@$result == @$entries) {
    print "Error updating entries: ",$ldap->error,
          "; code ",$ldap->errcode,".\n\n" ;
  }

  # Add an entry, or an array of them, works as above:
  die $ldap->error unless $ldap->add_many(@some_other_entries) ;

  # rename an entry: sometimes you simply want to change a name
  # and nothing else...
  $ldap->rename($entry,$newrdn) ;

  # Ask for just a few attributes, sort results
  $ldap = Net::LDAP::Express->new(host        => $server,
				  port        => $port,
				  base        => $base,
				  bindDN      => $binddn,
				  bindpw      => $bindpw,
				  onlyattrs   => \@only,
				  sort_by     => \@sortby,
				  searchattrs => \@search) ;
  my $entries = $ldap->simplesearch('person') ;


=head1 DESCRIPTION

Net::LDAP::Express is an alternative interface to the
fantastic Graham Barr's Net::LDAP, that simplifies the tasks of adding
and deleting multiple entries, renaming them, or searching entries
residing in a common subtree.

Net::LDAP is a great module for working with
directory servers, but it's a bit overkill when you want to do simple
short scripts or have big programs that always do the same job again
and again, say: open an authenticated connection to a directory
server, search entries against the same attributes each time and in
the same way (e.g.: approx search against the three attributes cn, uid
and loginname). With Net::LDAP this would mean:

=over 4

=item *

connect to the directory server using new();

=item *

authenticate with bind() ;

=item *

compose a search filter, and pass it to search(), along with the base
subtree;

=item *

perform the search getting a Net::LDAP::Search object;

=item *

verify that the search was successful using the code() or is_error()
method on the search object;

=item *

if the search was successful, extract the entries from the Search
object, for example with entries or shift_entry.

=back

With Net::LDAP::Express this is done with:

=over 4

=item *

connect, authenticate, define default search subtree and simple-search
attributes with the new() method;

=item *

pass the simplesearch method a search string to be matched against the
attributes defined with searchattrs in new() and check the return
value: if it was successful you have a reference to an array of
Net::LDAP::Entry objects, if it was unsuccessful you get undef, and
you can check what the error was with the error() method (or the error
code with errcode) ;

=back

=head1 CONSTRUCTOR

=over 4

=item new(%parms)

Creates a Net::LDAP::Express object. Accepts all the parameters that
are legal to Net::LDAP::new but the directory server name/address is
specified via the C<host> parameter. Specific Net::LDAP::Express
parameters are therefore:

=over 4

=item host

the name or IP address of the directory server we are connecting
to. Mandatory.

=item port

the port to connect to; if omitted, the 389 will be used. 389 is the
LDAP standard port.

=item bindDN

bind DN in case of authenticated bind

=item bindpw

bind password in case of authenticated bind

=item base

base subtree for searches. Mandatory.

=item searchattrs

attributes to use for simple searches (see the simplesearch method);

=item searchbool

boolean operator in case that more than one attribute is specified
with searchattrs; default is '|' (boolean or); allowed boolean
operators are | and &.

=item searchmatch

By default, an 'approx' search is performed by simplesearch(); for
those directory servers that doesn't support the ~= operator it is
possible to request a substring search specifying the value 'substr'
for the searchmatch parameter.  Alternatively, if this is set to 'exact'
then an exact search will be done - useful when fields are not indexed
for substring searching.

=item searchextras

A list of attributes that should be returned in addition of the
default ones.

=item onlyattrs

At the opposite of searchextras: if you need just a few attributes to
be returned for each entry, you can specify them here. Note
that it doesn't make much sense to include both searchextras and
onlyattrs.

=item sort_by

If you specify this parameter with a list of attributes, the
simplesearch method will return the entries sorted by the attributes
given. Note that if you also specify onlyattrs and there are
attributes in sort_by that are not in onlyattrs, they will be added to
allow the Net::LDAP::Search::sorted method to work.

=back

=back

=head1 REDEFINED METHODS

All Net::LDAP methods are supported via inheritance. Method specific
in Net::LDAP::Express or that override inherited methods are documented
below.

=over 4

=item search

search works exactly as Net::LDAP::search(), with a few changes:

=over 4

=item *

it takes advantage of the defaults set with new(): uses
new()'s base parameter if you don't specify another base, and adds
searchextras to default attributes, or uses onlyattrs, unless you
specify an C<attrs> parameter.

=item *

if you pass it an odd number of parameters, then the first is
considered as a query string, that is used internally yo build a
search filter; anyway, if you specify a search filter with the filter
parameter the query string is discarded

=back

search() returns a Net::LDAP::Search object, thus mantaining an almost
complete compatibility with the parent class interface.

=back

=head1 NEW METHODS

=over 4

=item add_many

Takes one or more
Net::LDAP::Entry objects, returns a reference to an array
of Net::LDAP::Entry objects that successfully made it on the directory
server. You can check if every entry has been added by comparing the
length of the input list against the length of the output list. Use
the error and/or errorcode methods to see what went wrong.

=item delete_many

Works the same way as C<add_many>, but it deletes entries instead :-)

=item rename($entry,$newrdn)

Renames an entry; $entry can be a Net::LDAP::Entry or a DN, $newrdn is
a new value for the RDN. Returns $entry for success, undef on failure.

=item update(@entries)

update takes a list of Net::LDAP::Entry objects as arguments and
commits changes on the directory server. Returns a reference to an
array of updated entries.

B<NOTE:> if you want to modify an entry, say C<$e>, remember to call
C<$e-E<gt>changetype('modify')> on it B<before> doing any changes; the
defined changetype at object creation is C<add> at the moment, which
results in C<update> trying to create new entries. This could be
addressed by Net::LDAP::Express in the future, maybe.

=item simplesearch($searchstring)

Searches entries using the new()'s search* and base parameters. Takes
a search string as argument. Returns a reference to an array of
entries on success, undef on error.

=item error

Returns last error's name

=item errcode

Returns last error's code

=back


=head1 AUTHOR

Marco Marongiu, E<lt>bronto@cpan.orgE<gt>

"sort_by" feature kindly suggested by John Woodell

Original patch for exact matching (code and documentation) was
kindly contributed by Gordon Lack.

=head1 SEE ALSO

L<Net::LDAP>.

=cut
