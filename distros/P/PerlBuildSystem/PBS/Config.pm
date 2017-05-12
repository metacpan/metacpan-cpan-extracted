
package PBS::Config ;

use PBS::Debug ;
use strict ;
use warnings ;

use 5.006 ;

#~ use Data::Dumper ;
use Data::TreeDumper ;
use Data::Compare;

use Carp ;
 
require Exporter ;
use AutoLoader qw(AUTOLOAD) ;

our @ISA = qw(Exporter) ;
our %EXPORT_TAGS = ('all' => [ qw() ]) ;
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } ) ;
our @EXPORT = qw(
					AddConfig       AddConfigTo
					GetConfig       GetConfigFrom
					GetConfigAsList GetConfigFromAsList
					
					AddCompositeDefine
					
					AddConditionalConfig
					AddConditionalConfigTo
						ConfigVariableNotDefined
						ConfigVariableEmpty
						ConfigVariableNotDefinedOrEmpty
					) ;
					
our $VERSION = '0.03' ;

use PBS::Output ;

our $debug_display_all_configurations ;

#-------------------------------------------------------------------------------

my %configs ;

#-------------------------------------------------------------------------------

sub GetPackageConfig
{
my $package = shift ;
my ($caller_package, $file_name, $line) = caller() ;

if(defined $package && $package ne '')
	{
	$configs{$package} = {} unless (exists $configs{$package}) ;
	
	return($configs{$package}) ;
	}
else
	{
	PrintWarning("'GetPackageConfig' mandatory argument missing at '$file_name:$line'.\n") ;
	return({}) ;
	}
}

#-------------------------------------------------------------------------------

sub GetConfigFrom
{
my ($package, $file_name, $line) = caller() ;

my $from = shift ; # namespace

unless(defined $from)
	{
	PrintWarning("'GetConfigFrom' mandatory argument missing at '$file_name:$line'.\n") ;
	#~ PbsDisplayErrorWithContext($file_name,$line) ;
	return() ;
	}

my %user_config = ExtractConfig($configs{$package}, [$from], undef) ;

return
	(
	__GetConfig
		(
		  $package, $file_name, $line
		, wantarray
		, \%user_config
		, @_
		)
	) ;
}

#-------------------------------------------------------------------------------

sub GetConfig
{
my ($package, $file_name, $line) = caller() ;

my $pbs_config = PBS::PBSConfig::GetPbsConfig($package) ;
my %user_config = ExtractConfig($configs{$package}, $pbs_config->{CONFIG_NAMESPACES}, undef) ;

return
	(
	__GetConfig
		(
		  $package, $file_name, $line
		, wantarray
		, \%user_config
		, @_
		)
	) ;
}

#-------------------------------------------------------------------------------

sub __GetConfig
{
my 
	(
	  $package, $file_name, $line
	, $wantarray
	, $user_config
	, @config_variables
	) = @_ ;
	
$file_name =~ s/^'// ; $file_name =~ s/'$// ;

my @user_config ;
if(@config_variables == 0)
	{
	unless($wantarray)
		{
		PrintWarning("'GetConfig' is returning the whole config but it was not called in list context at '$file_name:$line'.\n") ;
		}
		
	return(%$user_config) ;
	}
	
if(@config_variables > 1 && (!$wantarray))
	{
	PrintWarning("'GetConfig' is asked for multiple values but it was not called in list context at '$file_name:$line'!\n") ;
	}

for my $config_variable (@config_variables)
	{
	my $silent_not_exists = $config_variable =~ s/:SILENT_NOT_EXISTS$// ;
	
	if(exists $user_config->{$config_variable})
		{
		push @user_config, $user_config->{$config_variable} ;
		}
	else
		{
		my $pbs_config = PBS::PBSConfig::GetPbsConfig($package) ;
		
		if($pbs_config->{NO_SILENT_OVERRIDE} || ! $silent_not_exists)
			{
			PrintWarning("User config variable '$config_variable' doesn't exist at '$file_name:$line'. Returning undef!\n") ;
			}
			
		#~ PbsDisplayErrorWithContext($file_name,$line) ;
		push @user_config, undef ;
		}
	}

if($wantarray)
	{
	return(@user_config) ;
	}
else
	{
	return($user_config[0]) ;
	}
}

#-------------------------------------------------------------------------------

sub GetConfigFromAsList
{
my ($package, $file_name, $line) = caller() ;

my $from = shift ; # from namespace

unless(defined $from)
	{
	PrintWarning("'GetConfigFromAsList' mandatory argument missing at '$file_name:$line'.\n") ;
	#~ PbsDisplayErrorWithContext($file_name,$line) ;
	return() ;
	}

my %user_config = ExtractConfig($configs{$package}, [$from], undef) ;

return
	(
	__GetConfigAsList
		(
		  $package, $file_name, $line
		, wantarray
		, \%user_config
		, @_
		)
	) ;
}

#-------------------------------------------------------------------------------

sub GetConfigAsList
{
my ($package, $file_name, $line) = caller() ;
$file_name =~ s/^'// ; $file_name =~ s/'$// ;

my $pbs_config = PBS::PBSConfig::GetPbsConfig($package) ;
my %user_config = ExtractConfig($configs{$package}, $pbs_config->{CONFIG_NAMESPACES}, undef) ;

return
	(
	__GetConfigAsList
		(
		  $package, $file_name, $line
		, wantarray
		, \%user_config
		, @_
		)
	) ;
}

#-------------------------------------------------------------------------------

sub __GetConfigAsList
{
my 
	(
	 $package, $file_name, $line
	, $wantarray
	, $user_config
	, @config_variables
	) = @_ ;

my $caller_location = "at '$file_name:$line'" ;
my @user_config ;

unless($wantarray)
	{
	die ERROR "'GetConfigAsList' is not called in list context $caller_location!\n" ;
	}

if(@config_variables == 0)
	{
	die ERROR "'GetConfigAsList' called without arguments $caller_location'.\n" ;
	}
	
for my $config_variable (@config_variables)
	{
	if(exists $user_config->{$config_variable})
		{
		my $config_data = $user_config->{$config_variable} ;
		
		for my $data_type (ref $config_data)
			{
			'ARRAY' eq $data_type && do
				{
				my $array_element_index = 0 ;
				for my $array_element (@$config_data)
					{
					PrintWarning "GetConfigAsList: Element $array_element_index of array '$config_variable', $caller_location, is not defined!\n" unless defined $array_element  ;
					$array_element_index++ ;
					}
				
				push @user_config, @$config_data ;
				last ;
				} ;
				
			'' eq $data_type && do
				{
				PrintWarning "GetConfigAsList: '$config_variable', $caller_location, is not defined!\n" unless defined $config_data ;
				
				push @user_config, $config_data ;
				last ;
				} ;
				
			die ERROR "GetConfigAsList: Unhandled type '$data_type' for '$config_variable' $caller_location.\n" ;
			}
		
		}
	else
		{
		PrintWarning("Config variable '$config_variable' doesn't exist $caller_location. Ignoring!\n") ;
		#~ PbsDisplayErrorWithContext($file_name,$line) ;
		}
	}

return(@user_config) ;
}

#-------------------------------------------------------------------------------

sub ExtractConfig
{
my $config = shift ;
my $config_class_names = shift ;

# see documentation about config classes and namespaces
my $config_types = shift || ['CURRENT', 'PARENT', 'LOCAL', 'COMMAND_LINE', 'PBS_FORCED'] ;

my %all_configs = () ;

for my $type (@$config_types)
	{
	for my $config_class_name (@$config_class_names, '__PBS', '__PBS_FORCED')
		{
		if(exists $config->{$type}{$config_class_name})
			{
			my $current_config = $config->{$type}{$config_class_name} ;
			
			for my $key (sort keys %$current_config)
				{
				next if $key =~ /^__/ ;
				$all_configs{$key} =  $current_config->{$key}{VALUE} ;
				}
			}
		}
	}

return(%all_configs) ;
}

#-------------------------------------------------------------------------------

sub AddConfig
{
# available within Pbsfiles
my ($package, $file_name, $line) = caller() ;

AddConfigEntry($package, 'CURRENT', 'User', "$package:$file_name:$line", @_) ;
}

#-------------------------------------------------------------------------------

sub ConfigVariableNotDefined
{
return (! defined $_[1]) ;
}

sub ConfigVariableEmpty
{
if(defined $_[1])
	{
	return ($_[1] eq '') ;
	}
else
	{
	PrintWarning croak "Configuration variable '$_[0]' is not defined!\n" ;
	return(0) ;
	}
}

sub ConfigVariableNotDefinedOrEmpty
{
return ConfigVariableNotDefined(@_) || ConfigVariableEmpty(@_) ;
}

#-------------------------------------------------------------------------------
sub AddConditionalConfig
{
my ($package, $file_name, $line) = caller() ;

_AddConditionalConfig($package, $file_name, $line, 'USER', @_) ;
}

sub AddConditionalConfigTo
{
my ($package, $file_name, $line) = caller() ;
my $class = shift ;

_AddConditionalConfig($package, $file_name, $line, $class, @_) ;
}

sub _AddConditionalConfig
{
my ($package, $file_name, $line, $class) = splice(@_, 0, 4) ;

while(@_)
	{
	my ($variable, $value, $test) = splice(@_, 0, 3) ;
	
	my $pbs_config = PBS::PBSConfig::GetPbsConfig($package) ;
	my %user_config = ExtractConfig($configs{$package}, $pbs_config->{CONFIG_NAMESPACES}, undef) ;
	
	my $current_value ;
	$current_value = $user_config{$variable} if exists $user_config{$variable};
	
	#~ PrintDebug "$variable: $current_value\n" ;
	
	if($test->($variable, $current_value))
		{
		#~ PrintDebug "Adding '$variable' in 'AddConditionalConfig'\n" ;
		
		AddConfigEntry($package, 'CURRENT', $class, "$package:$file_name:$line", $variable, $value) ;
		}
	}
}

#-------------------------------------------------------------------------------

sub AddConfigTo
{
# available within Pbsfiles
my $class = shift ;
my ($package, $file_name, $line) = caller() ;

AddConfigEntry($package, 'CURRENT', $class, "$package:$file_name:$line", @_) ;
}

#-------------------------------------------------------------------------------

sub AddConfigEntry
{
my $package = shift ;
my $type    = shift ; # CURRENT | PARENT | COMMAND_LINE
my $class   = shift ;
my $origin  = shift ;

#~ my $pbs_config = PBS::PBSConfig::GetPbsConfig($package) ;

MergeConfig($package, $type, $class, $origin, @_) ;
}

#-------------------------------------------------------------------------------

sub DisplayAllConfigs
{
PrintInfo(DumpTree(\%configs, 'All configurations:')) ;
}

#------------------------------------------------------------------------------------------

sub MergeConfig
{
my $package            = shift ; # name of the packages and eventual command flags
my $original_type      = shift ;
my $original_class     = shift ;
my $origin             = shift ;

# @_ contains the configuration variable to merge  (name => value, name => value ...)

# check if we have any command global flags
my $global_flags ;
($original_class, $global_flags) = $original_class =~ /^([^:]+)(.*)/ ;

my %global_attributes ;
if(defined $global_flags)
	{
	$global_flags =~ s/^:+// ;
	
	for my $attribute (split /:+/, $global_flags)
		{
		$global_attributes{uc($attribute)}++ ;
		}
		
	if($global_attributes{LOCKED} && $global_attributes{UNLOCKED})
		{
		PrintError("Global configuration flag defined at '$origin', is declared as LOCKED and UNLOCKED\n") ;
		die ;
		}
		
	if($global_attributes{OVERRIDE_PARENT} && $global_attributes{LOCAL})
		{
		PrintError("Global configuration flag defined at '$origin', is declared as OVERRIDE_PARENT and LOCAL\n") ;
		die ;
		}
	}
		
# Get the config and extract what we need from it
my $pbs_config = PBS::PBSConfig::GetPbsConfig($package) ;

if(defined $pbs_config->{DEBUG_DISPLAY_ALL_CONFIGURATIONS})
	{
	PrintInfo("Merging to configuration: '${package}::${original_type}::$original_class' from '$origin'.\n") ;
	}

my $config_to_merge_to = GetPackageConfig($package) ;
my $config_to_merge_to_cache = {ExtractConfig($config_to_merge_to, [$original_class], undef)} ;

# replace by the above node and kept till we test validity (27/12/2004)
#my $config_to_merge_to_cache = {ExtractConfig($config_to_merge_to, [$original_class], [$original_type, 'PARENT', 'LOCAL'])} ;

# handle the config values and their flags
for(my $i = 0 ; $i < @_ ; $i += 2)
	{
	my ($type, $class) = ($original_type, $original_class) ; #sometimes overridden by flags
	
	my ($key, $value) = ($_[$i], $_[$i +1]) ;
	my ($local, $force, $override_parent, $locked, $unlocked, $silent_override) ;
		
	my $flags ;
	($key, $flags) = $key =~ /^([^:]+)(.*)/ ;
	
	my %attributes ;
	if(defined $flags)
		{
		$flags =~ s/^:+// ;
		
		for my $attribute (split /:+/, $flags)
			{
			$attributes{uc($attribute)}++ ;
			}
		
		$force           = $attributes{FORCE}           || $global_attributes{FORCE}           || '' ;
		$locked          = $attributes{LOCKED}          || $global_attributes{LOCKED}          || '' ;
		$unlocked        = $attributes{UNLOCKED}        || $global_attributes{UNLOCKED}        || '' ;
		$override_parent = $attributes{OVERRIDE_PARENT} || $global_attributes{OVERRIDE_PARENT} || '' ;
		$local           = $attributes{LOCAL}           || $global_attributes{LOCAL}           || '' ;
		
		$silent_override = $attributes{SILENT_OVERRIDE} || $global_attributes{SILENT_OVERRIDE} || '' ;
		$silent_override = 0 if $pbs_config->{NO_SILENT_OVERRIDE} ;
		
		if($locked && $unlocked)
			{
			PrintError("Configuration variable '$key' defined at '$origin', is declared as LOCKED and UNLOCKED\n") ;
			die ;
			}
			
		if($override_parent && $local)
			{
			PrintError("Configuration variable '$key' defined at '$origin', is declared as OVERRIDE_PARENT and LOCAL\n") ;
			die ;
			}
		}
		
	if('' eq ref $value && $type ne 'PARENT')
		{
		# PARENT variables was evaluated while adding them, we don't want to re-evaluate it 
		$value = EvalConfig
				(
				  $value
				, $config_to_merge_to_cache
				, $key
				, "Config at $origin"
				) ;
		}
		
	if(defined $pbs_config->{DEBUG_DISPLAY_ALL_CONFIGURATIONS})
		{
		PrintInfo("\t$key => $value\n") ;
		}
		
	#DEBUG	
	my %debug_data = 
		(
		  TYPE                => 'VARIABLE'
		  
		, VARIABLE_NAME       => $key
		, VARIABLE_VALUE      => $value
		, VARIABLE_ATTRIBUTES => \%attributes 
		
		, CONFIG_TO_MERGE_TO  => $config_to_merge_to
		, MERGE_TYPE          => $type
		, CLASS               => $class
		, ORIGIN              => $origin
		
		, PACKAGE_NAME        => $package
		, NODE_NAME           => 'not available'
		, PBSFILE             => 'not available'
		, RULE_NAME           => 'not available'
		) ;
	
	#DEBUG	
	$DB::single = 1 if($PBS::Debug::debug_enabled && PBS::Debug::CheckBreakpoint(%debug_data)) ;

	# Always merge variables of class PBS_FORCED, regardless of parent config/locked etc.
	if($class eq '__PBS_FORCED')
	{
	# warning: this adds a single entry
	$config_to_merge_to->{$type}{$class}{$key}{VALUE} = $value ;
	$config_to_merge_to_cache->{$key} = $value ;
	
	my $value_txt = defined $value ? $value : 'undef' ;
	push @{$config_to_merge_to->{$type}{$class}{$key}{ORIGIN}}, "$origin => $value_txt" ;
	
	return ;
	}
	
	if($override_parent)
		{
		$type = 'PARENT' ;
		$class = '__PBS' ;
		}
		
	if($local)
		{
		$type = 'LOCAL' ;
		}
		
	if(exists $config_to_merge_to->{$type}{$class}{$key})
		{
		if($config_to_merge_to->{$type}{$class}{$key}{LOCKED} && (! $force))
			{
			PrintError
				(
				DumpTree
					(
					  $config_to_merge_to->{$type}{$class}{$key}
					, "Configuration variable '$key' defined at $origin, wants to override locked variable:\n"
					  . "${package}::${type}::${class}::$key:"
					)
				) ;
			die ;
			}
		
		$config_to_merge_to->{$type}{$class}{$key}{LOCKED} = 1 if $locked ;
		$config_to_merge_to->{$type}{$class}{$key}{LOCKED} = 0 if $unlocked ;
		
		#~ if($config_to_merge_to->{$type}{$class}{$key}{VALUE} ne $value)
		if(! Compare($config_to_merge_to->{$type}{$class}{$key}{VALUE},$value))
			{
			# not equal
			$config_to_merge_to->{$type}{$class}{$key}{VALUE} = $value ;
			$config_to_merge_to_cache->{$key} = $value ;
			
			my $value_txt = defined $value ? $value : 'undef' ;
			push @{$config_to_merge_to->{$type}{$class}{$key}{ORIGIN}},  "$origin => $value_txt" ;
			
			PrintWarning
				(
				DumpTree
					(
					$config_to_merge_to->{$type}{$class}{$key}
					, "Overriding config '${package}::${type}::${class}::$key' it is now:"
					)
				) unless $silent_override ;
				
			$config_to_merge_to->{$type}{__PBS}{__OVERRIDE}{VALUE} = 1 ;
			push @{$config_to_merge_to->{$type}{__PBS}{__OVERRIDE}{ORIGIN}}, "$key @ $origin" ;
			}
		else
			{
			$config_to_merge_to->{$type}{$class}{$key}{VALUE} = $value ;
			$config_to_merge_to_cache->{$key} = $value ;
			
			my $value_txt = defined $value ? $value : 'undef' ;
			push @{$config_to_merge_to->{$type}{$class}{$key}{ORIGIN}}, "$origin => $value_txt" ;
			}
		}
	else
		{
		$config_to_merge_to->{$type}{$class}{$key}{LOCKED} = 1 if $locked ;
		$config_to_merge_to->{$type}{$class}{$key}{LOCKED} = 0 if $unlocked ;
		
		$config_to_merge_to->{$type}{$class}{$key}{VALUE} = $value ;
		$config_to_merge_to_cache->{$key} = $value ;
			
		my $value_txt = defined $value ? $value : 'undef' ;
		push @{$config_to_merge_to->{$type}{$class}{$key}{ORIGIN}}, "$origin => $value_txt" ;
		}
		
	# let the user know if it's configuration will not be used because of higer order classes
=comment
note that anytype that is override parent becomes a parent
but even a parent type can't override the command line =>
does it mean that command line cna't be overriden at all even by LOCAL


	if($type eq 'LOCAL')
		{
		CURRENT
		PARENT
		COMMAND_LINE
		
		if
		   exists $config_to_merge_to->{PARENT}
		&& exists $config_to_merge_to->{PARENT}{__PBS}{$key} 
		#~ && $value ne $config_to_merge_to->{PARENT}{__PBS}{$key}{VALUE}
		&& ! Compare($value, $config_to_merge_to->{PARENT}{__PBS}{$key}{VALUE})
		)
			{
			PrintWarning2
				(
				DumpTree
					(
					  {
					    'Parent\'s value' => $config_to_merge_to->{'PARENT'}{__PBS}{$key}{VALUE}
					  , 'Current value' => $value
					  }
					, "Ignoring '$key' defined at '$origin': Already defined in the subpbs'parent:"
					)
				) ;
			}
		}
=cut		
	if($type eq 'CURRENT')
		{
		if
		(
		   exists $config_to_merge_to->{PARENT}
		&& exists $config_to_merge_to->{PARENT}{__PBS}{$key} 
		#~ && $value ne $config_to_merge_to->{PARENT}{__PBS}{$key}{VALUE}
		&& ! Compare($value, $config_to_merge_to->{PARENT}{__PBS}{$key}{VALUE})
		)
			{
			PrintWarning2
				(
				DumpTree
					(
					  {
					    'Parent\'s value' => $config_to_merge_to->{'PARENT'}{__PBS}{$key}{VALUE}
					  , 'Current value' => $value
					  }
					, "Ignoring '$key' defined at '$origin': Already defined in the subpbs'parent:"
					)
				) ;
			}
		
		if
		(
		   exists $config_to_merge_to->{COMMAND_LINE}
		&& exists $config_to_merge_to->{COMMAND_LINE}{__PBS}{$key} 
		#~ && $value ne $config_to_merge_to->{COMMAND_LINE}{__PBS}{$key}{VALUE}
		&& ! Compare($value, $config_to_merge_to->{COMMAND_LINE}{__PBS}{$key}{VALUE})
		)
			{
			PrintWarning2
				(
				DumpTree
					(
					  {
					    'Command line' => $config_to_merge_to->{'COMMAND_LINE'}{__PBS}{$key}{VALUE}
					  , 'Current value' => $value
					  }
					, "Ignoring '$key' defined at '$origin': Already defined on the command line:"
					)
				) ;
			}
		}
		
	if($type eq 'PARENT')
		{
		if
		(
		   exists $config_to_merge_to->{COMMAND_LINE}
		&& exists $config_to_merge_to->{COMMAND_LINE}{__PBS}{$key} 
		#~ && $value ne $config_to_merge_to->{COMMAND_LINE}{__PBS}{$key}{VALUE}
		&& ! Compare($value, $config_to_merge_to->{COMMAND_LINE}{__PBS}{$key}{VALUE})
		)
			{
			PrintWarning2
				(
				DumpTree
					(
					  {
					    'Command line' => $config_to_merge_to->{'COMMAND_LINE'}{__PBS}{$key}{VALUE}
					  , Parent => $value
					  }
					, "Ignoring '$key' defined at '$origin': Already defined on the command line:"
					)
				) ;
			}
		}
		
	# TODO: add warning for locla override
	}
}

#-------------------------------------------------------------------------------

sub EvalConfig 
{
my $entry  = shift ;
my $config = shift ;
my $key    = shift ;
my $origin = shift ;

return($entry) unless defined $entry ;

my $undefined_config = 0 ;

#%% entries are not evaluated
$entry =~ s/\%\%/__PBS__PERCENT__/g ;

# replace config names with their values
while($entry =~/\$config->{('*[^}]+)'*}/g)
	{
	my $element = $1 ; $element =~ s/^'// ; $element =~ s/'$// ;

	unless(exists $config->{$element})
		{
		PrintWarning("While evaling '$key': \$config->{$1} doesn't exist at $origin.\n") ;
		$undefined_config++ ;
		next ;
		}
		
	unless(defined $config->{$element})
		{
		PrintWarning("While evaling '$key': \$config->{$1} isn't defined at $origin.\n") ;
		$undefined_config++ ;
		}
	}

return($entry) if $undefined_config ;

$entry =~ s|\\|\\\\|g ;
$entry =~ s/"/\x100/g ;
$entry = eval "\"$entry\";" ;
$entry =~ s/\x100/"/g ;

# replace uppercase words by their values within the config
while($entry =~ /\%([_A-Z0-9]+)/g)
	{
	my $element = $1 ;
	
	unless(exists $config->{$element})
		{
		#~ PrintDebug DumpTree($config, "Config") ;
		PrintWarning("While evaling '$key': configuration variable '$element' doesn't exist at $origin.\n") ;
		next ;
		}
		
	unless(defined $config->{$element})
		{
		PrintWarning("While evaling '$key': configuration variable '$element' isn't defined at $origin.\n") ;
		}
	}
	
$entry =~ s/\%([_A-Z0-9]+)/defined $config->{$1} ? $config->{$1} : $1/eg ;

$entry =~ s/__PBS__PERCENT__/\%/g ;

return($entry) ;
}

#-------------------------------------------------------------------------------

sub AddCompositeDefine
{
my ($variable_name, %defines) = @_;
my ($package, $file_name, $line) = caller() ;

if(keys %defines)
	{
	my @defines = map { "$_=$defines{$_}" } sort keys %defines ;
	my $defines = ' -D' . join ' -D', @defines;
	
	AddConfigEntry($package, 'CURRENT', 'User', "$package:$file_name:$line", $variable_name => $defines) ;
	}
}

#-------------------------------------------------------------------------------

1 ;

__END__

=head1 NAME

PBS::Config  -

=head1 SYNOPSIS

	use PBS::Config;
	AddConfig( CC => 'gcc', PROJECT => 'NAILARA') ;
	
	if(GetConfig('DEBUG_FLAGS'))
		{
		....

=head1 DESCRIPTION

PBS::Config exports functions that let the user add configuration variable.
The configuration are kept sorted on 5 different hierarchical levels.

=over 2

=item 1 Package name

=item 2 Class ('CURRENT', 'PARENT', 'LOCAL', 'COMMAND_LINE', 'PBS_FORCED')

=item 3 User defined namespaces

=back

The package name is automatically set by PBS and is used to keep all the subpbs configuration separate.
The classes are also set by PBS. They are used to define a precedence hierachy.
The precedence order is  B<CURRENT> < B<PARENT> < B<LOCAL> < B<COMMAND_LINE> < B<PBS_FORCED>.

I<AddConfig> uses the 'CURRENT' class, namespace 'User' by default. It's behaviour can be changed with argument attributes (see bellow).
If a variable exists in multiple classes, the one defined in the higher order class will be 
returned by I<GetConfig>.

=head2 Argument attributes

The variables passed to I<AddConfig> can have attributes that modify the lock attribute
of the variable or it's class. The attributes can be any of the following.

=over 2

=item LOCKED

=item UNLOCKED

=item FORCE

=item OVERRIDE_PARENT

=item LOCAL

=back

An attribute is passed by appending a ':' and the attribute to the variable name.

=head3 LOCKED and UNLOCKED

Within the class where the variable will be stored, the variable will be locked or not.
When run with the following example:

	AddConfig 'a' => 1 ;
	AddConfig 'a' => 2 ;
	
	AddConfig 'b:locked' => 1 ;
	AddConfig 'b' => 2 ;

Pbs generates a warning message for the first ovverride and an error message for
the attempt to override a locked variable:

	Overriding config 'PBS::Runs::PBS_1::CURRENT::User::a' it is now:
	+- ORIGIN [A1]
	¦  +- 0 = PBS::Runs::PBS_1:'Pbsfiles/config/lock.pl':14 => 1
	¦  +- 1 = PBS::Runs::PBS_1:'Pbsfiles/config/lock.pl':15 => 2
	+- VALUE = 2
	
	Configuration variable 'b' defined at PBS::Runs::PBS_1:'Pbsfiles/config/lock.pl':18,
	wants to override locked variable:PBS::Runs::PBS_1::CURRENT::User::b:
	+- LOCKED = 1
	+- ORIGIN [A1]FORCE
	¦  +- 0 = PBS::Runs::PBS_1:'Pbsfiles/config/lock.pl':17 => 1
	+- VALUE = 1

=head3 FORCE

Within the same class, a configuration can override a locked variable.
	AddConfig 'b:locked' => 1 ;
	AddConfig 'b:force' => 2 ;

	Overriding config 'PBS::Runs::PBS_1::CURRENT::User::b' it is now:
	+- LOCKED = 1
	+- ORIGIN [A1]
	¦  +- 0 = PBS::Runs::PBS_1:'Pbsfiles/config/force.pl':14 => 1
	¦  +- 1 = PBS::Runs::PBS_1:'Pbsfiles/config/force.pl':15 => 2
	+- VALUE = 2

=head3 OVERRIDE_PARENT

Pbsfile should always be written without knowledge of being a subbs or not. In some exceptional circumstenses,
you can override a parent variable with the 'OVERRIDE_PARENT' attribute. The configuration variable is changed
in the 'PARENT' class directly.

	AddConfig 'b:OVERRIDE_PARENT' => 42 ;

=head3 LOCAL

Configuration variable inheritence is present in PBS to insure that the top level Pbsfile can force it's configuration
over sub Pbsfiles. This is normaly what you want to do. Top level Pbsfile should know how child Pbsfiles work and what 
variables it utilizes. In normal cicumstences, the top Pbsfile sets configuration variables for the whole build 
(debug vs dev vs release for example). Child Pbsfiles sometimes know better than their parents what configuration is best.

Let's take an example whith 3 Pbsfile: B<parent.pl> uses B<child.pl> which in turn uses B<grand_child.pl>. B<Parent.pl> sets the optimization 
flags with the following I<AddConfig> call:

	AddConfig OPTIMIZE_FLAG => '04' ;

The configuration variable 'OPTIMIZE_FLAG' is passed to B<parent.pl> children. This is what we normaly want but we might know that
the code build by B<child.pl> can not be optimized with something other than 'O2' because of a compiler bug. We could use the B<OVVERIDE_PARENT>
attribute within B<child.pl>:

	AddConfig 'OPTIMIZE_FLAG:OVERRIDE_PARENT' => 'O2' ;

This would generate the right code but B<grand_child.pl> would receive the value 'O2' within the OPTIMIZE_FLAG variable. It is possible
to define local variable that override parent variable but let children get their grand parent configuration.

	AddConfig 'OPTIMIZE_FLAG:LOCAL' => 'O2' ;

Here is the output from the config example found in the distribution:

	[nadim@khemir PBS]$ pbs -p Pbsfiles/config/parent.pl -dc -nh -tta -nsi parent
	No source directory! Using '/home/nadim/Dev/PerlModules/PerlBuildSystem-0.24'.
	No Build directory! Using '/home/nadim/Dev/PerlModules/PerlBuildSystem-0.24'.
	Config for 'PBS':
	|- OPTIMIZE_FLAG_1 = O3
	|- OPTIMIZE_FLAG_2 = O3
	`- TARGET_PATH =
	Overriding config 'PBS::Runs::child_1::PARENT::__PBS::OPTIMIZE_FLAG_1' it is now:
	|- ORIGIN [A1]
	|  |- 0 = parent: 'PBS' [./child] => O3
	|  `- 1 = PBS::Runs::child_1:'./Pbsfiles/config/child.pl':1 => O2
	`- VALUE = O2
	Config for 'child':
	|- OPTIMIZE_FLAG_1 = O2
	|- OPTIMIZE_FLAG_2 = O2
	`- TARGET_PATH =
	Config for 'grand_child':
	|- OPTIMIZE_FLAG_1 = O2
	|- OPTIMIZE_FLAG_2 = O3
	`- TARGET_PATH =
	...

=head2 EXPORT

	AddConfig AddConfigTo
	GetConfig GetConfigFrom
	GetConfigAsList GetConfigFromAsList
	
=head1 AUTHOR

Khemir Nadim ibn Hamouda. nadim@khemir.net

=head1 SEE ALSO

--no_silent_override

=cut
