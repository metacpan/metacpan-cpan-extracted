# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use 5.008003;
use strict;
use warnings;
use Module::Build;

shift(@ARGV) if defined $ARGV[0] and $ARGV[0] eq 'Build'; # accomodate with CPAN autoinstall

my $builder = Module::Build->new(
    (sign		=> 1),
    module_name         => 'Net::Upwork::API',
    license             => 'apache',
    dist_author         => 'Maksym Novozhylov <mnovozhilov@upwork.com>',
    dist_version	=> '2.3.0',
    dist_abstract       => 'Perl bindings for Upwork API (OAuth2)',
    build_requires => {
        'Test::More' => '0.66',
        'Test::Warn' => '0.21',
    },
    requires => {
	'perl' => '5.8.8',
	'IO::Socket::SSL' => '1.965',
        'Net::OAuth2' => '0.67',
    },    
    meta_merge => { keywords => [qw( upwork oauth2 )], },
    meta_add   => {
        resources => {
            homepage   => 'http://developers.upwork.com',
            repository => 'https://github.com/upwork/perl-upwork-oauth2.git',
            bugtracker => 'https://github.com/upwork/perl-upwork-oauth2/issues',
        },
    },
    add_to_cleanup      => [ 'Net-Upwork-API-*' ],
    create_makefile_pl => 'passthrough',
);

$builder->create_build_script();

__END__
# handy lister of installed dependency versions
use Data::Dumper;
my $requires = $builder->build_requires;
for my $mod (keys %$requires) {
    eval "require $mod";
    $requires->{$mod} = eval "\$$mod\::VERSION";
}
print "Current dependency versions:\n";
print Dumper $requires;
