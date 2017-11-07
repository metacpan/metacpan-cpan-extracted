#!perl

use strict;
use warnings;

use Test::More;

my $TESTED_PREREQS = {
 'B::Debug'                    => '0',
 'Browser::Open'               => '0',
 'Capture::Tiny'               => '0',
 'Class::XSAccessor'           => '0',
 'Digest::MD5'                 => '0',
 'HTML::Entities'              => '3.69',
 'HTML::Parser'                => '0',
 'JSON::MaybeXS'               => '1.003003',
 'Moo'                         => '0',
 'PPI::HTML'                   => '1.07',
 'Parallel::Iterator'          => '0',
 'Pod::Coverage'               => '0.06',
 'Pod::Coverage::CountParents' => '0',
 'Sereal::Decoder'             => '0',
 'Sereal::Encoder'             => '0',
 'Storable'                    => '0',
 'Template'                    => '2.00',
 'namespace::clean'            => '0',
};

plan tests => keys(%$TESTED_PREREQS) + 1;

my @tests = map [ $_ => $TESTED_PREREQS->{$_} ], keys %$TESTED_PREREQS;
push @tests, [ 'Devel::Cover' => '1.29' ];

for my $test (@tests) {
 my ($module, $version) = @$test;
 local $@;
 if ($version && $version !~ /^[0._]*$/) {
  eval "use $module $version ()";
  is $@, '', "$module v$version is available";
 } else {
  eval "use $module ()";
  is $@, '', "any version of $module is available";
 }
}
