#!perl

use Test::Spec;
use Test::Deep;
use Monorail::Change::RenameTable;
use Monorail::Change::CreateTable;

describe 'An add field change' => sub {
    my $sut;
    my %sut_args;
    before each => sub {
        %sut_args = (
            to   => 'epcot',
            from => 'epcot_center',
        );
        $sut = Monorail::Change::RenameTable->new(%sut_args);
        $sut->db_type('PostgreSQL');
    };

    it 'produces valid sql' => sub {
        like($sut->as_sql, qr/ALTER TABLE epcot_center RENAME TO epcot/i);
    };

    it 'produces valid perl' => sub {
        my $perl = $sut->as_perl;

        my $new = eval $perl;
        cmp_deeply($new, all(
            isa('Monorail::Change::RenameTable'),
            methods(%sut_args),
        ));
    };

    it 'transforms a schema' => sub {
        my $schema = SQL::Translator::Schema->new;
        $schema->add_table(name => 'epcot_center');

        $sut->transform_schema($schema);

        my $old = $schema->get_table('epcot_center');
        my $new = $schema->get_table('epcot');

        cmp_deeply($old, undef);
        cmp_deeply($new, methods(name => 'epcot'));
    };
};

runtests;
