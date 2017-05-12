package Sys::Mlockall;

use 5.006000;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Sys::Mlockall ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = (
  'all' => [ qw(MCL_FUTURE MCL_CURRENT mlockall munlockall) ]
);

our @EXPORT_OK = (@{$EXPORT_TAGS{'all'}});

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Sys::Mlockall', $VERSION);

# Preloaded methods go here.

1;
__END__

=head1 NAME

Sys::Mlockall - Prevent this process's memory from being placed in swap.

=head1 SYNOPSIS

use Sys::Mlockall qw(:all);

if(mlockall(MCL_CURRENT | MCL_FUTURE) != 0) {
  die "Failed to lock RAM: $!";
}

[memory will not be swapped from here on out]

=head1 DESCRIPTION

This module provides a quick-and-dirty interface to the mlockall() and
munlockall() system calls. mlockall() can be used to prevent your process's
memory from being placed in swap, which can be useful for scripts that
deal with sensitive information (passwords / RSA keys / stardrive plans / etc).

=head1 EXPORTS

Please see L<mlockall(2)> for documentation on these. Their
calling convention and return value are exactly the same, and C<errno>
will, by perl convention, be stored in C<$!>.

=over

=item mlockall()

=item munlockall()

=item MCL_CURRENT

=item MCL_FUTURE

=back

=head1 NOTES

By default, linux systems have the resource limit RLIMIT_MAXLOCK set to
64kb, which is insufficient for running perl scripts. The unit tests
require root permissions to boost that limit to 32MB; in production, you
may want to use the "ulimit" commanad, or add a rule to
/etc/security/limits.conf (or /etc/security/limits.d/ if supported).

=head1 LICENSE

You may use this module under the same terms as perl itself.

=head1 MAINTAINER

Tyler MacDonald <japh@crackerjack.net>

=cut



