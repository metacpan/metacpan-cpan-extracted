package ScriptX_Util::Patcher::DumpAndExit;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-10-03'; # DATE
our $DIST = 'ScriptX_Util'; # DIST
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;

use Data::Dmp;
use Module::Patch qw(patch_package);

BEGIN {
    if ($INC{"ScriptX.pm"}) {
        warn "ScriptX has been loaded, we might not be able to patch it";
    }
    require ScriptX;
}

sub _dump {
    print "# BEGIN DUMP ScriptX\n";
    local $Data::Dmp::OPT_DEPARSE = 0;
    say dmp($_[0]);
    print "# END DUMP ScriptX\n";
}

our $handle = patch_package('ScriptX', [
    {
        action => 'replace',
        sub_name => 'import',
        code => sub {
            my $class = shift;
            _dump(\@_);
            exit 0;
        },
    },
]);

1;
# ABSTRACT: Patch ScriptX to dump import arguments and exit

__END__

=pod

=encoding UTF-8

=head1 NAME

ScriptX_Util::Patcher::DumpAndExit - Patch ScriptX to dump import arguments and exit

=head1 VERSION

This document describes version 0.004 of ScriptX_Util::Patcher::DumpAndExit (from Perl distribution ScriptX_Util), released on 2020-10-03.

=head1 DESCRIPTION

This patch can be used to extract ScriptX list of loaded plugins

=for Pod::Coverage ^(patch_data)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/ScriptX_Util>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-ScriptX_Util>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=ScriptX_Util>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
