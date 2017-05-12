#!/usr/bin/env perl
use 5.014;
use warnings;
use utf8;
use autodie;
use Furl;
use YAML;
use Data::Dumper::Concise;

my $url = 'https://raw.github.com/ziguzagu/typecast/master/conf/emoticon.yaml';
my $res = Furl->new->get($url);
my $hash = YAML::Load($res->content);
my $docomo_map = $hash->{docomo};

my $map = Dumper $docomo_map;
my $tmpl = do {local $/; <DATA>};
my $content = eval qq{my \$map = qq{$map}; "$tmpl"};

my $file = 'lib/Plack/Middleware/UnicodePictogramFallback/TypeCast/EmoticonMap.pm';
open my $fh, '>', $file;
print $fh $content;

__DATA__
package Plack::Middleware::UnicodePictogramFallback::TypeCast::EmoticonMap;
use strict;
use warnings;

# This file was generated automatically.
use constant MAP => $map;

1;
