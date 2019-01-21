package
    t::MySQL::Workbench::DBIC::Table;

use Moo;

has comment     => (is => 'rw', default => sub { '' } );
has name        => (is => 'ro', required => 1 );
has columns     => (is => 'ro', default => \&_gen_cols );
has indexes     => (is => 'ro', default => sub {[]} );
has primary_key => (is => 'ro', default => sub { [$_[0]->columns->[0]->name] } );

sub _gen_cols {
    return [ map{ t::MySQL::Workbench::DBIC::Column->new( name => $_ ) }qw(hallo) ];
}

package
    t::MySQL::Workbench::DBIC::Column;

use Moo;

has comment       => (is => 'rw', default => sub { '' } );
has name          => (is => 'ro' );
has default_value => (is => 'rw', default => sub { 0 } );
has length        => (is => 'rw', default => sub { 34 } );
has datatype      => (is => 'rw', default => sub { 'VARCHAR' } );
has autoincrement => (is => 'ro', default => sub { 0 } );
has not_null      => (is => 'ro', default => sub { 1 } );
has flags         => (is => 'ro', default => sub { {} } );

package
    t::MySQL::Workbench::DBIC::Index;

use Moo;

has name    => (is => 'ro' );
has type    => (is => 'rw' );
has columns => (is => 'ro', default => sub { ['hallo'] } );

1;
