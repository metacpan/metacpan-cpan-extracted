package Perinci::Sub::Property::curry;

our $DATE = '2016-05-12'; # DATE
our $VERSION = '0.07'; # VERSION

use 5.010001;
use strict;
use warnings;
#use Log::Any '$log';

use Data::Dmp;
use Perinci::Sub::PropertyUtil qw(declare_property);

declare_property(
    name => 'curry',
    type => 'function',
    schema => ['hash*'],
    wrapper => {
        meta => {
            v       => 2,
            prio    => 10,
            convert => 1,
        },
        handler => sub {
            my ($self, %args) = @_;
            my $v    = $args{new} // $args{value} // {};
            my $meta = $args{meta};

            $self->select_section('before_call_arg_validation');
            for my $an (keys %$v) {
                my $av = $v->{$an};
                $self->_errif(400, "\"Argument $an has been set by curry\"",
                              'exists($args{\''.$an.'\'})');
                $self->push_lines(
                    '$args{\''.$an.'\'} = '.dmp($av).';');
            }
        },
    },
);

1;
# ABSTRACT: Set arguments for function

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::Property::curry - Set arguments for function

=head1 VERSION

This document describes version 0.07 of Perinci::Sub::Property::curry (from Perl distribution Perinci-Sub-Property-curry), released on 2016-05-12.

=head1 SYNOPSIS

 # in function metadata
 args  => {a=>{}, b=>{}, c=>{}},
 curry => {a=>10},

 # when calling function
 f();             # equivalent to f(a=>10)
 f(b=>20, c=>30); # equivalent to f(a=>10, b=>20, c=>30)
 f(a=>5, b=>20);  # error, a has been set by curry

=head1 DESCRIPTION

This property sets arguments for function.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Sub-Property-curry>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Sub-Property-curry>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Sub-Property-curry>

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
