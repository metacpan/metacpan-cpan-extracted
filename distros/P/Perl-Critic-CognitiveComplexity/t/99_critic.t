use strict;
use warnings;
use File::Spec;
use Test::More;
use Test::Perl::Critic;

if ( not $ENV{TEST_AUTHOR} ) {
    my $msg = 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.'; ## no critic(RequireInterpolationOfMetachars)
    plan( skip_all => $msg );
}

Test::Perl::Critic->import(-profile => \(join q{}, <DATA>)); ## no critic(ProhibitJoinedReadline)
all_critic_ok( 'lib' );

__END__

profile-strictness = fatal
severity = 1
theme = core
verbose = %f: %m at line %l, column %c.  %e.  (Severity: %s, %p)\n

exclude = ProhibitAutomaticExportation$ ProhibitBuiltinHomonyms ProhibitCommaSeparatedStatements ProhibitComplexMappings ProhibitConstantPragma ProhibitExplicitReturnUndef RequireExtendedFormatting ProhibitManyArgs ProhibitSubroutinePrototypes ProhibitUniversalCan$ ProhibitUniversalIsa$ Subroutines::RequireArgUnpacking RequireCarping RequireCheckingReturnValueOfEval RequireEndWithOne RequireExplicitPackage RegularExpressions::RequireExtendedFormatting RequireFilenameMatchesPackage$ RequireFinalReturn RequireLexicalLoopIterators RequireQuotedHeredocTerminator RequireSimpleSortBlock RequireUseWarnings ProhibitCallsToUndeclaredSubs ProhibitPostfixControls

#-----------------------------------------------------------------------------

[BuiltinFunctions::ProhibitStringyEval]
allow_includes = 1

[CodeLayout::ProhibitHardTabs]
allow_leading_tabs = 0

[CodeLayout::ProhibitQuotedWordLists]
strict = 1

[-CodeLayout::RequireTidyCode]
[-Documentation::RequirePodLinksIncludeText]

[Documentation::RequirePodSections]
lib_sections    = NAME|DESCRIPTION|AUTHOR|COPYRIGHT
script_sections = NAME|DESCRIPTION|AUTHOR|COPYRIGHT

# Wrapping Exception constructor calls across lines runs into 9 lines too quickly.
[InputOutput::RequireBriefOpen]
lines = 20

[InputOutput::RequireCheckedSyscalls]
functions = open close

[RegularExpressions::ProhibitUnusualDelimiters]
allow_all_brackets = 1

[RegularExpressions::RequireBracesForMultiline]
allow_all_brackets = 1

[Subroutines::ProhibitUnusedPrivateSubroutines]
private_name_regex = _(?!_)\w+
allow = _get_behavior_values _get_description_with_trailing_period

[Subroutines::ProtectPrivateSubs]
private_name_regex = _(?!_)\w+

[Variables::ProhibitPackageVars]
add_packages = Email::Address
