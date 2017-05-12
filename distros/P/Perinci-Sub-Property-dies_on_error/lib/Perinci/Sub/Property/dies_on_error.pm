package Perinci::Sub::Property::dies_on_error;

our $DATE = '2016-05-11'; # DATE
our $VERSION = '0.07'; # VERSION

use 5.010001;
use strict;
use warnings;
#use Log::Any '$log';

use Perinci::Sub::PropertyUtil qw(declare_property);

declare_property(
    name => 'dies_on_error',
    type => 'function',
    schema => ['any*' => {of=>[
        ['bool' => {default=>0}],
        ['hash*' => {keys=>{
            'success_statuses'   => ['regex' => {default=>'^(2..|304)$'}],
        }}],
    ]}],
    wrapper => {
        meta => {
            v       => 2,
            prio    => 99, # very low, the last to do stuff to $_w_res
            convert => 1,
        },
        handler => sub {
            my ($self, %args) = @_;
            my $v    = $args{new} // $args{value} // 0;
            my $meta = $args{meta};

            return unless $v;

            die "Cannot use dies_on_error if result_naked is 1"
                if $self->{_meta}{result_naked};

            $v = {} if ref($v) ne 'HASH';

            $v->{success_statuses} //= qr/^(2..|304)$/;

            for my $k (qw/success_statuses/) {
                if (defined($v->{$k}) && ref($v->{$k}) ne 'Regexp') {
                    $v->{$k} = qr/$v->{$k}/;
                }
            }

            $self->select_section('after_eval');

            $self->push_lines('if ($_w_eval_err) { die $_w_eval_err }');

            $self->push_lines('if ($_w_res->[0] !~ /'.$v->{success_statuses}.'/) {');
            $self->indent;
            $self->push_lines(join(
                "",
                "die 'Call to ",
                ($self->{_args}{sub_name} ? "$self->{_args}{sub_name}()" : "function"),
                q[ returned non-success status '. "$_w_res->[0]: $_w_res->[1]";]));
            $self->unindent;
            $self->push_lines('}');
        },
    },
);

1;
# ABSTRACT: Die on non-success result

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::Property::dies_on_error - Die on non-success result

=head1 VERSION

This document describes version 0.07 of Perinci::Sub::Property::dies_on_error (from Perl distribution Perinci-Sub-Property-dies_on_error), released on 2016-05-11.

=head1 SYNOPSIS

Without dies_on_error:

 # on successful call
 f(...); # [200, "OK"]

 # on non-successful call
 f(...); # [404, "Not found"]

With C<< dies_on_error => 1 >>:

 # on successful call
 f(...); # [200, "OK"]

 # on non-successful call
 f(...); # dies with message "Call f() failed with 404 status: Not found"

To customize what statuses are considered error: C<< dies_on_error => {
success_statuses => '^2..$' } >>.

=head1 DESCRIPTION

This property sets so that function dies when result status is a non-successful
one (it even dies under wrapping option trap=>1). Successful statuses by default
include 2xx and 304 (C<< '^(2..|304)$' >>).

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Sub-Property-dies_on_error>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Sub-Property-dies_on_error>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Sub-Property-dies_on_error>

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
