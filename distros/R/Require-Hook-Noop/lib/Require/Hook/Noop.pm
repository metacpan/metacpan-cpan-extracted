package Require::Hook::Noop;

our $DATE = '2017-01-21'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

sub new {
    my ($class, %args) = @_;

    $args{_filenames} = [];
    for my $e0 (@{ $args{modules} // [] }) {
        (my $e = "$e0.pm") =~ s!::!/!g;
        push @{ $args{_filenames} }, $e;
    }

    bless \%args, $class;
}

my $noop_code = "1;\n";

sub Require::Hook::Noop::INC {
    my ($self, $filename) = @_;

    if (grep { $filename eq $_ } @{ $self->{_filenames} }) {
        print STDERR __PACKAGE__ . ": require($filename) no-op'ed\n" if $self->{debug};
        return \$noop_code;
    }

    print STDERR __PACKAGE__ . ": declined handling require($filename)\n" if $self->{debug};
    undef;
}

1;
# ABSTRACT: No-op loading of some modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Require::Hook::Noop - No-op loading of some modules

=head1 VERSION

This document describes version 0.002 of Require::Hook::Noop (from Perl distribution Require-Hook-Noop), released on 2017-01-21.

=head1 SYNOPSIS

 {
     local @INC = (Require::Hook::Noop->new( modules => [qw/Foo::Bar Qux/] ));
     require Foo::Bar; # will be no-op'ed
     require Baz;      # will be loaded
     # ...
 }

=head1 DESCRIPTION

This is a L<Require::Hook> version of L<lib::noop>.

=for Pod::Coverage .+

=head1 METHODS

=head2 new([ %args ]) => obj

Constructor. Known arguments:

=over

=item * modules => array

Module names to no-op, e.g. C<< ["Mod::SubMod", "Mod2"] >>.

=item * debug => bool

If set to true, will print debug statements to STDERR.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Require-Hook-Noop>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Require-Hook-Noop>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Require-Hook-Noop>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<lib::noop>

Other C<Require::Hook::*> modules.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
