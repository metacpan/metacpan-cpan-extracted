package Net::Posterous::Post;

use base qw(Net::Posterous::Object);
use Class::Accessor "antlers";
use Scalar::Util qw(blessed);
use Data::Dumper;
use MIME::Base64;

use Net::Posterous::Media::Image;
use Net::Posterous::Media::Video;
use Net::Posterous::Media::Audio;
use Net::Posterous::Media::Local;



=head1 NAME

Net::Posterous::Post - represent a post instance in Net::Posterous

=cut

=head1 METHODS

=cut

=head2 new

Create a new Post

=cut

sub new {
    my $class    = shift;
    my %opts     = @_;
    my $media    = delete $opts{media};
    my $comments = delete $opts{comments} || delete $opts{comment};
    my $self     = bless \%opts, $class;
    $self->media('ARRAY' eq ref($media) ? @$media : $media) if $media;
    $self->comments('ARRAY' eq ref($comments) ? @$commend : $comments) if $comments;
    return $self;
}



=head2 id 

Get or set the id of the post.

=cut

has id => ( is => "rw", isa => "Int"  );

=head2 title

Get or set the title of the post.

=cut

has title => ( is => "rw", isa => "Str" );

=head2 body 

Get or set the body of the post.

=cut

has body => ( is => "rw", isa => "Str" );

=head2 tags  [tag[s]]

Get or set the tags for a post as an array of tags.

=cut

sub tags{
    my $self = shift;
    $self->tag(join(",", @_)) if @_;
    return split /\s*,\s*/, $self->tag || "";
}

=head2 tag [tag list]

Get or set the tags for a post as an string of comma separated tags.

=cut

has tag => ( is =>"rw", isa => "Str" );

=head2 datetime

Get or set the date of this post as a C<DateTime> object.

=cut

sub datetime {
   shift->_handle_datetime(@_);
}

=head2 date

Get or set the date of this post as an RFC822 encoded date string.

=cut

has date => ( is => "rw", isa => "Str" );

=head2 site_id

Get the site id of this Post

=cut

has site_id  => ( is => "rw", isa => "Int"  );

=head2 media 

Get or set a list of C<Net::Posterous::Media> objects for this post.

=cut
sub media {
    my $self = shift;
    if (@_) {
        my @tmp = (blessed $_[0]) ? map { $_->_to_params } @_ : @_;
        $self->_media(\@tmp);
    }
    return map { Net::Posterous::Media->new(%$_) } @{$self->_media || []};
}
has _media => ( is => "rw", isa => "ArrayRef" );

=head2 comments

Get or set a list of C<Net::Posterous::Comment> objects for this post.

=cut
sub comments {
    my $self = shift;
    if (@_) {
        my @tmp = (blessed $_[0]) ? map { $_->_to_params } @_ : @_;
        $self->_comments(\@tmp);
    }
    return map { Net::Posterous::Comment->new(%$_) } @{$self->_comments || []};
}
has _comments => ( is => "rw", isa => "ArrayRef" );



=head2 autopost 

Get or set whether to autopost.

=cut

has autopost => ( is => "rw", isa => "Bool" );

=head2 private

Get or set whether this is private.

=cut

has private => ( is => "rw", isa => "Bool" );

=head2 source 

Get or set what the source app for this post is.

=cut

# TODO should this be Net::Posterous-<version> by default?
has source => (is => "rw", isa => "Str" );

=head2 source_link 

=head2 sourceLink

Get or set what the link to the source app for this post is.

C<sourceLink> is an alias due to Posterous having interestingly inconsistent naming schema.

=cut

sub source_link { shift->sourceLink(@_) }

has sourceLink => (is => "rw", isa => "Str" );

=head2 comments_enabled 

=head2 commentsenabled.

Get or set whether comments are enabled for this post.

C<commentsenabled> is an alias due to Posterous having interestingly inconsistent naming schema.

=cut

sub comments_enabled { shift->commentsenabled(@_) }
has commentsenabled => ( is => "rw", isa => "Bool" );


=head2 url 

Get or set the http://post.ly url for this post.

=cut

has url => ( is => "rw", isa => "Str" );

=head2 short_code 

Get or set the short code for this post.

=cut
sub short_code {
    my $self = shift;
    if (@_) {
        my $id = shift;
        $id =~ s!^http://post\.ly/!!;
        $self->url("http://post.ly/$id");
    }
    my $id = $self->url;
    $id =~ s!^http://post\.ly/!!;
    return $id;
}


=head2 longurl 

Get or set the long url for this Post.

=cut

has longurl => ( is => "rw", isa => "Str" );


=head2 link

Get or set the link for this Post.

=cut
# TODO is this the same as longurl
has link => ( is => "rw", isa => "Str" );

=head2 views

Get or set the number of views for this Post.

=cut

has views => ( is => "rw", isa => "Int"  );

=head2 author

Get or set the author for this Post.

=cut

has author => ( is => "rw", isa => "Str" );

=head2 author_pic 

Get or set the author picture for this Post.

C<authorpic> is an alias due to Posterous having interestingly inconsistent naming schema.

=cut

sub author_pic { shift->authorpic(@_) }
has authorpic => ( is => "rw", isa => "Str" );

=head2 comments_count 

Get or set the count of the number of comments for this post.

C<commentscount> is an alias due to Posterous having interestingly inconsistent naming schema.

=cut
sub comments_count { shift->commentscount(@_) }
has commentscount => ( is => "rw", isa => "Int" );

sub _to_params {
    my $self   = shift;
    my @keys   = $self->id ? qw(id title body) 
                           : qw(site_id title body autopost private date tags source sourceLink);     
    # Pass different params depending on whether we're creating or updating ... why Posterous WHY?                       
    my %params = ();
    foreach my $key (@keys) {
        my $val = $self->$key || next;
        $params{$key} = $val;
    }
   
    # Find local media to get ready to upload
    my @media = grep { $_->isa('Net::Posterous::Media::Local') } $self->media;
    $params{@media>1 ? 'media[]' : 'media'} = [ map { [ $_->file ] } @media ];
    return %params;
}

1;