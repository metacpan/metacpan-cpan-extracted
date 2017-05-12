package app::multi;
use strict;
use warnings;
use OptArgs;

$OptArgs::COLOUR = 1;

arg command => (
    isa      => 'SubCmd',
    required => 1,
    comment  => '(required) valid values include:',
);

opt help => (
    isa     => 'Bool',
    alias   => 'h',
    ishelp  => 1,
    comment => 'print a help message and exit',
);

opt dry_run => (
    isa     => 'Bool',
    alias   => 'n',
    comment => 'do nothing',
);

opt verbose => (
    isa     => 'Bool',
    alias   => 'v',
    comment => 'do it loudly',
);

subcmd(
    cmd     => 'init',
    comment => 'do the y thing',
);

opt opty => (
    isa     => 'Bool',
    comment => 'do nothing',
);

subcmd(
    cmd     => 'new',
    comment => 'do the z thing',
);

arg thread => (
    isa      => 'SubCmd',
    required => 1,
    comment  => '',
);

subcmd(
    cmd     => [qw/new project/],
    comment => 'do the new project thing',
);

opt popt => (
    isa     => 'Bool',
    comment => 'do nothing',
);

subcmd(
    cmd     => [qw/new issue/],
    comment => 'create a new issue',
    hidden  => 1,
);

opt iopt => (
    isa     => 'Bool',
    comment => 'do nothing',
);

subcmd(
    cmd     => [qw/new task/],
    comment => 'create a new task thread',
);

opt topt => (
    isa     => 'Bool',
    comment => 'do nothing',
);

arg targ => (
    isa      => 'SubCmd',
    required => 1,
    comment  => '',
);

subcmd(
    cmd     => [qw/new task pretty/],
    comment => 'create a new task prettier than before',
);

opt optz => (
    isa     => 'Bool',
    comment => 'do nothing',
);

subcmd(
    cmd     => [qw/new task noopts/],
    comment => 'create a new task with no opts or args',
);

1;
