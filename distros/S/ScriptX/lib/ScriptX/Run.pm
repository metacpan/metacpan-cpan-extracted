package ScriptX::Run;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-09-03'; # DATE
our $DIST = 'ScriptX'; # DIST
our $VERSION = '0.000001'; # VERSION

use strict;
use Log::ger;

use parent 'ScriptX::Base';

sub meta {
    return {
        summary => "Run something (code, command) in the 'run' event",
        description => <<'_',

You can give this plugin a coderef (`code`), or a command (`command`). Or you
can also define `run()` in your `main` package.

_
        conf => {
            code => {
                schema => 'code*',
                description => <<'_',

Code will get the plugin's instance as the first argument and stash as the
second:

    ($self, $stash)

_
            },
            command => {
                schema => ['any*', of=>['str*', 'array*']],
                description => <<'_',

Will be run using <pm:IPC::System::Options>'s `system`. Note that you can pass
options to IPC::System::Option via hashref as the first element in the array
argument, for example:

    [{die=>1, log=>1}, 'ls']

_
            },
        },
        conf_rels => {
            choose_one => ['conf', 'command'],
        },
    };
}

sub on_run {
    my ($self, $stash) = @_;

    if (my $code = $self->{code}) {
        log_trace "[ScriptX::Run] Running code";
        $code->($self, $stash);
    } elsif (defined(my $command = $self->{command})) {
        log_trace "[ScriptX::Run] Running command";
        require IPC::System::Options;
        IPC::System::Options::system(
            ref $command eq 'ARRAY' ? @$command : $command);
    } elsif (defined &{"main::run"}) {
        log_trace "[ScriptX::Run] Running main::run()";
        main::run($self, $stash);
    } else {
        die "Don't know what to run. Give me 'code', or 'command', ".
            "or define main::run().";
    }

    [200, "OK"];
}

1;
# ABSTRACT: Run something (code, command) in the 'run' event

__END__

=pod

=encoding UTF-8

=head1 NAME

ScriptX::Run - Run something (code, command) in the 'run' event

=head1 VERSION

This document describes version 0.000001 of ScriptX::Run (from Perl distribution ScriptX), released on 2020-09-03.

=head1 DESCRIPTION

=head1 CONFIGURATION

=head2 code

Code. Optional. 

Code will get the plugin's instance as the first argument and stash as the
second:

 ($self, $stash)


=head2 command

Any. Optional. 

Will be run using L<IPC::System::Options>'s C<system>. Note that you can pass
options to IPC::System::Option via hashref as the first element in the array
argument, for example:

 [{die=>1, log=>1}, 'ls']

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
