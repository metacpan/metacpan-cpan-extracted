package Parley::Schema::Person;
# vim: ts=8 sts=4 et sw=4 sr sta

# Created by DBIx::Class::Schema::Loader v0.03004 @ 2006-08-10 09:12:24

use strict;
use warnings;
use Carp;

use Parley::Version;  our $VERSION = $Parley::VERSION;

use base 'DBIx::Class';

__PACKAGE__->load_components("PK::Auto", "Core");
__PACKAGE__->table("parley.person");
__PACKAGE__->add_columns(
  "id" => {
    data_type => "integer",
    is_nullable => 0,
    size => 4,
  },
  "authentication_id" => {
    data_type => "integer",
    default_value => undef,
    is_nullable => 1,
    size => 4
  },
  "last_name" => {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "email" => {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "forum_name" => {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "preference_id" => {
    data_type => "integer",
    default_value => undef,
    is_nullable => 1,
    size => 4
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
  "first_name" => {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },

  suspended     => {},
);

__PACKAGE__->set_primary_key("id");
__PACKAGE__->resultset_class('Parley::ResultSet::Person');

__PACKAGE__->add_unique_constraint(
    "person_forum_name_key",
    ["forum_name"]
);
__PACKAGE__->add_unique_constraint(
    "person_email_key",
    ["email"]
);
__PACKAGE__->has_many(
    "threads" => "Thread" =>
    { "foreign.creator_id" => "self.id" }
);
__PACKAGE__->has_many(
  "email_queues",
  "EmailQueue",
  { "foreign.recipient_id" => "self.id" },
);
__PACKAGE__->has_many(
    "posts" => "Post",
    { "foreign.creator_id" => "self.id" });
__PACKAGE__->has_many(
  "thread_views" => "ThreadView",
  { "foreign.person_id" => "self.id" },
);
__PACKAGE__->belongs_to(
    "preference" => "Preference",
    { 'foreign.id' => "self.preference_id" }
);
__PACKAGE__->belongs_to(
    "last_post" => "Post",
    { 'foreign.id' => "self.last_post_id" });
__PACKAGE__->belongs_to(
  "authentication" => "Authentication",
  { 'foreign.id' => 'self.authentication_id' },
    { join_type => 'left' }
);
__PACKAGE__->has_many(
  "registration_authentications",
  "RegistrationAuthentication",
  { "foreign.recipient" => "self.id" },
);

sub roles {
    my $record = shift;
    my ($schema, $rs);

    $schema = $record->result_source()->schema();

    $rs = $schema->resultset('Role')->search(
        {
            'authentication.id'  => $record->authentication_id(),
        },
        {
            prefetch => [
                { 'map_user_role' => 'authentication' },
            ],
        }
    );

    return $rs;
}

sub check_user_roles {
    my $record = shift;
    my @roles  = @_;

    return
        if (not @roles);

    my ($schema, $rs);

    $schema = $record->result_source()->schema();

    $rs = $schema->resultset('Role')->search(
        {
            'map_user_role.authentication_id'   => $record->authentication_id(),
            'me.name' => {
                -in => \@roles,
            },
        },
        {
            prefetch => [
                { 'map_user_role' => 'authentication' },
            ],
        },
    );

    return ($rs->count == scalar(@roles) || 0);
}

sub check_any_user_role {
    my $record = shift;
    my @roles  = @_;

    return
        if (not @roles);

    my ($schema, $rs);
    $schema = $record->result_source()->schema();

    $rs = $schema->resultset('Role')->search(
        {
            'map_user_role.authentication_id'   => $record->authentication_id(),
            'me.name' => {
                -in => \@roles,
            },
        },
        {
            prefetch => [
                { 'map_user_role' => 'authentication' },
            ],
        },
    );
    return ($rs->count > 0);
}

# suspend a user (and log a message at the same time)
sub set_suspended {
    my ($record, $args) = @_;
    my ($value, $reason, $admin_id);
    $value      = $args->{value};
    $reason     = $args->{reason};
    $admin_id   = $args->{admin}->id;

    my $schema = $record->result_source()->schema();

    if (not defined $value) {
        Carp::carp('no value passed to set_suspended()');
        return;
    }

    if (not defined $reason) {
        $reason = q{None Given};
    }

    # suspend the user and add a log action
    eval {
        $schema->txn_do(
            sub {
                # set the value of suspended
                $record->update({suspended => $value});
                # add a log message
                $schema->resultset('LogAdminAction')->create(
                    {
                        person_id   => $record->id,
                        admin_id    => $admin_id,
                        message     => $reason,

                        action => {
                            name => 'suspend_user',
                        },
                    }
                );
                return;
            }
        )
    };
    if ($@) {                                   # Transaction failed
        die "something terrible has happened!"  #
            if ($@ =~ /Rollback failed/);       # Rollback failed

        #$return_data->{error}{message} =
            #qq{Database transaction failed: $@};
        #$c->log->error( $@ );
        die $@;
    }
}

sub last_suspension {
    my $record = shift;
    my ($schema, $result);

    $schema = $record->result_source()->schema();

    $result = $schema->resultset('LogAdminAction')->search(
        {
            'action.name' => 'suspend_user',
        },
        {
            join => [qw( action )],
            rows => 1,
            order_by    => [\'created DESC'],
        }
    );

    if ($result->count()) {
        return $result->first;
    }

    return;
}

# thin wrapper around check_user_roles() for convenience
sub is_site_moderator {
    my $record = shift;

    return $record->check_user_roles(
        'site_moderator'
    );
}
# thin wrapper around check_user_roles() for convenience
sub can_suspend_account {
    my $record = shift;

    return $record->check_any_user_role(
        'site_moderator', 'suspend_account'
    );
}
# thin wrapper around check_any_user_role() for convenience
sub can_ip_ban {
    my $record = shift;

    return $record->check_any_user_role(
        'site_moderator', 'ip_ban_posting', 'ip_ban_signup', 'ip_ban_login'
    );
}

sub can_view_site_menu {
    my $record = shift;

    return $record->check_any_user_role(
        'site_moderator', 'ip_ban_posting', 'ip_ban_signup', 'ip_ban_login'
    );
}

sub can_moderate_forum {
    my $record = shift;
    my $forum_id = shift;
    my $schema = $record->result_source()->schema();

    my $results = $schema->resultset('ForumModerator')->search(
        {
            person_id       => $record->id(),
            forum_id        => $forum_id,
            can_moderate    => 1,
        },
        {
            #key     => 'forum_moderator_person_key',
        }
    );

    if ($results->count) {
        return 1;
    }

    return 0;
}

sub ips_posted_from {
    my $record = shift;
    my ($rs, $schema, @ips);

    # grab the schema so we can search a different table
    $schema = $record->result_source()->schema();

    $rs = $schema->resultset('Post')->search(
        {
            creator_id  => $record->id,
        },
        {
            distinct    => 1,
            columns     => [ qw/ip_addr/ ],
        }
    );

    while (my $result = $rs->next) {
        push @ips, $result->ip_addr;
    }

    return \@ips;
}

sub posts_from_ip {
    my ($record, $ip_address) = @_;
    my ($schema, $rs);

    # grab the schema so we can search a different table
    $schema = $record->result_source()->schema();

    $rs = $schema->resultset('Post')->search(
        {
            creator_id  => $record->id,
            ip_addr     => $ip_address,
        },
    );

    return $rs;
}

1;
