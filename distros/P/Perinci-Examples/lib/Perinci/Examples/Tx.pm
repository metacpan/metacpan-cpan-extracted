package Perinci::Examples::Tx;

our $DATE = '2019-06-29'; # DATE
our $VERSION = '0.814'; # VERSION

use 5.010;
use strict;
use warnings;

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Examples for using transaction',
};

$SPEC{check_state} = {
    v => 1.1,
    summary => "Return 'check_state' if checking state, otherwise empty string",
    features => {tx=>{v=>2}, idempotent=>1},
};
sub check_state {
    my %args = @_;
    [200, "OK", $args{-tx_action} eq 'check_state' ? "check_state" : ""];
}

1;
# ABSTRACT: Examples for using transaction

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Examples::Tx - Examples for using transaction

=head1 VERSION

This document describes version 0.814 of Perinci::Examples::Tx (from Perl distribution Perinci-Examples), released on 2019-06-29.

=head1 FUNCTIONS


=head2 check_state

Usage:

 check_state() -> [status, msg, payload, meta]

Return 'check_state' if checking state, otherwise empty string.

This function is not exported.

This function is idempotent (repeated invocations with same arguments has the same effect as single invocation). This function supports transactions.


No arguments.

Special arguments:

=over 4

=item * B<-tx_action> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=item * B<-tx_action_id> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=item * B<-tx_recovery> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=item * B<-tx_rollback> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=item * B<-tx_v> => I<str>

For more information on transaction, see L<Rinci::Transaction>.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Examples>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Examples>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Examples>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2017, 2016, 2015, 2014, 2013, 2012, 2011 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
