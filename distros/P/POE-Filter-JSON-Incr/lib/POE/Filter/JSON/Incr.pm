#!/usr/bin/perl

package POE::Filter::JSON::Incr;
use Any::Moose;

use JSON;
use POE::Filter::JSON::Incr::Error;

use namespace::clean -except => [qw(meta)];

our $VERSION = "0.03";

extends our @ISA, qw(POE::Filter);

# with qw(MooseX::Clone)

sub clone {
	my ( $self, @args ) = @_;

	die "metaclass doesn't support cloning" unless $self->meta->can("clone_object");

	$self->meta->clone_object(
		$self,
		@args,
		# clear the buffers
		buffer => [],
		json => $self->_build_json,
	);
}

has buffer => (
	#traits => [qw(NoClone)],
	isa => "ArrayRef",
	is  => "rw",
	lazy_build => 1,
);

sub _build_buffer { [] }

has json => (
	#traits => [qw(NoClone)],
	is => "rw",
	lazy_build => 1,
	handles => [qw(encode incr_parse incr_skip)],
);

has json_opts => (
	isa => "ArrayRef",
	is  => "rw",
	lazy_build => 1,
);

sub _build_json {
	my $self = shift;

	my $json = JSON->new;

	foreach my $opt ( @{ $self->json_opts } ) {
		$json->$opt;
	}

	return $json;
}

sub _build_json_opts {
	return [qw(
		relaxed
		allow_nonref
		utf8
	)];
}

has error_class => (
	isa => "ClassName",
	is  => "rw",
	default => "POE::Filter::JSON::Incr::Error",
	handles => { create_error_object => "new" },
);

has errors => (
	isa => "Bool",
	is  => "rw",
	default => 0,
);

sub get_one_start {
	my ( $self, $chunks ) = @_;
	$chunks = [ $chunks ] unless ref $chunks;
	push @{ $self->buffer }, $self->_parse($chunks);
}

sub get_one {
	my $self = shift;
	return [ splice @{ $self->buffer }, 0, 1 ]; # shift returns undef, this returns empty list
}

sub get {
	my ( $self, $chunks ) = @_;

	return [
		splice(@{ $self->buffer }),
		$self->_parse($chunks),
	];
}

sub _parse {
	my ( $self, $chunks ) = @_;

	my @ret;

	foreach my $chunk ( @$chunks ) {
		local $@;
		if ( my @out = eval { $self->incr_parse($chunk) } ) {
			push @ret, @out;
		}

		if ( $@ ) {
			$self->incr_skip;
			push @ret, $self->json_error(error => $@, chunk => $chunk);
		}
	}

	return @ret;
}

sub json_error {
	my ( $self, @args ) = @_;

	if ( $self->errors ) {
		return $self->create_error_object(@args);
	} else {
		return ();
	}
}

sub put {
	my ( $self, $data ) = @_;
	return [ map { $self->encode($_) . "\n" } @$data ];
}

sub get_pending {
	my $self = shift;

	if ( my @contents = @{ $self->buffer } ) {
		return \@contents;
	} else {
		return undef;
	}
}

__PACKAGE__

__END__

=pod

=head1 NAME

POE::Filter::JSON::Incr - Parse JSON from streams without needing per-line
input

=head1 SYNOPSIS

	POE::Wheel::Whatever->new(
		Filter => POE::Filter::JSON::Incr->new( ... );
	);

=head1 DESCRIPTION

This filter uses the incremental parsing support found in L<JSON::XS> 2.2 and
L<JSON> 2.09 to decode JSON data from text streams without needing line by line
input.

=head1 ATTRIBUTES

=over 4

=item errors

When true causes L<POE::Filter::JSON::Incr::Error> objects to be created as
input on parse errors.

Defaults to false (errors are silently ignored).

=item error_class

Defaults to L<POE::Filter::JSON::Incr::Error>.

=item json

The instance of the L<JSON> object.

Note that this is stateful, due to the incremental API's interface.

=item json_opts

When no C<json> object is provided, one will be created with these options.
Defaults to C<utf8>, C<relaxed> and C<allow_nonref>.

=item buffer

An array reference of deserialized values.

=back

=head1 METHODS

See L<POE::Filter> for the interface.

=over 4

=item get \@chunks

=item get_one_start \@chunks

=item get_one

These methods will parse the text in C<@chunks>. C<get> will return an array
reference containing all the parsed values, while C<get_one> will remove one
value from the buffer and return it in an array reference.

=item put \@data

This method serializes the data in C<@data> and returns an array of JSON
strings.

=item get_pending

Returns the decoded objects in the buffer without clearing it.

=back

=head1 VERSION CONTROL

This module is maintained using Darcs. You can get the latest version from
L<http://nothingmuch.woobling.org/code>, and use C<darcs send> to commit
changes.

=head1 AUTHOR

Yuval Kogman E<lt>nothingmuch@woobling.orgE<gt>

=head1 COPYRIGHT

	Copyright (c) 2008 Yuval Kogman. All rights reserved
	This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.

=cut
