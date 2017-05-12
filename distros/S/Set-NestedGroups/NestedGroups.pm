package Set::NestedGroups;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use Set::NestedGroups::Member;
use Carp;

@ISA = qw();
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
    
);
$VERSION = '0.01';

# Constructor
sub new {
    my $proto=shift;
    my $fh=shift;
    my $class=ref($proto) || $proto;
    my $self = {};    
    bless($self,$class);
   
    if(defined $fh){ 
      if(ref($fh) eq "DBI::st"){
	  $fh->execute();
	  for(my $i=0;$i<$fh->rows();$i++){
	    my ($member,$group)=$fh->fetchrow();
	    $self->add($member,$group);
	  }
      }  else {
	no strict "refs"; # Can't use strict here,
			  # incase called with (DATA) instead
			  # of \*DATA
	$fh=to_filehandle($fh);
	while(<$fh>){
	  chomp;
	  last if(/^=$/);
	  my ($member,$group)=split(/=/,$_,2);
	  $self->add(unescape($member),unescape($group));
	}
      }
    }
    return $self;
}

# Add a member to a group
sub add {
    my $self=shift;
    my ($member,$group)=@_;    
    my $was= $self->{'MEMBERS'}{$member}{$group};
    $self->{'MEMBERS'}{$member}{$group}=1;
    return $was;
}

# And remove a member from a group
sub remove {
    my $self=shift;
    my ($member,$group)=@_;    
    my $was=$self->{'MEMBERS'}{$member}{$group};
    delete $self->{'MEMBERS'}{$member}{$group};
    $self->{'GROUPS'}{$group}--;
    if($self->{'GROUPS'}{$group} == 0){
	    delete $self->{'GROUPS'}{$group};
    }
    return $was;
}

# Create some sort of list object
sub list {
    my $self=shift;
    my %options=@_;
    my $member_list=new Set::NestedGroups::MemberList;
    my $nogroups = $options{'-nogroups'} || 0;
    
    foreach my $user (keys %{$self->{'MEMBERS'}}){
	next if($nogroups && $self->group($user));
	foreach my $group ($self->groups($user,%options)){
	    $member_list->add($user,$group);
	}
    }
    return $member_list;
}

sub to_filehandle {
    no strict "refs"; # Can't use strict here,
		      # incase called with (DATA) instead
		      # of \*DATA
    my $string = shift;
    if ($string && !ref($string)) {
	my($package) = caller(1);
	my($tmp) = $string=~/[':]/ ? $string : "$package\:\:$string"; 
	return $tmp if defined(fileno($tmp));
    }
    return $string;
}

# unescape URL-encoded data
sub unescape {
    my($todecode) = @_;
    $todecode =~ tr/+/ /;       # pluses become spaces
    $todecode =~ s/%([0-9a-fA-F]{2})/pack("c",hex($1))/ge;
    return $todecode;
}

# URL-encode data
sub escape {
    my($toencode) = @_;
    $toencode=~s/([^a-zA-Z0-9_\-.])/uc sprintf("%%%02x",ord($1))/eg;
    return $toencode;
}

# Save the current object
sub save {
    my $self=shift;
    my $fh=shift;

    if(ref($fh) eq "DBI::st"){
      my $members=$self->list('-norecurse'=>1,-nomiddles=>0);
      for(my $i=0;$i<$members->rows();$i++){
	$fh->execute($members->next()) or return;
      }
      return 1;
    } else {
      no strict "refs"; # Can't use strict here,
			# incase called with (DATA) instead
			# of \*DATA
      $fh=to_filehandle($fh);

      my $members=$self->list('-norecurse'=>1,-nomiddles=>0);
      for(my $i=0;$i<$members->rows();$i++){
	  my ($member,$group)=$members->next();
	  print $fh escape($member),'=',escape($group),"\n" or return;
      }
      print $fh "=\n" or return;
  }
}

# Check a member
sub member {
    my $self=shift;
    my $member=shift;
    if(@_){
	my $want_group=shift;
	foreach my $got_group ($self->groups($member,-norecurse=>0,-nomiddles=>0)){
	    return 1 if($got_group eq $want_group);
	}
	return undef;
    }
    
    return (keys %{$self->{'MEMBERS'}{$member}})
}

# Check a group
sub group {
    my $self=shift;		
    my $group=shift;

    return 
	grep {$_ eq $group} $self->allgroups();
}

# Return all the members
sub allmembers {
    my $self=shift;
    return (keys %{$self->{'MEMBERS'}});
}

# Return all the groups
sub allgroups {
    my $self=shift;
    my $group=shift;
    my %seen;

    return
	grep  { !$seen{$_}++ }
	map { keys %{$self->{'MEMBERS'}{$_}} }
	$self->allmembers()
};


# Returns the groups a member belongs to
sub groups {
    my $self=shift;
    my $member=shift;
    my %options=@_;
    my $norecurse = $options{'-norecurse'} || 0;
    my $nomiddles= $options{'-nomiddles'} || 0;
    
    my %group=%{$self->{'MEMBERS'}{$member}};

    if(!$norecurse){
	my $again = 1;
	while($again){
	    $again=0;
	    foreach my $group (keys %group){
		foreach my $newgroup ( keys %{$self->{'MEMBERS'}{$group}}){
		    if(!$group{$newgroup}){
			$again=$group{$newgroup}=1;
		    }
		}
	    }
	}
    }
    return grep { !$nomiddles || !$self->member($_) }keys %group;
}

# Returns the members in a group
sub members {
    my $self=shift;
    my $group=shift;
    my %options=@_;
    my $nomiddles= $options{'-nomiddles'} || 0;
    my %members;

    foreach my $member ($self -> allmembers()){
	$members{$member}++ if(grep {$_ eq $group} $self->groups($member,%options));
    }

    return grep { !$nomiddles || !$self->group($_) }keys %members;
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Set::NestedGroups - grouped data eg ACL's, city/state/country etc

=head1 SYNOPSIS

  use Set::NestedGroups;
  $nested = new Set::NestedGroups;
  $nested->add('user','group');
  $nested->add('group','parentgroup');
  do_something() if($nested->member('user','parentgroup'));

=head1 DESCRIPTION

Set::NestedGroups gives an implementation of nested groups, 
access control lists (ACLs) would be one example of
nested groups.

For example, if Joe is a Manager, and Managers have access to payroll,
you can create an ACL which implements these rules, then ask the ACL
if Joe has access to payroll.

Another example, you may wish to track which city, state and country 
people are in, by adding people to cities, cities to states, and states
to countries.

=head1 CONSTRUTORS

=over 4

=item new()

creates a new Set::NestedGroups object.

=item new( fh )

creates a new Set::NestedGroups object, 
the object will be initialized using data read from this handle. For
details on the format, see the save() method

=item new( $sth )

creates a new Set::NestedGroups object, the object will be initialized
using data read using this this DBI statement handle.  For details on
the format, see the save() method

=head1 METHODS

=item add ( $member, $group) 

adds a member to a group. The group will be created if it doesn't
already exist.

=item remove ( $member, $group )

removes a member from a group. If this was the last member in this group,
then the group will be deleted. If the member was only in this group,
then the member will be deleted.

=item save(FILEHANDLE)

Outputs the object to the given filehandle, which must be already open
in write mode.

The format is compatable with the format used by CGI, and can be
used with new to initialize a new object;

Returns true if successfully wrote the data, or false if something
went wrong (usually that meant that the handle wasn't already open in
write mode).

=item save($sth)

Saves the object to a DBI database. This can be used with new to initialize
a new object. The $sth should be expecting 2 values, in this fashion:

  $sth = $dbh->prepare('insert into acl values (?,?)')
  $acl->save($dbh);
  $sth->finish();

  $sth = $dbh->prepare('select * from acl');
  $newacl=new ACL($sth);

Returns true if successfully wrote the data, or false if something
went wrong.

=item member ( $member, $group )

Returns true if $member is a member of $group.

=item member ( $member )

returns true if $member exists in any group.

=item group ( $group )

returns true if $group exists

=item groups ( $member, %options )

Returns the groups that $member belongs to. Options are explained below.

=item members ( $group , %options )

Returns the members of $group. Keep on reading for the options

=item list(%options)

Returns a Set::NestedGroups::Member object that will output an list
of the members & groups. This could be considered a calling of groups()
on each member, except this is more efficent.

The object can be used as follows.

  $list=$nested->list();
  for(my $i=0;$i<$list->rows();$i++){
    my ($member,$group)=$list->next();
    print "$member=$group\n";	
  }

=head2 options

By default, the above methods give every valid combination. However
you might not always want that. Therefore there are options which
can prevent return of certain values.

All of these examples presume that 'joe' is a member of 'managers',
and 'managers' is a member of payroll, and that you are using only
one of these options. You can use all 3, but that gets complicated
to explain.

-norecurse=>1

No Recursion is performed, method would ignore
payroll, and return only managers.

-nomiddles=>1

Doesn't returns groups 'in the middle', method would
ignore mangers, and return only payroll. 

-nogroups=>1

Doesn't return members that are groups. This only applies
to the list() method, in which case it acts like nomiddles, except on
the member instead of the group. list would ignore managers and
return joe => managers , joe => payroll.

=back 2

This sounds a lot more confusing than it actually is, once you try it
once or twice you'll get the idea.

=head1 AUTHOR

Alan R. Barclay, gorilla@elaine.drink.com

=head1 SEE ALSO

perl(1), CGI, DBI.

=cut
