# Net::IPA.pm -- Perl 5 interface of the (Free)IPA JSON-RPC API
#
#   for more information about this api see: https://vda.li/en/posts/2015/05/28/talking-to-freeipa-api-with-sessions/
#
#   written by Nicolas Cisco (https://github.com/nickcis)
#   https://github.com/nickcis/perl-Net-IPA
#
#     Copyright (c) 2016 Nicolas Cisco. All rights reserved.
#     Licensed under the GPLv2, see LICENSE file for more information.

package Net::IPA::Response;

use strict;

use vars qw($AUTOLOAD);
use constant {
	OptionError => 3005,
	RequirementError => 3007,
	NotFound => 4001,
	DuplicateEntry => 4002,
	EmptyModlist => 4202, # e.g: user_mod with no modifications to the db
};

sub new
{
	my ($proto, $result) = @_;
	my $class = ref($proto) || $proto;
	my $self = $result || {};
	bless $self, $class;
	return $self;
}

#** Returns a string explaining the error.
# If it's not an error, it returns an empty string
# @return String explaining the error
#*
sub error_string
{
	my ($self) = @_;
	return "" unless($self->is_error());
	return "undef" unless(%$self);
	return "code: " . $self->error_code() ." (" . $self->error_name() .") " . $self->error_message();
}

sub error_code
{
	my ($self) = @_;
	return $self->{error_code} if($self->{error_code});
	return $self->{error}->{code} if(ref($self->{error}) eq 'HASH' and $self->{error}->{code});
	return 0;
}

sub error_name
{
	my ($self) = @_;
	return $self->{error_name} if($self->{error_name});
	return $self->{error}->{name} if(ref($self->{error}) eq 'HASH' and $self->{error}->{name});
	return '';
}

sub error_message
{
	my ($self) = @_;
	return $self->{error}->{message} if(ref($self->{error}) eq 'HASH' and $self->{error}->{message});
	return $self->{error} if($self->{error});
	return '';
}

#** Checks if the response is an error.
# @returns 1: If error, 0: if not error
#*
sub is_error
{
	my ($self) = @_;
	return 1 if(
		not(%$self) ||
		$self->error_code() ||
		$self->error_name() ||
		$self->error_message()
	);
	return 0;
}

sub AUTOLOAD
{
	my ($self) = @_;

	my $sub = $AUTOLOAD;
	(my $name = $sub) =~ s/.*:://;

	if(ref($self->{result}) eq 'HASH'){
		my $value = $self->{result}->{$name};
		return  ref($value) eq 'ARRAY' ? $value->[0] : $value;
	};


	return undef;
}

1;
