
use inc::Module::Install;

# Define metadata
name          'Rex-WebUI';

author        'Mike Tonks <miket@cpan.org>';
version_from  'lib/Rex/WebUI.pm';
license       'perl', 'gpl';
 
# Specific dependencies
requires 'Mojolicious' => 3.11;
requires 'Rex' => 0.39;

requires 'Mojolicious::Plugin::Database';

requires 'Data::Dumper';
requires 'DBD::SQLite';
requires 'DBIx::Foo';
requires 'File::Basename';
requires 'Try::Tiny';

# Modules required for testing
test_requires 'Test::More' => 0;

install_script 'bin/rex-webui';

#manifest_skip;

#no_index directory => 'sample';

WriteAll;
