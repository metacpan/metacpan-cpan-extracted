#!perl -T

use lib './t'; require 'testlib.pm';
use strict;
use warnings;
use Test::More tests => 92;
use File::Slurp::Tiny qw(read_file);
use FindBin '$Bin';
use YAML::Syck; $YAML::Syck::ImplicitTyping = 1;

my $meta = Load(scalar read_file("$Bin/data/META.yml"));

valid_2($meta, sub {}, "valid");

invalid_2($meta, sub { shift->{foo} = 1 }, "unknown key");

invalid_2($meta, sub { delete shift->{"meta-spec"} }, "missing meta-spec");
invalid_2($meta, sub { delete shift->{"meta-spec"}{version} }, "missing meta-spec/version");
invalid_2($meta, sub { shift->{"meta-spec"}{version} = 1.4 }, "meta-spec version not 2.0");

invalid_2($meta, sub { delete shift->{name} }, "missing name");
invalid_2($meta, sub { shift->{name} = 'Foo Bar' }, "invalid name");

invalid_2($meta, sub { delete shift->{dynamic_config} }, "missing dynamic_config");
invalid_2($meta, sub { shift->{dynamic_config} = [] }, "invalid dynamic_config");

invalid_2($meta, sub { delete shift->{release_status} }, "missing release_status");
invalid_2($meta, sub { shift->{release_status} = 'foo' }, "invalid release_status");
invalid_2($meta, sub { $_[0]->{release_status} = 'stable'; $_[0]->{version} = '0.36_01' }, "release_status must not be stable when version contains underscore");

invalid_2($meta, sub { delete shift->{version} }, "missing version");
invalid_2($meta, sub { shift->{version} = []         }, "invalid version 1");
invalid_2($meta, sub { shift->{version} = '1.'       }, "invalid version 2");
invalid_2($meta, sub { shift->{version} = '1.2.3'    }, "invalid version 3");
invalid_2($meta, sub { shift->{version} = '1. 2'     }, "invalid version 4");
invalid_2($meta, sub { shift->{version} = '1.2a'     }, "invalid version 5");
valid_2  ($meta, sub { shift->{version} = 'v1.2.3'   }, "valid version 1");
valid_2  ($meta, sub { shift->{version} = '1.2'      }, "valid version 2");
valid_2  ($meta, sub { $_[0]->{release_status} = 'testing'; $_[0]->{version} = '1.2_3'    }, "valid version 3");
valid_2  ($meta, sub { $_[0]->{release_status} = 'testing'; $_[0]->{version} = 'v1.2.3_3' }, "valid version 4");

invalid_2($meta, sub { delete shift->{abstract} }, "missing abstract");

invalid_2($meta, sub { delete shift->{author} }, "missing author");
invalid_2($meta, sub { shift->{author} = [] }, "no author");
#has_warning($meta, sub { shift->{author}[0] = 'foo bar' }, "author not in 'name <email>' form");

invalid_2($meta, sub { delete shift->{license} }, "missing license");
invalid_2($meta, sub { shift->{license} = 'perl_5' }, "invalid license, must be array");
invalid_2($meta, sub { shift->{license} = ['foo'] }, "invalid license");

invalid_2($meta, sub { delete shift->{generated_by} }, "missing generated_by");
invalid_2($meta, sub { shift->{generated_by} = [] }, "invalid generated_by: must be str");

# distribution_type is optional
invalid_2($meta, sub { shift->{distribution_type} = 'foo' }, "invalid distribution_type");
#XXX deprecated

# prereqs is optional
invalid_2($meta, sub { shift->{prereqs}{foo} = {requires=>{Foo=>0}} }, "invalid prereqs: unknown phase");
invalid_2($meta, sub { shift->{prereqs}{build} = {foo=>{Foo=>0}} }, "invalid prereqs: unknown relation");
invalid_2($meta, sub { shift->{prereqs}{develop} = {conflicts =>{"foo bar"=>0}} }, "invalid prereqs: invalid package");
invalid_2($meta, sub { shift->{prereqs}{runtime} = {suggests  =>{"foo bar"=>-1         }} }, "invalid prereqs: invalid version 1");
invalid_2($meta, sub { shift->{prereqs}{test}    = {recommends=>{"foo bar"=>undef      }} }, "invalid prereqs: invalid version 2");

valid_2  ($meta, sub { shift->{prereqs}{configure} = {requires   =>{Foo=>1.2             }} }, "prereqs: valid version 1");
valid_2  ($meta, sub { shift->{prereqs}{build}     = {conflicts  =>{Foo=>"> 1.2"         }} }, "prereqs: valid version 2");
valid_2  ($meta, sub { shift->{prereqs}{test}      = {recommends =>{Foo=>">=1.2"         }} }, "prereqs: valid version 3");
valid_2  ($meta, sub { shift->{prereqs}{runtime}   = {suggests   =>{Foo=>"!=1.2_3,==1"   }} }, "prereqs: valid version 4");
valid_2  ($meta, sub { shift->{prereqs}{develop}   = {requires   =>{Foo=>"<1.2, <=v2.3.4"}} }, "prereqs: valid version 5");

# requires is optional
invalid_2($meta, sub { shift->{requires}{'foo bar'} = 0 }, "invalid requires");
#XXX deprecated

# build_requires is optional
invalid_2($meta, sub { shift->{build_requires}{'foo bar'} = 0 }, "invalid build_requires");
#XXX deprecated

# configure_requires is optional
invalid_2($meta, sub { shift->{configure_requires}{'foo bar'} = 0 }, "invalid configure_requires");
#XXX deprecated

# recommends is optional
invalid_2($meta, sub { shift->{recommends}{'foo bar'} = 0 }, "invalid recommends");
#XXX deprecated

# conflicts is optional
invalid_2($meta, sub { shift->{conflicts}{'foo bar'} = 0 }, "invalid conflicts");
#XXX deprecated

# optional_features is optional
invalid_2($meta, sub { shift->{optional_features} = 1 }, "invalid optional_features 1");
invalid_2($meta, sub { shift->{optional_features}{foo} = 1 }, "invalid optional_features 2");
invalid_2($meta, sub { shift->{optional_features}{foo}{'configure_requires'}{'foo::bar'} = 0 }, "invalid optional_features 3");
valid_2  ($meta, sub { shift->{optional_features}{foo}{'requires'}{'foo::bar'} = 0 }, "valid optional_features 1");
valid_2  ($meta, sub { shift->{optional_features}{foo}{prereqs} = {build=>{}, test=>{}, runtime=>{}, develop=>{}} }, "valid phases in prereqs in optional_features");
invalid_2($meta, sub { shift->{optional_features}{foo}{prereqs} = {configure=>{}} }, "prereqs in optional_features must not have configure phase");
#XXX deprecated

# XXX private deprecated

# provides is optional
invalid_2($meta, sub { shift->{provides} = 1 }, "invalid provides 1");
invalid_2($meta, sub { shift->{provides} = {foo => 1} }, "invalid provides 2");
invalid_2($meta, sub { shift->{provides} = {foo => {bar => 1}} }, "invalid provides 3");
invalid_2($meta, sub { shift->{provides} = {foo => {version=>1.0}} }, "invalid provides 3: missing file");
invalid_2($meta, sub { shift->{provides} = {foo => {file=>'/foo/bar'}} }, "invalid provides 4: missing version");
valid_2  ($meta, sub { shift->{provides} = {foo => {file=>'/foo/bar', version=>1.0}} }, "valid provides 1");

# no_index is optional
invalid_2($meta, sub { shift->{no_index} = 1 }, "invalid no_index 1");
invalid_2($meta, sub { shift->{no_index} = {foo => 1} }, "invalid no_index 2");
invalid_2($meta, sub { shift->{no_index} = {file => 1} }, "invalid no_index 3");
valid_2  ($meta, sub { shift->{no_index} = {file => [1, 2]} }, "valid no_index 1");
invalid_2($meta, sub { shift->{no_index} = {package => ['foo bar']} }, "invalid no_index 4: invalid package");
valid_2  ($meta, sub { shift->{no_index} = {package => ['foo::bar']} }, "valid no_index 2");

# keywords is optional
invalid_2($meta, sub { shift->{keywords} = 'foo' }, "invalid keywords: must be array");
invalid_2($meta, sub { shift->{keywords} = ['foo bar'] }, "invalid keywords: must not contain whitespace");
valid_2  ($meta, sub { shift->{keywords} = ['foo'] }, "valid keywords");

# resources is optional
invalid_2($meta, sub { shift->{resources} = 'foo' }, "invalid resources: must be hash");
valid_2  ($meta, sub { shift->{resources} = {homepage=>1, license=>1, bugtracker=>1, repository=>1} }, "valid keys in resources");
invalid_2($meta, sub { shift->{resources} = {foo=>1} }, "invalid keys in resources");

valid_2  ($meta, sub { shift->{X_Foo} = 1   }, "valid custom field 1");
valid_2  ($meta, sub { shift->{x_foo} = 1   }, "valid custom field 2");
invalid_2($meta, sub { shift->{"x-foo"} = 1 }, "invalid custom field");

# see deprecated warnings, should've tested this. in DS 0.13 forbidden:warn doesn't work yet
#use vars qw($ds_2);
#use Data::Dump qw(pp);
#my $metac = dclone($meta);
#$metac->{build_requires} = {Foo=>0};
#pp $ds_2->validate($metac);
