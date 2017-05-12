package NGS::Tools::BAMSurgeon::Helper;

# This package is primarily used to import other things. ToolSet makes this easier
use base 'ToolSet';

use Data::Dump 'dump';
use feature qw(say);
use Log::ProgramInfo;

=head1 NAME

NGS::Tools::BAMSurgeon::Helper - A convenience module for importing general perl usefulness

=cut


=head1 SYNOPSIS

	use NGS::Tools::BAMSurgeon::Helper;
	# We are now using strict, warnings, Carp, File::ShareDir, File::pushd, MooseX::Params::Validate
	# You also have access to the following functions:

	# Like print, but includes a newline automatically
	say("Hello!");

	# both of these pretty print variable contents, even if they are arrays, hashes, nested, etc.
	# (formatted printing via Data::Dump)
	pretty_print(\@my_array);
	# [2, 3, { 5 => 7 }]
	dump(\@my_array);
	# [2, 3, { 5 => 7 }]

	# This lists all loaded modules, their versions, and the path they're loaded from
	show_modules();
	# "NGS::Tools::BAMSurgeon::Helper"	=> [
	# 	"0.1.0",
	# 	"/u/me/lib/NGS/Tools/BAMSurgeon/Helper.pm",
	# ],
	# "Carp"                  => [
	# 	1.32,
	# 	"/sw/perl/lib/site_perl/5.18.1/Carp.pm",
	# ],
	# ...

	# This lists @INC, the search path for modules, in a nice format
	show_inc();
	# [
	# 	"/u/me/repos/modulename/blib/lib",
	# 	".",
	#	...
	# ]

=cut

ToolSet->use_pragma('strict');
ToolSet->use_pragma('warnings');

# Make the say function work
ToolSet->use_pragma( qw(feature say) );

# define exports from other modules
ToolSet->export(
	Carp                     => undef,    # get the defaults
	Data::Dump               => 'dump',
	File::pushd              => undef,
	File::ShareDir           => undef,
	MooseX::Params::Validate => undef
	);

our @EXPORT = qw(pretty_print show_modules show_inc);

# Nice data structures
sub pretty_print {
	dump(@_);
}

# Print version and loading path information for modules
sub show_modules {
	my $module_infos = {};

	# %INC looks like this:
	# {
	#    ...
	#    "Data/Dump.pm"
	#        => "/whatever/perl/lib/site_perl/5.18.1/Data/Dump.pm",
	#    ...
	# }
	# So let's convert it to this:
	# {
	#    ...
	#    "Data/Dump.pm"
	#        => [ "1.4.2",
	#             "/whatever/perl/lib/site_perl/5.18.1/Data/Dump.pm",
	#           ],
	#    ...
	# }
	foreach my $module_inc_name ( keys(%INC) ) {
		my $real_name = $module_inc_name;
		$real_name =~ s|/|::|g;
		$real_name =~ s|\.pm$||;

		my $version = eval { $real_name->VERSION }
			// eval { ${"${real_name}::VERSION"} }
			// 'unknown';
		# stringify, in case it is a weird format
		# - I don't think the 'invalid' alternative can be hit, but safer to have it in
		$version = eval { $version . ''  } // 'invalid';

		$module_infos->{$real_name} = [ $version, $INC{$module_inc_name} ];
		}

	return $module_infos if defined wantarray();

	say( "Modules currently found are:\n", dump($module_infos) );
	}

# Print @INC nicely
sub show_inc {
	my $result = dump( \@INC );
	return $result if defined wantarray();
	say( "Modules are currently being looked for in these locations:\n", $result );
	}

1;
