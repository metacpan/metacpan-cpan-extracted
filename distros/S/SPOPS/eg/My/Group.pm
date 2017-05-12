package My::Group;

# $Id: Group.pm,v 3.1 2003/07/15 12:19:47 lachoy Exp $

use strict;

$My::Group::VERSION = sprintf("%d.%02d", q$Revision: 3.1 $ =~ /(\d+)\.(\d+)/);

my $USER_CLASS = 'My::User';

sub _base_config {
    my $config = {
       'group' => {
           class        => 'My::Group',
           isa          => [ 'My::CommonResources', 'SPOPS::Secure', 'My::Common' ],
           rules_from   => [ 'SPOPS::Tool::DBI::DiscoverField' ],
           field_discover => 'yes',
           field        => [],
           id_field     => 'group_id',
           increment_field => 1,
           sequence_name => 'sp_group_seq',
           no_insert    => [ qw/ group_id / ],
           skip_undef   => [],
           no_update    => [ qw/ group_id / ],
           base_table   => 'spops_group',
           sql_defaults => [],
           alias        => [],
           has_a        => {},
           links_to     => { $USER_CLASS => 'spops_group_user' },
           fetch_by     => [ 'name' ],
           creation_security => {
                 u   => undef,
                 g   => { 3 => 'WRITE' },
                 w   => 'READ',
           },
           track        => { create => 1, update => 1, remove => 1 },
           display      => { url => '/Group/show/' },
           name         => 'name',
           object_name  => 'Group'
      },
    };
    return $config;
}

1;

