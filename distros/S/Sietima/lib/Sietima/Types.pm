package Sietima::Types;
use Sietima::Policy;
use Type::Utils -all;
use Types::Standard qw(Str HashRef Defined Str);
use namespace::clean;
use Type::Library
    -base,
    -declare => qw(SietimaObj
                   Address AddressFromStr
                   TagName
                   EmailMIME Message
                   HeaderUri HeaderUriFromThings
                   Subscriber SubscriberFromAddress SubscriberFromStr SubscriberFromHashRef
                   Transport MailStore MailStoreFromHashRef);

our $VERSION = '1.1.4'; # VERSION
# ABSTRACT: type library for Sietima


class_type SietimaObj, { class => 'Sietima' };


class_type EmailMIME, { class => 'Email::MIME' };


role_type Transport, { role => 'Email::Sender::Transport' };


role_type MailStore, { role => 'Sietima::MailStore' };

declare_coercion MailStoreFromHashRef,
    to_type MailStore, from HashRef,
    q{ require Module::Runtime; } .
    q{ Module::Runtime::use_module(delete $_->{class})->new($_); };


class_type Address, { class => 'Email::Address' };
declare_coercion AddressFromStr,
    to_type Address, from Str,
    q{ (Email::Address->parse($_))[0] };


declare TagName, as Str,
    where { /\A\w+\z/ },
    inline_as sub($constraint,$varname,@){
        $constraint->parent->inline_check($varname)
            .qq{ && ($varname =~/\\A\\w+\\z/) };
    };


class_type Message, { class => 'Sietima::Message' };

class_type HeaderUri, { class => 'Sietima::HeaderURI' };

declare_coercion HeaderUriFromThings,
    to_type HeaderUri, from Defined,
q{ Sietima::HeaderURI->new($_) };


class_type Subscriber, { class => 'Sietima::Subscriber' };

declare_coercion SubscriberFromAddress,
    to_type Subscriber, from Address,
    q{ Sietima::Subscriber->new(primary=>$_) };

declare_coercion SubscriberFromStr,
    to_type Subscriber, from Str,
    q{ Sietima::Subscriber->new(primary=>(Email::Address->parse($_))[0]) };

declare_coercion SubscriberFromHashRef,
    to_type Subscriber, from HashRef,
    q{ Sietima::Subscriber->new($_) };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sietima::Types - type library for Sietima

=head1 VERSION

version 1.1.4

=head1 DESCRIPTION

This module is a L<< C<Type::Library> >>. It declares a few type
constraints nad coercions.

=head1 TYPES

=head2 C<SietimaObj>

An instance of L<< C<Sietima> >>.

=head2 C<EmailMIME>

An instance of L<< C<Email::MIME> >>.

=head2 C<Transport>

An object that consumes the role L<< C<Email::Sender::Transport> >>.

=head2 C<MailStore>

An object that consumes the role L<< C<Sietima::MailStore> >>.

Coercions:

=over

=item C<MailStoreFromHashRef>

  has store => ( isa => MailStore->plus_coercions(MailStoreFromHashRef) );

Using this coercion, a hashref of the form:

  {
    class => 'Some::Store::Class',
    %constructor_args,
  }

will be converted into an instance of C<Some::Store::Class> built with
the C<%constructor_args>.

=back

=head2 C<Address>

An instance of L<< C<Email::Address> >>.

Coercions:

=over

=item C<AddressFromStr>

  has address => ( isa => Address->plus_coercions(AddressFromStr) );

Using this coercion, a string will be parsed into an L<<
C<Email::Address> >>. If the string contains more than one address,
only the first one will be used.

=back

=head2 C<TagName>

A string composed exclusively of "word" (C</\w/>) characters. Used by
L<mail stores|Sietima::MailStore> to tag messages.

=head2 C<Message>

An instance of L<< C<Sietima::Message> >>.

=head2 C<Subscriber>

An instance of L<< C<Sietima::Subscriber> >>.

Coercions:

=over

=item C<SubscriberFromAddress>

  has sub => ( isa => Subscriber->plus_coercions(SubscriberFromAddress) );

Using this coercion, an L<< C<Email::Address> >> will be converted
into a subscriber that has that address as its primary.

=item C<SubscriberFromStr>

  has sub => ( isa => Subscriber->plus_coercions(SubscriberFromStr) );

Using this coercion, a string will be converted into a subscriber that
has the first address parsed from that string as its primary.

=item C<SubscriberFromHashRef>

  has sub => ( isa => Subscriber->plus_coercions(SubscriberFromHashRef) );

Using this coercion, a hashref will be converted into a subscriber by
passing it to the constructor.

=back

=head1 AUTHOR

Gianni Ceccarelli <dakkar@thenautilus.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Gianni Ceccarelli <dakkar@thenautilus.net>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
