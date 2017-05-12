
use strict;
use warnings;

use FindBin;
use lib map $FindBin::Bin . '/' . $_, qw( . ../lib ../lib/perl5 );

use Test::More;
END { done_testing }

######################################################################

use_ok ('SQL::Admin::Utils');
use_ok ('SQL::Admin');

use_ok ('SQL::Admin::Driver::Base');
use_ok ('SQL::Admin::Driver::Base::DBI');
use_ok ('SQL::Admin::Driver::Base::Parser');
use_ok ('SQL::Admin::Driver::Base::Producer');
use_ok ('SQL::Admin::Driver::Base::Evaluate');
use_ok ('SQL::Admin::Driver::Base::Decompose');

use_ok ('SQL::Admin::Driver::DB2');
use_ok ('SQL::Admin::Driver::DB2::DBI');
use_ok ('SQL::Admin::Driver::DB2::Grammar');
use_ok ('SQL::Admin::Driver::DB2::Keywords');
use_ok ('SQL::Admin::Driver::DB2::Parser');
use_ok ('SQL::Admin::Driver::DB2::Producer');
use_ok ('SQL::Admin::Driver::DB2::Evaluate');
use_ok ('SQL::Admin::Driver::DB2::Decompose');

use_ok ('SQL::Admin::Driver::Pg');
use_ok ('SQL::Admin::Driver::Pg::DBI');
use_ok ('SQL::Admin::Driver::Pg::Grammar');
use_ok ('SQL::Admin::Driver::Pg::Keywords');
use_ok ('SQL::Admin::Driver::Pg::Parser');
use_ok ('SQL::Admin::Driver::Pg::Producer');
#use_ok ('SQL::Admin::Driver::Pg::Evaluate');
#use_ok ('SQL::Admin::Driver::Pg::Decompose');

#use_ok ('SQL::Admin::Catalog');
use_ok ('SQL::Admin::Catalog::Compare');
use_ok ('SQL::Admin::Catalog::Object');
use_ok ('SQL::Admin::Catalog::Index');
use_ok ('SQL::Admin::Catalog::Schema');
use_ok ('SQL::Admin::Catalog::Sequence');
use_ok ('SQL::Admin::Catalog::Table');
use_ok ('SQL::Admin::Catalog::Table::Object');
use_ok ('SQL::Admin::Catalog::Table::Constraint');
use_ok ('SQL::Admin::Catalog::Table::PrimaryKey');
use_ok ('SQL::Admin::Catalog::Table::Unique');
use_ok ('SQL::Admin::Catalog::Table::ForeignKey');
use_ok ('SQL::Admin::Catalog::Table::Column');


