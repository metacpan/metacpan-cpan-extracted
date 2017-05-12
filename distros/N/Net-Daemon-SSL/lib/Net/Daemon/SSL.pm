package IO::Socket::SSL::SafeAccept;

use strict;
use POSIX;
use IO::Socket::SSL;
$IO::Socket::SSL::SafeAccept::VERSION = ( split " ", '# 	$Id: SSL.pm,v 1.0 2000/06/14 10:30:56 mkul Exp $	' )[3];
@IO::Socket::SSL::SafeAccept::ISA     = qw(IO::Socket::SSL);

sub accept
{
    my $this   = shift;
    my $result = $this->SUPER::accept ( @_ );
    $! = POSIX::EINTR() if ( ! $result );
    $result;
}

1;

package Net::Daemon::SSL;

=head1 NAME

Net::Daemon::SSL - perl extensions for portable ssl daemons

=head1 SYNOPSIS

 use Net::Daemon::SSL;
 package MyDaemon;
 @MyDaemon::ISA = qw (Net::Daemon::SSL);
 sub Run
 {
     my $this = shift;
     my $buffer;
     $this->{socket}->print ( "vasja was here\n" );
     $this->{socket}->sysread ( $buffer, 100 ); # Attention! getline() method
                                                # do not work with IO::Socket::SSL
                                                # version 0.73
                                                # see perldoc IO::Socket::SSL
                                                # for more details
 }
 package main;
 my $daemon = new MyDaemon ( {}, \ @ARGV ); # you can use --help command line key
 $daemon || die "error create daemon instance: $!\n";
 $daemon->Bind();

=head1 DESCRIPTION

This class implements an IO::Socket::SSL functionality for Net::Daemon
class. See perldoc Net::Daemon for more information about Net::Daemon usage.

=cut

use strict;
use Net::Daemon;
$Net::Daemon::SSL::VERSION = ( split " ", '# 	$Id: SSL.pm,v 1.0 2000/06/14 10:30:56 mkul Exp $	' )[3];
@Net::Daemon::SSL::ISA     = qw (Net::Daemon);

sub Version ($)
{
    'Generic Net::Daemon::SSL server 1.0 (C) Michael Kulakov 2000';
}

=head2 Options

This method add IO::Socket::SSL specific options ( SSL_use_cert,
SSL_verify_mode, SSL_key_file, SSL_cert_file, SSL_ca_path, SSL_ca_file ) to
generic Net::Daemon options. See perldoc IO::Socket::SSL for description of
this options

=cut

sub Options ($)
{
    my $this = shift;
    my $options = $this->SUPER::Options();
    my $descr =  ' - see perldoc IO::Socket::SSL for same parameter';
    $options->{SSL_use_cert}    = { 'template'    => 'SSL_use_cert',
				    'description' => '--SSL_use_cert'    . $descr };
    $options->{SSL_verify_mode} = { 'template'    => 'SSL_verify_mode=s',
				    'description' => '--SSL_verify_mode' . $descr };
    $options->{SSL_key_file}    = { 'template'    => 'SSL_key_file=s',
				    'description' => '--SSL_key_file'    . $descr };
    $options->{SSL_cert_file}   = { 'template'    => 'SSL_cert_file=s',
				    'description' => '--SSL_cert_file'   . $descr };
    $options->{SSL_ca_path}     = { 'template'    => 'SSL_ca_path=s',
				    'description' => '--SSL_ca_path'     . $descr };
    $options->{SSL_ca_file}     = { 'template'    => 'SSL_ca_file=s',
				    'description' => '--SSL_ca_file'     . $descr };
    $options;
}

=head2 Bind

This method creates an IO::Socket::SSL::SafeAccept socket, stores this socket
into $this->{socket} and passes control to parent Net::Daemon::Bind. The
IO::Socket::SSL::SafeAccept is a class inherited from
IO::Socket::SSL with the only difference from parent class - the accept() method of
this class returns EINTR on *any* error. This trick is needed to "hack"
Net::Daemon::Bind functionality: if this method gets an error from accept() 
( Net::Daemon::SSL auth error, for example ) it will call Fatal() method and
die unless this is a EINTR error.

=cut

sub Bind
{
    my $this = shift;
    unless ( $this->{socket} )
    {
	$this->{socket} = new IO::Socket::SSL::SafeAccept
	    ( LocalAddr       => $this->{localaddr},
	      LocalPort       => $this->{localport},
	      Proto           => $this->{proto}  || 'tcp',
	      Listen          => $this->{listen} || 10,
	      Reuse           => 1,
	      SSL_use_cert    => $this->{SSL_use_cert},
	      SSL_verify_mode => $this->{SSL_verify_mode},
	      SSL_key_file    => $this->{SSL_key_file},
	      SSL_cert_file   => $this->{SSL_cert_file},
	      SSL_ca_path     => $this->{SSL_ca_path},
	      SSL_ca_file     => $this->{SSL_ca_file} ) || $this->Fatal("Cannot create socket: $!");
    }
    $this->SUPER::Bind ( @_ );
}

1;

=head1 AUTHOR AND COPYRIGHT

 Net::Daemon::SSL (C) Michael Kulakov, Zenon N.S.P. 2000
                      125124, 19, 1-st Jamskogo polja st,
                      Moscow, Russian Federation

                      mkul@cpan.org

 All rights reserved.

 You may distribute this package under the terms of either the GNU
 General Public License or the Artistic License, as specified in the
 Perl README file.

=head1 SEE ALSO

L<Net::Daemon(3)>, L<IO::Socket::SSL(3)>

=cut

__END__

