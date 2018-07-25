package Test::PathClassTiny::Utils;

use Test::More;
use Test::Exception;

use Module::Runtime qw< module_notional_filename >;

use parent 'Exporter';
our @EXPORT =   (
                    qw< loads_ok unload_module >,
                );


# stolen from: https://github.com/barefootcoder/common/blob/master/perl/myperl/t/autoload.t
sub loads_ok (&$$)
{
	my ($sub, $function, $module) = @_;
	my $module_key = module_notional_filename($module);

	is exists $INC{$module_key}, '', "haven't yet loaded: $module";
	lives_ok { $sub->() } "can call $function()";
	is exists $INC{$module_key}, 1, "have now loaded: $module";
}

# stolen from: Module::Refresh, which is:
# Copyright 2004,2011 by Jesse Vincent <jesse@bestpractical.com>, Audrey Tang <audreyt@audreyt.org>
# released under the Artistic License
sub unload_module
{
	my ($module) = @_;
	my $module_key = module_notional_filename($module);

	delete $INC{$module_key};
	foreach ( grep { index( $DB::sub{$_} , "$module_key:" ) == 0 } keys %DB::sub )
	{
		local $@;
		eval { undef &$_ };
		warn "$_: $@" if $@;
		delete $DB::sub{$_};
		no strict 'refs';
		delete *{$1}->{$2} if /^(.*::)(.*?)$/;
	}
}
