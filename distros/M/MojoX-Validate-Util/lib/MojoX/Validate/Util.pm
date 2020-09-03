package MojoX::Validate::Util;

use strict;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use Mojolicious::Validator;

use Moo;

use Params::Classify 'is_number';

use Types::Standard qw/Object/;

use URI::Find::Schemeless;

has url_finder =>
(
	default		=> sub{return URI::Find::Schemeless -> new(sub{my($url, $text) = @_; return $url})},
	is			=> 'ro',
	isa			=> Object,
	required	=> 0,
);

has validation =>
(
	is			=> 'rw',
	isa			=> Object,
	required	=> 0,
);

has validator =>
(
	default		=> sub{return Mojolicious::Validator -> new},
	is			=> 'ro',
	isa			=> Object,
	required	=> 0,
);

our $VERSION = '1.02';

# -----------------------------------------------

sub BUILD
{
	my($self) = @_;

	$self -> validation($self -> validator -> validation);
	$self -> add_dimension_check;
	$self -> add_url_check;

} # End of BUILD.

# -----------------------------------------------

sub add_dimension_check
{
	my($self) = @_;

	$self -> validator -> add_check
	(
		dimension => sub
		{
			my($validation, $topic, $value, @args) = @_;

			# Return 0 for success, 1 for error!
			# Warning: The test will fail if (length($value) == 0)!

			my($args) = join('|', @args);

			# We permit exactly 1 copy of one of the args.
			# This means you cannot omit the arg and default to something.

			return 1 if ($value !~ /^([0-9.]+)(\s*-\s*[0-9.]+)?\s*(?:$args){1,1}$/);

			my($one, $two)	= ($1, $2 || '');
			$two			= substr($two, 1) if (substr($two, 0, 1) eq '-');

			if (length($two) == 0)
			{
				return ! is_number($one);
			}
			else
			{
				return ! (is_number($one) && is_number($two) );
			}
		}
	);

} # End of add_dimension_check.

# -----------------------------------------------

sub add_url_check
{
	my($self) = @_;

	$self -> validator -> add_check
	(
		url => sub
		{
			my($validation, $topic, $value, @args)	= @_;
			my($count)								= $self -> url_finder -> find(\$value);

			# Return 0 for success, 1 for error!

			return ($count == 1) ? 0 : 1;
		}
	);

} # End of add_url_check.

# -----------------------------------------------
# Warning: Returns 1 for valid!

sub check_ascii_digits
{
	my($self, $params, $topic)	= @_;
	my($value)					= $$params{$topic};

	return ( (length($value) == 0) || ($value !~ /^[0-9]+$/) ) ? 0 : 1;

} # End of check_ascii_digits.

# -----------------------------------------------

sub check_dimension
{
	my($self, $params, $topic, $units) = @_;

	$self -> validation -> input($params);

	return (length($$params{$topic}) == 0)
			|| $self
			-> validation
			-> required($topic)
			-> dimension(@$units)
			-> is_valid;

} # End of check_dimension.

# -----------------------------------------------

sub check_equal_to
{
	my($self, $params, $topic, $expected) = @_;

	$self -> validation -> input($params);

	return $self
			-> validation
			-> required($topic)
			-> equal_to($expected)
			-> is_valid;

} # End of check_equal_to.

# -----------------------------------------------
# Warning: Returns 1 for valid!

sub check_key_exists
{
	my($self, $params, $topic) = @_;

	return exists($$params{$topic}) ? 1 : 0;

} # End of check_key_exists.

# -----------------------------------------------

sub check_member
{
	my($self, $params, $topic, $set) = @_;

	$self -> validation -> input($params);

	return $self
			-> validation
			-> required($topic)
			-> in(@$set)
			-> is_valid;

} # End of check_member.

# -----------------------------------------------
# Warning: Returns 1 for valid!

sub check_number
{
	my($self, $params, $topic, $expected) = @_;

	return $$params{$topic} == $expected ? 1 : 0;

} # End of check_number.

# -----------------------------------------------

sub check_optional
{
	my($self, $params, $topic) = @_;

	$self -> validation -> input($params);

	return $self
			-> validation
			-> optional($topic)
			-> is_valid;

} # End of check_optional.

# -----------------------------------------------

sub check_required
{
	my($self, $params, $topic) = @_;

	$self -> validation -> input($params);

	return $self
			-> validation
			-> required($topic)
			-> is_valid;

} # End of check_required.

# -----------------------------------------------

sub check_url
{
	my($self, $params, $topic) = @_;

	$self -> validation -> input($params);

	return (length($$params{$topic}) == 0)
			|| $self
			-> validation
			-> required($topic)
			-> url
			-> is_valid;

} # End of check_url.

# -----------------------------------------------

1;

=pod

=head1 NAME

C<MojoX::Validate::Util> - A very convenient wrapper around Mojolicious::Validator

=head1 Synopsis

This program ships as scripts/synopsis.pl.

	#!/usr/bin/env perl
	#
	# This is a copy of t/01.range.t, without the Test::More parts.

	use strict;
	use warnings;

	use MojoX::Validate::Util;

	# ------------------------------------------------

	my(%count)		= (fail => 0, pass => 0, total => 0);
	my($checker)	= MojoX::Validate::Util -> new;

	$checker -> add_dimension_check;

	my(@data) =
	(
		{height => ''},          # Pass.
		{height => '1'},         # Fail. No unit.
		{height => '1cm'},       # Pass.
		{height => '1 cm'},      # Pass.
		{height => '1m'},        # Pass.
		{height	=> '40-70.5cm'}, # Pass.
		{height	=> '1.5 -2m'},   # Pass.
		{height => 'z1'},        # Fail. Not numeric.
	);

	my($expected);
	my($params);

	for my $i (0 .. $#data)
	{
		$count{total}++;

		$params   = $data[$i];
		$expected = ( ($i == 1) || ($i == $#data) ) ? 0 : 1;

		$count{fail}++ if ($expected == 0);

		$count{pass}++ if ($checker -> check_dimension($params, 'height', ['cm', 'm']) == 1);
	}

	print "Test counts: \n", join("\n", map{"$_: $count{$_}"} sort keys %count), "\n";

This is the printout of synopsis.pl:

	Test counts:
	fail: 2
	pass: 6
	total: 8

See also scripts/demo.pl and t/*.t.

=head1 Description

C<MojoX::Validate::Util> is a wrapper around L<Mojolicious::Validator> which
provides a suite of convenience methods for validation.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html>
for help on unpacking and installing distros.

=head1 Installation

Install C<MojoX::Validate::Util> as you would any C<Perl> module:

Run:

	cpanm MojoX::Validate::Util

or run:

	sudo cpan Text::Balanced::Marpa

or unpack the distro, and then run:

	perl Makefile.PL
	make (or dmake or nmake)
	make test
	make install

=head1 Constructor and Initialization

C<new()> is called as C<< my($parser) = MojoX::Validate::Util -> new >>.

It returns a new object of type C<MojoX::Validate::Util>.

C<new()> does not take any parameters.

=head1 Methods

=head2 add_dimension_check()

Called in BEGIN(). The check itself is called C<dimension>, and it is used by calling
L</check_dimension($params, $topic, $units)>.

=head2 add_url_check()

Called in BEGIN(). The check itself is called C<url>, and it is used by calling
L</check_url($params, $topic)>.

This method uses L<URI::Find::Schemeless>.

=head2 check_ascii_digits($params, $topic)

This test uses 2 steps:

=over 4

=item o The length of $$params{$topic} must be > 0, and

=item o All digits in $$params{$topic} must be in the set [0-9]

=back

Parameters:

=over 4

=item o $params => A hashref

E.g.: $params = {age => $value, ...}.

=item o $topic => The name of the parameter being tested

E.g.: $topic = 'age'.

=back

Return value: Integer (0 or 1):

=over 4

=item o 0 => Invalid

=item o 1 => Valid

=back

See also L</check_equal_to($params, $topic, $other_topic)> and
L</check_number($params, $topic, $expected)>.

Note: This method uses neither L<Mojolicious::Validator> nor L<Mojolicious::Validator::Validation>.

=head2 check_dimension($params, $topic, $units)

Parameters:

=over 4

=item o $params => A hashref

E.g.: $params = {height => $value, ...}.

=item o $topic => The name of the parameter being tested

E.g.: $topic = 'height'.

=item o $value => A string containing a floating point number followed by one of the abbreviations

Or, the string can contain 2 floating point numbers separated by a hyphen, followed by one of the
abbreviations.

Spaces can be used liberally within the string, but of course not within the numbers.

So the code tests $$params{$topic} = $value.

=item o $units => An arrayref of strings of unit names or abbreviations

E.g.: $units = ['cm', 'm'].

=back

Return value: Integer (0 or 1) as returned by L<Mojolicious::Validator::Validation#is_valid>:

=over 4

=item o 0 => Invalid

=item o 1 => Valid

=back

For some non-undef $topic, $value and $units, here are some sample values for the hashref
and the corresponding return values (using $units = ['cm', 'm']):

=over 4

=item o {height => ''}: returns 1 (sic)

=item o {height => '1'}: returns 0

=item o {height => '1cm'}: returns 1

=item o {height => '1 cm'}: returns 1

=item o {height => '1m'}: returns 1

=item o {height => '40-70.5cm'}: returns 1

=item o {height => '1.5 -2 m'}: returns 1

=back

=head2 check_equal_to($params, $topic, $other_topic)

This test uses B<eq>. For a test using B<==>, see L</check_number($params, $topic, $other_topic)>.

Parameters:

=over 4

=item o $params => A hashref

E.g.: $params = {password => $value_1, confirm_password => $value_2, ...}.

=item o $topic => The name of the parameter being tested

E.g.: $topic = 'password'.

=item o $other_topic => The name of the other key within $params whose value should match $value_1

E.g.: $other_topic = 'confirm_password'.

So the code tests (using B<eq>) $$params{$topic} = $value_1 with $$params{$other_topic} = $value_2.

=back

Return value: Integer (0 or 1) as returned by L<Mojolicious::Validator::Validation#is_valid>.

=over 4

=item o 0 => Invalid

=item o 1 => Valid

=back

See also L</check_ascii_digits($params, $topic)> and L</check_number($params, $topic, $expected)>.

=head2 check_key_exists($params, $topic)

Parameters:

=over 4

=item o $params => A hashref

E.g.: $params = {email_address => $value, ...}.

=item o $topic => The name of the parameter being tested

E.g.: $topic = 'email_address'.

=back

Return value: Integer (0 or 1):

=over 4

=item o 0 => Invalid

=item o 1 => Valid

=back

For some non-undef $topic, here are some sample values for $params and the corresponding
return values (using $topic = 'x'):

=over 4

=item o {}: returns 0

=item o {x => undef}: returns 1

=item o {x => ''}: returns 1

=item o {x => '0'}: returns 1

=item o {x => 0}: returns 1

=item o {x => 'yz'}: returns 1

=back

This method uses neither L<Mojolicious::Validator> nor L<Mojolicious::Validator::Validation>.

=head2 check_member($params, $topic, $set)

Parameters:

=over 4

=item o $params => A hashref

E.g.: $params = {love_popup_ads => $value, ...}.

=item o $topic => The name of the parameter being tested

E.g.: $topic = 'love_popup_ads'.

=item o $set => An arrayref of strings

E.g.: ['Yes', B<'No'>].

=back

Return value: Integer (0 or 1) as returned by L<Mojolicious::Validator::Validation#is_valid>.

=over 4

=item o 0 => Invalid

=item o 1 => Valid

=back

=head2 check_number($params, $topic, $expected)

This test uses B<==>. For a test using B<eq>, see L</check_equal_to($params, $topic, $other_topic)>.

Parameters:

=over 4

=item o $params => A hashref

E.g.: $params = {age => $value, ...}.

=item o $topic => The name of the parameter being tested

E.g.: $topic = 'age'.

=item o $expected => An integer

E.g.: 99.

=back

Return value: Integer (0 or 1):

=over 4

=item o 0 => Invalid

=item o 1 => Valid

=back

For some non-undef $topic, $value and $expected, here are some sample values for $value and
$expected, and the corresponding return values:

=over 4

=item o $value == 99 and $expected != 99: returns 0

=item o $value == 99 and $expected == 99: returns 1

=back

See also L</check_ascii_digits($params, $topic)> and
L</check_equal_to($params, $topic, $other_topic)>.

Note: This method uses neither L<Mojolicious::Validator> nor L<Mojolicious::Validator::Validation>.

=head2 check_optional($params, $topic)

Parameters:

=over 4

=item o $params => A hashref

E.g.: $params = {email_address => $value, ...}.

=item o $topic => The name of the parameter being tested

E.g.: $topic = 'email_address'.

=back

Return value: Integer (0 or 1) as returned by L<Mojolicious::Validator::Validation#is_valid>:

=over 4

=item o 0 => Invalid

=item o 1 => Valid

=back

For some non-undef $topic, here are some sample values for $params and the corresponding
return values (using $topic = 'x'):

=over 4

=item o {}: returns 0

=item o {x => undef}: returns 0

=item o {x => ''}: returns 0 (because the length is 0)

=item o {x => '0'}: returns 1

=item o {x => 0}: returns 1

=item o {x => 'yz'}: returns 1

=back

See also L</check_required($params, $topic)>.

See scripts/demo.pl and t/03.email.address.t.

=head2 check_required($params, $topic)

Parameters:

=over 4

=item o $params => A hashref

E.g.: $params = {email_address => $value, ...}.

=item o $topic => The name of the parameter being tested

E.g.: $topic = 'email_address'.

=back

Return value: Integer (0 or 1) as returned by L<Mojolicious::Validator::Validation#is_valid>:

=over 4

=item o 0 => Invalid

=item o 1 => Valid

=back

For some non-undef $topic, here are some sample values for $params and the corresponding
return values (using $topic = 'x'):

=over 4

=item o {}: returns 0

=item o {x => undef}: returns 0

=item o {x => ''}: returns 0 (because the length is 0)

=item o {x => '0'}: returns 1

=item o {x => 0}: returns 1

=item o {x => 'yz'}: returns 1

=back

See also L</check_optional($params, $topic)>.

See scripts/demo.pl and t/03.email.address.t.

=head2 check_url($params, $topic)

Parameters:

=over 4

=item o $params => A hashref

E.g.: $params = {homepage => $value, ...}.

=item o $topic => The name of the parameter being tested

E.g.: $topic = 'homepage'.

=back

Return value: Integer (0 or 1) as returned by L<Mojolicious::Validator::Validation#is_valid>:

=over 4

=item o 0 => Invalid

=item o 1 => Valid

=back

For some non-undef $topic, here are some sample values for $params and the corresponding
return values (using $topic = 'homepage'):

=over 4

=item o {homepage => 'localhost'}: returns 0.

=item o {homepage => 'savage.net.au'}: returns 1.

=item o {homepage => 'http://savage.net.au'}: returns 1.

=item o {homepage => 'https://savage.net.au'}: returns 1.

=back

=head2 new()

=head2 url_finder()

Returns an object of type L<URI::Find::Schemeless>.

=head2 validation()

Returns an object of type L<Mojolicious::Validator::Validation>

=head2 validator()

Returns an object of type L<Mojolicious::Validator>

=head1 FAQ

=head2 Why did you prefix all the method names with 'check_'?

In order to clarify which methods are part of this module and which are within
L<Mojolicious::Validator> or L<Mojolicious::Validator::Validation>.

=head2 Why provide both check_optional() and check_required()?

Calling either C<required()> or C<optional()> within L<Mojolicious::Validator::Validation>, and then
calling C<is_valid()> can return the same value, but the difference becomes apparent after (then)
calling methods such as C<failed()>, C<has_error()>, C<output()> and C<passed()>.

This will be much clearer after you study the output of scripts/demo.pl and t/03.email.address.t.

=head2 Why did you not make any provision for Mojolicious-style filters?

I will add them if there is any interest, but ATM I take the attitude: Release early and release
often.

=head2 Why did you not use the module C<boolean>?

I was tempted, but it would mean 2 extra, albeit small, complexities:

=over 4

=item o Another pre-requisite

And that conflicts with the minimalistic philosophy of Mojolicious itself.

=item o Handling the types of all the values returned from the Mojolicious code

=back

=head1 See Also

L<Mojolicious::Validator>

L<Mojolicious::Validator::Validation>

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Repository

L<https://github.com/ronsavage/MojoX-Validate-Util>

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=MojoX::Validate::Util>.

=head1 Author

L<MojoX::Validate::Util> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2017.

My homepage: L<http://savage.net.au/>.

=head1 Copyright and Licence

Australian copyright (c) 2017, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Perl License, a copy of which is available at:
	http://dev.perl.org/licenses/.

=cut
