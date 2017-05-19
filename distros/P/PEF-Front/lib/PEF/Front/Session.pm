package PEF::Front::Session;

use strict;
use warnings;
use PEF::Front::Config;
use Digest::SHA qw(sha1_hex);
use Scalar::Util 'blessed';
use Math::Random::Secure 'rand';
use feature 'state';

sub _secure_value {
	return sha1_hex(rand . rand . rand . rand);
}

sub get_key_value_from_request {
	my ($request) = @_;
	my $key = (
		  blessed($request) ? $request->param(cfg_session_request_field()) || $request->cookies->{cfg_session_request_field()}
		: ref($request)     ? $request->{cfg_session_request_field()}
		:                     $request
	);
	$key ||= _secure_value;
	return $key;
}

sub _load_module {
	my $module = cfg_session_module();
	if ($module !~ /::/) {
		$module = "PEF::Front::Session::$module";
	}
	my $module_file = $module;
	$module_file =~ s|::|/|g;
	$module_file .= ".pm";
	if (!$INC{$module_file}) {
		eval {require $module_file};
		if ($@) {
			die {
				result      => 'INTERR',
				answer      => 'Unknown session provider $1',
				answer_args => [$module]
			};
		}
	}
	return $module;
}

sub new {
	my ($class, $request) = @_;
	state $module = _load_module;
	my $self = "$module"->init($request);
	bless $self, $module;
	$self->load;
	$self;
}

sub init {
	my ($class, $request) = @_;
	my $key = get_key_value_from_request($request);
	return [$key, [time + cfg_session_ttl(), {}]];
}

sub load {
}

sub store {
}

sub destroy {
}

sub data {
	return $_[1][1];
}

sub key {
}

1;

__END__

=head1 NAME
 
PEF::Front::Session - Session data object

=head1 SYNOPSIS

  my $session = PEF::Front::Session->new($context->{request});
  if ($session->data->{name}) {
    $name      = $session->data->{name};
    $is_author = $session->data->{is_author};
  }

=head1 DESCRIPTION

This module allows you to easily create sessions , store data in them and 
later retrieve that information. It uses L<Storable> for data serialisation.

=head1 FUNCTIONS

=head2 new([$key])

Makes new session object. $key is unique string or request object. 
If it is empty or omitted then it will be generated.
If $key is a request object then it will be looked in request parameters 
and then in cookies for C<cfg_session_request_field> to get the key.

=head2 load()

Loads session data associated with the key.

=head2 store()

Stores session data associated with the key. You don't need to call it
usually, only when you want to synchronize data with storage.

=head2 destroy()

Destroys session data associated with the key.

=head2 key()

Returns session key.

=head2 data([$hash])

Returns and optionaly sets session data hash. 

=head1 AUTHOR
 
This module was written and is maintained by Anton Petrusevich.

=head1 Copyright and License
 
Copyright (c) 2016 Anton Petrusevich. Some Rights Reserved.
 
This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
