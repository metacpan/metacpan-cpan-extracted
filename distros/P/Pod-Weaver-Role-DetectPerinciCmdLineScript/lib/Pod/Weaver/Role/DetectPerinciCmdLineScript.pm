package Pod::Weaver::Role::DetectPerinciCmdLineScript;

our $DATE = '2014-12-28'; # DATE
our $VERSION = '0.01'; # VERSION

use 5.010001;
use Moose::Role;

use Perinci::CmdLine::Util ();

sub detect_perinci_cmdline_script {
    my ($self, $input) = @_;

    my $filename = $input->{filename};

    # find file object
    my $file;
    for (@{ $input->{zilla}->files }) {
        if ($_->name eq $filename) {
            $file = $_;
            last;
        }
    }
    die "Can't find file object for $filename" unless $file;

    Perinci::CmdLine::Util::detect_perinci_cmdline_script(
        string => $file->content,
    );
}

no Moose::Role;
1;
# ABSTRACT: Role to detect Perinci::CmdLine script

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Role::DetectPerinciCmdLineScript - Role to detect Perinci::CmdLine script

=head1 VERSION

This document describes version 0.01 of Pod::Weaver::Role::DetectPerinciCmdLineScript (from Perl distribution Pod-Weaver-Role-DetectPerinciCmdLineScript), released on 2014-12-28.

=head1 METHODS

=head2 $obj->detect_perinci_cmdline_script($input)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Pod-Weaver-Role-DetectPerinciCmdLineScript>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Pod-Weaver-Role-DetectPerinciCmdLineScript>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Pod-Weaver-Role-DetectPerinciCmdLineScript>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
