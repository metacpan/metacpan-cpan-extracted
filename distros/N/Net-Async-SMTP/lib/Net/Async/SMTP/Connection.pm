package Net::Async::SMTP::Connection;

use strict;
use warnings;
use parent qw(IO::Async::Stream);

our $VERSION = '0.004'; ## VERSION
## AUTHORITY

=head1 NAME

Net::Async::SMTP::Connection - stream subclass for dealing with SMTP connections

=head1 DESCRIPTION

Used internally by L<Net::Async::SMTP>. No user-serviceable parts inside.

Timeouts:

RFC821 4.5.3.2 - An SMTP client MUST provide a timeout mechanism

greeting_timeout => 300,
mail_timeout => 300,
rcpt_timeout => 300,
data_timeout => 120,
data_block_timeout => 180,
data_finish_timeout => 600,

=cut

use IO::Socket::SSL qw(SSL_VERIFY_NONE);
use Protocol::SMTP::Client;

sub configure {
    my $self = shift;
    my %args = @_;
    $self->{auth} = delete $args{auth} if exists $args{auth};
    $self->SUPER::configure(%args)
}

sub _add_to_loop {
    my ($self, $loop) = @_;
    $self->{protocol} = Protocol::SMTP::Client->new(
        future_factory => sub { $loop->new_future },
        writer => sub { $self->write(@_) },
        auth_mechanism_override => $self->auth,
    );
    $self->protocol->startup;
    $self->SUPER::_add_to_loop($loop);
}

sub _remove_from_loop {
    my ($self, $loop) = @_;
    delete $self->{protocol};
    $self->SUPER::_remove_from_loop($loop);
}

sub auth { shift->{auth} }
sub protocol { shift->{protocol} }

sub send_greeting {
    my $self = shift;
    # Start with our greeting, which should receive back a nice list of features
    $self->protocol->send_greeting;
}

sub starttls {
    my $self = shift;
    my %args = @_;
    $self->debug_printf("STARTTLS");
    die "This server does not support TLS" unless $self->has_feature('STARTTLS');

    require IO::Async::SSL;
    $self->protocol->starttls->then(sub {
        $self->loop->SSL_upgrade(
            handle => $self,
            # SSL_verify_mode => SSL_VERIFY_NONE,
            %args,
        )->on_done(sub {
            $self->debug_printf("STARTTLS successful");
        })
         ->then($self->curry::send_greeting)
         ->transform(done => sub { $self });
    });
}

sub on_read {
    my ($self, $buffref) = @_;
    while( $$buffref =~ s/^(.*)\x0D\x0A// ) {
        my $line = $1;
        if($self->{sending_content}) {
            warn "- this is awkward; we shouldn't have anything because we're in the middle of sending: $1";
        } else {
            $self->protocol->handle_line($line);
        }
    }
    return 0;
}

sub has_feature { my $self = shift; $self->protocol->has_feature(@_) }
sub send { my $self = shift; $self->protocol->send(@_) }
sub login { my $self = shift; $self->protocol->login(@_) }
sub quit { my $self = shift; $self->protocol->quit(@_) }

1;

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2012-2024. Licensed under the same terms as Perl itself.

