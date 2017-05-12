package Tapper::Action;
# git description: v4.1.1-14-g65e3f23

our $AUTHORITY = 'cpan:TAPPER';
# ABSTRACT: Tapper - Daemon and plugins to handle MCP actions
$Tapper::Action::VERSION = '5.0.0';
use 5.010;
use warnings;
use strict;

use Moose;
use Tapper::Model 'model';
use Tapper::Config;
use YAML::Syck 'Load';
use Try::Tiny;
use Class::Load ':all';

extends 'Tapper::Base';

has cfg => (is => 'rw', default => sub { Tapper::Config->subconfig} );


sub get_messages
{
        my ($self) = @_;

        my $messages;
        while () {
                $messages = model('TestrunDB')->resultset('Message')->search({type => 'action'});
                last if ($messages and $messages->count);
                sleep $self->cfg->{times}{action_poll_intervall} || 1;
        }
        return $messages;
}


sub loop
{
        my ($self) = @_;

#        my $x=model('TestrunDB')->resultset('Host');
        try {
        ACTION:
                while (my $messages = $self->get_messages) {
                        while (my $message = $messages->next) {
                                if (my $action = $message->message->{action}) {
                                        my $plugin         = $self->cfg->{action}{$action}{plugin};
                                        my $plugin_options = $self->cfg->{action}{$action}{plugin_options};
                                        my $plugin_class   = "Tapper::Action::Plugin::${action}::${plugin}";
                                        load_class($plugin_class);

                                        if ($@) {
                                                $self->log->error( "Could not load $plugin_class: $@" );
                                        } else {
                                                try{
                                                        no strict 'refs'; ## no critic
                                                        $self->log->info("Call ${plugin_class}::execute()");
                                                        &{"${plugin_class}::execute"}($self, $message->message, $plugin_options);
                                                } catch {
                                                        $self->log->error("Error occured: $_");
                                                }
                                        }
                                }
                                $message->delete;
                        }
                }
        } catch {
                say STDERR "Caught exception $_";
                $self->log->error("Caugth exception: $_");
        };
        return;
}

1; # End of Tapper::Action

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Action - Tapper - Daemon and plugins to handle MCP actions

=head1 SYNOPSIS

There are a few actions that Tapper assigns to an external daemon. This
includes for example restarting a test machine that went to sleep during
ACPI tests. This module is the base for a daemon that executes these
assignments.

    use Tapper::Action;

    my $daemon = Tapper::Action->new();
    $daemon->run();

=head1 FUNCTIONS

=head2 get_messages

Read all pending messages from database. Try no more than timeout seconds

@return success - Resultset class containing all available messages

=head2 loop

Run the Action daemon loop.

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
