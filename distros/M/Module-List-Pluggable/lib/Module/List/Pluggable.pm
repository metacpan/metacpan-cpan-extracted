package Module::List::Pluggable;

=head1 NAME

Module::List::Pluggable - list or require sub-sets of modules

=head1 SYNOPSIS

  use Module::List::Pluggable qw( list_modules_under import_modules );

  # get a list of all modules installed under a given point
  # in perl's module namespace
  my @plugins = list_modules_under( "My::Project::Plugins" );

  # require & import all modules in the tree
  import_modules( "My::Project::Plugins::ViaExporter" );

  # skip some of them
  import_modules( "My::Project::Plugins::ViaExporter",
                  { exceptions =>
                      'My::Project::Plugins::ViaExporter::ButNotThese' }
                );

  # just require them, don't do an "import"
  import_modules( "My::Project::Plugins::ViaExporter",
                  { import => 0 }
                 );

=head1 DESCRIPTION

This module provides some procedural routines to

(1) list a sub-set of modules installed in a particular place in
perl's module namespace,

(2) require those modules and import their exported features into
the current package.

Both of these functions are useful for implementing "plug-in"
extension mechanisms.

Note: this module is named Module::List::Pluggable because it
uses L<Module::List> to do some things similar to L<Module::Pluggable>.

=head2 EXPORT

None by default.  The following are exported on request
(":all" tag is available that brings in all of them):

=over

=cut

use 5.8.0;
use strict;
use warnings;
use Module::List qw(list_modules);
use Carp qw(carp croak);
use Data::Dumper;

require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(
  list_modules_under
  import_modules
  require_modules
  list_exports
  report_export_locations
  check_plugin_exports
) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw(
);

our $VERSION = '0.08';

=item list_modules_under

Uses the "list_modules" feature of Module::List to get
a list of all modules under the given root location
in perl's module namespace.

Example:
  my @plugins = list_modules_under( "My::Project::Plugins" );

Note that if no location is supplied, this will list all
installed modules: this can take some time.

=cut

sub list_modules_under {
  my $root = shift || '';
  my $opts  = shift;
  my $plugin_exceptions = $opts->{ exceptions };

  unless( defined($root) ){
    croak "list_modules_under: missing argument, need a module prefix";
  }
  # Module::List insists on a trailing "::" on the given prefix
  # let's make that optional (if it isn't there, append it, unless
  # the string is blank to start with)
  $root =~
    s/($root)/$1::/
      unless $root =~ m{(?: :: $)|(?: ^ \s* $ )}x;

  # using the Module::List routine
  my $modules = list_modules("$root",
                           { list_modules =>1, recurse => 1});

  # but list_modules returns an href, so let's make that a list
  my @found = keys %{ $modules };

  my @results = ();

  if ( $plugin_exceptions->[0] ) {
    my @pass;
    foreach my $module (@found) {
      foreach my $exception (@{ $plugin_exceptions }){
        push @pass, $module unless $module eq $exception;
      }
      @results = @pass;
    }
  } else {
    @results = @found;
  }
  return \@results;
}


=item import_modules

Does a "require" and then an "import" of all of the modules in
perl's module namespace at or under the given "root" location.

With Exporter based plugins, everything listed in @EXPORT
becomes available in the calling namespace.

Inputs:

=over

=item  location in module namespace (e.g. "My::Project::Plugins")

=item  options hash:

=over

=item  "exceptions"

list of exceptions, modules to be skipped (aref)

=item  "beware_conflicts"

if true, errors out if a conflict is discovered (i.e., the
same name imported twice from different plug-ins).  defaults
to 1, set to 0 if you don't want to worry about this
(perhaps for efficiency reasons?)

=back

=back

Returns: the number of successfully loaded modules.

=cut

sub import_modules {
  my $root                  = shift;
  my $opts                  = shift;
  my $exceptions            = $opts->{ exceptions };
  my $beware_conflicts      = $opts->{ beware_conflicts } || 1;

  if ( $root =~ m{ ^ \s* $  }x ) {
    croak "import_modules called without a plugin root location";
  }

  # check for multiple plugin exports with the same name
  # (also checks for syntax errors in plugin modules)
  check_plugin_exports( $root,
                        { exceptions => $exceptions,
                        } ) if ( $beware_conflicts );

  my $plugins
    = list_modules_under( $root,
                          { exceptions => $exceptions,
                          } );

  my ($eval_code, $error_prefix);
  my $count = 0;
  foreach my $plugin (@{ $plugins }) {
    $error_prefix = "import_modules: $plugin: ";

    my $calling_namespace = caller(0);
    $eval_code =
      "package $calling_namespace; " .
        "require $plugin; ".
          "import $plugin;" ;

    $error_prefix = "import_modules: $plugin: ";
    run_code_or_die( $eval_code, $error_prefix );
    $count++;             # count each successfully loaded module
  }
  return $count;
}


=item require_modules

Like "import_modules", this does a "require" (but no "import")
on all of the modules in perl's module namespace at or under
the given "root" location.

Inputs:

=over

=item  location in module namespace (e.g. "My::Project::Plugins")

=item  options hash:

=over

=item  "exceptions"

list of exceptions, modules to be skipped (aref)

=item  "beware_conflicts"

If true, errors out if a conflict is discovered (i.e., the
same name imported twice from different plug-ins).  Defaults
to 1.  Set this to 0 if you don't want it to worry about this
(perhaps for efficiency reasons?)

=back

=back

Returns: the number of successfully loaded plug-in modules.

=cut

sub require_modules {
  my $root = shift;
  my $opts        = shift;
  my $exceptions     = $opts->{ exceptions };
  my $beware_conflicts      = $opts->{ beware_conflicts } || 1;

  if ( $root =~ m{ ^ \s* $  }x ) {
    croak "require_modules called without a plugin root location";
  }

  # check for multiple plugin exports with the same name
  # (also checks for syntax errors in plugin modules)
  check_plugin_exports( $root,
                        { exceptions => $exceptions,
                        } ) if ( $beware_conflicts );

  my $plugins
    = list_modules_under( $root,
                          { exceptions => $exceptions,
                          } );

  my ($eval_code, $error_prefix);
  my $count = 0;
  foreach my $plugin (@{ $plugins }) {
    $error_prefix = "require_modules: $plugin: ";

    $eval_code =
      "require $plugin";

    run_code_or_die( $eval_code, $error_prefix );
    $count++; # count each successfully loaded module
  }
  return $count;
}

=back

=head2 reporting routines

=over

=item list_exports

Returns a list (aref) of all items that are exported from the
modules under the object's plugin root.

=cut

sub list_exports {
  my $root = shift;
  my $modules = list_modules_under( $root );

  my @list = ();
  foreach my $mod ( @{ $modules } ) {
    my $export_list = $mod . '::EXPORT';
    {
      no strict 'refs';
      push @list, @{ $export_list };
    }
  }
  return \@list;
}

=item report_export_locations

Reports on all routines that are exported by the modules
under the object's plug-in root, including the module
where each routine is found.

Inputs:

=over

=item The location to begin scanning in module name space,
e.g. "Mah::Modules::Plugins"

=item An options hash reference, with options:

=over

=item exceptions

And array reference of plug-in modules to be ignored.

=back

=back

Return:

A hash reference, keyed by the names of the exported routines
with values that are array references listing all modules
where that routine was found.

=cut

sub report_export_locations {
  my $root = shift;
  my $opts = shift;
  my $plugin_exceptions = $opts->{ exceptions };

  my $modules = list_modules_under( $root,
                                    { exceptions => $plugin_exceptions });

  my $report = {};
  foreach my $mod ( @{ $modules } ) {

    my $error_prefix = "report_export_locations: $mod: ";
    my $eval_code =
       "require $mod";

    run_code_or_die( $eval_code, $error_prefix );

    my $export_array = $mod . '::EXPORT';
    {
      no strict 'refs';
      my @exports = @{ $export_array };
      foreach my $ex (@exports) {
        push @{ $report->{ $ex } }, $mod;
      }
    }
  }
  return $report;
}

=back

=head2 routines primarily for internal use

=over

=item check_plugin_exports

Looks for conflicts in the tree of plug-ins under the given plug-in root.
Errors out if it finds multiple definitions of exported items
of the same names.

The form of the error message is:

  Multiple definitions of ___ from plugins: ___

Inputs:

=over

=item the location to begin scanning in module name space,
e.g. "Mah::Modules::Plugins"

=item an options hash reference, with options:

=over

=item exceptions

array reference of plug-in modules to be ignored.

=back

=back

Note: this routine also checks that each plug-in module is
free of syntax errors.

=cut

sub check_plugin_exports {
  my $root  = shift;
  my $opts  = shift;
  my $plugin_exceptions = $opts->{ exceptions };

  my $report = report_export_locations($root,
                              { exceptions => $plugin_exceptions,
                               });
  foreach my $exported_item ( %{ $report } ){
    my $aref = $report->{ $exported_item };
    my @sources = @{ $aref } if defined($aref);

    my $count = scalar( @sources );

    if ($count >= 2) {
      croak("Multiple definitions of $exported_item from plugins: " .
            join " ", @sources );
    }
  }
  return 1;
}

=item run_code_or_warn

Runs code passed in as a string (not a coderef), so that
"barewords" can be created from variables.

Returns the value of the code expression.

Generates an error message string using an optional
passed-in prefix, but with the the value from $@ appended.

As with carp, the error is reported as occurring in the calling
context, but also includes the full error message with it's own
location indicated.  The error message is reported to STDERR,
but execution continues.

Inputs:

=over

=item code string

=item prefix (optional) pre-pended to error messages.

=back

Example:

  my $prefix = "problem with $module_name";
  my $code = "require $module_name";
  run_code_or_warn( $code, $prefix );

=cut

sub run_code_or_warn {
  my $code_string   = shift;
  my $prefix        = shift;

  my ($package, $filename, $line) = caller(0);
  my $context = "in $filename at line $line: ";

  my $ret = '';
  $ret = eval $code_string;
  if ($@) {
    my $err_mess = $prefix . $context . $@;
    print STDERR "$err_mess\n";
  }
  return $ret;
}

=item run_code_or_die

Variant of run_code_or_warn that dies

Note: reports error in the calling context, much like "croak",
but also includes the full error message with it's own location
indicated.

=cut

sub run_code_or_die {

  my $code_string   = shift;
  my $prefix        = shift;

  my ($package, $filename, $line) = caller(0);
  my $context = "in $filename at line $line: ";

  my $ret = '';
  $ret = eval $code_string;
  if ($@) {
    my $err_mess = $prefix . $context . $@;
    die "$err_mess";
  }
  return $ret;
}




1;

=back

=head1 DISCUSSION

A "plug-in" architecture is a way of allowing for the behavior of
a system to be extended at a later date by the addition of new
modules without any changes to the existing code.

=head2 Plug-in Extension Techniques (polymorphism vs. promiscuity)

There are essentially two styles of plug-ins:

=over

=item polymorphic plug-ins

With "polymorphic plug-ins" a particular module appropriate to a
task is selected from the available set.  The same set of methods
(often called the "interface") are defined in different ways,
depending on the plug-in used.

=item promiscuous plug-ins

With "promiscuous plug-ins", the entire set of plug-in modules
is used at once, and each plug-in defines new methods.

=back

When implementing "polymorphic plug-ins", it's often convenient to
get a list of available modules, and then choose one of them
somehow (often by applying a naming convention).  The
"list_modules_under" routine here is helpful for this, though
admittedly, it's frequently almost as easy to just require the
expected module, and trap the error if the module doesn't exist.

For "promiscuous plug-ins", there are essentially two sub-types,
object-oriented and procedural.  In the object-oriented case, a
list of modules can be pushed directly into the @ISA array so that
any methods implemented in the extension modules become available
via the justly-feared but occasionally useful
"multiple-inheritance" mechanism.  In the procedural case, you
can use the "import_modules" routine provided here, which does
something like a use-at-runtime on all of the plug-ins (it does a
"require" of each module, and then an "import").

Obviously, in the object-oriented form, the routines in the
extensions must be written as methods (e.g. each should begin
with "my $self=shift;").  In the procedural case, each module
should use "Exporter", and to work with the "import_modules"
routine supplied here, all features to-be-exported should be in
the @EXPORT array of each plug-in module.

But note that these two approaches can be combined into a hybrid
form: Exporter can be used to bring a collection of OOP methods
into the current object's namespace.

These Exporter-based "promiscuous plug-ins" (whether OOP or
procedural) have an advantage over the multiple-inheritance
approach: the damage is limited that can be done by the addition
of a new, perhaps carelessly written plug-in module:
The "import_modules" routine (by default) watches for name
collisions in the routines imported from the plug-ins, and
throws an error when they occur.  In comparison the simple MI
solution will silently use which ever plug-in method it sees
first in the path; so if the sort order of your list of plug-in
modules doesn't work as a precedence list, then you may be in
trouble.

Using the hybrid approach (OOP methods brought into a common
namespace by using "import_modules"), you need to watch out for
the fact that these plug-in methods will inherit based on the
@ISA of the class they're imported into: a "use base" in the
package where the methods are defined will have no effect.  If
your plug-ins all need to use common code inherited from a
particular module, then the parent needs to be in the
inheritance chain of the class the plug-ins are imported into,
not in the package in which they were originally written.

A restriction that all "promiscuous" OOP plug-in schemes share
(to my knowledge) is that sub-classing essentially doesn't work
with them.  Simply adding a subclass of a plug-in to the set is
not enough to reliably override the original: the precedence
between the two will be silently chosen based on some arbitrary
criteria (typically accidents of sort order in the module
names).

Even if a way could be found to solve that problem (e.g. an
import mechanism that skips parents when a child exists) it
wouldn't seem advisable to use it: simply adding a new plug-in
would have the potential to break existing code.

However, if you *really* feel the need to do something like this,
the "exceptions" feature of "import_modules" could be used to
manually suppress a parent plug-in, so that only the child
plug-in will be imported.  Similarly, if you realize that someone
else's module is creating problems for you, the "exceptions"
feature provides an alternate way to suppress it's use without
uninstalling it.


=head1 MOTIVATION

The L<List::Filter> project is an example of a use of
"promiscuous plug-ins" to provide an extreme (perhaps
"pathological") degree of extensibility.

=head2 list_modules_under

The wrapper routine "list_modules_under" seemed advisable
because of the very clunky interface of the "list_modules"
routine provided by L<Module::List> (see below). But then, at
least Module::List actually works correctly, unlike
L<Module::Find> (which double-reports modules if found in two
places in @INC).  And L<Module::Pluggable> is peculiarly limited
in that it essentially assumes you'll have a hardcoded search
location in module namespace.

=head2 Module::List peculiarities

The list_modules routine exported by Module::List has two
"options" that you will almost always want enabled:

  my $modules = list_modules("$root",
                           { list_modules =>1, recurse => 1});

You need to tell list_modules that you really want it to list the
modules (reminiscent of the "-print" option on the original unix
"find" command).  But recursion is I<off> by default, the
opposite of the "find" convention...

And the return value from "list_modules" is a hash reference
(not a 'list' or an aref).  What you actually want is the keys
of this hash (the values are just undefs):

  my @found = keys %{ $modules };

Another minor irritation is that the first argument (a place in
module name space) is required to have a trailing "::" appended
to it.  However, it does understand that an empty string should
be interpreted as the entire list of installed modules (note: it
takes a long time to get this full list, as you might expect).

=head1 LIMITATIONS

When using "import_modules" (which brings in methods via Exporter):

  o  methods can inherit from the @ISA of their new context, but
     not the package they came from.

  o  subclassing an existing plug-in to create a new one should
     almost always be avoided: the precedence of child over
     parent can't be easily guaranteed, and adding a new plug-in
     can break existing code.

=head1 SEE ALSO

L<Module::List>
L<Module::Pluggable>
L<Module::Find>

=head1 TODO

Add a "recurse" option to both routines: default to recurse, but
allow them to work on a single directory level.

=head1 AUTHOR

Joseph Brenner, E<lt>doom@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Joseph Brenner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut
