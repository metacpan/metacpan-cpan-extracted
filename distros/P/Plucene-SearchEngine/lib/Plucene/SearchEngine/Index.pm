package Plucene::SearchEngine::Index;
use Carp;
use strict;
use warnings;
use Module::Pluggable (require => 1, search_path => [qw/Plucene::SearchEngine::Index/]);
use File::Spec::Functions qw(catfile);
use Plucene::Index::Writer;
use UNIVERSAL::require;
our $VERSION = "1.1";

__PACKAGE__->plugins;

=head1 NAME

Plucene::SearchEngine::Index - A higher level abstraction for Plucene

=head1 SYNOPSIS

    my $indexer = Plucene::SearchEngine::Index->new(
        dir => "/var/lib/plucene" 
    );

    my @documents = map { $_->document } 
        Plucene::SearchEngine::Index::File->examine("foo.html");

    $indexer->index($_) for @documents;

=head1 DESCRIPTION

This module makes it easy to write to Plucene indexes. It does so by
providing an interface to the index writer which, in terms of
complexity, sits between C<Plucene::Index::Writer> and
C<Plucene::Simple>; it also provides a framework of modules for turning
data into C<Plucene::Document> objects, so that you don't necessarily
have to parse them yourself. See L</Document Frontends and Backends> for
more on this.

Designed to be used with L<Plucene::SearchEngine::Query>, these two
modules aim to make it easy for anyone writing search engines based on
Plucene.

=head1 METHODS

=head2 new

    my $indexer = Plucene::SearchEngine::Index->new(
        dir      => "/var/plucene/foo",
        analyzer => "Plucene::Analysis::SimpleAnalyzer",
    );

This creates a new indexer; you must specify the directory to contain
the index, and you may specify an analyzer to tokenize the data.

=cut

sub new {
    my ($class, %args) = @_;
    croak("No directory given!") unless $args{dir};
    my $self = bless {
        analyzer    => "Plucene::Analysis::SimpleAnalyzer",
        %args
    }, $class;
    $self->{analyzer}->require
        or die "Couldn't require analyzer: $self->{analyzer}";
    return $self;
}

=head2 index

This adds a C<Plucene::Document> to the index.

=cut

sub index {
    my ($self, $doc) = @_;
    $self->_writer->add_document($doc);
}

sub _writer {
    my $self = shift;
    return Plucene::Index::Writer->new(
        $self->{dir},
        $self->{analyzer}->new,
        -e catfile($self->{dir}, "segments") ? 0 : 1
    );
}

=head1 Document Frontends and Backends

So far so good, but how do you create these C<Plucene::Documents>? You
can, of course, do so manually, but the easiest way is to use the
supplied C<Plucene::SearchEngine::Index::File> or
C<Plucene::SearchEngine::Index::URL> modules.

These two modules are frontends which gather metadata about a file or
URL and then hand the data off to one of the backend modules - there are
backends supplied for PDF, HTML and plain text files. These in turn
return a list of documents found in the file or URL. In most cases,
there'll only be one document, but, for instance, a Unix mbox should
return an object for each email in the box. These objects can be turned
into C<Plucene::Document> objects by calling the C<document> method on
them. This isn't done by default because you may wish to mess with the
hash yourself, or serialize it, or whatever.

=head2 Creating your own backend

If you want to handle a different type of file, it's relatively easy to
do. All you need to do is create a module called
C<Plucene::SearchEngine::Index::Whatever>; this should inherit from
C<Plucene::SearchEngine::Index::Base> and supply a
C<gather_data_from_file> method. It should also call the
C<register_handler> method to state which MIME types and file extensions
it can handle.

For instance, suppose we want to create a backend which grabs metadata
from an image and indexes that. (Not unlike
L<Plucene::SearchEngine::Index::Image>...) We'd start off like this:

    package Plucene::SearchEngine::Index::Image;
    use strict;
    use warnings;
    use base 'Plucene::SearchEngine::Index::Base';
    use Image::Info;

Now we register the mime types and file extensions we can handle:

    __PACKAGE__->register_handler(qw( 
        image/bmp           .bmp 
        image/gif           .gif
        image/jpeg          .jpeg .jpg .jpe
        ...
    ));

And our C<gather_data_from_file> method will call C<add_data> for
each bit of metadata it can find:

    sub gather_data_from_file {
        my ($self, $filename) = @_;
        my $info = image_info($filename);    
        return if $info->{error};  
        $self->add_data("size", "UnStored", scalar html_dim($info));
        $self->add_data("text", "UnStored", $info->{Comment});
        $self->add_data("subtype", "UnStored", $info->{file_ext});
        $self->add_data("created", "Date", Time::Piece->new(
            str2time($info->{LastModificationTime})));
    }

See L<Plucene::SearchEngine::Index::Base> for an explanation of C<add_data>.

Beceause C<Plucene::SearchEngine::Index> uses a plugin architecture,
once this module is installed, it will automatically be called upon to
handle those image types it can deal with, without any additional action
by the user.

=head2 Creating your own frontend

For certain types of data, such as emails, news articles, or instant
messages, you may not want to use the file or URL frontends.
Alternatively, if you have a simple piece of data which isn't
file-based, you may just want to do everything yourself. Even then,
C<Plucene::SearchEngine::Index::Base> can help you to create
C<Plucene::Documents> - just inherit from it, and use C<add_data> to add
fields to the document in your C<examine> method. See
L<Plucene::SearchEngine::Index::Base> for more details.

=head1 SEE ALSO

L<Plucene::SearchEngine::Index::File>,
L<Plucene::SearchEngine::Index::URL>,
L<Plucene::SearchEngine::Index::Base>, L<Plucene::SearchEngine::Query>,
L<Plucene::Simple>.

=head1 AUTHOR

Simon Cozens C<simon@cpan.org>.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut


1;
