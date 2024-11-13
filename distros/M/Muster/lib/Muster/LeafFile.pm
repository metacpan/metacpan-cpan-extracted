package Muster::LeafFile;
$Muster::LeafFile::VERSION = '0.92';
#ABSTRACT: Muster::LeafFile - a file in a Muster content tree
=head1 NAME

Muster::LeafFile - a file in a Muster content tree

=head1 VERSION

version 0.92

=head1 SYNOPSIS

    use Muster::LeafFile;
    my $file = Muster::LeafFile->new(
        filename => 'foo.md'
    );
    my $html = $file->html;

=head1 DESCRIPTION

File nodes represent files in a content tree.

=cut

use Mojo::Base -base;

use Carp;
use File::Basename 'basename';
use File::stat;
use POSIX qw(strftime);
use YAML::Any;
use Lingua::EN::Titlecase;
use File::MimeInfo::Magic;

has pagename    => '';
has pagesrcname    => '';
has parent_page => '';
has is_binary   => sub { shift->is_this_a_binary };
has bald_name    => sub { shift->build_bald_name };
has hairy_name    => sub { shift->build_hairy_name };
has title       => sub { shift->build_title };
has filename   => sub { croak 'no filename given' };
has filetype   => sub { shift->build_filetype };
has extension  => sub { shift->build_ext };
has pagename   => sub { shift->build_pagename };
has pagesrcname   => sub { shift->build_pagesrcname };

=head2 raw

The raw content.

=cut
sub raw {
    my $self = shift;
    if (!exists $self->{raw})
    {
        $self->{raw} = $self->build_raw();
    }
    return $self->{raw};
}

=head2 cooked

The "cooked" (processed) content.

=cut
sub cooked {
    my $self = shift;
    my $new_content = shift;
    if (defined $new_content)
    {
        $self->{cooked} = $new_content;
    }
    elsif (!exists $self->{cooked})
    {
        $self->{cooked} = $self->raw;
    }
    return $self->{cooked};
}

=head2 html

HTML generation.

=cut
sub html {
    my $self = shift;
    if (!exists $self->{html})
    {
        $self->{html} = $self->build_html();
    }
    return $self->{html};
}

=head2 meta

Get the meta-data from the file.

=cut
sub meta {
    my $self = shift;
    if (!exists $self->{meta})
    {
        $self->{meta} = $self->build_meta();
    }
    return $self->{meta};
}

=head2 decache

Removed the cached information.
I'm not sure we still need to do this?

=cut
sub decache {
    my $self = shift;
    
    delete $self->{raw};
    delete $self->{html};
    delete $self->{meta};
}

=head2 build_title

Build the title for this page.

=cut
sub build_title {
    my $self = shift;

    # try to extract title
    return $self->meta->{title} if exists $self->{meta} and exists $self->meta->{title};
    return $1 if defined $self->html and $self->html =~ m|<h1>(.*?)</h1>|i;
    return $self->bald_name;
} # build_title

=head2 reclassify

Reclassify this object as a Muster::LeafFile subtype.
If a subtype exists, cast to that subtype and return the object;
if not, return self.
To simplify things, filetypes are determined by the file extension,
and the object name will be Muster::LeafFile::$filetype

=cut

sub reclassify {
    my $self = shift;

    my $filetype = $self->filetype;
    if ($filetype)
    {
        my $subtype = __PACKAGE__ . "::" . $filetype;
        eval "require $subtype;"; # needs to be quoted because $subtype is a variable
        $subtype->import();
        bless $self, $subtype;
        # initialize the meta data for this leaf, now that it knows how to parse it
        $self->meta();
        return $self;
    }
    return $self;
}

=head2 build_bald_name

Build the base name of the related page with no suffix.
It is "bald" because the suffix has been chopped off.

=cut
sub build_bald_name {
    my $self = shift;

    # get last filename part
    my $base = basename($self->filename);

    # delete the suffix
    $base =~ s/\.\w+$//;

    return $base;
} # build_bald_name

=head2 build_hairy_name

Build the base name of the related page, including the suffix.
It is "hairy" because the suffix has not been chopped off.

=cut
sub build_hairy_name {
    my $self = shift;

    # get last filename part
    my $base = basename($self->filename);

    return $base;
} # build_hairy_name

=head2 is_this_a_binary

If we don't know what it is, assume it is a binary file.
Returns undef if the file is NOT a binary file.
This is so we can use "IS NULL" tests in SQL for it.

=cut
sub is_this_a_binary {
    my $self = shift;
    return 1;
}

=head2 build_pagename

Create the pagename from the filename.

=cut
sub build_pagename {
    my $self = shift;

    # build from parent_page, infix slash and name
    return join '/' => grep {$_ ne ''} $self->parent_page, $self->bald_name;
}

=head2 build_pagesrcname

Create the pagesrcname from the filename.

=cut
sub build_pagesrcname {
    my $self = shift;

    # build from parent_page, infix slash and hairy name
    return join '/' => grep {$_ ne ''} $self->parent_page, $self->hairy_name;
}

=head2 build_filetype

Derive the filetype for this file, if it has a known module for it.
Otherwise, the filetype is empty.

=cut
sub build_filetype {
    my $self = shift;

    my $file=$self->filename;

    # the extension is the filetype only if there exists a Muster::LeafFile::*ext* module for it.
    if ($file =~ /\.([^.]+)$/) {
        my $pt = $1;
        my $subtype = __PACKAGE__ . "::" . $pt;
        my $has_filetype = eval "require $subtype;"; # needs to be quoted because $subtype is a variable
        return $pt if $has_filetype;
    }
    return '';
}

=head2 build_ext

The file's extension.

=cut
sub build_ext {
    my $self = shift;

    my $ext = '';
    if ($self->filename =~ /\.(\w+)$/)
    {
        $ext = $1;
    }
    return $ext;
}

=head2 build_raw

The raw content of the page.

=cut
sub build_raw {
    my $self = shift;

    # We only want to read text files;
    # since there could be all sorts of binary files
    # that don't have their own LeafFile module,
    # it behooves us to check before opening it.
    my $fn = $self->filename;
    my $mime_type = mimetype($fn);
    my $content = '';
    if ($mime_type =~ /text/)
    {
        # Open file for decoded reading
        open my $fh, '<:encoding(UTF-8)', $fn or croak "couldn't open $fn: $!";

        # slurp
        $content = do { local $/; <$fh> };

        # Test if it is really UTF-8
        # See: https://www.perlmonks.org/?node_id=669902
        utf8::decode($content)
            or carp "LeafFile::build_raw INVALID UTF-8 ($mime_type) ", $self->filename;
    }
    return $content;
}

=head2 build_meta

The meta-data extracted from the file.

=cut
sub build_meta {
    my $self    = shift;

    # Unix filesystems do NOT store the file creation time.  The default date
    # of a file is the mtime (the last modification time), so that's what we'll
    # have to live with.

    # NOTE: Many people think that the ctime is the creation time, but it is
    # the "change time", which is the last modification of the inode. This will
    # either be the same as the mtime, or more recent than the mtime, if the
    # file permissions have been changed without changing the content.  A file
    # may store its creation-date in its meta-data, but that will depend on the
    # filetype of that particular file, so we can't deal with it here.
    # Therefore the most relevant file "date" comes from the mtime.

    my $st = stat($self->filename);
    my $date = strftime('%Y-%m-%d %H:%M', localtime($st->mtime));

    my $grandparent_page = '';
    if ($self->pagename =~ m{^(.*)/[-\.\w]+/[-\.\w]+$}o)
    {
        $grandparent_page = $1;
    }
    else # top-level page
    {
        $grandparent_page = '';
    }

    # There is always the default information
    # of pagename, filename etc.
    my $meta = {
        pagename=>$self->pagename,
        pagesrcname=>$self->pagesrcname,
        parent_page=>$self->parent_page,
        filename=>$self->filename,
        filetype=>$self->filetype,
        is_binary=>$self->is_binary,
        extension=>$self->extension,
        bald_name=>$self->bald_name,
        hairy_name=>$self->hairy_name,
        title=>$self->derive_title,
        date=>$date,
        mtime=>$st->mtime,
        grandparent_page=>$grandparent_page,
    };

    return $meta;
}

=head2 derive_title

Derive the title without trying to create HTML.

=cut
sub derive_title {
    my $self = shift;

    # get the title from the name of the file
    my $name = $self->bald_name;
    $name =~ s/[_-]/ /g;
    my $tc = Lingua::EN::Titlecase->new($name);
    return $tc->title();
}

=head2 build_html

Create the default HTML for an unknown page.

=cut
sub build_html {
    my $self = shift;
    
    my $me = $self->pagename();
    my $title = $self->derive_title();
    return <<EOT;
<h1>$title</h1>
<p>
$me
</p>
EOT

}

1;

__END__
