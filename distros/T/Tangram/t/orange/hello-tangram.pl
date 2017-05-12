#!/usr/bin/perl
#
# the missing bare bones example, from Sebastian Riedel.
#

use DBI;
use Tangram;
use Class::Tangram::Generator;

my $schema = Tangram::Schema->new(
    {
        classes => [
            Orange => {
                fields  => { int => [qw(juicyness ripeness)] },
                methods => {
                    squeeze => sub {
                        my $self = shift;
                        $self->juicyness( $self->juicyness() - 1 );
                    },
                    eviscerate => sub {
                        my $self = shift;
                        $self->juicyness(0);
                    },
                }
            }
        ]
    }
);

if ( $ARGV[0] ) {
    my $dbh = DBI->connect('dbi:SQLite:test.db');
    Tangram::Relational->deploy( $schema, $dbh );
}

my $gen     = Class::Tangram::Generator->new($schema);
my $storage = Tangram::Relational->connect( $schema, 'dbi:SQLite:test.db' );

my $orange = $gen->new('Orange');
$orange->juicyness(20);
$storage->insert($orange);
