package MozRepl::Client;

use strict;
use warnings;

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw/telnet connect_args extra_telnet_args/);

use Carp::Clan qw(croak);
use Data::Dump qw(dump);
use Net::Telnet;
use Text::SimpleTable;

=head1 NAME

MozRepl::Client - MozRepl client class using telnet.

=head1 VERSION

version 0.03

=cut

our $VERSION = '0.03';

=head1 METHODS

=head2 new($ctx, $args)

Create instance. two arguments.

=over 4

=item $ctx

Context object. see L<MozRepl>.

=item $args

Hash reference.

=over 4

=item host

Default value is "localhost".

=item port

Default value is 4242.

=item timeout

Default value is 10(sec).

=item extra_client_args

See L<Net::Telnet>'s new method arguments.

=back

=back

=cut

sub new {
    my ($class, $ctx, $args) = @_;

    $args->{host} ||= $ENV{MOZREPL_HOST} || 'localhost';
    $args->{port} ||= $ENV{MOZREPL_PORT} || 4242;
    $args->{timeout} ||= $ENV{MOZREPL_TIMEOUT} || 10;
    $args->{extra_client_args} ||= {};

    $args->{extra_client_args}->{binmode} = 1 if ($^O eq "cygwin");

    if ($ctx->log->is_debug) {
        my $table = Text::SimpleTable->new([20, 'client_arg_name'], [40, 'client_arg_value']);

        $table->row('host', $args->{host});
        $table->row('port', $args->{port});
        $table->row('timeout', $args->{timeout});
        $table->row('extra_client_args', dump($args->{extra_client_args}));

        $ctx->log->debug("---- Client arguments ----\n" . $table->draw);
    }

    my $self = $class->SUPER::new({
        telnet => Net::Telnet->new(%{$args->{extra_client_args}}),
        connect_args => {
            Host => $args->{host},
            Port => int($args->{port}),
            Timeout => int($args->{timeout})
        }
    });

    return $self;
}

=head2 setup($ctx, $args)

Two arguments.

=over 4

=item $ctx

Context object. see L<MozRepl>.

=item $args

Hash reference.

=over 4

=item host

Default value is "localhost".

=item port

Default value is 4242.

=item timeout

Default value is 10(sec).

=back

=back

=cut

sub setup {
    my ($self, $ctx, $args) = @_;

    my $telnet = $self->telnet;
    my %connect_args = %{$self->connect_args};

    $connect_args{Host} = $args->{host} if ($args->{host});
    $connect_args{Port} = int($args->{port}) if (defined $args->{port});
    $connect_args{Timeoout} = int($args->{timeout}) if (defined $args->{timeout} && $args->{timeout} > 0);

    unless ($telnet->open(%connect_args)) {
        my $message = q|Can't connect to | . sprintf("%s:%d", $connect_args{Host}, $connect_args{Port});
        # $ctx->log->fatal($message);
        croak($message);
    }

    # initialize repl object name and prompt pattern
    my @msg = $telnet->waitfor('/repl\d*> /');
    my $prompt =  pop @msg;
    $prompt = '/' . $prompt . '/';
    my ($repl) = ($prompt =~ m|(repl\d*)|);

    $ctx->log->debug('repl name: ' . $repl);

    $telnet->prompt($prompt);
    $ctx->repl($repl);
}

=head2 execute($ctx, $command)

Execute command and return result string or lines as array.

=over 4

=item $ctx

Context object. see L<MozRepl>.

=item $command

Command string.

=back

=cut

sub execute {
    my ($self, $ctx, $command) = @_;

    ### adhoc
    $command = join(" ", split(/\n/, $command)) if ($^O eq "cygwin");

    my $message = [map { chomp; $_ } $self->telnet->cmd(String => $command)];

    if ($ctx->log->is_debug) {
        my $table = Text::SimpleTable->new([10, 'type'], [40, 'content']);
        $table->row('command', $command);
        $table->row('result', join("\n", @$message));
        $ctx->log->debug($table->draw);
    }

    return wantarray ? @$message : join("\n", @$message);
}

=head2 prompt($prompt)

Telnet prompt string.

=cut

sub prompt {
    my ($self, $prompt) = @_;

    if ($prompt) {
        $self->telnet->prompt($prompt);
    }
    else {
        $self->telnet->prompt;
    }
}

=head2 quit()

Quit connection.

=cut

sub quit {
    my ($self, $ctx, $args) = @_;
    ### logging
    $self->telnet->quit;
}

=head1 SEE ALSO

=over 4

=item L<Net::Telnet>

=back

=head1 AUTHOR

Toru Yamaguchi, C<< <zigorou@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-mozrepl-client@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Toru Yamaguchi, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of MozRepl::Client
