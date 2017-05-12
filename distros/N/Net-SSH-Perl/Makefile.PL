# $Id: Makefile.PL,v 1.30 2008/10/02 18:53:25 turnstep Exp $

use strict;
use 5.006;
use ExtUtils::MakeMaker qw(prompt WriteMakefile);

my %prereq = (
        'IO::Socket'        => 0,
        'File::Spec'        => 0,
        'File::HomeDir'     => 0,
);

my %SSH_PREREQ = (
    1 => {
        'Digest::MD5'       => 0,
        'String::CRC32'     => '1.2',
        'Math::GMP'         => '1.04',
        'Scalar::Util'      => 0,
        'Crypt::IDEA'       => 0,
    },

    2 => {
        'CryptX'            => '0.032',
        'Crypt::Curve25519' => '0.05',
    },
);

$SSH_PREREQ{3} = { map %{$SSH_PREREQ{$_}}, 1..2 };

print<<MSG;
This is Net::SSH::Perl.

As of version 1.00, Net::SSH::Perl supports both the SSH1 and
SSH2 protocols natively. The two protocols have different
module prerequisitives, so you need to decide which protocol(s)
you plan to use. If you use one or the other, only those modules
for your chosen protocol will be installed; if you choose both,
all of the supporting modules will be installed. Please choose
the protocols you'd like to use from the following list ("Both"
is the default).

MSG

printf "    [%d] SSH%d\n", $_, $_ for 1..2;
printf "    [3] Both SSH1 and SSH2\n";

my $p = prompt("\nWhich protocol(s) do you plan to use?", 3);
print "\n";

@prereq{keys %{$SSH_PREREQ{$p}}} = values %{$SSH_PREREQ{$p}};

print "Checking for optional modules\n\n";

unless (have_module('Digest::BubbleBabble', 0.01)) {
    print<<MSG, "\n";
Digest::BubbleBabble is required if you want to generate bubble babble
key fingerprints with pssh-keygen.
MSG

    if (read_yes_or_no("Would you like to install it? (y/n)", "y")) {
        $prereq{'Digest::BubbleBabble'} = '0.01';
    }
    print "\n";
}

WriteMakefile(
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    NAME         => 'Net::SSH::Perl',
    DISTNAME     => 'Net-SSH-Perl',
    VERSION_FROM => 'lib/Net/SSH/Perl.pm',
    PREREQ_PM    => \%prereq,
    AUTHOR       => 'David Robins <dbrobins@cpan.org>',
    ABSTRACT     => 'Perl client interface to SSH',
    NO_META      => 1,
);

sub read_yes_or_no {
    my($prompt, $def) = @_;
    my $ans = prompt($prompt, $def);
    $ans =~ /^y/i;
}

sub have_module {
    my($name, $ver) = @_;
    eval("use $name" . ($ver ? " $ver;" : ";"));
    !$@;
}
