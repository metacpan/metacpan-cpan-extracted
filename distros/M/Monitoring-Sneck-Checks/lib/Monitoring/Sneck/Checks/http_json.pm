package Monitoring::Sneck::Checks::http_json;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::http';

=head1 NAME

Monitoring::Sneck::Checks::http_json - checks values in a JSON response

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    api_health|perl:http_json -u https://api.example.org/health -J status=ok -J checks.db.status=ok
    queue|perl:http_json -H 192.0.2.30 -p 8080 -u /stats -V queue.depth -W 100 -C 500
    first_node|perl:http_json -u https://cluster.example.org/nodes -J nodes.0.healthy=true

=head1 DESCRIPTION

Fetches a URL the same as L<Monitoring::Sneck::Checks::http>, taking
all of its options, then checks values in the JSON it gets back.
Content that is not JSON, or a value that is not there or not what it
should be, is CRITICAL.

Paths are keys split by dots, with numbers indexing arrays, so
nodes.0.name is the name of the first node. -1 is the last. Keys with
dots in them can not be reached.

true, false, and null are compared as those words.

=head1 OPTIONS

These are on top of the options of L<Monitoring::Sneck::Checks::http>.

- -J, --json :: "path=value", a value that must be there, or "path",
something that must be there. May be given more than once.

- -V, --value :: The path to a number to check with --value-warning and
--value-critical, and add to the perfdata.

- -W, --value-warning :: Range for --value.

- -C, --value-critical :: Range for --value.

One of --json or --value must be given. --value-warning and
--value-critical need --value.

=cut

sub option_spec {
	my ($self) = @_;

	return ( $self->SUPER::option_spec, 'json|J=s@', 'value|V=s', 'value-warning|W=s', 'value-critical|C=s' );
}

sub ranges {
	my ($self) = @_;

	return ( $self->SUPER::ranges, 'value-warning', 'value-critical' );
}

sub validate {
	my ( $self, $options ) = @_;

	my @problems = $self->SUPER::validate($options);
	foreach my $name ( 'value-warning', 'value-critical' ) {
		push( @problems, '--' . $name . ' needs --value' )
			if defined( $options->{$name} ) && !defined( $options->{value} );
	}
	push( @problems, 'nothing to check, give --json or --value' )
		if !defined( $options->{json} ) && !defined( $options->{value} );

	return @problems;
} ## end sub validate

=head1 METHODS

=head2 content_problems

Checks the content as http does, then as --json and --value say.

=cut

sub content_problems {
	my ( $self, $response, $content ) = @_;

	require JSON;
	my @found = $self->SUPER::content_problems( $response, $content );
	my $data  = eval { JSON->new->allow_nonref->decode($content) };
	if ($@) {
		push( @found, [ $self->CRITICAL, 'content is not JSON' ] );
		return @found;
	}

	foreach my $json ( @{ $self->opt('json') // [] } ) {
		my ( $path,  $expected ) = split( /=/, $json, 2 );
		my ( $there, $value )    = $self->json_path( $data, $path );
		if ( !$there ) {
			push( @found, [ $self->CRITICAL, $path . ' is not there' ] );
			next;
		}
		next if !defined($expected);
		my $text = _text($value);
		push( @found, [ $self->CRITICAL, $path . ' is ' . $text . ', not ' . $expected ] ) if $text ne $expected;
	} ## end foreach my $json ( @{ $self->opt('json') // [] ...})

	if ( defined( $self->opt('value') ) ) {
		my $path = $self->opt('value');
		my ( $there, $value ) = $self->json_path( $data, $path );
		if ( !$there || ref($value) || !defined($value) || $value !~ /\A-?[0-9]+(?:\.[0-9]+)?(?:[eE][-+]?[0-9]+)?\z/ ) {
			push( @found,
				[ $self->CRITICAL, $path . ' is ' . ( $there ? _text($value) : 'not there' ) . ', not a number' ] );
		} else {
			$self->perfdata(
				label    => $path,
				value    => $value,
				warning  => $self->opt('value-warning'),
				critical => $self->opt('value-critical')
			);
			my $code = $self->threshold_status( $value, $self->opt('value-warning'), $self->opt('value-critical') );
			push( @found, [ $code, $path . ' is ' . $value ] ) if $code != $self->OK;
		} ## end else [ if ( !$there || ref($value) || !defined($value...))]
	} ## end if ( defined( $self->opt('value') ) )

	return @found;
} ## end sub content_problems

=head2 json_path

Finds a path in decoded JSON, as said under L</DESCRIPTION>.

- data :: The decoded JSON.

- path :: The path, such as nodes.0.name.

Returns 1 and the value if it is there, else 0.

    my ( $there, $value ) = $check->json_path( { nodes => [ { name => 'a' } ] }, 'nodes.0.name' );
    # ( 1, 'a' )

=cut

sub json_path {
	my ( $self, $data, $path ) = @_;

	my $at = $data;
	foreach my $key ( split( /\./, $path ) ) {
		if ( ref($at) eq 'HASH' && exists( $at->{$key} ) ) {
			$at = $at->{$key};
		} elsif ( ref($at) eq 'ARRAY'
			&& $key =~ /\A-?[0-9]+\z/
			&& $key < scalar( @{$at} )
			&& -$key <= scalar( @{$at} ) )
		{
			$at = $at->[$key];
		} else {
			return (0);
		}
	} ## end foreach my $key ( split( /\./, $path ) )

	return ( 1, $at );
} ## end sub json_path

# Turns a decoded JSON value into text for comparing and messages.
#
# Args...
#
#     - value :: The value.
#
# Returns true, false, or null for those, "a object" or "a array" for
# those, else the value.
#
# Example...
#
#     _text( JSON::true );    # 'true'
#     _text(undef);           # 'null'
sub _text {
	my ($value) = @_;

	return 'null'                    if !defined($value);
	return $value ? 'true' : 'false' if JSON::is_bool($value);
	return 'a object'                if ref($value) eq 'HASH';
	return 'a array'                 if ref($value) eq 'ARRAY';

	return $value;
} ## end sub _text

1;
