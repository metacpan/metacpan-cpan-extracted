#
# $Id: User.pm,v 0.16 2003/08/07 00:01:59 lawrence Exp $
#

package Net::Msmgr::User;
use strict;
use warnings;
use Digest::MD5;
our @ISA = qw (Net::Msmgr::Object);


sub _fields { return  shift->SUPER::_fields,( salt => undef,
					      user => undef,
					      password => undef ); }

=pod

=head1 NAME

Net::Msmgr::User

=head1 SYNOPSIS

 use Net::Msmgr::User;

 my $user = Net::Msmgr::User->new(user => 'joeblow@msn.com',
                           password => 'password' );

 print "Username is: ", $user->user;

=head1 DESCRIPTION

Net::Msmgr::User is the encapsulation object for a user/password pair.  

=head1 CONSTRUCTOR

 my $user = new Net::Msmgr::User ( user => ... );

  - or -

 my $user = Net::Msmgr::User->new(user => .... );

 Constructor parameters are:

=over

=item user (mandatory)

Registered MSN email address.

=item password (mandatory)

Your password.  This is never sent "in the clear"

=back

=cut

=pod

=head1 INSTANCE METHODS

=over

=item $user->crypto_passwd;

Returns the MD5 hex digest of the salt, which is assigned during the
login authentication process and the user password.

=back

=cut

sub crypto_passwd
{
    my $self = shift;
    my $d = new Digest::MD5;
    $d->add($self->{salt} . $self->{password} );
    return $d->hexdigest;
}

1;

#
# $Log: User.pm,v $
# Revision 0.16  2003/08/07 00:01:59  lawrence
# Initial Release
#
#
