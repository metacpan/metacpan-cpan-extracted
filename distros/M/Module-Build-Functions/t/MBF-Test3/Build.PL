use strict;
$^W = 1; # Can't use "use warnings", see perl_version below.
use inc::Module::Build::Functions;

dist_name           'MBF-Test3';
dist_version        0.001_001;
author              'Curtis Jewell <csjewell@cpan.org>';
abstract_from       'lib/MBF/Test3.pm';
perl_version        5.008001;
meta_add            'meta-test1' => 'test1';
meta_add            'meta-test1' => 'meta-test1';
repository          'http://svn.ali.as/cpan/trunk/Module-Build-Functions/';
bugtracker          'http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Module-Build-Functions';
meta_merge          'resources', 'MailingList' => 'mailto:module-build@perl.org';
add_to_cleanup      'MBF-Test3-*';

create_build_script;