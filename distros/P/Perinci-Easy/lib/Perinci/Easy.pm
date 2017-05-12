package Perinci::Easy;

our $DATE = '2015-09-03'; # DATE
our $VERSION = '0.29'; # VERSION

use 5.010001;
use strict;
use warnings;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(defsub);

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Some easy shortcuts for Perinci',
};

$SPEC{defsub} = {
    v       => 1.1,
    summary => 'Define a subroutine',
    description => <<'_',

This is just a shortcut to define subroutine and meta together so instead of:

    our %SPEC;
    $SPEC{foo} = {
        v => 1.1,
        summary => 'Blah ...',
    };
    sub foo {
        ...
    }

you write:

    defsub name=>'foo', summary=>'Blah ...',
        code=>sub {
            ...
        };

_
};
sub defsub(%) {
    my %args = @_;
    my $name = $args{name} or die "Please specify subroutine's name";
    my $code = $args{code} or die "Please specify subroutine's code";

    my $spec = {%args};
    delete $spec->{code};
    $spec->{v} //= 1.1;

    no strict 'refs';
    my ($callpkg, undef, undef) = caller;
    ${$callpkg . '::SPEC'}{$name} = $spec;
    *{$callpkg . "::$name"} = $code;
}

sub defvar {
}

sub defpkg {
}

sub defclass {
}

1;
# ABSTRACT: Some easy shortcuts for Perinci

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Easy - Some easy shortcuts for Perinci

=head1 VERSION

This document describes version 0.29 of Perinci::Easy (from Perl distribution Perinci-Easy), released on 2015-09-03.

=head1 SYNOPSIS

 use Perinci::Easy qw(defsub);

 # define subroutine, with metadata
 defsub
     name        => 'myfunc',
     summary     => 'Does foo to bar',
     description => '...',
     args        => {
         ...
     },
     code        => sub {
         my %args = @_;
         ...
     };

=head1 DESCRIPTION

This module provides some easy shortcuts.

=head1 FUNCTIONS


=head2 defsub() -> [status, msg, result, meta]

Define a subroutine.

This is just a shortcut to define subroutine and meta together so instead of:

 our %SPEC;
 $SPEC{foo} = {
     v => 1.1,
     summary => 'Blah ...',
 };
 sub foo {
     ...
 }

you write:

 defsub name=>'foo', summary=>'Blah ...',
     code=>sub {
         ...
     };

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=for Pod::Coverage (defvar|defpkg|defclass)

=head1 SEE ALSO

L<Perinci>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Easy>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Easy>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Easy>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
