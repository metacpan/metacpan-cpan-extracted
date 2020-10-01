package ScriptX::Getopt::Long;

use parent 'ScriptX_Base';

sub meta {
    return {
        summary => 'Parse command-line options using Getop::Long',
        conf => {
            spec => {
                summary => "Specification to be passed to Getopt::Long's GetOptions",
                schema => 'array*',
                req => 1,
            },
            abort_on_failure => {
                summary => 'Whether to abort script execution on GetOptions() failure',
                schema => 'bool*',
                default => 1,
            },
        },
    };
}

sub before_run {
    my ($self, $stash) = @_;

    my $abort_on_failure = $self->{abort_on_failure} // 1;

    require Getopt::Long;
    Getopt::Long::Configure("gnu_getopt", "no_ignore_case");
    my $res = Getopt::Long::GetOptions(@{ $self->{spec} });
    $res ? [200] : [$abort_on_failure ? 601 : 500, "GetOptions failed"];
}

1;
# ABSTRACT: Parse command-line options using Getop::Long

__END__

=pod

=encoding UTF-8

=head1 NAME

ScriptX::Getopt::Long - Parse command-line options using Getop::Long

=head1 VERSION

This document describes version 0.000004 of ScriptX::Getopt::Long (from Perl distribution ScriptX), released on 2020-10-01.

=head1 SYNOPSIS

 use ScriptX::Getopt::Long => {
     spec => [
         'foo=s' => sub { ... },
         'bar'   => sub { ... },
     ],
 };

=head1 DESCRIPTION

This plugin basically just configures L<Getopt::Long>:

 Getopt::Long::Configure("gnu_getopt", "no_ignore_case");

then pass the spec to C<GetOptions()>.

=head1 SCRIPTX PLUGIN CONFIGURATION

=head2 abort_on_failure

Bool. Optional. Whether to abort script execution on GetOptions() failure.

=head2 spec

Array. Required. Specification to be passed to Getopt::Long's GetOptions.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/ScriptX>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-ScriptX>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=ScriptX>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Getopt::Long>

L<ScriptX::Getopt::Specless>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
