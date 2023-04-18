#!/usr/bin/perl -w
#
# 2023-04-17 Otmar Lendl <lendl@cert.at>
#
# Cleaning up behind CipherMail 
#
#  - Duplicate From: Subject: and To: headers are removed
#  - Subject tags are reset based on the X-Djigzo headers

use strict;
use Email::Simple;
use Encode qw(encode decode);

undef $/;

binmode STDIN;
binmode STDOUT;

my $text = <STDIN>;
my $email = Email::Simple->new($text);
my $header = $email->header_obj;
my %header_present = ();
map {$header_present{$_} = 1} $header->header_names();

#
# Handle Duplicates
#

foreach my $field (qw/ From Subject To /) {
	my @values  = $header->header_raw($field);
	if ($#values == 0) {
#		print STDERR "skipping $field: only one header line\n";
		next;
	}
#	print STDERR "$field: " , join('|', @values), "\n";
	if ($#values == 1) {  # two lines?
		if ($values[0] eq $values[1]) {
			$header->header_raw_set($field, $values[0]);
#			print STDERR "removed duplicate $field\n";
		}
	}
}

#
# sanitize subject
#
my $subject = $header->header_raw("Subject");
my $s = decode("MIME-Header",$subject);

#print STDERR "SUB: $subject | $s\n";

if ($s =~ /\[signed\]/) { # really signed?
#	print STDERR "Checking [signed] Tag\n";

	if ($header_present{'X-Djigzo-Info-PGP-Signed'} and 
		$header_present{'X-Djigzo-Info-PGP-Signature-Valid'} and
		($header->header_raw('X-Djigzo-Info-PGP-Signature-Valid') eq 'True')) {
#			print STDERR "Found X-Djigzo-Info-PGP-Signature-Valid\n";
	} elsif ($header_present{'X-Djigzo-Info-SMIME-Signed'} and 
		$header_present{'X-Djigzo-Info-Signer-Verified-0-0'} and
		($header->header_raw('X-Djigzo-Info-Signer-Verified-0-0') eq 'True')) {
#			print STDERR "Found X-Djigzo-Info-SMIME-Signed\n";
	} else {
#		print STDERR "Removing [signed] Tag\n";
		$s =~ s/\[signed\]\s*//g;	# remove tag;
		$s =~ s/\s+$//;
		$header->header_raw_set('Subject', $s);
	}

}


if ($s =~ /\[decrypted\]/) { # really decrypted?
#	print STDERR "Checking [decrypted] Tag\n";

	if ($header_present{'X-Djigzo-Info-PGP-Encrypted'}) {
		1;

# need info how smime encryption looks like
#elsif ($header_present{'X-Djigzo-Info-SMIME-Signed'} and 
#		$header_present{'X-Djigzo-Info-Signer-Verified-0-0'} and
#		($header->header_raw('X-Djigzo-Info-Signer-Verified-0-0') eq 'True')) {
#			print STDERR "Found X-Djigzo-Info-SMIME-Signed\n";

	} else {
#		print STDERR "Removing [decrypted] Tag\n";
		$s =~ s/\[decrypted\]\s*//g;	# remove tag;
		$s =~ s/\s+$//;
		$header->header_raw_set('Subject', $s);
	}
}

#
# write out the mail again
#
print $email->as_string;
