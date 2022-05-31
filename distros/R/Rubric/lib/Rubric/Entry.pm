use strict;
use warnings;
package Rubric::Entry 0.157;
# ABSTRACT: a single entry made by a user

use parent qw(Rubric::DBI);

use Class::DBI::utf8;

#pod =head1 DESCRIPTION
#pod
#pod This class provides an interface to Rubric entries.  It inherits from
#pod Rubric::DBI, which is a Class::DBI class.
#pod
#pod =cut

use Encode 2 qw(_utf8_on);
use Rubric::Entry::Formatter;
use String::TagString;
use Time::Piece;

__PACKAGE__->table('entries');

#pod =head1 COLUMNS
#pod
#pod  id          - a unique identifier
#pod  link        - the link to which the entry refers
#pod  username    - the user who made the entry
#pod  title       - the title of the link's destination
#pod  description - a short description of the entry
#pod  body        - a long body of text for the entry
#pod  created     - the time when the entry was first created
#pod  modified    - the time when the entry was last modified
#pod
#pod =cut

__PACKAGE__->columns(
  All => qw(id link username title description body created modified)
);

__PACKAGE__->utf8_columns(qw( title description body ));

#pod =head1 RELATIONSHIPS
#pod
#pod =head2 link
#pod
#pod The link attribute returns a Rubric::Link.
#pod
#pod =cut

__PACKAGE__->has_a(link => 'Rubric::Link');

#pod =head2 uri
#pod
#pod The uri attribute returns the URI of the entry's link.
#pod
#pod =cut

sub uri { my ($self) = @_; return unless $self->link; $self->link->uri; }

#pod =head2 username
#pod
#pod The user attribute returns a Rubric::User.
#pod
#pod =cut

__PACKAGE__->has_a(username => 'Rubric::User');

#pod =head2 tags
#pod
#pod Every entry has_many tags that describe it.  The C<tags> method will return the
#pod tags, and the C<entrytags> method will return the Rubric::EntryTag objects that
#pod represent them.
#pod
#pod =cut

__PACKAGE__->has_many(entrytags => 'Rubric::EntryTag');
__PACKAGE__->has_many(tags => [ 'Rubric::EntryTag' => 'tag' ]);

#pod =head3 recent_tags_counted
#pod
#pod This method returns a reference to an array of arrayrefs, each a (tag, count)
#pod pair for tags used on the week's 50 most recent entries.
#pod
#pod =cut

__PACKAGE__->set_sql(recent_tags_counted => <<'');
SELECT tag, COUNT(*) as count
FROM   entrytags
WHERE entry IN (SELECT id FROM entries WHERE created > ? LIMIT 100)
  AND tag NOT LIKE '@%%'
  AND entry NOT IN (SELECT entry FROM entrytags WHERE tag = '@private')
GROUP BY tag
ORDER BY count DESC
LIMIT 50

sub recent_tags_counted {
  my ($class) = @_;
  my $sth = $class->sql_recent_tags_counted;
  $sth->execute(time - (86400 * 7));
  my $result = $sth->fetchall_arrayref;
  return $result;
}

#pod =head1 INFLATIONS
#pod
#pod =head2 created
#pod
#pod =head2 modified
#pod
#pod The created and modified columns are stored as seconds since epoch, but
#pod inflated to Time::Piece objects.
#pod
#pod =cut

__PACKAGE__->has_a(
  $_ => 'Time::Piece',
  deflate => 'epoch',
  inflate => Rubric::Config->display_localtime ? sub { localtime($_[0]) }
                                               : sub { gmtime($_[0]) }
) for qw(created modified);

__PACKAGE__->add_trigger(before_create => \&_default_title);

__PACKAGE__->add_trigger(before_create => \&_create_times);
__PACKAGE__->add_trigger(before_update => \&_update_times);

sub _default_title {
  my $self = shift;
  $self->title('(default)') unless $self->{title}
}

sub _create_times {
  my $self = shift;
  $self->created(scalar gmtime) unless defined $self->{created};
  $self->modified(scalar gmtime) unless defined $self->{modified};
}

sub _update_times {
  my $self = shift;
  $self->modified(scalar gmtime);
}

#pod =head1 METHODS
#pod
#pod =head2 query(\%arg)
#pod
#pod The arguments to C<query> provide a set of abstract constraints for the query.
#pod These are sent to Rubric::Entry::Query, which builds an SQL query and returns
#pod the result of running it.  (Either a list or an Iterator is returned.)
#pod
#pod (The built-in Class::DBI search method can't handle this kind of search.)
#pod
#pod  user   - entries for this User
#pod  tags   - entries with these tags (arrayref)
#pod  link   - entries for this Link
#pod  urimd5 - entries for the Link with this md5 sum
#pod  has_body    - whether entries must have bodies (T, F, or undef)
#pod  has_link    - whether entries must have a link (T, F, or undef)
#pod  (time spec) - {created,modified}_{before,after,on}
#pod                limits entries by time; given as a complete or partial
#pod                time and date string in the form "YYYY-MM-DD HH:MM"
#pod
#pod =cut

sub query {
  my $self = shift;
  require Rubric::Entry::Query;
  Rubric::Entry::Query->query(@_);
}

#pod =head2 set_new_tags(\%tags)
#pod
#pod This method replaces all entry's current tags with the new set of tags.
#pod
#pod =cut

sub set_new_tags {
  my ($self, $tags) = @_;
  $self->entrytags->delete_all;
  $self->update;

  while (my ($tag, $value) = each %$tags) {
    $self->add_to_tags({ tag => $tag, tag_value => $value });
  }
}

#pod =head2 tags_from_string
#pod
#pod   my $tags = Rubric::Entry->tags_from_string($string);
#pod
#pod This (class) method takes a string of tags, delimited by whitespace, and
#pod returns an array of the tags, throwing an exception if it finds invalid tags.
#pod
#pod Valid tags (shouldn't this be documented somewhere else instead?) may contain
#pod letters, numbers, underscores, colons, dots, and asterisks.  Hyphens me be
#pod used, but not as the first character.
#pod
#pod =cut

sub tags_from_string {
  my ($class, $tagstring) = @_;

  return {} unless $tagstring and $tagstring =~ /\S/;

  String::TagString->tags_from_string($tagstring);
}

#pod =head2 C< markup >
#pod
#pod This method returns the value of the entry's @markup tag, or C<_default> if
#pod there is no such tag.
#pod
#pod =cut

sub markup {
  my ($self) = @_;

  my ($tag)
    = Rubric::EntryTag->search({ entry => $self->id, tag => '@markup' });

  return ($tag and $tag->tag_value) ? $tag->tag_value : '_default';
}


#pod =head2 C< body_as >
#pod
#pod   my $formatted_body = $entry->body_as("html");
#pod
#pod This method returns the body of the entry, formatted into the given format.  If
#pod the entry cannot be rendered into the given format, an exception is thrown.
#pod
#pod =cut

sub body_as {
  my ($self, $format) = @_;

  my $markup = $self->markup;

  Rubric::Entry::Formatter->format({
    text   => $self->body,
    markup => $markup,
    format => $format
  });
}

sub accessor_name_for {
  my ($class, $field) = @_;

  return 'user' if $field eq 'username';

  return $field;
}

## return retrieve_all'd objects in recent-to-older order

__PACKAGE__->set_sql(RetrieveAll => <<'');
SELECT __ESSENTIAL__
FROM   __TABLE__
ORDER BY created DESC

sub tagstring {
  my ($self) = @_;
  String::TagString->string_from_tags({
    map {; $_->tag => $_->tag_value } $self->entrytags
  });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Rubric::Entry - a single entry made by a user

=head1 VERSION

version 0.157

=head1 DESCRIPTION

This class provides an interface to Rubric entries.  It inherits from
Rubric::DBI, which is a Class::DBI class.

=head1 PERL VERSION

This code is effectively abandonware.  Although releases will sometimes be made
to update contact info or to fix packaging flaws, bug reports will mostly be
ignored.  Feature requests are even more likely to be ignored.  (If someone
takes up maintenance of this code, they will presumably remove this notice.)
This means that whatever version of perl is currently required is unlikely to
change -- but also that it might change at any new maintainer's whim.

=head1 COLUMNS

 id          - a unique identifier
 link        - the link to which the entry refers
 username    - the user who made the entry
 title       - the title of the link's destination
 description - a short description of the entry
 body        - a long body of text for the entry
 created     - the time when the entry was first created
 modified    - the time when the entry was last modified

=head1 RELATIONSHIPS

=head2 link

The link attribute returns a Rubric::Link.

=head2 uri

The uri attribute returns the URI of the entry's link.

=head2 username

The user attribute returns a Rubric::User.

=head2 tags

Every entry has_many tags that describe it.  The C<tags> method will return the
tags, and the C<entrytags> method will return the Rubric::EntryTag objects that
represent them.

=head3 recent_tags_counted

This method returns a reference to an array of arrayrefs, each a (tag, count)
pair for tags used on the week's 50 most recent entries.

=head1 INFLATIONS

=head2 created

=head2 modified

The created and modified columns are stored as seconds since epoch, but
inflated to Time::Piece objects.

=head1 METHODS

=head2 query(\%arg)

The arguments to C<query> provide a set of abstract constraints for the query.
These are sent to Rubric::Entry::Query, which builds an SQL query and returns
the result of running it.  (Either a list or an Iterator is returned.)

(The built-in Class::DBI search method can't handle this kind of search.)

 user   - entries for this User
 tags   - entries with these tags (arrayref)
 link   - entries for this Link
 urimd5 - entries for the Link with this md5 sum
 has_body    - whether entries must have bodies (T, F, or undef)
 has_link    - whether entries must have a link (T, F, or undef)
 (time spec) - {created,modified}_{before,after,on}
               limits entries by time; given as a complete or partial
               time and date string in the form "YYYY-MM-DD HH:MM"

=head2 set_new_tags(\%tags)

This method replaces all entry's current tags with the new set of tags.

=head2 tags_from_string

  my $tags = Rubric::Entry->tags_from_string($string);

This (class) method takes a string of tags, delimited by whitespace, and
returns an array of the tags, throwing an exception if it finds invalid tags.

Valid tags (shouldn't this be documented somewhere else instead?) may contain
letters, numbers, underscores, colons, dots, and asterisks.  Hyphens me be
used, but not as the first character.

=head2 C< markup >

This method returns the value of the entry's @markup tag, or C<_default> if
there is no such tag.

=head2 C< body_as >

  my $formatted_body = $entry->body_as("html");

This method returns the body of the entry, formatted into the given format.  If
the entry cannot be rendered into the given format, an exception is thrown.

=head1 AUTHOR

Ricardo SIGNES <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
