package Perl::Critic::Policy::ProhibitImplicitImport;

use strict;
use warnings;

our $VERSION = '0.000001';

use Perl::Critic::Utils qw($SEVERITY_LOW);
use parent 'Perl::Critic::Policy';

use constant DESC => 'Using a module without an explicit import list';
use constant EXPL =>
    'Using the a module without specifying an import list can result in importing many symbols. Import the symbols you want explicitly, or prevent implicit imports via ().';

sub applies_to { 'PPI::Statement::Include' }

sub default_severity { $SEVERITY_LOW }

sub supported_parameters {
    return (
        {
            name        => 'ignored_modules',
            description => 'Modules which will be ignored by this policy.',
            behavior    => 'string list',
            list_always_present_values => [
                qw(
                    Carp::Always
                    Courriel::Builder
                    Data::Dumper
                    Data::Dumper::Concise
                    Data::Printer
                    DDP
                    Devel::Confess
                    Encode::Guess
                    Exporter::Lite
                    File::chdir
                    FindBin
                    Git::Sub
                    HTTP::Message::PSGI
                    Import::Into
                    Mojolicious::Lite
                    Moo
                    Moo::Role
                    Moose
                    Moose::Exporter
                    Moose::Role
                    Moose::Util::TypeConstraints
                    MooseX::Getopt
                    MooseX::LazyRequire
                    MooseX::NonMoose
                    MooseX::Role::Parameterized
                    MooseX::SemiAffordanceAccessor
                    MooX::Options
                    MooX::StrictConstructor
                    Mouse
                    PerlIO::gzip
                    Stepford::Role::Step
                    Test2::V0
                    Test::Class::Moose
                    Test::Class::Moose::Role
                    Test::More
                    Test::Number::Delta
                    Test::XML
                )
            ],
        },
    );
}

sub violates {
    my ( $self, $elem ) = @_;
    my $ignore = $self->{_ignored_modules};

    if (  !$elem->pragma
        && $elem->type
        && $elem->type eq 'use'
        && !$elem->arguments
        && !exists $ignore->{ ( $elem->module // q{} ) } ) {
        return $self->violation( DESC, EXPL, $elem );
    }

    return ();
}

1;

# ABSTRACT: Prefer symbol imports to be explicit

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::ProhibitImplicitImport - Prefer symbol imports to be explicit

=head1 VERSION

version 0.000001

=head1 DESCRIPTION

Some Perl modules can implicitly import many symbols if no imports are
specified. To avoid this, and to assist in finding where symbols have been
imported from, specify the symbols you want to import explicitly in the C<use>
statement.  Alternatively, specify an empty import list with C<use Foo ()> to
avoid importing any symbols at all, and fully qualify the functions or
constants, such as C<Foo::strftime>.

    use POSIX;                                                         # not ok
    use POSIX ();                                                      # ok
    use POSIX qw(fcntl);                                               # ok
    use POSIX qw(O_APPEND O_CREAT O_EXCL O_RDONLY O_RDWR O_WRONLY);    # ok

For modules which inherit from L<Test::Builder::Module>, you may need to use a
different import syntax.

    use Test::JSON;                          # not ok
    use Test::JSON import => ['is_json'];    # ok

=head1 CONFIGURATION

By default, this policy ignores many modules (like L<Moo> and L<Moose>) for
which implicit imports provide the expected behaviour. See the source of this
module for a complete list. If you would like to ignore additional modules,
this can be done via configuration:

    [ProhibitImplicitImport]
    ignored_modules = Git::Sub Regexp::Common

=head1 ACKNOWLEDGEMENTS

Much of this code and even some documentation has been inspired by and borrowed
directly from L<Perl::Critic::Policy::Freenode::POSIXImports> and
L<Perl::Critic::Policy::TooMuchCode>.

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
