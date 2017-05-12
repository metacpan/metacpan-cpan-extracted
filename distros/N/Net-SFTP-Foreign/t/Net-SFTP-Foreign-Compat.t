
use Test::More tests => 3;

BEGIN { use_ok('Net::SFTP::Foreign::Compat', ':supplant') };
BEGIN { use_ok('Net::SFTP') };


ok (UNIVERSAL::isa('Net::SFTP', 'Net::SFTP::Foreign::Compat'), "inheritance is wrong");