package Net::MovableType;

# MovableType.pm,v 1.18 2004/08/14 08:31:32 sherzodr Exp

use strict;
use vars qw($VERSION $errstr $errcode);
use Carp;
use XMLRPC::Lite;

$VERSION = '1.74';

# Preloaded methods go here.

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my ($url, $username, $password) = @_;

  my $self = {
    proxy   => undef,
    blogid   => undef,
    username => $username,
    password => $password
  };

  bless $self, $class;

  # if $url starts with 'http://' and ends in '.xml', we assume it was a
  # location of rsd.xml file
  if ( $url =~ m/^http:\/\/.+\.xml$/ ) {
      $self->rsd_url($url) or return undef;

  # if the URL just starts with 'http://', we assume it was a url for
  # MT's XML-RPC server
  } elsif ( $url =~ m/^http:\/\// ) {
      $self->{proxy} = XMLRPC::Lite->proxy($url);

  # in neither case, we assume it was a file system location of rsd.xml file
  } elsif ( $url ) {
      $self->rsd_file($url) or return undef;

  }

  return $self
}





# shortcut for XMLRPC::Lite's call() method. Main difference from original call()
# is, it returns native Perl data, instead of XMLRPC::SOM object
sub call {
    my ($self, $method, @args) = @_;

    unless ( $method ) {
        die "call(): usage error"
    }

    my $proxy = $self->{proxy} or die "'proxy' is missing";
    my $som   = $proxy->call($method, @args);
    my $result= $som->result();

    unless ( defined $result ) {
        $errstr = $som->faultstring;
        $errcode= $som->faultcode;
        return undef
    }

    return $result
}




sub process_rsd {
    my ($self, $string_or_file ) = @_;

    unless ( $string_or_file ) {
        croak "process_rsd() usage error"
    }

    require XML::Simple;
    my $xml     = XML::Simple::XMLin(ref($string_or_file) ? $$string_or_file : $string_or_file );
    my $apilink = $xml->{service}->{apis}->{api}->{MetaWeblog}->{apiLink};
    my $blogid  = $xml->{service}->{apis}->{api}->{MetaWeblog}->{blogID};

    unless ( $apilink && $blogid ) {
        croak "Couldn't retrieve 'apiLink' and 'blogID' from $xml"
    }

    $self->blogId($blogid);
    $self->{proxy} = XMLRPC::Lite->proxy($apilink);

    # need to return a true value indicating success
    return 1
}


# fetches RSD file from a remote location,
# and configures Net::MovableType object properly
sub rsd_url {
    my ($self, $url) = @_;

    unless ( $url ) {
        croak "rsd_url() usage error"
    }

    $self->{rsd_url} = $url;

    require LWP::UserAgent;

    my $ua = LWP::UserAgent->new();
    my $req= HTTP::Request->new('GET', $url);
    my $response = $ua->request($req);
    if ( $response->is_error ) {
        $errstr = $response->base . ": " . $response->message;
        $errcode= $response->code;
        return undef
    }

    return $self->process_rsd($response->content_ref)
}



sub rsd_file {
    my ($self, $file) = @_;

    unless ( $file ) {
        croak "rsd_file() usage error"
    }

    $self->{rsd_file} = $file;

    return $self->process_rsd($file)
}




sub username {
    my ($self, $username) = @_;

    if ( defined $username ) {
        $self->{username} = $username;
    }
    return $self->{username}
}



*error = \&errstr;
sub errstr {
    return $errstr
}


sub errcode {
    return $errcode
}




sub password {
  my ($self, $password) = @_;

  if ( defined $password ) {
    $self->{password} = $password
  }
  return $self->{password}
}



sub proxy {
    my ($self, $proxy) = @_;

    if ( defined $proxy ) {
        $self->{proxy} = $proxy
    }
    return $self->{proxy}
}



*blogid = \&blogId;
sub blogId {
    my ($self, $blogid) = @_;

    if ( defined $blogid ) {
        $self->{blogid} = $blogid
    }
    return $self->{blogid}
}



sub resolveBlogId {
    my ($self, $blogname) = @_;

    unless ( $self->username && $self->password ) {
        croak "username and password are missing\n"
    }

    my $blogs = $self->getUsersBlogs();
    while ( my $b = shift @$blogs ) {
        if ( $b->{blogName} eq $blogname ) {
            return $b->{blogid}
        }
    }

    $errstr = "Couldn't find blog '$blogname'";
    return undef
}




sub getBlogInfo {
    my ($self, $blogid) = @_;

    $blogid ||= $self->blogId() or croak "no 'blogId' set";
    my $blogs = $self->getUsersBlogs() or return undef;

    while ( my $b = shift @$blogs ) {
        if ( $b->{blogid} == $blogid ) {
            return $b
        }
    }

    $errstr = "No blog found with id '$blogid";
    return undef
}







*getBlogs = \&getUsersBlogs;
sub getUsersBlogs {
    my ($self, $username, $password)  = @_;

    $username = $self->username($username);
    $password = $self->password($password);

    unless ( $username && $password ) {
        croak "username and password are missing";
    }

    return $self->call('blogger.getUsersBlogs', "", $username, $password)
}






sub getUserInfo {
    my ($self, $username, $password) = @_;

    $username = $self->username($username);
    $password = $self->password($password);

    unless ( $username && $password ) {
        croak "username and/or password are missing"
    }

    return $self->call('blogger.getUserInfo', "", $username, $password)
}




sub getPost {
    my ($self, $postid, $username, $password) = @_;

    $username = $self->username($username);
    $password = $self->password($password);

    unless ( $username && $password && $postid ) {
        croak "getPost() usage error"
    }

    return $self->call('metaWeblog.getPost', $postid, $username, $password)
}







sub getRecentPosts {
    my ($self, $numposts) = @_;

    my $blogid   = $self->blogId()     or croak "no 'blogId' defined";
    my $username = $self->username()   or croak "no 'username' defined";
    my $password = $self->password()   or croak "no 'password' defined";
    $numposts ||= 1;

    return $self->call('metaWeblog.getRecentPosts', $blogid, $username, $password, $numposts)
}



sub getRecentPostTitles {
    my ($self, $numposts) = @_;

    my $blogid  = $self->blogId()       or croak "no 'blogId' defined";
    my $username= $self->username()     or croak "no 'username' defined";
    my $password= $self->password()     or croak "no 'password' defined";
    $numposts ||= 1;

    return $self->call('mt.getRecentPostTitles', $blogid, $username, $password, $numposts)
}






*getCategories = \&getCategoryList;
sub getCategoryList {
    my ($self, $blogid, $username, $password) = @_;

    $blogid      = $self->blogId($blogid) or croak "no 'blogId' defined";
    $username   = $self->username($username) or croak "no 'username' defined";
    $password   = $self->password($password) or croak "no 'password' defined";

    return $self->call('mt.getCategoryList', $blogid, $username, $password)
}




sub getPostCategories {
    my ($self, $postid, $username, $password) = @_;

    $username = $self->username($username) or croak "no 'username' defined";
    $password = $self->password($password) or croak "no 'password' defined";

    unless ( $postid ) {
        croak "getPostCategories() usage error"
    }

    return $self->call('mt.getPostCategories', $postid, $username, $password)
}



sub setPostCategories {
    my ($self, $postid, $cats) = @_;

    unless ( ref $cats ) {
        $cats = [$cats]
    }

    unless ( @$cats && $postid ) {
        croak "setPostCategories() usage error"
    }

    my $blogid = $self->blogId()    or croak "no 'blogId' set";

    my $category_list = $self->getCategoryList($blogid);
    my $post_categories = [];
    for my $cat ( @$cats ) {
        for my $c ( @$category_list ) {
            if ( lc $c->{categoryName} eq lc $cat ) {
                push @$post_categories, {categoryId=>$c->{categoryId} }
            }
        }
    }

    my $username  = $self->username() or croak "no 'username' defined";
    my $password  = $self->password() or croak "no 'password' defined";
    $postid                          or croak "setPostCategories() usage error";

    return $self->call('mt.setPostCategories', $postid, $username, $password, $post_categories)
}











sub supportedMethods {
    my ($self) = @_;

    return $self->call('mt.supportedMethods')
}



sub publishPost {
    my ($self, $postid, $username, $password) = @_;

    $username = $self->username($username) or croak "no 'username' set";
    $password = $self->password($password)  or croak "no 'password' set";

    unless ( $postid ) {
        croak "publishPost() usage error"
    }

    return $self->call('mt.publishPost', $postid, $username, $password)
}





sub newPost {
    my ($self, $content, $publish) = @_;

    my $blogid   = $self->blogId()   or croak "'blogId' is missing";
    my $username = $self->username() or croak "'username' is not set";
    my $password = $self->password() or croak "'password' is not set";

    unless ( $content && (ref($content) eq 'HASH') ) {
        croak "newPost() usage error"
    }

    return $self->call('metaWeblog.newPost', $blogid, $username, $password, $content, $publish)
}






sub editPost {
    my ($self, $postid, $content, $publish) = @_;

    my $username = $self->username() or croak "'username' is not set";
    my $password = $self->password() or croak "'password' is not set";

    unless ( $content && (ref($content) eq 'HASH') ) {
        croak "newPost() usage error"
    }

    return $self->call('metaWeblog.editPost', $postid, $username, $password, $content, $publish)
}






sub deletePost {
    my ($self, $postid, $publish) = @_;

    my $username = $self->username or croak "'username' not set";
    my $password = $self->password or croak "'password' not set";
    $postid                        or croak "deletePost() usage error";

    return $self->call('blogger.deletePost', "", $postid, $username, $password, $publish)
}




*upload = \&newMediaObject;
sub newMediaObject {
    my ($self, $filename, $name, $type) = @_;

    my $blogid   = $self->blogId()   or croak "'blogId' is missing";
    my $username = $self->username() or croak "'username' is not set";
    my $password = $self->password() or croak "'password' is not set";

    unless ( $filename ) {
        croak "newMediaObject() usage error";
    }

    my $blob = undef;
    if ( ref $filename ) {
        $blob = $$filename;
        $filename = undef;

    } else {
        unless(open(FH, $filename)) {
            $errstr = "couldn't open $filename: $!";
            return undef
        }
        local $/ = undef;
        $blob = <FH>; close(FH);
    }

    if ( $filename && !$name ) {
        require File::Basename;
        $name = File::Basename::basename($filename);
    }

    unless ( $name ) {
        croak "newMediaObject() usage error: \$name is missing"
    }

    my %content_hash = (
         bits    => XMLRPC::Data->type(base64 => $blob),
         name    => $name,
         type    => $type || ""
    );

    return $self->call('metaWeblog.newMediaObject', $blogid, $username, $password, \%content_hash)
}










sub dump {
  my $self = shift;

  require Data::Dumper;
  my $d = new Data::Dumper([$self], [ref $self]);
  return $d->Dump();
}



package MovableType;
@MovableType::ISA = ('Net::MovableType');


package MT;
@MT::ISA = ('Net::MovableType');


1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Net::MovableType - light-weight MovableType client

=head1 SYNOPSIS

  use Net::MovableType;
  my $mt = new Net::MovableType('http://your.com/rsd.xml');
  $mt->username('user');
  $mt->password('secret');

  my $entries = $mt->getRecentPosts(5);
  while ( my $entry = shift @$entries ) {
    printf("[%02d] - %s\n\tURI: %s\n",
           $entry->{postid}, $entry->{title}, $entry->{'link'} )
  }

=head1 DESCRIPTION

Using I<Net::MovableType> you can post new entries, edit existing entries, browse entries
and users blogs, and perform most of the features you can perform through accessing your
MovableType account.

Since I<Net::MovableType> uses MT's XML-RPC (I<Remote Procedure Call> gateway, you can do it from
any computer with Internet connection.

=head1 PROGRAMMING STYLE

I<Net::MovableType> promises an intuitive, user friendly, Object Oriented interface for managing
your web sites published through MovableType. Most of the method names correspond to those documented
in MovableType's Programming Interface Manual, however, their expected arguments differ.

=head2 CREATING MT OBJECT

Before you start doing anything, you need to have a I<MovableType> object handy. You can
create a I<MovableType> object by calling C<new()> - constructor method:

    $mt = new MovableType('http://mt.handalak.com/cgi-bin/mt-xmlrpc.cgi');
    # or
    $mt = new MovableType('http://author.handalak.com/rsd.xml');
    # or even..
    $mt = new MovableType('/home/sherzodr/public_html/author/rsd.xml');

Notice, you need to pass at least one argument while creating I<MT> object, that is
the location of your either F<mt-xmlrpc.cgi> file, or your web site's F<rsd.xml> file.
Default templates of I<MT> already generate F<rsd.xml> file for you. If they don't,
you should get one from http://www.movabletype.org/

If your F<rsd.xml> file is available locally, you should provide a full path to the
file instead of providing it as a URL. Reading the file locally is more efficient
than fetching it over the Web.

Giving it a location of your F<rsd.xml> file is preferred, since it will ensure that
your C<blogId()> will be set properly. Otherwise, you will have to do it manually calling
C<blogId()> (see later).

It is very important that you get this one right. Otherwise, I<Net::MovableType> will
know neither about where your web site is nor how to access them.

I<MovableType> requires you to provide valid username/password pair to do most of the things.
So you need to tell I<MovableType> object about your username and passwords, so it can use
them to access the resources.

=head2 LOGGING IN

You can login in two ways; by either providing your I<username> and I<password> while creating
I<MT> object, or by calling C<username()> and C<password()> methods after creating I<MT> object:

    # creating MT object with valid username/password:
    $mt = new MovableType($proxy, 'author', 'password');

    # or
    $mt = new MovableType($proxy);
    $mt->username('author');
    $mt->password('password');

C<username()> and C<password()> methods are used for both setting username and password,
as well as for retrieving username and password for the current user. Just don't pass
it any arguments should you wish to use for the latter purpose.

=head2 DEFINING A BLOG ID

Defining a blog id may not be necessary if you generated your C<$mt> object
with an F<rsd.xml> file. Otherwise, read on.

As we will see in subsequent sections, most of the I<MovableType>'s methods operate on
specific web log. For defining a default web log to operate on, after setting above I<username>
and I<password>, you can also set your default blog id using C<blogId()> method:

    $mt->blogId(1);

To be able to do this, you first need to know your blog id. There are no documented ways of
retrieving your blog id, except for investigating the URL of your MovableType account panel.
Just login to your MovableType control panel (through F<mt.cgi> script). In the first screen,
you should see a list of your web logs. Click on the web log in question, and look at the
URL of the current window. In my case, it is:

    http://mt.handalak.com/cgi-bin/mt?__mode=menu&blog_id=1

Notice I<blog_id> parameter? That's the one!

Wish you didn't have to go through all those steps to find out your blog id? I<Net::MovableType>
provides C<resolveBlogId()> method, which accepts a name of the web log, and returns correct blogId:

    $blog_id = $mt->resolveBlogId('lost+found');
    $mt->blogId($blog_id);

Another way of retrieving information about your web logs is to get all the lists of your web logs
by calling C<getUsersBlogs()> method:

    $blogs = $mt->getUsersBlogs();

C<getUsersBlogs()> returns list of blogs, where each blog is represented with a hashref. Each hashref
holds such information as I<blogid>, I<blogName> and I<url>. Following example lists all the
blogs belonging to the current user:

    $blogs = $mt->getUsersBlogs();
    for $b ( @$blogs ) {
        printf("[%02d] %s\n\t%s\n", $b->{blogid}, $b->{blogName}, $b->{url})
    }

=head2 POSTING NEW ENTRY

By now, you know how to login and how to define your blogId. Now is a good time to post
a new article to your web log. That's what  C<newPost()> method is for.

C<newPost()> expects at least a single argument, which should be a reference to a hash
containing all the details of your new entry. First, let's define a new entry to be posted
on our web log:

    $entry = {
        title       => "Hello World from Net::MovableType",
        description => "Look ma, no hands!"
    };

Now, we can pass above C<$entry> to our C<newPost()> method:

    $mt->newPost($entry);

In the above example, I<description> field corresponds to Entry Body field of MovableType.
This is accessible from within your templates through I<MTEntryBody> tag. MovableType allows
you to define more entry properties than we did above. Following is the list of all the
attributes we could've defined in our above C<$entry>:

=over 4

=item dateCreated

I<Authored Date> attribute of the entry. Format of the date should be in I<ISO.8601> format

=item mt_allow_comments

Should comments be allowed for this entry

=item mt_allow_pings

should pings be allowed for this entry

=item mt_convert_breaks

Should it use "Convert Breaks" text formatter?

=item mt_text_more

Extended entry

=item mt_excerpt

Excerpt of the entry

=item mt_keywords

Keywords for the entry

=item mt_tb_ping_urls

List of track back ping urls

=back

Above entry is posted to your MT database. But you still don't see it in your weblog, do you?
It's because, the entry is still not published. There are several ways of publishing an entry.
If you pass a true value to C<newPost()> as the second argument, it will publish your entry
automatically:

    $mt->newPost($entry, 1);

You can also publish your post by calling C<publishPost()> method. C<publishPost()>, however, needs
to know I<id> of the entry to publish. Our above C<newPost()>, luckily, already returns this information,
which we've been ignoring until now:

    my $new_id = $mt->newPost($entry);
    $mt->publishPost($new_id);

You can also publish your post later, manually, by simply rebuilding your web log from within
your MT control panel.

=head2 ENTRY CATEGORIES

I<MovableType> also allows entries to be associated with specific category, or even with
multiple categories. For example, above C<$entry>, we just published, may belong to category "Tutorials".

Unfortunately, structure of our C<$entry> doesn't have any slots for defining its categories.
This task is performed by a separate procedure, C<setPostCategories()>.

C<setPostCategories()> expects two arguments. First should be I<postid> of the post to assign
categories to, and second argument should either be a name of the primary category, or
a list of categories in the form of an arrayref. In the latter case, the first category mentioned
becomes entry's primary category.

For example, let's re-post our above C<$entry>, but this time assign it to "Tutorials" category:

    $new_id = $mt->newPost($entry, 0);  # <-- not publishing it yet
    $mt->setPostCategories($new_id, "Tutorials");
    $mt->publishPost($new_id);

We could also assign a single entry to multiple categories. Say, to both "Tutorials" and
"Daily Endeavors". But say, we want "Daily Endeavors" to be the primary category for this entry:

    $new_id = $mt->newPost($entry, 0);  # <-- not publishing it yet
    $mt->setPostCategories($newPid, ["Daily Endeavors", "Tutorials"]);
    $mt->publishPost($new_id);


Notice, in above examples we made sure that C<newPost()> method didn't publish the entry
by passing it false value as the second argument. If we published it, we again would end
up having to re-publish the entry after calling C<setPostCategories()>, thus wasting
unnecessary resources.

=head2 BROWSING ENTRIES

Say, you want to be able to retrieve a list of entries from your web log. There couple of ways
for doing this. If you just want titles of your entries, consider using C<getRecentPostTitles()>
method. C<getRecentPostTitles()> returns an array of references to a hash, where each hashref
contains fields I<dateCreated>, I<userid>, I<postid> and I<title>.

C<getRecentPostTitles()> accepts a single argument, denoting the number of recent entries to retrieve.
If you don't pass any arguments, it defaults to I<1>:

    $recentTitles = $mt->getRecentPostTitles(10);
    for my $post ( @$resentTitles ) {
        printf("[%03d] %s\n", $post->{postid}, $post->{title})
    }

Remember, even if you don't pass any arguments to C<getRecentPostTitles()>, it still returns an array
of hashrefs, but this array will hold only one element:

    $recentTitle = $mt->getRecentPostTitles();
    printf("[%03d] %s\n", $recentTitles->[0]->{postid}, $recentTitles->[0]->{title});

Another way of browsing a list of entries, is through C<getRecentPosts()> method. Use of this method
is identical to above-discussed C<getRecentPostTitles()>, but this one returns a lot more information
about each post. It can accept a single argument, denoting number of recent entries to retrieve.

Elements of the returned hash are compatible with the C<$entry> we constructed in earlier sections.

=head2 RETREIVING A SINGLE ENTRY

Sometimes, you may want to retrieve a specific entry from your web log. That's what C<getPost()>
method does. It accepts a single argument, denoting an id of the post, and returns a hashref, keys of
which are compatible with the C<$entry> we built in earlier sections (see POSTING NEW ENTRY):

    my $post = $mt->getPost(134);
    printf("Title: %s (%d)\n", $post->{title}, $post->{postid});
    printf("Excerpt: %s\n\n", $post->{mt_excerpt} );
    printf("BODY: \n%s\n", $post->{description});
    if ( $post->{mt_text_more} ) {
        printf("\nEXTENDED ENTRY:\n", $post->{mt_text_more} );
    }

=head2 EDITING ENTRY

Editing an entry means to re-post the entry. This is done almost the same way as the entry
has been published. C<editPost()> method, which is very similar in use to C<newPost()>, but accepts
a I<postid> denoting the id of the post that you are editing. Second argument should be a hashref,
describing fields of the entry. Structure of this hashref was discussed in earlier sections (see
POSTING NEW ENTRY):

    $mt->editPost($postid, $entry)


=head2 DELETING ENTRY

You can delete a specific entry from your database (and weblog) using C<deletePost()>
method. C<deletePost()> accepts at least one argument, which is the id of the post to be
deleted:

    $mt->deletePost(122);   # <-- deleting post 122


By default entries are deleted form the database, not from your web log. They usually
fade away once your web log is rebuilt. However, it may be more desirable to remove
the entry both from the database and from the web site at the same time.

This can be done by passing a true value as the second argument to C<deletePost()>. This
ensures that your pages pertaining to the deleted entry are rebuilt:

    $mt->deletePost(122, 1); # <-- delet post 122, and rebuilt the web site


=head2 UPLOADING

With I<Net::MovableType>, you can also upload files to your web site. Most common
use of this feature is to associate an image, or some other downloadable file with
your entries.

I<Net::MovableType> provides C<upload()> method, which given a file contents,
uploads it to your web site's F<archives> folder. On success, returns the URL of
the newly uploaded file.

C<upload()> method accepts either a full path to your file, or a reference to its
contents. Second argument to upload() should be the file's name. If you already provided
file's full path as the first argument, I<Net::MovableType> resolves the name of the file
automatically, if it's missing.

If you passed the contents of the file as the first argument, you are required to provide
the name of the file explicitly.

Consider the following code, which uploads a F<logo.gif> file to your web site:

    $url = $mt->upload('D:\images\logo.gif');

Following example uploads the same file, but saves it as "my-log.gif", instead of
"logo.gif":


    $url = $mt->upload('D:\images\logo.gif', 'my-logo.gif');


Following example downloads a file from some remote location, using LWP::Simple,
and uploads it to your web site with name "image.jpeg":


    use LWP::Simple;

    $content = get('http://some.dot.com/image.jpeg');
    $url = $mt->upload( \$content, 'image.jpeg' )


=head1 ERROR HANDLING

If you noticed, we didn't even try to check if any of our remote procedure calls
succeeded. This is to keep the examples as clean as possible.

For example, consider the following call:

    $new_id = $mt->newPost($entry, 1);

There is no guarantee that the above entry is posted, nor published.
You username/password might be wrong, or you made a mistake while defining your
I<mt-xmlrpc> gateway? You may never know until its too late.

That's why you should always check the return value of the methods that make a remote
procedure call.

All the methods return true on success, C<undef> otherwise. Error message from the latest
procedure call is available by calling C<errstr()> static class method. Code of the error
message (not always as useful) can be retrieved through C<errcode()> static class method:

    $new_id = $mt->newPost($entry, 1);
    unless ( defined $new_id ) {
        die $mt->errstr
    }

or just:

    $new_id = $mt->newPost($entry, 1) or die $mt->errstr;


If you are creating your I<MovableType> object with an F<rsd.xml> file, you should also
check the return value of C<new()>:

    $mt = new Net::MovableType($rsd_url);
    unless ( defined $mt ) {
        die "couldn't create MT object with $rsd_url: " . Net::MovableType->errstr
    }


=head1 OTHER METHODS

comming soon...

=head1 TEST BLOG

I opened a public test blog at http://net-mt.handalak.com/. Initial purpose of this
blog was to provide a working weblog for Net::MovableType's tests to operate on. Currently
its open to the World.

Credentials needed for accessing this weblog through Net::MovableType are:

    Username: net-mt
    Password: secret

=head1 TODO

Should implement a caching mechanism

Manual is still not complete, more methods are left to be documented properly


=head1 CREDITS

Following people have contributed to the library with their suggestions and patches.
The list may not be complete. Please help me with it.

=over 4

=item Atsushi Sano

For F<rsd.xml> and C<newMediaObject()> support.

=back

=head1 COPYRIGHT

Copyright (C) 2003, Sherzod B. Ruzmetov. All rights reserved.

This library is a free software, and can be modified and distributed under the same
terms as Perl itself.

=head1 AUTHOR

Sherzod Ruzmetov E<lt>sherzodr AT cpan.orgE<gt>

http://author.handalak.com/

=head1 SEE ALSO

L<Net::Blogger>

=cut
