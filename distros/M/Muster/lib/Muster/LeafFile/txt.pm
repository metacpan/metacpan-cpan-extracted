package Muster::LeafFile::txt;
$Muster::LeafFile::txt::VERSION = '0.93';
#ABSTRACT: Muster::LeafFile::txt - a plain text file in a Muster content tree
=head1 NAME

Muster::LeafFile::txt - a plain text file in a Muster content tree

=head1 VERSION

version 0.93

=head1 DESCRIPTION

File nodes represent files in a Muster::Content content tree.
This is a plain text file.

=cut

use Mojo::Base 'Muster::LeafFile';

use Carp;
use Mojo::Util      'decode';
use YAML::Any;

=head2 is_this_a_binary

Test if this type of file which just contains binary data.

=cut
sub is_this_a_binary {
    my $self = shift;

    return undef;
}

=head2 build_html

Convert the content into HTML (output) format.
If the output is going to be .txt, then leave it as it is.

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
    return <<EOT;
<pre>
$content
</pre>
EOT

}

=head2 build_meta

Fill in the meta-data for this file.

=cut
sub build_meta {
    my $self = shift;

    my $meta = $self->SUPER::build_meta();

    # add the wordcount to the default meta
    $meta->{wordcount} = $self->wordcount;

    return $meta;
}

=head2 wordcount

Calculate the word-count of the content.

=cut
sub wordcount {
    my $self = shift;

    if (!exists $self->{wordcount})
    {
        my $content = $self->raw();

        # count the words in the content
        $content =~ s/<[^>]+>/ /gs; # remove html tags
        # Remove everything but letters + spaces
        # This is so that things like apostrophes don't make one
        # word count as two words
        $content =~ s/[^\w\s]//gs;

        my @matches = ($content =~ m/\b[\w]+/gs);
        $self->{wordcount} = scalar @matches;
    }

    return $self->{wordcount};
} # wordcount
1;

__END__
