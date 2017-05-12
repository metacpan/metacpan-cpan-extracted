package Parley::Schema::Post;

# Created by DBIx::Class::Schema::Loader v0.03004 @ 2006-08-10 09:12:24

use strict;
use warnings;
use Data::Dump qw(pp);

use Parley::Version;  our $VERSION = $Parley::VERSION;

use DateTime;
use DateTime::Format::Pg;
use Text::Context::EitherSide;
use Text::Search::SQL;

use Parley::App::DateTime qw( :interval );

use base 'DBIx::Class';

__PACKAGE__->load_components("PK::Auto", "Core");
__PACKAGE__->table("parley.post");
__PACKAGE__->add_columns(
  "id" => {
    data_type => "integer",
    #default_value => "nextval('post_post_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "creator_id" => {
    data_type => "integer",
    default_value => undef,
    is_nullable => 0,
    size => 4
  },
  "subject" => {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "quoted_post_id" => {
    data_type => "integer",
    default_value => undef,
    is_nullable => 1,
    size => 4
  },
  "message" => {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "quoted_text" => {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "created" => {
    data_type => "timestamp with time zone",
    default_value => "now()",
    is_nullable => 1,
    size => 8,
  },
  "thread_id" => {
    data_type => "integer",
    default_value => undef,
    is_nullable => 0,
    size => 4
  },
  "reply_to_id" => {
    data_type => "integer",
    default_value => undef,
    is_nullable => 1,
    size => 4
  },
  "edited" => {
    data_type => "timestamp with time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },

  ip_addr => {
    data_type => "inet",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },

  admin_editor_id   => {},
  locked            => {},
);

__PACKAGE__->set_primary_key("id");
__PACKAGE__->resultset_class('Parley::ResultSet::Post');

__PACKAGE__->has_many(
    "threads" => "Thread",
    { "foreign.last_post_id" => "self.id" }
);
__PACKAGE__->has_many(
    "forums" => "Forum",
    { "foreign.last_post_id" => "self.id" }
);
__PACKAGE__->belongs_to(
    "creator" => "Person",
    { 'foreign.id' => "self.creator_id" },
    { join_type => 'left' }
);
__PACKAGE__->belongs_to(
    "reply_to" => "Post",
    { 'foreign.id' => "self.reply_to_id" },
    { join_type => 'left' },
);
__PACKAGE__->has_many(
  "post_reply_toes" => "Post",
  { "foreign.reply_to_id" => "self.id" },
);
__PACKAGE__->belongs_to(
    "thread" => "Thread",
    { 'foreign.id' => "self.thread_id" },
);
__PACKAGE__->belongs_to(
    "quoted_post" => "Post",
    { 'foreign.id' => "self.quoted_post_id" },
    { join_type => 'left' },
);
__PACKAGE__->has_many(
  "post_quoted_posts" => "Post",
  { "foreign.quoted_post" => "self.id" },
);
__PACKAGE__->has_many(
    "people" => "Person",
    { "foreign.last_post" => "self.id" },
);
__PACKAGE__->belongs_to(
    "admin_editor" => "Person",
    { 'foreign.id' => "self.admin_editor_id" },
);




foreach my $datecol (qw/created edited/) {
    __PACKAGE__->inflate_column($datecol, {
        inflate => sub { DateTime::Format::Pg->parse_datetime(shift); },
        deflate => sub { DateTime::Format::Pg->format_datetime(shift); },
    });
}




# accessor to use in search results to return context matches
sub match_context {
    my $self = shift;
    my $search_terms = shift;
    my ($tss, $terms);

    if (not defined $search_terms) {
        return;
    }

    $tss = Text::Search::SQL->new(
        {
            search_term     => $search_terms,
        }
    );
    $tss->parse();
    $terms = $tss->get_chunks();
    warn pp($terms);
    warn pp($self->message());

    my $context = Text::Context::EitherSide->new( $self->message(), context => 3 );
    return $context->as_string( @{ $terms } );
}

sub interval_ago {
    my $self = shift;
    my ($now, $duration, $longest_duration);

    my $interval_string = interval_ago_string(
        $self->created()
    );
    return $interval_string;
}

1;
__END__
vim: ts=8 sts=4 et sw=4 sr sta
