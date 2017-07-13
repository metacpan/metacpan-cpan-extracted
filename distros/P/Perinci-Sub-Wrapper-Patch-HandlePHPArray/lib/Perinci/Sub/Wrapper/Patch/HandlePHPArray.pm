package Perinci::Sub::Wrapper::Patch::HandlePHPArray;

our $DATE = '2017-07-10'; # DATE
our $VERSION = '0.04'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use parent qw(Module::Patch);

my $code = sub {
    my $ctx = shift;

    my ($self, %args) = @_;

    $ctx->{orig}->(@_);

    $self->select_section('before_call_before_arg_validation');

    my $args = $self->{_meta}{args};
    for my $an (sort keys %$args) {
        my $aspec = $args->{$an};
        next unless $aspec->{schema};
        if ($aspec->{schema}[0] eq 'array') {
            $self->push_lines("if (ref(\$args{$an}) eq 'HASH' && !keys(\%{\$args{$an}})) { \$args{$an} = [] }");
        }
        if ($aspec->{schema}[0] eq 'hash') {
            $self->push_lines("if (ref(\$args{$an}) eq 'ARRAY' && !\@{\$args{$an}}) { \$args{$an} = {} }");
        }
    }
};

sub patch_data {
    return {
        v => 3,
        patches => [
            {
                action => 'wrap',
                sub_name => 'handle_args',
                code => $code,
            },
        ],
    };
}

1;
# ABSTRACT: Convert {} to [] or vice versa to match functions' expectations

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::Wrapper::Patch::HandlePHPArray - Convert {} to [] or vice versa to match functions' expectations

=head1 VERSION

This document describes version 0.04 of Perinci::Sub::Wrapper::Patch::HandlePHPArray (from Perl distribution Perinci-Sub-Wrapper-Patch-HandlePHPArray), released on 2017-07-10.

=head1 SYNOPSIS

 use Perinci::Sub::Wrapper::HandlePHPArray;

=head1 DESCRIPTION

This module patches L<Perinci::Sub::Wrapper> so the generated function wrapper
code can convert argument C<{}> to C<[]> when function expects argument to be an
array, or vice versa C<[]> to C<{}> when function expects a hash argument. This
can help if function is being called by PHP clients, because in PHP C<Array()>
is ambiguous, it can be an empty hash or an empty array.

To make this work, you have to specify schema in your argument specification in
your Rinci metadata, and the type must be hash or array.

This is a temporary/stop-gap solution. The more "official" solution is to use
L<Perinci::Access::HTTP::Server> which has the C<deconfuse_php_clients> option
(by default turned on).

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Sub-Wrapper-Patch-HandlePHPArray>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Sub-Wrapper-Patch-HandlePHPArray>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Sub-Wrapper-Patch-HandlePHPArray>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2015, 2014, 2013 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
