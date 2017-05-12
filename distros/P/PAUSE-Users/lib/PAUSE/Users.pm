package PAUSE::Users;
$PAUSE::Users::VERSION = '0.07';
# ABSTRACT: interface to PAUSE's users file (00whois.xml)
use strict;
use warnings;

use MooX::Role::CachedURL 0.04;

use Moo;
use PAUSE::Users::User;
use PAUSE::Users::UserIterator;
with 'MooX::Role::CachedURL';

has '+url' =>
    (
     default => sub { 'http://www.cpan.org/authors/00whois.xml' },
    );

has '+max_age' =>
    (
     default => sub { '1 day' },
    );

sub user_iterator
{
    my $self = shift;

    return PAUSE::Users::UserIterator->new( users => $self );
}

1;

=encoding utf8

=head1 NAME

PAUSE::Users - interface to PAUSE's users file (00whois.xml)

=head1 SYNOPSIS

 use PAUSE::Users;

 my $users    = PAUSE::Users->new(max_age => '1 day');
 my $iterator = $users->user_iterator();

 while (defined($user = $iterator->next_user)) {
   print "PAUSE id = ", $user->id, "\n";
   print "Name     = ", $user->fullname, "\n";
 }

=head1 DESCRIPTION

PAUSE::Users provides an interface to the C<00whois.xml>
file produced by the Perl Authors Upload Server (PAUSE).
This file contains a list of all PAUSE users, with some basic information
about each user.

By default PAUSE::Users will request the file from PAUSE at most once a day,
using a locally cached copy otherwise. You can specify the caching time
using the C<max_age> attribute. You can express the caching time using any
of the expressions supported by L<Time::Duration::Parse>.

At the moment this module supports a single iterator interface.
The C<next_user()> method returns an instance of L<PAUSE::Users::User>
(I know, bit of an odd name).

Here's the simple skeleton for iterating over all PAUSE users:

 my $iterator = PAUSE::Users->new()->user_iterator();

 while (my $user = $iterator->next_user) {
    # doing something with $user
 }

=head1 Constructor

The constructor takes the following attributes

=over 4

=item * cache_path
Specify the full path to the local file where the contents of
00whois.xml should be cached. If not set, an appropriate
path for your operating system will be generated using L<File::HomeDir>.

If you don't set this attribute, then after instantiating PAUSE::Users
you can get this attribute to see where the content is being cached.

=item * path
The full path to your own copy of 00whois.xml.
If this is provided, then PAUSE::Users won't check to see if
CPAN's copy is more recent than your file.

=item * max_age
The maximum age for the cached copy, which is stored in the file
referenced with the C<cache_path> attribute. If your cached copy
was updated with the last C<max_age> seconds, then PAUSE::Users
won't even check whether the CPAN copy has been updated.

You can specify the C<max_age> using any of the notations supported
by L<Time::Duration::Parse>. It defaults to '1 day'.

=back

=head1 The user object

The user object supports the following methods:

=over 4

=item id

The user's PAUSE id. For example my PAUSE id is NEILB.

=item fullname

The full name of the user, as they would write it.
So expect to see Kanji and plenty of other non-ASCII characters here.
You are UTF-8 clean, right?

=item asciiname

An ASCII version of the user's name. This might be the romaji version
of a Japanese name, or the fullname without any accents.
For example, author NANIS has fullname A. Sinan Ünür,
and asciiname A. Sinan Unur.

=item email

The contact email address for the author, or C<CENSORED> if the
author specified that their email address should not be shared.

=item has_cpandir

Set to C<1> if the author has a directory on CPAN, and 0 if not.
This is only true (1) if the author I<currently> has something on CPAN.
If you upload a dist then delete it, the dist will be on BackPAN but
not on CPAN, and C<has_cpandir> will return 0.

=item homepage

The author's homepage, if they've specified one.
This might be their blog, their employer's home page,
or any other URL they've chosen to associate with their account.

=item introduced

When the author's PAUSE account was created, specified as
seconds since the epoch. This may change to being an instance
of L<DateTime>.

=back

=head1 00whois.xml file format

The meat of the file is a list of C<E<lt>cpanidE<gt>> elements,
each of which contains details of one PAUSE user:

 <?xml version="1.0" encoding="UTF-8"?>
 <cpan-whois xmlns='http://www.cpan.org/xmlns/whois'
            last-generated='Sat Nov 16 18:19:01 2013 UTC'
            generated-by='/home/puppet/pause/cron/cron-daily.pl'>
  
  ...
  
  <cpanid>
   <id>NEILB</id>
   <type>author</type>
   <fullname>Neil Bowers</fullname>
   <email>neil@bowers.com</email>
   <has_cpandir>1</has_cpandir>
  </cpanid>
  
  ...
  
 </cpan-whois>

In addition to all PAUSE users, the underlying file (00whois.xml)
also contains details of perl.org mailing lists.
For example, here's the entry for Perl5-Porters:

 <cpanid>
  <id>P5P</id>
  <type>list</type>
  <asciiname>The Perl5 Porters Mailing List</asciiname>
  <email>perl5-porters@perl.org</email>
  <info>Mail perl5-porters-subscribe@perl.org</info>
  <has_cpandir>0</has_cpandir>
 </cpanid>

All B<list> type entries are ignored by C<PAUSE::Users>.

=head1 NOTES

I started off trying a couple of XML modules, but I was surprised at
how slow they were, and not really iterator-friendly.
So the current version of the iterator does line-based parsing using
regexps. You really shouldn't do that, but 00whois.xml is automatically
generated, follows a well-defined format, which very rarely changes.

=head1 SEE ALSO

L<Parse::CPAN::Whois> is another module that parses 00whois.xml,
but you have to download it yourself first.

L<Parse::CPAN::Authors> is another module for getting information about
PAUSE users, but based on C<01.mailrc.txt.gz>.

L<CPAN::Index::API::File::Whois> provides a similar interface to 00whois.xml.

L<CPAN::Search::Author> does a real-time search for CPAN authors
using L<search.cpan.org|http://search.cpan.org>.

L<CPAN::Source> fetches 4 of the PAUSE indices and lets you query an aggregation
of the data they contain.

L<PAUSE::Permissions>, L<PAUSE::Packages>.

=head1 REPOSITORY

L<https://github.com/neilbowers/PAUSE-Users>

=head1 AUTHOR

Neil Bowers E<lt>neilb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Neil Bowers <neilb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

