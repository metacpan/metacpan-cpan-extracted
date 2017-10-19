package Perl::Examples::Accessors::Array;

our $DATE = '2017-10-15'; # DATE
our $VERSION = '0.131'; # VERSION

sub new {
    my ($class, %attrs) = @_;
    my $self = bless [], $class;
    $self->[0] = $attrs{attr1} if exists $attrs{attr1};
    $self;
}

sub attr1_unoptimized {
    my $self = shift;
    $self->[0] = $_[0] if @_;
    $self->[0];
}

sub attr1 {
    if (@_ > 1) {
        $_[0][0] = $_[1];
    } else {
        $_[0][0];
    }
}

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Examples::Accessors::Array

=head1 VERSION

This document describes version 0.131 of Perl::Examples::Accessors::Array (from Perl distribution Perl-Examples-Accessors), released on 2017-10-15.

=head1 DESCRIPTION

This is an example of a class which does not use any kind of object system or
accessor generator. It is array-based.

=for Pod::Coverage ^(attr1_unoptimized)$

=head1 ATTRIBUTES

=head2 attr1

=head1 METHODS

=head2 new(%attrs) => obj

Constructor. Accept a hash to set attributes. No checking of unknown attributes
is performed.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perl-Examples-Accessors>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perl-Examples-Accessors>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perl-Examples-Accessors>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
