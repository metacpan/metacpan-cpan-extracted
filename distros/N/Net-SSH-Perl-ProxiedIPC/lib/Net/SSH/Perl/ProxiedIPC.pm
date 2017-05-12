package Net::SSH::Perl::ProxiedIPC;
use strict;
use warnings;
use vars qw($VERSION);

$VERSION = '0.02';

=head1 NAME

Net::SSH::Perl::ProxiedIPC - Make long distance SSH commands

=head1 SYNOPSIS

	my $ssh = Net::SSH::Perl->new( ... );

	my $pipc = Net::SSH::Perl::ProxiedIPC->new( ssh => $ssh );

	{
	my ($cmd, $perlssh) = $pipc->open;

	$perlssh->eval( "use POSIX qw(uname)" );
	my @uname = $perlssh->eval( "uname()" ); # Returns the host of $ssh
	}

	{
	# Go from this host through host1 to host2
	my ($cmd, $perlssh) = $pipc->open( 'user1@host1', 'user2@host2' );

	$perlssh->eval( "use POSIX qw(uname)" );
	my @uname = $perlssh->eval( "uname()" ); # Returns 'host2'
	}

=head1 DESCRIPTION

This is a utility module that wraps around two SSH modules;
L<Net::SSH::Perl> and L<IPC::PerlSSH>. By leveraging PerlSSH against
the authenticated long-distance requests, you create a means to access
data that would otherwise be secured and unaccessible from the outside
world, such as if you were on site with a client. And it lets you call
Perl from the remote machine! Yay!

=head1 METHODS

=over 4

=item new

Create a new proxied object by passing the object you
create with C<Net::SSH::Perl>.

=item open

This is just a wrapper around C<_open_perlssh>, an internal function you
shouldn't have to worry about.

=back

=cut

use IPC::PerlSSH;

sub new {
  my( $class ) = shift;
  bless( { @_ }, $class );
}

sub _ssh {
  $_[0]->{ssh} ||= $_[0]->_build_ssh
}

sub _build_ssh {
  require Net::SSH::Perl;
  Net::SSH::Perl->new();
}

sub _ssh_env_vars {
  if( defined $_[1] ) {
    $_[0]->{ssh_env_vars} = $_[1];
  } else {
    $_[0]->{ssh_env_vars} ||= $_[0]->_build_ssh_env_vars;
  }
}

sub _build_ssh_env_vars {
  return '';
  # this needs work I think. First off, it won't work.
  # +{ $_[0]->_firsthop_perlssh->eval(; 'chomp(my @env = `ssh-agent`); my %new_env; foreach (@env) { /^(.*?)=(.*)/; $ENV{$1} =$new_env{$1}=$2; } return %new_env;' ); }
}

sub _open_perlssh {
  my( $self, @hosts ) = @_;
  my $ssh = $self->_ssh;

  my $env_str = $self->_ssh_env_vars;
  my $command = join ' ',
  	(map "ssh -o StrictHostKeyChecking=no -A $_", @hosts),
  	"perl";
  $command = "sh -c '$env_str$command'";
  my( $read, $write ) = $ssh->open2($command);

  my $readfunc  = sub { sysread( $read, $_[0], $_[1] ) };
  my $writefunc = sub { syswrite( $write, $_[0] ) };

  ($command, IPC::PerlSSH->new( Readfunc => $readfunc, Writefunc => $writefunc ));
}

# Provide a nice interface to _open_ssh()
sub open { shift->_open_perlssh( @_ ) }

1;

__END__

=head1 SEE ALSO

L<Net::SSH::Perl>

=head1 AUTHOR

Jennie Rose Evers-Corvina C<< <seven@nanabox.net> >>, Matthew S Trout

=head1 COPYRIGHT

=head1 LICENSE

You can use this package under the same terms as Perl itself.

=cut
