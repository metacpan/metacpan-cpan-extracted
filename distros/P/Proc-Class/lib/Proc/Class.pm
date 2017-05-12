package Proc::Class;
use strict;
use warnings;
use Any::Moose;
our $VERSION = '0.05';
use 5.008001;
our @EXPORT = qw/test_script/;
use Proc::Class::Status;
use IPC::Open3 ();

has stdin => (
    is => 'rw',
);

has stdout => (
    is => 'rw',
);

has stderr => (
    is => 'rw',
);

has pid => (
    is => 'rw',
    isa => 'Int',
);

has cmd => (
    is => 'ro',
    isa => 'Str',
);

has env => (
    is => 'ro',
    isa => 'HashRef',
    default => sub { \%ENV },
);

has argv => (
    is => 'ro',
    isa => 'ArrayRef',
    default => sub { +[] },
);

sub BUILD {
    my $self = shift;

    local %ENV = (%ENV, %{ $self->env });

    my ($in, $out, $err);
    my $pid = IPC::Open3::open3($in, $out, $err, $self->cmd, @{ $self->argv });
    $self->pid($pid);
    $self->stdin($in);
    $self->stdout($out);
    $self->stderr($err);
}

sub print_stdin {
    my ($self, $txt) = @_;
    my $fh = $self->{stdin};
    print $fh $txt;
}

sub close_stdin {
    my $self = shift;
    close $self->{stdin};
}

sub slurp_stdout {
    my ($self, $expected) = @_;
    my $fh = $self->stdout;
    my $got = join '', <$fh>;
    return $got;
}

sub slurp_stderr {
    my ($self, $expected) = @_;
    my $fh = $self->stderr;
    if ($fh) {
        my $got = join '', <$fh>;
        return $got;
    } else {
        return '';
    }
}

sub waitpid {
    my $self = shift;
    waitpid($self->{pid}, 0);
    return Proc::Class::Status->new(status => $?);
}

sub kill {
    my ($self, $signal) = @_;
    $signal ||= 'TERM';
    kill $signal, $self->pid;
}

no Any::Moose;
__PACKAGE__->meta->make_immutable;
__END__

=head1 NAME

Proc::Class - OO interface for process management

=head1 SYNOPSIS

    use Test::More tests => 4;
    use Proc::Class;

    my $script = Proc::Class->spawn(
        cmd  => '/path/to/script/qmail/foo.pl',
        env  => {DEFAULT => "TOKEN"},
        argv => [qw/--dump/],
    );
    $script->print_stdin($mail->body);
    $script->close_stdin();
    is $script->slurp_stdout(), '';
    is $script->slurp_stderr(), '';

    my $status = $script->waitpid;
    ok $status->is_exited();
    is $status->exit_status(), 0;

=head1 DESCRIPTION

Proc::Class is a simple OO wrapper for IPC::Open3, POSIX.pm, and more.

B<THIS MODULE IS IN ITS BETA QUALITY. THE API MAY CHANGE IN THE FUTURE>

=head1 METHODS

=over 4

=item my $script = Proc::Class->new( cmd => '/path/to/script', env => \%env, argv => \@args );

create a new script object.

=item $script->print_stdin($txt);

pass $txt to child process' STDIN

=item $script->close_stdin();

close child process' *STDIN.

=item my $txt = $script->slurp_stdout();

slurp() from child process' *STDOUT.

=item my $txt = $script->slurp_stderr();

slurp() from child process' *STDERR.

=item my $txt = $script->slurp_stderr();

slurp() from child process' *STDERR.

=item my $status = $script->waitpid();

Waits for a particular child process to terminate and returns the pid of the deceased process.
Returns Proc::Class::Status object.

=item $script->kill('TERM');

Send signal to the process.

=back

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom  slkjfd gmail.comE<gt>

=head1 SEE ALSO

L<Proc::Open3>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
