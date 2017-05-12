use strict;
use warnings;
use Test::Base;
use Sledge::Config::YAML;
BEGIN {
    eval q[use Sledge::Config;];
    plan skip_all => "Sledge::Config required for testing base" if $@;
};


plan tests => 1*blocks;

filters {
    input    => [qw/conf/],
    expected => [qw/yaml/],
};

# for __ENV:*__
$ENV{HOME} = '/home/kan';
$ENV{USER} = 'kan';

sub conf {
    my $in = shift;
    +{%{Sledge::Config::YAML->new($in, 't/example.yaml')}};
}

run_is_deeply 'input' => 'expected';

__END__

===
--- input: develop_user
--- expected
favorite : precure

datasource:
  - dbi:mysql:proj
  - dev_user
  - dev_pass
session_servers:
  - 127.0.0.1:XXXXX
  - 127.0.0.2:XXXXX
cache_servers  :
  - 127.0.0.1:XXXXX
host: proj.kan.dev.example.com
info_addr: kan@example.com
tmpl_path: /home/kan/template/proj
validator_message_file: /home/kan/conf/message.yaml

org_param: foo
log: /home/kan/foo/kan.conf

===
--- input: develop_foo
--- expected
favorite : precure

datasource:
  - dbi:mysql:proj
  - dev_user
  - dev_pass
session_servers:
  - 127.0.0.1:XXXXX
  - 127.0.0.2:XXXXX
cache_servers  :
  - 127.0.0.1:XXXXX
host: proj.kan.dev.example.com
info_addr: kan@example.com
tmpl_path: /home/kan/template/proj
validator_message_file: /home/kan/conf/message.yaml

===
--- input: product
--- expected
favorite : precure

datasource:
  - dbi:mysql:proj
  - proj
  - pass_xxx
session_servers:
  - 111.111.111.1:12345
cache_servers  :
  - 222.222.222.2:12345
tmpl_path: /path/to/template/proj
host: proj.example.com
validator_message_file: /path/to/conf/message.yaml
info_addr: info@proj.example.com

