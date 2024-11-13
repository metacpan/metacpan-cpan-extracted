package Muster::LeafFile::EXIF;
$Muster::LeafFile::EXIF::VERSION = '0.92';
#ABSTRACT: Muster::LeafFile::EXIF - an EXIF-containing file in a Muster content tree
=head1 NAME

Muster::LeafFile::EXIF - an EXIF-containing file in a Muster content tree

=head1 VERSION

version 0.92

=head1 DESCRIPTION

File nodes represent files in a Muster::Content content tree.
This is an EXIF-containing file. It is meant to be subclassed with specific files.

=cut

use Mojo::Base 'Muster::LeafFile';

use Carp;
use Image::ExifTool qw(:Public);
use Text::Markdown::Discount 'markdown';

sub is_this_a_binary {
    my $self = shift;

    return 1;
}

sub build_meta {
    my $self = shift;

    my $meta = $self->SUPER::build_meta();

    # What is in the EXIF overrides the defaults
    my $info = ImageInfo($self->filename);

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
    foreach my $field (qw(Author Artist Creator))
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

    # The URL could be from the Source or the Identifier
    # Check through them until you find a non-empty one which contains an actual URL
    foreach my $field (qw(Source Identifier))
    {
        if (exists $info->{$field}
                and $info->{$field}
                and $info->{$field} =~ /^http/
                and !exists $meta->{url})
        {
            $meta->{url} = $info->{$field};
        }
    }

    # There are multiple fields which could be used as a file date.
    # Check through them until you find a non-empty one.
    my $date = '';
    foreach my $field (qw(CreateDate DateTimeOriginal Date PublishedDate PublicationDate))
    {
        if (exists $info->{$field} and $info->{$field} and !$date)
        {
            $date = $info->{$field};
            # often the formatting can be different
            # Change YYYY:MM:DD to YYYY-MM-DD
            $date =~ s/^(\d+):(\d+):(\d+)/$1-$2-$3/;
        }
    }
    $meta->{date} = $date if $date;
    $meta->{creation_date} = $date if $date;

    # Use a consistent naming for tag fields.
    # Combine the tag-like fields together.
    # Put them in a hash because there might be duplicates
    my %tags = ();
    foreach my $field (qw(Keywords Subject))
    {
        if (exists $info->{$field} and $info->{$field})
        {
            my @tags = split(/,\s*/, $info->{$field});
            foreach my $t (@tags)
            {
                $t =~ s/ - / /g; # remove isolated dashes
                $t =~ s/[^\w\s,-]//g; # remove non-word characters
                $tags{$t}++;
            }
        }
    }
    $meta->{tags} = join('|', sort keys %tags);
    delete $meta->{tags} if !$meta->{tags}; # remove empty tag-field

    # There are SOOOOOO many fields in EXIF data, just remember a subset of them
    foreach my $field (qw(
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
