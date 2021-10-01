package Pod::Weaver::Role::RequireFromBuild;

use 5.010001;
use Moose::Role;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-09-27'; # DATE
our $DIST = 'Pod-Weaver-Role-RequireFromBuild'; # DIST
our $VERSION = '0.001'; # VERSION

sub require_from_build {
    my ($self, $input, $name) = @_;

    my $zilla = $input->{zilla} or die "Can't get Dist::Zilla object";

    if ($name =~ /::/) {
        $name =~ s!::!/!g;
        $name .= ".pm";
    }

    return if exists $INC{$name};

    my @files = grep { $_->name eq "lib/$name" } @{ $zilla->files };
    @files    = grep { $_->name eq $name }       @{ $zilla->files }
        unless @files;
    die "Can't find $name in lib/ or ./ in build files" unless @files;

    my $file = $files[0];
    my $filename = $file->name;
    eval "# line 1 \"$filename (from dist build)\"\n" . $file->encoded_content; ## no critic: BuiltinFunctions::ProhibitStringyEval
    die if $@;
    $INC{$name} = "(set by ".__PACKAGE__.", from build files)";
}

no Moose::Role;
1;
# ABSTRACT: Role to require() from Dist::Zilla build files

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Role::RequireFromBuild - Role to require() from Dist::Zilla build files

=head1 VERSION

This document describes version 0.001 of Pod::Weaver::Role::RequireFromBuild (from Perl distribution Pod-Weaver-Role-RequireFromBuild), released on 2021-09-27.

=head1 SYNOPSIS

 $self->require_from_build($input, 'Foo/Bar.pm');
 $self->require_from_build($input, 'Baz::Quux');

=head1 DESCRIPTION

=head1 PROVIDED METHODS

=head2 require_from_build

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Pod-Weaver-Role-RequireFromBuild>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Pod-Weaver-Role-RequireFromBuild>.

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

This software is copyright (c) 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Pod-Weaver-Role-RequireFromBuild>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
