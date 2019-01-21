#!/usr/bin/env perl

use strict;
use warnings;

use Capture::Tiny qw(capture_stderr);
use FindBin ();
use File::Basename;
use Test::More;
use Test::LongString;

use lib dirname(__FILE__) . '/../';

use MySQL::Workbench::DBIC;
use t::MySQL::Workbench::DBIC::Table;

my $bin  = $FindBin::Bin;
my $file = $bin . '/test.mwb';

my $foo = MySQL::Workbench::DBIC->new(
    file        => $file,
    schema_name => 'Schema',
    version     => '0.01',
);

my $table = t::MySQL::Workbench::DBIC::Table->new( name => 'TestTable' );
my $col   = t::MySQL::Workbench::DBIC::Column->new( name => 'column_1' );
my $index = t::MySQL::Workbench::DBIC::Index->new( name => 'index_1' );

my $sub = $foo->can('_indexes_template');

{
    my $expected = q~
=head1 DEPLOYMENT

=head2 sqlt_deploy_hook

These indexes are added to the table during deployment

=over 4

=item * index_1



=back

=cut

sub sqlt_deploy_hook {
    my ($self, $table) = @_;

    $table->add_index(
        type   => "normal",
        name   => "index_1",
        fields => ['hallo'],
    );


    return 1;
}
~;
    my $got = $foo->$sub( $index );
    is_string $got, $expected;
}

{
    $index->type('unique');

    my $got = $foo->$sub( $index );
    like_string $got, qr/add_unique_constraint/;
}

{
    $index->type('index');

    my $got = $foo->$sub( $index );
    like_string $got, qr/add_index/;
    like_string $got, qr/"normal"/;
    like_string $got, qr/"index_1"/;
}

done_testing;
