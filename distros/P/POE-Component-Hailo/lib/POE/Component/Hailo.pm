package POE::Component::Hailo;
BEGIN {
  $POE::Component::Hailo::AUTHORITY = 'cpan:HINRIK';
}
BEGIN {
  $POE::Component::Hailo::VERSION = '0.10';
}

use 5.010;
use strict;
use warnings FATAL => 'all';
use Carp 'croak';
use Hailo;
use POE qw(Wheel::Run Filter::Reference);

sub spawn {
    my ($package, %args) = @_;

    croak "Hailo_args parameter missing" if ref $args{Hailo_args} ne 'HASH';
    my $options = delete $args{options};
    my $self = bless \%args, $package;

    $self->{response} = {
        learn       => 'hailo_learned',
        train       => 'hailo_trained',
        reply       => 'hailo_replied',
        learn_reply => 'hailo_learn_replied',
        stats       => 'hailo_stats',
        save        => 'hailo_saved',
    };

    POE::Session->create(
        object_states => [
            $self => [qw(
                _start
                shutdown
                _sig_DIE
                _sig_chld
                _go_away
                _child_stderr
                _child_stdout
            )],
            $self => {
                map { +$_ => '_hailo_method' } keys %{ $self->{response } },
            }
        ],
        (ref $options eq 'HASH' ? (options => $options) : ()),
    );

    return $self;
}

sub _start {
    my ($kernel, $session, $self) = @_[KERNEL, SESSION, OBJECT];
    $self->{session_id} = $session->ID();
    $kernel->sig(DIE => '_sig_DIE');

    if (defined $self->{alias}) {
        $kernel->alias_set($self->{alias});
    }
    else {
        $kernel->refcount_increment($self->{session_id}, __PACKAGE__);
    }

    $self->{wheel} = POE::Wheel::Run->new(
        Program     => \&_main,
        ProgramArgs => [ %{ $self->{Hailo_args} } ],
        StdoutEvent => '_child_stdout',
        StderrEvent => '_child_stderr',
        StdioFilter => POE::Filter::Reference->new,
        ( $^O eq 'MSWin32' ? ( CloseOnCall => 0 ) : ( CloseOnCall => 1 ) ),
    );

    $kernel->sig_child( $self->{wheel}->PID, '_sig_chld' );
    return;
}

sub _sig_DIE {
    my ($kernel, $self, $ex) = @_[KERNEL, OBJECT, ARG1];
    chomp $ex->{error_str};
    warn "Error: Event $ex->{event} in $ex->{dest_session} raised exception:\n";
    warn "  $ex->{error_str}\n";
    $kernel->sig_handled();
    return;
}

sub session_id {
    return $_[0]->{session_id};
}

sub _hailo_method {
    my ($kernel, $self, $state, $args, $context)
        = @_[KERNEL, OBJECT, STATE, ARG0, ARG1];
    my $sender = $_[SENDER]->ID();

    return if $self->{shutdown};

    $args //= [ ];
    $context = { %{ $context // { } } };
    my $request = {
        args    => $args,
        context => $context,
        method  => $state,
        sender  => $sender,
        event   => $self->{response}{$state},
    };

    $kernel->refcount_increment($sender, __PACKAGE__);
    $self->{wheel}->put($request);

    return;
}

sub _sig_chld {
    my ($kernel, $self) = @_[KERNEL, OBJECT];
    $kernel->yield('shutdown') if !$self->{shutdown};
    $kernel->yield('_go_away');
    $kernel->sig_handled();
    return;
}

sub _child_stderr {
    my ($kernel, $self, $input) = @_[KERNEL, OBJECT, ARG0];
    warn "$input\n";
    return;
}

sub _child_stdout {
    my ($kernel, $self, $input) = @_[KERNEL, OBJECT, ARG0];
    $kernel->post(@$input{qw(sender event result context)});
    $kernel->refcount_decrement($input->{sender}, __PACKAGE__);
    return;
}

sub shutdown {
    my ($self) = $_[OBJECT];
    $self->{shutdown} = 1;
    $self->{wheel}->shutdown_stdin;
    return;
}

sub _go_away {
    my ($kernel, $self) = @_[KERNEL, OBJECT];

    delete $self->{wheel};
    $kernel->alias_remove($_) for $kernel->alias_list();
    if (!defined $self->{alias}) {
        $kernel->refcount_decrement($self->{session_id}, __PACKAGE__);
    }
    return;
}

sub _main {
    my (%args) = @_;

    if ($^O eq 'MSWin32') {
        binmode STDIN;
        binmode STDOUT;
    }

    my $hailo;
    eval { $hailo = Hailo->new(%args) };
    if ($@) {
        chomp $@;
        warn "$@\n";
        return;
    }

    my $raw;
    my $size = 4096;
    my $filter = POE::Filter::Reference->new;

    while (sysread STDIN, $raw, $size) {
        my $requests = $filter->get([$raw]);
        for my $req (@$requests) {
            my $method = $req->{method};
            $req->{result} = [$hailo->$method(@{ $req->{args} })];
            my $response = $filter->put([$req]);
            print @$response;
        }
    }

    return;
}

1;

=encoding utf8

=head1 NAME

POE::Component::Hailo - A non-blocking wrapper around L<Hailo|Hailo>

=head1 SYNOPSIS

 use strict;
 use warnings;
 use POE qw(Component::Hailo);

 POE::Session->create(
     package_states => [
         (__PACKAGE__) => [ qw(_start hailo_learned hailo_replied) ],
     ],
 );

 POE::Kernel->run;

 sub _start {
     POE::Component::Hailo->spawn(
         alias      => 'hailo',
         Hailo_args => {
             storage_class  => 'SQLite',
             brain_resource => 'hailo.sqlite',
         },
     );

     POE::Kernel->post(hailo => learn =>
         ['This is a sentence'],
     );
 }

 sub hailo_learned {
     POE::Kernel->post(hailo => reply => ['This']);
 }

 sub hailo_replied {
     my $reply = $_[ARG0]->[0];
     die "Didn't get a reply" if !defined $reply;
     print "Got reply: $reply\n";
     POE::Kernel->post(hailo => 'shutdown');
 }

=head1 DESCRIPTION

POE::Component::Hailo is a L<POE|POE> component that provides a
non-blocking wrapper around L<Hailo|Hailo>. It accepts the events listed
under L</INPUT> and emits the events listed under L</OUTPUT>.

=head1 METHODS

=head2 C<spawn>

This is the constructor. It takes the following arguments:

B<'alias'>, an optional alias for the component's session.

B<'Hailo_args'>, a hash reference of arguments to pass to L<Hailo|Hailo>'s
constructor.

B<'options'>, a hash reference of options to pass to
L<POE::Session|POE::Session>'s constructor.

=head2 C<session_id>

Takes no arguments. Returns the POE Session ID of the component.

=head1 INPUT

This component reacts to the following POE events:

=head2 C<learn>

=head2 C<train>

=head2 C<reply>

=head2 C<learn_reply>

=head2 C<stats>

=head2 C<save>

All these events take two arguments. The first is an array reference of
arguments which will be passed to the L<Hailo|Hailo> method of the same
name. The second (optional) is a hash reference. You'll get this hash
reference back with the corresponding event listed under L</OUTPUT>.

=head2 C<shutdown>

Takes no arguments. Terminates the component.

=head1 OUTPUT

The component will post the following event to your session:

=head2 C<hailo_learned>

=head2 C<hailo_trained>

=head2 C<hailo_replied>

=head2 C<hailo_learn_replied>

=head2 C<hailo_stats>

=head2 C<hailo_saved>

C<ARG0> is an array reference of arguments returned by the underlying
L<Hailo|Hailo> method. C<ARG1> is the context hashref you provided (if any).

=head1 AUTHOR

Hinrik E<Ouml>rn SigurE<eth>sson, hinrik.sig@gmail.com

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Hinrik E<Ouml>rn SigurE<eth>sson

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
