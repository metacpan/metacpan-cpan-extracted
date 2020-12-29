package Sys::Linux::KernelVersion;

# ABSTRACT: Gives tools for checking the current running linux kernel version

use v5.8.3;
use strict;
use warnings;

our $VERSION = '0.101';
use Exporter 'import';

our @EXPORT_OK = qw/is_linux_kernel get_kernel_version is_at_least_kernel_version is_development_kernel stringify_kernel_version/;

# not a complicated check, probably doesn't need to exist either but sure
sub is_linux_kernel { $^O eq 'linux' }

my $linux_version;

sub get_kernel_version {
  # cache the result, it shouldn't ever change while we run.  if it does TS for you.
  return $linux_version if $linux_version;

  open(my $fh, "<", "/proc/version") or die "Couldn't open /proc/version : $!";

  my $line = <$fh>;

  close($fh) or die "Couldn't close the handle for /proc/version $!";

  $linux_version = _parse_version_line($line);
}

sub _parse_version_spec {
  my $spec = shift;
  if ($spec =~ /^(\d+)\.(\d+)\.(\d+)(-\S+)?$/) {
    my ($major, $minor, $revision, $subpart) = ($1, $2, $3, $4);

    $linux_version = {major => $major, minor => $minor, revision => $revision, subpart => $subpart, subparts => [split /-/, $subpart||""]};
  } else {
    die "Invalid version spec";
  }
}

# TODO parse the compiler and other version info too? I'm not interested in it and I don't know if they're stable formatting wise
sub _parse_version_line {
  my $line = shift;

  if ($line =~ /^Linux version (\S+) .*$/) {
    return _parse_version_spec($1);
  } else {
    die "Couldn't parse [$line]";
  }
}

sub _cmp_version {
  my ($left, $right) = @_;

  unless (defined($left->{major})  && defined($left->{minor})  && defined($left->{revision}) &&
          defined($right->{major}) && defined($right->{minor}) && defined($right->{revision})) {
    die "Invalid version spec provided";
  }

  return $left->{major} <=> $right->{major} || $left->{minor} <=> $right->{minor} || $left->{revision} <=> $right->{revision};
}

sub is_at_least_kernel_version {
  my $input = shift; # just a string as input

  my $running_version = get_version();
  my $input_version = _parse_version($input);

  my $cmp = _cmp_version($running_version, $input_version);

  return $cmp != -1;
}

# Is this a development kernel
sub is_development_kernel {
  my $running_version = get_kernel_version();

  return _is_development($running_version);
}

sub _is_development {
  my $version = shift;

  my $last_dev_rev = _parse_version_spec("2.5.9999"); # last one where the even/odd minor number was a thing

  if (_cmp_version($last_dev_rev, $version) != -1) {
    my $minor = $version->{minor};

    return 1 if ($minor % 2);
    return 0;
  } else {
    # There's no longer any proper development series like there used to be, but there are -rcN kernels during development, these should count
    my $subpart = $version->{subpart} || "";
    
    return ($subpart =~ /-rc\d/);
  }
}

sub stringify_kernel_version {
  my $version = shift;

  sprintf "%d.%d.%d%s", $version->{major}, $version->{minor}, $version->{revision}, $version->{subpart}||"";
}

1;

__END__
=head1 NAME

Sys::Linux::KernelVersion

=head1 DESCRIPTION

=begin html

<a href="https://github.com/simcop2387/sys-linux-kernel-version/actions?query=workflow%3A%22CI+-+Distzilla%22"><img src="https://github.com/simcop2387/sys-linux-kernelversion/workflows/CI%20-%20Distzilla/badge.svg"></a>

=end html

This is a simple module that helps look up the particular Linux kernel version number in a safe and otherwise portable way.  It's intended for doing configure_requires checks and also during test suites that can't test certain features on older kernels.

=head1 EXPORTED FUNCTIONS

=over

=item C<get_kernel_version>

Returns a hashref containing the parsed kernel version

The hashref will always contain the following keys: major, minor, revision

It may contain: subpart, subparts

The subpart key will contain anything after the revision that was included as part of the version of the kernel.  There is no standard to how these must be formatted other than starting with a C<->. Most commonly you'll see things like C<-10>, C<-generic>, C<-amd64>, or even C<-rc4>, or a combination of all of those.  Usually a bare number like C<-10> will mean a build number, or a distro patch number.  C<-generic> is what Ubuntu likes to use for marking what kind of kernel it is, i.e. the generic configuration, a hardware enablement kernel, or a realtime kernel.  A sometimes present C<-amd64> would indicate that this is a kernel for an amd64 architecture.  None of these subparts are actually standard across vendors and can't be depended on to be present, or in any particular order.

=item C<is_linux_kernel>

Just a simple check that we actually appear to be running on a linux kernel, or at least something compatible enough to call itself linux.

=item C<is_at_least_kernel_version>

This takes a string as it's only parameter, to give a minimum version number.

    use Sys::Linux::KernelVersion qw/is_at_least_kernel_version/;

    die "Too old!" unless is_at_least_kernel_version("12.56.42");

This is useful for segmenting off tests or failing a build early during module configuration if there's not at least a minimum kernel version running.

If putting this into a test for a minimum kernel version running, I'd recommend also providing a way to override the check with an Environment Variable, so that build servers don't have to be running the same kernels as development or production release machines in all environments.  This would give a way for users to acknowledge that the check is incorrect/insufficient for their environments and checking that the versions in use is their responsibility.

I would not use this to choose what features should be built or not-built in the module, instead that should happen at runtime so that features match the running kernel and not the building kernel.

=item C<is_development_kernel>

Check if the currently running kernel is a development series kernel.

=back

=head1 BUGS

Report any issues on the public github bugtracker.

=head1 AUTHOR

Ryan Voots <simcop@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Ryan Voots.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

