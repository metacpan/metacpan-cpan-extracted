use strict ;
use warnings ;
use Data::Dumper ;

use PBS::Output ;
use PBS::Constants ;
use PBS::Shell ;

#-------------------------------------------------------------------------------

die "this is an old module and most certainly doesn't work with the latest Pbs version" ;

#-------------------------------------------------------------------------------

sub Multiple_O_Compile
{
my $package            = shift  ;
my $pbs_config     = shift  ;

my @build_sequence = @_ ;
my ($build_result, $build_message) = (BUILD_FAILED, '') ;

PrintInfo("\n** Sequence Miner: 'Multiple Object Files Compile' **\n") unless $pbs_config->{DISPLAY_NO_STEP_HEADER} ;

# Handle the '.c' files that are in the build sequence
# we could also handle only the file that are dependencies for our '.o' files
my (@c_nodes, @not_c_nodes, @o_nodes, @not_o_nodes) ;

for my $node (@build_sequence)
	{
	if($node->{__NAME} =~ /\.c$/)
		{
		push @c_nodes, $node ;
		}
	else
		{
		push @not_c_nodes, $node ;
		}
	}

if(@c_nodes)
	{
	PrintInfo("Found C files in the build sequence, attempting to build them.\n") ;
	($build_result, $build_message) = PBS::Build::BuildSequence
														(
														  $package
														, $pbs_config
														, \@c_nodes
														) ;
														
	if($build_result == BUILD_FAILED)
		{
		PrintInfo("Sequence Miner: 'Multiple Object Files Compile', Aborting.\n") ;
		return ($build_result, $build_message) ;
		}
	}
	
for my $node (@not_c_nodes)
	{
	my $node_will_be_compiled_with_other_nodes = 0 ;
	
	if($node->{__NAME} =~ /\.o$/)
		{
		my $number_of_dependencies = 0 ;
		my $c_dependency  ;
		
		#~ print "********* Checking : $node->{__BUILD_NAME}\n" ;
		for my $key (keys %$node)
			{
			next if($key =~  /^__/) ;
			#~ print "********* dependency $node->{__BUILD_NAME} -> $key\n" ;
			
			$number_of_dependencies++ ;
			if($number_of_dependencies == 2)
				{
				#~ print "!!!!!!!! more than one dependency.\n" ;
				last  ;
				}
			
			$c_dependency = $key if($key =~ /\.c$/) ;
			}
			
		}
		
	unless($node_will_be_compiled_with_other_nodes)
		{
		push @not_o_nodes, $node ;
		}
	}

my %sorted_nodes ;
for my $node (@o_nodes)
	{
	my ($basename, $path, $ext) = File::Basename::fileparse($node->{__BUILD_NAME}, ('\..*')) ;
	
	use Digest::MD5 qw(md5_hex) ;
	
	my $node_digest = GetDigest($node) ;
	
	for my $key (keys %$node_digest)
		{
		# could delete the Pbsfile md5!
		
		delete $node_digest->{$key} unless $key =~ /^__/ ;
		}
		
	my $config_md5 = md5_hex($node_digest) ;
	
	$node->{__MULTIPLE_OBJECT_FILES_COMPILE_PATH} = $path ;
	push @{$sorted_nodes{$path}{$config_md5}}, $node ;
	}

for my $path (keys %sorted_nodes)
	{
	my $command;
	
	for my $config_md5 (keys %{$sorted_nodes{$path}})
		{
		my $first_node = $sorted_nodes{$path}{$config_md5}[0] ;
		my $cc         = $first_node->{__CONFIG}{MULTIPLE_CC} || $first_node->{__CONFIG}{CC} || '! No CC defined' ;
		my $c_flags    = $first_node->{__CONFIG}{MULTIPLE_CFLAGS} || $first_node->{__CONFIG}{CFLAGS} || '' ;
		my $path       = $first_node->{__MULTIPLE_OBJECT_FILES_COMPILE_PATH} ;
		
		#~ my $files_to_build     = join ' ', map({$_->{__BUILD_NAME}} @{$sorted_nodes{$path}{$config_md5}}) ;
		my $c_files_to_compile = join ' ', map({$_->{__MULTIPLE_OBJECT_FILES_COMPILE_C_SOURCE}} @{$sorted_nodes{$path}{$config_md5}}) ;
		
		local $PBS::Shell::silent_commands = 1 ;
		
		if(defined $pbs_config->{CREATE_NODE_PATH})
			{
			use File::Path ;
			mkpath($path) unless(-e $path) ;
			}
			
		PrintInfo("Processing Object files in directory '$path'.\n") ;
		$command = "cd $path && $cc $c_flags -c $c_files_to_compile";
		eval
			{
			PBS::Shell::RunShellCommands($command);
				
			for my $node (@{$sorted_nodes{$path}{$config_md5}})
				{
				# the following  is very important
				# if you _don't_ use -j when building, the build sequence is ordered
				# and everything works fine. But when using the -j switch, PBS reorders
				# the build to a more effective parallel sequence. The parallel sequence 
				# used the parent/child relationship. Children must be tagged as already build.
				$node->{__BUILD_DONE} = "'Multiple OBject Files Compile'" ;
				
#				if(@{$node->{__POST_BUILD_COMMANDS}})
#					{
#					PrintError("Multiple Object Files Compiler: Ignoring post build commands for node '$node->{__BUILD_NAME}'. (Not supported!)\n") ;
#					}
				}
			} ;
			
		#check results
		if($@)
			{
			if($@->isa('PBS::Shell'))
				{
				$build_result = BUILD_FAILED ;
				
				$build_message= "\n\t" . $@->{error} . "\n" ;
				$build_message .= "\tCommand   : '" . $@->{command} . "'\n" ;
				$build_message .= "\tErrno     : " . $@->{errno} . "\n" ;
				$build_message .= "\tErrno text: " . $@->{errno_string} . "\n" ;
				
				PrintError("BUILD_FAILED : $build_message\n") ;
				
				return($build_result, $build_message, @not_o_nodes) ;
				}
			else
				{
				PrintError("'Multiple Object Files Compiler' running '$command': Exception: $@\n") ;
				die ;
				}
			}
		
		PBS::Digest::GenerateNodeDigest($_) for (@o_nodes) ;
		}
	}
	
PrintInfo("\n** Sequence Miner: 'Multiple Object Files Compile' Done **\n") unless $pbs_config->{DISPLAY_NO_STEP_HEADER} ;

#~return($build_result, $build_message, @not_o_nodes) ;
return(1, "ok", @not_o_nodes) ;
}

#-------------------------------------------------------------------------------
1;

