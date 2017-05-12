package Perl::Core;
$Perl::Core::VERSION = '0.0100';
use 5.010_000;

use strict;
use warnings;
 
use match::simple           ();
use mro                     ();
use feature                 ();
use PerlX::Define           ();
use PerlX::Maybe            ();
use Syntax::Feature::Try    ();
use Sub::Infix              ();

use constant DEFAULT_VERSION => ':5.14';

sub import
{
    my ($class, $version) = @_;
    my $caller = scalar caller();
 
    warnings->import;
    strict->import;
    feature->import( $version ? ":$version" : DEFAULT_VERSION );
    mro::set_mro($caller, 'c3');

    PerlX::Define->import;
    Syntax::Feature::Try->install;
    no strict 'refs';
    *{$caller . '::maybe'} = \&PerlX::Maybe::maybe;
    *{$caller . '::provided'} = \&PerlX::Maybe::provided;
    *{$caller . '::in'} = Sub::Infix::infix { match::simple::match @_ };
}
 
sub unimport
{
    warnings->unimport;
    strict->unimport;
    feature->unimport;
}
 
1;

# ABSTRACT: Perl core essentials in a single import

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Core - Perl core essentials in a single import

=head1 VERSION

version 0.0100

=head1 SYNOPSIS

    use Perl::Core;

    # Your code here

=head1 DESCRIPTION

Perl::Core provides the best parts of Modern Perl in a single, user-friendly import. Perl version C<5.14> is used by default, but you can choose which version to use in your import statement.

    use Perl::Core '5.18';

The following modules and keywords will be automatically loaded into your script:

=over

=item L<strict> – Restrict unsafe constructs

=item L<warnings> – Enable optional warnings

=item L<feature> – Enable new language features based on selected version

=item L<mro> – Sane method resolution order under multiple inheritance (L<Class::C3>)

=item L<match::simple> – Simplified smartmatch with C<|in|> keyword

=item L<PerlX::Define> – Simplified constants with C<define> keyword

=item L<PerlX::Maybe> – Simplified conditional handling with C<maybe/provided> keywords

=item L<Syntax::Feature::Try> – Sane exception handling with C<try/catch/finally> keywords

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/aanari/Perl-Core/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Ali Anari <ali@anari.me>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Ali Anari.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
