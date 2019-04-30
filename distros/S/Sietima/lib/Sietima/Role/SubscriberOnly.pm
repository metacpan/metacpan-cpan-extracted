package Sietima::Role::SubscriberOnly;
use Moo::Role;
use Sietima::Policy;
use Email::Address;
use List::AllUtils qw(any);
use Types::Standard qw(Object CodeRef);
use Type::Params qw(compile);
use namespace::clean;

our $VERSION = '1.0.5'; # VERSION
# ABSTRACT: base role for "closed" lists


requires 'munge_mail_from_non_subscriber';

our $let_it_pass=0; ## no critic(ProhibitPackageVars)


around munge_mail => sub ($orig,$self,$mail) {
    my ($from) = Email::Address->parse( $mail->header_str('from') );
    if ( $let_it_pass or
             any { $_->match($from) } $self->subscribers->@* ) {
        $self->$orig($mail);
    }
    else {
        $self->munge_mail_from_non_subscriber($mail);
    }
};


sub ignoring_subscriberonly($self,$code) {
    state $check = compile(Object,CodeRef); $check->(@_);

    local $let_it_pass = 1;
    return $code->($self);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sietima::Role::SubscriberOnly - base role for "closed" lists

=head1 VERSION

version 1.0.5

=head1 SYNOPSIS

  package Sietima::Role::SubscriberOnly::MyPolicy;
  use Moo::Role;
  use Sietima::Policy;

  sub munge_mail_from_non_subscriber($self,$mail) { ... }

=head1 DESCRIPTION

This is a base role; in other words, it's not useable directly.

This role should be used when defining policies for "closed" lists:
lists that accept messages from subscribers, but do something special
with messages from non-subscribers.

See L<< C<Sietima::Role::SubscriberOnly::Drop> >> and L<<
C<Sietima::Role::SubscriberOnly::Moderate> >> for useable roles.

=head1 REQUIRED METHODS

=head2 C<munge_mail_from_non_subscriber>

  sub munge_mail_from_non_subscriber($self,$mail) { ... }

This method will be invoked from L<< C<munge_mail>|Sietima/munge_mail
>> whenever an email is processed that does not come from one of the
list's subscribers. This method should return a (possibly empty) list
of L<< C<Sietima::Message> >> objects, just like C<munge_mail>. It can
also have side-effects, like forwarding the email to the owner of the
list.

=head1 METHODS

=head2 C<ignoring_subscriberonly>

  $sietima->ignoring_subscriberonly(sub($s) {
    $s->handle_mail($mail);
  });

This method provides a way to run Sietima ignoring the "subscriber
only" beaviour. Your coderef will be passed a Sietima object that will
behave exactly as the invocant of this method, minus this role's
modifications.

=head1 MODIFIED METHODS

=head2 C<munge_mail>

If the incoming email's C<From:> header contains an address that
L<matches|Sietima::Subscriber/match> any of the subscribers, the email
is processed normally. Otherwise, L<<
/C<munge_mail_from_non_subscriber> >> is invoked.

=head1 AUTHOR

Gianni Ceccarelli <dakkar@thenautilus.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gianni Ceccarelli <dakkar@thenautilus.net>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
