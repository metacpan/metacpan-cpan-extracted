package Local::TrapExit;

use 5.006;
use strict;
use warnings;

our $VERSION = 'v0.0.0_01';

my $exit_code;

my $exit_trap = sub {
    $exit_code = scalar(@_) ? ( $_[0] || 0 ) : 0;

    CORE::exit(0);
};

BEGIN {
    *CORE::GLOBAL::exit = sub { $exit_trap->(@_); };
}

sub exit_code {
    return $exit_code;
}

1;
__END__

=pod

=head1 NAME

Local::TrapExit - intercept calls to C<exit>.

=head1 SYNOPSIS
  
 use Local::TrapExit;
  
=head1 DESCRIPTION

This is a quick and dirty, private module used by the L<Role::RunAlone>
test suite to intercept calls to C<exit(N)>, save the value it was called
with, and then pass the call on with the value always set to C<0> (zero)
regardless of what the original value was.

This allows test scripts to place various test conditions in their C<END>
block and report back to the test harness correctly while at the same time
being able to verify the exit status from the code under test.

The scripts in the C<t/no_pkg_modulinos> and C<t/pkg_modulinos> in this
distribution demostrate the technique.

=head1 SEE ALSO

All the test scripts in C<t/no_pkg_modulinos> and C<t/pkg_modulinos> in
the L<Role::RunAlone> distribution.

=head1 AUTHOR

Jim Bacon, C<< <boftx at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by Jim Bacon.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

