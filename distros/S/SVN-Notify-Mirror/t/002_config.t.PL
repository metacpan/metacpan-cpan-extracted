use Module::Build;
my $mb = Module::Build->current();
exit(0) unless $mb->feature('config_support');

use Cwd;
my ($testconfig, $maintest, $subtest) = (shift, shift, shift);
my $PWD = getcwd;

# setup the configuration file
open my $FILE, '>', $testconfig;
print {$FILE} <<"EOF";
#!/usr/bin/perl -MSVN::Notify::Config=\$0
--- #YAML:1.0
'':
  PATH: "/usr/local/bin:/usr/bin"
'/project1/branches/branch1':
  handler: Mirror
  to: "$PWD/t/wc-branch/"
EOF

if ( $mb->feature('ssh_support') and $mb->notes('sshtests') ) {
    print {$FILE} <<"EOF";
'/project1/trunk':
  handler: Mirror::SSH
  to: "$PWD/t/wc-trunk/"
  minimal: 1
  ssh-host: localhost
'/project1/tags':
  handler: Mirror::SSH
  to: "$PWD/t/wc-tag/"
  tag-regex: 'TRUNK'
  ssh-host: localhost
EOF
}
else {
    print {$FILE} <<"EOF";
'/project1/trunk':
  handler: Mirror
  minimal: 1
  to: "$PWD/t/wc-trunk/"
'/project1/tags':
  handler: Mirror
  to: "$PWD/t/wc-tag/"
  tag-regex: 'TRUNK'
EOF
}
close $FILE;

open my $FILE, '>', $subtest;
print {$FILE} <<"EOF";
#!/usr/bin/perl -w
# We have to go through this roundabout method because
# SVN::Notify::Config->import() won't run with -I on the
# command line and because it calls exit at the end
BEGIN {
    unshift \@INC, "blib/lib", "blib/arch";
}

my (\$repos_path, \$rev) = (shift, shift);

require SVN::Notify::Config;
push \@ARGV, \$repos_path, \$rev;
SVN::Notify::Config->import(
	"$testconfig"
);
EOF

close $FILE;

open my $FILE, '>', $maintest;
print {$FILE} <<"EOF";
require "t/coretests.pm";

reset_all_tests();
run_tests("perl $subtest");
EOF

close $FILE;
