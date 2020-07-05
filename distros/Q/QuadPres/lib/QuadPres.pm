package QuadPres;
$QuadPres::VERSION = '0.28.3';
use 5.016;
use strict;
use warnings;

use utf8;

use parent 'QuadPres::Base';

use IO::All qw/ io /;
use Data::Dumper  ();
use QuadPres::Url ();
use Carp          ();
use HTML::Widgets::NavMenu::EscapeHtml qw(escape_html);

my $navigation_style_class = "nav";
my $contents_style_class   = "contents";

__PACKAGE__->mk_acc_ref(
    [
        qw(
            contents
            coords
            doc_id
            doc_id_slash_terminated
            mode
            navigation_bar
            stage_idx
            )
    ]
);

sub _init
{
    my $self = shift;

    $self->contents(shift);

    my %args = (@_);

    my $doc_id = $args{'doc_id'};

    $self->mode( $args{'mode'} || "server" );

    $self->stage_idx( $args{'stage_idx'} || 0 );

    $self->_populate_doc_id($doc_id);

    $self->doc_id_slash_terminated( ( $doc_id =~ /\/$/ ) ? 1 : 0 );

    return 0;
}

sub _populate_doc_id
{
    my $self = shift;

    my $doc_id = shift;

    my $doc_id_parsed = [ split( /\//, $doc_id ) ];

    $self->_populate_coords($doc_id_parsed);

    my @coords = @{ $self->coords() };
    my $b      = $self->contents;

    foreach my $c (@coords)
    {
        $b = $b->{'subs'}->[$c];
    }

    $self->doc_id(
        QuadPres::Url->new(
            $doc_id_parsed, exists( $b->{'subs'} ),
            $self->mode,
        )
    );

    return;
}

sub _populate_coords
{
    my $self = shift;

    my $doc_id_parsed = shift;
    if ( !defined( $self->coords ) )
    {
        my %locs;
        my $traverse;

        $traverse = sub {
            my $coords = shift;
            my $branch = shift;
            my $path   = shift;

            push @$path, $branch->{'url'};

            $locs{ join( "/", @$path[ 1 .. $#$path ] ) } = [ @{$coords} ];
            if ( exists( $branch->{'subs'} ) )
            {
                my $i;

                for ( $i = 0 ; $i < scalar( @{ $branch->{'subs'} } ) ; $i++ )
                {
                    $traverse->(
                        [ @$coords, $i ],
                        $branch->{'subs'}->[$i], [@$path],
                    );
                }
            }
        };

        $traverse->( [], $self->contents, [], );

        if (0)
        {
            print "Content-Type: text/plain\n\n";
            my $d = Data::Dumper->new( [ \%locs ], ["locs"] );
            print $d->Dump();
        }

        my $document_id = join( "/", @{$doc_id_parsed} );
        if ( !exists( $locs{$document_id} ) )
        {
            die "Pres::get_coords(): Could not find the document \""
                . $document_id . "\".";
        }
        $self->coords( [ @{ $locs{$document_id} } ] );
    }

    return;
}

sub get_document_base_text
{
    my $self = shift;

    my $document_id = join( "/", @{ $self->doc_id->get_url() } );

    my $filename = "./src/" . $document_id;

    my $index_fn = $filename . "/index.html";

    if ( -f $filename )
    {
        return scalar( io->file($filename)->slurp );
    }
    elsif ( ( -d $filename ) && ( -f $index_fn ) )
    {
        return scalar( io->file($index_fn)->slurp );
    }
    else
    {
        die "Could not find the file \"" . $document_id . "\"";
    }
}

sub get_url_by_coords
{
    my $self = shift;

    my @coords = @{ shift(@_) };

    my @url;

    my $b = $self->contents;

    foreach my $c (@coords)
    {
        $b = $b->{'subs'}->[$c];
        my $comp = $b->{url};

        if ( !defined($comp) )
        {
            Carp::confess("undef component.");
        }
        push @url, $comp;
    }

    return QuadPres::Url->new( \@url, exists( $b->{'subs'} ), $self->mode );
}

sub get_contents_url
{
    my $self = shift;

    return QuadPres::Url->new( [], 1, $self->mode );
}

sub get_last_url
{
    my $self = shift;

    my $b = $self->contents;

    my @path;

    my $b_subs;

    my $fetch = sub {
        $b_subs = $b->{subs};
    };

    $fetch->();

    while ( defined($b_subs) && @$b_subs )
    {
        my $last_branch = $b_subs->[-1];
        my $url         = $last_branch->{url};
        if ( !defined($url) )
        {
            Carp::confess("undef URL.");
        }
        push @path, $url;
        $b = $last_branch;
        $fetch->();
    }

    return QuadPres::Url->new( [@path], ( exists( $b->{subs} ) ? 1 : 0 ),
        $self->mode );
}

sub get_next_url
{
    my $self = shift;

    my @coords = @{ $self->coords };

    my @branches = ( $self->contents );

    my @dest_coords;

    my $i;

    for ( $i = 0 ; $i < scalar(@coords) ; $i++ )
    {
        $branches[ $i + 1 ] = $branches[$i]->{'subs'}->[ $coords[$i] ];
    }

    my $subs = $branches[$i]->{'subs'};
    if ( defined $subs && @$subs )
    {
        @dest_coords = ( @coords, 0 );
    }
    else
    {
        for ( $i-- ; $i >= 0 ; $i-- )
        {
            if ( @{ $branches[$i]->{'subs'} } > ( $coords[$i] + 1 ) )
            {
                @dest_coords = ( @coords[ 0 .. ( $i - 1 ) ], $coords[$i] + 1 );
                last;
            }
        }
        if ( $i == -1 )
        {
            return;
        }
    }

    return $self->get_url_by_coords( \@dest_coords );
}

sub get_most_advanced_leaf
{
    my $self = shift;

    # We accept as a parameter the vector of coordinates
    my $coords_ref = shift;

    my @coords = @{$coords_ref};

    # Get a reference to the contents HDS (= hierarchial data structure)
    my $branch = $self->contents;

    # Get to the current branch by advancing to the offset
    foreach my $c (@coords)
    {
        # Advance to the next level which is at index $c
        $branch = $branch->{'subs'}->[$c];
    }

    # As long as there is something deeper
    while ( exists( $branch->{'subs'} ) )
    {
        # Get the index of the most advanced sub-branch
        my $index = scalar( @{ $branch->{'subs'} } ) - 1;

        # We are going to return it, so store it
        push @coords, $index;

        # Recurse into the sub-branch
        $branch = $branch->{'subs'}->[$index];
    }

    return \@coords;
}

sub get_prev_url
{
    my $self = shift;

    my @coords = @{ $self->coords };

    if ( scalar(@coords) == 0 )
    {
        return;
    }
    elsif ( $coords[$#coords] > 0 )
    {
        # Get the previous leaf
        my @previous_leaf =
            ( @coords[ 0 .. ( $#coords - 1 ) ], $coords[$#coords] - 1 );

        # Continue in this leaf to the end.
        my $new_coords = $self->get_most_advanced_leaf( \@previous_leaf );

        return $self->get_url_by_coords($new_coords);
    }
    elsif ( scalar(@coords) > 0 )
    {
        return $self->get_url_by_coords( [ @coords[ 0 .. ( $#coords - 1 ) ] ] );
    }
    else
    {
        return;
    }
}

sub get_up_url
{
    my $self = shift;

    my @coords = @{ $self->coords };

    if ( scalar(@coords) == 0 )
    {
        return;
    }
    else
    {
        return $self->get_url_by_coords( [ @coords[ 0 .. ( $#coords - 1 ) ] ] );
    }
}

sub get_relative_url__depcracated
{
    my @this_url         = @{ shift(@_) };
    my @other_url        = @{ shift(@_) };
    my $slash_terminated = shift;

    while (scalar(@this_url)
        && scalar(@other_url)
        && ( $this_url[0] eq $other_url[0] ) )
    {
        shift(@this_url);
        shift(@other_url);
    }

    my $ret = "";

    if ($slash_terminated)
    {
        $ret .= join( "/", ( map { ".." } @this_url ), @other_url );
    }
    else
    {
        $ret .= (
            join( "/",
                ( map { ".." } @this_url[ 1 .. $#this_url ] ), @other_url )
        );
        $ret = "./$ret" if ( not length $ret );
    }

    return $ret;
}

sub get_control_url
{
    my $self = shift;

    my $other_url = shift;

    if ( !defined($other_url) )
    {
        return;
    }

    my $this_url = $self->doc_id;

    return $this_url->get_relative_url( $other_url,
        $self->doc_id_slash_terminated );
}

sub get_control_text
{
    my $self = shift;

    my $spec = shift;

    my $text = "";

    my $this_url = $self->doc_id;

    my $other_url = $spec->{'url'}->($self);

    if ( defined($other_url) )
    {

        $text .=
              "<a href=\""
            . $self->get_control_url($other_url)
            . "\" class=\""
            . $navigation_style_class . "\">";

        $text .= $spec->{'caption'};

        $text .= "</a>";
    }
    else
    {
        $text .=
              "<b class=\""
            . $navigation_style_class . "\">"
            . $spec->{'caption'} . "</b>";
    }

    return $text;
}

sub get_navigation_bar
{
    my $self = shift;

    if ( !defined( $self->navigation_bar ) )
    {
        # Render the Navigation Bar
        my $text = "";
        my @controls;

        $text .= "<table>\n";
        $text .= "<tr>\n";
        $text .= "<td>\n";

        push @controls,
            (
            $self->get_control_text(
                {
                    'url'     => \&get_contents_url,
                    'caption' => "Contents",
                },
            )
            );

        push @controls,
            (
            $self->get_control_text(
                {
                    'url'     => \&get_up_url,
                    'caption' => "Up",
                },
            )
            );

        push @controls,
            (
            $self->get_control_text(
                {
                    'url'     => \&get_prev_url,
                    'caption' => "Previous",
                },
            )
            );

        push @controls,
            (
            $self->get_control_text(
                {
                    'url'     => \&get_next_url,
                    'caption' => "Next",
                },
            )
            );

        $text .= join( "</td>\n<td>\n", @controls );

        $text .= "</td>\n";
        $text .= "</tr>\n";
        $text .= "</table>\n";
        $text .= "\n";

        #$text .= "<br><br>";

        $self->navigation_bar($text);
    }

    return $self->navigation_bar;
}

sub get_subject_by_coords
{
    my $self       = shift;
    my $coords_ref = shift;

    my $branch = $self->contents;

    my @coords = @$coords_ref;

    for ( my $i = 0 ; $i < scalar(@coords) ; $i++ )
    {
        $branch = $branch->{'subs'}->[ $coords[$i] ];
    }

    return $branch->{'title'};
}

sub get_subject
{
    my $self = shift;

    return $self->get_subject_by_coords( $self->coords );
}

sub get_title
{
    my $self = shift;

    my @coords = @{ $self->coords };

    my @coords_plus_1 = ( map { $_ + 1; } @coords );
    my $indexes_str   = join( ".", @coords_plus_1 );
    if ( scalar(@coords) )
    {
        $indexes_str .= ". ";
    }

    return $indexes_str . $self->get_subject();
}

sub get_style_css_url
{
    my $self = shift;

    return $self->doc_id->get_relative_url(
        QuadPres::Url->new( ["style.css"], 0, $self->mode ),
        $self->doc_id_slash_terminated );
}

sub get_header
{
    my $self = shift;

    my $text = "";
    my $branch;

    my @coords = @{ $self->coords };

    $text .= "<html>\n";
    $text .= "<head>\n";
    $text .= "<title>" . $self->get_subject() . "</title>\n";
    $text .=
          "<link rel=\"StyleSheet\" href=\""
        . $self->get_style_css_url
        . "\" type=\"text/css\">\n";

    $text .= "</head>\n";
    $text .= "<body>\n";
    $text .= $self->get_navigation_bar();

    $text .= "<h1 class=\"fcs\">" . $self->get_title() . "</h1>";

    return $text;
}

sub get_footer
{
    my $self = shift;

    my $text = "";

    $text .= "\n\n<hr>\n";

    $text .= $self->get_navigation_bar();

    $text .= "</body>\n";
    $text .= "</html>\n";

    return $text;
}

sub get_contents_helper
{
    my $self = shift;

    my $branch     = shift;
    my $url        = shift;
    my $coords_ref = shift;
    my @coords     = @{$coords_ref};

    my $text = "";
    $text .= "<li>";
    $text .=
        "<a href=\""
        . $self->doc_id->get_relative_url(
        QuadPres::Url->new( [@$url], exists( $branch->{'subs'} ), $self->mode )
        )
        . "\" class=\""
        . $contents_style_class . "\">";
    my @coords_plus_1 = ( map { $_ + 1; } @coords );
    $text .= join( ".", @coords_plus_1 );
    $text .= ". ";
    $text .= $branch->{'title'};
    $text .= "</a>\n";

    if ( exists( $branch->{'subs'} ) )
    {
        $text .= "<ul class=\"$contents_style_class\">\n";
        my $index = 0;
        foreach my $sb ( @{ $branch->{'subs'} } )
        {
            $text .= $self->get_contents_helper(
                $sb,
                [ @$url,   $sb->{'url'} ],
                [ @coords, $index ],
            );
            $index++;
        }
        $text .= "</ul>\n";
    }
    $text .= "</li>";
    return $text;
}

sub get_contents
{
    my $self = shift;

    my $text = "";

    my @coords = @{ $self->coords };
    my @url;

    my $b = $self->contents;

    my $i;

    for ( $i = 0 ; $i < scalar(@coords) ; $i++ )
    {
        $b = $b->{'subs'}->[ $coords[$i] ];
        push @url, $b->{'url'};
    }

    if ( exists( $b->{'subs'} ) )
    {
        for ( $i = 0 ; $i < scalar( @{ $b->{'subs'} } ) ; $i++ )
        {
            $text .= $self->get_contents_helper(
                $b->{'subs'}->[$i],
                [ @url,    $b->{'subs'}->[$i]->{'url'} ],
                [ @coords, $i ],
            );
        }
    }

    return
          "<ul class=\"$contents_style_class"
        . "main\">\n"
        . $text
        . "</ul>\n";    # The wrapping <ul>'s are
        # meant to make sure there are no spaces between the various
        # lines.
        # It just works.
}

sub get_menupath_text
{
    # We are not using $self, but it may prove useful in the future, so a
    # stitch in time saves nine. So for the while get_menupath_text is treated
    # as a method function.
    my $self = shift;

    my $inside = shift;

    # Remove new-lines
    $inside =~ s/\n//g;

    # Remove the existing <tt>'s and such.
    $inside =~ s/< *\/? *tt *>//;

    # convert these ampersand escapes to normal text.
    if (0)
    {
        $inside =~ s/&(amp|lt|gt);/
            (($1 eq "amp") ?
                "&" :
                ($1 eq "lt") ?
                    "<" :
                    ">"
            )
                    /ge;
    }

    # Split to the menu path components
    my @components = split( /\s*-&gt;\s*/, $inside );

    # Wrap the components of the path with the HTML Cascading Style
    # Sheets Magic
    my @components_rendered =
        map { "\n<b class=\"menupathcomponent\">\n" . $_ . "\n" . "</b>\n" }
        @components;

    # An arrow wrapped in CSS magic.
    my $separator_string =
        "\n <font class=\"menupathseparator\">\n" . "-&gt;" . "</font> \n";

    my $final_string = join( $separator_string, @components_rendered );

    $final_string =
          ( "&nbsp;" x 2 )
        . "<font class=\"menupath\">"
        . $final_string
        . "</font>";

    return $final_string;
}

sub process_document_text
{
    my $self = shift;

    my $text = shift;

    my $header   = $self->get_header();
    my $footer   = $self->get_footer();
    my $contents = $self->get_contents();

    $text =~
s/<!-+ *\& *begin_header *-+>[\x00-\xFF]*?<!-+ *\& *end_header *-+>/$header/;
    $text =~
s/<!-+ *\& *begin_footer *-+>[\x00-\xFF]*?<!-+ *\& *end_footer *-+>/$footer/;
    $text =~
s/<!-+ *\& *begin_contents *-+>[\x00-\xFF]*?<!-+ *\& *end_contents *-+>/$contents/;
    $text =~
s/<!-+ *\& *begin_menupath *-+>([\x00-\xFF]*?)<!-+ *\& *end_menupath *-+>/$self->get_menupath_text($1)/ge;

    return $text;
}

sub render_text
{
    my $self = shift;

    my $base_text = $self->get_document_base_text();
    my $text      = $self->process_document_text($base_text);

    return $text;
}

sub render
{
    my $self = shift;
    eval {
        $self->_populate_coords();
        my $text = $self->render_text();
        if ( $self->mode eq 'cgi' )
        {
            print "Content-Type: text/html\n\n";
        }
        print $text;
    };

    if ($@)
    {
        if ( $self->mode eq 'cgi' )
        {
            print "Content-Type: text/plain\n\n";
        }
        print "Error!\n\n";
        print $@;
    }

    return;
}

sub traverse_tree
{
    my $self     = shift;
    my $callback = shift;

    my $contents = $self->contents;

    my $traverse_helper;
    $traverse_helper = sub {
        my $path_ref = shift;
        my $coords   = shift;
        my $branch   = shift;

        $callback->(
            'path'   => $path_ref,
            'branch' => $branch,
            'coords' => $coords,
        );

        if ( exists( $branch->{'subs'} ) )
        {
            # Let's traverse all the directories
            my $new_coord = 0;
            foreach my $sub_branch ( @{ $branch->{'subs'} } )
            {
                $traverse_helper->(
                    [ @$path_ref, $sub_branch->{'url'} ],
                    [ @$coords, $new_coord ], $sub_branch,
                );
            }
            continue
            {
                $new_coord++;
            }
        }
    };

    $traverse_helper->( [], [], $contents );

    return;
}

sub get_breadcrumbs_trail
{
    my $qp  = shift;
    my $sep = shift;

    if ( !defined($sep) )
    {
        $sep = " → ";
    }

    my @abs_coords = @{ $qp->{'coords'} };

    my @strs;
    for my $end ( (-1) .. $#abs_coords )
    {
        my @coords = @abs_coords[ 0 .. $end ];
        my $s =
            "<a href=\""
            . escape_html(
            $qp->get_control_url( $qp->get_url_by_coords( \@coords ) ) )
            . "\">"
            . $qp->get_subject_by_coords( \@coords ) . "</a>";
        push @strs, $s;
    }

    return join( $sep, @strs );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

QuadPres - a presentation / slides manager.

=head1 VERSION

version 0.28.3

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 contents

TBD.

=head2 coords

TBD.

=head2 doc_id

TBD.

=head2 doc_id_slash_terminated

TBD.

=head2 get_breadcrumbs_trail

TBD.

=head2 get_contents

TBD.

=head2 get_contents_helper

TBD.

=head2 get_contents_url

TBD.

=head2 get_control_text

TBD.

=head2 get_control_url

TBD.

=head2 get_document_base_text

TBD.

=head2 get_footer

TBD.

=head2 get_header

TBD.

=head2 get_last_url

TBD.

=head2 get_menupath_text

TBD.

=head2 get_most_advanced_leaf

TBD.

=head2 get_navigation_bar

TBD.

=head2 get_next_url

TBD.

=head2 get_prev_url

TBD.

=head2 get_relative_url__depcracated

TBD.

=head2 get_style_css_url

TBD.

=head2 get_subject

TBD.

=head2 get_subject_by_coords

TBD.

=head2 get_title

TBD.

=head2 get_up_url

TBD.

=head2 get_url_by_coords

TBD.

=head2 mode

TBD.

=head2 navigation_bar

TBD.

=head2 process_document_text

TBD.

=head2 render

TBD.

=head2 render_text

TBD.

=head2 stage_idx

TBD.

=head2 traverse_tree

TBD.

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/QuadPres>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=QuadPres>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/QuadPres>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/Q/QuadPres>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=QuadPres>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=QuadPres>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-quadpres at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=QuadPres>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/quad-pres>

  git clone https://github.com/shlomif/quad-pres.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/quad-pres/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
