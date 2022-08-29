package Require::Hook::Source::DzilBuild;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-07-16'; # DATE
our $DIST = 'Require-Hook-Source-DzilBuild'; # DIST
our $VERSION = '0.004'; # VERSION

sub new {
    my ($class, %args) = @_;
    $args{zilla} or die "Plase supply zilla object";
    bless \%args, $class;
}

sub Require::Hook::Source::DzilBuild::INC {
    my ($self, $filename) = @_;

    print STDERR __PACKAGE__ . ": entering handler for require($filename)\n" if $self->{debug};

    my @files = grep { $_->name eq "lib/$filename" } @{ $self->{zilla}->files };
    @files    = grep { $_->name eq $filename }       @{ $self->{zilla}->files }
        unless @files;
    @files or do {
        die "Can't locate $filename in lib/ or ./ in build files" if $self->{die};
        print STDERR __PACKAGE__ . ": declined handling require($filename): Can't locate $filename in lib/ or ./ in Dist::Zilla build files\n" if $self->{debug};
        return;
    };

    print STDERR __PACKAGE__ . ": require($filename) from Dist::Zilla build file\n" if $self->{debug};
    \($files[0]->encoded_content);
}

1;
# ABSTRACT: Load module source code from Dist::Zilla build files

__END__

=pod

=encoding UTF-8

=head1 NAME

Require::Hook::Source::DzilBuild - Load module source code from Dist::Zilla build files

=head1 VERSION

This document describes version 0.004 of Require::Hook::Source::DzilBuild (from Perl distribution Require-Hook-Source-DzilBuild), released on 2022-07-16.

=head1 SYNOPSIS

In your L<Dist::Zilla> plugin, e.g. in C<munge_files()>:

 sub munge_files {
     my $self = shift;

     local @INC = (Require::Hook::Source::DzilBuild->new(zilla => $self->zilla), @INC);
     require Foo::Bar; # will be searched from build files, if exist

     ...
 }

=head1 DESCRIPTION

This is the L<Require::Hook> version of the same functionality found in
L<Dist::Zilla::Role::RequireFromBuild>.

It looks for files from C<lib/> and C<.> of Dist::Zilla build files.

=for Pod::Coverage .+

=head1 METHODS

=head2 new(%args) => obj

Constructor. Known arguments:

=over

=item * die => bool (default: 0)

If set to 1, will die if filename to be C<require()>-d does not exist in build
files. Otherwise if set to false (the default) will simply decline if file is
not found in build files.

=item * debug => bool

If set to 1, will print more debug stuffs to STDERR.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Require-Hook-Source-DzilBuild>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Require-Hook-Source-DzilBuild>.

=head1 SEE ALSO

L<Dist::Zilla::Role::RequireFromBuild>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2020, 2017 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Require-Hook-Source-DzilBuild>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
