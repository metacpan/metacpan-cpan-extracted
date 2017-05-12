package Parley::Schema::IpBan;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Parley::Version;  our $VERSION = $Parley::VERSION;

use base qw/DBIx::Class/;

# Load required DBIC stuff
__PACKAGE__->load_components(qw/PK::Auto Core/);
# Set the table name
__PACKAGE__->table('parley.ip_ban');
# Set columns in table
__PACKAGE__->add_columns(qw/
    id
    ban_type_id
    ip_range
/);
# Set the primary key for the table
__PACKAGE__->set_primary_key(qw/id/);
__PACKAGE__->resultset_class('Parley::ResultSet::IpBan');


__PACKAGE__->belongs_to(
    ban_type => 'Parley::Schema::IpBanType',
    'ban_type_id'
);

__PACKAGE__->add_unique_constraint(
    'unique_ip_ban_type',
    ['ban_type_id']
);



1;
