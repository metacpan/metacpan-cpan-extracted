package Mock;

{

	package Mock::Base;
	sub isa {1}

	sub AUTOLOAD {
		our $AUTOLOAD =~ m{.*::(.+)};
		my $self = shift;
		if (@_) {
			$self->{$1} = shift;
		}
		else {
			$self->{$1};
		}
	}

	sub new {
		my $class = shift;
		bless {@_}, $class;
	}
}

{

	package Mock::Proxy;
	use base 'Mock::Base';

	sub new {
		my $class = shift;
		my $self = $class->SUPER::new(@_);
		XML::EPP::register_obj_uri(
			"urn:ietf:params:xml:ns:domain-1.0",
			"urn:ietf:params:xml:ns:contact-1.0",
		);
		return $self;
	}
}

{

	package Mock::Event::Watcher;
	our @ISA = qw(Mock::Base);

	sub stop {
		my $self = shift;
		$self->{running} = 0;
	}

	sub start {
		my $self = shift;
		$self->{running} = 1;
	}

	sub ready {
		my $self = shift;
		if ( $self->{running}//=1 ) {
			if ( $self->{poll} eq "r" ) {
				if ( length ${ $self->{fd}||\"" }) {
					return 1;
				}
			}
			else {
				1;
			}
		}
	}
}

{

	package Mock::Event;
	our @ISA = qw(Mock::Base);
	for my $func (qw(io timer)) {
		no strict 'refs';
		*$func = sub {
			my $self = shift;
			if (@_) {
				push @{$self->{$func}}, {@_};
				my $w = Mock::Event::Watcher->new
					(
					event => $self,
					@_
					);
				$self->{watchers}{$w}=$w
					if $func eq "io";
				return $w;
			}
			else {
				$self->{$func};
			}
		};
	}

	sub queued_events {
		my $self = shift;
		my $events = $self->{timer}
			or return();
		map {
			my $href = ref $_ eq "HASH" ? $_ : {@$_};
			$href->{desc}
		} @$events;
	}

	sub has_queued_events {
		my $self = shift;
		$self->timer && @{ $self->timer };
	}

	sub queued {
		my $self = shift;
		my $event = shift;
		grep { $_ eq $event } $self->queued_events;
	}

	sub ignore {
		my $self = shift;
		my $event = shift;
		my $events = $self->{timer} or return;
		@$events = grep { $_->{desc} ne $event }
			@$events;
	}

	sub loop_until {
		my $self = shift;
		my $end = shift;
		my $allowed = shift if ref $_[0];
		my $test_name = pop;
		$test_name ||= "event loop";
		my $fail;
		while ( !$end->() ) {
			my $event;
			$event = shift @{ $self->{timer}||=[] }
				or do {
				for my $watcher (values %{$self->{watchers}}) {
					if ( $watcher->ready ) {
						$event = $watcher;
						last;
					}
				}
				};
			last if !$event;
			my $desc = $event->{desc};
			my $cb = $event->{cb};
			if (
				$allowed
				and
				!($desc ~~ @$allowed)
				)
			{

				# Hoist the main::fail!!
				main::fail(
					"$test_name - "
						."illegal event '$desc' "
						."(allowed: @$allowed)"
				);
				++$fail;
				last;
			}
			else {
				$cb->();
			}
		}
		main::pass("$test_name - events as expected")
			unless $fail;
	}
}

{

	package Mock::IO;
	use Encode;
	use utf8;
	use bytes qw();
	our @ISA = qw(Mock::Base);
	our @model_fds = qw(5 8 4 7);

	sub new {
		my $class = shift;
		my $self = $class->SUPER::new(@_);
		$self->{get_fd} = shift @model_fds;
		$self;
	}

	sub get_fd {
		my $self = shift;
		\$self->{input};
	}
	use bytes;

	sub read {
		my $self = shift;
		my $how_much = shift;
		bytes::substr $self->{input}, 0, $how_much, "";
	}

	sub peek {
		my $self = shift;
		my $how_much = shift;
		bytes::substr $self->{input}, 0, $how_much;
	}
	our $been_evil;

	sub write {
		my $self = shift;
		my $data = shift;
		my $how_much = bytes::length($data);
		if ( rand(1) < 0.5 ) {

			# be EEEVIL and split string in the middle of
			# a utf8 sequence if we can... hyuk yuk yuk
			$data = Encode::encode("utf8", $data)
				if utf8::is_utf8($data);
			if ( $data =~ /^(.*?[\200-\377])/ and !$been_evil ) {

				#print STDERR "BEING DELIGHTFULLY EVIL\n";
				$how_much = bytes::length($1);
				$been_evil++;
			}
			else {
				$how_much = int($how_much * rand(1));
			}
		}
		$self->{output}//="";
		$self->{output} .= bytes::substr($data, 0, $how_much);
		return $how_much;
	}

	sub get_packet {
		my $self = shift;
		my $output = $self->{output};
		my $packet_length = unpack
			("N", bytes::substr($output, 0, 4));
		$packet_length or return;
		my $packet = bytes::substr($output, 4, $packet_length - 4);
		if ( bytes::length($packet)+4 == $packet_length ) {
			bytes::substr($self->{output}, 0, $packet_length, "");
		}
		else {
			return;
		}
		return XML::EPP->parse($packet);
	}
}

{

	package Mock::Session;
	use base 'Mock::Base';

	sub new {
		shift;
		bless {input=>[@_],output=>[]}, __PACKAGE__;
	}

	sub read_input {
		my $self = shift;
		my $length = shift;
		my $packet = shift @{ $self->{input} };
		$packet //= "";
		warn(
			"read was bigger than asked for! wanted $length,"
				." have ".length($packet)
			)
			if length $packet > $length;
		$packet;
	}

	sub input_packet {
		my $self = shift;
		my $packet = shift;
		push @{ $self->{output} }, $packet;
	}

	sub input_ready {
		0
	}
}

{

	package Mock::Session::FromFile;
	our @ISA = qw(Mock::Session);

	sub new {
		my $class = shift;
		open my $fh, shift or die $!;
		binmode $fh;
		bless {fh=>$fh,output=>[]}, $class;
	}

	sub read_input {
		my $self = shift;
		my $length = shift;
		my $well_give_them_cackle = rand(1)>0.2
			? int(rand($length))
			: $length;
		$well_give_them_cackle ||= 1;
		read $self->{fh}, (my $data), $well_give_them_cackle;
		return $data;
	}
}

1;
