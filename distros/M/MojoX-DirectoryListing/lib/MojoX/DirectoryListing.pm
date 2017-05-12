package MojoX::DirectoryListing;

use 5.010;
use MojoX::DirectoryListing::Icons;
use strict;
use warnings FATAL => 'all';
use base 'Exporter';
use Cwd;

our @EXPORT = ('serve_directory_listing');
our $VERSION = '0.09';

use constant TEXT_403 => 'Forbidden';
use constant TEXT_404 => 'File not found';

# FIXME: see  @{app->static->paths} for list of public directories
our $public_dir = "public";
our %icon_server_set = ();

sub set_public_app_dir {
    $public_dir = shift;
    $public_dir =~ s{/+$}{};
}

my %realpaths;

sub serve_directory_listing {
    %realpaths = ();
    my $route = shift;
    my $local;
    if (@_ % 2 == 1) {
	$local = shift;
    }
    _serve_directory_listing($route, $local, 'caller', caller, @_);
}

sub _serve_directory_listing {
    my $route = shift;
    my $local = shift;
    my %options = @_;
    my $caller = $options{caller};

    if ($route !~ m{^/}) {
	$caller->app->log->error(
	    "MojoX::DirectoryListing: route in serve_directory_listing() "
	    . "must have a leading / !" );
	return;
    }

    my $listing_sub = _mk_dir_listing($route,$local,%options);

    $caller->app->routes->get( $route, $listing_sub );
    $icon_server_set{$caller}++ or
	# route was  /directory-listing-icons/#icon
	# but that was not compatible with some older libraries.
	# :icon   is ok because we expect icon param to never
	# contain '/' or '.'
	$caller->app->routes->get( "/directory-listing-icons/:icon",
				   \&_serve_icon );

    if ($options{recursive}) {
	my $dh;
	my $actual = $local // $public_dir . $route;
	opendir $dh, $actual;
	my @subdirs = grep {
	    $_ ne '.' && $_ ne '..' && -d "$actual/$_"
	} readdir($dh);
	closedir($dh);
	$options{caller} //= $caller;
	my $route1 = $route eq '/' ? '' : $route;
	foreach my $subdir (@subdirs) {
	    if ($local) {
		my $real = Cwd::realpath("$local/$subdir");
		next if $realpaths{$real}++;
		_serve_directory_listing( "$route1/$subdir",
					 "$local/$subdir", %options );
	    } else {
		_serve_directory_listing( "$route1/$subdir", undef, %options );
	    }
	}
    }

    if ($local) {
	# route was  $route/#file  in 0.06, but that caused test
	# failures on some systems, mainly with older Perl (but
	# not necessarily older Mojolicious?)
	$caller->app->routes->get( "$route/#file", 
				   _mk_fileserver($local) );
	$caller->app->routes->get( "$route/*file", 
				   _mk_fileserver($local) );
    }
}

sub _mk_fileserver {
    my ($local) = @_;
    return sub {
	my $self = shift;
	my $file = $self->param('file');

	if (! -r "$local/$file") {
	    $self->render( text => TEXT_403, status => 403 );
	} elsif (-d "$local/$file") {
	    $self->render( status => 403, text => TEXT_403 );
	} elsif (open my $fh, '<', "$local/$file") {
	    my $output = join '', <$fh>;
	    close $fh;
	    my ($type) = $file =~ /.*\.(\S+)$/;
	    if ($type) {
		my $format = $self->app->types->type($type);
		if ($format && $format =~ /te?xt/i) {
		    $self->render( format => $type, text => $output );
		} elsif ($format) {
		    $self->render( format => $type, data => $output );
		} else {
		    $self->render( data => $output );
		}
	    } else {
		$self->render( data => $output );
	    }
	} else {
	    $self->render( text => TEXT_404, status => 404 );
	}
    };
}

sub _mk_dir_listing {
    my ($route, $local, %options) = @_;
    die "Expect leading slash in route $route"
	unless $route =~ m#^/#;
    $local //= $public_dir . $route;
    return sub {
	my $self = shift;
	$self->stash( "actual-dir", $local );
	$self->stash( "virtual-dir", $route );
	$self->stash( $_ => $options{$_} ) for keys %options;
	_render_directory( $self );
    };
}

sub _directory_listing_link {
    my ($href, $text) = @_;
    return sprintf '<a class="%s" href="%s">%s</a>',
	"directory-listing-link", $href, $text;
}

sub _render_directory {
    my $self = shift;
    my $output;
    my $virtual_dir = $self->stash("virtual-dir");
    my $actual_dir = $self->stash("actual-dir");

    # sort column: [N]ame, Last [M]odified, [S]ize, [D]escription
    my $sort_column = $self->param('C') || $self->stash('sort-column') || 'N';

    # support Apache style  ?C=x;O=y  query string or ?C=x&O=y
    if ($sort_column =~ /^(\w);O=(\w)/) {
	$sort_column = $1;
	$self->param("O", $2);
    }
    # sort order: [A]scending, [D]escending
    my $sort_order = $self->param('O') || $self->stash('sort-order') || 'A';

    my $show_file_time = $self->stash("show-file-time") // 1;
    my $show_file_size = $self->stash("show-file-size") // 1;
    my $show_file_type = $self->stash("show-file-type") // 1;
    my $show_forbidden = $self->stash("show-forbidden") // 0;
    my $show_icon = $self->stash("show-icon") // 0;    # TODO
    my $stylesheet = $self->stash("stylesheet");

    $virtual_dir =~ s{/$}{} unless $virtual_dir eq '/';
    my $dh;
    if (!opendir $dh, $actual_dir) {
	$self->app->log->error(
	    "MojoX::DirectoryListing: opendir failed on $actual_dir" );
	if (-d $actual_dir) {
	    $self->render( text => TEXT_403, status => 403 );
	} else {
	    $self->render( text => TEXT_404, status => 404 );
	}
	return;
    }
    my @items = map {
	my @stat = stat("$actual_dir/$_");
	my $modtime = $stat[9];
	my $size = $stat[7];
	my $is_dir = -d "$actual_dir/$_";
	$size = -1 if $is_dir;
	my $forbidden = ! -r "$actual_dir/$_";

	# another way this item can be forbidden is if
	#   * it is a directory
	#   * that directory is not served
	
	+{
	    name => $_,
	    is_dir => $is_dir,
	    modtime => $modtime,
	    size => $size,
	    forbidden => $forbidden,
	    type => $is_dir ? "Directory" : _filetype("$_")
	};
    } readdir($dh);
    closedir $dh;

    if ($sort_column eq 'S') {
	@items = sort { $a->{size} <=> $b->{size} 
			|| $a->{name} cmp $b->{name} } @items;
    } elsif ($sort_column eq 'M') {
	@items = sort { $a->{modtime} <=> $b->{modtime} 
			|| $a->{name} cmp $b->{name} } @items;
    } elsif ($sort_column eq 'T') {
	@items = sort { $a->{type} cmp $b->{type} 
			|| $a->{name} cmp $b->{name} } @items;
    } else {
	@items = sort { $a->{name} cmp $b->{name} } @items;
    }
    if ($sort_order eq 'D') {
	@items = reverse @items;
    }

    $output = "<!DOCTYPE html><html><head>";
    $output .= _add_style($self, $stylesheet);
    $output .= qq[
</head>
<body class="directory-listing">
<base href="/" />
<!-- directory listing by MojoX::DirectoryListing
     sort column: $sort_column
     sort order:  $sort_order
  -->
];

    my $header = $self->stash("header") //
	qq[<h1 class="directory-listing">Index of __DIR__</h1>];
    $header =~ s/__DIR__/$virtual_dir/g;
    $output .= $header . "\n";

    $output .= "<hr class=\"directory-listing\"/>\n";

    $output .= qq[
<table border=0>
<thead class="directory-listing-header">
];

    for ( [$show_icon, "Icon", ""],
	  [1,'Name','N'], [$show_file_time,'Last Modified','M'], 
	  [$show_file_size,'Size','S'], [$show_file_type,'Type','T'] ) {
	my ($show, $text, $col_code) = @$_;
	next if !$show;
	my $sortind = "";
	my $order_code = 'A';
	if ($sort_column eq $col_code) {
	    if ($sort_order eq 'D') {
		$sortind = "v";
	    } else {
		$sortind = "^";
		$order_code = 'D';
	    }
	}
	if ($text eq 'Icon') {
	    $output .= qq[  <th>&nbsp;</th>\n];
	} else {

	    my $link = _directory_listing_link(
		"$virtual_dir?C=$col_code;O=$order_code", $text);
	    $output .= qq[  <th>
      $link $sortind
  </th>
];
	}
    }

    $output .= "</thead>\n<tbody>\n";

    my $table_element_template = qq[    <td class="directory-listing-%s">&nbsp;%s&nbsp;</td>\n];

    foreach my $item (@items) {
        next if $item->{name} eq '.';
        next if $item->{forbidden} && !$show_forbidden;
        $output .= "  <tr class=\"directory-listing-row\">\n";

	if ($show_icon) {
	    my $icon = choose_icon($item);
	    $output .= sprintf $table_element_template,
	        "icon", "<img src=\"/directory-listing-icons/$icon\">";
	}

	if ($item->{forbidden}) {
	    $output .= sprintf $table_element_template,
		"forbidden-name", $item->{name};
	} else {
	    my $name = $item->{name};
	    $name = 'Parent Directory' if $name eq '..';
	    my $href = "$virtual_dir/$item->{name}";
	    $href =~ s{^//}{/};
	    my $link = _directory_listing_link($href, $name);
	    $output .= sprintf $table_element_template, "name", $link;
	}


	if ($show_file_time) {
	    $output .= sprintf $table_element_template,
		"time", _render_modtime($item->{modtime});
	}
	if ($show_file_size) {
	    $output .= sprintf $table_element_template,
		"size", _render_size($item);
	}
	if ($show_file_type) {
	    $output .= sprintf $table_element_template,
		"type", $item->{type};
	}
	$output .= "  </tr>\n";
    }
    $output .= "</tbody>\n</table>\n";

    if ($self->stash("footer")) {
	$output .= "<hr class=\"directory-listing\">\n";
	my $footer = $self->stash("footer");
	$footer =~ s/__DIR__/$virtual_dir/g;
	$output .= $footer . "\n";
    }

    $output .= "</body>\n</html>\n";
    $self->render( text => $output );
}

sub _add_style {
    # output either a  <style>...</style>  tag or a
    # <link rel="stylesheet" href="..." /> tag

    my ($self, $stylesheet) = @_;
    if (defined($stylesheet) && !ref($stylesheet)) {
	return qq[<link rel="stylesheet" href="$stylesheet">\n];
    }

    my $style = "";
    if (!defined $stylesheet) {
	$style = _default_style();
    } elsif (ref $stylesheet eq 'ARRAY') {
	$style = join "\n", @$stylesheet;
    } elsif (ref $stylesheet eq 'HASH') {
	while (my ($selector,$attrib) = each %$stylesheet) {
	    $style .= "$selector $attrib\n";
	}
    } elsif (ref $stylesheet eq 'SCALAR') {
	$style = $$stylesheet;
    } else {
	$self->app->log->warn( "MojoX::DirectoryListing: Invalid ref type "
			       . (ref $stylesheet) . " for stylesheet" );
	$style = _default_style();
    }
    return "<style>\n$style\n</style>\n";
}

sub _default_style {
    # inspired by/borrowed from  app-dirserve
    return qq~<style>
body.directory-listing {
  font-family: "Lucida Grande", tahoma, sans-serif;
  font-size: 100%; margin: 0; width: 100%;
}
h1.directory-listing {
  background: #999;
  background: -webkit-gradient(linear, left top, left bottom, from(#A2C6E5), to(#2B6699));
  background: -moz-linear-gradient(top,  #A2C6E5,  #2B6699);
  filter: progid:DXImageTransform.Microsoft.gradient(startColorstr='#A2C6E5', endColorstr='#2B6699');
  padding: 10px 0 10px 10px; margin: 0; color: white;
}
a.directory-listing-link   { color: #5C8DB8; }
hr.directory-listing       { border: solid silver 1px; width: 95%; }
.directory-listing-row, .directory-listing-header { font-family: Courier }
.directory-listing-name    { font-weight: bold; color: #346D9E; }
</style>~;
}

sub _render_size {
    my $item = shift;
    if ($item->{is_dir}) {
	return "--";
    }
    my $s = $item->{size};
    if ($s < 100000) {
	return $s;
    }
    if ($s < 1024 * 999.5) {
	return sprintf "%.3gK", $s/1024;
    }
    if ($s < 1024 * 1024 * 999.5) {
	return sprintf "%.3gM", $s/1024/1024;
    }
    if ($s < 1024 * 1024 * 1024 * 999.5) {
	return sprintf "%.3gG", $s/1024/1024/1024;
    }
    return sprintf "%.3gT", $s/1024/1024/1024/1024;
}

sub _render_modtime {
    my $t = shift;
    my @gt = localtime($t);
    sprintf ( "%04d-%s-%02d %02d:%02d:%02d",
	      $gt[5]+1900,
	      [qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)]->[$gt[4]],
	      @gt[3,2,1,0] );
}

sub _filetype {
    my $file = shift;
    if ($file =~ s/.*\.//) {
	return $file;
    }
    return "Unknown";
}

sub _serve_icon {
    my $self = shift;
    my $icon = $self->param('icon');
    my $bytes = MojoX::DirectoryListing::Icons::get_icon( $icon );
    $self->render( format => 'gif',
		   data => $bytes );	
}

1;

__END__

=head1 NAME

MojoX::DirectoryListing - show Apache-style directory listings in your Mojolicious app

=head1 VERSION

0.09

=head1 SYNOPSIS

    use Mojolicious;  # or Mojolicious::Lite;
    use MojoX::DirectoryListing;

    # serve a directory listing under your app's  public/  folder
    serve_directory_listing( '/data' );

    # serve a directory listing in a different location
    serve_directory_listing( '/more-data', '/path/to/other/directory' );

    # serve all subdirectories, too
    serve_directory_listing( '/data', recursive => 1 );

    # change the default display options
    serve_directory_listings( '/data', 'show-file-type' => 0, 'show-forbidden' => 1 );

=head1 DESCRIPTION

I ported a web application from CGI to L<Mojolicious>. I was mostly pleased
with the results, but one of the features I lost in the port was the ability
to serve a directory listing. This module is an attempt to make that feature
available in Mojolicious, and maybe even make it better.

Mojolicious serves static files under your app's C<public/> directory.
To serve a whole directory under your C<public/> directory (say, 
C<public/data-files>), you would call

    serve_directory_listings( '/data-files' );

Now a request to your app for C</dara-files> will display a listing
of all the files under C<public/data-files> .

To serve a directory listing for a directory that is B<not> under
your app's public directory, provide a second argument to
C<serve_directory_listings>. For example

    serve_directory_listings( '/research', 'public/files/research/public' );
    serve_directory_listings( '/log', '/var/log/system' );

=head1 EXPORT

This module exports the L<"serve_directory_listing"> subroutine
to the calling package.

=head1 SUBROUTINES/METHODS

=head2 serve_directory_listing

=head2 serve_directory_listing( $route, %options )

=head2 serve_directory_listing( $route, $path, %options )

Configures the Mojolicious app to serve directory listings
for the specified path rom the specified route.

If C<$path> is omitted, then the appropriate directory
in your apps C<public> directory will be listed. For example,
the route C</data/foo> will serve a listing for your app's
C<public/data/foo> directory.

=head3 recognized options

The C<serve_directory_listing> function recognizes several options
that control the appearance and the behavior of the directory listing.

=over 4

=item C<sort-column> => C< N | M | S | T >

Controls whether the files in a directory will be ordered
by C<< <N> >>ame, file C<< <M> >>odification time,
file C<< <S> >>ize, or file C<< <T> >>ype.
The default is to order listings by name. 

If a request includes the parameter C<C>, it will override
this setting for that request. This makes the behavior of
this feature similar to the feature in Apache (see
L<http://cpansearch.perl.org/src/MOB/MojoX-DirectoryListing-0.05/>
for example [actually, this is an emulation of Apache-style
directory listing in L<Plack>)).

=item C<display-order> => C< A | D>

Controls whether the files will be listed
(using the sort criteria from C<sort-column>)
in C<< <A> >>scending or C<< <D> >>escending order.
The default is ascending order.

A request that includes the parameter C<O> will override
this setting for that request.    

=item C<show-file-time> => boolean

If true, the directory listing includes the modification time
of each file listed. The default is true.

=item C<show-file-size> => boolean

If true, the directory listing includes the size of each file
listed. The default is true.

=item C<show-file-type> => boolean

If true, the directory listing includes the MIME type of each
file listed. The default is true.

=item C<show-forbidden> => boolean

If true, the directory listing includes files that are not
readable by the user running the web server. When such a 
file is listed, it will not include a link to the file.
The default is false.

=item C<show-icon> => boolean

If true, an icon appears to the left of every directory
listing indicating the type of file.
The default is false.

=item C<recursive> => boolean

If true, invoke C<serve_directory_listing> on all
I<subdirectories> of the directory being served.
The default is false.

For example, to serve all directories as well as all files
under your app's C<public/> folder, it is sufficient to run

    serve_directory_listing( '/',  recursive => 1 );

=item C<stylesheet> => url

=item C<stylesheet> => \$style-spec

A URL to specify a cascading stylesheet to be applied to the
directory listing page, or reference to a scalar that holds
style information (suitable for inserting into a pair of
C<< <style></style> >> tags in the output of this subroutine. 

If you do wish to override the styles for the directory listing
output, the selectors you want to define are:

=over 4

=item C<.directory-listing>

A class that is applied to C<< <body> >>, C<< <h1> >>, and C<< <hr> >>
elements on the directory listing output.

=item C<.directory-listing-link>

A class that is applied to the C<< <a> >> tag associated with each
filename in the directory listing.

=item C<.directory-listing-header>

A class that applies to the column headings (Name, Last Modified,
Size, and Type columns) in the directory listing.

=item C<.directory-listing-row>

A class that applies to a row in the directory listing. which may
include a file name, the file's modification time, the file's
size, and the file's type.

=item C<.directory-listing-name>

A class that applies to a filename in the directory listing, but
not "forbidden" files -- see C<.directory-listing-forbidden-name>.

=item C<.directory-listing-forbidden-name>

A class that applies to the filename for a "forbidden" file; that is,
a file listing that the user is allowed to see for a file that
he/she is not allowed to see. See L<"show-forbidden">.

=item C<.directory-listing-time>

A class that applies to the display of a file's last modification time
in the directory listing.

=item C<.directory-listing-size>

A class that applies to the display of a file's size in the
directory listing.

=item C<.directory-listing-type>

A class that applies to the display of a file's file type
in the directory listing.

=back

If not specified, the default style is the one used by the
L<app-dirserve|https::/github.com/tempire/app-dirserve>
application (see L<"ACKNOWLEDGEMENTS">).

=item C<header> => string

Specify HTML code to be included at the top of the
directory listing page. If the string contains the token
C<__DIR__>, it will be replaced with the path of the
directory being requested.

If a header is not specified, the default header is

    <h1 class="directory-listing">Index of __DIR__</h1>

=item C<footer> => string

Specify HTML code to be included at the bottom of the
directory listing page. If the string contains the token
C<__DIR__>, it will b e replaced with the path of the
directory being requested.

The default footer is the empty string.

=back

=head2 set_public_app_dir( $path )

Tells C<MojoX::DirectoryListing> which directory your
app uses to serve static data. The default is C<./public>.
The public app dir is used to map the route to an actual
path when you don't supply a C<$path> argument to
L<"serve_directory_listing">.

=head1 AUTHOR

Marty O'Brien, C<< <mob at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to 
C<bug-mojox-lite-directorylisting at rt.cpan.org>, or through
the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MojoX-DirectoryListing>.  
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MojoX::DirectoryListing


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MojoX-DirectoryListing>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MojoX-DirectoryListing>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MojoX-DirectoryListing>

=item * Search CPAN

L<http://search.cpan.org/dist/MojoX-DirectoryListing/>

=back


=head1 ACKNOWLEDGEMENTS

github user L<Glenn Hinkle|https://github.com/tempire>
created the L<app-dirserve|https://github.com/tempire/app-dirserve>
microapplication to serve a directory over a webservice. 
I have borrowed a lot of his ideas and a little of 
his code in this module.

=head1 SEE ALSO

L<Plack::App::Directory>

=head1 LICENSE AND COPYRIGHT

Copyright 2013-2017 Marty O'Brien.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
