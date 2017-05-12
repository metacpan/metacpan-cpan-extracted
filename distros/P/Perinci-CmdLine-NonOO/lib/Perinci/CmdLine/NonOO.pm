package Perinci::CmdLine::NonOO;

our $DATE = '2015-09-03'; # DATE
our $VERSION = '0.02'; # VERSION

use 5.010001;
use strict;
use warnings;
use Perinci::Sub::Gen::FromClass qw(gen_func_from_class);

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(run_cmdline_app);

my $res = gen_func_from_class(
    class  => 'Perinci::CmdLine::Lite',
    method => 'run',
    name   => 'run_cmdline_app',
);
die "Can't create run_cmdline_app(): $res->[0] - $res->[1]"
    unless $res->[0] == 200;

1;
# ABSTRACT: Non-OO interface for Perinci::CmdLine

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::CmdLine::NonOO - Non-OO interface for Perinci::CmdLine

=head1 VERSION

This document describes version 0.02 of Perinci::CmdLine::NonOO (from Perl distribution Perinci-CmdLine-NonOO), released on 2015-09-03.

=head1 SYNOPSIS

 use Perinci::CmdLine::NonOO qw(run_cmdline_app);
 run_cmdline_app(url => '/Foo/bar');

which is equivalent to:

 use Perinci::CmdLine::Lite;
 my $cli = Perinci::CmdLine::Lite->new(url => '/Foo/bar');
 $cli->run;

=head1 DESCRIPTION

L<Perinci::CmdLine> (or its alternatives L<Perinci::CmdLine::Lite>,
L<Perinci::CmdLine::Any>) is a command-line application framework. It "exports"
your functions as a CLI application. However, Perinci::CmdLine itself has an OO
interface, which can be seen as ironic. This module is an attempt to fix this.
It's basically a thin functional interface wrapper over Perinci::CmdLine::Lite.

Because I'm lazy, it currently uses L<Perinci::Sub::Gen::FromClass> and adds a
bit of startup overhead. If you're concerned with startup overhead, you should
use Perinci::CmdLine::Lite directly.

=head1 FUNCTIONS


=head2 run_cmdline_app(%args) -> any

Arguments ('*' denotes required arguments):

=over 4

=item * B<actions> => I<any>

=item * B<cleanser> => I<any>

=item * B<common_opts> => I<any>

=item * B<completion> => I<any>

=item * B<config_dirs> => I<any>

=item * B<config_filename> => I<any>

=item * B<default_prompt_template> => I<any> (default: "Enter %s: ")

=item * B<default_subcommand> => I<any>

=item * B<description> => I<any>

=item * B<env_name> => I<any>

=item * B<exit> => I<any> (default: 1)

=item * B<extra_urls_for_version> => I<any>

=item * B<formats> => I<any>

=item * B<get_subcommand_from_arg> => I<any> (default: 1)

=item * B<log> => I<any>

=item * B<log_level> => I<any>

=item * B<pass_cmdline_object> => I<any> (default: 0)

=item * B<per_arg_json> => I<any>

=item * B<per_arg_yaml> => I<any>

=item * B<program_name> => I<any>

=item * B<read_config> => I<any> (default: 1)

=item * B<read_env> => I<any> (default: 1)

=item * B<riap_client> => I<any>

=item * B<riap_client_args> => I<any>

=item * B<riap_version> => I<any> (default: 1.1)

=item * B<skip_format> => I<any>

=item * B<subcommands> => I<any>

=item * B<summary> => I<any>

=item * B<tags> => I<any>

=item * B<url> => I<any>

=item * B<validate_args> => I<any> (default: 1)

=back

Return value:  (any)

=head1 STATUS

Experimental, proof of concept.

=head1 SEE ALSO

L<Perinci::CmdLine>, L<Perinci::CmdLine::Lite>, L<Perinci::CmdLine::Any>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-CmdLine-NonOO>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-CmdLine-NonOO>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-CmdLine-NonOO>

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
