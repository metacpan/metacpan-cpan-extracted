package Perinci::Sub::Property::retry;

use 5.010001;
use strict;
use warnings;

use Perinci::Sub::PropertyUtil qw(declare_property);

our $VERSION = '0.10'; # VERSION

declare_property(
    name => 'retry',
    type => 'function',
    schema => ['any' => {default=>0, of=>[
        ['int' => {min=>0, default=>0}],
        ['hash*' => {keys=>{
            'n'     => ['int' => {min=>0, default=>0}],
            'delay' => ['int' => {min=>0, default=>0}], # XXX: use duration?
            'success_statuses'   => ['regex' => {default=>'^(2..|304)$'}],
            'fatal_statuses'     => 'regex',
            'non_fatal_statuses' => 'regex',
            'fatal_messages'     => 'regex',
            'non_fatal_messages' => 'regex',
        }}],
    ]}],
    wrapper => {
        meta => {
            v       => 2,
            # very high, we want to trap errors as early as possible after eval,
            # so we can retry it.
            prio    => 0,
            convert => 1,
        },
        handler => sub {
            my ($self, %args) = @_;

            my $v    = $args{new} // $args{value};
            $v       = {n=>$v} unless ref($v) eq 'HASH';
            $v->{n}                //= 0;
            $v->{delay}            //= 0;
            $v->{success_statuses} //= qr/^(2..|304)$/;

            for my $k (qw/success_statuses
                          fatal_statuses non_fatal_statuses
                          fatal_messages non_fatal_messages/) {
                if (defined($v->{$k}) && ref($v->{$k}) ne 'Regexp') {
                    $v->{$k} = qr/$v->{$k}/;
                }
            }

            return unless $v->{n} > 0;

            $self->select_section('before_eval');
            $self->push_lines(
                '', 'my $_w_retries = 0;',
                'RETRY: while (1) {');
            $self->indent;

            # pass special variable for function to let it know about retries
            $self->select_section('before_call_arg_validation');
            my $args_as = $self->{_meta}{args_as};
            if ($args_as eq 'hash') {
                $self->push_lines('$args{-retries} = $_w_retries;');
            } elsif ($args_as eq 'hashref') {
                $self->push_lines('$args->{-retries} = $_w_retries;');
            }

            $self->select_section('after_eval');
            if ($self->{_arg}{meta}{result_naked}) {
                $self->push_lines('if ($_w_eval_err) {');
            } else {
                $self->push_lines('if ($_w_eval_err || $_w_res->[0] !~ qr/'.
                                      $v->{success_statuses}.'/) {');
            }
            $self->indent;
            if ($v->{fatal_statuses}) {
                $self->_errif('521', '"Can\'t retry (fatal status $_w_res->[0])"',
                              '$_w_res->[0] =~ qr/'.$v->{fatal_statuses}.'/');
            }
            if ($v->{non_fatal_statuses}) {
                $self->_errif(
                    '521', '"Can\'t retry (not non-fatal status $_w_res->[0])"',
                    '$_w_res->[0] !~ qr/'.$v->{non_fatal_statuses}.'/');
            }
            if ($v->{fatal_messages}) {
                $self->_errif(
                    '521', '"Can\'t retry (fatal message: $_w_res->[1])"',
                    '$_w_res->[1] =~ qr/'.$v->{fatal_messages}.'/');
            }
            if ($v->{non_fatal_messages}) {
                $self->_errif(
                    '521', '"Can\'t retry (not non-fatal message $_w_res->[1])"',
                    '$_w_res->[1] !~ qr/'.$v->{non_fatal_messages}.'/');
            }
            $self->_errif('521', '"Maximum retries reached"',
                          '++$_w_retries > '.$v->{n});
            $self->push_lines('sleep '.int($v->{delay}).';')
                if $v->{delay};
            $self->push_lines('next RETRY;');
            $self->unindent;
            $self->push_lines('} else {');
            $self->indent;
            # return information on number of retries performed
            unless ($self->{_meta}{result_naked}) {
                $self->push_lines('if ($_w_retries) {');
                $self->push_lines($self->{_args}{indent} . '$_w_res->[3] //= {};');
                $self->push_lines($self->{_args}{indent} . '$_w_res->[3]{retries}' .
                              ' = $_w_retries;');
                $self->push_lines('}');
            }
            $self->push_lines('last RETRY;');
            $self->unindent;
            $self->push_lines('}');
            $self->unindent;
            $self->push_lines('', '# RETRY', '}', '');
        },
    },
);

1;
# ABSTRACT: Specify automatic retry

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::Property::retry - Specify automatic retry

=head1 VERSION

This document describes version 0.10 of Perinci::Sub::Property::retry (from Perl distribution Perinci-Sub-Property-retry), released on 2016-05-11.

=head1 SYNOPSIS

 # in function metadata
 retry => 3,

 # more detailed
 retry => {n=>3, delay=>10, success_statuses=>/^(2..|3..)$/},

=head1 DESCRIPTION

This property specifies retry behavior.

Values: a hash containing these keys:

=over 4

=item * n => INT (default: 0)

Number of retries, default is 0 which means no retry.

=item * delay => INT (default: 0)

Number of seconds to wait before each retry, default is 0 which means no wait
between retries.

=item * success_statuses => REGEX (default: '^(2..|304)$')

Which status is considered success.

=item * fatal_statuses => REGEX

If set, specify that status matching this should be considered fatal and no
retry should be attempted.

=item * non_fatal_statuses => REGEX

If set, specify that status I<not> matching this should be considered fatal and
no retry should be attempted.

=item * fatal_messages => REGEX

If set, specify that message matching this should be considered fatal and no
retry should be attempted.

=item * non_fatal_messages => REGEX

If set, specify that message I<not> matching this should be considered fatal and
no retry should be attempted.

=back

Property value can also be an integer (specifying just 'n').

If function does not return enveloped result (result_naked=0), which means there
is no status returned, a function is assumed to fail only when it dies.

This property's wrapper implementation currently uses a simple loop around
the eval block.

It also pass a special argument to the function C<-retries> so that function can
be aware about retries.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Sub-Property-retry>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Sub-Property-retry>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Sub-Property-retry>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Perinci>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
