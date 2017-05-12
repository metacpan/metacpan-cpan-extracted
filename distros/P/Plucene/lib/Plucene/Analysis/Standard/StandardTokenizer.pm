package Plucene::Analysis::Standard::StandardTokenizer;

=head1 NAME 

Plucene::Analysis::Standard::StandardTokenizer - standard tokenizer

=head1 SYNOPSIS

	# isa Plucene::Analysis::CharTokenizer

=head1 DESCRIPTION

This is the standard tokenizer.

This should be a good tokenizer for most European-language documents.

=head1 METHODS

=cut

use strict;
use warnings;

use base 'Plucene::Analysis::CharTokenizer';

# Don't blame me, blame the Plucene people!
my $alpha      = qr/\p{IsAlpha}+/;
my $apostrophe = qr/$alpha('$alpha)+/;
my $acronym    = qr/$alpha\.($alpha\.)+/;
my $company    = qr/$alpha(&|\@)$alpha/;
my $hostname   = qr/\w+(\.\w+)+/;
my $email      = qr/\w+\@$hostname/;
my $p          = qr/[_\/.,-]/;
my $hasdigit   = qr/\w*\d\w*/;
my $num        = qr/\w+$p$hasdigit|$hasdigit$p\w+
                   |\w+($p$hasdigit$p\w+)+
                   |$hasdigit($p\w+$p$hasdigit)+
                   |\w+$p$hasdigit($p\w+$p$hasdigit)+
                   |$hasdigit$p\w+($p$hasdigit$p\w+)+/x;

=head2 token_re

The regular expression for tokenising.

=cut

sub token_re {
	qr/
        $apostrophe | $acronym | $company | $hostname | $email | $num
        | \w+
    /x;
}

=head2 normalize

Remove 's and .

=cut

sub normalize {
	my $class = shift;

	# These are in the StandardFilter in Java, but Perl is not Java.
	# Thankfully.
	local $_ = shift;
	if (/$apostrophe/) { s/'s//; }
	if (/$company/)    { s/\.//g; }
	return $_;
}

1;
