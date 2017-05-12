package Parley::Schema::IpBanType;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Parley::Version;  our $VERSION = $Parley::VERSION;

use base qw/DBIx::Class/;

# Load required DBIC stuff
__PACKAGE__->load_components(qw/PK::Auto Core/);
# Set the table name
__PACKAGE__->table('parley.ip_ban_type');
# Set columns in table
__PACKAGE__->add_columns(qw/id name description/);
# Set the primary key for the table
__PACKAGE__->set_primary_key(qw/id/);
# Set the resultset class
__PACKAGE__->resultset_class('Parley::ResultSet::IpBanType');

#
# Set relationships:
#

__PACKAGE__->add_unique_constraint(
    'unique_ban_name',
    ['name']
);

# lib/Parley/Schema/Forum.pm:__PACKAGE__->has_many(
# "threads", "Thread", { "foreign.forum" => "self.id" });
__PACKAGE__->has_many(
    'ip_bans' => 'IpBan',
    { 'foreign.ban_type_id' => 'self.id' }
);


1;
