package Protocol::IMAP::Fetch;
{
  $Protocol::IMAP::Fetch::VERSION = '0.004';
}
use strict;
use warnings;
use parent qw(Mixin::Event::Dispatch);

use Try::Tiny;
use Future;
use Protocol::IMAP::FetchResponseParser;
use Protocol::IMAP::Envelope;
use List::Util qw(min);

sub new {
	my $class = shift;
	my $self = bless {
		parse_buffer => '',
		@_
	}, $class;
	$self->{parser} = Protocol::IMAP::FetchResponseParser->new;
	$self->{parser}->subscribe_to_event(
		literal_data => sub {
			my ($ev, $count) = @_;
#			warn "Have pos=". $self->parser->pos . " count $count len " . length($self->{parse_buffer}) . "\n";
			eval {
				my $starter = substr $self->{parse_buffer}, $self->parser->pos, min($count, length($self->{parse_buffer}) - $self->parser->pos), '';
				$self->{literal} = $starter;
				$self->{remaining} = $count - length($starter);
				1
			} or do { $self->{literal} = ''; $self->{remaining} = $count };
			$self->{reading_literal} = 1;
			$self->{parse_buffer} =~ s/\Q{$count}\E$/""/;
		}
	);
	$self
}

sub parser { shift->{parser} }
sub parse_buffer { shift->{parse_buffer} }
sub completion { shift->{completion} ||= Future->new }

sub on_read {
	my $self = shift;
	my $buffref = shift;
#	warn "reading with " . $$buffref . "\n";
	READ:
	while(1) {
		if($self->{reading_literal}) {
#			warn "We are reading a literal, remaining " . $self->{remaining};
			my $chunk = substr $$buffref, 0, min($self->{remaining}, length($$buffref)), '';
			$self->{literal} .= $chunk;
			$self->{remaining} -= length $chunk;
			return 1 if $self->{remaining};
#			warn "Completed read, had " . length($self->{literal}) . " bytes\n";
			delete $self->{reading_literal};
			next READ;
		}
		if($$buffref =~ s/^([^\r\n]*)[\r\n]*//) {
#			warn "[$1]\n";
			$self->{parse_buffer} .= $1;
			die "bad chars found..." if $self->parse_buffer =~ /[\r\n]/;
#			warn "Reading data, buffer is now:\n" . $self->parse_buffer;
			return 1 unless $self->attempt_parse;
			$$buffref = $self->{parse_buffer} . $$buffref;
			return 0;
		}

#		warn "no handler, buffer is currently " . $$buffref;
#		$self->{parse_buffer} .= substr $$buffref, 0, length($$buffref);
		return 1;
	}
}

sub on_done { my $self = shift; $self->completion->on_done(@_) }

#sub literal_string {
#	my $self = shift;
#	my $str = shift;
#	my $count = length($str);
#	warn "Had $count in literal string";
#	$self->{parse_buffer} =~ s/\Q{$count}\E$/""/;
#	$self->attempt_parse;
#}

sub attempt_parse {
	my $self = shift;
	my $parser = $self->parser;
	try {
#		warn "$self Will try to parse: [" . $self->parse_buffer . "]\n";
		my $rslt = $parser->from_string($self->parse_buffer);
#		warn "... and we're done\n";
		$self->{fetched} = $rslt;
		$self->{data}{size} = Future->new->done($rslt->{'rfc822.size'});
		$self->{parse_buffer} = '';
		$self->completion->done($self);
		1
	} catch {
		if(/^Expected end of input/) {
#			warn "Had end-of-input warning, this is good\n";
			substr $self->{parse_buffer}, 0, $parser->pos - 1, '';
			return 1;
		}
#		warn "Failure from parser: $_\n";
		0
	};
}

=head2 data

Returns a L<Future> which will resolve when the given
item is available. Suitable for smaller data strucures
such as the envelope. Not recommended for the full
body of a message, unless you really want to load the
entire message data into memory.

=cut

sub data {
	my $self = shift;
	my $k = shift;
	return $self->{data}{$k} if exists $self->{data}{$k};
	$self->{data}{$k} = my $f = Future->new;
	$self->completion->on_done(sub {
		$f->done(Protocol::IMAP::Envelope->new(
			%{$self->{fetched}{$k}}
		));
	});
	$f
}

=head2 stream

This is what you would normally use for a message, although
at the moment you can't, so don't.

=cut

sub stream { die 'unimplemented' }

1;

__END__

=pod

=over 4

=item * L<Protocol::IMAP::Envelope> - represents the message envelope

=item * L<Protocol::IMAP::Address> - represents an email address as found in the message envelope

=back

my $msg = $imap->fetch(message => 123);
$msg->data('envelope')->on_done(sub {
	my $envelope = shift;
	say "Date: " . $envelope->date;
	say "From: " . join ',', $envelope->from;
	say "To:   " . join ',', $envelope->to;
	say "CC:   " . join ',', $envelope->cc;
	say "BCC:  " . join ',', $envelope->bcc;
});


Implementation:

The untagged FETCH response causes instantiation of this class. We pass
the fetch line as the initial buffer, set up the parser and run the first
parse attempt.

If we already have enough data to parse the FETCH response, then we relinquish
control back to the client.

If there's a {123} string literal, then we need to stream that amount of data:
we request a new sink, primed with the data we have so far, with the byte count
({123} value) as the limit, and allow it to pass us events until completion.

In streaming mode, we'll pass those to event listeners.
Otherwise, we'll store this data internally to the appropriate key.

then switch back to line mode.

