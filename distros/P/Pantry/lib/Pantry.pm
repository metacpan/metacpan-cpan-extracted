use v5.14;
use warnings;

package Pantry;
# ABSTRACT: Configuration management tool for chef-solo
our $VERSION = '0.012'; # VERSION

# This file is a namespace placeholder and gives a default place to find
# documentation for the 'pantry' program.

# Pod for this file is generated from the pod/ directory in the source
# repository using the 'AppendExternalData' dzil plugin

1;

# vim: ts=2 sts=2 sw=2 et:

__END__

=pod

=head1 NAME

Pantry - Configuration management tool for chef-solo

=head1 VERSION

version 0.012

=head1 SYNOPSIS

  $ mkdir my-project
  $ cd my-project
  $ pantry init
  $ pantry create node foo.example.com
  $ pantry list nodes
  $ pantry apply node foo.example.com --recipe nginx
  $ pantry apply node foo.example.com --default nginx.port=80
  $ pantry sync node foo.example.com

=head1 DESCRIPTION

C<pantry> is a utility to make it easier to manage a collection of
computers with the configuration management tool
Chef Solo L<http://wiki.opscode.com/display/chef/Chef+Solo>

=head1 USAGE

Arguments to the C<pantry> command line tool follow a regular structure:

  $ pantry VERB [[NOUN] [ARGUMENTS...]]

See the following sections for details and examples by topic.

=head2 Pantry setup and introspection

=head3 init

  $ pantry init

This initializes a pantry in the current directory.  Currently, it just
creates some directories for use storing cookbooks, node data, data bags, etc.

=head3 list

  $ pantry list nodes
  $ pantry list roles
  $ pantry list environments
  $ pantry list cookbooks
  $ pantry list bags

Prints to STDOUT a list of items of a particular type managed within the
pantry.

=head2 Managing nodes

In this section, when a node NAME is required, the name is
expected to be a valid DNS name or IP address.  The name
will be converted to lowercase for consistency.  When referring
to an existing node, you may often abbreviate it to a unique
prefix, e.g. "foo" for "foo.example.com".

Also, whenever a command takes a single 'node NAME' target,
you may give a single dash ('-') as the NAME and the command
will be run against a list of nodes read from STDIN.

You can combine this with the C<pantry list> command to do
batch operations.  For example, to sync all nodes:

  $ pantry list nodes | pantry sync node -

Pantry supports grouping nodes into arbitrarily named environments,
such as "test", "staging" or "production".  The node commands "create"
and "list" can be given an environment selector with the C<--env
ENV_NAME> or C<-E ENV_NAME> options and all operations will be happen
in the context of that environment.

This works with "list" and input from STDIN for a handy way to sync
all nodes in an environment:

  $ pantry list nodes -E staging | pantry sync node -

See L</"Managing Environments> for more.

=head3 create

  $ pantry create node NAME

Creates a node configuration file for the given C<NAME>.

=head3 rename

  $ pantry rename node NAME DESTINATION

Renames a node to a new name.  The old node data file
is renamed.  The C<NAME> must exist.

=head3 delete

  $ pantry delete node NAME

Deletes a node. The C<NAME> must exist. Unless the C<--force>
or C<-f> options are given, the user will be prompted to confirm
deletion.

=head3 show

  $ pantry show node NAME

Prints to STDOUT the JSON data for the given C<NAME>.

=head3 apply

  $ pantry apply node NAME --recipe nginx --role mail --default nginx.port=80

Applies recipes, roles or attributes to the given C<NAME>.

To apply a role to the node's C<run_list>, specify C<--role role> or C<-R role>.
May be specified multiple times to apply more than one role.  Roles will
be appended to the C<run_list> before after any existing entries but before
any recipes specified in the same command.

To apply a recipe to the node's C<run_list>, specify C<--recipe RECIPE> or C<-r
RECIPE>.  May be specified multiple times to apply more than one recipe.

To apply an attribute to the node, specify C<--default KEY=VALUE> or C<-d
KEY=VALUE>.  If the C<KEY> has components separated by periods (C<.>), they will
be interpreted as subkeys of a multi-level hash.  For example:

  $ pantry apply node NAME -d nginx.port=80

will be added to the node's data structure like this:

  {
    ... # other node data
    nginx => {
      port => 80
    }
  }

If the C<VALUE> contains commas, the value will be split and serialized as
an array data structure.  For example:

  $ pantry apply node NAME -d nginx.port=80,8080

will be added to the node's data structure like this:

  {
    ... # other node data
    nginx => {
      port => [80, 8080]
    }
  }

Both C<KEY> and C<VALUE> support periods and commas (respectively) to be
escaped by a backslash.

If a C<VALUE> is a literal string containing 'true' or 'false', it will be
replaced in the configuration data with actual JSON boolean values.

N.B. While the term C<--default> is used for command line consistency, attributes
set on nodes actually have what Chef terms "normal" precedence.

=head3 strip

  $ pantry strip node NAME --recipe nginx --role mail --default nginx.port

Strips recipes, roles or attributes from the given C<NAME>.

To strip a role to the node's C<run_list>, specify C<--role role> or C<-R role>.
May be specified multiple times to strip more than one role.

To strip a recipe to the node's C<run_list>, specify C<--recipe RECIPE> or C<-r
RECIPE>.  May be specified multiple times to strip more than one recipe.

To strip an attribute from the node, specify C<--default KEY> or C<-d KEY>.
The C<KEY> parameter is interpreted and may be escaped just like in C<apply>,
above.

=head3 sync

  $ pantry sync node NAME

Copies cookbooks and configuration data to the C<NAME> node and invokes
C<chef-solo> via C<ssh> to start a configuration run.  After configuration,
the latest run-report for the node is updated in the 'reports' directory
of the pantry.

If the C<--reboot> option is given, each node will be rebooted after
the synchronization run.  This will only work on Unix hosts that
can use the C<shutdown> command.

=head3 edit

  $ pantry edit node NAME

Invokes the editor given by the environment variable C<EDITOR> on
the configuration file for the C<name> node.

The resulting file must be valid JSON in a form acceptable to Chef.  Generally,
you should use the C<apply> or C<strip> commands instead of editing the node
file directly.

=head2 Managing roles

In this section, when a role NAME is required, any name without whitespace is
acceptable. The name will be converted to lowercase for consistency.  When
referring to an existing role, you may often abbreviate it to a unique prefix,
e.g. "web" for "webserver".

Also, whenever a command takes a single 'role NAME' target,
you may give a single dash ('-') as the NAME and the command
will be run against a list of roles read from STDIN.

You can combine this with the C<pantry list> command to do
batch operations.  For example, to add a recipe to all roles:

  $ pantry list roles | pantry apply role - --recipe ntp

=head3 create, rename, delete, show and edit

These commands work the same as they do for nodes.
The difference is that you must specify the 'role' type:

  $ pantry create role web
  $ pantry show role web

=head3 apply and strip

The C<apply> and C<strip> commands have slight differences, as roles have two
kinds of attributes, "default attributes" (C<--default> or C<-d>) and "override
attributes" (C<--override>), with slightly different precedence.

  $ pantry apply role NAME -d nginx.user=nobody --override nginx.port=80
  $ pantry strip role NAME -d nginx.user --override nginx.port

The C<--recipe> (C<-r>) and C<--role> (C<-R>) arguments work the same as for nodes.
Note that roles can have other roles in their C<run_list>.

When Chef merges attribute, the role default attribute has the lower precedence
than node attributes.  Override attributes have higher precedence than node
attributes. Yes, this is a gross simplification of how Chef does it.  See Chef
docs for more: L<http://wiki.opscode.com/display/chef/Attributes>

Roles have two kinds of run lists: default and environment-specific.
The default run list applies whenever there is no environment-specific
run list for the active environment for a node.  You can apply/strip
environment-specific run list entries with the C<-E ENV_NAME> option,
or omit it to apply/strip from the default list.

  $ pantry apply role web -r nginx
  $ pantry apply role web -r ufw -E production

=head2 Managing data bags

In this section, when a bag NAME is required, any name without whitespace is
acceptable. The name will be converted to lowercase for consistency.  When
referring to an existing bag, you may often abbreviate it to a unique prefix,
e.g. "users/d" for "users/dagolden".

Note that data bags may exist at the "top" level or within subdirectories and
so either of these forms are acceptable as bag names:

=over 4

=item *

top_level_bag

=item *

bag_name/item_name

=back

Also, whenever a command takes a single 'bag NAME' target,
you may give a single dash ('-') as the NAME and the command
will be run against a list of bags read from STDIN.

You can combine this with the C<pantry list> command to do
batch operations.

  $ pantry list bags | grep users | pantry apply bag - -d remove=true

=head3 create, rename, delete, show and edit

These commands work the same as they do for nodes.
The difference is that you must specify the 'bag' type:

  $ pantry create bag users/dagolden
  $ pantry show bag users/dagolden

=head3 apply and strip

The C<apply> and C<strip> commands have slight differences, as bags don't have
attributes in the way that nodes or roles do.  The "default" flags are used
and just set fields in the top level of the bag.  (Don't set "id" or bad things
might happen.)

  $ pantry apply bag NAME -d key=value
  $ pantry strip bag NAME -d key

=head2 Managing environments

In this section, when a environment NAME is required, any name without
whitespace is acceptable. The name will be converted to lowercase for
consistency.  When referring to an existing role, you may often abbreviate it
to a unique prefix, e.g. "prod" for "production".

Also, whenever a command takes a single 'environment NAME' target,
you may give a single dash ('-') as the NAME and the command
will be run against a list of roles read from STDIN.

You can combine this with the C<pantry list> command to do
batch operations.  For example, to add a default to all environments:

  $ pantry list environments | pantry apply environment - -d nginx.port=8080

Environments are different than nodes and roles because there are
really three ways to work with an environment.  When you create an
environment, an environment data file is created to hold attributes.
When you create a node, it gets assigned to an environment (the
"_default" environment is used if you don't specify one).  However,
you can create a node in an environment even if you don't create the
environment data file first.  Finally, roles can have
environment-specific run lists.

Here's a summary of those distinctions:

=for *list: * all nodes are assigned to environments
* roles can hold environment-specific run lists
* environment data files hold environment-specific attributes

When you want to affect environment data files, you'll use
C<pantry VERB environment ...> commands, like this:

  $ pantry show environment staging

When you want to set an environment for node and role actions, you'll
use the C<--env> or C<-E> selector option

  $ pantry create node foo.example.com -E test
  $ pantry apply role web -r ufw -E production

=head3 create, rename, delete, show and edit

These commands work the same as they do for nodes and roles.
The difference is that you must specify the 'environment' type:

  $ pantry create environment staging
  $ pantry show environment staging

=head3 apply and strip

The C<apply> and C<strip> commands work like roles, except that environments
don't have run lists.

  $ pantry apply environment NAME -d nginx.user=nobody --override nginx.port=80
  $ pantry strip environment NAME -d nginx.user --override nginx.port

If you want to have different run lists in different environments, you have to
do that via roles, with environment-specific run lists:

  # turn on firewall in production
  $ pantry apply role web -r ufw -E production

An environment-specific run list I<replaces> the default run list if the role is
applied to a node in the specified environment.

Chef Solo does not yet have support for merging environment attributes
the way Chef Client does.  Therefore, during sync, Pantry will do its
own merge with node attributes to provide a reasonable emulation.  The
precedence is slightly different, but if you have overlapping
environment, role and node attributes and the order is really
important to you, you're probably over-complicating things.  See Chef
docs for more: L<http://wiki.opscode.com/display/chef/Attributes>

=head2 Managing cookbooks

Pantry does very little to manage cookbooks -- this is left up to you
and you are free to do whatever you like in the C<cookbooks>
directory.

As a convenience, however, Pantry may be used to create an empty
boilerplate cookbook for you to customize:

  $ pantry create cookbook my-cookbook

=head2 Getting help

=head3 commands

  $ pantry commands

This gives a list of all pantry commands with a short description of each.

=head3 help

  $ pantry help COMMAND

This gives some detailed help for a command, including the options and
arguments that may be used.

=head1 AUTHENTICATION

C<pantry> relies on OpenSSH for secure communications with managed nodes,
but does not manage keys itself.  Instead, it expects the user to manage
keys using standard OpenSSH configuration and tools.

The user should specify SSH private keys to use in the ssh config file.  One
approach would be to use the C<IdentityFile> with a host-name wildcard:

  IdentityFile ~/.ssh/identities/id_dsa_%h

This would allow a directory of host-specific identities (which could all be
symlinks to a master key).  Another alternative might be to create a master key
for each environment:

  IdentityFile ~/.ssh/id_dsa_dev
  IdentityFile ~/.ssh/id_dsa_test
  IdentityFile ~/.ssh/id_dsa_prod

C<pantry> also assumes that the user will unlock keys using C<ssh-agent>.
For example, assuming that ssh-agent has not already been invoked by a
graphical shell session, it can be started with a subshell of a terminal:

  $ ssh-agent $SHELL

Then private keys can be unlocked in advance of running C<pantry> using
C<ssh-add>:

  $ ssh-add ~/.ssh/id_dsa_test
  $ pantry ...

See the documentation for C<ssh-add> for control over how long keys
stay unlocked.

=head1 ROADMAP

In the future, I hope to extend pantry to support some or all of the following:

=over 4

=item *

tagging nodes

=item *

searching nodes based on configuration

=item *

encrypted data bags (or equivalent functionality)

=item *

cookbook download from Opscode community repository

=item *

bootstrapping Chef over ssh

=back

If you are interested in contributing features or bug fixes, please let me
know!

=head1 SEE ALSO

Inspiration for this tool came from similar chef-solo management tools.
In addition to being implemented in different languages, each approaches
the problem in slightly different ways, neither of which fit my priorities.
Nevertheless, if you use chef-solo, you might consider them as well:

=over 4

=item *

littlechef L<http://github.com/tobami/littlechef> (Python)

=item *

pocketknife L<http://github.com/igal/pocketknife> (Ruby)

=item *

knife-solo L<https://github.com/matschaffer/knife-solo> (Ruby)

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/pantry/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/pantry>

  git clone git://github.com/dagolden/pantry.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
