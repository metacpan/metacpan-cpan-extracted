package Net::ADB::Shell::Result;

use strict;
use warnings;
use utf8;
use v5.16;

use Carp;

our $VERSION  = '0.01';
our @CARP_NOT = qw(Net::ADB Net::ADB::Device);

sub new {
    my ($class, %params) = @_;

    my $self = \%params;
    return bless $self, $class;
}

sub stdout    { shift->{stdout} }
sub stderr    { shift->{stderr} }
sub exit_code { shift->{exit} }
sub command   { shift->{command} }
sub duration  { shift->{duration} }

sub is_success { (shift->{exit} == 0) ? 1 : 0 }
sub is_error   { !shift->is_success }

sub _split {
    my ($self, $ch) = @_;
    my @lines = split /\n/, $self->{$ch};
    return wantarray ? @lines : \@lines;
}

sub lines        { shift->_split('stdout') }
sub stdout_lines { shift->_split('stdout') }
sub stderr_lines { shift->_split('stderr') }

sub assert_success {
    my $self = shift;
    return $self if $self->is_success;

    chomp(my $err = $self->stderr);
    Carp::croak(sprintf "Command '%s' failed (exit %d): %s", $self->{command}, $self->{exit}, $err);
}

sub TO_JSON {
    my $self = shift;
    return {
        stdout   => $self->{stdout},
        stderr   => $self->{stderr},
        exit     => $self->{exit},
        command  => $self->{command},
        duration => $self->{duration},
    };
}

1;

__END__

=encoding utf-8

=head1 NAME

Net::ADB::Shell::Result - Result of a shell command run on an Android device

=head1 SYNOPSIS

    use Net::ADB;

    my $adb = Net::ADB->new;
    my $res = $adb->shell_v2(command => 'ls /sdcard');

    if ($res->is_success) {
        say for $res->stdout_lines;
    }
    else {
        say STDERR $res->stderr;
    }

    say $res->exit_code;    # 0
    say $res->duration;     # 0.084

    # Croak unless the command succeeded
    my $output = $adb->shell_v2(command => 'getprop')->assert_success->stdout;


=head1 DESCRIPTION

L<Net::ADB::Shell::Result> holds the result of a command run with
L<Net::ADB/shell_v2> or L<Net::ADB::Device/shell>: output, error output,
exit code and duration.

The instance is a blessed hash reference, so the fields can also be read
directly (C<$res-E<gt>{stdout}>, C<$res-E<gt>{stderr}>, C<$res-E<gt>{exit}>).


=head1 CONSTRUCTOR

=head2 new

    my $res = Net::ADB::Shell::Result->new(
        command  => 'ls /sdcard',
        stdout   => "Download\nPictures\n",
        stderr   => '',
        exit     => 0,
        duration => 0.084
    );

Create a new L<Net::ADB::Shell::Result> instance. It is created by
L<Net::ADB/shell_v2>, so there is usually no need to call C<new> directly.

Allowed parameters:

=over

=item * C<command>, the command.

=item * C<stdout>, the output.

=item * C<stderr>, the error output.

=item * C<exit>, the exit code.

=item * C<duration>, the duration in seconds.

=back


=head1 METHODS

=head2 command

Return the command.

=head2 stdout

Return the output of the command, as bytes.

=head2 stderr

Return the error output of the command, as bytes.

=head2 exit_code

Return the exit code of the command (C<0> to C<255>).

=head2 duration

Return the duration of the call in seconds, with decimals. It includes the
connection to the ADB server and the transfer of the output, not only the
execution of the command.

=head2 is_success

Return C<1> if the exit code is C<0>, C<0> otherwise.

=head2 is_error

Return C<1> if the exit code is not C<0>, C<0> otherwise.

=head2 assert_success

    my $output = $res->assert_success->stdout;

Return the instance if the command succeeded, otherwise croak with the
command, the exit code and the error output:

    Command 'cat /no/such/file' failed (exit 1): cat: /no/such/file: No such file or directory

Note that some commands exit with a non-zero code in normal cases (e.g.
C<grep> with no match).

=head2 stdout_lines

    for my $line ($res->stdout_lines) { ... }

Return the lines of the output, without the newlines (an array reference in
scalar context).

=head2 lines

Alias of L</stdout_lines>.

=head2 stderr_lines

Return the lines of the error output, without the newlines (an array
reference in scalar context).

=head2 TO_JSON

Helper method for JSON modules (e.g. L<JSON::PP>).

    use JSON::PP;

    say JSON::PP->new->canonical->convert_blessed->encode($res);

    # {"command":"ls /sdcard","duration":0.084,"exit":0,"stderr":"","stdout":"Download\nPictures\n"}


=head1 SEE ALSO

=over

=item * L<Net::ADB>

=item * L<Net::ADB::Device>

=back


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-Net-ADB/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-Net-ADB>

    git clone https://github.com/giterlizzi/perl-Net-ADB.git


=head1 AUTHOR

=over

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2026 by Giuseppe Di Terlizzi.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
