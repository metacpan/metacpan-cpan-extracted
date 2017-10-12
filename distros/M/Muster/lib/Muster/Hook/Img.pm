package Muster::Hook::Img;
$Muster::Hook::Img::VERSION = '0.62';
=head1 NAME

Muster::Hook::Img - Muster image and thumbnailing directive

=head1 VERSION

version 0.62

=head1 DESCRIPTION

L<Muster::Hook::Img> links to images and makes thumbnails for the links.

=cut

use Mojo::Base 'Muster::Hook::Directives';
use Muster::LeafFile;
use Muster::Hooks;
use Muster::Hook::Links;
use File::Basename qw(basename);
use File::Spec;
use File::Slurper 'write_binary';
use Image::Magick;
use YAML::Any;

use Carp 'croak';

=head1 METHODS

L<Muster::Hook::Img> inherits all methods from L<Muster::Hook::Directives>.

=head2 register

Do some intialization.

=cut
sub register {
    my $self = shift;
    my $hookmaster = shift;
    my $conf = shift;

    $self->{metadb} = $hookmaster->{metadb};

    # place to store and serve cached thumbnails
    $self->{cache_dir} = $conf->{cache_dir};
    $self->{img_dir} = File::Spec->catdir($self->{cache_dir}, 'images');
    if (!-d $self->{img_dir})
    {
        mkdir $self->{img_dir};
    }
    $self->{img_url} = $conf->{route_prefix} . 'images/';

    $hookmaster->add_hook('img' => sub {
            my %args = @_;

            return $self->do_directives(
                directive=>'img',
                call=>sub {
                    my %args2 = @_;

                    return $self->process(%args2);
                },
                %args,
            );
        },
    );
    return $self;
} # register

=head2 process

Image directive: link to image, with a thumbnail.

=cut
sub process {
    my $self = shift;
    my %args = @_;

    my $directive = $args{directive};
    my $leaf = $args{leaf};
    my $phase = $args{phase};
    my @p = @{$args{params}};
    my $image = $p[0]; # the first argument is the image
    my %params = @p;
    my $pagename = $leaf->pagename;

    # We don't display anything if:
    # - we are scanning
    # - this is the "defaults" directive
    # But if we are scanning the "defaults" directive, we want to remember it.
    if ($image eq 'defaults' or $phase eq $Muster::Hooks::PHASE_SCAN)
    {
        if ($image eq 'defaults' and $phase eq $Muster::Hooks::PHASE_SCAN)
        {
            $leaf->{meta}->{img_defaults} = Dump(@p);
        }
        return "";
    }
    # ---------------------------------------------------------
    # Not Scanning
    # ---------------------------------------------------------

    # Image defaults
    if (exists $leaf->{meta}->{img_defaults}
            and defined $leaf->{meta}->{img_defaults})
    {
        my @d = Load($leaf->{meta}->{img_defaults});
        my %d = @d;
        foreach my $key (keys %d)
        {
            if ($key ne 'defaults' and !exists $params{$key})
            {
                $params{$key} = $d{$key};
            }
        }
    }
    if (! exists $params{size} || ! length $params{size})
    {
        $params{size}='full';
    }

    my $imgpage = $self->{metadb}->bestlink($pagename, $image);
    if (!$imgpage)
    {
        return "[[$image]]"; # link to the unknown image
    }
    my $img_info = $self->{metadb}->page_or_file_info($imgpage);

    my $extension = $img_info->{extension};
    my $format;

    # Never interpret well-known file extensions as any other format,
    # in case the wiki configuration unwisely allows attaching
    # arbitrary files named *.jpg, etc.
    my $magic;
    my $offset = 0;
    open(my $in, '<', $img_info->{filename}) or croak sprintf(gettext("failed to read %s: %s"), $imgpage, $!);
    binmode($in);

    if ($extension =~ m/^(jpeg|jpg)$/is)
    {
        $format = 'jpeg';
        $magic = "\377\330\377";
    }
    elsif ($extension =~ m/^(png)$/is)
    {
        $format = 'png';
        $magic = "\211PNG\r\n\032\n";
    }
    elsif ($extension =~ m/^(gif)$/is)
    {
        $format = 'gif';
        $magic = "GIF8";
    }
    elsif ($extension =~ m/^(svg)$/is)
    {
        $format = 'svg';
    }
    else {
        # allow ImageMagick to auto-detect (potentially dangerous)
        $format = '';
    }
    # Try harder to protect ImageMagick from itself
    if (defined $magic)
    {
        my $content;
        read($in, $content, length $magic) or croak sprintf(("failed to read %s: %s"), $imgpage, $!);
        if ($magic ne $content) {
            croak sprintf(("\"%s\" does not seem to be a valid %s file"), $imgpage, $format);
        }
    }
    close($in);

    # give it a long flat name
    my $thumb_base = $imgpage;
    $thumb_base =~ s!/!-!g;
    my $imglink;
    my ($dwidth, $dheight);

    my ($w, $h);
    if ($params{size} ne 'full')
    {
        ($w, $h) = ($params{size} =~ /^(\d*)x(\d*)$/);
    }

    if ($format eq 'svg')
    {
        # svg images are not scaled using ImageMagick because the
        # pipeline is complex. Instead, the image size is simply
        # set to the provided values.
        #
        # Aspect ratio will be preserved automatically when
        # only a width or only a height is specified.
        # When both are specified, aspect ratio will not be
        # preserved.
        $imglink = $imgpage;
        $dwidth = $w if length $w;
        $dheight = $h if length $h;
    }
    else
    {
        my $im = Image::Magick->new();
        my $r = $im->Read("$format:". $img_info->{filename});
        croak sprintf(("failed to read %s: %s"), $imgpage, $r) if $r;

        if (! defined $im->Get("width") || ! defined $im->Get("height"))
        {
            croak sprintf('failed to get dimensions of %s', $imgpage);
        }

        if (! length $w && ! length $h)
        {
            $dwidth = $im->Get("width");
            $dheight = $im->Get("height");
        }
        else
        {
            croak sprintf('wrong size format "%s" (should be WxH)', $params{size})
            unless (defined $w && defined $h &&
                (length $w || length $h));

            if ($im->Get("width") == 0 || $im->Get("height") == 0)
            {
                ($dwidth, $dheight)=(0, 0);
            } elsif (! length $w || (length $h && $im->Get("height")*$w > $h * $im->Get("width")))
            {
                # using height because only height is given or ...
                # because original image is more portrait than $w/$h
                # ... slimness of $im > $h/w
                # ... $im->Get("height")/$im->Get("width") > $h/$w
                # ... $im->Get("height")*$w > $h * $im->Get("width")

                $dheight=$h;
                $dwidth=$h / $im->Get("height") * $im->Get("width");
            }
            else
            { # (! length $h) or $w is what determines the resized size
                $dwidth=$w;
                $dheight=$w / $im->Get("width") * $im->Get("height");
            }
        }
        # thumbnail?
        if ($dwidth < $im->Get("width"))
        {
            # resize down, or resize to pixels at all
            my $outfile = File::Spec->catfile($self->{img_dir}, $params{size} . '-' . $thumb_base);
            $imglink = $self->{img_url} . $params{size} . '-' . $thumb_base;

            if (-e $outfile && (-M $img_info->{filename} >= -M $outfile))
            {
                $im = Image::Magick->new;
                $r = $im->Read($outfile);
                croak sprintf("failed to read %s: %s", $outfile, $r) if $r;
            }
            else
            {
                $r = $im->Resize(geometry => "${dwidth}x${dheight}");
                croak sprintf("failed to resize: %s", $r) if $r;

                my @blob = $im->ImageToBlob();
                write_binary($outfile, $blob[0]);
            }

            # always get the true size of the resized image (it could be
            # that imagemagick did its calculations differently)

            $dwidth  = $im->Get("width");
            $dheight = $im->Get("height");
        }
        else
        {
            $imglink = $imgpage;
        }

        if (! defined($dwidth) || ! defined($dheight))
        {
            croak sprintf("failed to determine size of image %s", $imgpage)
        }
    }

    if (! exists $params{class})
    {
        $params{class}="img";
    }

    my $attrs='';
    foreach my $attr (qw{alt title class id hspace vspace})
    {
        if (exists $params{$attr})
        {
            $attrs.=" $attr=\"$params{$attr}\"";
        }
    }
	
    my $imgtag='<img src="'.$imglink.'"';
    $imgtag.=' width="'.$dwidth.'"' if defined $dwidth;
    $imgtag.=' height="'.$dheight.'"' if defined $dheight;
    $imgtag.= $attrs.
    (exists $params{align} && ! exists $params{caption} ? ' align="'.$params{align}.'"' : '').
    ' />';

    my $link;
    if (! defined $params{link})
    {
        $link = $img_info->{pagelink};
    }
    elsif ($params{link} =~ /^\w+:\/\//)
    {
        $link=$params{link};
    }

    if (defined $link)
    {
        $imgtag='<a href="'.$link.'">'.$imgtag.'</a>';
    }
    if (!exists $params{caption} and exists $img_info->{description})
    {
        $params{caption} = $img_info->{description};
    }

    if (exists $params{caption} and $params{caption})
    {
        my $style = '';
        $style = sprintf('width: %dpx;', $dwidth + 6) if defined $dwidth; # give it a bit of a margin

        return <<EOT;
<div style="$style" class="$params{class}">
$imgtag<br/>
<span class="caption">$params{caption}</span>
</div>
EOT
    }
    else
    {
        return $imgtag;
    }
} # process

1;
