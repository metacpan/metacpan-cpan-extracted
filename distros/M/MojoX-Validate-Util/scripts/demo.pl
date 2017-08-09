#!/usr/bin/env perl

use warnings;
use strict;

use Mojolicious;
use Mojolicious::Validator;
use Mojolicious::Validator::Validation;

# ------------------------------------------------

sub hashref2string
{
	my($hashref) = @_;
	$hashref ||= {};

	return '{' . join(', ', map{defined($$hashref{$_}) ? qq|$_ => "$$hashref{$_}"| : "$_ => undef"} sort keys %$hashref) . '}';

} # End of hashref2string.

# ------------------------------------------------

print "Mojolicious::VERSION: $Mojolicious::VERSION. \n";

# These topics are keys into the hashref within @data.

my(@topics)		= ('a', 'b', 'c', 'd', 'e', 'f');
my(@data)		=
(
	# This hashref deliberately does not contain the key 'a'.

	{b => undef, c => '', d => 0, e => 'e', f => 'x', x => 'x'},
);

my($errors);
my($output);
my($params);
my($validator, $validation);

for my $i (0 .. $#data)
{
	$params = $data[$i];

	print 'params:   ', hashref2string($params), ". \n";

	for my $topic (@topics)
	{
		for my $kind (qw/required optional/)
		{
			$validator	= Mojolicious::Validator -> new;
			$validation	= Mojolicious::Validator::Validation->new(validator => $validator);

			$validation -> input($params); # Not a required call with MojoX::Validate::Util.

			print "i: @{[$i + 1]}: topic: $topic. Using $kind(): \n";

			if ($topic =~ /[ef]/)
			{
				print "$topic == x:    ", $validation -> $kind($topic) -> equal_to('x') -> is_valid, ". \n";
			}
			else
			{
				print 'required:  ', $validation -> $kind($topic) -> is_valid, ". \n";
			}

			$errors	= $validation -> error($topic);
			$errors	= defined($errors) ? join(', ', @$errors) : '';
			$output	= $validation -> output;
			$output	= defined($output) ? hashref2string($output) : '';

			print 'has_error: ', defined($validation -> has_error) ? 1 : 0, ". \n";
			print "errors:    $errors. \n";
			print "output:    $output. \n";
			print 'failed:    ', join(', ', @{$validation -> failed}), ". \n";
			print 'passed:    ', join(', ', @{$validation -> passed}), ". \n";
			print '-' x 15, ". \n";
		}
	}
}

@data =
(
	{love_popup_ads => 'No'},
	{love_popup_ads => 'Nyet'},
);

my($topic)	= 'love_popup_ads';
my(@set)	= ('Yes', 'No');

my($infix);
my($result);

for my $i (0 .. $#data)
{
	$params = $data[$i];

	print 'params:     ', hashref2string($params), ". \n";

	$validator	= Mojolicious::Validator -> new;
	$validation	= Mojolicious::Validator::Validation->new(validator => $validator);

	$validation -> input($params); # Not a required call with MojoX::Validate::Util.

	$infix	= ($i == 0) ? 'is' : 'is not';
	$result = $validation -> required($topic) -> in(@set) -> is_valid ? 1 : 0;

	print "Membership: $result (meaning '$$params{love_popup_ads}' $infix in the set "
		. "@{[join(', ', map{qq|'$_'|} @set)]}). \n";
}

print "Finished. \n";
