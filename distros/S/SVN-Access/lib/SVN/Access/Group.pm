package SVN::Access::Group;

use 5.006001;
use strict;
use warnings;

our $VERSION = '0.11';

sub new {
    my ($class, %attr) = @_;
    return bless(\%attr, $class);
}

sub members {
    my ($self) = @_;
    my @members;
    foreach my $member (@{$self->{members}}) {
        push(@members, $member);
    }
    return (@members);
}

sub remove_member {
    my ($self, $remove) = @_;
    my @members;
    foreach my $member (@{$self->{members}}) {
        push(@members, $member) unless $member eq $remove;
    }
    $self->{members} = \@members;
}

sub add_member {
    my ($self, $new) = @_;
    if ($self->member_exists($new)) {
        return "Member $new already in group " . $self->name . "\n";
    } else {
        push(@{$self->{members}}, $new);
        return "Member $new successfully added to group " . $self->name . "\n";
    }
}

sub member_exists {
    my ($self, $search) = @_;
    foreach my $member (@{$self->{members}}) {
        return $member if $member eq $search;
    }
    return undef;
}

sub name {
    my ($self) = @_;
    return $self->{name};
}

1;
__END__

=head1 NAME

B<SVN::Access::Group> - Object representing a SVN Access file group

=head1 SYNOPSIS

 use SVN::Access;
 
 my $acl = SVN::Access->new(acl_file => '/usr/local/svn/conf/badnews_svn_access.conf');

 # add a member to all groups.
 foreach my $group ($acl->groups) {
     $group->add_member("peter");
 }

=head1 DESCRIPTION

Object wrapper around the groups portion of the SVN access control file. 
Groups usually look like...

=over 2

[groups]
everyone = harry, sally, joe, frank, sally, jane

=back

=head1 METHODS

=over 4

=item B<new>

the constructor, takes anything you want in hash form but im looking for 
members (arrayref), and the name of the group.  the meat and potatoes if 
you will.

Example:

  my $group = SVN::Access::Group->new(
      members   => [qw/ray bob elle/],
      name      => "Carpenters",
  );

  $group->add_member("janette");

=item B<members>

returns a list of the group's members.

Example:

  my @members = $group->members;

=item B<remove_member>

removes a member from the group.

Example:

  $group->remove_member("ray");

=item B<add_member>

adds a member to the group.  returns an error string for some reason. this 
is inconsistent with the rest of the interface, so expect either other methods 
to start having this, or expect this functionality to go away.

Example:

  print $group->add_member("becky");
  # should print "Member becky successfully added to Carpenters\n"

  print $group->add_member("janette"):
  # should print "Member janette already in group Carpenters\n"

=item B<member_exists>

returns true (the member's name) if the member exists.

Example:

  if ($group->member_exists("ray")) {
      print "i thought i fired him...\n";
      $group->remove_member("ray"); # carpenters don't need SVN access anyway
  }

=item B<name>

light accessor method which returns the group's name.

=back

=head1 SEE ALSO

subversion (http://subversion.tigris.org/), SVN::ACL, svnserve.conf

=head1 AUTHOR

Michael Gregorowicz, E<lt>mike@mg2.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2017 by Michael Gregorowicz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
