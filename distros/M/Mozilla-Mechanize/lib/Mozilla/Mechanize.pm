package Mozilla::Mechanize;
use strict;
use warnings;

# $Id: Mechanize.pm,v 1.4 2005/10/07 12:17:20 slanning Exp $
our $VERSION = '0.06';

use Glib qw(FALSE G_PRIORITY_LOW);
use URI;

use Mozilla::DOM '0.22';
use Mozilla::Mechanize::Browser;
use Mozilla::Mechanize::Form;
use Mozilla::Mechanize::Input;
use Mozilla::Mechanize::Link;
use Mozilla::Mechanize::Image;

=head1 NAME

Mozilla::Mechanize - Like WWW::Mechanize but using Gtk2::MozEmbed

=head1 SYNOPSIS

    use Mozilla::Mechanize;

    my $moz = Mozilla::Mechanize->new();

    $moz->get( $url );

    $moz->follow_link( text => $link_txt );

    $moz->form_name( $form_name );
    $moz->set_fields(
        username => 'yourname',
        password => 'dummy'
    );
    $moz->click( $btn_name );

    # Or all in one go:
    $moz->submit_form(
        form_name => $form_name,
        fields    => {
            username => 'yourname',
            password => 'dummy',
        },
        button    => $btn_name,
    );

=begin comment

XXX: not sure how to add headers
(necko/nsIHttpAuthenticator.h ?)

Now also tries to support Basic-Authentication like LWP::UserAgent

    use Mozilla::Mechanize;

    my $moz = Mozilla::Mechanize->new( visible => 1 );

    $moz->credentials( 'pause.perl.org:443', 'PAUSE', 'abeltje', '********' );
    $moz->get( 'https://pause.perl.org/pause/authenquery' );

=end comment

=head1 DESCRIPTION

This module tries to be a sort of drop-in replacement for
L<WWW::Mechanize|WWW::Mechanize>. It uses Mozilla's Gecko HTML-rendering
engine via the modules L<Mozilla::DOM|Mozilla::DOM> and
L<Gtk2::MozEmbed|Gtk2::MozEmbed>.

Don't expect it to be like L<WWW::Mechanize|WWW::Mechanize>
in that the class is not derived from the user-agent class (like LWP).

B<WARNING: this was quickly ported from Win32::IE::Mechanize.
The docs are incomplete and may still refer to the Win32 module.
Some methods are unimplemented.>

Comment from Abe, which I echo: Thank you Andy Lester for
L<WWW::Mechanize|WWW::Mechanize>. I ported a lot of that code
and nicked most of your documentation!

Ditto from me regarding Abe Timmerman's L<Win32::IE::Mechanize|Win32::IE::Mechanize>.

=head1 CONSTRUCTION AND PROPERTIES

=cut


my %moz_property = (
#    addressbar => { type => 'b', value => undef },
    fullscreen => { type => 'b', value => 0 },
#    resizable  => { type => 'b', value => undef },
#    statusbar  => { type => 'b', value => undef },
#    toolbar    => { type => 'b', value => undef },
    visible    => { type => 'b', value => 1     },
    width      => { type => 'n', value => 600   },
    height     => { type => 'n', value => 400   },
#    left       => { type => 'n', value => undef },
#    top        => { type => 'n', value => undef },
);


=head2 Mozilla::Mechanize->new( [%options] )

This initializes a new browser window and sets all the
properties that are passed via the C<%options> hash(ref).
Currently supported options are: quiet, onwarn, onerror.

B<XXX: most `set_property' %options aren't currently supported>.
Currently supported Browser options are: height, width, visible,
fullscreen.
See C<L<set_property()>>.

=cut

sub new {
    my $class = shift;

    my $self = bless {
        _opt    => {},
        onwarn  => \&Mozilla::Mechanize::__warn,
        onerror => \&Mozilla::Mechanize::__die,
        quiet   => 0,
        debug   => 0,
    }, $class;

    my %opt = @_ ? UNIVERSAL::isa( $_[0], 'HASH' ) ? %{ $_[0] } : @_ : ();

#    $self->{_opt} = { map {
#        ( $_ => __prop_value( $_, $opt{ $_ } ) )
#    } grep exists $moz_property{ lc $_ } => keys %opt };
    # Sets all default values (before it only set ones passed in)
    $self->{_opt} = { map {
        my $prop = lc $_;
        ($prop => __prop_value($prop, $opt{$prop}))
    } keys %moz_property };

    # some more options not for Browser
    $self->{$_} = exists $opt{$_} ? $opt{$_} : undef
        for qw(quiet debug onwarn onerror);

    $self->open();
}

=head2 $moz->set_property( %opt )

B<XXX: this method is currently not supported. You can only set
certain options through `new' (which see).>

Allows you to set these supported properties:

=over 4

=item B<visible>

Set the visibility of the Browser window. Setting this to 0
iconifies the window, while setting it to 1 deiconifies it.
I'd be very happy if it wasn't necessary to even create a window,
but I don't believe it's possible because of the way Mozilla
is implemented (layout and DOM are apparently tightly coupled).

=item B<height>

Set the height of the Browser window.

=item B<width>

Set the width of the Browser window.

=item B<addressbar> (NOT SUPPORTED)

Set the visibility of the addressbar

=item B<fullscreen>

Set the Browser window to fullscreen. Setting it false unfullscreens.

=item B<resizable> (NOT SUPPORTED)

Set the resize-ability

=item B<statusbar> (NOT SUPPORTED)

Set the visibility of the statusbar

=item B<toolbar> (NOT SUPPORTED)

Set the visibility of the toolbar

=item B<left> (NOT SUPPORTED)

Set the left coordinate of the Browser window

=item B<top> (NOT SUPPORTED)

Set the top-coordinate of the Browser window

=back

=cut

sub set_property {
    my $self = shift;

    my %raw = @_ ? UNIVERSAL::isa( $_[0], 'HASH' ) ? %{ $_[0] } : @_ : ();
    my %opt = map {
        ( $_ => __prop_value( $_, $raw{ $_ } ) )
    } grep exists $moz_property{ lc $_ } => keys %raw;

    foreach my $prop ( keys %opt ) {
        defined $opt{ $prop } and
          $self->agent->{ $prop } = $opt{ $prop };
    }
}

=head2 $moz->close

Close the Browser.

=cut

sub close {
    my $self = shift;
    $self->agent->quit();
    $self->{agent} = undef;

    # XXX: do we need to run the GUI here?
}

sub open {
    my $self = shift;
    defined $self->{agent} and return;

    my $browser_opts = $self->{_opt};
    $browser_opts->{debug} = $self->{debug};

    $self->{agent} = Mozilla::Mechanize::Browser->new($browser_opts)
      or $self->die("Cannot create a new Browser");

#    foreach my $prop ( keys %{ $self->{_opt} } ) {
#        defined $self->{_opt}{ $prop } and
#            $self->{agent}->{ $prop } = $self->{_opt}{ $prop };
#    }

    return $self;
}

=head2 $moz->agent

Return a reference to the Browser object.

=cut

sub agent { $_[0]->{agent} }


=head1 PAGE-FETCHING METHODS

=head2 $moz->get( $url )

Fetch C<$url>.

=cut

sub get {
    my $self = shift;
    my $agent = $self->agent;
    my ($url) = @_;

    my $uri = $self->uri
        ? URI->new_abs($url, $self->uri->as_string)
        : URI->new($url);

    # XXX: how to add headers?
#    $agent->navigate({ URL     => $uri->as_string,
#                       Headers => $self->_extra_headers($uri) });

    $agent->embedded->load_url($uri->as_string);
    $self->_wait_while_busy;
}

=head2 $moz->reload()

Reload the page.

=cut

sub reload {
    $_[0]->agent->embedded->reload('reloadnormal');
    $_[0]->_wait_while_busy;
}

=head2 $moz->back()

Go back a page in the browser history.

=cut

sub back {
    $_[0]->agent->embedded->go_back;
    $_[0]->_wait_while_busy;
}

=head1 STATUS METHODS

=head2 $moz->success

B<XXX: I don't know how to implement this yet.
So this always returns true for now.>
In fact, if a URL doesn't exist, it'll pop up a dialog. :/

=cut

sub success {
#    $_[0]->agent->ReadyState >= 2;

    # XXX: uh??

    return 1;
}

=head2 $moz->uri

Return the URI of this document (as a URI object).
Note: whenever you do a submit, Mozilla appends a question mark
followed by any form input (name=value pairs separated by ampersands).

=cut

sub uri {
    my $self = shift;
    my $agent = $self->agent;
    my $embed = $agent->embedded;
    my $uri = $embed->get_location;
    URI->new($uri);
}

=head2 $moz->ct

Fetch the content-type of the document.

=cut

sub ct {
    my $self = shift;

    my $doc = $self->get_document;
    my $diid = Mozilla::DOM::NSDocument->GetIID;
    my $nsdoc = $doc->QueryInterface($diid);
    return $nsdoc->GetContentType;
}

=head2 $moz->current_form

Returns the current form as a C<Mozilla::Mechanize::Form> object.

=cut

sub current_form {
    my $self = shift;
    defined $self->{cur_form} or $self->form_number( 1 );
    $self->{cur_form};
}

=head2 $moz->is_html

Return true if this is an HTML Document.

=cut

sub is_html {
    my $self = shift;
    return $self->ct eq 'text/html';
}

=head2 $moz->title

Fetch the C<title> from the document.

=cut

sub title { $_[0]->agent->embedded->get_title }


=head1 CONTENT-HANDLING METHODS

=head2 $moz->content

Fetch the HTML of the document. This won't exactly match
the HTML that's sent by the server... (The DOCTYPE/DTD will not
be there, the <html> element is kind of generated so its attributes
might be rearranged, and some linebreaks might be missing.)

=cut

sub content {
    my $self = shift;
    my $embed = $self->agent->embedded;
    my $html = '';

    # Boohoo, no outerHTML
    my $docelem = $self->get_document_element();

    # Try to output <html> with any attributes
    $html .= '<' . lc($docelem->GetNodeName);
    if ($docelem->HasAttributes) {
        $html .= ' ';
        my $attrs = $docelem->GetAttributes;
        for (my $i = 0; $i < $attrs->GetLength; $i++) {
            my $attr = $attrs->Item($i);
            $html .= $attr->GetNodeName . '="' . $attr->GetNodeValue . '" ';
        }
    }
    $html .= ">\n";

    # Add <body> ... </body>
    my $iid = Mozilla::DOM::NSHTMLElement->GetIID;
    my $nshtmlelement = $docelem->QueryInterface($iid);
    $html .= $nshtmlelement->GetInnerHTML;

    # Add back the closing html tag
    $html .= "\n</html>\n";

    return $html;
}

=head1 LINK METHODS

=head2 $moz->links

When called in a list context, returns a list of the links found in
the last fetched page. In a scalar context it returns a reference to
an array with those links. The links returned are all
C<Mozilla::Mechanize::Link> objects.

=cut

sub links {
    my $self = shift;

    defined $self->{links} or $self->{links} = $self->_extract_links();

    return wantarray ? @{ $self->{links} } : $self->{links};
}

=head2 $moz->follow_link( %opt )

Uses the C<< $self->find_link() >> interface to locate a link and
C<< $self->get() >> it.

=cut

sub follow_link {
    my $self = shift;
    my %parms = ( n => 1, @_ );

    if ( $parms{n} eq "all" ) {
        delete $parms{n};
        $self->warn( qq{follow_link( n => "all" ) is not valid} );
    }

    my $link = $self->find_link( @_ );
    $self->get( $link->url ) if $link;
}

=head2 $moz->find_link( [%options] )

This method finds a link in the currently fetched page. It returns a
L<Mozilla::Mechanize::Link> object which describes the link.  (You'll probably
be most interested in the C<url()> property.)  If it fails to find a
link it returns undef.

You can take the URL part and pass it to the C<get()> method.  If that's
your plan, you might as well use the C<follow_link()> method directly,
since it does the C<get()> for you automatically.

Note that C<< <FRAME SRC="..."> >> tags are parsed out of the the HTML
and treated as links so this method works with them.

You can select which link to find by passing in one or more of these
key/value pairs:

=over 4

=item * C<< text => 'string', >> and C<< text_regex => qr/regex/, >>

C<text> matches the text of the link against I<string>, which must be an
exact match.  To select a link with text that is exactly "download", use

    $mech->find_link( text => "download" );

C<text_regex> matches the text of the link against I<regex>.  To select a
link with text that has "download" anywhere in it, regardless of case, use

    $mech->find_link( text_regex => qr/download/i );

Note that the text extracted from the page's links are trimmed.  For
example, C<< <a> foo </a> >> is stored as 'foo', and searching for
leading or trailing spaces will fail.

=item * C<< url => 'string', >> and C<< url_regex => qr/regex/, >>

Matches the URL of the link against I<string> or I<regex>, as appropriate.
The URL may be a relative URL, like F<foo/bar.html>, depending on how
it's coded on the page.

=item * C<< url_abs => string >> and C<< url_abs_regex => regex >>

Matches the absolute URL of the link against I<string> or I<regex>,
as appropriate.  The URL will be an absolute URL, even if it's relative
in the page.

=item * C<< name => string >> and C<< name_regex => regex >>

Matches the name of the link against I<string> or I<regex>, as appropriate.

=item * C<< tag => string >> and C<< tag_regex => regex >>

Matches the tag that the link came from against I<string> or I<regex>,
as appropriate.  The C<tag_regex> is probably most useful to check for
more than one tag, as in:

    $mech->find_link( tag_regex => qr/^(a|frame)$/ );

The tags and attributes looked at are defined below, at
L<$mech->find_link() : link format>.

=item * C<< n => number >>

=back

The C<n> parms can be combined with the C<text*> or C<url*> parms
as a numeric modifier.  For example,
C<< text => "download", n => 3 >> finds the 3rd link which has the
exact text "download".

If C<n> is not specified, it defaults to 1.  Therefore, if you don't
specify any parms, this method defaults to finding the first link on the
page.

Note that you can specify multiple text or URL parameters, which
will be ANDed together.  For example, to find the first link with
text of "News" and with "cnn.com" in the URL, use:

    $moz->find_link( text => "News", url_regex => qr/cnn\.com/ );

=cut

sub find_link {
    my $self = shift;
    my %parms = ( n=>1, @_ );

    my $wantall = ( $parms{n} eq "all" );

    $self->_clean_keys(
        \%parms,
        qr/^(n|(text|url|url_abs|name|tag)(_regex)?)$/
    );

    my @links = $self->links or return;

    my $nmatches = 0;
    my @matches;
    for my $link ( @links ) {
        if ( _match_any_link_parms($link,\%parms) ) {
            if ( $wantall ) {
                push( @matches, $link );
            } else {
                ++$nmatches;
                return $link if $nmatches >= $parms{n};
            }
        }
    } # for @links

    if ( $wantall ) {
        return @matches if wantarray;
        return \@matches;
    }

    return;
}

# Stolen from WWW::Mechanize-1.08
# Used by find_links to check for matches
# The logic is such that ALL parm criteria that are given must match
sub _match_any_link_parms {
    my $link = shift;
    my $p = shift;

    # No conditions, anything matches
    return 1 unless keys %$p;

    return if defined $p->{url}
        and !( $link->url eq $p->{url} );
    return if defined $p->{url_regex}
        and !( $link->url =~ $p->{url_regex} );
    return if defined $p->{url_abs}
        and !( $link->url_abs eq $p->{url_abs} );
    return if defined $p->{url_abs_regex}
        and !( $link->url_abs =~ $p->{url_abs_regex} );
    return if defined $p->{text}
        and !( defined($link->text) and $link->text eq $p->{text} );
    return if defined $p->{text_regex}
        and !( defined($link->text) and $link->text =~ $p->{text_regex} );
    return if defined $p->{name}
        and !( defined($link->name) and $link->name eq $p->{name} );
    return if defined $p->{name_regex}
        and !( defined($link->name) and $link->name =~ $p->{name_regex} );
    return if defined $p->{tag}
        and !( $link->tag and lc( $link->tag ) eq lc( $p->{tag} ) );
    return if defined $p->{tag_regex}
        and !( $link->tag and $link->tag =~ $p->{tag_regex} );

    # Success: everything that was defined passed.
    return 1;
}

# Cleans the %parms parameter for the find_link and find_image methods.
sub _clean_keys {
    my $self = shift;
    my $parms = shift;
    my $rx_keyname = shift;

    for my $key ( keys %$parms ) {
        my $val = $parms->{$key};
        if ( $key !~ qr/$rx_keyname/ ) {
            $self->warn( qq{Unknown link-finding parameter "$key"} );
            delete $parms->{$key};
            next;
        }

        my $key_regex = ( $key =~ /_regex$/ );
        my $val_regex = ( ref($val) eq "Regexp" );

        if ( $key_regex ) {
            if ( !$val_regex ) {
                $self->warn( qq{$val passed as $key is not a regex} );
                delete $parms->{$key};
                next;
            }
        } else {
            if ( $val_regex ) {
                $self->warn( qq{$val passed as '$key' is a regex} );
                delete $parms->{$key};
                next;
            }
            if ( $val =~ /^\s|\s$/ ) {
                $self->warn( qq{'$val' is space-padded and cannot succeed} );
                delete $parms->{$key};
                next;
            }
        }
    } # for keys %parms
} # _clean_keys()

=head2 $moz->find_all_links( %opt )

Returns all the links on the current page that match the criteria.
The method for specifying link criteria is the same as in
C<find_link()>.  Each of the links returned is in the same format
as in C<find_link()>.

In list context, C<find_all_links()> returns a list of the links.
Otherwise, it returns a reference to the list of links.

C<find_all_links()> with no parameters returns all links in the
page.

=cut

sub find_all_links {
    my $self = shift;
    $self->find_link( @_, n => 'all' );
}

=head1 IMAGE METHODS

=head2 $moz->images

Lists all the images on the current page.  Each image is a
Mozilla::Mechanize::Image object. In list context, returns a list of all
images.  In scalar context, returns an array reference of all images.

B<NOTE>: Although L<WWW::Mechanize> explicitly only supports
    <INPUT type=submit src="...">
constructs, this is B<not> supported by IE, it must be:
    <INPUT type=image src="...">
for IE to behave as expected.
(XXX: not sure if this is true for Mozilla::Mechanize)

=cut

sub images {
    my $self = shift;

    $self->_extract_images unless defined $self->{images};

    return wantarray ? @{ $self->{images} } : $self->{images};
}

=head2 $moz->find_image()

Finds an image in the current page. It returns a
L<Mozilla::Mechanize::Image> object which describes the image.  If it fails
to find an image it returns undef.

You can select which link to find by passing in one or more of these
key/value pairs:

=over 4

=item * C<< alt => 'string' >> and C<< alt_regex => qr/regex/, >>

C<alt> matches the ALT attribute of the image against I<string>, which must be a
n
exact match. To select a image with an ALT tag that is exactly "download", use

    $moz->find_image( alt  => "download" );

C<alt_regex> matches the ALT attribute of the image  against a regular
expression.  To select an image with an ALT attribute that has "download"
anywhere in it, regardless of case, use

    $moz->find_image( alt_regex => qr/download/i );

=item * C<< url => 'string', >> and C<< url_regex => qr/regex/, >>

Matches the URL of the image against I<string> or I<regex>, as appropriate.
The URL may be a relative URL, like F<foo/bar.html>, depending on how
it's coded on the page.

=item * C<< url_abs => string >> and C<< url_abs_regex => regex >>

Matches the absolute URL of the image against I<string> or I<regex>,
as appropriate.  The URL will be an absolute URL, even if it's relative
in the page.

=item * C<< tag => string >> and C<< tag_regex => regex >>

Matches the tag that the image came from against I<string> or I<regex>,
as appropriate.  The C<tag_regex> is probably most useful to check for
more than one tag, as in:

    $moz->find_image( tag_regex => qr/^(img|input)$/ );

The tags supported are C<< <img> >> and C<< <input> >>.

=back

If C<n> is not specified, it defaults to 1.  Therefore, if you don't
specify any parms, this method defaults to finding the first image on the
page.

Note that you can specify multiple ALT or URL parameters, which
will be ANDed together.  For example, to find the first image with
ALT text of "News" and with "cnn.com" in the URL, use:

    $moz->find_image( image => "News", url_regex => qr/cnn\.com/ );

The return value is a reference to an array containing a
L<Mozilla::Mechanize::Image> object for every image in C<< $self->content >>.

=cut

sub find_image {
    my $self = shift;
    my %parms = ( n=>1, @_ );

    my $wantall = ( $parms{n} eq "all" );

    $self->_clean_keys( \%parms, qr/^(n|(alt|url|url_abs|tag)(_regex)?)$/ );

    my @images = $self->images or return;

    my $nmatches = 0;
    my @matches;
    for my $image ( @images ) {
        if ( _match_any_image_parms($image,\%parms) ) {
            if ( $wantall ) {
                push( @matches, $image );
            } else {
                ++$nmatches;
                return $image if $nmatches >= $parms{n};
            }
        }
    } # for @images

    if ( $wantall ) {
        return @matches if wantarray;
        return \@matches;
    }

    return;
}

# Used by find_images to check for matches
# The logic is such that ALL parm criteria that are given must match
sub _match_any_image_parms {
    my $image = shift;
    my $p = shift;

    # No conditions, anything matches
    return 1 unless keys %$p;

    return if defined $p->{url}
        and !( $image->url eq $p->{url} );
    return if defined $p->{url_regex}
        and !( $image->url =~ $p->{url_regex} );
    return if defined $p->{url_abs}
        and !( $image->url_abs eq $p->{url_abs} );
    return if defined $p->{url_abs_regex}
        and !( $image->url_abs =~ $p->{url_abs_regex} );
    return if defined $p->{alt}
        and !( defined($image->alt) and $image->alt eq $p->{alt} );
    return if defined $p->{alt_regex}
        and !( defined($image->alt) and $image->alt =~ $p->{alt_regex} );
    return if defined $p->{tag}
        and !( $image->tag and lc( $image->tag ) eq lc( $p->{tag} ) );
    return if defined $p->{tag_regex}
        and !( $image->tag and $image->tag =~ $p->{tag_regex} );

    # Success: everything that was defined passed.
    return 1;
}

=head2 $moz->find_all_images( ... )

Returns all the images on the current page that match the criteria.  The
method for specifying image criteria is the same as in C<L<find_image()>>.
Each of the images returned is a L<Mozilla::Mechanize::Image> object.

In list context, C<find_all_images()> returns a list of the images.
Otherwise, it returns a reference to the list of images.

C<find_all_images()> with no parameters returns all images in the
page.


=cut

sub find_all_images {
    my $self = shift;
    return $self->find_image( @_, n=>'all' );
}

=head1 FORM METHODS

=head2 $moz->forms

Lists all the forms on the current page.  Each form is an
Mozilla::Mechanize::Form object.  In list context, returns a list of all forms.
In scalar context, returns an array reference of all forms.

=cut

sub forms {
    my $self = shift ;
    $self->_extract_forms unless defined $self->{forms};

    return wantarray ? @{ $self->{forms} } : $self->{forms};
}

=head2 $moz->form_number( $number )

Selects the numberth form on the page as the target for subsequent
calls to field() and click().  Also returns the form that was
selected.  Emits a warning and returns undef if there is no such form.
Forms are indexed from 1, so the first form is number 1, not zero.

=cut

sub form_number {
    my $self = shift;

    my $number = shift || 1;
    $self->_extract_forms unless defined $self->{forms};
    if ( @{ $self->{forms} } && $number <= @{ $self->{forms} } ) {
        $self->{cur_form} = $self->{forms}[ $number - 1 ];
    } else {
        $self->warn( "There is no form numbered $number." );
        return undef;
    }
}

=head2 $moz->form_name( $name )

Selects a form by name.  If there is more than one form on the page
with that name, then the first one is used, and a warning is
generated.  Also returns the form itself, or undef if it is not
found.

=cut

sub form_name {
    my $self = shift;

    my $name = shift or return undef;
    $self->_extract_forms unless defined $self->{forms};
    my @matches = grep $_->name && $_->name eq $name => @{ $self->{forms} };
    if ( @matches ) {
        $self->warn( "There are " . scalar @matches . "forms named '$name'. " .
                     "The first one was used." ) if @matches > 1;
        $self->{cur_form} = $matches[0];
    } else {
        $self->warn( "There is no form named '$name'." );
        return undef;
    }
}

=head2 $moz->field( $name[, $value[, $index]] )

=head2 $moz->field( $name, \@values[, $number ] )

Given the name of a field, set its value to the value specified.  This
applies to the current form (as set by the C<L<form_name()>> or
C<L<form_number()>> method or defaulting to the first form on the page).

The optional I<$number> parameter is used to distinguish between two fields
with the same name. The fields are numbered from 1.

=cut

sub field {
    my $self = shift;

    my( $name, $value, $index ) = @_;
    my $form = $self->current_form;

    my @inputs = $form->find_input( $name );
    $self->debug('field: num inputs = ' . scalar(@inputs));

    @inputs or $self->warn( "No '$name' parameter exists" );
    $index ||= 1;
    my $control = $inputs[ $index - 1 ];
    defined $value ? $control->value( $value ) : $control->value();
}

=head2 $moz->select( $name, $value )

=head2 $moz->select( $name, \@values )

Given the name of a C<select> field, set its value to the value
specified.  If the field is not E<lt>select multipleE<gt> and the
C<$value> is an array, only the B<first> value will be set. Passing
C<$value> as a hash with an C<n> key selects an item by number
(e.g. C<{n => 3> or C<{n => [2,4]}>).  The numbering starts at 1.
This applies to the current form (as set by the C<L<form()>> method or
defaulting to the first form on the page).

Returns 1 on successfully setting the value. On failure, returns
undef and calls C<$self->warn()> with an error message.

=cut

sub select {
    my $self = shift;
    my( $name, $value ) = @_;

    my $form = $self->current_form;
    my $input = $form->find_input( $name, 'select' );
    if ( !$input ) {
        $self->warn( "Select '$name' not found." );
        return;
    }
    $input->select_value( $value );
    return 1;
}

=head2 $moz->set_fields( %arguments )

This method sets multiple fields of a form. It takes a list of field
name and value pairs. If there is more than one field with the same
name, the first one found is set. If you want to select which of the
duplicate field to set, use a value which is an anonymous array which
has the field value and its number as the 2 elements.

        # set the second foo field
        $moz->set_fields( $name => [ 'foo', 2 ] ) ;

The fields are numbered from 1.

This applies to the current form (as set by the C<L<form_name()>> or
C<L<form_number()>> method or defaulting to the first form on the
page).

=cut

sub set_fields {
    my $self = shift;

    my $form = $self->current_form;
    my %opt = @_ ? UNIVERSAL::isa( $_[0], 'HASH' ) ? %{ $_[0] } : @_ : ();
    while ( my( $fname, $value ) = each %opt ) {
        if ( ref $value eq 'ARRAY' ) {
            my( $input ) = $form->find_input( $fname, undef, $value->[1] );
            if ( $input ) {
                $input->value( $value->[0] );
            } else {
                $self->warn( "No inputcontrol by the name '$fname'" );
            }
        } else {
            my( $input ) = $form->find_input( $fname );
            if ( $input ) {
                $input->value( $value );
            } else {
                $self->warn( "No inputcontrol by the name '$fname'" );
            }
        }
    }
}

=head2 $moz->set_visible( @criteria )

This method sets fields of a form without having to know their
names.  So if you have a login screen that wants a username and
password, you do not have to fetch the form and inspect the source
to see what the field names are; you can just say

    $moz->set_visible( $username, $password ) ;

and the first and second fields will be set accordingly.  The method
is called set_I<visible> because it acts only on visible fields;
hidden form inputs are not considered.  The order of the fields is
the order in which they appear in the HTML source which is nearly
always the order anyone viewing the page would think they are in,
but some creative work with tables could change that; caveat user.

Each element in C<@criteria> is either a field value or a field
specifier.  A field value is a scalar.  A field specifier allows
you to specify the I<type> of input field you want to set and is
denoted with an arrayref containing two elements.  So you could
specify the first radio button with

    $moz->set_visible( [ radio => "KCRW" ] ) ;

Field values and specifiers can be intermixed, hence

    $moz->set_visible( "fred", "secret", [ select => "Checking" ] ) ;

would set the first two fields to "fred" and "secret", and the I<next>
C<OPTION> menu field to "Checking".

The possible field specifier types are: "text", "password", "hidden",
"textarea", "file", "image", "submit", "radio", "checkbox" and "select".

This method was ported from L<WWW::Mechanize>.

=cut

sub set_visible {
    my $self = shift;

    my $form = $self->current_form;
    my @inputs = $form->inputs;

    while (my $value = shift) {
        if (ref $value eq 'ARRAY') {
           my ($type, $val) = @$value;
           while (my $input = shift @inputs) {
               next if $input->type eq 'hidden';
               if ($input->type eq $type) {
                   $input->value($val);
                   last;
               }
           }
        } else {
           while (my $input = shift @inputs) {
               next if $input->type eq 'hidden';
               $input->value($value);
               last;
           }
       }
    }
}

=head2 $moz->tick( $name, $value[, $set] )

'Ticks' the first checkbox that has both the name and value assoicated
with it on the current form.  Dies if there is no named check box for
that value.  Passing in a false value as the third optional argument
will cause the checkbox to be unticked.

=cut

sub tick {
    my $self = shift;

    my $form = $self->current_form;

    my( $name, $value, $set ) = @_;
    $set = 1 if @_ <= 2;
    my @check_boxes = grep $_->value eq $value
        => $form->find_input( $name, 'checkbox' );

    $self->warn( "No checkbox '$name'  for value '$value' in form." ), return
        unless @check_boxes;

    foreach my $check_box ( @check_boxes ) {
        next unless $check_box->value eq $value;
        # XXX: breaks encapsulation
        $check_box->{input}->SetChecked($set || 0);
    }
    return 1;
}

=head2 $moz->untick( $name, $value )

Causes the checkbox to be unticked. Shorthand for
C<tick( $name, $value, undef)>

=cut

sub untick {
    my $self = shift;
    $self->tick( @_[0, 1], undef );
}

=head2 $mech->value( $name, $number )

Given the name of a field, return its value. This applies to the current
form (as set by the C<form()> method or defaulting to the first form on
the page).

The option I<$number> parameter is used to distinguish between two fields
with the same name.  The fields are numbered from 1.

If the field is of type file (file upload field), the value is always
cleared to prevent remote sites from downloading your local files.
To upload a file, specify its file name explicitly.

=cut

sub value {
    my $self = shift;
    my $name = shift;
    my $number = shift || 1;

    my $form = $self->current_form;
    if ( wantarray ) {
        my @inputs = $form->find_input( $name );
        return @inputs ? map $_->value() => @inputs : undef;
    }
    if ( $number > 1 ) {
        return $form->find_input( $name, undef, $number )->value();
    } else {
        return $form->value( $name );
    }
}

=head2 $moz->click( $button )

Call the click method on an INPUT object with the name C<$button>. Has
the effect of clicking a button on a form.  The first argument is the
name of the button to be clicked. I have not found a way to set the
(x,y) coordinates of the click.

Note: inputs are searched in the order: buttons, images, submits.

=cut

sub click {
    my ($self, $button) = @_;

    my $form = $self->current_form;

    # XXX: this is unsorted
    my ($toclick) = (
        $form->find_input( $button, 'button' ),
        $form->find_input( $button, 'image' ),
        $form->find_input( $button, 'submit' ),
    );

    $toclick and $toclick->click();
}

=head2 $moz->click_button( %args )

Has the effect of clicking a button on a form by specifying its name,
value, or index.  Its arguments are a list of key/value pairs.  Only
one of name, number, or value must be specified.

=over 4

=item * name => name

Clicks the button named I<name>.

=item * number => n

Clicks the I<n>th button in the form.
B<XXX: this isn't currently working.> It will select the Nth button
if you assume they're gotten in the order: button, image, submit.
This will presumably get fixed sometime, so I'd advise not relying on it.

=item * value => value

Clicks the button with the value I<value>.

=back

B<NOTE>: Unlike WWW::Mechanize, Mozilla::Mechanize takes
all buttonish types of C<< <INPUT type=> >> into account: B<button>,
B<image>, and B<submit>.

=cut

sub click_button {
    my $self = shift;
    my %args = @_;

    for ( keys %args ) {
        if ( !/^(number|name|value)$/ ) {
            $self->warn( qq{Unknown click_button_form parameter "$_"} );
        }
    }

    my $form = $self->current_form;
    # XXX: this is unsorted
    my @buttons = (
        $form->find_input( $args{name}, 'button' ),
        $form->find_input( $args{name}, 'image' ),
        $form->find_input( $args{name}, 'submit' ),
    );

    @buttons or return;
    if ( $args{name} ) {
        $buttons[0]->click();
        return 1;
    } elsif ( $args{number} ) {
        @buttons <= $args{number} and return
        $buttons[ $args{number} - 1 ]->click();
        return 1;
    } elsif ( $args{value} ) {
        for my $button ( @buttons ) {
            if ( $button->value eq $args{value} ) {
                $button->click();
                return 1;
            }
        }
    }
}

=head2 $moz->submit( )

Submits the page, without specifying a button to click.  Actually,
no button is clicked at all.

This will call the C<Submit()> method of the currently selected form.

B<NOTE>: It looks like this method does not call the C<onSubmit>
handler specified in the C<< <FORM> >>-tag, that only seems to work if
you call the C<click_button()> method with submit button.

=cut

sub submit {
    my $self = shift;

    my $form = $self->current_form;

    $form->submit();
}

=head2 $moz->submit_form( %opt )

This method lets you select a form from the previously fetched page,
fill in its fields, and submit it. It combines the form_number/form_name,
set_fields and click methods into one higher level call. Its arguments
are a list of key/value pairs, all of which are optional.

=over 4

=item * form_number => n

Selects the I<n>th form (calls C<L<form_number()>>).  If this parm is not
specified, the currently-selected form is used.

=item * form_name => name

Selects the form named I<name> (calls C<L<form_name()>>)

=item * fields => fields

Sets the field values from the I<fields> hashref (calls C<L<set_fields()>>)

=item * button => button

Clicks on button I<button> (calls C<L<click()>>)

=item * button => { value => value }

When you specify a hash_ref for button it calls C<click_button()>

=back

If no form is selected, the first form found is used.

If I<button> is not passed, then the C<L<submit()>> method is used instead.

Returns true on success.

=cut

sub submit_form {
    my $self = shift;

    my %opt = @_;
    if ( my $form_number = $opt{form_number} ) {
        $self->form_number( $form_number ) ;
    }
    elsif ( my $form_name = $opt{form_name} ) {
        $self->form_name( $form_name ) ;
    } else {
        $self->form_number( 1 ) unless defined $self->{cur_form};
    }

    if ( my $fields = $opt{fields} ) {
        if ( ref $fields eq 'HASH' ) {
            $self->set_fields( %{$fields} ) ;
        } # TODO: What if it's not a hash?  We just ignore it silently?
    }

    if ( $opt{button} ) {
        if ( ref $opt{button} ) {
            $self->click_button( %{ $opt{button} } );
        } else {
            $self->click( $opt{button} );
        }
    } else {
        $self->submit();
    }

    return $self->success;
}

=head1 MISCELANEOUS METHODS

B<XXX: don't know how to add headers, so this is unsupported>

=head2 $moz->add_header( name => $value [, name => $value... ] )

Sets HTTP headers for the agent to add or remove from the HTTP request.

    $moz->add_header( Encoding => 'text/klingon' );

If a I<value> is C<undef>, then that header will be removed from any
future requests.  For example, to never send a Referer header:

    $moz->add_header( Referer => undef );

Returns the number of name/value pairs added.

=cut

sub add_header {
    my $self = shift;
    my $npairs = 0;

    while ( @_ ) {
        my $key = shift;
        my $value = shift;
        ++$npairs;

        $self->{headers}{$key} = $value;
    }

    return $npairs;
}

=head2 $moz->delete_header( name [, name ... ] )

B<XXX: don't know how to add headers, so this is unsupported>

Removes HTTP headers from the agent's list of special headers.

B<NOTE>: This might not work like it does with C<WWW::Mechanize>

=cut

sub delete_header {
    my $self = shift;

    while ( @_ ) {
        my $key = shift;
        delete $self->{headers}{$key};
    }
}

=head2 $moz->quiet( [$state] )

Allows you to suppress warnings to the screen.

    $a->quiet(0); # turns on warnings (the default)
    $a->quiet(1); # turns off warnings
    $a->quiet();  # returns the current quietness status

=cut

sub quiet {
    my $self = shift;

    $self->{quiet} = $_[0] if @_;

    return $self->{quiet};
}

=head2 $moz->find_frame( $frame_name )

Returns the URL to the source of the frame with C<name eq $frame_name>

=cut

sub find_frame {
    my ($self, $frame) = @_;

    # XXX: there must be an easier way than this...?
    my $docelem = $self->get_document_element;
    my $framelist = $docelem->GetElementsByTagName('frame');
    for (my $i = 0; $i < $framelist->GetLength; $i++) {
        my $frame_elem = $framelist->Item($i);
        if ($frame_elem->HasAttributes) {
            my $attrs = $frame_elem->GetAttributes;
            my %attrs = ();
            for (my $j = 0; $j < $attrs->GetLength; $j++) {
                my $attr = $attrs->Item($j);
                $attrs{lc($attr->GetNodeName)} = $attr->GetNodeValue;
            }

            if ($attrs{'name'} eq $frame) {
                return (URI->new_abs($attrs{'src'}, $self->uri))->as_string;
            }
        }
    }

    return;
}

=head2 $moz->load_frame( $frame_name )

C<< $self->get( $self->find_frame( $frame_name )) >>

=cut

sub load_frame {
    my( $self, $frame ) = @_;
    $self->get( $self->find_frame($frame) );
}

=head1 DOM CONVENIENCE METHODS

=cut

=head2 $moz->get_window;

Convenience method to get the Window
(L<Mozilla::DOM::Window|Mozilla::DOM::Window>).
(This is the `window' browser object in JavaScript.)

=cut

sub get_window {
    my $self = shift;
    my $embed = $self->agent->embedded;
    my $browser = $embed->get_nsIWebBrowser;
    return $browser->GetContentDOMWindow;
}

=head2 $moz->get_document;

Convenience method to get the Document
(L<Mozilla::DOM::Document|Mozilla::DOM::Document>).
(This is the `document' browser object in JavaScript.)

=cut

sub get_document {
    my $self = shift;
    my $window = $self->get_window;
    return $window->GetDocument;
}

=head2 $moz->get_document_element;

Convenience method to get the document element
(L<Mozilla::DOM::Element|Mozilla::DOM::Element>).
(Actually this is a L<Mozilla::DOM::HTMLHtmlElement|Mozilla::DOM::HTMLHtmlElement>,
i.e. <html>, if you want to QueryInterface to it).
This is useful for calling GetElementsByTagName.

=cut

sub get_document_element {
    my $self = shift;
    my $doc = $self->get_document;
    return $doc->GetDocumentElement;
}

=head1 LWP COMPATABILITY METHODS

=head2 $moz->credentials( $netloc, $realm, $uid, $pass )

B<XXX: don't know how to add headers, so this is unsupported>

Set the user name and password to be used for a realm.

C<$netloc> looks like C<hostname:port>.

=cut

sub credentials {
    my($self, $netloc, $realm, $uid, $pass) = @_;
    $self->{basic_authentication}{ $netloc }{ $realm } = [ $uid, $pass ];
    $self->{basic_authentication}{ $netloc }{__active_realm__} = $realm;
}

=head2 $moz->get_basic_credentials( $realm, $uri )

B<XXX: don't know how to add headers, so this is unsupported>

This is called by C<_extra_headers> to retrieve credentials for documents
protected by Basic Authentication.  The arguments passed in
are the C<$realm> and the C<$uri> requested.

The method should return a username and password.  It should return an
empty list to abort the authentication resolution attempt.

The base implementation simply checks a set of pre-stored member
variables, set up with the credentials() method.

=cut

sub get_basic_credentials {
    my($self, $realm, $uri ) = @_;

    my $host_port = $uri->can( 'host_port' )
        ? $uri->host_port : $uri->as_string;

    $realm ||= $self->{basic_authentication}{ $host_port }{__active_realm__};
    $realm or return ( );

    if ( exists $self->{basic_authentication}{ $host_port }{ $realm } ) {
        return @{ $self->{basic_authentication}{ $host_port }{ $realm } };
    }

    return ( );
}

=head2 $moz->set_realm( $netloc, $realm );

B<XXX: don't know how to add headers, so this is unsupported>

Sets the authentication realm to C<$realm> for C<$netloc>. An empty value
unsets the realm for C<$netloc>.

C<$netloc> looks like C<hostname:port>.

As I have not found a way to access response-headers, I cannot find
out the authentication realm (if any) and automagically set the right
headers. You will have to do some bookkeeping for now.

=cut

sub set_realm {
    my( $self, $netloc, $realm ) = @_;
    $netloc or return;
    defined $realm or $realm = "";
    $self->{basic_authentication}{ $netloc }{__active_realm__} = $realm;
}

=head1 INTERNAL-ONLY METHODS

=head2 DESTROY

Close the browser.

=cut

sub DESTROY {
    my $agent = shift->agent;
    $agent && $agent->quit;
}


=head2 $moz->_extract_forms()

Return a list of forms. All forms are mapped onto the
L<Mozilla::Mechanize::Form|Mozilla::Mechanize::Form> interface
that mimics L<HTML::Form|HTML::Form>.

=cut

sub _extract_forms {
    my $self = shift;
    my @forms;

    my $docelem = $self->get_document_element;
    my $formlist = $docelem->GetElementsByTagName('form');
    for (my $i = 0; $i < $formlist->GetLength; $i++) {
        push @forms, Mozilla::Mechanize::Form->new($formlist->Item($i), $self);
    }
    $self->{forms} = \@forms;

    return wantarray ? @{ $self->{forms} } : $self->{forms};
}

=head2 $self->_extract_links()

The links come from the following:

=over 2

=item "<A HREF=...>"

=item "<AREA HREF=...>"

=item "<FRAME SRC=...>"

Note: only works within a <frameset>

=item "<IFRAME SRC=...>"

Note: this must be like <iframe ...></iframe>

=back

=cut

{
    # Recursively get link elements. This is necessary in order
    # to preserve their order. Too bad Mozilla doesn't have
    # an `all' method like Internet Explorer.

    my @links;

    sub _extract_links {
        my ($self, $subelement) = @_;
        my $node;

        # The first time, it's called with no subelement
        if (defined $subelement) {
            $node = $subelement;
        } else {
            @links = ();
            $node = $self->get_document_element;
        }

        # If it's a link element, get it; otherwise, recurse if has children
        if ($node->GetNodeName =~ /^(iframe|frame|area|a)$/i) {
            my $tagname = lc $1;

            if ($tagname eq 'a') {
                # Element interface is more convenient for attributes
                my $element = $node->QueryInterface(Mozilla::DOM::Element->GetIID);
                # <a> are links only if they have an href
                push @links, Mozilla::Mechanize::Link->new($element, $self)
                  if $element->HasAttribute('href');
                $self->debug("added '$tagname' link");
            } else {
                push @links, Mozilla::Mechanize::Link->new($node, $self);
                $self->debug("added '$tagname' link");
            }
        } elsif ($node->HasChildNodes) {
            my @children = $node->GetChildNodes;
            # skips #text nodes
            foreach my $child (grep {$_->GetNodeName !~ /^#/} @children) {
                $self->_extract_links($child);
            }
        }

        # Continue only at the top-level
        return if defined $subelement;

        $self->{links} = \@links;
        return wantarray ? @{ $self->{links} } : $self->{links};
    }
}

=head2 $moz->_extract_images()

Return a list of images.
All images are mapped onto the L<Mozilla::Mechanize::Image|Mozilla::Mechanize::Image>
interface that mimics L<WWW::Mechanize::Image|WWW::Mechanize::Image>.

=cut

{
    # Recursively get image elements. This is necessary in order
    # to preserve their order. Too bad Mozilla doesn't have
    # an `all' method like Internet Explorer.

    my @images;

    sub _extract_images {
        my ($self, $subelement) = @_;
        my $node;

        # The first time, it's called with no subelement
        if (defined $subelement) {
            $node = $subelement;
        } else {
            @images = ();
            $node = $self->get_document_element;
        }

        # If it's an image element, get it; otherwise, recurse if has children
        if ($node->GetNodeName =~ /^(img|input)$/i) {
            my $tagname = lc $1;

            if ($tagname eq 'input') {
                # Element interface is more convenient for attributes
                my $element = $node->QueryInterface(Mozilla::DOM::Element->GetIID);
                # <input> are images only if they have a src
                # (XXX: or maybe should be if type="image"...)
                push @images, Mozilla::Mechanize::Image->new($element, $self)
                  if $element->HasAttribute('src');
                $self->debug("added '$tagname' image");
            } else {
                push @images, Mozilla::Mechanize::Image->new($node, $self);
                $self->debug("added '$tagname' image");
            }
        } elsif ($node->HasChildNodes) {
            my @children = $node->GetChildNodes;
            # skips #text nodes
            foreach my $child (grep {$_->GetNodeName !~ /^#/} @children) {
                $self->_extract_images($child);
            }
        }

        # Continue only at the top-level
        return if defined $subelement;

        $self->{images} = \@images;
        return wantarray ? @{ $self->{forms} } : $self->{forms};
    }
}

=head2 $self->_wait_while_busy()

This adds a "single-shot" idle callback that does Gtk2->main_quit,
then does Gtk2->main. The result is that whenever the UI becomes idle
it will exit the main loop. Thanks to muppet for the idea.
This is repeated until the net_stop event fires, indicating that
the new page has finished loading. (Note therefore that you can only
call this when you expect a new page to load.)

=cut

sub _wait_while_busy {
    my $self = shift;
    my $agent = $self->agent;

    do {
        Glib::Idle->add(sub {
            Gtk2->main_quit;
            FALSE;  # uninstall
        }, undef, G_PRIORITY_LOW);
        Gtk2->main;
    } until $agent->{netstopped};

    $self->{$_} = undef for qw(forms cur_form links images);
    return $self->success;
}

=head2 warn( @messages )

Centralized warning method, for diagnostics and non-fatal problems.
Defaults to calling C<CORE::warn>, but may be overridden by setting
C<onwarn> in the construcotr.

=cut

sub warn {
    my $self = shift;

    return unless my $handler = $self->{onwarn};

    return if $self->quiet;

    $handler->(@_);
}

=head2 die( @messages )

Centralized error method.  Defaults to calling C<CORE::die>, but
may be overridden by setting C<onerror> in the constructor.

=cut

sub die {
    my $self = shift;

    return unless my $handler = $self->{onerror};

    $handler->(@_);
}

# Not a method
sub __warn {

    eval "require Carp";
    if ( $@ ) {
        CORE::warn @_;
    } else {
        &Carp::carp;
    }
}

# Not a method
sub __die {
    require Carp;
    &Carp::croak; # pass thru
}

sub debug {
    my ($self, $msg) = @_;
    my (undef, $file, $line) = caller();
    print STDERR "$msg at $file line $line\n" if $self->{debug};
}


=head2 $self->_extra_headers( )

(XXX: Not implemented.)
For the moment we only support B<basic authentication>.

=cut

sub _extra_headers {
    my( $self, $uri ) = @_;

    my $header = "";

    for my $header ( keys %{ $self->{headers} } ) {
        next unless defined $self->{headers}{ $header };
        ( my $hfield = $header ) =~ s/(\w+)/ucfirst lc $1/eg;
        $header .= "$hfield: $self->{headers}{ $header }\015\012";
    }

    my $host_port = $uri->can( 'host_port' )
        ? $uri->host_port : $uri->as_string;
    return $header unless exists $self->{basic_authentication}{ $host_port };

    my $realm = $self->{basic_authentication}{ $host_port }{__active_realm__};
    my( $user, $pass ) = $self->get_basic_credentials( $realm, $uri );

    $header .= defined $user ? __authorization_basic( $user, $pass ) : "";

    return $header;
}

=head1 INTERNAL ONLY NON-METHODS

=head2 __prop_value( $key[, $value] )

Check to see if we support the property C<$key> and return a validated
value or the default value from C<%moz_properties>.

=cut

sub __prop_value($;$) {
    my ($key, $value) = @_;
    $key = lc $key;

    exists $moz_property{$key} or return undef;
    @_ > 1 or return $moz_property{$key}{value};

    CASE: {
        local $_ = $moz_property{ $key }{type};

        /^b$/ and do {
            defined $value or return $moz_property{$key}{value};
            return $value ? 1 : 0;
        };
        /^n$/ and do {
            defined $value or return $moz_property{$key}{value};
            return $value =~ /((?:\+|-)?[0-9]+)/ ? $1 : 0;
        };
    }
}

=head2 __authorization_basic( $user, $pass )

(XXX: Not implemented.)
Return a HTTP "Authorization: Basic xxx" header.

=cut

sub __authorization_basic {
    my( $user, $pass ) = @_;
    defined $user && defined $pass or return;

    require MIME::Base64;
    return "Authorization: Basic " .
           MIME::Base64::encode_base64( "$user:$pass" ) .
           "\015\012";
}


1;

=head1 BUGS

Send bugs directly to me or use
L<http:E<sol>E<sol>rt.cpan.orgE<sol>NoAuthE<sol>Bugs.html?Dist=Mozilla-Mechanize>.

=head1 SEE ALSO

L<Mozilla::DOM|Mozilla::DOM>,
L<Gtk2::MozEmbed|Gtk2::MozEmbed>,
L<Win32::IE::Mechanize|Win32::IE::Mechanize>,
L<WWW::Mechanize|WWW::Mechanize>

=head1 CREDITS

See F<Credits>. In particular, I acknowledge having copied a lot of
the code from L<Win32::IE::Mechanize|Win32::IE::Mechanize>, by Abe Timmerman.

=head1 COPYRIGHT AND LICENSE

Copyright 2005,2009 Scott Lanning <slanning@cpan.org>. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
