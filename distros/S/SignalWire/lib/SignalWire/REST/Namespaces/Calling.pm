package SignalWire::REST::Namespaces::Calling;
use strict;
use warnings;
use Moo;
extends 'SignalWire::REST::Namespaces::Base';

# REST call control -- all commands dispatched via single POST endpoint.

sub BUILD {
    my ($self) = @_;
    # base_path is /api/calling/calls
}

sub _execute {
    my ($self, $command, $call_id, %params) = @_;
    my %body = (command => $command, params => \%params);
    $body{id} = $call_id if defined $call_id;
    return $self->_http->post($self->_base_path, body => \%body);
}

# Call lifecycle
sub dial        { my ($s, %p) = @_; $s->_execute('dial', undef, %p) }
# Python parity: `update` is the public name; `update_call` stays as an
# alias because earlier Perl releases shipped with that name.
sub update      { my ($s, %p) = @_; $s->_execute('update', undef, %p) }
sub update_call { my ($s, %p) = @_; $s->_execute('update', undef, %p) }
sub end         { my ($s, $id, %p) = @_; $s->_execute('calling.end', $id, %p) }
sub transfer    { my ($s, $id, %p) = @_; $s->_execute('calling.transfer', $id, %p) }
sub disconnect  { my ($s, $id, %p) = @_; $s->_execute('calling.disconnect', $id, %p) }

# Play
sub play        { my ($s, $id, %p) = @_; $s->_execute('calling.play', $id, %p) }
sub play_pause  { my ($s, $id, %p) = @_; $s->_execute('calling.play.pause', $id, %p) }
sub play_resume { my ($s, $id, %p) = @_; $s->_execute('calling.play.resume', $id, %p) }
sub play_stop   { my ($s, $id, %p) = @_; $s->_execute('calling.play.stop', $id, %p) }
sub play_volume { my ($s, $id, %p) = @_; $s->_execute('calling.play.volume', $id, %p) }

# Record
sub record        { my ($s, $id, %p) = @_; $s->_execute('calling.record', $id, %p) }
sub record_pause  { my ($s, $id, %p) = @_; $s->_execute('calling.record.pause', $id, %p) }
sub record_resume { my ($s, $id, %p) = @_; $s->_execute('calling.record.resume', $id, %p) }
sub record_stop   { my ($s, $id, %p) = @_; $s->_execute('calling.record.stop', $id, %p) }

# Collect
sub collect                    { my ($s, $id, %p) = @_; $s->_execute('calling.collect', $id, %p) }
sub collect_stop               { my ($s, $id, %p) = @_; $s->_execute('calling.collect.stop', $id, %p) }
sub collect_start_input_timers { my ($s, $id, %p) = @_; $s->_execute('calling.collect.start_input_timers', $id, %p) }

# Detect
sub detect      { my ($s, $id, %p) = @_; $s->_execute('calling.detect', $id, %p) }
sub detect_stop { my ($s, $id, %p) = @_; $s->_execute('calling.detect.stop', $id, %p) }

# Tap
sub tap      { my ($s, $id, %p) = @_; $s->_execute('calling.tap', $id, %p) }
sub tap_stop { my ($s, $id, %p) = @_; $s->_execute('calling.tap.stop', $id, %p) }

# Stream
sub stream      { my ($s, $id, %p) = @_; $s->_execute('calling.stream', $id, %p) }
sub stream_stop { my ($s, $id, %p) = @_; $s->_execute('calling.stream.stop', $id, %p) }

# Denoise
sub denoise      { my ($s, $id, %p) = @_; $s->_execute('calling.denoise', $id, %p) }
sub denoise_stop { my ($s, $id, %p) = @_; $s->_execute('calling.denoise.stop', $id, %p) }

# Transcribe
sub transcribe      { my ($s, $id, %p) = @_; $s->_execute('calling.transcribe', $id, %p) }
sub transcribe_stop { my ($s, $id, %p) = @_; $s->_execute('calling.transcribe.stop', $id, %p) }

# AI
sub ai_message { my ($s, $id, %p) = @_; $s->_execute('calling.ai_message', $id, %p) }
sub ai_hold    { my ($s, $id, %p) = @_; $s->_execute('calling.ai_hold', $id, %p) }
sub ai_unhold  { my ($s, $id, %p) = @_; $s->_execute('calling.ai_unhold', $id, %p) }
sub ai_stop    { my ($s, $id, %p) = @_; $s->_execute('calling.ai.stop', $id, %p) }

# Live transcribe / translate
sub live_transcribe { my ($s, $id, %p) = @_; $s->_execute('calling.live_transcribe', $id, %p) }
sub live_translate  { my ($s, $id, %p) = @_; $s->_execute('calling.live_translate', $id, %p) }

# Fax
sub send_fax_stop    { my ($s, $id, %p) = @_; $s->_execute('calling.send_fax.stop', $id, %p) }
sub receive_fax_stop { my ($s, $id, %p) = @_; $s->_execute('calling.receive_fax.stop', $id, %p) }

# SIP
sub refer { my ($s, $id, %p) = @_; $s->_execute('calling.refer', $id, %p) }

# Custom events
sub user_event { my ($s, $id, %p) = @_; $s->_execute('calling.user_event', $id, %p) }

1;
