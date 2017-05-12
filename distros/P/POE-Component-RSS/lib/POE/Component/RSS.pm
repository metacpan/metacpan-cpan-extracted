package POE::Component::RSS;

=head1 NAME

POE::Component::RSS - Event based RSS parsing

=head1 SYNOPSIS

  use POE qw(Component::RSS);

  POE::Component::RSS->spawn();

  $kernel->post(
    'rss', 
    'parse' => {
      Item => 'item_state',
    },
    $rss_string
  );

=head1 DESCRIPTION

POE::Component::RSS is an event based RSS parsing module. It wraps
XML::RSS and provides a POE based framework for accessing the information
provided.

=head1 INTERFACE

=cut

use warnings;
use strict;

use POE;
use Carp qw(croak);

use XML::RSS;
use Params::Validate qw(validate_with SCALAR);

our $VERSION = '3.01';

=head2 spawn

RSS parser components are not normal objects, but are instead 'spawned'
as separate sessions. This is done with PoCo::RSS's 'spawn' method, which
takes one named parameter:

=over 4

=item C<< Alias => $alias_name >>

'Alias' sets the name by which the session is known. If no alias
is given, the component defaults to 'rss'. It's possible to spawn
several RSS components with different names.

=back

=cut

sub spawn { #{{{
	my $class = shift;

	my %params = validate_with(
		params => \@_,
		spec => {
			Alias => { 
				type => SCALAR,
				default => 'rss',
				optional => 1,
			},
		},
	);

	my $alias = delete $params{'Alias'};

	POE::Session->create(
		inline_states => {
			_start => \&rss_start,
			_stop  => sub {},
			parse  => \&got_parse,
		},
		args => [ $alias ],
	);

	return;
} #}}}


=begin devel

=head2 got_parse

Accepts parse requests, runs the documents through XML::Parser and generates
events. Unfortunately, this call is entirely blocking and, if given a sizeable
document, could take a while to return.

=cut

sub got_parse { #{{{
	my ($return_states, $rss_string, $rss_identity_tag) = @_[ARG0, ARG1, ARG2];

	my @rss_tag;

	if (defined($rss_identity_tag)) {
		@rss_tag = ($rss_identity_tag);
	} else {
		@rss_tag = ();
	}

	my $rss_parser = XML::RSS->new();
  
	$rss_parser->parse($rss_string);
  
	if (exists $return_states->{'Start'}) {
		$_[KERNEL]->post(
			$_[SENDER],
			$return_states->{'Start'},
			@rss_tag
		);
	}

	if (exists $return_states->{'Item'}) {
		foreach my $item (@{$rss_parser->{'items'}}) {
			# $item->{'title'}
			# $item->{'link'}
			$_[KERNEL]->post(
				$_[SENDER],
				$return_states->{'Item'},
				@rss_tag,
				$item
			);
		}
	}

	if (exists $return_states->{'Channel'}) {
		$_[KERNEL]->post(
			$_[SENDER], 
			$return_states->{'Channel'},
			@rss_tag,
			$rss_parser->{'channel'}
		);
	}

	if (exists $return_states->{'Image'}) {
		$_[KERNEL]->post(
			$_[SENDER],
			$return_states->{'Image'},
			@rss_tag,
			$rss_parser->{'image'}
		);
	}

	if (exists $return_states->{'Textinput'}) {
		$_[KERNEL]->post(
			$_[SENDER],
			$return_states->{'Textinput'},
			@rss_tag,
			$rss_parser->{'textinput'}
		);
	}
  
	if (exists $return_states->{'Stop'}) {
		$_[KERNEL]->post(
			$_[SENDER],
			$return_states->{'Stop'},
			@rss_tag
		);
	}

	return;

} #}}}


=head2 rss_start

Just sets our alias

=cut

sub rss_start { #{{{
	$_[KERNEL]->alias_set($_[ARG0]);
} #}}}

1;
__END__

=end devel

=head2 Postbacks

Sessions communicate asynchronously with PoCo::RSS - they post requests
to it, and it posts results back.

Parse requests are posted to the component's C<parse> state, and
include a hash of states to return results to, and a RSS string to
parse, followed by an optional identity parameter. For example:

  $kernel->post(
    'rss', 
    'parse' => { # hash of result states
      Item      => 'item_state',
      Channel   => 'channel_state',
      Image     => 'image_state',
      Textinput => 'textinput_state',
      Start     => 'start_state',
      Stop      => 'stop_state',
    },
    $rss_string, $rss_identity_tag);

Currently supported result events are:

=over 4

=item C<< Item => 'item_state' >>

A state to call every time an item is found within the RSS
file. Called with a reference to a hash which contains all attributes
of that item.

=item C<< Channel => 'channel_state' >>

A state to call every time a channel definition is found within the
RSS file. Called with a reference to a hash which contains all attributes
of that channel.

=item C<< Image => 'image_state' >>

A state to call every time an image definition is found within the
RSS file. Called with a reference to a hash which contains all attributes
of that image.

=item C<< Textinput => 'textinput_state' >>

A state to call every time a textinput definition is found within the
RSS file. Called with a reference to a hash which contains all attributes
of that textinput.

=item C<< Start => 'start_state' >>

A state to call at the start of parsing.

=item C<< Stop => 'stop_state' >>

A state to call at the end of parsing.

=back

If an identity parameter was supplied with the parse event, the first
parameter of all result events is that identity string. This allows easy
identification of which parse a result is for.

=head1 BUGS

=over 4

=item *

Some events may be emitted even if no data was found. Calling
code should check return data to verify content.

=item *

This really needs to be rewritten using C<POE::Filter::XML>.
Of course, I've been saying that for a few years now... 

=back

=head1 AUTHORS

=over 4

=item * Matt Cashner - sungo@pobox.com

=item * Michael Stevens - michael@etla.org

=back

=head1 LICENSE

Copyright (c) 2004, Matt Cashner. All rights reserved.

Copyright (c) 2002, Michael Stevens. All rights reserved. 

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

=over 4

=item * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.  

=item * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

=item * Neither the name of the Matt Cashner nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

=back

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

# vim: ts=4 sw=4 noet
