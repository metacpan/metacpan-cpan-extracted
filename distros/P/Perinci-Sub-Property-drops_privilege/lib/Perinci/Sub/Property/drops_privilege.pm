package Perinci::Sub::Property::drops_privilege;

use 5.010001;
use strict;
use warnings;

use Perinci::Sub::PropertyUtil qw(declare_property);

our $VERSION = '0.08'; # VERSION

declare_property(
    name => 'drops_privilege',
    type => 'function',
    schema => ['bool' => {default=>0}],
    wrapper => {
        meta => {
            v       => 2,
            # should be done quite immediately after eval
            prio    => 20,
            convert => 1,
        },
        handler => sub {
            my ($self, %args) = @_;
            my $v = $args{new} // $args{value} // '';
            die "Invalid value for drops_privilege '$v', ".
                "please use '', 'temporary', or 'permanent'"
                    unless $v =~ /\A(|temp(?:orary)?|perm(?:anent)?)\z/;

            if ($v =~ /temp/) {
                $self->select_section('after_eval');
                $self->push_lines('if ($< == 0 && $>) { $> = 0; $) = $( }');
            }
        },
    },
);

1;
# ABSTRACT: Declare that function drops privilege during running

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::Property::drops_privilege - Declare that function drops privilege during running

=head1 VERSION

This document describes version 0.08 of Perinci::Sub::Property::drops_privilege (from Perl distribution Perinci-Sub-Property-drops_privilege), released on 2016-05-11.

=head1 SYNOPSIS

 # in your function metadata
 drops_privilege => 'temp'

=head1 DESCRIPTION

Valid values: '', 'temporary' (or 'temp'), or 'permanent' (or 'perm').

This property declares that function drops privilege (either temporarily by
setting EUID ($>), or permanently by setting UID ($<)) during execution. Usually
the function is run by superuser and needs to perform things on behalf of normal
users.

This property's wrapper implementation currently does this: If privilege is
dropped temporarily, make sure that we switch back to superuser. Sometimes when
the function dies, privileges are not restored, causing failure to subsequent
operation.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Sub-Property-drops_privilege>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Sub-Property-drops_privilege>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Sub-Property-drops_privilege>

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
