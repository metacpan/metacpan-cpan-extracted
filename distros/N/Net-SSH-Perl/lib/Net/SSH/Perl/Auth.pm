# $Id: Auth.pm,v 1.9 2008/10/02 18:51:15 turnstep Exp $

package Net::SSH::Perl::Auth;

use strict;
use warnings;
use Carp qw( croak );

use vars qw( %AUTH %AUTH_REVERSE @AUTH_ORDER %SUPPORTED );
BEGIN {
    %AUTH = (
        Rhosts       => 1,
        RSA          => 2,
        Password     => 3,
        Rhosts_RSA   => 4,
        ChallengeResponse => 5,
        Kerberos     => 6,
        Kerberos_TGT => 7,
    );
    %AUTH_REVERSE = reverse %AUTH;

    @AUTH_ORDER = qw( 7 6 1 4 2 5 3 );
}

sub _determine_supported {
    for my $auth (keys %AUTH) {
        my $pack = sprintf "%s::%s", __PACKAGE__, $auth;
        eval "use $pack";
        $SUPPORTED{$AUTH{$auth}}++ unless $@;
    }
}

sub new {
    my $class = shift;
    my $type = shift;
    my $auth_class = join '::', __PACKAGE__, $type;
    (my $lib = $auth_class . ".pm") =~ s!::!/!g;
    require $lib;
    $auth_class->new(@_);
}

## For SSH2: mgr is Net::SSH::Perl::AuthMgr object.
sub mgr {
    my $auth = shift;
    $auth->{mgr} = shift if @_;
    $auth->{mgr};
}

sub id {
    my $this = shift;
    my $type;
    if (my $class = ref $this) {
        my $pack = __PACKAGE__;
        ($type = $class) =~ s/^${pack}:://;
    }
    else {
        $type = $this;
    }
    $AUTH{$type};
}

sub name {
    my $this = shift;
    my $name;
    if (my $class = ref $this) {
        my $pack = __PACKAGE__;
        ($name = $class) =~ s/^${pack}:://;
    }
    else {
        $name = $AUTH_REVERSE{$this};
    }
    $name;
}

sub mask {
    my $mask = 0;
    $mask |= (1<<$_) for keys %SUPPORTED;
    $mask;
}

sub supported {
    unless (keys %SUPPORTED) {
        _determine_supported();
    }
    return [ keys %SUPPORTED ] unless @_;
    my $id = shift;
    return $id == 0 || exists $SUPPORTED{$id} unless @_;
    my $ssupp = shift;
    mask() & $ssupp & (1 << $id);
}

sub auth_order { \@AUTH_ORDER }

sub authenticate { 0 }

1;
__END__

=head1 NAME

Net::SSH::Perl::Auth - Base authentication class, plus utility methods

=head1 SYNOPSIS

   use Net::SSH::Perl::Cipher;

   # Get list of supported authentication IDs.
   my $supported = Net::SSH::Perl::Auth::supported();

   # Translate an auth name into an ID.
   my $id = Net::SSH::Perl::Auth::id($name);

   # Translate an auth ID into a name.
   my $name = Net::SSH::Perl::Auth::name($id);

   # Get the order in which auth methods are tested.
   my $order = Net::SSH::Perl::Auth::order();

=head1 DESCRIPTION

I<Net::SSH::Perl::Auth> provides a base class for each of
the authentication method classes. In addition, it defines
a set of utility methods that can be called either as
functions or object methods.

=head1 UTILITY METHODS

=head2 supported( [ $auth_id [, $server_supports ] ])

Without arguments, returns a reference to an array of
auth methods supported by I<Net::SSH::Perl>. These are methods
that have working Net::SSH::Perl::Auth:: implementations,
essentially.

With one argument I<$auth_id>, returns a true value if
that auth method is supported by I<Net::SSH::Perl>, and
false otherwise.

With two arguments, I<$auth_id> and I<$server_supports>,
returns true if the auth represented by I<$auth_id>
is supported both by I<Net::SSH::Perl> and by the sshd
server. The list of methods supported by the server
should be in I<$server_supports>, a bit mask sent
from the server during the session identification
phase.

Can be called either as a non-exported function, i.e.

    my $i_support = Net::SSH::Perl::Auth::supported();

or as an object method of a I<Net::SSH::Perl::Auth>
object, or an object of a subclass (in which case
the first argument should be I<$server_supports>,
not the I<$auth_id>):

    if ($auth->supported($server_supports)) {
        print "Server supports auth method $auth";
    }

=head2 id( [ $auth_name ] )

Translates an auth method name into an ID (suitable
for sending to the sshd server, for example).

If given I<$auth_name> translates that name into
the corresponding ID. If called as an object method,
translates the object's auth class name into the
ID.

=head2 name( [ $auth_id ] )

Translates an auth method ID into a name.

If given I<$auth_id> translates that ID into the
corresponding name. If called as an object method,
returns the (stripped) object's auth class name;
for example, if the object were of type
I<Net::SSH::Perl::Auth::Rhosts>, I<name> would return
I<Rhosts>.

=head2 auth_order()

Returns a reference to an array containing auth method
IDs. These IDs describe the order in which authentication
should be tested against the server. So, for example, if
the array listed (2, 4, 3), then the client should test:
RSA, then Rhosts-RSA, then Password authentication.

=head1 AUTH USAGE

=head2 Net::SSH::Perl::Auth->new($auth_name, $ssh)

Instantiates a new auth object of the type
I<$auth_name>, and gives it the I<Net::SSH::Perl>
object I<$ssh>, which should contain an open
connection to an sshd server.

Returns the auth object, which will be blessed into
the actual auth subclass.

=head2 $valid = $auth->authenticate()

Talks to the sshd server to authenticate the user;
if valid, returns true, and if invalid, returns
false.

=head1 AUTH DEVELOPMENT

Classes implementing an authentication method must implement
the following two methods:

=over 4

=item * $class->new($ssh)

Given a I<Net::SSH::Perl> object I<$ssh>, should construct a
new auth object and bless it into I<$class>, presumably.

=item * $class->authenticate()

Authenticate the current user with the remote daemon. This
requires following the messaging protocol defined for your
authentication method. All of the data you need--user name,
password (if required), etc.--should be in the I<$ssh>
object.

Returns 1 if the authentication is successful, 0 otherwise.

=back

=head1 AUTHOR & COPYRIGHTS

Please see the Net::SSH::Perl manpage for author, copyright,
and license information.

=cut
