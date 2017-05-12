package SSH::RPC::Client;

our $VERSION = 1.201;

use strict;
use Class::InsideOut qw(readonly private id register);
use JSON;
use Net::OpenSSH;
use SSH::RPC::Result;

=head1 NAME

SSH::RPC::Client - The requestor, or client side, of an RPC call over SSH.

=head1 SYNOPSIS

 use SSH::RPC::Client;

 my $rpc = SSH::RPC::Client->new($host, $user);
 my $result = $rpc->run($command, \%args); # returns a SSH::RPC::Result object

 if ($result->isSuccess) {
    say $result->getResponse;
 }
 else {
    die $result->getError;
 }

=head1 DESCRIPTION

SSH::RPC::Client allows you to make a remote procedure call over SSH to an L<SSH::RPC::Shell> on the other end. In this way you can execute methods remotely on other servers while also passing and receiving complex data structures. The arguments and return values are serialized into JSON allowing shells to be written in languages other than Perl.

=head1 METHODS

The following methods are available from this class.

=cut

#-------------------------------------------------------------------

=head2 ssh

Constructs and returns a reference to the L<Net::OpenSSH> object.

=cut

readonly ssh => my %ssh;

#-------------------------------------------------------------------

=head2 new ( host, user,  [ pass ])

Constructor.

=head3 host

The hostname or ip address you want to connect to.

=head3 user

The username you want to connect as. 

=head3 pass

The password to connect to this account. Can be omitted if you've set up an ssh key to automatically authenticate. See man ssh-keygen for details.

=cut

sub new {
    my ($class, $host, $user, $pass) = @_;
    my $self = register($class);
    $ssh{id $self} = Net::OpenSSH->new($host,user=>$user, password=>$pass, timeout=>30, master_opts => [ '-T']);
    return $self;
}


#-------------------------------------------------------------------

=head2 run ( command, [ args ] ) 

Execute a command on the remote shell. Returns a reference to an L<SSH::RPC::Result> object.

=head3 command

The method you wish to invoke.

=head3 args

If the method has any arguments pass them in here as a scalar, hash reference, or array reference.

=cut

sub run {
    my ($self, $command, $args) = @_;
    my $json = JSON->new->utf8->pretty->encode({
        command => $command,
        args    => $args,
        }) . "\n"; # all requests must end with a \n
    my $ssh = $self->ssh;
    my $response;
    if ($ssh) {
        my $out;
        if ($out = $ssh->capture({stdin_data => $json, ssh_opts => ['-T']})) {
            $response =  eval{JSON->new->utf8->decode($out)};
            if ($@) {
                $response = {error=>"Response translation error. $@".$ssh->error, status=>510};
            }
        }
        else {
            $response = {error=>"Transmission error. ".$ssh->error, status=>406};
        }
    }
    else {
        $response = {error=>"Connection error. ".$ssh->error, status=>408};
    }
    return SSH::RPC::Result->new($response);
}


=head1 SEE ALSO

L<GRID::Machine> and L<IPC::PerlSSH> are also good ways of solving this same problem. I chose not to use either for these reasons:

=over

=item Arbitrary Execution

They both allow arbitrary execution of Perl on the remote machine. While that's not all bad, in my circumstance that was a security risk that was unacceptable. Instead, SSH::RPC requires both a client and a shell be written, so you know exactly what's allowed to be executed. 

=item Language Neutral

Because SSH::RPC uses JSON as a serialization layer between the connection, clients and shells can be written in languages other than Perl and still interoperate. 

=item Net::OpenSSH

The Net::OpenSSH module that SSH::RPC is based upon is fast, flexible, and most importantly way easier to install than the modules required by GRID::Machine and IPC::PerlSSH.

=back

=head1 PREREQS

This package requires the following modules:

L<Net::OpenSSH>
L<JSON>
L<Class::InsideOut>

=head1 CAVEATS

You cannot use this module inside of mod_perl currently. Not sure why, but it hoses the SSH connection.

=head1 AUTHOR

JT Smith <jt_at_plainblack_com>

=head1 LEGAL

 -------------------------------------------------------------------
  SSH::RPC::Client is Copyright 2008-2009 Plain Black Corporation
  and is licensed under the same terms as Perl itself.
 -------------------------------------------------------------------
  http://www.plainblack.com                     info@plainblack.com
 -------------------------------------------------------------------

=cut


1;

