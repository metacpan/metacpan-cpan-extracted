package POE::Component::Lingua::Translate;
BEGIN {
  $POE::Component::Lingua::Translate::AUTHORITY = 'cpan:HINRIK';
}
BEGIN {
  $POE::Component::Lingua::Translate::VERSION = '0.06';
}

use strict;
use warnings FATAL => 'all';
use Carp;
use POE;
use POE::Component::Generic;

sub new {
    my ($package, %args) = @_;
    my $self = bless { }, $package;
    $self->{alias} = delete $args{alias} if $args{alias};
    $self->{trans_args} = \%args;
    
    POE::Session->create(
        object_states => [
            $self => {
                # public events
                translate => '_translate',
                shutdown => '_shutdown',
            },
            $self => [ qw(_start _stop _result) ],
        ],
    );

    return $self;
}

sub _start {
    my ($session, $self) = @_[SESSION, OBJECT];
    $self->{session_id} = $session->ID();

    if ( $self->{alias} ) {
        $poe_kernel->alias_set( $self->{alias} );
    }
    else {
        $poe_kernel->refcount_increment( $self->{session_id} => __PACKAGE__ );
    }

    $self->{trans} = POE::Component::Generic->spawn(
        package        => 'Lingua::Translate',
        object_options => [ %{ $self->{trans_args} } ],
        methods        => [ qw(translate) ],
        verbose        => 1,
    );
  
    return;
}

sub _stop {
    return;
}

sub _shutdown {
    my $self = $_[OBJECT];
    $poe_kernel->alias_remove( $_ ) for $poe_kernel->alias_list();
    $poe_kernel->refcount_decrement( $self->{session_id} => __PACKAGE__ ) if !$self->{alias};
    return;
}

sub _translate {
    my ($self, $sender, $text, $context) = @_[OBJECT, SENDER, ARG0, ARG1];

    $self->{trans}->yield(
        translate =>
            {
                event => '_result',
                data => {
                    recipient => $sender->ID(),
                    context => $context || { },
                },
            },
            $text,
    );
    return;
}

sub _result {
    my ($ref, $result) = @_[ARG0, ARG1];

    my ($recipient, $context) = @{ $ref->{data} }{ qw(recipient context) };
    $poe_kernel->post(
        $recipient,
        'translated',
        $result,
        $context,
        ($ref->{error} ? $ref->{error} : ())
    );
    
    return;
}

sub session_id {
    my ($self) = @_;
    return $self->{session_id};
}

1;

=encoding utf8

=head1 NAME

POE::Component::Lingua::Translate - A non-blocking wrapper around L<Lingua::Translate|Lingua::Translate>

=head1 SYNOPSIS

 use POE;
 use POE::Component::Lingua::Translate;

 POE::Session->create(
     package_states => [
         main => [ qw(_start translated) ],
     ],
 );

 $poe_kernel->run();

 sub _start {
     my $heap = $_[HEAP];
     $heap->{trans} = POE::Component::Lingua::Translate->new(
         alias => 'translator',
         back_end => 'Babelfish',
         src      => 'en',
         dest     => 'de',
     );
     
     $poe_kernel->post(translator => translate => 'This is a sentence');
     return;
 }

 sub translated {
     my $result = $_[ARG0];
     # prints 'Dieses ist ein Satz'
     print $result . "\n";
 }

=head1 DESCRIPTION

POE::Component::Lingua::Translate is a L<POE> component that provides a
non-blocking wrapper around L<Lingua::Translate|Lingua::Translate>. It accepts
C<translate> events and emits C<translated> events back.

=head1 CONSTRUCTOR

=over

=item C<new>

Arguments

'alias', an optional alias for the component's session.

Any other arguments will be passed verbatim to L<Lingua::Translate|Lingua::Translate>'s
constructor.

=back

=head1 METHODS

=over

=item C<session_id>

Takes no arguments. Returns the POE Session ID of the component.

=back

=head1 INPUT

The POE events this component will accept.

=over

=item C<translate>

The first argument should be a string containing some text to translate. The
second argument (optional) can be a hash reference containing some context
information. You'll get this hash reference back with the C<translated> event.

=item C<shutdown>

Takes no arguments, terminates the component.

=back

=head1 OUTPUT

The POE events emitted by this component.

=over

=item C<translated>

ARG0 is the translated text. ARG1 is the context hashref from C<translate>. If
there was an error, ARG2 will be the error string.

=back

=head1 AUTHOR

Hinrik E<Ouml>rn SigurE<eth>sson, hinrik.sig@gmail.com

=head1 LICENSE AND COPYRIGHT

Copyright 2008 Hinrik E<Ouml>rn SigurE<eth>sson

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
