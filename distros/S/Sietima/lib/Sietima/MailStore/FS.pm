package Sietima::MailStore::FS;
use Moo;
use Sietima::Policy;
use Types::Path::Tiny qw(Dir);
use Types::Standard qw(Object ArrayRef Str Slurpy);
use Type::Params -sigs;
use Sietima::Types qw(EmailMIME TagName);
use Digest::SHA qw(sha1_hex);
use namespace::clean;

our $VERSION = '1.1.4'; # VERSION
# ABSTRACT: filesystem-backed email store


with 'Sietima::MailStore';


has root => (
    is => 'ro',
    required => 1,
    isa => Dir,
    coerce => 1,
);

has [qw(_tagdir _msgdir)] => ( is => 'lazy' );
sub _build__tagdir($self) { $self->root->child('tags') }
sub _build__msgdir($self) { $self->root->child('msgs') }

sub BUILD($self,@) {
    $self->$_->mkpath for qw(_tagdir _msgdir);
    return;
}


signature_for store => (
    method => Object,
    positional => [
        EmailMIME,
        Slurpy[ArrayRef[TagName]],
    ],
);
sub store($self,$mail,$tags) {

    my $str = $mail->as_string;
    my $id = sha1_hex($str);

    $self->_msgdir->child($id)->spew_raw($str);

    $self->_tagdir->child($_)->append("$id\n") for $tags->@*;

    return $id;
}


signature_for retrieve_by_id => (
    method => Object,
    positional => [ Str ],
);
sub retrieve_by_id($self,$id) {
    my $msg_path = $self->_msgdir->child($id);
    return unless -e $msg_path;
    return Email::MIME->new($msg_path->slurp_raw);
}


sub _tagged_by($self,$tag) {
    my $tag_file = $self->_tagdir->child($tag);
    return unless -e $tag_file;
    return $tag_file->lines({chomp=>1});
}

signature_for retrieve_ids_by_tags => (
    method => Object,
    positional => [
        Slurpy[ArrayRef[TagName]],
    ],
);
sub retrieve_ids_by_tags($self,$tags) {
    # this maps: id -> how many of the given @tags it has
    my %msgs;
    if ($tags->@*) {
        for my $tag ($tags->@*) {
            $_++ for @msgs{$self->_tagged_by($tag)};
        }
    }
    else {
        $msgs{$_->basename}=0 for $self->_msgdir->children;
    }

    my @ret;
    for my $id (keys %msgs) {
        # if this message id does not have all the required tags, we
        # won't return it
        next unless $msgs{$id} == $tags->@*;
        push @ret, $id;
    }
    return \@ret;
}


signature_for retrieve_by_tags => (
    method => Object,
    positional => [
        Slurpy[ArrayRef[TagName]],
    ],
);
sub retrieve_by_tags($self,$tags) {
    my @ret;
    for my $id ($self->retrieve_ids_by_tags($tags->@*)->@*) {
        push @ret, {
            id => $id,
            mail => $self->retrieve_by_id($id),
        };
    }

    return \@ret;
}


signature_for remove => (
    method => Object,
    positional => [ Str ],
);
sub remove($self,$id) {
    for my $tag_file ($self->_tagdir->children) {
        $tag_file->edit_lines( sub { $_='' if /\A\Q$id\E\n?\z/ } );
    }
    $self->_msgdir->child($id)->remove;

    return;
}


sub clear($self) {
    do { $self->$_->remove_tree;$self->$_->mkpath } for qw(_tagdir _msgdir);
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sietima::MailStore::FS - filesystem-backed email store

=head1 VERSION

version 1.1.4

=head1 SYNOPSIS

  my $store = Sietima::MailStore::FS->new({ root => '/tmp/my-store' });

=head1 DESCRIPTION

This class implements the L<< C<Sietima::MailStore> >> interface,
storing emails as files on disk.

=head1 ATTRIBUTES

=head2 C<root>

Required, a L<< C<Path::Tiny> >> object that points to an existing
directory. Coercible from a string.

It's a good idea for the directory to be readable and writable by the
user who will run the mailing list, and also by all users who will run
administrative commands (like those provided by L<<
C<Sietima::Role::SubscriberOnly::Moderate> >>). A way to achieve that
is to have a group dedicated to list owners, and set the directory
group-writable and group-sticky, and owned by that group:

  # chgrp -R mailinglists /tmp/my-store
  # chmod -R g+rwXs /tmp/my-store

=head1 METHODS

=head2 C<store>

  my $id = $store->store($email_mime_object,@tags);

Stores the given email message inside the L<store root|/root>, and
associates it with the given tags.

Returns a unique identifier for the stored message. If you store twice
the same message (or two messages that stringify identically), you'll
get the same identifier.

=head2 C<retrieve_by_id>

  my $email_mime_object = $store->retrieve_by_id($id);

Given an identifier returned by L<< /C<store> >>, this method returns
the email message.

If the message has been deleted, or the identifier is not recognised,
this method returns C<undef> in scalar context, or an empty list in
list context.

=head2 C<retrieve_ids_by_tags>

  my @ids = $store->retrieve_ids_by_tags(@tags)->@*;

Given a list of tags, this method returns an arrayref containing the
identifiers of all (and only) the messages that were stored associated
with (at least) all those tags. The order of the returned identifiers
is essentially random.

If there are no messages associated with the given tags, this method
returns an empty arrayref.

=head2 C<retrieve_by_tags>

  my @email_mime_objects = $store->retrieve_by_tags(@tags)->@*;

This method is similar to L<< /C<retrieve_ids_by_tags> >>, but it
returns an arrayref of hashrefs like:

 $store->retrieve_by_tags('t1') ==> [
   { id => $id1, mail => $msg1 },
   { id => $id2, mail => $msg2 },
  ]

=head2 C<remove>

  $store->remove($id);

This method removes the message corresponding to the given identifier
from disk. Removing a non-existent message does nothing.

=head2 C<clear>

  $store->clear();

This method removes all messages from disk. Clearing as empty store
does nothing.

=for Pod::Coverage BUILD

=head1 AUTHOR

Gianni Ceccarelli <dakkar@thenautilus.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Gianni Ceccarelli <dakkar@thenautilus.net>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
