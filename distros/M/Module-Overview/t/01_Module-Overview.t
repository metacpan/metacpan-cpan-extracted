#!/usr/bin/perl

use strict;
use warnings;

#use Test::More 'no_plan';
use Test::More tests => 7;
use Test::Differences;

use FindBin qw($Bin);
use lib "$Bin/lib";

BEGIN {
	use_ok ( 'Module::Overview' ) or exit;
	use_ok ( 'M::O' ) or exit;
}

exit main();

sub main {
	my $mo = Module::Overview->new({
		'module_name' => 'Module::Overview',
	});
	can_ok($mo, 'get');
	can_ok($mo, 'text_simpletable');
	can_ok($mo, 'graph');
	
	eq_or_diff(
		$mo->text_simpletable,
		mo_texttable(),
		'->text_simpletable()',
	);

	my $mo2 = Module::Overview->new({
		'module_name'  => 'M::O',
		'hide_methods' => 1,
	});
	eq_or_diff(
		$mo2->text_simpletable,
		mo2_texttable(),
		'->text_simpletable()  hide_methods, classes',
	);
	
	return 0;
}

sub mo_texttable {
	return << '__END_OF_TABLE__'
.------------------+--------------------------------------------------------------.
| class            | Module::Overview                                             |
+------------------+--------------------------------------------------------------+
| parents          | Class::Accessor::Fast                                        |
| classes          | Class::Accessor                                              |
+------------------+--------------------------------------------------------------+
| uses             | Carp                                                         |
|                  | Class::Sniff                                                 |
|                  | Graph::Easy                                                  |
|                  | Module::ExtractUse                                           |
|                  | Text::SimpleTable                                            |
+------------------+--------------------------------------------------------------+
| methods          | _carp() [Class::Accessor]                                    |
|                  | _croak() [Class::Accessor]                                   |
|                  | _mk_accessors() [Class::Accessor]                            |
|                  | accessor_name_for() [Class::Accessor]                        |
|                  | best_practice_accessor_name_for() [Class::Accessor]          |
|                  | best_practice_mutator_name_for() [Class::Accessor]           |
|                  | follow_best_practice() [Class::Accessor]                     |
|                  | get()                                                        |
|                  | graph()                                                      |
|                  | import() [Class::Accessor]                                   |
|                  | make_accessor() [Class::Accessor::Fast]                      |
|                  | make_ro_accessor() [Class::Accessor::Fast]                   |
|                  | make_wo_accessor() [Class::Accessor::Fast]                   |
|                  | mk_accessors() [Class::Accessor]                             |
|                  | mk_ro_accessors() [Class::Accessor]                          |
|                  | mk_wo_accessors() [Class::Accessor]                          |
|                  | mutator_name_for() [Class::Accessor]                         |
|                  | new()                                                        |
|                  | set() [Class::Accessor]                                      |
|                  | text_simpletable()                                           |
+------------------+--------------------------------------------------------------+
| methods_imported | _hide_methods_accessor()                                     |
|                  | _module_name_accessor()                                      |
|                  | _recursion_filter_accessor()                                 |
|                  | _recursive_accessor()                                        |
|                  | confess()                                                    |
|                  | hide_methods()                                               |
|                  | module_name()                                                |
|                  | recursion_filter()                                           |
|                  | recursive()                                                  |
|                  | subname() [Class::Accessor]                                  |
'------------------+--------------------------------------------------------------'
__END_OF_TABLE__

}

sub mo2_texttable {
	return << '__END_OF_TABLE__'
.------------------+--------------------------------------------------------------.
| class            | M::O                                                         |
+------------------+--------------------------------------------------------------+
| parents          | Module::Overview                                             |
| classes          | Class::Accessor::Fast                                        |
|                  | Class::Accessor                                              |
'------------------+--------------------------------------------------------------'
__END_OF_TABLE__

}
