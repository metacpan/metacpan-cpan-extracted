package
   miniauthorfile;     # hide from PAUSE
use strict;
use warnings;
use warnings FATAL => qw{ uninitialized };
use autodie;
use 5.10.0;
################################################################
=pod
=head1 Title
  miniautorfile.pm --- mini data base for a role-based access control (RBAC) file.
=head1 Invocation
  $ perl miniautorfile.pm
shows off how this module works.
=head1 Versions
  0.0: April 11 2012
=cut
################################################################
# file format: role:privilege1:privilege2:privilege3
#              role1:privilege1:privilege3
################################################################
sub new {
  my $class = shift;
  my ($authorfile)= @_;
  (-e $authorfile) or die "You must create a user-readable and user-writable authorization file first.\n";
  ## load persistent role information from an existing authorization file
  my %roles;
  open(my $FIN, "<", $authorfile);
  while (<$FIN>) {
    (/^\#/) and next; ## skip comments
    (/\w/) or next;  ## skip empty lines
    (!/([\w :\\])/) and die "Your authorization file has a non-word character ($1), other than : and \\ on line $.: $_\n";
    my @values= split(/:/);
    my $role = shift(@values);
    my $privs;
    foreach my $priv (@values){
       $priv =~ s/\R//g;
       $privs->{$priv} = 1;
    }
    $roles{$role}= $privs;
  }
  close($FIN);
  return bless({ authorfile => $authorfile, %roles }, $class);
}
################################################################
sub set_role {
  my $self = shift;
  my ($session,$role) = @_;
  #$session->{'role_privs'} = $roles{$role};
  $session->{'role'}=$role;
#  return ((exists($self->{$_[0]}))?($_[0]):undef);
}
1;
