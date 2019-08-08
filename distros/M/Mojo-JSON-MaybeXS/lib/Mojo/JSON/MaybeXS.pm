package Mojo::JSON::MaybeXS;

use strict;
use warnings;
use Mojo::Util 'monkey_patch';
use JSON::MaybeXS 'JSON';
use Mojo::JSON ();

our $VERSION = '1.002';

my $BINARY = JSON::MaybeXS->new(utf8 => 1, canonical => 1, allow_nonref => 1,
	allow_unknown => 1, allow_blessed => 1, convert_blessed => 1);
my $TEXT = JSON::MaybeXS->new(utf8 => 0, canonical => 1, allow_nonref => 1,
	allow_unknown => 1, allow_blessed => 1, convert_blessed => 1);
my $TRUE = JSON->true;
my $FALSE = JSON->false;

if (JSON eq 'Cpanel::JSON::XS') {
	local $@;
	if (eval { Cpanel::JSON::XS->VERSION('4.09'); 1 }) {
		$BINARY->allow_dupkeys;
		$TEXT->allow_dupkeys;
	}
	if (eval { Cpanel::JSON::XS->VERSION('3.0112'); 1 }) {
		$BINARY->stringify_infnan;
		$TEXT->stringify_infnan;
	}
	if (eval { Cpanel::JSON::XS->VERSION('3.0206'); 1 }) {
		$BINARY->escape_slash;
		$TEXT->escape_slash;
	}
} elsif (JSON eq 'JSON::PP') {
	$BINARY->escape_slash;
	$TEXT->escape_slash;
}

monkey_patch 'Mojo::JSON', 'encode_json', sub { $BINARY->encode($_[0]) };
monkey_patch 'Mojo::JSON', 'decode_json', sub { $BINARY->decode($_[0]) };

monkey_patch 'Mojo::JSON', 'to_json',   sub { $TEXT->encode($_[0]) };
monkey_patch 'Mojo::JSON', 'from_json', sub { $TEXT->decode($_[0]) };

monkey_patch 'Mojo::JSON', 'true',  sub () { $TRUE };
monkey_patch 'Mojo::JSON', 'false', sub () { $FALSE };

1;

=head1 NAME

Mojo::JSON::MaybeXS - use JSON::MaybeXS as the JSON encoder for Mojolicious

=head1 SYNOPSIS

 use Mojo::JSON::MaybeXS;
 use Mojo::JSON qw/encode_json decode_json true false/;
 
 # Preload for scripts using Mojo::JSON
 $ perl -MMojo::JSON::MaybeXS -S morbo myapp.pl
 
 # Must be set in environment for hypnotoad
 $ PERL5OPT=-MMojo::JSON::MaybeXS hypnotoad myapp.pl

=head1 DESCRIPTION

L<Mojo::JSON::MaybeXS> is a monkey-patch module for using L<JSON::MaybeXS> as
the JSON encoder for a L<Mojolicious> application, or anything else using
L<Mojo::JSON>. It must be loaded before L<Mojo::JSON> so the new functions will
be properly exported.

Since L<Mojolicious> version 7.87, L<Mojo::JSON> has delegated to
L<Cpanel::JSON::XS> by default if installed and recent enough. Installing
L<Mojolicious> version 7.87+ and L<Cpanel::JSON::XS> version 4.09+ resolves the
below listed caveats between these modules, and is sufficient to improve the
performance of L<Mojo::JSON> without the use of this module.

=head1 CAVEATS

L<JSON::MaybeXS> may load different modules behind the scenes depending on what
is available, and these modules have slightly different behavior from
L<Mojo::JSON> and occasionally from each other. References to the behavior of
L<JSON::MaybeXS> below are actually describing the behavior shared among the
modules it loads.

L<JSON::MaybeXS> is used with the options C<canonical>, C<allow_nonref>,
C<allow_unknown>, C<allow_blessed>, and C<convert_blessed>. C<canonical>
enables sorting of hash keys when encoding to JSON objects as L<Mojo::JSON>
does. C<allow_nonref> allows encoding and decoding of bare values outside of
hash/array references, since L<Mojo::JSON> does not prevent this, in accordance
with L<RFC 7159|http://tools.ietf.org/html/rfc7159>. The other options prevent
the encoder from blowing up when encountering values that cannot be represented
in JSON to better match the behavior of L<Mojo::JSON>. See below for more
specifics.

To better match the behavior of L<Mojo::JSON>, certain options may be enabled
depending on the backend that is used. If L<Cpanel::JSON::XS> version 3.0112 or
greater is loaded, it will be used with the option C<stringify_infnan>. If
either L<Cpanel::JSON::XS> of at least version 3.0206 or L<JSON::PP> is loaded,
it will be used with the option C<escape_slash>. If L<Cpanel::JSON::XS> version
4.09 or greater is loaded, it will be used with the option C<allow_dupkeys>.

As of this writing, the author has found the following incompatibilities:

=head2 Object Conversion

Both L<JSON::MaybeXS> and L<Mojo::JSON> will attempt to call the TO_JSON method
of a blessed reference to produce a JSON-friendly structure. If that method
does not exist, L<Mojo::JSON> or L<Cpanel::JSON::XS> version 3.0207 or greater
will stringify the object, while L<JSON::XS> or L<JSON::PP> will always encode
it to C<null>.

 print encode_json([DateTime->now]);
 # Mojo::JSON or Cpanel::JSON::XS >= 3.0207: ["2014-11-30T04:31:13"]
 # JSON::XS or JSON::PP: [null]

=head2 Unblessed References

L<JSON::MaybeXS> does not allow unblessed references other than to hashes,
arrays, or the scalar values C<0> and C<1>, and will encode them to C<null>.
Before L<Mojolicious> version 7.87, L<Mojo::JSON> will treat all scalar
references the same as references to C<0> or C<1> and will encode them to
C<true> or C<false> depending on their boolean value, and other references
(code, filehandle, etc) will be stringified.

Since L<Mojolicious> version 7.87, L<Mojo::JSON>'s behavior with unblessed
references is the same as L<JSON::MaybeXS>.

 print encode_json([\'asdf', sub { 1 }]);
 # Mojo::JSON (Mojolicious >= 7.87): [null,null]
 # JSON::MaybeXS: [null,null]

=head2 Escapes

L<Mojo::JSON> currently escapes the slash character C</> for security reasons.
Before L<Mojolicious> version 7.87, it also escaped the unicode characters
C<u2028> and C<u2029>. L<Cpanel::JSON::XS> version 3.0206 or greater and
L<JSON::PP> will have the option set to escape the slash character, and
L<JSON::XS> does not escape these characters. This does not affect decoding of
the resulting JSON.

 print encode_json(["/\x{2028}/\x{2029}"]);
 # Mojo::JSON (Mojolicious >= 7.87): ["\/ \/ "]
 # Cpanel::JSON::XS >= 3.0206 or JSON::PP: ["\/ \/ "]
 # JSON::XS: ["/ / "]
 # Both decode to arrayref containing: "/\x{2028}/\x{2029}"

=head2 inf and nan

L<Mojo::JSON> encodes C<inf> and C<nan> to strings. L<Cpanel::JSON::XS> version
3.0112 or greater will also stringify C<inf> and C<nan>. However, L<JSON::XS>
or L<JSON::PP> will encode them as numbers (barewords) producing invalid JSON.

 print encode_json([9**9**9, -sin 9**9**9]);
 # Mojo::JSON or Cpanel::JSON::XS >= 3.0112: ["inf","nan"] (on Linux)
 # JSON::XS or JSON::PP: [inf,nan]

=head2 Upgraded Numbers

L<JSON::MaybeXS>, if using L<JSON::XS>, will attempt to guess if a value to be
encoded is numeric or string based on whether Perl has ever populated a string
value for it internally. Therefore, using a variable containing C<13> in a
string context will cause it to be encoded as C<"13"> even if the variable
itself was not changed. L<Mojo::JSON>, L<JSON::PP> version 2.92 or greater, or
L<Cpanel::JSON::XS> version 3.0109 or greater will encode C<13> as C<13>
regardless of whether it has been used as a string.

 my ($num1, $num2) = (13, 14);
 my $str = "$num1";
 print encode_json([$num1, $num2, $str]);
 # Mojo::JSON, JSON::PP >= 2.92, Cpanel::JSON::XS >= 3.0109: [13,14,"13"]
 # JSON::XS: ["13",14,"13"]

=head2 Duplicate Keys

L<Mojo::JSON>, L<JSON::XS>, and L<JSON::PP> will silently accept duplicate keys
in the same JSON object when decoding a JSON string. L<Cpanel::JSON::XS>
version 3.0235 or greater will throw an exception if duplicate keys are
encountered. L<Cpanel::JSON::XS> version 4.09 or greater will have the option
set to once again accept duplicate keys.

 print dumper decode_json('{"foo":1, "bar":2, "foo":3}');
 # Mojo::JSON, JSON::XS, or JSON::PP: { bar => 2, foo => 3 }
 # Cpanel::JSON::XS >= 3.0235 and < 4.09: "Duplicate keys not allowed" exception

=head1 BUGS

This is a monkey-patch of one of a few possible modules into another, and they
have incompatibilities, so there will probably be bugs. Report any issues on
the public bugtracker.

=head1 AUTHOR

Dan Book, C<dbook@cpan.org>

=head1 CREDITS

Sebastian Riedel, author of L<Mojolicious>, for basic implementation.

=head1 COPYRIGHT AND LICENSE

Copyright 2014, Dan Book.

This library is free software; you may redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Mojo::JSON>, L<JSON::MaybeXS>, L<Cpanel::JSON::XS>, L<JSON::XS>, L<JSON::PP>
