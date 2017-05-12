#!perl -w
use strict;
use Test::More tests => 11;
use lib qw(t/lib);
use Siesta::Test;
use Siesta::List;

# create a new, virgin list
my $list = Siesta::List->create({
    name  => 'pluginorder',
    owner => Siesta::Member->create({ email => 'foo' }),
});


my @names = qw(ReplyTo);

# the list of plugins should be empty
is( $list->plugins, 0, "empty list" );

ok( $list->set_plugins( post => @names ), "set" );
is_deeply( [ map { $_->name } $list->plugins ], \@names,
           "plugins are set correctly" );

# add one at the end
ok( $list->add_plugin( post => 'Send' ) );
my @plugins = $list->plugins;

is_deeply( [ map { $_->name } $list->plugins ],
           [ @names, 'Send' ],
           "Add on the end" );

# add at the start
ok( $list->add_plugin( post => 'MembersOnly', 1 ) );
is_deeply( [ map { $_->name } $list->plugins ],
           [ 'MembersOnly', @names, 'Send' ],
           "Add on the start" );

# now delete them all
ok( $list->set_plugins( 'post' ) );

# the list of plugins should be empty
is( $list->plugins, 0, "empty list again" );


# check that ids remain stable when reordering things
$list->set_plugins( post => qw( Archive ReplyTo Send ) );
my %ids = map { $_->name => $_->id } $list->plugins;

$list->set_plugins( post => qw( ReplyTo Archive Send ) );
my %ids2 = map { $_->name => $_->id } $list->plugins;

is_deeply( \%ids2, \%ids, "reordering not recreating" );


# check that ids remain stable when switching things between list and personal
$list->set_plugins( post => qw( Archive ReplyTo Send ) );
%ids = map { $_->name => $_->id } $list->plugins;

$list->set_plugins( post => qw( +ReplyTo Archive Send ) );
%ids2 = map { $_->name => $_->id } $list->plugins;

is_deeply( \%ids2, \%ids, "reordering not recreating, personal" );
