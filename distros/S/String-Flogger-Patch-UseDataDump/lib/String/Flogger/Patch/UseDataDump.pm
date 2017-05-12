package String::Flogger::Patch::UseDataDump;

our $DATE = '2015-12-31'; # DATE
our $VERSION = '0.01'; # VERSION

use 5.010001;
use strict;
no warnings;

use Data::Dump::SortKeys ();
use Module::Patch 0.12 qw();
use base qw(Module::Patch);

our %config;

sub patch_data {
    return {
        v => 3,
        patches => [
            {
                action      => 'replace',
                #mod_version => qr/^/,
                sub_name    => '_stringify_ref',
                code        => sub {
                    my ($self, $ref) = @_;
                    local $Data::Dump::SortKeys::REMOVE_PRAGMAS = 1;
                    Data::Dump::SortKeys::dump($ref);
                },
            },
        ],
   };
}

1;
# ABSTRACT: Use Data::Dump to stringify reference

__END__

=pod

=encoding UTF-8

=head1 NAME

String::Flogger::Patch::UseDataDump - Use Data::Dump to stringify reference

=head1 VERSION

This document describes version 0.01 of String::Flogger::Patch::UseDataDump (from Perl distribution String-Flogger-Patch-UseDataDump), released on 2015-12-31.

=head1 SYNOPSIS

 % PERL5OPT=-MString::Flogger::Patch::UseDataDump dzil build -v

=head1 DESCRIPTION

I use this patch module when debugging building with L<Dist::Zilla> (dzil). By
default, dzil uses L<Log::Dispatchouli> which in turn uses L<String::Flogger>
which in turn uses L<JSON> to dump references, with all its limitations. This
patch improves the dumping by using L<Data::Dump> (actually, currently
L<Data::Dump::SortKeys> for better coderef dumping) to see data structures more
clearly (objects, coderefs, etc).

=for Pod::Coverage ^()$

=head1 SEE ALSO

L<String::Flogger::Patch::UseDataDmp>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/String-Flogger-Patch-UseDataDump>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-String-Flogger-Patch-UseDataDump>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=String-Flogger-Patch-UseDataDump>

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
