package Proc::ChildError;

our $DATE = '2016-01-06'; # DATE
our $VERSION = '0.04'; # VERSION

use strict;
use warnings;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(explain_child_error);

sub explain_child_error {
    my $opts;
    if (ref($_[0]) eq 'HASH') {
        $opts = shift;
    } else {
        $opts = {};
    }

    my ($num, $str);
    if (defined $_[0]) {
        $num = $_[0];
        $str = $_[1];
    } else {
        $num = $?;
        $str = $!;
    }

    my $prefix = "";
    if (defined $opts->{prog}) {
        $prefix = "$opts->{prog} ";
    }

    if ($num == -1) {
        return "${prefix}failed to execute: ".($str ? "$str ":"")."($num)";
    } elsif ($num & 127) {
        return sprintf(
            "${prefix}died with signal %d, %s coredump",
            ($num & 127),
            (($num & 128) ? 'with' : 'without'));
    } else {
        return sprintf("${prefix}exited with code %d", $num >> 8);
    }
}

1;
# ABSTRACT: Explain process child error

__END__

=pod

=encoding UTF-8

=head1 NAME

Proc::ChildError - Explain process child error

=head1 VERSION

This document describes version 0.04 of Proc::ChildError (from Perl distribution Proc-ChildError), released on 2016-01-06.

=head1 FUNCTIONS

=head2 explain_child_error([\%opts, ]$child_error, $os_error) => STR

Produce a string description of an error number. C<$child_error> defaults to
C<$?> if not specified. C<$os_error> defaults to C<$!> if not specified.

The algorithm is taken from perldoc -f system. Some sample output:

 failed to execute: No such file or directory (-1)
 died with signal 15, with coredump
 exited with value 3

An options hashref can be specified as the first argument to add information.
Currently known keys:

=over

=item * prog => str

Program name/path, to include in error messages:

 /usr/bin/foo failed to execute: Permission denied (-1)
 foo died with signal 15, with coredump
 /usr/bin/foo exited with value 3

=back

=head1 SEE ALSO

L<Process::Status> provides a lightweight OO interface for C<$?>. I recommend
this module now over Proc::ChildError.

L<IPC::System::Simple> provides a replacement for Perl's C<system()>, with the
difference that it will print a diagnostic error message similar to what
C<Proc::ChildError> provides. You only need to do C<use IPC::System::Simple
qw(system)> and use C<system()> as usual. Recommended.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Proc-ChildError>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Proc-ChildError>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Proc-ChildError>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
