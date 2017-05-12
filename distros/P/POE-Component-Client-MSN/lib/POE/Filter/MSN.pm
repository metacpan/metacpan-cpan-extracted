package POE::Filter::MSN;
use strict;

use POE qw(Component::Client::MSN::Command);

use vars qw($Debug);
$Debug = 0;

sub Dumper { require Data::Dumper; local $Data::Dumper::Indent = 1; Data::Dumper::Dumper(@_) }

sub new {
    my $class = shift;
	my %opts = @_;
	my $o = {
		buffer => '',
		get_state => 'line',
		put_state => 'line',
		body_info => {},
		ftp => 0,
    };
	foreach (keys %opts) {
		$o->{$_} = $opts{$_};
	}
	bless($o, $class);
}

sub get {
	my ($self, $stream) = @_;

	# Accumulate data in a framing buffer.
	$self->{buffer} .= join('', @$stream);

	
	my $many = [];
	while (1) {
		my $input = $self->get_one([]);
		if ($input) {
			push(@$many,@$input);
		} else {
			last;
		}
	}

	return $many;
}

sub get_one_start {
	my ($self, $stream) = @_;

	$Debug && do {
		open(FH,">>/tmp/proto.log");
		print FH join('', @$stream);
		close(FH);
	};
	# Accumulate data in a framing buffer.
	$self->{buffer} .= join('', @$stream);
}

sub get_one {
    my($self, $stream) = @_;
	
    return [] if ($self->{finish});
	
    my @commands;
    if ($self->{get_state} eq 'line') {
		return [] unless($self->{buffer} =~ m/\r\n/s);

		while (1) {
#			warn "buffer length is".length($self->{buffer})."\n";
			if ($self->{ftp} == 1 && $self->{buffer} =~ s/^(.{3})\r\n//) {
#				print STDERR "got [TFR]\n";
				$self->{put_state} = 'msftp';
				my $command =  POE::Component::Client::MSN::Command->new($1);
				if ($command->name eq 'TFR') {
					$self->{body_info} = {
					    command => $command,
					    file_length  => $self->{file_size},
					};
#					print STDERR "file len: ".$self->{file_size}."\n";
					delete $self->{file_size};
				}
				push @commands, $command;
				return \@commands;
			}
			
			if ($self->{buffer} =~ s/^(.{3}) (?:(\d+) )?(.*?)\r\n//) {
#				print STDERR "got [$1] [$2] [$3]\n";
				#while ($self->{buffer} =~ s/^(.{3}) (?:(\d+) )?(.*?)\r\n//){
				my $command =  POE::Component::Client::MSN::Command->new($1, $3, $2);
		    	if ($command->name eq 'MSG') {
					# switch to body
					$self->{get_state} = 'body';
					$self->{body_info} = {
					    command => $command,
					    length  => $command->args->[2],
					};
					last;
			    } elsif ($self->{ftp} == 1 && $command->name eq 'FIL') {
					# switch to body
					$command->name("file_data_stream");
					$self->{body_info} = {
					    command => $command,
					    file_length  => $command->data,
						bytes_read => 0,
						total_bytes_read => 0,
					};
#					print STDERR "file len: ".$command->data."\n";
					push @commands, $command;
					return \@commands;
				} else {
					push @commands, $command;
			    }
			} else {
				#return [];
				last;
			}
		}
    }

    if ($self->{get_state} eq 'body') {
		if (length($self->{buffer}) < $self->{body_info}->{length}) {
		    # not enough bytes
		    $Debug and warn Dumper \@commands;
			return \@commands;
		}
		my $message = substr($self->{buffer}, 0, $self->{body_info}->{length}, '');
		my $command = $self->{body_info}->{command};
		$command->message($message);
		push @commands, $command;
	
		# switch to line by line
		$self->{get_state} = 'line';
    	$Debug and warn "GET: ", Dumper \@commands;
		return \@commands;
    } elsif ($self->{get_state} eq 'msftp-head') {
		my @d = unpack('C*', $self->{buffer});
		
#print STDERR "ftp head: ".scalar(@d)."\n";

		if (scalar(@d) == 0 && $self->{body_info}->{total_bytes_read} == $self->{body_info}->{file_length}) {
#print STDERR "EOF!!\n";
				$self->{get_state} = 'line';
				return [{ eof => 1, stream => ''}];
		}

		# poe locks up here if length of $d is 0
		return [] unless ($#d > 1); # not enough head bytes read
		
		if ($d[0] == 1 && $d[1] == 0 && $d[2] == 0) {
#print STDERR "EOF!\n";
				$self->{buffer} = substr($self->{buffer},3);
				$self->{get_state} = 'line';
				return [{ eof => 1, stream => ''}];
		}
		
		shift(@d); #don't need the first byte
		
		# lenth of body = byte1 + (byte2 * 256)
		$self->{body_info}->{length} = shift(@d) + (shift(@d) * 256);
#		$self->{body_info}->{length} = unpack('S',substr($self->{buffer},1,2));
		$self->{body_info}->{bytes_read} = 0;
#print STDERR "got body len: ".$self->{body_info}->{length}."\n";

		# cut the buffer
		$self->{buffer} = substr($self->{buffer},3);
		
		$self->{get_state} = 'msftp-body';
	}

	if ($self->{get_state} eq 'msftp-body') {
		# do this?
		return [] if (length($self->{buffer}) < $self->{body_info}->{length});

#		$Debug and warn "stream data bytes read:".$self->{body_info}->{bytes_read}."\n";
##		if ($self->{body_info}->{bytes_read} < $self->{body_info}->{length}) {
#		if (length($self->{buffer}) < $self->{body_info}->{length}) {
#			# the complete body has not been read
#			push(@commands,{ stream => $self->{buffer} });
#			$self->{body_info}->{bytes_read} += length($self->{buffer});
#			$self->{body_info}->{total_bytes_read} += length($self->{buffer}); # doesn't get reset
#print STDERR "ftp body:".$self->{body_info}->{bytes_read}." which is ".$self->{body_info}->{total_bytes_read}." out of ".$self->{body_info}->{file_length}."\n";
#			$self->{buffer} = '';
#			# not enough bytes
#			#$Debug and warn Dumper \@commands;
#			return \@commands;
#		}

		if ($self->{body_info}->{bytes_read} == $self->{body_info}->{length}) {
#print STDERR "Forced EOF with ".length($self->{buffer})." bytes in the buffer\n";
			push(@commands,{ eof => 1, stream => '' });
			# switch to line by line
			$self->{get_state} = 'line';
			return \@commands;	
		}
		my $data = substr($self->{buffer}, 0, $self->{body_info}->{length}, '');
		$self->{body_info}->{bytes_read} += length($data);
		$self->{body_info}->{total_bytes_read} += length($data); # doesn't get reset
#print STDERR "ftp: ".$self->{body_info}->{total_bytes_read}." bytes\n";
#print STDERR "ftp body:".$self->{body_info}->{bytes_read}." which is ".$self->{body_info}->{total_bytes_read}." out of ".$self->{body_info}->{file_length}."\n";
		push(@commands,{ stream => $data });
		if ($self->{body_info}->{total_bytes_read} == $self->{body_info}->{file_length}) {
#print STDERR "forced EOF with ".length($self->{buffer})." bytes in the buffer\n";
			push(@commands,{ eof => 1, stream => '' });
			# switch to line by line
			$self->{get_state} = 'line';
		} else {
			# switch to the header
			$self->{get_state} = 'msftp-head';
		}
		return \@commands
    }
	
    $Debug and warn "GET: ", Dumper \@commands;
    return \@commands;
}

sub put {
    my($self, $commands) = @_;
    return [ map $self->_put($_), @$commands ];
}

sub _put {
    my($self, $command) = @_;
#    $Debug and warn "PUT: ", Dumper $command."\r\n";
	if ($self->{ftp} == 1) {
			# MSNFTP doesn't have transactions
			if (ref($command) && exists($command->{name_only})) {
				if ($command->name eq 'TFR') {
					$self->{get_state} = 'msftp-head';
				}
				$Debug and warn "PUT: ".$command->name.($command->no_newline ? '' : "\r\n");
				return $command->name.($command->no_newline ? '' : "\r\n");
			} else {
				if ($self->{put_state} eq 'msftp') {
					my @data;
					# make header and send data
					if ($command->{eof}) {
						my @header = qw(1 0 0);
						push(@data,pack('C*', @header));
					} else {
						my @header = "0";
						#push(@header,pack('S',length($command->{stream})));
						my $x = pack "S", length($command->{stream});
						push(@header,ord(substr($x,0,1)));
						push(@header,ord(substr($x,1,1)));
						push(@data,pack('C*', @header));
						push(@data,$command->{stream});
					}
					return join('',@data);
				} else {
					$Debug and warn "PUT: ".sprintf "%s %s%s",$command->name, $command->data, ($command->no_newline ? '' : "\r\n");
					return sprintf "%s %s%s",$command->name, $command->data, ($command->no_newline ? '' : "\r\n");
				}
			}
	} else {
			# this shouldn't happen, but fix it
			if ($self->{put_state} eq 'msftp') {
				$self->{put_state} = 'line';
			}
			$Debug and warn "PUT: ".sprintf "%s %d %s%s",$command->name, $command->transaction, $command->data, ($command->no_newline ? '' : "\r\n");
			return sprintf "%s %d %s%s",$command->name, $command->transaction, $command->data, ($command->no_newline ? '' : "\r\n");

	}
}

sub get_pending {
	my $self = shift;
	return [ $self->{buffer} ] if length $self->{buffer};
	return undef;
}

1;

