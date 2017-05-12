package Parley::Schema::Forum;

# Created by DBIx::Class::Schema::Loader v0.03004 @ 2006-08-10 09:12:24

use strict;
use warnings;

use Parley::Version;  our $VERSION = $Parley::VERSION;

use base 'DBIx::Class';

__PACKAGE__->load_components("PK::Auto", "Core");
__PACKAGE__->table("parley.forum");
__PACKAGE__->add_columns(
  "id" => {
    data_type => "integer",
    #default_value => "nextval('forum_forum_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "last_post_id" => {
    data_type => "integer",
    default_value => undef,
    is_nullable => 1,
    size => 4
  },
  "post_count" => {
    data_type => "integer",
    default_value => 0,
    is_nullable => 0,
    size => 4
  },
  "active" => {
    data_type => "boolean",
    default_value => "true",
    is_nullable => 0,
    size => 1,
  },
  "name" => {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "description" => {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);

__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("forum_name_key", ["name"]);

__PACKAGE__->resultset_class('Parley::ResultSet::Forum');

__PACKAGE__->has_many("threads", "Thread", { "foreign.forum" => "self.id" });
__PACKAGE__->belongs_to(
    "last_post" => "Post",
    { 'foreign.id' => 'self.last_post_id' },
    { join_type => 'left' }
);

sub moderators {
    my $self = shift;
    my ($schema, $results, @modlist);

    $schema = $self->result_source()->schema();

    # get all forum_moderators for a given forum
    $results = $schema->resultset('ForumModerator')->search(
        {
            forum_id        => $self->id(),
            can_moderate    => 1,
        },
        {
            prefetch => [
                'person',
            ],
        }
    );

    while (my $res = $results->next()) {
        push @modlist, $res->person();
    }

    return \@modlist;
}

sub interval_ago {
    my $self = shift;
    my ($now, $duration, $longest_duration);

    # get now as a DT object
    $now = DateTime->now();

    # the difference between now and the post time
    $duration = $now - $self->created();

    # we use the largest unit to give an idea of how long ago the post was made
    foreach my $unit (qw[years months days hours minutes seconds]) {
        if ($longest_duration = $duration->in_units($unit)) {
            return _time_string($longest_duration, $unit);
        }
    };

    # we should get *something* in the loop above, but just in case
    return '0 seconds';
}
sub _time_string {
    my ($duration, $unit) = @_;

    # DateTime::Duration uses plural names for units
    # so if we have ONE we need to return the singular
    if (1 == $duration) {
        $unit =~ s{s\z}{};
    }

    return "$duration $unit";
}

1;
