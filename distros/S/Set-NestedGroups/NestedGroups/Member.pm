package Set::NestedGroups::MemberList;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

@ISA = qw();
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
    
);
$VERSION = '0.01';

# Preloaded methods go here.

sub new {
    my $proto=shift;
    my $class=ref($proto) || $proto;
    my $self ={};
    $self->{'COUNT'}= 0;    
    bless($self,$class);
    return $self;
}

sub add {
    my $self=shift;
    my ($member,$group)=@_;    
    push(@{$self->{'LIST'}},$member);
    push(@{$self->{'LIST'}},$group);
    $self->{'COUNT'}++;
}

sub next {
    my $self=shift;

    my $member=shift(@{$self->{'LIST'}});
    my $group=shift(@{$self->{'LIST'}});

    return ($member,$group);
}

sub rows {
	my $self=shift;

	return $self->{'COUNT'};
}


=head1 NAME

Set::NestedGroup::Member - Set of nested groups

=head1 SYNOPSIS

  use Set::NestedGroup;
  $acl = new Set::NestedGroup;
  $acl->add('user','group');
  $acl->add('group','parentgroup');
  $list=$acl->list();
  for(my $i=0;$i<$list->rows();$i++){
    my ($member,$group)=$list->next();
    print "$member=$group\n";	
  }

=head1 DESCRIPTION

Set::NestedGroup::Member objects are returns from a Set::NestedGroup
object's list() method.

=head1 METHODS

=item rows () 

Returns the number of rows this has. May be used to construct a loop
to extract all the data.

=item next ()

Returns a list comprising of the next member & group. Returns undef
when the list is exhausted.

=head1 AUTHOR

Alan R. Barclay, gorilla@elaine.drink.com

=head1 SEE ALSO

perl(1), Set::NestedGroup

=cut
