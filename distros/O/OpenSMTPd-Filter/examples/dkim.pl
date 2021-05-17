#!/usr/bin/perl
use v5.16;
use warnings;

use OpenSMTPd::Filter;

use OpenBSD::Unveil;
use OpenBSD::Pledge;
use Mail::DKIM::Verifier;

# This lets us see if there are other modules we may need to preload
unshift @INC, sub { warn "Attempted to load $_[1]"; return };

# Something tries to load /etc/hosts and possibly other things
# but it works fine if unveil says they don't exist.
unveil();
pledge(qw< inet rpath >) || die "Unable to pledge: $!";

my $debug = 1;

OpenSMTPd::Filter->new(
    debug => $debug,
    on    => { filter => { 'smtp-in' => {
        'data-line' => \&dkim_verifier,
        'commit'    => \&dkim_result,
    } } }
)->ready;

sub dkim_verifier {
    my ( $phase, $s, $line ) = @_;

    my $dkim = $s->{state}->{message}->{dkim_verifier} ||=
      Mail::DKIM::Verifier->new();

    if ( $line eq '.' ) {
        $dkim->CLOSE();
    }
    elsif ( $line =~ /^\.(.+)$/ ) {
        $dkim->PRINT("$1\015\012");
    }
    else {
        $dkim->PRINT("$line\015\012");
    }

    return $line;
}

sub dkim_result {
    my ( $phase, $s ) = @_;

    my $dkim   = $s->{state}->{message}->{dkim_verifier};
    my $result = $dkim->result;

    warn "DKIM Result: " . $dkim->result_detail . "\n" if $debug;

    return reject => '451 Temporary failure, please try again later.'
      if $result eq 'temperror';

    return disconnect => '550 DKIM check failed.'
      if $result eq 'fail';

    # We ignore other errors and let the mail through
    return 'proceed';
}
