package Net::Dropbox;
our $VERSION = '1.091510';

# ABSTRACT: Communicate with local Dropbox daemon

use warnings;
use strict;

use File::HomeDir;

use Moose;
use Moose::Util::TypeConstraints;

use MooseX::StrictConstructor;

use IO::Socket;
use IO::Socket::UNIX;

use Encode;

subtype SocketExists 
	=> as 'Str'
	=> where { -S $_ }
	=> message { "The socket name you provided, $_, is not a valid socket" };

has 'command_socket' => ( 
	is      => 'ro', 
	isa     => 'SocketExists', 
	default => File::HomeDir->my_home.'/.dropbox/command_socket' 
);

has 'hold_connection_open' => ( 
	is      => 'ro', 
	isa     => 'Bool', 
	default => 0 
);

# This is hardcoded into the official C client so I'm mirroring it
has 'max_args' => (
	is         => 'ro',
	isa        => 'Int',
	default    => 20,
	init_arg   => undef
);

has '_socket' => (
	is        => 'rw',
	isa       => 'FileHandle',
	init_arg  => undef
);



sub file_status { #{{{
	my $self = shift;
	my $file = shift;

	my $res = $self->_send_and_fetch(
		"icon_overlay_file_status",
		{ path => $file },
	);

	return $res;
} #}}}





sub dir_status { #{{{
	my $self = shift;
	my $dir  = shift;

	return { ok => 0, status => 'not a dir' } 
		unless( -d $dir );

	my $res = $self->_send_and_fetch(
		"icon_overlay_file_status",
		{ path => $dir },
	);

	if($res->{ok} == 1) {
		my $res2 = $self->_send_and_fetch(
			"get_folder_tag",
			{ path => $dir },
		);

		if($res2->{ok} == 1) {
			for my $key ( keys %$res2 ) {
				$res->{$key} = $res2->{$key};
			}
			
		} else {
			return $res2;
		}
	}

	return $res;

} #}}}


######################
# Internal methods
######################


sub _send_and_fetch { #{{{
	my $self = shift;
	my $cmd = shift;
	my $args = shift;

	my $cmdtxt = $self->_build_command($cmd, $args);

	$self->_open_connection();
	my $sock = $self->_socket();
	print $sock $cmdtxt or die "print : $!\n";

	my $buf = $self->_read_sock_buffer();
	$self->_close_connection();
	
	my $res = $self->_parse_response($buf);

	return $res;
} #}}}

sub _build_command { #{{{
	my $self    = shift;
	my $command = shift;
	my $args    = shift;

	my $output = "$command\n";
	foreach my $arg (sort keys %$args) {
		$output .= "$arg\t$args->{$arg}\n";
	}
	$output .= "done\n";

	$output = encode("utf8", $output);

	return $output;
} #}}}

sub _parse_response { #{{{
	my $self = shift;
	my $text = shift;

	my $res = { ok => 0 };
	my @lines = split("\n", $text);

	#use Data::Dumper; print Dumper \@lines;

	pop @lines; # remove the 'done' on the end

	my $type = shift @lines;

	if($type eq 'notok') {
		$res->{ok} = 0;
		$res->{reason} = shift @lines;

	} elsif ($type eq 'ok') {
		$res->{ok} = 1;

		foreach my $line (@lines) {
			if($line =~ /^(.+?)\t$/) {
				# single word response. Mark it as defined but empty
				$res->{$1} = '';
				next;
			}

			my ($key, $value) = $line =~ /^(.+?)\t(.+?)$/;

			if($key eq 'options') {
				$res->{options} = {};

				my @bits = split(/\t/, $value);
				foreach my $bit (@bits) {
					my ($short, $long, $action) = split(/~/, $bit);
					$res->{options}->{$action} = {
						short => $short,
						long => $long,
						action => $action,
					};
				}
			} else {
				$res->{$key} = $value;
			}
		}
	}

	
	return $res;
} #}}}


sub _open_connection { #{{{
	my $self = shift;
	my $sock = IO::Socket::UNIX->new($self->command_socket) 
		or die $!;
	
	$sock->autoflush(1);

	$self->_socket($sock);
} #}}}

sub _close_connection { #{{{
	my $self = shift;

	unless($self->hold_connection_open) {
		close $self->_socket();
	}
} #}}}

sub _read_sock_buffer { #{{{
	my $self = shift;
	my $sock = $self->_socket();;

	my ($line, $buf);
	while (defined( $line = <$sock> )) {
		$buf .= $line;
		chomp $line;
		if ($line eq 'done') {
			last;
		}
	}
	return $buf;
} #}}}

1;



=pod

=head1 NAME

Net::Dropbox - Communicate with local Dropbox daemon

=head1 VERSION

version 1.091510

=head1 THANKS

This module wouldn't exist without the Dropbox community. With the lack of
documentation and very confusing and poorly written official libraries,
these fine folks did most of my work for me. I think I've read through every
piece of code on the wiki (L<http://wiki.getdropbox.com>) in
my attempt to figure out this protocol.  

Particularly, I want to point out Filip Lundborg (filip@mkeyd.net). His
dbcli.py and status.py files provided much knowledge and helped me more than
any other piece of code I ran across. Thanks, Filip. I owe you a beverage of
your choice. :)




=head1 METHODS

=head2 file_status

	my $hash_ref = $self->file_status("file name");

Retrieves the status of the provided filename and returns it as a hash
reference.

First and only argument is the file name to retrieve status for. This
B<must> be a fully formed uri like C</home/sungo/Dropbox/test.txt> 

If the transaction is successful, 'ok' will be set to 1 and 'status'
will be a string. 'up to date', 'syncing', and 'unsyncable' are
possible values of the string. 

If the transaction is unsuccessful, 'ok' will be set to 0 and 'reason'
will be set to the error string returned by the server. 



=head2 dir_status 

	my $hash_ref = $self->dir_status("directory name");

Retrieves the status of the provided directory and returns it as a hash
reference.

The first and only argument is the directory name to retrieve status
for. This B<must> be a fully formed uri like C</home/sungo/Dropbox/Dir> 

If the transaction is successful, 'ok' will be set to 1. 'status'
will be a string with the possible values of 'up to date', 'syncing',
and 'unsyncable'. 'tag' will be a string with the possible values of
'public', 'shared' and 'photos'. If there is no tags, 'tag' will be an
empty string. 

If the transaction is unsuccessful, 'ok' will be set to 0 and 'reason'
will be set to the error string returned by the server. 



=head1 AUTHOR

  sungo <sungo@sungo.us>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Matt Cashner (sungo).

This is free software, licensed under:

  The (three-clause) BSD License

=cut 



__END__

