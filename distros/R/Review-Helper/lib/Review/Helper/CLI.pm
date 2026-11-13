package Review::Helper::CLI;
use v5.36;

our $VERSION = '0.001';

use Encode qw/decode FB_CROAK LEAVE_SRC/;

# Subcommand => class implementing it. Classes load only when their
# subcommand runs.
my %COMMANDS = (
    build     => 'Review::Helper::CLI::Build',
    close     => 'Review::Helper::CLI::Close',
    export    => 'Review::Helper::CLI::Export',
    feedback  => 'Review::Helper::CLI::Feedback',
    fill      => 'Review::Helper::CLI::Fill',
    import    => 'Review::Helper::CLI::Import',
    iterate   => 'Review::Helper::CLI::Iterate',
    list      => 'Review::Helper::CLI::List',
    note      => 'Review::Helper::CLI::Note',
    prune     => 'Review::Helper::CLI::Prune',
    published => 'Review::Helper::CLI::Published',
    serve     => 'Review::Helper::CLI::Serve',
    sheet     => 'Review::Helper::CLI::Sheet',
    skills    => 'Review::Helper::CLI::Skills',
    version   => 'Review::Helper::CLI::Version',
);

# Option values are text bound for JSON, SQLite and git, so they become
# characters here. Positional arguments and these options name files or
# commands, and Perl's file operations and exec take them as the bytes given.
my %PATH_OPTIONS = map { ($_ => 1) } qw/file out port_command/;

sub run($class, @args) {
    unless (@args) {
        print STDERR $class->usage;
        return 1;
    }

    # Anything that is not a subcommand is a review file to serve.
    my $command = exists $COMMANDS{$args[0]} ? shift(@args) : 'serve';

    my $command_class = $COMMANDS{$command};

    my $ok  = eval { $class->run_command($command_class, @args); 1 };
    my $err = $@;
    return 0 if $ok;

    print STDERR "review-helper $command: $err";
    return 1;
}

sub usage($class) {
    my $commands = join ', ' => sort keys %COMMANDS;
    return "Usage: review-helper <command> [options] [arguments]\n       review-helper <review-file>\nCommands: $commands\n";
}

sub run_command($class, $command_class, @args) {
    require(($command_class =~ s{::}{/}gr) . '.pm');

    # A lone '-' means standard input. The option parser would reject it as
    # an option, so it stops parsing there and is passed on as an argument.
    my $state = $command_class->options->process_args(\@args, skip_non_opts => 1, stops => ['--', '-']);
    my @rest  = @{$state->remains // []};
    unshift @rest => '-' if ($state->stop // '') eq '-';
    my $settings = $state->settings;
    $class->decode_settings($settings);
    $command_class->run($settings, @{$state->skipped}, @rest);

    return;
}

sub decode_settings($class, $settings) {
    for my $group (values %$settings) {
        for my $name (grep { !$PATH_OPTIONS{$_} } keys %$group) {
            my $value = $group->{$name};
            if (ref($value) eq 'ARRAY') {
                $_ = $class->decode_arg($name, $_) for @$value;
            }
            elsif (!ref($value)) {
                $group->{$name} = $class->decode_arg($name, $value);
            }
        }
    }

    return;
}

sub decode_arg($class, $name, $bytes) {
    return undef unless defined $bytes;
    my $text;
    my $ok = eval { $text = decode('UTF-8', $bytes, FB_CROAK | LEAVE_SRC); 1 };
    die "The value of --" . ($name =~ tr/_/-/r) . " is not valid UTF-8\n" unless $ok;
    return $text;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Review::Helper::CLI - The review-helper command.

=head1 DESCRIPTION

Parses the command line of C<review-helper> and runs one subcommand. A first
argument that names no subcommand is taken as a review file to serve.

Each subcommand is a class, such as L<Review::Helper::CLI::Note>, that
declares its options with L<Getopt::Yath> and provides
C<< run($settings, @args) >>. Options may appear anywhere after the
subcommand name; the remaining arguments, including everything after C<-->,
are passed to C<run> in order. A lone C<-> (standard input) is an argument;
options after it are not parsed.

Option values are decoded from UTF-8 before the subcommand sees them: they
are text, such as note sentences, titles, revisions and path specs. Positional
arguments and the C<--file>, C<--out> and C<--port-command> options name files
or commands and are passed on as given, as bytes.

Output goes to standard output. Errors go to standard error, prefixed with the
subcommand, and give a non-zero exit code.

=head1 SYNOPSIS

    use Review::Helper::CLI;

    exit(Review::Helper::CLI->run(@ARGV));

=head1 PUBLIC METHODS

=over 4

=item $exit = Review::Helper::CLI->run(@args)

Run the command line C<@args> and return the exit code: 0 on success, 1 on
any error.

=item $text = Review::Helper::CLI->usage()

The usage message printed when no arguments are given.

=item Review::Helper::CLI->run_command($command_class, @args)

Load C<$command_class>, parse its options out of C<@args>, and call its
C<run>. Dies on invalid options or when the subcommand fails.

=item Review::Helper::CLI->decode_settings($settings)

Decode every parsed option value from UTF-8 to characters, in place, except
C<--file>, C<--out> and C<--port-command>. Dies when a value is not valid UTF-8.

=item $text = Review::Helper::CLI->decode_arg($name, $bytes)

Decode one value of option C<$name> from UTF-8. Returns undef for undef.

=back

=head1 SOURCE

The source code repository for Review-Helper can be found at
L<https://github.com/exodist/Review-Helper>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
