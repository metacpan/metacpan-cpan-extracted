package Muster::LeafFile::EXIF;
$Muster::LeafFile::EXIF::VERSION = '0.9501';
#ABSTRACT: Muster::LeafFile::EXIF - an EXIF-containing file in a Muster content tree
=head1 NAME

Muster::LeafFile::EXIF - an EXIF-containing file in a Muster content tree

=head1 VERSION

version 0.9501

=head1 DESCRIPTION

File nodes represent files in a Muster::Content content tree.
This is an EXIF-containing file. It is meant to be subclassed with specific files.

=cut

use Mojo::Base 'Muster::LeafFile';

use Carp;
use Image::ExifTool qw(:Public);
use Text::Markdown::Discount 'markdown';
use YAML::Any;
use List::MoreUtils qw(uniq);

sub is_this_a_binary {
    my $self = shift;

    return 1;
}

sub build_meta {
    my $self = shift;

    my $meta = $self->SUPER::build_meta();

    # Fields found in the EXIF will replace the defaults (e.g. title)
    my $exif_options = {DateFormat => "%Y-%m-%d %H:%M:%S"};
    my $info = ImageInfo($self->filename,$exif_options);

    # Check if this is a Gutenberg book; they have quirks.
    my $is_gutenberg_book = 0;
    if (exists $info->{Identifier}
            and $info->{'Identifier'} =~ m!http://www.gutenberg.org/ebooks/\d+!)
    {
        $is_gutenberg_book = 1;
        # If this is a Gutenberg book, the Identifier holds the correct URL
        $meta->{'url'} = $info->{'Identifier'};
    }

    # There are multiple fields which could be used as a file "description".
    # Check through them until you find a non-empty one.
    my $description = '';
    foreach my $field (qw(Caption-Abstract Comment ImageDescription UserComment Description))
    {
        if (exists $info->{$field} and $info->{$field} and !$description)
        {
            $description = $info->{$field};
            $description =~ s/\n$//; # remove trailing newlines
        }
    }
    $meta->{description} = $description if $description;
 
    # There are multiple fields which could be used as a file content creator.
    # Check through them until you find a non-empty one.
    my $creator = '';
    foreach my $field (qw(Author Artist Creator MetadataCreator))
    {
        if (exists $info->{$field} and $info->{$field} and !$creator)
        {
            $creator = $info->{$field};
        }
    }
    $meta->{creator} = $creator if $creator;

    # There are multiple fields which could be used as a copyright notice.
    # Check through them until you find a non-empty one.
    my $copyright = '';
    foreach my $field (qw(License Rights))
    {
        if (exists $info->{$field} and $info->{$field} and !$copyright)
        {
            $copyright = $info->{$field};
        }
    }
    $meta->{copyright} = $copyright if $copyright;

    # Alt text!
    my $alt_text = '';
    foreach my $field (qw(AltTextAccessibility))
    {
        if (exists $info->{$field} and $info->{$field} and !$alt_text)
        {
            $alt_text = $info->{$field};
        }
    }
    $meta->{alt_text} = $alt_text if $alt_text;

    # The URL could be from the Source or the Identifier
    # Check through them until you find a non-empty one which contains an actual URL
    foreach my $field (qw(Source Identifier MetadataIdentifier))
    {
        if (exists $info->{$field}
                and $info->{$field}
                and $info->{$field} =~ /^http/
                and !exists $meta->{url})
        {
            $meta->{url} = $info->{$field};
        }
    }

    # CreateDate is going to be treated as a separate field
    my $create_date = '';
    foreach my $field (qw(CreateDate))
    {
        if (exists $info->{$field} and $info->{$field} and !$create_date)
        {
            $create_date = $info->{$field};
        }
    }
    $meta->{create_date} = $create_date if $create_date;

    # There are multiple fields which could be used as a file date.
    # Check through them until you find a non-empty one.
    my $date = '';
    foreach my $field (qw(DateTimeOriginal Date PublishedDate PublicationDate))
    {
        if (exists $info->{$field} and $info->{$field} and !$date)
        {
            $date = $info->{$field};
        }
    }
    $meta->{date} = $date if $date;

    # Use a consistent naming for tag fields.
    # Combine the tag-like fields together.
    # Preserve the order and check for dupicates later with uniq
    my @tags = ();
    foreach my $field (qw(Keywords Subject))
    {
        if (exists $info->{$field} and $info->{$field})
        {
            my $val = $info->{$field};
            my @these_tags;
            if ($is_gutenberg_book)
            {
                # gutenberg tags are multi-word, separated by comma-space or ' -- '
                # and can have parens in them
                $val =~ s/\(//g;
                $val =~ s/\)//g;
                $val =~ s/\s--\s/,/g;
                @these_tags = split(/,\s?/, $val);
            }
            else
            {
                @these_tags = split(/,\s*/, $val);
            }
            foreach my $t (@these_tags)
            {
                $t =~ s/ - / /g; # remove isolated dashes
                $t =~ s/[^\w\s,-]//g; # remove non-word characters
                push @tags, $t;
            }
        }
    }
    # Are there any tags?
    if (@tags)
    {
        # remove duplicates
        $meta->{tags} = [uniq @tags];
    }
    else # remove empty tag-field
    {
        delete $meta->{tags};
    }

    # There are SOOOOOO many fields in EXIF data, just remember a subset of them
    foreach my $field (qw(
Flash
FileSize
ImageHeight
ImageSize
ImageWidth
Megapixels
Location
Title
))
    {
        if (exists $info->{$field} and $info->{$field})
        {
            $meta->{lc($field)} = $info->{$field};
        }
    }

    # -------------------------------------------------
    # Freeform Fields
    # These are stored as YAML data in the Instructions field.
    # -------------------------------------------------
    if (exists $info->{Instructions}
            and $info->{Instructions}
            and $info->{Instructions} =~ /^---/)
    {
        my $data;
        eval {$data = Load($info->{Instructions});};
        if ($@)
        {
            warn __PACKAGE__, " Load of YAML data failed: $@";
        }
        elsif (!$data)
        {
            warn __PACKAGE__, " no legal YAML";
        }
        else # okay
        {
            foreach my $field (sort keys %{$data})
            {
                $meta->{$field} = $data->{$field};
            }
        }
    }
    return $meta;
}

=head2 build_raw

The raw content of the page.
For binary files, the "page" content is empty;
if you want to show the actual binary file,
do a source-file request.

=cut
sub build_raw {
    my $self = shift;

    return "";
}

=head2 build_html

Create the HTML for this binary-file page.

=cut
sub build_html {
    my $self = shift;
    
    my $content = $self->cooked();
    # if the output is going to be text, don't process it
    if (defined $self->meta->{render_format}
            and $self->meta->{render_format} eq 'txt')
    {
        return $content;
    }
    elsif (defined $content
            and $content
            and defined $self->meta->{html_from})
    {
        # This probably needs to be done more generically
        # by using modules' own methods,
        # but this will do for now.
        if ($self->meta->{html_from} eq 'html')
        {
            # HTML doesn't need processing
            return $content;
        }
        elsif ($self->meta->{html_from} eq 'txt')
        {
    return <<EOT;
<pre>
$content
</pre>
EOT
        }
        elsif ($self->meta->{html_from} eq 'mdwn')
        {
            return markdown($content);
        }
        else # Don't know what this is, don't process
        {
            return $content;
        }
    }
    else
    {
        return $content;
    }
}

1;

__END__
