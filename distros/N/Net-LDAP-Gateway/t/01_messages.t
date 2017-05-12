#!/usr/bin/perl

use strict;
use warnings;

use Net::LDAP::Gateway qw(ldap_shift_message
			  ldap_pack_message_ref
			  ldap_peek_message);

use Test::More;

our $message;
do "t/messages.pl";

plan tests => @$message * 5;

my $unberize = 0;


sub unber {
    my $data = shift;
    open my $tmp, '>', 't/message.bin'
	or die "unable to create t/message.bin'";
    binmode $tmp;
    print $tmp $data;
    close $tmp;
    my $out = sprintf("[%d bytes]\n%s",
		      length $data,
		      scalar qx(unber t/message.bin));
    unlink 't/message.bin';
    return $out;
}

sub diag_error {
    diag "error: $@" if $@
}

use Data::Dumper;
# print STDERR Dumper $request;

for my $msg (@$message) {
    my ($msgid, $op) = @{$msg->{perl}};
    my $text_op = $msg->{asn1}[0];
    my $packed = $msg->{packed};

#    my $unber1 = unber $packed;
#    diag "original:\n$unber1\n";
    my @peek = eval { ldap_peek_message($packed) };
    is_deeply(\@peek, [length $packed, $msgid, $op, grep defined, $msg->{peek}],
	      "peek $text_op $msgid")
	or do {
	    if ($unberize) {
		my $unber1 = unber $packed;
		diag "original:\n$unber1\n";
	    }
	};

    diag_error;

    my $rubbish = 'x' x rand 4;
    my $buffer = $packed . $rubbish;
    my @unpacked = eval { ldap_shift_message($buffer) };
    is_deeply(\@unpacked, $msg->{perl}, "unpacked $text_op $msgid")
	or do {
	    if ($unberize) {
		my $unber1 = unber $packed;
		diag "original:\n$unber1\n";
	    }
	    diag sprintf("expected:\n%s\ngot:\n%s\n",
			 Dumper($msg->{perl}), Dumper(\@unpacked));
	};
    diag_error;
    is ($buffer, $rubbish, "rubbish remains $text_op $msgid");
#    use Data::Dumper;
#    print Dumper \@unpacked;
    my $repacked = eval { ldap_pack_message_ref(@unpacked) };
    is ($repacked, $packed, "repacked $text_op $msgid")
	or do {
	    if ($unberize) {
		my $unber1 = unber $packed;
		my $unber2 = unber $repacked;
		diag "original:\n$unber1\ngenerated:\n$unber2\n";
	    }
	};
    diag_error;
    my @unpacked2 = eval { ldap_shift_message($repacked) };
    is_deeply(\@unpacked2, \@unpacked, "repacked unpacked $text_op $msgid");
    diag_error;

}
