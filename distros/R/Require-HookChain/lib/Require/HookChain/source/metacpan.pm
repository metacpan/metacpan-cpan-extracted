package Require::HookChain::source::metacpan;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-11-13'; # DATE
our $DIST = 'Require-HookChain'; # DIST
our $VERSION = '0.003'; # VERSION

use strict;
use warnings;
use Log::ger;

use Require::Hook::Source::MetaCPAN;

sub new {
    my ($class, $die) = @_;
    $die = 1 unless defined $die;
    bless { die => $die }, $class;
}

sub Require::HookChain::source::metacpan::INC {
    my ($self, $r) = @_;

    my $filename = $r->filename;

    # safety, in case we are not called by Require::HookChain
    return () unless ref $r;

    if (defined $r->src) {
        log_trace "[RHC:source::metacpan] source code already defined for $filename, declining";
        return;
    }

    my $rh = Require::Hook::Source::MetaCPAN->new(die => $self->{die});
    my $res = Require::Hook::Source::MetaCPAN::INC($rh, $filename);
    return unless $res;
    $r->src($$res);
}

1;
# ABSTRACT: Prepend a piece of code to module source

__END__

=pod

=encoding UTF-8

=head1 NAME

Require::HookChain::source::metacpan - Prepend a piece of code to module source

=head1 VERSION

This document describes version 0.003 of Require::HookChain::source::metacpan (from Perl distribution Require-HookChain), released on 2020-11-13.

=head1 SYNOPSIS

In Perl code:

 use Require::HookChain 'source::metacpan';
 use Ask; # will retrieve from MetaCPAN, even if it's installed

On the command-line:

 # will retrieve from MetaCPAN if Ask is not installed
 % perl -MRHC=-end,1,source::metacpan -MAsk -E...

=head1 DESCRIPTION

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Require-HookChain>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Require-HookChain>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Require-HookChain>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Require::HookChain>

L<Require::Hook::MetaCPAN>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
