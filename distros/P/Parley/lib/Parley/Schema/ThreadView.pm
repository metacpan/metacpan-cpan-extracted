package Parley::Schema::ThreadView;

# Created by DBIx::Class::Schema::Loader v0.03004 @ 2006-08-10 09:12:24

use strict;
use warnings;

use Parley::Version;  our $VERSION = $Parley::VERSION;

use base 'DBIx::Class';
use DateTime::Format::Pg;

use Parley::App::DateTime qw( :interval );

__PACKAGE__->load_components("PK::Auto", "Core");
__PACKAGE__->table("parley.thread_view");
__PACKAGE__->add_columns(
  "id" => {
    data_type => "integer",
    #default_value => "nextval('thread_view_thread_view_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },

  "watched" => {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 0,
    size => 1,
  },

  "last_notified" => {
    data_type => "timestamp with time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },

  "thread_id" => {
    data_type => "integer",
    default_value => undef,
    is_nullable => 0,
    size => 4
  },
  "timestamp" => {
    data_type => "timestamp with time zone",
    default_value => "now()",
    is_nullable => 0,
    size => 8,
  },
  "person_id" => {
    data_type => "integer",
    default_value => undef,
    is_nullable => 0,
    size => 4
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->resultset_class('Parley::ResultSet::ThreadView');
__PACKAGE__->add_unique_constraint(
    'thread_view_person_key',
    ['person_id', 'thread_id']
);
__PACKAGE__->belongs_to(
    "thread" => "Thread",
    { 'foreign.id' => 'self.thread_id' },
);
__PACKAGE__->belongs_to(
    "person" => "Person",
    { 'foreign.id' => 'self.person_id' }
);




foreach my $datecol (qw/timestamp/) {
    __PACKAGE__->inflate_column($datecol, {
        inflate => sub { DateTime::Format::Pg->parse_datetime(shift); },
        deflate => sub { DateTime::Format::Pg->format_datetime(shift); },
    });
}



sub interval_ago {
    my $self = shift;
    my ($now, $duration, $longest_duration);

    my $interval_string = interval_ago_string(
        $self->timestamp()
    );
    return $interval_string;
}

1;
