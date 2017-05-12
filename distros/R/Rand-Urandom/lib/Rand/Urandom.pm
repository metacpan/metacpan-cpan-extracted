package Rand::Urandom;
use strict;
use warnings;
use Config;
use POSIX qw(EINTR ENOSYS);
use Exporter qw(import);

our @EXPORT_OK = qw(perl_rand rand_bytes);
our $VERSION = '0.03';

## no critic (Subroutines::ProhibitSubroutinePrototypes)
sub use_urandom(;$) {
	my $max = shift || 1;

	my $buf = rand_bytes(8);
	my $n;
	if($Config{'use64bitint'}) {
		$n = unpack('Q', $buf);
	}else {
		# just treat it as 2 longs for now...
		$n = unpack('LL', $buf);
	}
	return $n if ($max == 2**64);

	$max *= $n / 2**64;
	return $max;
}

my $syscall;
my $bsd;
sub try_syscall {
	my $num = shift;

	if(!defined $syscall) {
		if($Config{'osname'} =~ m/openbsd/i && $Config{'archname'} =~ m/amd64/) {
			$syscall = 7;
			$bsd = 1;
		}elsif ($Config{'osname'} =~ m/linux/) {
			$syscall = $Config{'archname'} =~ m/x86_64/ ? 318 : 355;
		}else {
			$syscall = -1;
		}
	}
	return if($syscall < 0);

	my $ret;
	my $buf   = ' ' x $num;
	my $tries = 0;
	local $! = undef;
	do {
		$ret = syscall($syscall, $buf, $num, 0);
		if ($! == ENOSYS) {
			return;
		}

		if ($ret != ($bsd ? 0 : $num)) {
			warn "Rand::Urandom: huh, getrandom() returned $ret... trying again";
			$ret = -1;
			$!   = EINTR;
		}

		if ($tries++ > 100) {
			warn 'Rand::Urandom: getrandom() looped lots, falling back';
			return;
		}
	} while ($ret == -1 && $! == EINTR);

	# didn't fill in the buffer? fallback
	return if($buf =~ m/^ +$/);

	return $buf;
}

sub rand_bytes {
	my $num = shift;

	my $buf;
	$buf = try_syscall($num) if(!defined $syscall || $syscall > 0);

	if (!$buf) {
		local $! = undef;
		my $file = -r '/dev/arandom' ? '/dev/arandom' : '/dev/urandom';
		open(my $fh, '<:raw', $file) || die "Rand::Urandom: Can't open $file: $!";

		my $got = read($fh, $buf, $num);
		if ($got == 0 || $got != $num) {
			die "Rand::Urandom: failed to read from $file: $!";
		}
		close($fh) || die "Rand::Urandom: close failed: $!";
	}
	return $buf;
}

my $orig_rand;
sub perl_rand {
	if ($^V lt 'v5.16') {
		die 'Rand::Urandom: sorry, you cant access the original rand function on perls older than 5.16';
	}

	goto &$orig_rand;
}

sub BEGIN {
	no warnings 'redefine';
	no warnings 'prototype';
	$orig_rand           = \&CORE::rand;
	*CORE::GLOBAL::rand = \&use_urandom;
}


1;
__END__

=head1 NAME

Rand::Urandom - replaces rand() with /dev/urandom

=head1 SYNOPSIS

  use Rand::Urandom();

  # now grabs 8 bytes from /dev/urandom
  # works just like rand, that is returns a random fractional number >= 0 and
  # less than $max
  my $r = rand($max);

  # or
  use Rand::Urandom qw(perl_rand rand_bytes);

  # rand() still overloaded, but we want to use the original rand
  my $r = perl_rand();

  # returns $int random bytes
  my $r = rand_bytes($int);

=head1 DESCRIPTION

http://sockpuppet.org/blog/2014/02/25/safely-generate-random-numbers/

Perl's built-in rand has a few problems:

=over

=item *
the state is inherited across fork(), meaning its real easy to generate/use the
same "random" number twice. Especially when using mod_perl. Yes I've been
bitten by this before.

=item *
per perldoc "rand()" is not cryptographically secure. You should not rely on it in security-sensitive situations."

=item *
seeding is hard to get right

=back

By default it uses the getentropy() (only available in > Linux 3.17) and falls
back to /dev/arandom then /dev/urandom. Otherwise it dies.

This means it should "DoTheRightThing" on most unix based systems, including,
OpenBSD, FreesBSD, Mac OSX, Linux, blah blah.

You: I<Yeah, Ok I see you're point, but do I actually want to use this?>

Me: B<Maybe!>, It could also be a really bad idea!

=head2 SUBROUTINES

=over

=item *
perl_rand() - the original rand(), only works on perls newer or equal to 5.16

=item *
rand_bytes($int) - returns $int rand bytes()

=back

=head2 EXPORT

None by default. perl_rand(), rand_bytes();

=head1 SEE ALSO

https://github.com/badalex/Rand-Urandom

=head1 AUTHOR

Alex Hunsaker, E<lt>badalex@gmail.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Alex Hunsaker

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
