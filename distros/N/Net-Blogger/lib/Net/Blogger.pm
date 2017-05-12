{

=head1 NAME

Net::Blogger - an OOP-ish interface for accessing a weblog via
the Blogger XML-RPC API.

=head1 SYNOPSIS

 use Net::Blogger;
 my $b = Net::Blogger->new(appkey=>APPKEY);

 $b->BlogId(BLOGID);
 $b->Username(USERNAME);
 $b->Password(PASSWORD);

 $b->BlogId($b->GetBlogId(blogname=>'superfoobar'));

 # Get recent posts

 my ($ok,@p) = $b->getRecentPosts(numposts=>20);

 if (! $ok) {
   croak $b->LastError();
 }

 map { print "\t $_->{'postid'}\n"; } @p;

 # Post from a file

 my ($ok,@p) = $b->PostFromFile(file=>"/usr/blogger-test");

 if (! $ok) {
   croak $b->LastError();
 }

 # Deleting posts

 map {
   $b->deletePost(postid=>"$_") || croak $b->LastError();
 } @p;

 # Getting and setting templates

 my $t = $b->getTemplate(type => 'main');
 $b->setTemplate(type=>'main',template=>\$t) || croak $b->LastError();

 # New post

 my $txt = "hello world.";
 my $id = $b->newPost(postbody=>\$txt) || croak $b->LastError();

 # Get post

 my $post = $b->getPost($id) || croak $b->LastError();
 print "Text for last post was $post->{'content'}\n";

=head1 DESCRIPTION

Blogger.pm provides an OOP-ish interface for accessing a weblog
via the Blogger XML-RPC API.

=head1 ENGINES

Blogger.pm relies on "engines" to implement it's functionality.
The Blogger.pm package itself is little more than a wrapper file
that happens to use a default "Blogger" engine is none other is
specified.

   my $manila = Net::Blogger->new(engine=>"manila");

But wait!, you say. It's an API that servers implements and all I should have to
do is changed the login data. Why do I need an engine?

Indeed. Every server pretty much gets the spirit of the API right, but each implements
the details slightly differently. For example :

The MovableType XML-RPC server follows the spec for the I<getRecentPost> but because of
the way Perl auto-vivifies hashes it turns out you can slurp all the posts for a blog
rather than the just the 20 most recent.

The Userland Manila server doesn't support the I<getUsersBlogs> method; the Userland
RadioUserland server does.

The Blogger server imposes a limit on the maximum length of a post. Other servers don't.
(Granted the server in question will return a fault, if necessary, but Blogger.pm tries
to do the right thing and check for these sorts of things before adding to the traffic
on the network.)

Lots of weblog-like applications don't support the Blogger API but do have a traditional
REST interface. With the introduction of Blogger.pm "engines", support for these applications
via the API can be added with all the magic happening behind the curtain, so to speak.

=cut

package Net::Blogger;
use strict;

use vars qw ( $AUTOLOAD $LAST_ERROR );

$Net::Blogger::VERSION   = '1.02';

=head1 PACKAGE METHODS

=cut

=head2 __PACKAGE__->new(\%args)

Instantiate a new Blogger object.

Valid arguments are :

=over 4

=item *

B<engine> (required)

String. Default is "blogger".

=item *

B<appkey>

String. The magic appkey for connecting to the Blogger XMLRPC server.

=item *

B<blogid>

String. The unique ID that Blogger uses for your weblog

=item *

B<username>

String. A valid username for blogid

=item *

B<password>

String. A valid password for the username/blogid pair.

=back

Releases prior to Net::Blogger 0.85 accepted a list of arguments
rather than a reference. Version 0.85+ are backwards compatible.

Returns an object. Woot!

=head2 __PACKAGE__->init()

Initializes the specified engine

=cut

sub new {
    my $pkg = shift;
    my $self = {};
    bless $self,$pkg;
    $self->init(@_) || return undef;
    return $self;
}

sub init {
    my $self = shift;
    my $args = (ref($_[0]) eq "HASH") ? shift : { @_ };

    my $engine = $args->{'engine'} || "blogger";
    my $class  = join("::",__PACKAGE__,"Engine",ucfirst $engine);

    eval "require $class";

    if ($@) {
	print $@,"\n";
	$LAST_ERROR = "Unrecognized implementation of the Blogger API.";
	return 0;
    }

    $self->{"_class"} = $class->new(%$args)
	|| &{ $LAST_ERROR = Error->prior(); return 0; };

    return 1;
}

=head1 Blogger API METHODS

=head2 $pkg->getUsersBlogs()

Fetch the I<blogid>, I<url> and I<blogName> for each of the Blogger blogs
the current user is registered to.

Returns an array ref of hashes.

=head2 $pkg->newPost(\%args)

Add a new post to the Blogger server.

Valid arguments are :

=over 4

=item *

B<postbody>

Scalar ref. I<required>

=item *

B<publish>

Boolean.

=back

If the length of I<postbody> exceeds maximum length allowed by the Blogger servers
-- 65,536 characters -- currently  the text will be chunked into smaller pieces are
each piece will be posted separately.

Returns an array containing one, or more, post ids.

=head2 $pkg->getPost($postid)

Returns a hash ref, containing the following keys : userid, postid, content and dateCreated.

=head2 $pkg->getRecentPosts(\%args)

Fetch the latest (n) number of posts for a given blog. The most recent posts are returned
first.

Valid arguments are

=over 4

=item *

B<numposts>

Int. If no argument is passed to the method, default is 1.

"NumberOfPosts is limited to 20 at this time. Let me know if this
gets annoying. Letting this number get too high could result in some
expensive db access, so I want to be careful with it." --Ev

=back

Releases prior to Net::Blogger 0.85 accepted a list of arguments
rather than a reference. Version 0.85+ are backwards compatible.

Returns true or false, followed by an array of hash refs. Each hash ref contains the following
keys : postid,content,userid,dateCreated

=head2 $pkg->editPost(\%args)

Update the Blogger database. Set the body of entry $postid to $body.

Valid arguments are :

=over 4

=item *

B<postbody> (required)

Scalar ref or a valid filehandle.

=item *

B<postid> (required)

String.

=item *

B<publish>

Boolean.

=back

If the length of I<postbody> exceeds maximum length allowed by the Blogger servers
-- 65,536 characters -- currently  the text will be chunked into smaller pieces are
each piece will be posted separately.

Releases prior to Net::Blogger 0.85 accepted a list of arguments
rather than a reference. Version 0.85+ are backwards compatible.

Returns an array containing one, or more, post ids.

=head2 $pkg->deletePost(\%args)

Delete a post from the Blogger server.

Valid arguments are

=over 4

=item *

B<postid> (required)

String.

=item *

B<publish>

Boolean.

=back

Releases prior to Net::Blogger 0.85 accepted a list of arguments
rather than a reference. Version 0.85+ are backwards compatible.

Returns true or false.

=head2 $pkg->setTemplate(\%args)

Set the body of the template matching type I<$type>.

 "template is the HTML (XML, whatever -- Blogger can output any sort of text).
  Must contain opening and closing <Blogger> tags to be valid and accepted."
     --Evan

Valid arguments are

=over 4

=item *

B<template>

Scalar ref. I<required>

=item *

B<type>

String. I<required>

Valid types are "main" and "archiveIndex"

=back

Releases prior to Net::Blogger 0.85 accepted a list of arguments
rather than a reference. Version 0.85+ are backwards compatible.

Returns true or false.

=head2 $pkg->getTemplate(\%args)

Fetch the body of the template matching type I<$type>.

Valid types are

=over 4

=item *

B<type>

String. I<required>

Valid types are "main" and "archiveIndex"

=back

Releases prior to Net::Blogger 0.85 accepted a list of arguments
rather than a reference. Version 0.85+ are backwards compatible.

Returns a string.

=head1 EXTENDED METHODS

=cut

=head2 $pkg->GetBlogId(\%args)

Return the unique blogid for I<$args->{'blogname'}>.

Valid arguments are

=over 4

=item *

B<blogname>

String.

=back

Releases prior to Net::Blogger 0.85 accepted a list of arguments
rather than a reference. Version 0.85+ are backwards compatible.

Returns a string. If no blogname is specified, the current blogid for
the object is returned.

=head2 $pkg->DeleteAllPosts(\%args)

Delete all the posts on a weblog. Valid arguments are :

=over 4

=item *

B<publish>

Boolean.

=back

Releases prior to Net::Blogger 0.85 accepted a list of arguments
rather than a reference. Version 0.85+ are backwards compatible.

=head2 $pkg->PostFromFile(\%args)

Open a filehandle, and while true, post to Blogger. If the length of the
amount read from the file exceeds the per-post limit assigned by the Blogger
servers -- currently 65,536 characters -- the contents of the file will be
posted in multiple "chunks".

Valid arguments are

=over 4

=item *

B<file>

/path/to/file I<required>

=item *

B<postid>

String.

=item *

B<publish>

Boolean.

=item *

B<tail>

Boolean.

If true, the method will not attempt to post data whose length exceeds the
limit set by the Blogger server in the order that the data is read. Translation :
last in becomes last post becomes the first thing you see on your weblog.

=back

If a I<postid> argument is present, the method will call the Blogger API I<editPost>
method with postid. Otherwise the method will call the Blogger API I<newPost> method.

Releases prior to Net::Blogger 0.85 accepted a list of arguments
rather than a reference. Version 0.85+ are backwards compatible.

Returns true or false, followed by an array of zero, or more, postids.

=head2 $pkg->PostFromOutline(\%args)

Like I<PostFromFile>, only this time the file is an outliner document.

This method uses Simon Kittle's Text::Outline::asRenderedHTML method for posting. As of
this writing, the Text::Outline package has not been uploaded to the CPAN. See below for
a link to the homepage/source.

Valid outline formats are OPML, tabbed text outline, Emacs' outline-mode format, and the
GNOME Think format.

Valid arguments are

=over 4

=item *

B<file>

/path/to/file I<required>

=item *

B<postid>

String.

=item *

B<publish>

Boolean.

=back

If a I<postid> argument is present, the method will call the Blogger API
I<editPost> method with postid. Otherwise the method will call the Blogger
API I<newPost> method.

Releases prior to Net::Blogger 0.85 accepted a list of arguments
rather than a reference. Version 0.85+ are backwards compatible.

Returns true or false, followed by an array of zero, or more, postids.

=cut

sub DESTROY {
    return 1;
}

sub AUTOLOAD {
    my $self = shift;
    $AUTOLOAD =~ s/.*:://;
    return $self->{"_class"}->$AUTOLOAD(@_);
}

=head1 NOTES

=head2 The Atom API

In January 2004, Blogger announced their support for the Atom
API.

As of this writing (version 0.87) this package does B<not>
support the Atom API. If you need to do things Atom-ish, your
best bet is to use the L<XML::Atom> package.

=head2 Content negotiation

Persons trying to connect to a server using shortened URLs and
content negotiation should not be surprised if they encounter
weirdness and/or errors. Specifically, a HTTP 406 error.

Some preliminary investigation suggests that, if there's a bug
at play here, it's a bug somewhere deep in SOAP::Lite/HTTP::*
land.

Patches are welcome. Otherwise, you've been warned. :-)

See also :

=head1 AUTHORS

    Originally authored by Aaron Straup Cope
    Adopted by Christopher H. Laco

=head1 SEE ALSO

L<Net::Blogger::API::Core>

L<Net::Blogger::Engine::Base>

http://plant.blogger.com/api/

=head1 BUGS

Hopefully, few. Please reports all bugs to :

 http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net::Blogger

=head1 SOURCE

You can get the latest version of the source code from the Subversion repository
at http://handelframework.com/svn/CPAN/Net-Blogger/

=head1 LICENSE

Copyright (c) 2001-2005 Aaron Straup Cope.

This is free software, you may use it and distribute it under
the same terms as Perl itself.

=cut

return 1;

}
