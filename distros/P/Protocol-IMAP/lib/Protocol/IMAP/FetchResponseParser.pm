package Protocol::IMAP::FetchResponseParser;
{
  $Protocol::IMAP::FetchResponseParser::VERSION = '0.004';
}
use strict;
use warnings;
use parent qw(Parser::MGC Mixin::Event::Dispatch);

use curry;

=pod

(key "value")
(key {5}
12345)
(key {5}
12345 key2 {6}
123456 key3{3}
123 key4{5}

=cut

sub parse {
	my $self = shift;
	$self->scope_of('(', sub {
		+{ map %$_, @{
		$self->sequence_of(sub {
			$self->any_of(
				$self->curry::envelope_section,
				$self->curry::body_section,
				$self->curry::generic_section,
			);
		}) } }
	}, ')')
}

sub nested_section {
	my $self = shift;
	$self->any_of(
		sub { $self->string_or_nil },
		sub { $self->token_int },
		sub { $self->token_ident },
		sub { $self->expect(qr/[a-zA-Z0-9\\_\$-]+/) },
		sub {
			$self->scope_of('(', sub {
				$self->sequence_of(
					$self->curry::nested_section
				)
			}, ')')
		},
	)
}

sub envelope_date { shift->string_or_nil }
sub envelope_subject { shift->string_or_nil }
sub envelope_from { my $self = shift; $self->address_list }
sub envelope_sender { my $self = shift; $self->address_list }
sub envelope_reply_to { my $self = shift; $self->address_list }
sub envelope_to { my $self = shift; $self->address_list }
sub envelope_cc { my $self = shift; $self->address_list }
sub envelope_bcc { my $self = shift; $self->address_list }
sub envelope_in_reply_to { shift->string_or_nil }
sub string_or_nil {
	my $self = shift;
	$self->any_of(
		sub { $self->token_string },
		sub { $self->expect('NIL'); undef },
		sub {
			my $count;
			$self->scope_of('{', sub {
				$count = $self->token_int
			}, '}');
			$self->commit;
			$self->invoke_event(literal_data => $count, \my $buf);
			\$buf
		},
	)
}
sub envelope_message_id {shift->string_or_nil}
sub address_list {
	my $self = shift;
	$self->any_of(
		sub { $self->expect('NIL'); undef },
		sub { $self->scope_of('(', sub {
			$self->sequence_of(
				$self->curry::address_elements
			)
		}, ')') }
	)
}
sub address_elements {
	my $self = shift;
	$self->scope_of('(', sub {
		+{
			name => $self->address_element, # name
			source => $self->address_element, # source list
			mailbox => $self->address_element, # mailbox
			host => $self->address_element, # host
		}
	}, ')')
}

sub address_element { my $self = shift; $self->string_or_nil }
sub envelope_section {
	my $self = shift;
	+{
		lc($self->expect('ENVELOPE')),
		$self->scope_of('(', sub {
			+{
				date        => $self->envelope_date,
				subject     => $self->envelope_subject,
				from        => $self->envelope_from,
				sender      => $self->envelope_sender,
				reply_to    => $self->envelope_reply_to,
				to          => $self->envelope_to,
				cc          => $self->envelope_cc,
				bcc         => $self->envelope_bcc,
				in_reply_to => $self->envelope_in_reply_to,
				message_id  => $self->envelope_message_id
			}
		}, ')')
	}
}

sub body_type { lc(shift->string_or_nil) }
sub body_subtype { lc(shift->string_or_nil) }
sub body_id { shift->string_or_nil }
sub body_description { shift->string_or_nil }
sub body_encoding { lc(shift->string_or_nil) }
sub body_size { shift->token_int }
sub body_lines { shift->token_int }
sub body_parameters {
	my $self = shift;
	$self->scope_of('(', sub {
		+{ @{
		$self->sequence_of(sub {
			lc($self->string_or_nil),
			$self->string_or_nil,
		}) } }
	}, ')')
}

sub body_part {
	my $self = shift;
	+{
		lc($self->expect('BODY')),
		$self->body_section
	}
}

=pod

=cut

sub body_section {
	my $self = shift;
	$self->scope_of('(', sub {
		$self->sequence_of(sub {
			$self->any_of(sub {
				+{
					type        => $self->body_type,
					subtype     => $self->body_subtype,
					parameters  => $self->body_parameters,
					id          => $self->body_id,
					description => $self->body_description,
					encoding    => $self->body_encoding,
					size        => $self->body_size,
					lines       => $self->body_lines,
				}
			}, sub {
				$self->body_section
			})
		})
	}, ')')
}

sub generic_section {
	my $self = shift;
	+{
		lc($self->expect(qr/\S+/)),
		$self->nested_section
	}
}

1;
