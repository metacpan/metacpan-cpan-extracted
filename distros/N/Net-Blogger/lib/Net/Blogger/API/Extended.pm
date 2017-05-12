{

=head1 NAME

Net::Blogger::API::Extended - provides helper methods not defined in the Blogger API.

=head1 SYNOPSIS

 It's very dark in here because this is a black box.

=head1 DESCRIPTION

This package is inherited by I<Net::Blogger::Engine::Base> and provides helper
methods not defined in the Blogger API.

=cut

package Net::Blogger::API::Extended;
use strict;

$Net::Blogger::API::Extended::VERSION   = '1.0';
@Net::Blogger::API::Extended::ISA       = qw ( Exporter );
@Net::Blogger::API::Extended::EXPORT    = qw ();
@Net::Blogger::API::Extended::EXPORT_OK = qw ();

use Exporter;
use FileHandle;

=head1 OBJECT METHODS

=head2 $pkg->MaxPostLength

Abstract method for returning the max post length

=cut

sub MaxPostLength {
    return undef;
}

=head2 $pkg->GetBlogId(\%args)

Return the unique blogid for I<$args{'blogname'}>.

Valid arguments are

=over

=item *

B<blogname> => string.

=back

Releases prior to Net::Blogger 0.85 accepted a list of arguments
rather than a reference. Version 0.85+ are backwards compatible.

Returns a string. If no blogname is specified, the current blogid for
the object is returned.

=cut

sub GetBlogId {
    my $self = shift;
    my $args = (ref($_[0]) eq "HASH") ? shift : { @_ };

    my $blogid = undef;

    if (! $args->{'blogname'}) {
	return $self->{'_blogid'};
    }

    my $blogs = $self->getUsersBlogs()
	|| return undef;

    foreach my $b (@$blogs) {
	if ($b->{'blogName'} eq $args->{'blogname'}) {
	    $blogid = $b->{'blogid'};
	    last;
	}
    }

    return $blogid;
}

=head2 $pkg->DeleteAllPosts(\%args)

Delete all the posts on a weblog. Valid arguments are :

=over 4

=item *

B<publish>

Boolean.

=back

Releases prior to Net::Blogger 0.85 accepted a list of arguments
rather than a reference. Version 0.85+ are backwards compatible.

Returns true or false.

=cut

sub DeleteAllPosts {
    my $self = shift;
    my $args = { @_ };

    my ($ok,@pids) = $self->getRecentPosts(numposts=>20);

    while (@pids) {
	foreach my $p (@pids) {
	    $self->deletePost(postid=>$p->{'postid'},publish=>$args->{'publish'});
	}

	($ok,@pids) = $self->getRecentPosts(numposts=>20);
    }

    return $ok;
}

=head2 $pkg->PostFromFile(\%args)

Open a filehandle, and while true, post to Blogger. If the length of the amount
read from the file exceeds the per-post limit assigned by the Blogger servers --
currently 65,536 characters -- the contents of the file will be posted in multiple
"chunks".

Valid arguments are

=over

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

If true, the method will not attempt to post data whose length exceeds the limit
set by the Blogger server in the order that the data is read. Translation : last
in becomes last post becomes the first thing you see on your weblog.

=back

If a I<postid> argument is present, the method will call the Blogger API I<editPost>
method with postid. Otherwise the method will call the Blogger API I<newPost> method.

Releases prior to Net::Blogger 0.85 accepted a list of arguments
rather than a reference. Version 0.85+ are backwards compatible.

Returns true or false, followed by an array of zero, or more, postids.

=cut

sub PostFromFile {
    my $self = shift;
    my $args = (ref($_[0]) eq "HASH") ? shift : { @_ };

    if (! -f $args->{'file'}) {
      $self->LastError("Not a file.");
	return 0;
    }

    my $fh = FileHandle->new();
    my $ok = $fh->open("<$args->{'file'}");

    if (! $ok) {
      $self->LastError("Failed to open file : $!");
	return 0;
    }

    my $method  = ($args->{'postid'}) ? "editPost" : "newPost";

    if (! $args->{'tail'}) {

	local $/;
	undef $/;

	my $postbody = <$fh>;
	$fh->close();

	return $self->$method(postbody=>\$postbody,%$args);
    }

    my $post    = "";
    my @postids = ();

    while (<$fh>) {
	my $line = $_;
	chomp $line;

	$post  .= $line;
	my $len = length($post);

	if (($self->MaxPostLength()) && ($len > $self->MaxPostLegth())) {

	    my $postbody  = substr($post,0,$self->MaxPostLength());
	    my $remainder = $self->_TrimPostBody(\$postbody);

	    my ($pid) = $self->$method(
				       postbody => \$postbody,
				       postid   => $args->{'postid'},
				       publish  => $args->{'publish'},
				       );

	    if (! $pid) {
		$fh->close();

	      $self->LastError("Encountered an error posting. Exiting prematurely.");
		return (0,@postids);
	    }

	    push(@postids,$pid);
	    $post = $remainder.substr($post,$self->MaxPostLength(),$len);
	}
    }

    $fh->close();

    if (! $post) {
      $self->LastError("Failed to read any data from file.");
	return 0;
    }

    my ($pid) = $self->$method(
			       postbody => \$post,
			       postid   => $args->{'postid'},
			       publish  => $args->{'publish'},
			       );

    if (! $pid) {
      $self->LastError("Encountered an error posting last chunk : ".Error->prior());
	return (0, @postids);
    }

    push (@postids,$pid);
    return (1,@postids);
}

=head2 $pkg->PostFromOutline(\%args)

Like I<PostFromFile>, only this time the file is an outliner document.

This method uses Simon Kittle's Text::Outline::asRenderedHTML method for
posting. As of this writing, the Text::Outline package has not been uploaded
to the CPAN. See below for a link to the homepage/source.

Valid outline formats are OPML, tabbed text outline, Emacs' outline-mode format,
and the GNOME Think format.

Valid arguments are

=over

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

If a I<postid> argument is present, the method will call the Blogger API I<editPost>
method with postid. Otherwise the method will call the Blogger API I<newPost> method.

Releases prior to Net::Blogger 0.85 accepted a list of arguments
rather than a reference. Version 0.85+ are backwards compatible.

Returns true or false, followed by an array of zero, or more, postids.

=cut

sub PostFromOutline {
    my $self = shift;
    my $args = (ref($_[0]) eq "HASH") ? shift : { @_ };

    my $class = "Text::Outline";

    # We'll get rid of this when, and if, a proper
    # Makefile is ever written...
    eval "require $class"
	|| &{ $self->LastError($@); return 0; };

    my $outline = $class->new(load=>$args->{'file'})
	|| &{ $self->LastError($!); return 0; };

    my $postbody = $outline->asRenderedHTML();

    my $method   = ($args->{'postid'}) ? "editPost" : "newPost";

    return $self->$method(postbody=>\$postbody,%$args);
}

sub _PostInChunks {
    my $self = shift;
    my $args = (ref($_[0]) eq "HASH") ? shift : { @_ };

    my $caller  = (caller(1))[3];
    my @chunks  = ();
    my @postids = ();

    unless ($caller =~ /^(Net::Blogger::Base::API::)(editPost|newPost)$/) {
	$self->LastError("$caller is not a valid caller for this method.");
	return 0;
    }

    my $text = $args->{"postbody"};

    while ( $$text ) {
	my $chunk     = substr($$text,0,$self->MaxPostLength());
	my $remainder = $self->_TrimPostBody(\$chunk);

	$$text = $remainder.substr($$text,length($chunk),length($$text));

	# Since Blogger posts are chronological, we add chunks
	# to the top of the stack. That way, the 'end' pieces get
	# added first and, in the end, the text will be displayed
	# in the order it was written.
	# 20010813 (asc)

	unshift (@chunks, \$chunk);
    }

    map {
	$args->{"postbody"} = $_;
	push(@postids, $self->$caller(%$args));
    } @chunks;

    return @postids;
}

sub _TrimPostBody {
    my $self = shift;
    my $body = shift;

    if (ref($body) ne "SCALAR") {
	$self->LastError("Input must be a scalar ref.");
	return undef;
    }
}

=head1 VERSION

1.0

=head1 DATE

$Date: 2005/03/26 19:29:08 $

=head1 AUTHOR

Aaron Straup Cope

=head1 SEE ALSO

L<Net::Blogger::Engine::Base>

L<Net::Blogger::API::Core>

=head1 LICENSE

Copyright (c) 2001-2005 Aaron Straup Cope.

This is free software, you may use it and distribute it under the same terms as Perl itself.

=cut

return 1;

}
