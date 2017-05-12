use strict;
use warnings;
use Module::Build;

use lib qw(lib);

my $build = Module::Build->new(
    module_name => 'Net::Amazon::TreeHash',
    author => 'Victor Efimov',
    dist_author => 'Victor Efimov',
    
        
    recursive_test_files=>1,
    dist_abstract=>'Amazon Glacier TreeHash algorithm',
    license     => 'Software::License::GPL_3',
    requires => {
        'Digest::SHA'        => 0,
    }
);

$build->create_build_script();
