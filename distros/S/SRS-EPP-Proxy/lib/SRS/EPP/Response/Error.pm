# vim: filetype=perl:noexpandtab:ts=3:sw=3
#
# Copyright (C) 2009  NZ Registry Services
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the Artistic License 2.0 or later.  You should
# have received a copy of the Artistic License the file COPYING.txt.
# If not, see <http://www.perlfoundation.org/artistic_license_2_0>
use strict;
use warnings;

use 5.010;

package SRS::EPP::Response::Error;
{
  $SRS::EPP::Response::Error::VERSION = '0.22';
}
use Moose;
use MooseX::StrictConstructor;
use Data::Dumper;

with 'MooseX::Log::Log4perl::Easy';

use SRS::EPP::Response::Error::Map qw(map_srs_error map_srs_error_code);

use XML::LibXML;
use PRANG::Graph::Context;
use XML::SRS::Error;

extends 'SRS::EPP::Response';

has 'exception' =>
	is => 'ro',
	;

has 'bad_node' =>
	is => "rw",
	isa => "XML::LibXML::Node",
	;

has '+server_id' =>
	required => 1,
	;

has '+code' =>
	lazy => 1,
	default => \&derive_error_code,
	;

sub derive_error_code {
	my $self = shift;
	my $exception = @_ ? shift : $self->exception;
	if ( ref $exception and ref $exception eq "ARRAY" ) {
		return $self->derive_error_code($exception->[0]);
	}
	given ($exception) {
		when (!blessed $_) {
			return 2400;
		}
		when ($_->isa("XML::LibXML::Error")) {
			return 2001;
		}
		when ($_->isa("XML::SRS::Error")) {
			return map_srs_error_code($exception);
		}
		when ($_->isa("PRANG::Graph::Context::Error")) {
			return 2004;
		}
	}
}

has '+extra' =>
	lazy => 1,
	default => \&derive_extra,
	;

sub derive_extra {
	my $self = shift;
	my $exception = @_ ? shift : $self->exception;
	given ($exception) {
		when (! defined $_) {
			return "";
		}
		when (!ref $_) {
		    return m{^(.+?)(?:at .+? line \d+)?\.?$} ? $1 : $_;
		}
		when (ref($_) eq "ARRAY") {
			return join "; ", map {
				$self->derive_extra($_);
			} @$exception;
		}
		when (!blessed $_) {
			return "";
		}
		when ($_->isa("XML::LibXML::Error")) {
			return "Input XML not valid (or xmlns error)";
		}
		when ($_->isa("XML::SRS::Error")) {
			return $exception->desc;
		}
		when ($_->isa("PRANG::Graph::Context::Error")) {
			return "Input violates XML Schema";
		}
		default {
			return "";
		}
	}
}

has 'mapped_errors' =>
	is => "ro",
	isa => "ArrayRef[XML::EPP::Error]",
	lazy => 1,
	default => sub {
	my $self = shift;
	my $exceptions_a = $self->exception;
	unless (
		ref $exceptions_a
		and
		ref $exceptions_a eq "ARRAY"
		)
	{
		$exceptions_a = [$exceptions_a];
	}
	[ map { map_exception($_) } @$exceptions_a ];
	};

sub map_exception {
	my $except = shift;
	given ($except) {
		when (ref $_ eq 'ARRAY') {
			return map { map_exception($_) } @$except;
		}
		when (!blessed($_)) {
			my $errorstr = ref $_ ? Dumper $_ : $_;
			my @lines = split /\n/, $errorstr;
			my $reason = parse_moose_error($lines[0], 1);
			return XML::EPP::Error->new(
				value => 'Unknown',
				reason => $reason||'(none)',
			);
		}
		when ($_->isa("PRANG::Graph::Context::Error")) {
			use YAML;
			my $xpath = $except->xpath;

			my $message = $except->message;

			my @lines = split /\n/, $message;

			my $reason = "XML Schema validation error at $xpath";

			$reason .= '; ' . parse_moose_error($lines[0]);

			return XML::EPP::Error->new(
				value => $except->node || '',
				reason => $reason || '',
			);
		}
		when ($_->isa("XML::LibXML::Error")) {
			my @errors;
			while ($except) {
				my $error = XML::EPP::Error->new(
					value => $except->context || "(n/a)",
					reason => $except->message || '',
				);
				push @errors, $error;

				# though called '_prev', this function
				# is documented.
				$except = $except->_prev;
			}
			return @errors;
		}
		when ($_->isa("XML::EPP::Error")) {
			return $except;
		}
		when ($_->isa("XML::SRS::Error")) {
			return map_srs_error($except);
		}
	}
}

around 'build_response' => sub {
	my $orig = shift;
	my $self = shift;

	my $message = $self->$orig(@_);
	my $result = $message->message->result;

	my $bad_node = $self->bad_node;
	my $errors_a = $self->exception
		? $self->mapped_errors
		: [];

	$result->[0]->add_error($_) for grep {defined} @$errors_a;
	return $message;
};

# TODO: Moose supports structured errors, although might need an
# extension or a newer version
#  This would be much easier if we used those
sub parse_moose_error {
	my $string = shift;
	my $dont_return_catchall = shift // 0;

	my $error = '';

	if (
		$string =~ m{
		Validation \s failed \s for \s
		'.*::(\w+Type)'
		\s (?:failed \s )?with \s value \s
		(.*) \s at
		}x
		)
	{
		$error = "'$2' does not meet schema requirements for $1";
	}
	elsif (
		$string =~ m{
		Attribute \s \((.+?)\) \s does \s not \s
		pass \s the \s type \s constraint \s
		because: \s Validation \s failed \s for \s
		'.+?' \s (?:failed \s )?
		with \s value \s (.+?) \s at
		}x
		)
	{
		my ($label, $value) = ($1, $2);
		unless ($value =~ m{^(?:ARRAY|HASH)}) {
			$error = "Invalid value $value ($label)";
		}
	}
	elsif ($string =~ m{Attribute \((.+?)\) is required}) {
		$error = "Missing required value ($1)";
	}
	elsif (! $dont_return_catchall) {
		# Catch-all
		$string =~ m{^(.+?)(?:at .+? line \d+)?\.?$};
		$error = $1;
	}

	return $error;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

SRS::EPP::Response::Error - EPP exception/error response class

=head1 SYNOPSIS

 #... in a SRS::EPP::Command subclass' ->process() handler...
 return SRS::EPP::Response::Error->new
        (
             id => "XXXX",
             extra => "...",
        );

=head1 DESCRIPTION

This module handles generating errors; the information these can hold
is specified in RFC3730 / RFC4930.

=head1 SEE ALSO

L<SRS::EPP::Response>, L<SRS::EPP::Command>

=cut

# Local Variables:
# mode:cperl
# indent-tabs-mode: t
# cperl-continued-statement-offset: 8
# cperl-brace-offset: 0
# cperl-close-paren-offset: 0
# cperl-continued-brace-offset: 0
# cperl-continued-statement-offset: 8
# cperl-extra-newline-before-brace: nil
# cperl-indent-level: 8
# cperl-indent-parens-as-block: t
# cperl-indent-wrt-brace: nil
# cperl-label-offset: -8
# cperl-merge-trailing-else: t
# End:
