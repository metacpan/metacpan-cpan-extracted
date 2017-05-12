package PIX::Accesslist;

use strict;
use warnings;

use Carp;
use PIX::Accesslist::Line;

our $VERSION = '1.10';

=pod

=head1 NAME

PIX::Accesslist - Accesslist object for use with PIX::Walker

=head1 SYNOPSIS

PIX::Accesslist is used by PIX::Walker to hold an ACL from a PIX firewall. 
This allows you to programmatically step through an ACL and match lines
to certain criteria.

See B<PIX::Walker> for an example.

  $acl = new PIX::Accesslist($name, $acl_conf, $walker);			


=head1 METHODS

=over

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = { };
	my ($name, $config, $walker) = @_;
	croak("Must provide the access-list name and config block") unless ($name and $config);

	$self->{class} = $class;
	$self->{name} = $name;
	$self->{config} = [ @$config ];
	$self->{config_block} = [ @$config ];
	$self->{walker} = $walker;
	$self->{acl} = [];
	$self->{linenum} = 0;

	bless($self, $class);
	$self->_init;

	return $self;
}

sub _init {
	my $self = shift;

	if (@{$self->{config_block}}[0] !~ /^access-list \S+ \S+/i) {
		carp("Invalid config block passed to $self->{class}");
		return undef;
	}

	$self->{unnamed_any} = 0;
	$self->{unnamed_host} = 0;
	$self->{unnamed_net} = 0;
	$self->{unnamed_proto} = 0;
	$self->{unnamed_service} = 0;

	my $idx = 0;
	my ($word, $next);
	while (defined(my $line = $self->_nextline)) {
		$idx++;
		$line =~ s/^access-list $self->{name}(?: extended)? //;
		next if $line =~ /^remark/;			# ignore remarks
		next unless $line =~ s/^(permit|deny)//;	# strip off action

		my $action = lc $1;
		my $proto = $self->_getproto(\$line);
		my $source = $self->_getnetwork(\$line);
		my $sport = $self->_getports(\$line, $proto);		# will be undef if there's no port or service object-group
		my $dest = $self->_getnetwork(\$line);
		my $dport = $self->_getports(\$line, $proto);		# ... 

		my $o = new PIX::Accesslist::Line($action, $proto, $source, $sport, $dest, $dport, $idx, $self);
		push(@{$self->{acl}}, $o);
	}
}

# returns the next network from the current line. $line is a ref
sub _getnetwork {
	my ($self, $line) = @_;
	croak("\$line must be a reference") unless ref $line;
	my $net;

	my $word = $self->_nextword($line);

	# ignore the 'inferface' source if specified, it does us no good
	#if ($word eq 'interface') {
	#	print "$$line\n";
	#	$word = $self->_nextword($line);	# ignore the interface name
	#	$word = $self->_nextword($line);	# get the next word which should actually be something we expect below
	#}

	if ($word eq 'object-group') {
		$net = $self->{walker}->obj( $self->_nextword($line) );

	} elsif ($word eq 'any') {
		my $name = 'unnamed_any_'.(++$self->{unnamed_any});
		my $conf = [ 
			"object-group network $name", 
			"network-object 0.0.0.0 0.0.0.0" 
		];
		$net = new PIX::Object('network', $name, $conf, $self->{walker});

	} elsif ($word eq 'host') {
		my $ip = $self->_nextword($line);
		my $name = 'unnamed_host_'.(++$self->{unnamed_host});
		my $conf = [ 
			"object-group network $name", 
			"network-object host " . $self->{walker}->alias($ip) 
		];
		$net = new PIX::Object('network', $name, $conf, $self->{walker});

	} elsif (($word =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/) || ($word ne $self->{walker}->alias($word))) {
		my $name = 'unnamed_net_'.(++$self->{unnamed_net});
		my $conf = [ 
			"object-group network $name", 
			"network-object " . $self->{walker}->alias($word) . " " . $self->_nextword($line) 
		];
		$net = new PIX::Object('network', $name, $conf, $self->{walker});

	} else {
		warn "** Unknown network: '$word' at '$self->{name}' line $self->{linenum}: $$line\n";
	}
	
	return $net;
}

# returns the protocol from the current line. $line is a ref
sub _getproto {
	my ($self, $line) = @_;
	croak("\$line must be a reference") unless ref $line;
	my $proto;

	my $word = $self->_nextword($line);
	if ($word eq 'object-group') {
		$proto = $self->{walker}->obj( $self->_nextword($line) );
	} else {
		my $name = 'unnamed_proto_'.(++$self->{unnamed_proto});
		my $conf = [ "object-group protocol $name", "protocol-object $word" ];
		$proto = new PIX::Object('protocol', $name, $conf, $self->{walker});
	}

	return $proto;
}

# returns the next 
sub _geticmp {
	my ($self, $line) = @_;
}

# returns the next service port(s) from the current line. $line is a ref
sub _getports {
	my ($self, $line, $proto) = @_;
	croak("\$line must be a reference") unless ref $line;
	my $port;

	my $word = $self->_nextword($line) || return undef;
	if ($word eq 'object-group') {
		my $word2 = $self->_nextword($line);
		my $obj = $self->{walker}->obj($word2);
		$port = (defined($obj) and $obj->type =~ /service|icmp-type/) ? $obj : undef;
		#print "OBJ=$obj == " . join(',',$obj->enumerate) . "\n" if $obj and $obj->type eq 'icmp-type';
		# put the previous words back in the line, since it's going to
		# be a valid network object-group
		if (!$port) {
			$self->_rewindword($word2, $line);
			$self->_rewindword($word, $line);
		}
	} elsif ($word eq 'eq' || $word eq 'gt' || $word eq 'lt' || $word eq 'neg') {
		my $op = $word;
		$word = $self->_nextword($line);
		my $name = 'unnamed_service_'.(++$self->{unnamed_service});
		my $conf = [ "object-group service $name", "port-object $op $word" ];
		$port = new PIX::Object('service', $name, $conf, $self->{walker});
	} elsif ($word eq 'range') {
		$word = $self->_nextword($line);
		my $word2 = $self->_nextword($line);
		my $name = 'unnamed_service_'.(++$self->{unnamed_service});
		my $conf = [ "object-group service $name", "port-object range $word $word2" ];
		$port = new PIX::Object('service', $name, $conf, $self->{walker});
	} else {	# any other values (eg: 'log') are ignored
		$self->_rewindword($word, $line);
		return undef;
	}

	# save the newly created service group to the main walker object
	if (defined $port and !defined $self->{walker}->obj($port->name)) {
		$self->{walker}{objects}{$port->name} = $port;
	}

	return $port;
}

=item B<elements( )>

=over

Returns the total elements (ACE) in the access-list.
B<Note:> It's not wise to call this over and over again. Store the result
in a variable and use that variable if you need to use this result in multiple
places.

=back

=cut
sub elements {
	my $self = shift;
	my $total = 0;
	$total += $_->elements for $self->lines;
	return $total;
}

=item B<lines( )>

=over

Returns all lines of the ACL. Each line is an B<PIX::Accesslist::Line> object.

=back

=cut
sub lines { @{$_[0]->{acl}} }

=item B<name( )>

=over

Returns the name of the ACL

=back

=cut
sub name { $_[0]->{name} }

=item B<print([$any])>

=over

Pretty prints the ACL. Tries to make it easy to read. If object-group's are used
the names are printed instead of IP's if more than a single IP is present for a line.

$any is an optional string that will be used for any IP that represents 'ANY',
defaults to: 0.0.0.0/0. It's useful to change this to 'ANY' to make the output
easier to read.

  1)  permit (tcp)   192.168.0.0/24 -> 0.0.0.0/0 [Web_Services_tcp: 80,443]
  10) deny   (ip)    0.0.0.0/0 -> 0.0.0.0/0

=back

=cut
sub print {
	my $self = shift;
	my $any = shift; # PIX::Accesslist::Line will default to 0.0.0.0/0
	my $output = "----- Access-list $self->{name} -----\n";
	$output .= $_->print($any) . "\n" for $self->lines;
	return $output;
}

# $line is a ref to a scalar string. The word returned is removed from the string
sub _nextword { (${$_[1]} =~ s/^\s*(\S+)\s*//) ? $1 : undef; }
sub _nextline { $_[0]->{linenum}++; shift @{$_[0]->{config_block}} }
sub _reset { $_[0]->{linenum} = 0; $_[0]->{config_block} = $_[0]->{config} }
sub _rewind { unshift @{$_[0]->{config_block}}, $_[1] }
sub _rewindword { ${$_[2]} = $_[1] . " " . ${$_[2]} }

1;

=pod

=head1 AUTHOR

Jason Morriss <lifo 101 at - gmail dot com>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-pix-walker at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PIX-Walker>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

    perldoc PIX::Walker

    perldoc PIX::Accesslist
    perldoc PIX::Accesslist::Line

    perldoc PIX::Object
    perldoc PIX::Object::network
    perldoc PIX::Object::service
    perldoc PIX::Object::protocol
    perldoc PIX::Object::icmp_type

=head1 COPYRIGHT & LICENSE

Copyright 2006-2008 Jason Morriss, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
