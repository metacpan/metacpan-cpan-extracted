use 5.006;

package Template::Plugin::JSON; # git description: v0.07-6-g80fc733
# ABSTRACT: Adds a .json vmethod for all TT values.

use Moose;

use JSON::MaybeXS 'JSON';

use Carp qw/croak/;

extends qw(Moose::Object Template::Plugin);

our $VERSION = '0.08';


has context => (
	isa => "Object",
	is  => "ro",
	weak_ref => 1,
);

has json_converter => (
	isa => "Object",
	is  => "ro",
	lazy_build => 1,
);

has json_args => (
	isa => "HashRef",
	is  => "ro",
	default => sub { {} },
);

sub BUILDARGS {
    my ( $class, $c, @args ) = @_;

	my $args;

	if ( @args == 1 and not ref $args[0] ) {
		warn "Single argument form is deprecated, this module always uses JSON::PP/Cpanel::JSON::XS now";
	}

	$args = ref $args[0] ? $args[0] : {};

	return { %$args, context => $c, json_args => $args };
}

sub _build_json_converter {
	my $self = shift;

	my $json = JSON()->new->allow_nonref(1);

	my $args = $self->json_args;

	for my $method (keys %$args) {
		if ( $json->can($method) ) {
			$json->$method( $args->{$method} );
		}
	}

	return $json;
}

sub json {
	my ( $self, $value ) = @_;

	$self->json_converter->encode($value);
}

sub json_decode {
	my ( $self, $value ) = @_;

	$self->json_converter->decode($value);
}

sub BUILD {
	my $self = shift;
	$self->context->define_vmethod( $_ => json => sub { $self->json(@_) } ) for qw(hash list scalar);
}

__PACKAGE__;

__END__

=pod

=encoding UTF-8

=head1 NAME

Template::Plugin::JSON - Adds a .json vmethod for all TT values.

=head1 VERSION

version 0.08

=head1 SYNOPSIS

	[% USE JSON ( pretty => 1 ) %];

	<script type="text/javascript">

		var foo = [% foo.json %];

	</script>

	or read in JSON

	[% USE JSON %]
	[% data = JSON.json_decode(json) %]
	[% data.thing %]

=head1 DESCRIPTION

This plugin provides a C<.json> vmethod to all value types when loaded. You
can also decode a json string back to a data structure.

It will load the L<JSON::MaybeXS> module, which will use L<Cpanel::JSON::XS>
when possible and fall back to L<JSON::PP> otherwise.

Any options on the USE line are passed through to the JSON object, much like L<Cpanel::JSON::XS/to_json>.

=head1 SEE ALSO

L<JSON::MaybeXS>, L<Template::Plugin>

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Template-Plugin-JSON>
(or L<bug-Template-Plugin-JSON@rt.cpan.org|mailto:bug-Template-Plugin-JSON@rt.cpan.org>).

=head1 AUTHOR

יובל קוג'מן (Yuval Kogman) <nothingmuch@woobling.org>

=head1 CONTRIBUTORS

=for stopwords Neil Bowers Karen Etheridge Graham Barr Leo Lapworth perigrin

=over 4

=item *

Neil Bowers <neil@bowers.com>

=item *

Karen Etheridge <ether@cpan.org>

=item *

Graham Barr <gbarr@pobox.com>

=item *

Leo Lapworth <leo@cuckoo.org>

=item *

perigrin <perigrin@cpan.org>

=back

=head1 COPYRIGHT AND LICENCE

This software is Copyright (c) 2006 by Yuval Kogman.

This is free software, licensed under:

  The MIT (X11) License

=cut
