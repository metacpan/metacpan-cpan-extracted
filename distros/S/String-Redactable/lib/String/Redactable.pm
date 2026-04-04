use v5.20;
use utf8;

package String::Redactable;
use experimental qw(signatures);
use warnings::register;

use Carp qw(carp);
use Encode ();

our $VERSION = '1.088';

=encoding utf8

=head1 NAME

String::Redactable - A string that automatically redacts itself

=head1 SYNOPSIS

	use String::Redactable;

	my $string = String::Redactable->new( $sensitive_text );

	say $string;                 # '<redacted string>'
	say $string->to_str_unsafe;  # unredacted text

=head1 DESCRIPTION

C<String::Redactable> tries to prevent you from accidentally exposing
a sensitive string, such as a password, in a larger string, such as a
log message or data dump.

When you carelessly use this as a simple string, you get back the
literal string C<*redacted data*>. To get the actual string, you call
C<to_str_unsafe>:

	$password->to_str_unsafe;

This is not designed to completely protect the sensitive data from
prying eyes. This is simply the UTF-8 encoded version of the value that
is XOR-ed by an object-specific key that is not stored with the object.
All of that is undone by C<to_str_unsafe>.

Beyond that, this module uses L<overload> and other tricks to prevent
the actual string from showing up in output and other strings.

=head2 Notes on serializers

C<String::Redactable> objects resist serialization to the best of
their ability. At worst, the serialization shows the internal string
for the object, which does not expose the key used to XOR the UTF-8
encoded string.

Since the XOR keys are not stored in the object (and those keys are
removed when the object goes out of scope), these values cannot be
serialized and re-inflated. But, that's what you want.

=over 4

=item * L<Data::Dumper> - cannot use C<$Data::Dump::Freezer> because that
requires the

=item * L<Storable> -

=item * JSON modules - this supports C<TO_JSON>

=item * YAML -


=back

=head2 Methods

=over 4

=item new

=cut

use overload
	q("") => sub { $_[0]->placeholder },
	'0+'  => sub { 0 },
	'-X'  => sub { () },

	map { $_ => sub { () } } qw(
		<=> cmp
		lt le gt ge eq ne
		~~
		)
	;

my %keys = ();

my $new_key = sub ($class, $length = 512) {
	state $rc = require List::Util;
	substr(
		join( '',
			List::Util::shuffle(
				map { List::Util::shuffle( 'A' .. 'Z', 'a' .. 'z', qw(= ! : ;) ) } 1 .. 25
				)
			),
		0, $length
		)
	;
	};

=item new( STRING )

Creates an object that hides that string by XOR-ing it with another string that
is not stored in the object, and is not a package variable.

This does not mean that the original string can't be recovered in other ways if
someone wanted to try hard enough, but it keeps you from unintentionally dumping
it into output where it shouldn't be.

=cut

sub new ($class, $string, $opts={}) {
	unless( length $string ) {
		carp sprintf "Argument to %s::new is zero length", __PACKAGE__;
		return;
		}

	my $key = $opts->{'key'} // $new_key->( 5 * length $string );

	my $encoded = Encode::encode( 'UTF-8', $string );
	my $hidden = ($encoded ^ $key);
	my $self = bless \$hidden, $class;
	{ local $SIG{__WARN__} = sub {}; $keys{overload::StrVal($self)} = $key };
	$self;
	}

sub DESTROY ($self) {
	local $SIG{__WARN__} = sub {};
	delete $keys{overload::StrVal($self)};
	}

=item placeholder

The value that is substituted for the actual string.

=cut

sub placeholder ( $class ) {
	state $rc = require Carp;
	Carp::cluck(
		"Possible unintended interpolation of a redactable string",
		) if warnings::enabled();
	'<redacted data>'
	}

=item STORABLE_freeze

Redact strings used in L<Storable>.

=cut

sub STORABLE_freeze ($self, $cloning) {
	$self->placeholder;
	}

=item TO_JSON

Redact the string in serializers that respect C<TO_JSON>.

=cut

sub TO_JSON {
	$_[0]->placeholder;
	}

=item to_str_unsafe

Returns the string that you are trying to hide.

=cut

sub to_str_unsafe ($self) {
	local $SIG{__WARN__} = sub {};
	my $encoded = ($$self ^ $keys{overload::StrVal($self)}) =~ s/\000+\z//r;
	Encode::decode( 'UTF-8', $encoded );
	}

=back

=head1 TO DO


=head1 SEE ALSO


=head1 SOURCE AVAILABILITY

This source is on Github:

	http://github.com/briandfoy/string-redactable

=head1 AUTHOR

brian d foy, C<< <briandfoy@pobox.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2025-2026, brian d foy, All Rights Reserved.

You may redistribute this under the terms of the Artistic License 2.0.

=cut

__PACKAGE__;
