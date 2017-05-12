use Test::More;
use strict;
use warnings;

use Data::Dumper;
use Net::SSH::Perl;

pass( 'This test needs to be implemented' );
# We need to fix this test to login to an appropriate machine

=pod

my $ssh = eval {
	my $ssh = Net::SSH::Perl->new('localhost');
	$ssh->login('user', 'localhost');
	$ssh;
	}
my $pipc = Net::SSH::Perl::ProxiedIPC->new(ssh => $ssh);

my ($cmd, $perlssh) = $pipc->open;

is( ref $perlssh, 'IPC::PerlSSH', "\$perlssh isa IPC::PerlSSH (via $cmd)" );

$perlssh->eval( 'use POSIX qw(uname)' );
my @remote_uname = $perlssh->eval( 'uname()' );

is( $remote_uname[1], "localhost", 'localhost uname() returns localhost' );

my $homedir = $perlssh->eval( '$ENV{HOME}' );
fail( 'we require a little sensibility in our $ENV thank you.' )
  unless defined $homedir;

$perlssh->eval( 'use File::HomeDir' );
my $homedir2 = $perlssh->eval( 'File::HomeDir->my_home' );
is( $homedir2, '/home/user', 'got $ENV{HOME} the smart way' );

my $new_env = $perlssh->eval( 'chomp(my @env = `ssh-agent`); my %new_env; foreach (@env) { /^(.*?)=([^;]+)/ or next; $ENV{$1} =$new_env{$1}=$2; } my $output; $output .= "$_=$new_env{$_} " foreach ( keys %new_env ); $output;' );
diag( Dumper( $new_env ) );
$pipc->{ssh_env_vars} = $new_env; 

my @test_hosts = ( 'user1@host1', 'user2@host2' );
my ($cmd2, $pssh2) = $pipc->open(@test_hosts);
is( ref $pssh2, 'IPC::PerlSSH', "\$pssh2 isa IPC::PerlSSH (via $cmd2)" );

$pssh2->eval( 'use POSIX qw(uname)' );
@remote_uname = $pssh2->eval( 'uname()' );
is( $remote_uname[1], 'localhost', 'uname() returns localhost three jumps into localhost!' );

=cut

done_testing();
