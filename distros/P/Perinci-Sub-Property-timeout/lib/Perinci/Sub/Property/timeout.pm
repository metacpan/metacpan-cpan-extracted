package Perinci::Sub::Property::timeout;

use 5.010001;
use strict;
use warnings;

use Perinci::Sub::PropertyUtil qw(declare_property);

our $VERSION = '0.08'; # VERSION

declare_property(
    name => 'timeout',
    type => 'function',
    schema => ['int*' => {min=>0}],
    wrapper => {
        meta => {
            v       => 2,
            # highest, we need to disable alarm right after call
            prio    => 1,
            convert => 1,
        },
        handler => sub {
            my ($self, %args) = @_;
            my $v    = int($args{new} // $args{value} // 0);
            my $meta = $args{meta};

            return unless $v > 0;

            $self->select_section('before_call_right_before_call');
            $self->push_lines(
                'local $SIG{ALRM} = sub { die "Timed out\n" };',
                "alarm($v);");

            $self->select_section('after_call_right_after_call');
            $self->push_lines('alarm(0);');

            $self->select_section('after_eval');
            $self->_errif(504, "\"Timed out ($v sec(s))\"",
                          '$_w_eval_err =~ /\ATimed out\b/');
        },
    },
);

1;
# ABSTRACT: Specify function execution time limit

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::Property::timeout - Specify function execution time limit

=head1 VERSION

This document describes version 0.08 of Perinci::Sub::Property::timeout (from Perl distribution Perinci-Sub-Property-timeout), released on 2016-05-11.

=head1 SYNOPSIS

 # in function metadata
 timeout => 5,

=head1 DESCRIPTION

This property specifies function execution time limit, in seconds. The default
is 0, which means unlimited.

This property's wrapper implementation uses C<alarm()> (C<ualarm()> replacement,
for subsecond granularity, will be considered upon demand). If limit is reached,
a 504 (timeout) status is returned.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Sub-Property-timeout>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Sub-Property-timeout>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Sub-Property-timeout>

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
