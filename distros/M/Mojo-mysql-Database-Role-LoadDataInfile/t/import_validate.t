use Mojo::Base -strict;
use Test::More;
use Test::Exception;
use Mojo::mysql;
use Mojo::Util 'dumper';
require Mojo::mysql::Database::Role::LoadDataInfile;

lives_ok
    { Mojo::mysql::Database::Role::LoadDataInfile->import() }
    'import with no arguments lives';

throws_ok
    { Mojo::mysql::Database::Role::LoadDataInfile->import('-no_apply', database_class => 'MyApp::DB') }
    qr/no other options may be provided with -no_apply/,
    q{can't call import with addition options when using -no_apply};
throws_ok
    { Mojo::mysql::Database::Role::LoadDataInfile->import(database_class => 'MyApp::DB', '-no_apply') }
    qr/no other options may be provided with -no_apply/,
    q{can't call import with addition options when using -no_apply};

my $unknown_options = { unknown_key => 'unknown_val' };
my $unknown_dump = dumper $unknown_options;
throws_ok
    { Mojo::mysql::Database::Role::LoadDataInfile->import(database_class => 'MyApp::DB', %$unknown_options) }
    qr/unknown options provided to import: \Q$unknown_dump\E/,
    'unknown options with database_class throw';

throws_ok
    { Mojo::mysql::Database::Role::LoadDataInfile->import(%$unknown_options) }
    qr/unknown options provided to import: \Q$unknown_dump\E/,
    'unknown options alone throw';

lives_ok
    { Mojo::mysql::Database::Role::LoadDataInfile->import(database_class => 'MyApp::DB') }
    'database_class option lives';

done_testing;
