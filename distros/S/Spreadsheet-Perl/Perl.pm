
package Spreadsheet::Perl ;

use 5.006 ;

use Carp ;
use strict ;
use warnings ;

require Exporter ;

our @ISA = qw(Exporter) ;

our %EXPORT_TAGS = 
	(
	'all' => [ qw() ]
	) ;

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } ) ;

our @EXPORT ;
push @EXPORT, qw( Reset ) ;

our $VERSION = '0.12' ;

use Spreadsheet::Perl::Address ;
use Spreadsheet::Perl::Cache ;
use Spreadsheet::Perl::Devel ;
use Spreadsheet::Perl::Format ;
use Spreadsheet::Perl::Formula ;
use Spreadsheet::Perl::PerlFormula ;
use Spreadsheet::Perl::Function ;
use Spreadsheet::Perl::ASCIITable;
use Spreadsheet::Perl::Html ;
use Spreadsheet::Perl::InsertDelete ;
use Spreadsheet::Perl::Lock ;
use Spreadsheet::Perl::Label ;
use Spreadsheet::Perl::QuerySet ;
use Spreadsheet::Perl::Reference ;
use Spreadsheet::Perl::RangeValues ;
use Spreadsheet::Perl::ReadWrite ;
use Spreadsheet::Perl::UserData ;
use Spreadsheet::Perl::Validator ;

#-------------------------------------------------------------------------------

sub GetSpreadsheetDefaultData
{ 
return 
	(
	  NAME                => undef
	, CACHE               => 1
	, AUTOCALC            => 0
	, OTHER_SPREADSHEETS  => {}
	, DEBUG               => {
								ERROR_HANDLE => \*STDERR,
								PRINT_FORMULA_ERROR => 1,
							}
	
	, VALIDATORS          => [['Spreadsheet lock validator', \&LockValidator]]
	, ERROR_HANDLER       => undef # user registred sub
	, MESSAGE             => 
				{
				ERROR => '#ERROR'
				, NEED_UPDATE => '#NEED UPDATE'
				, VIRTUAL_CELL => '#VC'
				, ROW_PREFIX => 'R-' 
				}
				
	, DEPENDENT_STACK     => []
	, CELLS               => {}
	) ;
}

sub Reset
{
my $self = shift ;
my $setup = shift ;
my $cell_data  = shift ;

if(defined $setup)
	{
	if('HASH' eq ref $setup)
		{
		%$self = (GetSpreadsheetDefaultData(), %$setup) ;
		}
	else
		{
		confess "Setup data must be a hash reference!" 
		}
	}
	
if(defined $cell_data)
	{
	confess "cell data must be a hash reference!" unless 'HASH' eq ref $cell_data ;
	$self->{CELLS} = $cell_data ;
	}
else
	{
	$self->{CELLS} = {} ;
	}
}

#-------------------------------------------------------------------------------

sub TIEHASH 
{
my $class = shift ;

return($class) unless '' eq ref $class ;

my $self = 
	{
	  GetSpreadsheetDefaultData()
	, @_ 
	} ;

return(bless $self, $class) ;
}

#-------------------------------------------------------------------------------

sub FETCH 
{
my $self    = shift ;
my $address = shift;

my $attribute ;

if($address =~ /(.*)\.(.+)/)
	{
	$address = $1 ;
	$attribute = $2 ;
	}

#inter spreadsheet references
my $original_address = $address ;
my $ss_reference ;

my ($cell_or_range, $is_cell, $start_cell, $end_cell) = $self->CanonizeAddress($address) ;

($ss_reference, $address) = $self->GetSpreadsheetReference($cell_or_range) ;

if(defined $ss_reference)
	{
	if($ss_reference == $self)
		{
		# fine, it's us
		}
	else
		{
		if($self->{DEBUG}{FETCH_FROM_OTHER})
			{
			my $dh = $self->{DEBUG}{ERROR_HANDLE} ;
			print $dh $self->GetName() . " Fetching from spreadsheet '$original_address'.\n" ;
			}
			
		#handle inter spreadsheet dependency tracking and formula references
		if(exists $self->{DEPENDENCY_STACK})
			{
			$ss_reference->{DEPENDENCY_STACK} = $self->{DEPENDENCY_STACK} ;
			$ss_reference->{DEPENDENCY_STACK_LEVEL} = $self->{DEPENDENCY_STACK_LEVEL} ;
			$ss_reference->{DEPENDENCY_STACK_NO_CACHE} = $self->{DEPENDENCY_STACK_NO_CACHE} ;
			}

		# all spreadsheets reference the same DEPENDENT_STACK
		$ss_reference->{DEPENDENT_STACK} = $self->{DEPENDENT_STACK} ;
		
		my $cell_value = $ss_reference->Get($address) ;
		
		delete $ss_reference->{DEPENDENCY_STACK} ;
		delete $ss_reference->{DEPENDENCY_STACK_LEVEL} ;
		delete $ss_reference->{DEPENDENCY_STACK_NO_CACHE} ;

		return($cell_value) ;
		}
	}
else
	{
	confess "Can't find Spreadsheet object for address '$address'.\n." ;
	}

if($self->{DEBUG}{FETCH})
	{
	my $dh = $self->{DEBUG}{ERROR_HANDLE} ;
	
	if($is_cell)
		{
		print $dh "Fetching cell '$cell_or_range'\n" ;
		}
	else
		{
		print $dh "Fetching range '$cell_or_range'\n" ;
		}
	}
	
if($is_cell)
	{
	my ($value, $evaluation_ok, $evaluation_type, $evaluation_data) ;
	
	#trigger
	if(exists $self->{DEBUG}{FETCH_TRIGGER}{$start_cell})
		{
		if('CODE' eq ref $self->{DEBUG}{FETCH_TRIGGER}{$start_cell})
			{
			$self->{DEBUG}{FETCH_TRIGGER}{$start_cell}->($self, $start_cell, $attribute) ;
			}
		else
			{
			if(exists $self->{DEBUG}{FETCH_TRIGGER_HANDLER})
				{
				$self->{DEBUG}{FETCH_TRIGGER_HANDLER}->($self, $start_cell, $attribute) ;
				}
			else
				{
				my $dh = $self->{DEBUG}{ERROR_HANDLE} ;
				print $dh "Fetching cell '$start_cell'.\n" ;
				}
			}
		}
		
	if(exists $self->{CELLS}{$start_cell})
		{
		my $current_cell = $self->{CELLS}{$start_cell} ;
		
		if(defined $attribute)
			{
			$value = $current_cell->{$attribute} if(exists $current_cell->{$attribute}) ;
			}
		else
			{
			if($self->{DEBUG}{FETCHED})
				{
				$current_cell->{FETCHED}++ ;
				}
				
			# circular dependency checking
			if(exists $current_cell->{CYCLIC_FLAG})
				{
				if(exists $self->{DEPENDENCY_STACK})
					{
					my $level = '   ' x $self->{DEPENDENCY_STACK_LEVEL} ; 
					$self->{DEPENDENCY_STACK_LEVEL}++ ;

					my $name = ($self->GetName() || "$self") . '!' ;

					push @{$self->{DEPENDENCY_STACK}}, "$level#CYCLIC $name$start_cell" ;
					}

				my $dh = $self->{DEBUG}{ERROR_HANDLE} ;
				
				push @{$self->{DEPENDENT_STACK}}, [$self, $start_cell, $self->GetName()] ;
				print $dh $self->DumpDependentStack("Cyclic dependency while fetching '$start_cell'") ;
				
				my @dump ;

				for my $dependent (@{$self->{DEPENDENT_STACK}})
					{
					my ($spreadsheet, $address, $name) = @$dependent ;
					push @dump, "$name!$address" ;
					}

				pop @{$self->{DEPENDENT_STACK}} ;

				# Todo: is there some cleanup to do before calling die?
				die bless {cycle => \@dump}, 'Cyclic dependency' ;
				}
			else
				{
				$current_cell->{CYCLIC_FLAG}++ ;
				}
		
			if(exists $self->{DEPENDENCY_STACK})
				{
				my $level = '   ' x $self->{DEPENDENCY_STACK_LEVEL} ; 
				$self->{DEPENDENCY_STACK_LEVEL}++ ;

				my $name = ($self->GetName() || "$self") . '!' ;

				push @{$self->{DEPENDENCY_STACK}}, "$level$name$start_cell" ;
				}

			$self->FindDependent($current_cell, $start_cell) ;
			push @{$self->{DEPENDENT_STACK}}, [$self, $start_cell, $self->GetName()] ;
			
			if($self->{DEBUG}{DEPENDENT_STACK_ALL} || $self->{DEBUG}{DEPENDENT_STACK}{$start_cell})
				{
				my $dh = $self->{DEBUG}{ERROR_HANDLE} ;
				print $dh $self->DumpDependentStack("Fetching '" . $self->GetName() . "!$start_cell'") ;
				}
				
			# formula directly set into cells must get "compiled"
			# IE, when data is directly loaded from external file
			if(exists $current_cell->{PERL_FORMULA} && ! exists $current_cell->{FETCH_SUB})
				{
				die "case to be handled!\n" ;
				}
			else
				{
				if(exists $current_cell->{FORMULA} && ! exists $current_cell->{FETCH_SUB})
					{
					die "case to be handled!\n" ;
					}
				}
				
			if(exists $current_cell->{FETCH_SUB}) # formula or fetch callback
				{
				$self->initial_value_from_perl_scalar($start_cell, $current_cell)  if(exists $current_cell->{REF_FETCH_SUB}) ;
				
				if
					(
					$current_cell->{NEED_UPDATE} 
					|| ! exists $current_cell->{NEED_UPDATE} 
					|| ! exists $current_cell->{VALUE}
					|| exists $self->{DEPENDENCY_STACK_NO_CACHE} 
					)
					{
					if($self->{DEBUG}{FETCH_SUB})
						{
						my $dh = $self->{DEBUG}{ERROR_HANDLE} ;
						my $ss_name = $self->GetName() ;
						
						print $dh "Running Sub @ '$ss_name!$start_cell'" ;
						
						if(exists $current_cell->{FORMULA})
							{
							print $dh " formula: $current_cell->{FORMULA}[1]" ;
							}
							
						if(exists $current_cell->{PERL_FORMULA})
							{
							print $dh " formula: $current_cell->{PERL_FORMULA}[1]" ;
							}
							
						print $dh " defined at '@{$current_cell->{DEFINED_AT}}'" if(exists $current_cell->{DEFINED_AT}) ;
						print $dh "\n" ;
						}
#TODO!!!!  next section should be in eval and formula should generate an exception. this is needed so a failed formula doesn't update NEED_UPDATE state nor saves the erroneous value trought STORE_ON_FETCH or a perl scalar. Although I am not sure. Maybe it is better to store the erroneous values if they are descriptive enought so it is clear that the values are not in synch.	
					if(exists $current_cell->{FETCH_SUB_ARGS} && @{$current_cell->{FETCH_SUB_ARGS}})
						{
						($value, $evaluation_ok, $evaluation_type, $evaluation_data)
							= ($current_cell->{FETCH_SUB})->($self, $start_cell, @{$current_cell->{FETCH_SUB_ARGS}}) ;
						}
						
					else
						{
						($value, $evaluation_ok, $evaluation_type, $evaluation_data)
							= ($current_cell->{FETCH_SUB})->($self, $start_cell) ;
						}
						
					if(exists $current_cell->{REF_STORE_SUB} && exists $current_cell->{STORE_ON_FETCH})
						{
						$current_cell->{REF_STORE_SUB}->($self, $start_cell, $value) ;
						}
						
					if(exists $current_cell->{STORE_SUB} && exists $current_cell->{STORE_ON_FETCH})
						{
						if(exists $current_cell->{STORE_SUB_ARGS} && @{$current_cell->{STORE_SUB_ARGS}})
							{
							$current_cell->{STORE_SUB}->($self, $start_cell, $value, @{$current_cell->{STORE_SUB_ARGS}}) ;
							}
						else
							{
							$current_cell->{STORE_SUB}->($self, $start_cell, $value) ;
							}
						}
						
					if($self->{DEBUG}{PRINT_FORMULA_ERROR} && $evaluation_ok == 0)
						{
						$value .= " ($evaluation_type)" ;
						}

					$current_cell->{EVAL_TYPE} = $evaluation_type ;
					$current_cell->{EVAL_OK} = $evaluation_ok ;
					$current_cell->{EVAL_DATA} = $evaluation_data ;
					
					# handle caching
					if((! $self->{CACHE}) || (exists $current_cell->{CACHE} && (! $current_cell->{CACHE})))
						{
						delete $current_cell->{VALUE} ;
						$current_cell->{NEED_UPDATE} = 1 ;
						}
					else
						{
						$current_cell->{VALUE} = $value ;
						$current_cell->{NEED_UPDATE} = 0 ;
						}

					if(@{$self->{DEPENDENT_STACK}} != 1)
						{
						# catch exception at cell that started computation
						unless ($evaluation_ok)
							{
							#Todo: cleanup automatically
							$self->{DEPENDENCY_STACK_LEVEL}-- if exists $self->{DEPENDENCY_STACK_LEVEL} ;
					
							pop @{$self->{DEPENDENT_STACK}} ;
							delete $current_cell->{CYCLIC_FLAG} ;

							die bless {spreadsheet => $self, cell => $start_cell}, 'Invalid dependency cell' ;
							}
						}
					}
				else
					{
					$value = $current_cell->{VALUE} ;
					}
				}
			else
				{
				if(exists $current_cell->{REF_FETCH_SUB})
					{
					#fetch value from reference
					if(exists $self->{DEBUG}{FETCH_TRIGGER}{$start_cell})
						{
						my $dh = $self->{DEBUG}{ERROR_HANDLE} ;
						print $dh "  => Fetching cell '$start_cell' value from scalar reference.\n" ;
						}
					
					$current_cell->{VALUE} = $current_cell->{REF_FETCH_SUB}->($self, $start_cell) ;
					}
					
				# Todo: shouldn't we handle cache here too?!
				if(exists $current_cell->{VALUE})
					{
					$value = $current_cell->{VALUE} ;
					}
				else
					{
					$value = undef ;
					}
				}

			$self->{DEPENDENCY_STACK_LEVEL}-- if exists $self->{DEPENDENCY_STACK_LEVEL} ;
				
			pop @{$self->{DEPENDENT_STACK}} ;
			delete $current_cell->{CYCLIC_FLAG} ;
			}
		}
	else
		{
		# cell has never been accessed before
		# not even to set a formula or a dependency list in it
		if(exists $self->{DEPENDENCY_STACK})
			{
			my $level = '   ' x $self->{DEPENDENCY_STACK_LEVEL} ; 
			my $name = ($self->GetName() || "$self") . '!' ;

			push @{$self->{DEPENDENCY_STACK}}, "$level$name$start_cell" ;
			}

		if(@{$self->{DEPENDENT_STACK}})
			{
			$self->{CELLS}{$start_cell} = {} ; # create the cell to hold the dependent
			$self->FindDependent($self->{CELLS}{$start_cell}, $start_cell) ;
		
			if($self->{DEBUG}{DEPENDENT_STACK_ALL} || $self->{DEBUG}{DEPENDENT_STACK}{$start_cell})
				{
				push @{$self->{DEPENDENT_STACK}}, [$self, $start_cell, $self->GetName()] ;
				
				my $dh = $self->{DEBUG}{ERROR_HANDLE} ;
				print $dh $self->DumpDependentStack("Fetching '" . $self->GetName() . "!$start_cell' (virtual cell)") ;
				
				pop @{$self->{DEPENDENT_STACK}} ;
				}
			}
			
		# handle headers and default values
		my ($column, $row) = ConvertAdressToNumeric($start_cell) ;
		
		if($row == 0)
			{
			$value = ToAA($column) ;
			}
		else
			{
			if($column == 0)
				{
				$value = $self->{MESSAGE}{ROW_PREFIX} . $row ;
				}
			else
				{
				$value = undef ;
				}
			}
		}

	if($self->{DEBUG}{FETCH_VALUE})
		{
		my $dh = $self->{DEBUG}{ERROR_HANDLE} ;
		print $dh "\t value: $value\n" ;
		}
		
	return($value) ;
	}
else
	{
	# range requested
	
	my @values ;

	for my $current_address ($self->GetAddressList($address))
		{
		push @values, $self->Get($current_address) ;
		}

	if($self->{DEBUG}{FETCH})
		{
		my $dh = $self->{DEBUG}{ERROR_HANDLE} ;
		print $dh "END: Fetching range '$cell_or_range'\n" ;
		}

		
	return \@values ;
	}
}

*Get = \&FETCH ;

sub initial_value_from_perl_scalar
{
# note that the scalar fetch mechanism is removed after the call to this sub

my ($self, $cell_address, $current_cell) = @_ ;

if(exists $current_cell->{REF_FETCH_SUB})
	{
	# value from reference will be shdowed by formula
	if(exists $self->{DEBUG}{FETCH_TRIGGER}{$cell_address})
		{
		my $dh = $self->{DEBUG}{ERROR_HANDLE} ;
		print $dh "  => Cell '$cell_address' value from scalar reference is shadowed by formula.\n" ;
		}
	
	$current_cell->{VALUE} = '# shadowed by formula' ;
	
	# the value from the scalar can be fetched with
	# $current_cell->{REF_FETCH_SUB}->($self, $cell_address) ;
	
	delete $current_cell->{REF_FETCH_SUB} ;
	delete $current_cell->{CACHE} ;
	$current_cell->{STORE_ON_FETCH}++ ;
	}
}
			
sub GetAllDependencies
{
my ($self, $cell_address, $do_not_use_cache) = @_ ;

# DEPENDENCY_STACK will hold the address of all the 
# cells accessed while accessing $cell_address
$self->{DEPENDENCY_STACK} = [] ;
$self->{DEPENDENCY_STACK_LEVEL} = -1 ;
$self->{DEPENDENCY_STACK_NO_CACHE}++ if $do_not_use_cache ;

$self->Get($cell_address) ;

my $all_dependencies = $self->{DEPENDENCY_STACK} ;

delete $self->{DEPENDENCY_STACK} ;
delete $self->{DEPENDENCY_STACK_LEVEL} ;
delete $self->{DEPENDENCY_STACK_NO_CACHE} ;

return $all_dependencies ;
}

sub FindDependent
{
my ($self, $current_cell, $start_cell) = @_ ;

if(exists $self->{DEPENDENT_STACK} && @{$self->{DEPENDENT_STACK}})
	{
	my $dependent = @{$self->{DEPENDENT_STACK}}[-1] ;
	my ($spreadsheet, $cell_name) = @$dependent ;
	my $dependent_name = $spreadsheet->GetName() . "!$cell_name" ;
	
	if($self->{DEBUG}{DEPENDENT})
		{
		$current_cell->{DEPENDENT}{$dependent_name}{DEPENDENT_DATA} = $dependent ;
		$current_cell->{DEPENDENT}{$dependent_name}{COUNT}++ ;
		}
	else
		{
		$current_cell->{DEPENDENT}{$dependent_name}{DEPENDENT_DATA} = $dependent ;
		}
	}
}

#-------------------------------------------------------------------------------

sub STORE 
{
my $self    = shift ;
my $address = shift ;
my $value   = shift ;

# inter spreadsheets references
my $original_address = $address ;
my $ss_reference ;

my ($cell_or_range, $is_cell, $start_cell, $end_cell) = $self->CanonizeAddress($address) ;

($ss_reference, $address) = $self->GetSpreadsheetReference($cell_or_range) ;

if(defined $ss_reference)
	{
	if($ss_reference == $self)
		{
		#~ print "fine, it's us" ;
		}
	else
		{
		if($self->{DEBUG}{REDIRECTION})
			{
			my $dh = $self->{DEBUG}{ERROR_HANDLE} ;
			print $dh $self->GetName() . " Store redirected to spreadsheet '$original_address'.\n" ;
			}
			
		return($ss_reference->Set($address, $value)) ;
		}
	}
else
	{
	confess "Can't find Spreadsheet object for address '$address'.\n." ;
	}
	
if($self->{DEBUG}{STORE})
	{
	my $dh = $self->{DEBUG}{ERROR_HANDLE} ;
	#~ print $dh "Storing To '$address' @ @{[join ':', caller()]}\n" ;
	print $dh "Storing To '$address'\n" ;
	}
	
# Set the value in the current spreadsheet
for my $current_address ($self->GetAddressList($address))
	{
	unless(exists $self->{CELLS}{$current_address})
		{
		$self->{CELLS}{$current_address} = {} ;
		}
	
	my $current_cell = $self->{CELLS}{$current_address} ;
	
	if($self->{DEBUG}{STORED})
		{
		$current_cell->{STORED}++ ;
		}
		
	# triggers
	if(exists $self->{DEBUG}{STORE_TRIGGER}{$current_address})
		{
		if('CODE' eq ref $self->{DEBUG}{STORE_TRIGGER}{$current_address})
			{
			$self->{DEBUG}{STORE_TRIGGER}{$current_address}->($self, $current_address, $value) ;
			}
		else
			{
			if(exists $self->{DEBUG}{STORE_TRIGGER_HANDLER})
				{
				$self->{DEBUG}{STORE_TRIGGER_HANDLER}->($self, $current_address, $value) ;
				}
			else
				{
				my $dh = $self->{DEBUG}{ERROR_HANDLE} ;
				my $value_text = "$value" if defined $value ;
				$value_text    = 'undef' unless defined $value ;
				print $dh "Storing cell '$current_address' => $value_text\n" ;
				}
			}
		}
		
	# validators
	my $value_is_valid = 1 ;
	
	unless(defined $value && ref $value =~ /^Spreadsheet::Perl/)
		{
		my $cell_validators = $current_cell->{VALIDATORS} if(exists $current_cell->{VALIDATORS}) ;
		
		for my $validator_data (@{$self->{VALIDATORS}}, @$cell_validators)
			{
			if(0 == $validator_data->[1]($self, $current_address, $current_cell, $value))
				{
				$value_is_valid = 0 ;
				last ;
				}
			}
		}
		
	if($value_is_valid)
		{
		$self->MarkDependentForUpdate($current_cell, $address) ;
		$self->InvalidateCellInDependent($current_address) ;

		$current_cell->{DEFINED_AT} = [caller] if(exists $self->{DEBUG}{DEFINED_AT}) ;
		
		for (ref $value)
			{
			/^Spreadsheet::Perl::Cache$/ && do
				{
				$current_cell->{CACHE} = $$value ;
				last ;
				} ;
				
			(
			   /^Spreadsheet::Perl::Formula$/
			|| /^Spreadsheet::Perl::PerlFormula$/
			) && do
				{
				delete $current_cell->{VALUE} ;
				
				my $sub_generator = $value->[0] ;
				my $formula = $value->[1] ;
				
				if(/^Spreadsheet::Perl::Formula$/)
					{
					$current_cell->{FORMULA} = $value ; # should we compile and check the formula directly?
					delete $current_cell->{PERL_FORMULA} ;
					}
				else
					{
					$current_cell->{PERL_FORMULA} = $value ;
					delete $current_cell->{FORMULA} ;
					}
				
				$current_cell->{FETCH_SUB_ARGS} = [(@$value)[2 .. (@$value - 1)]] ;
				$current_cell->{NEED_UPDATE}    = 1 ;
				$current_cell->{ANCHOR}         = $address ;
				($current_cell->{FETCH_SUB}, $current_cell->{GENERATED_FORMULA}) = $sub_generator->(
															  $self
															, $current_address
															, $address #anchor
															, $formula
															) ;
				last ;
				} ;
				
			/^Spreadsheet::Perl::Format$/ && do
				{
				@{$current_cell->{FORMAT}}{keys %$value} = values %$value ;
				last ;
				} ;
				
			/^Spreadsheet::Perl::Validator::Add$/ && do
				{
				push @{$current_cell->{VALIDATORS}}, [$value->[0], $value->[1]] ;
				last ;
				} ;
			
			/^Spreadsheet::Perl::Validator::Set$/ && do
				{
				$current_cell->{VALIDATORS} = [[$value->[0], $value->[1]]] ;
				last ;
				} ;
			
			/^Spreadsheet::Perl::StoreFunction$/ && do
				{
				delete $current_cell->{VALUE} ;
				
				$current_cell->{STORE_SUB_INFO} = $value->[0] ;
				$current_cell->{STORE_SUB}      = $value->[1] ;
				$current_cell->{STORE_SUB_ARGS} = [ @$value[2 .. (@$value - 1)] ] ;
				last ;
				} ;
				
			/^Spreadsheet::Perl::FetchFunction$/ && do
				{
				delete $current_cell->{VALUE} ;
				
				$current_cell->{FETCH_SUB_INFO}    = $value->[0] ;
				$current_cell->{FETCH_SUB}         = $value->[1] ;
				$current_cell->{FETCH_SUB_ARGS}    = [ @$value[2 .. (@$value - 1)] ] ;
				$current_cell->{NEED_UPDATE} = 1 ;
				last ;
				} ;
				
			/^Spreadsheet::Perl::UserData$/ && do
				{
				$current_cell->{USER_DATA} = {@$value} ;
				last
				} ;
				
			/^Spreadsheet::Perl::StoreOnFetch$/ && do
				{
				$current_cell->{STORE_ON_FETCH}++ ;
				last
				} ;
				
			/^Spreadsheet::Perl::DeleteFunction/ && do
				{
				$current_cell->{DELETE_SUB_INFO}    = $value->[0] ;
				$current_cell->{DELETE_SUB}         = $value->[1] ;
				$current_cell->{DELETE_SUB_ARGS}    = [ @$value[2 .. (@$value - 1)] ] ;
				last
				} ;
				
			/^Spreadsheet::Perl::Reference$/ && do
				{
				$current_cell->{IS_REFERENCE}  = 1 ;
				$current_cell->{REF_SUB_INFO}  = $value->[0] ;
				$current_cell->{REF_STORE_SUB} = $value->[1] ;
				$current_cell->{REF_FETCH_SUB} = $value->[2] ;
				$current_cell->{CACHE}         = 0 ;
				last
				} ;
				
			#----------------------
			# setting a value:
			#----------------------
			my $value_to_store = $value ; # do not modify $value as it is used again when storing ranges
			
			# check for range fillers
			if(/^Spreadsheet::Perl::RangeValues$/)
				{
				$value_to_store  = shift @$value  ;
				}
			else
				{
				if(/^Spreadsheet::Perl::RangeValuesSub$/)
					{
					$value_to_store = $value->[0]($self, $address, $current_address, @$value[1 .. (@$value - 1)]) ;
					}
				#else
					# store the value passed to STORE
				}
			
			if(exists $current_cell->{STORE_SUB})
				{
				if(exists $current_cell->{STORE_SUB_ARGS} && @{$current_cell->{STORE_SUB_ARGS}})
					{
					$current_cell->{STORE_SUB}->($self, $current_address, $value_to_store, @{$current_cell->{STORE_SUB_ARGS}}) ;
					}
				else
					{
					$current_cell->{STORE_SUB}->($self, $current_address, $value_to_store) ;
					}
				}
			else
				{
				# storing a simple value removes formulas

				delete $current_cell->{FORMULA} ;
				delete $current_cell->{PERL_FORMULA} ;
				delete $current_cell->{FETCH_SUB} ;
				delete $current_cell->{FETCH_SUB_ARGS} ;
				delete $current_cell->{GENERATED_FORMULA} ;
				delete $current_cell->{ANCHOR} ;

				$current_cell->{NEED_UPDATE} = 0 ;

				$current_cell->{VALUE} = $value_to_store ;
				}
				
			if(exists $current_cell->{REF_STORE_SUB})
				{
				$current_cell->{REF_STORE_SUB}->($self, $current_address, $value_to_store) ;
				}
			}
		
		if($self->{AUTOCALC} && exists $current_cell->{DEPENDENT} && $current_cell->{DEPENDENT})
			{
			$self->Recalculate() ;
			}

		if(exists $self->{DEBUG}{RECORD_STORE_ALL} || exists $self->{DEBUG}{RECORD_STORE}{$current_address})
			{	
			use Data::TreeDumper::Utils ;
			push @{$current_cell->{STORED_AT}}, Data::TreeDumper::Utils::get_caller_stack ;
			}
		}
	else
		{
		# not validated
		}
	}
}

*Set = \&STORE ;

#-------------------------------------------------------------------------------

sub MarkDependentForUpdate
{
my ($self, $current_cell, $cell_name, $level) = @_ ;

$level ||= 1 ;

return unless exists $current_cell->{DEPENDENT} ;

push @{$self->{DEPENDENT_STACK}}, [$self, $cell_name, $self->GetName()] ;

if(exists $current_cell->{CYCLIC_FLAG})
	{
	my $dh = $self->{DEBUG}{ERROR_HANDLE} ;

	my $full_cell_name = $self->GetName() . '!' . $cell_name ; 
	print $dh $self->DumpDependentStack("Cyclic dependency at '$full_cell_name' while marking cells for update\n") ;

	return ;
	}

$current_cell->{CYCLIC_FLAG}++ ;

for my $dependent_name (keys %{$current_cell->{DEPENDENT}})
	{
	if($level == 1 && (exists $self->{DEBUG}{MARK_ALL_DEPENDENT} || exists $self->{DEBUG}{MARK_DEPENDENT}{$cell_name}))
		{
		my $dh = $self->{DEBUG}{ERROR_HANDLE} ;
		my $spreadsheet_name = $self->GetName() || "$self" ;
		print $dh "$spreadsheet_name: '$cell_name' updated\n" ;
		}

	my $dependent = $current_cell->{DEPENDENT}{$dependent_name}{DEPENDENT_DATA} ;
	my ($spreadsheet, $cell_name) = @$dependent ;
	
	if(exists $spreadsheet->{CELLS}{$cell_name})
		{
		if(exists $current_cell->{CACHE} && $current_cell->{CACHE} == 0)
			{
			$spreadsheet->{CELLS}{$cell_name}{NEED_UPDATE}++ ;
			
			if(exists $self->{DEBUG}{MARK_ALL_DEPENDENT} || exists $self->{DEBUG}{MARK_DEPENDENT}{$cell_name})
				{
				my $dh = $self->{DEBUG}{ERROR_HANDLE} ;
				my $spreadsheet_name = $self->GetName() || "$self" ;
				print $dh ('   ' x $level) . "$spreadsheet_name: '$cell_name' needs update\n" ;
				}
			
			$spreadsheet->MarkDependentForUpdate($spreadsheet->{CELLS}{$cell_name}, $cell_name, $level+1) ;
			}
		else
			{
			if(exists $spreadsheet->{CELLS}{$cell_name}{FETCH_SUB})
				{
				$spreadsheet->{CELLS}{$cell_name}{NEED_UPDATE}++ ;
				
				if(exists $self->{DEBUG}{MARK_ALL_DEPENDENT} || exists $self->{DEBUG}{MARK_DEPENDENT}{$cell_name})
					{
					my $dh = $self->{DEBUG}{ERROR_HANDLE} ;
					my $spreadsheet_name = $spreadsheet->GetName() || "$self" ;
					print $dh ('   ' x $level) . "$spreadsheet_name: '$cell_name' needs update\n" ;
					}
				$spreadsheet->MarkDependentForUpdate($spreadsheet->{CELLS}{$cell_name}, $cell_name, $level+1) ;
				}
			else
				{
				delete $current_cell->{DEPENDENT}{$dependent_name} ;
				}
			}
		}
	else
		{
		delete $current_cell->{DEPENDENT}{$dependent_name} ;
		}
	}

pop @{$self->{DEPENDENT_STACK}} ;

delete $current_cell->{CYCLIC_FLAG} ;
}

#-------------------------------------------------------------------------------

sub InvalidateCellInDependent
{

my ($self, $cell_address) = @_ ;

my $dependent_name = $self->GetName() . '!' . $cell_address ;

for my $current_address ($self->GetCellList())
	{
	if(exists $self->{CELLS}{$current_address}{DEPENDENT})
		{
		if(exists $self->{CELLS}{$current_address}{DEPENDENT}{$dependent_name})
			{
			delete $self->{CELLS}{$current_address}{DEPENDENT}{$dependent_name} ;
			}
		}
	}
}

#-------------------------------------------------------------------------------

sub DELETE   
{
my $self    = shift ;
my $address = shift ;

for my $current_address ($self->GetAddressList($address))
	{
	if(exists $self->{CELLS}{$current_address}{DELETE_SUB})
		{
		if($self->{CELLS}{$current_address}{DELETE_SUB}->($self, $current_address, @{$self->{CELLS}{$current_address}{DELETE_SUB_ARGS}}))
			{
			$self->MarkDependentForUpdate($self->{CELLS}{$current_address}, $current_address) ;

			$self->InvalidateCellInDependent($current_address) ;

			delete $self->{CELLS}{$current_address} ;
			}
		}
	else
		{
		$self->MarkDependentForUpdate($self->{CELLS}{$current_address}, $current_address) ;
		
		$self->InvalidateCellInDependent($current_address) ;

		delete $self->{CELLS}{$current_address} ;
		}
	}
}

sub CLEAR 
{
my $self    = shift ;
my $address = shift ;

delete $self->{CELLS} ; 
# Todo: must call all set functions! and delete? functions? !!!!
}

sub EXISTS   
{
my $self    = shift ;
my $address = shift ;

for my $current_address ($self->GetAddressList($address))
	{
	unless(exists $self->{CELLS}{$current_address})
		{
		return(0) ;
		}
	}
	
return(1) ;
}

sub FIRSTKEY 
{
my $self = shift ;
scalar(keys %{$self->{CELLS}}) ;

return scalar each %{$self->{CELLS}} ;
}

sub NEXTKEY  
{
my $self = shift;
return scalar each %{ $self->{CELLS} }
}

sub DESTROY  
{
}

#-------------------------------------------------------------------------------

sub LockValidator
{
my $self    = shift ;
my $address = shift ;
my $cell    = shift ;
my $value   = shift ;

if($self->{LOCKED})
	{
	carp "While setting '$address': Spreadsheet lock is active" ;
	return(0) ;
	}
else
	{
	if($self->IsCellLocked($address))
		{
		carp "While setting '$address': Cell lock is active" ;
			
		return(0) ;
		}
	else
		{
		return(1) ;
		}
	}

}

#-------------------------------------------------------------------------------

1 ;

__END__
=head1 NAME

Spreadsheet::Perl - Pure Perl implementation of a spreadsheet engine

=head1 SYNOPSIS

  use Spreadsheet::Perl;
  use Spreadsheet::Perl::Arithmetic ;

  my $ss = tie my %ss, "Spreadsheet::Perl"

  $ss->SetNames("TEST_RANGE" => 'A5:B8') ;
  $ss{TEST_RANGE} = '7' ;
  
  DefineSpreadsheetFunction('AddOne', \&AddOne) ;
  
  $ss{A3} = PerlFormula('$ss->AddOne("A5") + $ss{A5}') ;
  print "A3 formula => " . $ss->GetFormulaText('A3') . "\n" ;
  print "A3 = $ss{A3}\n" ;

  $ss{'ABC1:ABD5'} = '10' ;

  $ss{A4} = PerlFormula('$ss->Sum("A5:B8", "ABC1:ABD5")') ;
  print "A4 = $ss{A4}\n" ;
  
  ...

=head1 DESCRIPTION

Spreadsheet::Perl is a pure Perl implementation of a spreadsheet engine. 

Spreadsheet::Perl functionality:

=over 2

=item * set and get values from cells or ranges

=item * handle cell private data

=item * has fetch/store callback

=item * has cell attributes access

=item * has cell/range fillers (auto-fill functionality)

=item * set formulas (pure perl and common format) 

=item * compute the dependencies between cells 

=item * formulas can fetch data from multiple spreadsheets and the dependencies still work

=item * checks for circular dependencies

=item * debugging triggers

=item * has a simple architecture for expansion

=item * has a simple architecture for debugging (and some flags are already implemented)

=item * can read its data from a file

=item * supports cell naming

=item * cell and range locking

=item * input validators

=item * cell formats (pod, HTML, ...)

=item * can define spreadsheet functions from the scripts using it or via a new module of your own

=item * Recalculate() / AUTOCALC

=item * value caching to speed up formulas and 'volatile' cells

=item * cell address offsetting functions

=item * Automatic formula offsetting

=item * Insertion of rows and columns (doesn't support interspreadsheet formulas)

=item * Relative and fixed cell addresses

=item * slice access

=item * Perl scalar mapping to a cell

=item * some debugging tool (dump, dump table, dump to HTML, formula stack trace, ...)

=back

Lots of examples in the 'examples' directory.

=head1 DRIVING FORCE

=head2 Why

I found no spreadsheet modules on CPAN.

I you have an application that takes some input and does calculation on them, chances
are that implementing it through a spreadsheet will make it more maintainable and easier to develop.
Here are the reasons (IMO) why:

=over 2

=item * Spreadsheet programming (SP) is data oriented and this is what programming should be.

=item * SP is encapsulating. The processing is "hidden"behind the cell value in form of formulas.

=item * SP is encapsulating II. The data dependencies are automatically computed by the spreadsheet, relieving 
you from keeping things in synch

=item * SP is 2 dimensional (or 3 or 4), specially if you have a GUI  for it.

=item * If you have a GUI, SP is visual programming and visual debugging as the 
spreadsheet is the input and the dump of the data. The possibility to to 
show a multi-dimensional dependency is great as is the fact that you don't 
need to look around for where things are defined (this is more about 
visual programming but still fit spreadsheets as they are often GUI based)

=item * SP allows for user customization 

=back

=head2 How

I want B<Spreadsheets::Perl> to:

=over 2

=item * Be very Perlish

=item * Be easy to expand

=item * Be easy to use for Perl programmers

=back 

=head1 CREATING A SPREADSHEET

Spreadsheet perl is implemented as a tie. Remember that you can use hash slices (I 'll give some examples). The
spreadsheet functions are accessed through the tied object.

=head2 Simple creation

  use Spreadsheet::Perl ;
  my $ss = tie my %ss, "Spreadsheet::Perl" ; 

=head2 Setting up data

=head3 Setting the cell data

  use Spreadsheet::Perl ;
  tie my %ss, "Spreadsheet::Perl"
		, CELLS =>
				{
				  A1 =>
						{
						VALUE => 'hi'
						}
					
				, A2 =>
						{
						VALUE => 'there'
						#~ or
						#~ PERL_FORMULA => [undef, '$ss{A1}']
						}
				} ;


=head3 Setting the cell data, simple way

  use Spreadsheet::Perl ;
  tie my %ss, "Spreadsheet::Perl"
  @ss{'A1', 'B1:C2', 'A8'} = ('A', 'B', 'C');

=head3 Setting the spreadsheet attributes

  use Spreadsheet::Perl ;
  tie my %ss, "Spreadsheet::Perl"
		  , NAME => 'TEST'
		  , DEBUG => { PRINT_FORMULA => 1} ;


=head2 reading, cell only,  data from a file

  <- start of ss_setup.pl ->
  # how to compute the data
  
  sub OneMillion
  {
  return(1_000_000) ;
  }
  
  #-----------------------------------------------------------------
  # the spreadsheet data
  #-----------------------------------------------------------------
  A1 => 120, 
  A2 => sub{1},
  A3 => PerlFormula('$ss->Sum("A1:A2")'),
  
  B1 => 3,
  
  c2 => "hi there",
  
  D1 => OneMillion()
  
  <- end of ss_setup.pl ->

  use Spreadsheet::Perl ;
  tie my %ss, "Spreadsheet::Perl", NAME => 'TEST' ;
  %ss = do "ss_setup.pl" or confess "Couldn't read setup file 'ss_setup.pl'" ;


=head2 insertion and deletion of rows and columns

Right now, SS::P will B<ONLY> properly handle insertion/deletion
within a single spreadsheet. That is, if you have multiply linked
spreadsheets, do not use insertion/deletion. This is B<not> automatically checked!

This is a temporary limitation and it will be removed.

If you use a spreadsheet that does not reference another spreadsheet, using
insertion/deletion will update Perl formulas and dependencies just fine.

=head2 dumping a spreadsheet

Use the Dump function (see I<Debugging>):

  my $ss = tied %ss ;
  ...
  print $ss->Dump() ;

Generates:
  
  ------------------------------------------------------------
  Spreadsheet::Perl=HASH(0x825540c) 'TEST' [3550 bytes]
  
  Cells:
  |- A1
  |  `- VALUE = 120
  |- A2
  |  `- VALUE = CODE(0x82554d8)
  |- A3
  |  |- ANCHOR = A3
  |  |- FETCH_SUB = CODE(0x825702c)
  |  |- FETCH_SUB_ARGS
  |  |- PERL_FORMULA = Object of type 'Spreadsheet::Perl::PerlFormula'
  |  |  |- 0 = CODE(0x923752c)
  |  |  `- 1 = $ss->Sum("A1:A2")
  |  |- GENERATED_FORMULA = $ss->Sum("A1:A2")
  |  `- NEED_UPDATE = 1
  |- B1
  |  `- VALUE = 3
  |- C2
  |  `- VALUE = hi there
  `- D1
     `- VALUE = 1000000
  
  Spreadsheet::Perl=HASH(0x825540c) 'TEST' dump end
  ------------------------------------------------------------

=head2 reading and writing  a spreadsheet from a file

Version 0.06 has, prototype, functionality to read and write spreadsheets. Serializing of common format formulas are also supported.

  use Spreadsheet::Perl ;
  
  my $ss = tie my %ss, "Spreadsheet::Perl" ;

  $ss->Read('ss_data.pl') ;

  print $ss->DumpTable() ;
  
  $ss->Write('generated_ss_data.pl') ;

  undef $ss ;
  untie %ss ;
  
  $ss = tie %ss, "Spreadsheet::Perl" ;
  $ss->Read('generated_ss_data.pl') ;
  
  print $ss->DumpTable() ;

You can find a small example in I<examples/read_write.>. See also: L<Function definition> bellow.

=head2 Dumping a table

Håkon Nessjøen (author of Text::ASCIITable) was nice enough to contribute a module to dump 
the spreadsheet in table form.

The functionality can be access through two, equivalent, function names: I<DumpTable> (an alias) and I<GenerateASCIITable>.
The functions take the following arguments:

=over 2

=item 1- a list of ranges within an array reference or 'undef' for the whole spreadsheet

=item 2- a boolean, when set, the spreadsheet attributes are also displayed

=item 3- options passed to Text::ASCIITable

=item 4- arguments passed to Text::ASCIITable::draw

=back

Most of the time you'll call I<DumpTable> without argument or with the first argument set.

  print $ss->DumpTable() ;
  
  generates :
  
  .----------------------------------------------------.
  | @  | A   | B   | C   | D   | E   | F   | G   | H   |
  |====================================================|
  | 1  | A1  | B1  | C1  | D1  | E1  | F1  | G1  | H1  |
  |----+-----+-----+-----+-----+-----+-----+-----+-----|
  | 2  | A2  | B2  | C2  | D2  | E2  | F2  | G2  | H2  |
  |----+-----+-----+-----+-----+-----+-----+-----+-----|
  | 3  | A3  | B3  | C3  | D3  | E3  | F3  | G3  | H3  |
  |----+-----+-----+-----+-----+-----+-----+-----+-----|
  ...
  ...
  |----+-----+-----+-----+-----+-----+-----+-----+-----|
  | 10 | A10 | B10 | C10 | D10 | E10 | F10 | G10 | H10 |
  '----------------------------------------------------'
  
  print $ss->DumpTable(['B4:C5', 'A2:B6', 'NAMED_RANGE']) ;
  
  .-------------.
  | @ | B  | C  |
  |=============|
  | 4 | B4 | C4 |
  |---+----+----|
  | 5 | B5 | C5 |
  '-------------'
  
  .-------------.
  | @ | A  | B  |
  |=============|
  | 2 | A2 | B2 |
  |---+----+----|
  | 3 | A3 | B3 |
  |---+----+----|
  | 4 | A4 | B4 |
  |---+----+----|
  | 5 | A5 | B5 |
  |---+----+----|
  | 6 | A6 | B6 |
  '-------------'
  
  .-------------------------------------------------------.
  | @ | A  | B  | C  | D  | E  | F  | G  | H  | I | J | K |
  |=======================================================|
  | 4 | A4 | B4 | C4 | D4 | E4 | F4 | G4 | H4 |   |   |   |
  |---+----+----+----+----+----+----+----+----+---+---+---|
  | 5 | A5 | B5 | C5 | D5 | E5 | F5 | G5 | H5 |   |   |   |
  '-------------------------------------------------------'
  
  print $ss->DumpTable
  		(
  		  undef
  		, undef 
  		, {
  		    alignHeadRow => 'center',
  		  , headingText  => 'Some Title'
  		  }
  		) ;

  .------------------------------------------------------.
  |                      Some Title                      |
  |======================================================|
  | @ |                     A                    | B | C |
  |======================================================|
  | 1 | datadatadatadatadatadatadatadatadatadata | B | B |
  |---+------------------------------------------+---+---|
  | 2 | datadatadatadatadatadatadatadatadatadata | B | B |
  |---+------------------------------------------+---+---|
  | 3 | datadatadatadatadatadatadatadatadatadata |   |   |
  |---+------------------------------------------+---+---|
  | 4 | datadatadatadatadatadatadatadatadatadata |   |   |
  |---+------------------------------------------+---+---|
  | 5 | datadatadatadatadatadatadatadatadatadata |   |   |
  |---+------------------------------------------+---+---|
  | 6 |                                          |   |   |
  |---+------------------------------------------+---+---|
  | 7 |                                          |   |   |
  |---+------------------------------------------+---+---|
  | 8 | C                                        |   |   |
  '------------------------------------------------------'

It is possible to give a page width. if the page width is not set, the screen width is used.
If there is no screen width available (redirecting to a file for example) B<78> is used as a width.

  print $ss->DumpTable(['A4:O5'], undef, {pageWidth => 40}) ;
  
  .--------------------------------------------
  | @ | A  | B  | C  | D  | E  | F  | G  | H  |
  |============================================
  | 4 | A4 | B4 | C4 | D4 | E4 | F4 | G4 | H4 |
  |---+----+----+----+----+----+----+----+----+
  | 5 | A5 | B5 | C5 | D5 | E5 | F5 | G5 | H5 |
  '--------------------------------------------
  'TEST' 1/4.
  
  .--------------------------------
  | @ | I | J | K | L | M | N | O |
  |================================
  | 4 |   |   |   |   |   |   |   |
  |---+---+---+---+---+---+---+---|
  | 5 |   |   |   |   |   |   |   |
  '--------------------------------
  'TEST' 2/4.

  ...
  
You can set the 'noPageCount' option if you don't want the page count.

Note:
If $ss->{DEBUG}{PRINT_DEPENDENT_LIST} is set, the cells depending
on a specific cell are listed in the inline information ( a reverse
dependency list)

To make sure the dependent list is up to date before display,
Recalculate() is called before dumping the spreadsheet.

See B<Text::ASCIITable>.

=head1 CELL and RANGE: ADDRESSING, NAMING

Cells are index  with a scheme I call baseAA (please let me know if it has a better name).
A cell address is a combination of letters and a figure, ex: 'A1', 'BB45', 'ABDE15'.

BaseAA figures match /[A-Z]{1,4}/. see B<Spreadsheet::ConvertAA>. There is no limit on the numeric figure.
Spreadsheet::Perl is implemented as a hash thus allowing for sparse spreadsheets.

=head2 Address format

Addresses are composed of:

=over 2

=item * an optional spreadsheet name and '!'. ex: 'TEST!'

=item * a baseAA1 figure. ex 'A1'

=item * a ':' followed by a baseAA1 figure for ranges. ex: ':A5'

=back

The following are valid addresses: A1 TEST!A1 A1:BB5 TEST!A5:CE43

For a range, the order of the baseAA figures is important!

  $ss{'A1:D5'} = 7; is equivalent to $ss{'D5:A1'} = 7; 

but

  $ss{'A1:D5'} = PerlFormula('$ss{H10}'); is NOT equivalent to $ss{'D5:A1'} = PerlFormula('$ss{H10}'); 
  
because formulas are regenerated for each cell. Spreadsheet::Perl goes from the first baseAA figure
to the second one by iterating the row, then the column.

It is also possible to index cells with numerals only: $ss{"1,7"}. Remember that A is 1 and there are
no zeros.

=head2 Names

It is possible to give a name to a cell or to a range: 

  my $ss = tie my %ss, "Spreadsheet::Perl" ;
  @ss{'A1', 'A2'} = ('cell A1', 'cell A2') ;
  
  $ss->SetCellName("FIRST", "A1") ;
  print  $ss{FIRST} . ' ' . $ss{A2} . "\n" ;
  
  $ss->SetRangeName("FIRST_RANGE", "A1:A2") ;
  print  "First range: @{$ss{FIRST_RANGE}}\n" ;

Names must be upper case.

Note that, for the moment, column/row insertion and deletion do not
work with cell/range names. Or, more exactely, SS:P can not change cell
addresses in named range. IE: after insertion of a row, formula "$ss{B4}" may become "$ss{C4}". if cell B4 had the name "MYCELL", SS:P could not modify the formula "$ss{MYCELL}". In future version, we may choose between replacing MYCELL with a cell address automatically or invalidate all the cells containing a named address that is influenced by a column/row insertion/deletion. 

=head1 LABELING ROW AND COLUMN HEADERS

	$ss{A0} = 'column A' ;
	$ss{B0} = 'column B' ;
	$ss{@1} = 'row 1' ;
	$ss{@2} = 'row 2' ;

The subs B<label_column> and B<label_row> can also be used.

	$ss->label_column('A' => "First column") ;
	$ss->label_row(1 => 'row 1') ;
	$ss->label_row(2 => 'row 2') ;
	
=head1 OTHER SPREADSHEET

To use inter-spreadsheet formulas, you need to make the spreadsheet aware of the other spreadsheets by
calling the I<AddSpreadsheet> function.

  tie my %romeo, "Spreadsheet::Perl", NAME => 'ROMEO' ;
  my $romeo = tied %romeo ;

  tie my %juliette, "Spreadsheet::Perl", NAME => 'JULIETTE' ;
  my $juliette = tied %juliette ;

  $romeo->AddSpreadsheet('JULIETTE', $juliette) ;
  $juliette->AddSpreadsheet('ROMEO', $romeo) ;
  
  $romeo{'B1:B5'} = 10 ;
  
  $juliette{A4} = 5 ;
  $juliette{A5} = PerlFormula('$ss->Sum("JULIETTE!A4") + $ss->Sum("ROMEO!B1:B2")') ; 

=head1 SPREADSHEET Functions

=head2 Locking

Locking the spreadsheet:

  tie my %ss, "Spreadsheet::Perl", LOCKED => 1 ;
  $ss->Lock() ;
  $ss->Lock(1) ;
  
Unlocking the spreadsheet:

  $ss->Lock(0) ;

=head2 Locking a Range
  
Locking a range:

  LockRange('A1:B6') ;
  LockRange('A1:B6', 1) ;

Unlocking a range:

  LockRange('A1:B6', 0) ;

=head2 Cache

Spreadsheet::Perl caches the result of the formulas and recalculates cell values only when needed.

=head2 Calculation control

Spreadsheet::Perl computes the value of a cell (see B<Cache> above) when the cell is accessed.
If a cell A1 depends on cell A2 and cell A2 is modified, the value of cell A1 is not updated until it is 
accessed. If you want to update all the cell (in need of being updated) use:

  $ss->Recalculate() ;

This comes handy if you want to flush the result to a database linked to the spreadsheet

It is possible to force the recalculation of the spreadsheet every time a cell with dependent is set:

  tie my %ss, "Spreadsheet::Perl", AUTOCALC => 1 ;
  $ss->SetAutocalc() ;
  $ss->SetAutocalc(1) ;

Turning off auto recalculation:

  $ss->SetAutocalc(0) ;


AUTOCALC is set to 0 by default.

=head2 Function definition

Spreadsheet::Perl comes with a single formula function defined (Sum).

Spreadsheet::Perl uses perl arithmetics so all the functions available in perl are available to you. You can define 
your own functions.

  sub AddOne
  {
  my $ss = shift ;
  my $address = shift ;
  
  return($ss->Get($address) + 1) ;
  }
  
  DefineSpreadsheetFunction('AddOne', \&AddOne) ;

  $ss{A3} = PerlFormula('$ss->AddOne("A1") + $ss{A2}') ;

Sub AddOne is now available in all your spreadsheets.

DefineSpreadsheetFunction takes the following parameters:

=over 2

=item 1 - A function name

=item 2 - A sub reference or undef if item 3 is defined

=item 3 - A text representation for the function (for file serialization)

=item 2 - A module name (for file serialization)

=back

The sub will be passed a reference to the spreadsheet object as first argument. The other argument are those you
pass to the function in your formula.

=head3 Function collections

If you implement more than a few formula functions, you may want to move those functions into a perl module.
"use" Spreadsheet::Perl in your module and register your functions through B<DefineSpreadsheetFunction>.

  package MyPackageName ;
  
  sub DoSomething{}
  
  AddSpreadsheetFunction('DoSomething', \&DoSomething, undef, __PACKAGE__) ;
  
Later in a script:

  use Spreadsheet::Perl ;
  use MyPackageName ;
  
  # DoSomething is now available within formulas
  $ss{A1} = PF('$ss->DoSomething('A2:A3', 'arg2', 'arg3')') ;
  ...
  $ss->Write('somefile.pl') ; # serializes the formula and "MyPackageName" module name in the file.
  
The saved file will now "use" MyPackageName automaticaly when you read the file.


B<Please contribute your functions to Spreadsheet::Perl>.

=head2 Misc spreadsheet functions

=over 2

=item * SetName, sets the name of the spreadsheet object

=item * GetName, returns the name of the spreadsheet object

=item * GetCellList, returns the list of the defined cells

=item * GetLastIndexes, returns the last column and the last row used

=item * GetCellsToUpdate, returns the list of the cells needing update

=back

=head1 SETTING AND READING CELLS

Cells have one value and attributes. Cells values are perl scalars, anything you can assign to a perl scalar can be assigned
to a cell value (see bellow for the one exception). Attributes have different format and are handled by the spreadsheet.

=head2 Setting a value

Anything that can be assigned to a perl variable can be assigned to a cell with the exception of object rooted in
"Spreadsheet::Perl" which are reserved and carry a special meaning.

  $ss{A1} = 458_627 ;
  $ss{A1} = undef ;
  $ss{A1} = '' ;
  $ss{A1} = function_call() ; # assign the value returned from the call
  $ss{A1} = \&Function ;
  $ss{A1} = \@_ ;
  
  $ss{A1} = $object_within_spreadsheet_perl_hierarchy ; # this is valid but may (and will) carry a special meaning.

  $ss->Set('A1', "some value') ; # OO style
  
=head2 locking

Cell locking is done through the I<LockRange> function:

  $ss->LockRange('A1') ;
  
Finding out the lock state of a cell:

  $cell_is_locked = $ss->IsCellLocked('A1') ;

=head2 Formulas

=head3 cell dependencies

Cell dependencies are automatically handled by Spreadsheet::Perl. If a dependency is changed,
the formula will be re-evaluated next time the cell, containing the formula, is accessed.

=head3 circular dependencies

If circular dependencies between cells exist, Spreadsheet::Perl will generate a dump of the cycle as well
as a perl stack dump to help you debug your formulas. The following formulas:

  $ss{'A1:A5'} = PerlFormula('$ss{"A2"}') ; #automatic address offsetting
  $ss{A6} = PerlFormula('$ss{A1}') ;
  print "$ss{A1}\n" ;

generate:

  -----------------
  Spreadsheet::Perl=HASH(0x813d234) 'TEST' Dependent stack:
  -----------------
  TEST!A1 : $ss->Get("A2")[main] cyclic_error.pl:18
  TEST!A2 : $ss->Get("A3")[main] cyclic_error.pl:18
  TEST!A3 : $ss->Get("A4")[main] cyclic_error.pl:18
  TEST!A4 : $ss->Get("A5")[main] cyclic_error.pl:18
  TEST!A5 : $ss->Get("A6")[main] cyclic_error.pl:18
  TEST!A6 : $ss->Get("A1")[main] cyclic_error.pl:19
  TEST!A1 : $ss->Get("A2")[main] cyclic_error.pl:18
  -----------------
  
  At cell 'TEST!A6' formula: $ss->Get("A1") defined at 'main cyclic_error.pl 19':
  	Found cyclic dependencies! at /usr/local/lib/perl5/site_perl/5.8.0/Spreadsheet/Perl.pm line 242.
  #ERROR

=head3 setting a formula

Formulas can be written in different formats. The native format is perl code. There seems
to be a consensus about what standard format the formulas should use, I call that format "common format".

=head4 Native format

B<PerlFormula> and B<PF> take a string as argument. The string must be a valid Perl code.

B<PerlFormula> can be used as a member function and define multiple formulas in one call

  $ss->PerlFormula
  	(
  	  'B1'    => '$ss{A1} + $ss{A2}'
  	, 'B2'    => '$ss{A4} + $ss{A3}'
  	, 'B3:B5' => '$ss{A4} + $ss{A3}'
  	) ;
  	
or it can used to set a cell or a cell range formula.

  $ss{'A1:A5'} = PerlFormula('$ss{"A2"}') ;

  $ss{'A1'} = PerlFormula('ANY VALID PERL CODE') ;

When used with a cell or a cell range, extra user data can be passed

  $ss{'A1'} = PF('PERL CODE', \$user_data, $more_user_date, 42, "something") ;

The formulas can also be part of the Spreadsheet dump

  $ss->{DEBUG}{INLINE_INFORMATION}++ ; # show the formulas in the table dump
  print $ss->DumpTable() ;:

=head5 Variables available in a formula

The following variables are available in the formula:

=over 2

=item * $ss, a spreadsheet object reference

=item * %ss, a hash tied to the spreadsheet object

=item * $cell, the address of the cell for which the formula is evaluated

=item * @formula_arguments, extra user data passed to PF() in cell mode

=back

=head5 Automatic cell address offsetting

If a range is assigned a formula, the cell addresses within the formulas are automatically offseted, fixed
address element can be protected by square brackets.

  # formula 1
  $ss{'C1:C2'} = PerlFormula('$ss->Sum("A1:A2")') ;
  
  Formula definition (anchor'C1:C2' @ cell 'C1'): $ss->Sum("A1:A2")
  generated formula => $ss->Sum("A1:A2")
  
  Formula definition (anchor'C1:C2' @ cell 'C2'): $ss->Sum("A1:A2")
  generated formula  => $ss->Sum("A2:A3")
  
  # formula 2
  $ss{'D1:E2'} = PerlFormula('$ss->Sum("[A]1:A[3]")') ;
  
  Formula definition (anchor'D1:E2' @ cell 'D1'): $ss->Sum("[A]1:A[3]")
  generated formula => $ss->Sum("A1:A3")
  
  Formula definition (anchor'D1:E2' @ cell 'D2'): $ss->Sum("[A]1:A[3]")
  generated formula => $ss->Sum("A2:A3")
  
  Formula definition (anchor'D1:E2' @ cell 'E1'): $ss->Sum("[A]1:A[3]")
  generated formula => $ss->Sum("A1:B3")
  
  Formula definition (anchor'D1:E2' @ cell 'E2'): $ss->Sum("[A]1:A[3]")
  generated formula => $ss->Sum("A2:B3")

=head4 common format

This is the format accepted by excel and gnumeric. I will _not_ implement that format because:

  =SUM(IF(A2:A20=A2,IF(B2:B20=38,1,0)))

is about the ugliest a formula language can get. Is all this user friendly syntax only because
someone thought it was too difficult to present a mutiline editor to the end user?
  
If Someone feels that the common format (or any other language) is more "appropriate" than Perl and 
contributes a translator, I'll be happy to add it to the distribution.

Steffen Müller (author of Math::Symbolic) was nice enough to contribute a translator for the 0.07 release. This doesn't make 
Spreadsheet::Perl compatible with Gnumeric but goes a long way towards that goal.

  $ss->Formula
	(
	  B1      => 'cos(A1 + A2)'
	, B2      => 'A4 + A3'
	, 'B3:B5' => 'log(A4) + A3'
	, 'B6:b7' => 'Sum(A4:A5) + Sum(A3)'
	, B8      => 'log(Sum(A4:A5)) + log(A3)'
	) ;

Examples of translation:

  SSHEET!A1:BB15 => $ss{'SSHEET!A1:BB15'}

  SSHEET!A1 => $ss{'SSHEET!A1'}

  2*Sum(SSHEET!A1:AD4)+log(A5) => ((2 * $ss->Sum('SSHEET!A1:AD4')) + log($ss{'A5'}))

  Function(Sum(SSHEET!A1:B1)^cos(Sum(SSHEET!NAMEDRANGE))) =>
  $ss->Function(($ss->Sum('SSHEET!A1:B1') ** cos($ss->Sum('SSHEET!NAMEDRANGE'))))

Note that some functions are translated as class functions ('Sum' in the example above) and other as global functions
('log' in the example above). Spreadsheet::Perl doesn't define any global functions (this will certainly change when I 
have time to go through this). The funtions bellow let manipulate the global functions. Spreadsheet::Perl will re-compile the
translator as needed.

=over 2

=item * SetBuiltin. Sets the list of the declared functions.

  SetBuiltin qw( atan ) ; # only 'atan' is available now

=item * AddBuiltin, adds one or more functions to the global functions declarations.

  AddBuiltin qw( log sin cos ) ;
  
=item * GetBuiltin, Returns the list of the declared functions.

  my @declared_builtin = GetBuiltin() ;

=back

Common format formulas come at a cost. To translate the formula, Parse::Recdescent must be loaded 
(that times at 0.25s on my 700 MHz box), the grammar must be compiled and the formulas translated.
This can amout to seconds when compared to pure perl formulas. Nevertheless, this is very good to experiment 
with. If needed, the parser can be tinkered with or re-written in C. Once the formulas are translated, you get
the same speed as the perl format formulas.

=head3 RangeValues

There are different way to assign values to a range.

  $ss{'A1:A5'} = 5 ; # all the cells within the range have "5" as value.
  @ss{'A1', 'A2', 'A3', 'A4', 'A5'} = (10 .. 15) ; # perl slice notation 
  $ss{'A1:A5'} = RangeValues(10 .. 15) ;
  
  $ss{'A1:A5'} = RangeValuesSub(\my_sub, $argument_1, $argument_2) ;
  
=head3 RangeValuesSub

B<RangeValuesSub> is passed the following arguments:

=over 2

=item 1 - a sub reference

=item 2 - an optional list of arguments

=back

The sub is called, multiple times, to fill the cell of ranges. It is passed these arguments:

=over 2

=item 1 - a reference to the spreadsheet

=item 2 - an anchor (the first cell of the range)

=item 3 - the address of the cell to generate a value for

=item 4 - the optional list of arguments passed to RangeValuesSub

=back

I<RangeValuesSub> can be used when the values are to be generated dynamically or could be used to create
'Auto-fill' functionality.

=head2 Setting formats

the cell formats are hold within a hash, you can set as many different formats as you wish. Your format can be
a complex perl structure, B<Spreadsheet::Perl> only handle the first level of the hash:

  $ss{A1} = Format(ANSI => {HEADER => "blink"}) ;
  $ss{A1} = Format(ANSI => {HEADER => "red_on_black"}) ; # override previous
  $ss{A1} = Format(POD => {FOOTER => "B<>"}) ; # add this format to cell A1

The format data must be passed as a perl hash reference.

=head2 Setting Validators

a Validator is defined in this way:

  $ss{'A1:A2'} = Validator('only letters', \&OnlyLetters) ;

I<Validator>, removes all previously set validators and sets the validator passed as argument.
I<Validator> takes these arguments:

=over 2

=item 1 - a name

=item 2 - a sub reference

=item 3 - an optional list of arguments

=back

A cell can have multiple validators. use I<ValidatorAdd> to append new validators.

Validators are passed the following arguments:

=over 2

=item 1 - a reference to the spreadsheet

=item 2 - the address of the cell to be set

=item 3 - a reference to the cell to be set

=item 4 - the optional list of arguments passed to I<Validator[Add]>

=back

The value is set if all the cell validators return true. B<Spreadsheet::Perl> is silent, your validator has to
give the user feedback.

=head2 Setting User data

You can store private data into the cell. It is out of limits for B<Spreadsheet::Perl>. the user data is stored in a hash.

  $ss{A1} = UserData(NAME => 'private data', ARRAY => ['hi']) ;

=head2 Setting fetch and store callbacks

You can map your own set of Fetch and Store data from/in  a cell. You will be working with the spreadsheet internals.

=head3 Fetch callback

I recommend that you don't use this system to compute values depending on other cells; the dependency mechanism
will still work but it is better to use formula so it will still work when row/columns deleting/inserting is
implemented. This mechanism is still very useful when you need to access a value that changes between cell 
access and is not depending on other cells. The description field is displayed when generating a table and 
$ss->{DEBUG}{INLINE_INFORMATION} is set, that can be of a great help when debugging your spreadsheet.

  $ss{A1} = FetchFunction('some description', \&MySub) ;

B<FetchFunction> takes these arguments

=over 2

=item 1 - a description string

=item 2 - a sub reference

=item 3 - an optional list of arguments

=back

The following arguments are passed to the fetch callback

=over 2

=item 1 - a reference to the spreadsheet

=item 2 - the address of the cell 

=item 3 - the optional list of arguments passed to FetchFunction

=back

=head4 Caching (volatile cells)

B<Spreadsheet::Perl> caches cell values (and updates them when a dependency has changed). If you want a cell to return a 
different value every time it is accessed (when using AUTOCALC = 0 and Recalculate for example), you need to turn caching
off for that cell. 

  ${A1} = NoCache() ;

=head3 Store callback

You can also attach a 'store' sub to a cell. whenever the cell is assigned a value, your sub will be called.

  $ss{'A1:A5'} = StoreFunction('description', \&StorePlus, 5) ;

B<StoreFunction> takes the following arguments:

=over 2

=item 1 - a description string

=item 2 - a sub reference

=item 3 - an optional list of arguments to be passed when the callback is, well, called.

=back

The callback is called with these arguments

=over 2

=item 1 - a spreadsheet object reference

=item 2 - the address of the cell to set

=item 3 - the value to store

=item 4 - the, optional, arguments passed to StoreFunction

=back

Your store callback must store the data directly in the spreadsheet data structure without calling the Store/Set functions.
You can find a typical implementation in the examples.

=head3 Delete callback

You can also attach a 'delete' sub to a cell. Your sub will be called when the cell is deleted.

  $ss{'A1:A5'} = DeleteFunction('description', \&DeleteCallback, 1, 2, 3) ;

B<StoreFunction> takes the following arguments:

=over 2

=item 1 - a description string

=item 2 - a sub reference

=item 3 - an optional list of arguments to be passed when the callback is, well, called.

=back

The callback is called with these arguments

=over 2

=item 1 - a spreadsheet object reference

=item 2 - the address of the cell to set

=item 3 - the, optional, arguments passed to StoreFunction

=back

=head2 Perl scalar mapping

Few problems fit the two dimensional mapping spreadsheets use. For a given project, you may already have data structure 
that you want to perform calculation on (thought spreadsheet). Mapping from the domain structure and back is time consuming,
error prone and borring. Even if that process cannot be eliminated, B<Spreadsheet::Perl> can do half the job. Here is a simple example:

  my $variable = 25 ;
  
  $ss{A1} = Ref('description', \$variable) ;
  $ss{A2} = PerlFormula('$ss{A1}') ;
  
  print "$ss{A1} $ss{A2}\n" ; # fetch the data from the scalar variable
  
  $ss{A1} = 52 ; # set the scalar
    
  print "\$variable = $variable\n" ;

B<Ref> can be called as attribute creator (as above) or as a spreadsheet member (as bellow).

  $ss->Ref
	(
	'description',
	'A1'      => \($struct->{something}), 
	'A2'      => \$variable,
	'A3:A5' => \$variable
	) ;

$ss->get_reference_description('A1') or $ss->REF_INFO('A1') can be used to retrieve the description field of cell, eg, A1.

A more complex example (based on examples/ref2.pl) which also show the usage of debug flags

	use strict ;
	use warnings ;

	use Data::TreeDumper ;
	use Spreadsheet::Perl ;

	my $ss = tie my %ss, "Spreadsheet::Perl", NAME => 'TEST' ;

	# set some debugging flags so we can see what is happening in the spreadsheet

	# show when a value is fetched from one of the following cells
	# we could also have used "$ss->{DEBUG}{FETCH}++; " but it doesn't show the details of the fetch operation
	$ss->{DEBUG}{FETCH_TRIGGER}{A1}++ ;
	$ss->{DEBUG}{FETCH_TRIGGER}{A2}++ ;
	$ss->{DEBUG}{FETCH_TRIGGER}{A3}++ ;

	# show which formulas are applied
	$ss->{DEBUG}{FETCH_SUB}++ ;
	

	# show when something is stored in a cell, tht can be a value, a formula, ...
	$ss->{DEBUG}{STORE}++;

	# show when dependencies are marked for recalculation
	$ss->{DEBUG}{MARK_ALL_DEPENDENT}++ ;
	 
	# plain perl variables
	my $variable = 25 ;
	my $variable_2 = 30 ;
	my $struct = {result => 'hello world'} ;

	# make cells refer to perl scalars. Note that this is a two way relationship
	$ss->Ref
		(
		'Ref and formulas',
		'A1' => \$variable,
		'A2' => \$variable_2,
		'A3' => \$struct->{result},
		) ;

	# set formulas over the perl scalars.
	
	$ss->PerlFormula
		(
		'A2' => '$ss{A1} * 2',	
		'A3' => '$ss{A2} * 2',	
		) ;

	# fetch the values, running the formulas as necessary
	print "$ss{A1} $ss{A2} $ss{A3}\n" ;

	# fetch the values, running the formulas as necessary, here some results will be cached
	print "$ss{A1} $ss{A2} $ss{A3}\n" ;

	# show the values of the perl scalars
	print DumpTree 
		{
		'$variable' => $variable,
		'$variable_2' => $variable_2,
		'$struct'=> $struct,
		}, 'scalars:' ;

	# set a cell and the perl scalar underneath 
	$ss{A1} = 10 ;

	# fetch the values, running the formulas as necessary
	print "$ss{A1} $ss{A2} $ss{A3}\n" ;

	# show the values of the perl scalars
	print DumpTree 
		{
		'$variable' => $variable,
		'$variable_2' => $variable_2,
		'$struct'=> $struct,
		}, 'scalars:' ;

The output is the following (comments are added as an explanation):

	# make cells refer to perl scalars. (arguments are passed in a hash thus the order)
	Storing To 'A3'
	Storing To 'A1'
	Storing To 'A2'
	
	# set formulas over the perl scalars.
	Storing To 'A3'
	Storing To 'A2'
	
	# fetch the values, running the formulas as necessary
	# this is the result of the first: print "$ss{A1} $ss{A2} $ss{A3}\n" ;
	
	# A1, the value comes from the scalar
	Fetching cell 'A1'.
	  => Fetching cell 'A1' value from scalar reference.
	  
	# A2, the value comes from the formula
	Fetching cell 'A2'.
	  => Cell 'A2' value from scalar reference shadowed by formula.
	  
	# run the formula, note that the formula is also displayed in the dump
	Running Sub @ 'TEST!A2' formula: $ss{A1} * 2
	# fetch the A1 cell refered to in the formula
	Fetching cell 'A1'.
	  => Fetching cell 'A1' value from scalar reference.
	  
	# A3, identic to A2  
	Fetching cell 'A3'.
	  => Cell 'A3' value from scalar reference shadowed by formula.
	Running Sub @ 'TEST!A3' formula: $ss{A2} * 2
	Fetching cell 'A2'.
	
	# the result of the first print
	25 50 100
	
	
	# fetch the values, running the formulas as necessary, here some results are cached
	# this is the result of the second: print "$ss{A1} $ss{A2} $ss{A3}\n" ;"
	
	# fetched from the perl scalar
	Fetching cell 'A1'.
	  => Fetching cell 'A1' value from scalar reference.
	  
	# A2 and A3 are fetched from the spreadsheet, since they are cached,
	# there is no need to run the formulas again
	Fetching cell 'A2'.
	Fetching cell 'A3'.
	
	# the result of the second print
	25 50 100
	
	# show the values of the perl scalars
	scalars:
	+- $struct  [H1]
	|  +- result = 100  [S2]
	+- $variable = 25  [S3]
	+- $variable_2 = 50  [S4]
	
	# set a cell and the perl scalar underneath 
	# the cells that have dependencies on A1 are marked for recalculation
	Storing To 'A1'
	   'A2' needs update
	      'A3' needs update
	      
	      
	# fetch the values, running the formulas as necessary      
	Fetching cell 'A1'.
	  => Fetching cell 'A1' value from scalar reference.
	Fetching cell 'A2'.
	Running Sub @ 'TEST!A2' formula: $ss{A1} * 2
	Fetching cell 'A1'.
	  => Fetching cell 'A1' value from scalar reference.
	Fetching cell 'A3'.
	Running Sub @ 'TEST!A3' formula: $ss{A2} * 2
	Fetching cell 'A2'.
	10 20 40
	
	# show the values of the perl scalars
	scalars:
	+- $struct  [H1]
	|  +- result = 40  [S2]
	+- $variable = 10  [S3]
	+- $variable_2 = 20  [S4]		

Note that B<Ref> accepts reference to scalars only.

=head3 Removing the mapping

Simply delete the cell:

  delete ${A1} ;

=head2 Store on fetch

You can direct Spreadsheet::Perl to call the 'store callback' of a cell everytime the cell is fetched. What is this good for?
Here is an example:

  $ss{A3} = PF('$ss{A1} + $ss{A2}') ;
  
  $ss{A3} = StoreOnFetch() ; # set the store on fetch attribute for this cell
  
  $ss{A3} = StoreFunction('formula to db', \&MyStoreCallback) ;
  
  $ss{'A1:A2'} = 10 ;
  $ss->Recalculate() ;

This lets you calculate the value of a cell through a formula and store that value wherever you wish to. For example a database,
a perl scalar or even mail the value.

=head2 Reading values

Use the normal perl assignment:

  my $value = $ss{A1} ;
  
You can read multiple values using slices:

my ($value1, $value2) = @ss{'A1', 'A2'} ;

=head3 Reading range values

I you want to read all the values contained in a range, use the following syntax:

  my $values = $ss{'A1:A10'} ;

An array reference is returned. It contains the values ordered by rows first then by columns.

=head3 Copying cell values from a spreadsheet to another spreadsheet or to another hash

Use Perl hash slices:

  tie my %spreadsheet, "Spreadsheet::Perl" ;
  my $spreadsheet = tied %$spreadsheet ;
  
  my @cells = qw(A1 B6 C4) ;
  
  @spreadsheet{@cells} = qw( first second third ) ;
  
  my %copy_hash ;
  @copy_hash{@cells} =  @spreadsheet{@cells} ;
  
  print DumpTree(\%copy_hash, 'CopyHash:') ;
  
=head2 Reading attributes

Cell attributes are handled internally by B<Spreadsheet::Perl>, some of those attributes need to be synchronized or influence
the way B<Spreadsheet::Perl> handles the cell. You still get the attributes through an extended address. This is easier 
explained with an example:

  $ss{A1} = UserData(FIRST => 1, SECOND => 2) ; # stored in a hash
  $user_data_hash = $ss{A1.USER_DATA} ;
  
The attributes you can use are:

=over 2

=item * FORMAT

=item * USER_DATA

=back

=head1 OUTPUT

=head2 HTML

As of version 0.04, there is a simple way to generate HTML tables. It uses the B<Data::Table> module. This is an 
interim solution and it is limited but it might just do what you want.

  ...
  print $ss->GenerateHtml() ;
  $ss->GenerateHtmlToFile('output_file_name.html') ;

See L<Dumping a table>.

=head1 DEBUGGING

=head2 Dump

The I<Dump> function, err, dumps the spreadsheet. It takes the following arguments:

=over 2

=item * an address list withing an array reference or undef. ex: ['A1', 'B5:B8']

=item * a boolean. When set, the spreadsheet attributes are displayed

=item * an optional hash reference passed as overrides to B<Data::TreeDumper>

It returns a string containing the dump.

=back

=head2 Debug handle

All debug output is done through the handle set in $ss{DEBUG}{ERROR_HANDLE}. It is set to STDERR but could 
be set to a file or other logging facilities.

The handle can be used from withing formulas if necessary:

  $ss{A9} = PerlFormula
		('
		my $dh = $ss->{DEBUG}{ERROR_HANDLE} ;
		print $dh "Doing something\n" ;
		$ss->Sum("A1:A7", "A8") ;
		') ;

=head2 Debug flags

=head3 $ss->{DEBUG}

I don't removes the flags I create while developing B<Spreadsheet::Perl> if I think it can be useful to the user (that's me at least).
The following flags exist:

  $ss->{DEBUG}{SUB}++ ; # show whenever a value has to be calculated
  $ss->{DEBUG}{FETCHED}++ ; # counts how many times the cell is fetched
  $ss->{DEBUG}{STORED}++ ; # counts how many times the cell is stored
  
  $ss->{DEBUG}{PRINT_FORMULA}++ ; # show the info about formula generation
  $ss->{DEBUG}{PRINT_FORMULA_EVAL_STATUS}++ ; # show the info about formula execution
  $ss->{DEBUG}{INLINE_INFORMATION}++ ; # inline cell information in the table dump
  $ss->{DEBUG}{PRINT_ORIGINAL_FORMULA}++ ; # inline original formula in the table dump
  $ss->{DEBUG}{PRINT_FORMULA_ERROR}++ ; # inline the error generated by the formula evaluation
  $ss->{DEBUG}{PRINT_DEPENDENT_LIST}++ # inline the list of dependents in the table dump
  $ss->{DEBUG}{PRINT_CYCLIC_DEPENDENCY})++ # inline dependency cyles in the table dump

  $ss->{DEBUG}{DEFINED_AT}++ ; # show where the cell has been defined
  $ss->{DEBUG}{ADDRESS_LIST}++ ; # shows the generated address lists
  $ss->{DEBUG}{FETCH_FROM_OTHER}++ ; # show when an inter spreadsheet value is fetched
  $ss->{DEBUG}{DEPENDENT_STACK_ALL}++ ; # show the dependent stack every time a value is fetched
  $ss->{DEBUG}{DEPENDENT_STACK}{A1}++ ; # show the dependent stack every time the cell is fetched
  $ss->{DEBUG}{DEPENDENT}++ ; # store information about dependent and show them in dump
  $ss->{DEBUG}{MARK_ALL_DEPENDENT}++; # shows when any dependent cell is marked as needing an update
  $ss->{DEBUG}{MARK_DEPENDENT}{$cell_name} # shows when dependent cell '$cell_name' is marked as needing an update 
  $ss->{DEBUG}{VALIDATOR}++ ; # display calls to all validators in spreadsheet
  
  $ss->{DEBUG}{FETCH}++ ; # shows when a cell value is fetched
  $self->{DEBUG}{FETCH_VALUE}++ ; # shows which value is fetched

  $ss->{DEBUG}{STORE}++ ; # shows when a cell value is stored
  $ss->{DEBUG}{RECORD_STORE_ALL}++ # keep all call stacks for all the STORE
  $ss->{DEBUG}{RECORD_STORE}{A1}++ # keep all call stacks for A1
  # RECORD_STORE_ALL and RECORD_STORE are memory hoags! And generate gigantic dumps but are great debugging help
  # RECORD_STORE does not have to be set through out your application, it canbe set and unset as you wish
  # remember that you can pass addresses and ranges to Dump().
  # print $ss->Dump(['A1', 'B0']) ;#
  
  $iss->{DEBUG}{FETCH_TRIGGER}{'A1'}++ ; # displays a message when 'A1' is fetched
  $ss->{DEBUG}{FETCH_TRIGGER}{'A1'} = sub {my ($ss, $address) = @_} ; # calls the sub when 'A1' is fetched
  $ss->{DEBUG}{FETCH_TRIGGER_HANDLER} = sub {my ($ss, $address) = @_} ; # calls sub when any trigger is fetched and no specific sub exists
  $ss->{DEBUG}{STORE_TRIGGER}{'A1'}++ ; # displays a message when 'A1' is stored
  $ss->{DEBUG}{STORE_TRIGGER}{'A1'} = sub {my ($ss, $address) = @_} ; # calls the sub when 'A1' is stored
  $ss->{DEBUG}{STORE_TRIGGER_HANDLER} = sub {my ($ss, $address, $value) = @_} ; # calls sub when any trigger is stored and no specific sub exists

more will be added when the need arises.

=head3 $ss->{DEBUG_MODULE}

This flag 'family' is reserved for modules that are not part of the distribution. The 'Arithmetic.pm' module
(which is a part of the distribution at version 0.04 will be made available as a separate package) includes these lines:

  if(exists $ss->{DEBUG_MODULE}{ARITHMETIC_SUM})
	  {
	  print $ss->{DEBUG}{ERROR_HANDLE} "Sum: $current_address => $cell_value\n" ;
	  }

=head1 TODO

There is still a lot to do (the basics are there) and I have the feeling I will not get the time needed.
If someone is willing to help or take over, I'll be glad to step aside.

Here are some of the things that I find missing, this doesn't mean all are good ideas:

=over 2

=item * more tests, automatic tests. Test on Win32 platform.

=item * perl debugger support

=item * Row/column/spreadsheet default values.

=item * R1C1 Referencing

=item * database interface (a handful of functions at most)

=item * Arithmetic functions (only Sum is implemented), statistic functions

=item * printing, exporting

=item * importing from other spreadsheets

=item * Gnumeric/Excel formula syntax (common format is done)	

=item * complex stuff 

=over 4

=item * Sorting

=back

=item * a complete GUI (Prima example exists)

=item * a nice logo :-)

=back

Lots is available on CPAN, just some glue is needed.

=head1 AUTHOR

Khemir Nadim ibn Hamouda. <nadim@khemir.net>

  Copyright (c) 2004 Nadim Ibn Hamouda el Khemir. All rights
  reserved.  This program is free software; you can redis-
  tribute it and/or modify it under the same terms as Perl
  itself.
  
If you find any value in this module or want to influence it's development, mail me!  All hints, tips, flames and wishes
are welcome at <nadim@khemir.net>.

=head1 SEE ALSO

L<Spreadsheet::Engine>

I, of course prefere my implementation that, IMHO, does much more; but L<Spreadsheet::Engine> provides a lot of functions like
SQRT, TODAY, TRIM, ... Since L<Spreadsheet::Perl> allows you to use perl as a cell formula language, there is little need for that.

If you need to load spreadsheet with "common format" formulas, L<Spreadsheet::Engine> may be a goog alternative. Stealing all those
to add them to L<Spreadsheet::Perl> has crossed my mind and it's not much work. Either send me a patch or ask and I may add them.

=head1 DEPENDENCIES

B<Spreadsheet::ConvertAA>.

B<Data::TreeDumper>.

B<Text::ASCIITable>.

Some examples need these:

B<Prima>.

B<Data::Table>.

=cut

