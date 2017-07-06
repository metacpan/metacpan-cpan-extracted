package Sietima::MailStore;
use Moo::Role;
use Sietima::Policy;
use namespace::clean;

our $VERSION = '1.0.3'; # VERSION
# ABSTRACT: interface for mail stores


requires 'store',
    'retrieve_ids_by_tags','retrieve_by_tags','retrieve_by_id',
    'remove','clear';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sietima::MailStore - interface for mail stores

=head1 VERSION

version 1.0.3

=head1 DESCRIPTION

This role defines the interface that all mail stores must adhere
to. It does not provide any implementation.

=head1 REQUIRED METHODS

=head2 C<store>

  my $id = $ms->store($email_mime_object,@tags);

Must persistently store the given email message (as an L<<
C<Email::Simple> >> object or similar), associating it with the gives
tags (which must be strings). Must return a unique identifier for the
stored message. It is acceptable if identical messages are
indistinguishable by the storage.

=head2 C<retrieve_by_id>

  my $email_mime_object = $ms->retrieve_by_id($id);

Given an identifier returned by L<< /C<store> >>, this method must
return the email message (as an L<< C<Email::Simple> >> or L<<
C<Email::MIME> >> object).

If the message has been deleted, or the identifier is not recognised,
this method must return C<undef> in scalar context.

=head2 C<retrieve_ids_by_tags>

  my @ids = $ms->retrieve_ids_by_tags(@tags)->@*;

Given a list of tags (which must be strings), this method must return
an arrayref containing the identifiers of all (and only) the messages
that were stored associated with (at least) all those tags. The order
of the returned identifiers is not important.

If there are no messages associated with the given tags, this method
must return an empty arrayref.

For example:

 my $id1 = $ms->store($msg1,'t1');
 my $id2 = $ms->store($msg2,'t2');
 my $id3 = $ms->store($msg3,'t1','t2');

 $ms->retrieve_ids_by_tags('t1') ==> [ $id3, $id1 ]
 $ms->retrieve_ids_by_tags('t2') ==> [ $id2, $id3 ]
 $ms->retrieve_ids_by_tags('t1','t2') ==> [ $id3 ]
 $ms->retrieve_ids_by_tags('t3') ==> [ ]

=head2 C<retrieve_by_tags>

  my @email_mime_objects = $ms->retrieve_by_tags(@tags)->@*;

This method is similar to L<< /C<retrieve_ids_by_tags> >>, but it must
return an arrayref of hashrefs. For example:

 my $id1 = $ms->store($msg1,'t1');
 my $id2 = $ms->store($msg2,'t2');
 my $id3 = $ms->store($msg3,'t1','t2');

 $ms->retrieve_ids_by_tags('t1') ==> [
   { id => $id3, mail => $msg3 },
   { id => $id1, mail => $msg1 },
  ]

=head2 C<remove>

  $ms->remove($id);

This method must remove the message corresponding to the given
identifier from the persistent storage. Removing a non-existent
message must succeed, and do nothing.

=head2 C<clear>

  $ms->clear();

This method must remove all messages from the persistent
storage. Clearing an empty store must succeed, and do nothing.

=head1 AUTHOR

Gianni Ceccarelli <dakkar@thenautilus.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gianni Ceccarelli <dakkar@thenautilus.net>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
