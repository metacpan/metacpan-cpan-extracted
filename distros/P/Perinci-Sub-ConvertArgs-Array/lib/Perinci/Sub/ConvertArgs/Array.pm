package Perinci::Sub::ConvertArgs::Array;

our $DATE = '2019-04-15'; # DATE
our $VERSION = '0.090'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(convert_args_to_array);

our %SPEC;

$SPEC{convert_args_to_array} = {
    v => 1.1,
    summary => 'Convert hash arguments to array',
    description => <<'_',

Using information in 'args' property (particularly the 'pos' and 'slurpy' of
each argument spec), convert hash arguments to array.

Example:

    my $meta = {
        v => 1.1,
        summary => 'Multiply 2 numbers (a & b)',
        args => {
            a => ['num*' => {arg_pos=>0}],
            b => ['num*' => {arg_pos=>1}],
        }
    }

then 'convert_args_to_array(args=>{a=>2, b=>3}, meta=>$meta)' will produce:

    [200, "OK", [2, 3]]

_
    args => {
        args => {req=>1, schema=>'hash*', pos=>0},
        meta => {req=>1, schema=>'hash*', pos=>1},
    },
};
sub convert_args_to_array {
    my %input_args   = @_;
    my $args         = $input_args{args} or return [400, "Please specify args"];
    my $meta         = $input_args{meta} or return [400, "Please specify meta"];
    my $args_prop    = $meta->{args} // {};

    my $v = $meta->{v} // 1.0;
    return [412, "Sorry, only metadata version 1.1 is supported (yours: $v)"]
        unless $v == 1.1;

    #$log->tracef("-> convert_args_to_array(), args=%s", $args);

    my @array;

    while (my ($k, $v) = each %$args) {
        next if $k =~ /\A-/; # skip special arguments
        my $as = $args_prop->{$k};
        return [412, "Argument $k: Not specified in args property"] unless $as;
        my $pos = $as->{pos};
        return [412, "Argument $k: No pos specified in arg spec"]
            unless defined $pos;
        if ($as->{slurpy} // $as->{greedy}) {
            $v = [$v] if ref($v) ne 'ARRAY';
            # splice can't work if $pos is beyond array's length
            for (@array .. $pos-1) {
                $array[$_] = undef;
            }
            splice @array, $pos, 0, @$v;
        } else {
            $array[$pos] = $v;
        }
    }
    [200, "OK", \@array];
}

1;
# ABSTRACT: Convert hash arguments to array

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::ConvertArgs::Array - Convert hash arguments to array

=head1 VERSION

This document describes version 0.090 of Perinci::Sub::ConvertArgs::Array (from Perl distribution Perinci-Sub-ConvertArgs-Array), released on 2019-04-15.

=head1 SYNOPSIS

 use Perinci::Sub::ConvertArgs::Array qw(convert_args_to_array);

 my $res = convert_args_to_array(args=>\%args, meta=>$meta, ...);

=head1 DESCRIPTION

This module provides convert_args_to_array() (and
gencode_convert_args_to_array(), upcoming). This module is used by, among
others, L<Perinci::Sub::Wrapper>.

=head1 FUNCTIONS


=head2 convert_args_to_array

Usage:

 convert_args_to_array(%args) -> [status, msg, payload, meta]

Convert hash arguments to array.

Using information in 'args' property (particularly the 'pos' and 'slurpy' of
each argument spec), convert hash arguments to array.

Example:

 my $meta = {
     v => 1.1,
     summary => 'Multiply 2 numbers (a & b)',
     args => {
         a => ['num*' => {arg_pos=>0}],
         b => ['num*' => {arg_pos=>1}],
     }
 }

then 'convert_args_to_array(args=>{a=>2, b=>3}, meta=>$meta)' will produce:

 [200, "OK", [2, 3]]

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<args>* => I<hash>

=item * B<meta>* => I<hash>

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

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Sub-ConvertArgs-Array>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Sub-ConvertArgs-Array>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Sub-ConvertArgs-Array>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2015, 2014, 2012, 2011 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
