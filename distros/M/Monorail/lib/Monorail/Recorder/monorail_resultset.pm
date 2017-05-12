package Monorail::Recorder::monorail_resultset;
$Monorail::Recorder::monorail_resultset::VERSION = '0.4';
use strict;
use warnings;
use Monorail::Recorder;
use parent 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table($Monorail::Recorder::TableName);

__PACKAGE__->add_columns (
    id => {
        data_type         => 'int',
        is_auto_increment => 1,
    },
    name => {
        data_type         => 'varchar',
        size              => '255'
    },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint(['name']);

1;

__END__
