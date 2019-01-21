#!/usr/bin/env perl

use strict;
use warnings;

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

my $sub = $foo->can('_class_template');

{
    my $expected = q~package Schema::Result::TestTable;

# ABSTRACT: Result class for TestTable

use strict;
use warnings;
use base qw(DBIx::Class);

our $VERSION = 0.01;

__PACKAGE__->load_components( qw/PK::Auto Core/ );
__PACKAGE__->table( 'TestTable' );
__PACKAGE__->add_columns(
qw/
    hallo
        /
);
__PACKAGE__->set_primary_key( qw/ hallo / );






# ---
# Put your own code below this comment
# ---

# ---

1;~;
    my $got      = $foo->$sub( $table, undef, '' );
    is_string $got, $expected;
}

{
    $table->comment('[]');
    my $expected = q~package Schema::Result::TestTable;

# ABSTRACT: Result class for TestTable

=head1 DESCRIPTION

[]

=cut

use strict;
use warnings;
use base qw(DBIx::Class);

our $VERSION = 0.01;

__PACKAGE__->load_components( qw/PK::Auto Core/ );
__PACKAGE__->table( 'TestTable' );
__PACKAGE__->add_columns(
qw/
    hallo
        /
);
__PACKAGE__->set_primary_key( qw/ hallo / );






# ---
# Put your own code below this comment
# ---

# ---

1;~;
    my $got      = $foo->$sub( $table, undef, '' );
    is_string $got, $expected;
}

{
    $table->comment('');
    my $expected = q~package Schema::Result::TestTable;

# ABSTRACT: Result class for TestTable

use strict;
use warnings;
use base qw(DBIx::Class);

our $VERSION = 0.01;

__PACKAGE__->load_components( qw/PK::Auto Core/ );
__PACKAGE__->table( 'TestTable' );
__PACKAGE__->add_columns(
qw/
    hallo
        /
);
__PACKAGE__->set_primary_key( qw/ hallo / );






# ---
# Put your own code below this comment
# ---

# ---

1;~;
    my $got      = $foo->$sub( $table, undef, '' );
    is_string $got, $expected;
}

done_testing;
