use strict;
use warnings;

use Test::More tests => 21;

use_ok 'Rex::Apache::Build';
use_ok 'Rex::Apache::Deploy';
use_ok 'Rex::Apache::Inject';

use_ok 'Rex::Apache::Build::Base';
use_ok 'Rex::Apache::Build::deb';
use_ok 'Rex::Apache::Build::rpm';
use_ok 'Rex::Apache::Build::tgz';

use_ok 'Rex::Apache::Deploy::Package::Base';
use_ok 'Rex::Apache::Deploy::Package::deb';
use_ok 'Rex::Apache::Deploy::Package::rpm';
use_ok 'Rex::Apache::Deploy::Package::tgz';

require_ok 'Rex::Apache::Inject::Command';
require_ok 'Rex::Apache::Inject::Properties';
require_ok 'Rex::Apache::Inject::Template';
require_ok 'Rex::Apache::Inject::YAML';

require_ok 'Rex::Apache::Deploy::Git';
require_ok 'Rex::Apache::Deploy::JBoss';
require_ok 'Rex::Apache::Deploy::Package';
require_ok 'Rex::Apache::Deploy::Symlink';
require_ok 'Rex::Apache::Deploy::Tomcat';
require_ok 'Rex::Apache::Deploy::Tomcat7';


1;
