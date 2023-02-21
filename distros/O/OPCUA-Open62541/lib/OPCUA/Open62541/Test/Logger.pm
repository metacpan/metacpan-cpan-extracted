use strict;
use warnings;

package OPCUA::Open62541::Test::Logger;
use Carp;
use POSIX;
use Time::HiRes qw(gettimeofday time sleep);

use Test::More;

sub planning {
    # number of ok(), pass() and fail() calls in this code
    return 2;
}

sub new {
    my $class = shift;
    my $self = { @_ };
    $self->{logger}
	or croak "$class logger not given";
    $self->{ident} ||= "OPC UA";

    return bless($self, $class);
}

sub writelog {
    my ($context, $level, $category, $message) = @_;
    my OPCUA::Open62541::Test::Logger $self = $context;

    note "$self->{ident} $level/$category: $message";
    $self->{fh}->printf("%d.%06d %s/%s: %s\n",
	gettimeofday(), $level, $category, $message);
    $self->{fh}->flush();
}

sub file {
    my OPCUA::Open62541::Test::Logger $self = shift;
    my $file = shift;

    ok(open(my $fh, '>', $file), "logger: file open") or do {
	diag "open '$file' for writing failed: $!";
	return;
    };
    $self->{logger}->setCallback(\&writelog, $self, undef);
    $self->{file} = $file;
    $self->{fh} = $fh;
}

sub pid {
    my OPCUA::Open62541::Test::Logger $self = shift;
    $self->{pid} = shift if @_;
    return $self->{pid};
}

sub loggrep {
    my OPCUA::Open62541::Test::Logger $self = shift;
    my ($regex, $timeout, $count) = @_;

    my $end;
    $end = time() + $timeout if $timeout;

    my $file = $self->{file};
    my $pid = $self->{pid};
    do {
	my $kid;
	if ($pid) {
	    $kid = waitpid($pid, WNOHANG);
	    if ($kid > 0 && $? != 0) {
		# child terminated with failure
		fail "logger: loggrep match" or diag "child '$pid' failed: $?";
		return;
	    }
	}
	open(my $fh, '<', $file) or do {
	    fail "logger: loggrep match"
		or diag "open '$file' for reading failed: $!";
	    return;
	};
	my @match = grep { /$regex/ } <$fh>;
	if (!$count && @match or $count && @match >= $count) {
	    pass "logger: loggrep match";
	    return wantarray ? @match : $match[0]
	}
	close($fh);
	# pattern not found
	if (!$pid) {
	    # no child, no new log data possible
	    fail "logger: loggrep match" or diag "no child running";
	    return;
	} elsif ($kid == 0) {
	    # child still running, wait for log data
	    sleep .1;
	} else {
	    # child terminated, no new log data possible
	    fail "logger: loggrep match" or diag "child '$pid' terminated";
	    return;
	}
    } while ($timeout and time() < $end);

    fail "logger: loggrep match" or diag "regex '$regex' not found";
    return;
}

1;

__END__

=pod

=head1 NAME

OPCUA::Open62541::Test::Logger - manage open62541 log file for testing

=head1 SYNOPSIS

  use OPCUA::Open62541::Test::Logger;

  my $logger = OPCUA::Open62541::Test::Server->logger();

=head1 DESCRIPTION

Write the output of a server into a log file.
Wait until a given regular expression matches a line in the file.

=head2 METHODS

=over 4

=item $logger = OPCUA::Open62541::Test::Logger->new(%args);

Create a new test logger instance.
Usually called from test server.

=over 8

=item $args{logger}

Required logger instance of the client or server config.

=back

=item $logger->file($file)

Start writing to log file.

=item $logger->loggrep($regex, $timeout, $count)

Check if regex is present in the log file.
If the process is still alive and a timeout is given, repeat the
check for the number of seconds.
If count is given, wait for this number of matches.
Returns the number of matches.

=item $logger->pid($pid)

Optionally set the id of the process that is writing to log file.
When grepping it will not wait for more input if the process is dead.
Returns the pid.

=back

=head1 SEE ALSO

OPCUA::Open62541,
OPCUA::Open62541::Test::Server

=head1 AUTHORS

Alexander Bluhm E<lt>bluhm@genua.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2020-2023 Alexander Bluhm

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Thanks to genua GmbH, https://www.genua.de/ for sponsoring this work.

=cut
