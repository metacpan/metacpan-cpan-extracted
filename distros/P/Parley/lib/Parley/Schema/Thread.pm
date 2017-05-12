package Parley::Schema::Thread;

# Created by DBIx::Class::Schema::Loader v0.03004 @ 2006-08-10 09:12:24

use strict;
use warnings;

use Parley::Version;  our $VERSION = $Parley::VERSION;
use DateTime::Format::Pg;

use base 'DBIx::Class';

__PACKAGE__->load_components("PK::Auto", "Core");
__PACKAGE__->table("parley.thread");
__PACKAGE__->add_columns(
  "id" => {
    data_type => "integer",
    #default_value => "nextval('thread_thread_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "locked" => {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 0,
    size => 1,
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
    is_nullable => 0,
    size => undef,
  },
  "active" => {
    data_type => "boolean",
    default_value => "true",
    is_nullable => 0,
    size => 1,
  },
  "forum_id", {
    data_type => "integer",
    default_value => undef,
    is_nullable => 0,
    size => 4
  },
  "created" => {
    data_type => "timestamp with time zone",
    default_value => "now()",
    is_nullable => 1,
    size => 8,
  },
  "last_post_id" => {
    data_type => "integer",
    default_value => undef,
    is_nullable => 1,
    size => 4
  },
  "sticky" => {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 0,
    size => 1,
  },
  "post_count" => {
    data_type => "integer",
    default_value => 0,
    is_nullable => 0,
    size => 4
  },
  "view_count" => {
    data_type => "integer",
    default_value => 0,
    is_nullable => 0,
    size => 4
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->resultset_class('Parley::ResultSet::Thread');

__PACKAGE__->belongs_to(
    "creator" => "Person",
    { 'foreign.id' => 'self.creator_id' }
);
__PACKAGE__->belongs_to(
    "last_post" => "Post",
    { 'foreign.id' => 'self.last_post_id' },
);
__PACKAGE__->belongs_to(
    "forum" =>  "Forum",
    { 'foreign.id' => 'self.forum_id' }
);
__PACKAGE__->has_many(
    "posts" => "Post",
    { "foreign.thread_id" => "self.id" },
);
__PACKAGE__->has_many(
  "thread_views" => "ThreadView",
  { "foreign.thread_id" => "self.id" },
);

__PACKAGE__->has_many(
    'forum_moderators' => 'ForumModerator',
    {
        'foreign.forum' => 'self.forum_id',
    }
);


foreach my $datecol (qw/created/) {
    __PACKAGE__->inflate_column($datecol, {
        inflate => sub { DateTime::Format::Pg->parse_datetime(shift); },
        deflate => sub { DateTime::Format::Pg->format_datetime(shift); },
    });
}


sub PROBABLY_DEAD_last_post_viewed_in_thread :ResultSet {
    my ($self, $person, $thread) = @_;
    my ($last_viewed, $last_post);

    my $schema = $self->result_source()->schema();

    # we need to be careful that we haven't deleted/hidden the post that
    # matches the exact timestamp of last_viewed for a thread - this is why we
    # use <= and not ==, since we can just return the latest undeleted post

    # get the "last_viewed" value from thread_view
    $last_viewed = $schema->resultset('ThreadView')->search(
        {
            person_id  => $person->id(),
            thread_id  => $thread->id(),
        },
        {
            rows => 1,
        }
    );

    # if last_viewed isn't defined, it should mean the user has never viewed
    # this thread
    if (not defined $last_viewed) {
        warn "thread has never been viewed - returning first post in thread";

        $last_post = $schema->resultset('Post')->search(
            {
                thread_id  => $thread->id(),
            },
            {
                rows        => 1,
                order_by    => [\'created ASC'],
            }
        );

        return $last_post->first();
    }
        
    #die dump(ref $last_viewed);
    if (not $last_viewed->count()) {
        warn "no matches for 'last viewed' in last_post_viewed_in_thread()";
        return;
    }

    # now get the last post made on or before our timestamp for when we last
    # viewed the thread
    $last_post = $schema->resultset('Post')->search(
        {
            created => {
                '<=', 
                DateTime::Format::Pg->format_datetime($last_viewed->timestamp())
            },
            thread_id  => $thread->id(),
        },
        {
            rows        => 1,
            order_by    => [\'created DESC'],
        }
    );

    # return the first result (if we have any)
    if ($last_post->count()) {
        return $last_post->first();
    }

    # oh well, we didn't get anything
    # XXX this might cause problems in the future, but we'll see
    return;
}


1;
__END__
vim: ts=8 sts=4 et sw=4 sr sta
