package ScriptX::Debug::DumpStash;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-09-03'; # DATE
our $DIST = 'ScriptX'; # DIST
our $VERSION = '0.000001'; # VERSION

use parent 'ScriptX::Base';

sub meta {
    return {
        summary => 'Dump stash',
    };
}

sub meta_before_run { +{prio=>99} }
sub before_run {
    my ($self, $stash) = @_;
    {
        eval { require Data::Dump::Color; Data::Dump::Color::dd($stash) };
        last unless $@;
        eval { require Data::Dump; Data::Dump::dd($stash) };
        last unless $@;
        require Data::Dumper; print Data::Dumper->new([$stash], ["stash"])->Purity(1)->Dump;
    }
    [200, "OK"];
}

1;
# ABSTRACT: Dump stash

__END__

=pod

=encoding UTF-8

=head1 NAME

ScriptX::Debug::DumpStash - Dump stash

=head1 VERSION

This document describes version 0.000001 of ScriptX::Debug::DumpStash (from Perl distribution ScriptX), released on 2020-09-03.

=head1 DESCRIPTION

By default, stash is dumped right before run (event C<before_run>, prio 99). You
can dump at other events using the import syntax:

 use ScriptX 'Debug::DumpStash@after_run';
 use ScriptX 'Debug::DumpStash@after_run@99';

on the command-line perl option:

 -MScriptX=-Debug::DumpStash@after_run
 -MScriptX=-Debug::DumpStash@after_run@99

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/ScriptX>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-ScriptX>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=ScriptX>

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
