TODO
====

 * Update Changes file to meet Changes spec
 * add new theme for OTRS4 (add all existing policies to that theme)
 * add documentation to policies (what is a do/don't)
 * ProhibitOpen: only prohibit the open when it is the Core function (Module::Name->open() should be allowed)
 * Add policies for:
   - "our @ObjectDependencies" or "$ObjectManagerDisabled" (for OTRS >= 4.0)
   - ProhibitObjectManagerAware -> no "our $ObjectManagerAware" (for OTRS >= 4.0)
   - ProhibitForeach -> no foreach my $var ( @array )
   - ProhibitGoto    -> no 'goto'
   - ProhibitCacheNew -> no Kernel::System::Cache->new() (for OTRS >= 4.0)
   - ProhibitShebangInModules -> no "#!..." in .pm files
   - ProhibitParamObjectInBackendAndBin -> OTRS < 4.0: no "ParamObject" in Kernel::System::* and bin/, OTRS >= 4.0: no "Kernel::System::Web::Request"
   - RequireSortKeys -> Use "sort" when "keys" is used
   - RequireUseUTF8ForNonASCIIFiles (.pl, .pm)
   - RequireStrictWarnings -> Use "use strict" and "use warnings"
   - RequireLabelsWithLoopOps -> always use a label when using "next" or "last"
   - ProhibitUnless -> no "unless" ( for OTRS >= 4.0 )
   - ProhibitSmartMatch -> no smart-match
 * Create sample perlcritic.rc files for
   - OTRS >= 4.0
   - OTRS >= 3.3, < 4.0
   - OTRS < 3.3
   - find out which Perl::Critic policies should be enabled/disabled
   - Activate Perl::Critic policies:
     - ProhibitLvalueSubstr
     - ProhibitSleepViaSelect
     - ProhibitTrailingWhitespace
     - RequireLexicalLoopIterators
   - Deactivate Perl::Critic policies:
     - ProhibitBooleanGrep
     - ProhibitComplexMappings
     - ProhibitReverseSortBlock
