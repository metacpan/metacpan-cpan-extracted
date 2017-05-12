use 5.010000;
use warnings;
use strict;

use Test::Perl::Critic (

    -profile => 'xt/perlcriticrc',

    -exclude => [ qw(
        BuiltinFunctions::ProhibitComplexMappings
        CodeLayout::RequireTidyCode
        CodeLayout::RequireTrailingCommas
        ControlStructures::ProhibitCascadingIfElse
        ControlStructures::ProhibitDeepNests
        ControlStructures::ProhibitPostfixControls
        Documentation::RequirePodLinksIncludeText
        Documentation::RequirePodSections
        InputOutput::ProhibitExplicitStdin
        InputOutput::ProhibitInteractiveTest
        InputOutput::ProhibitOneArgSelect
        InputOutput::RequireBracedFileHandleWithPrint
        InputOutput::RequireEncodingWithUTF8Layer
        NamingConventions::Capitalization
        References::ProhibitDoubleSigils
        RegularExpressions::ProhibitEnumeratedClasses
        RegularExpressions::RequireDotMatchAnything
        RegularExpressions::RequireExtendedFormatting
        RegularExpressions::RequireLineBoundaryMatching
        Subroutines::ProhibitExcessComplexity
        Subroutines::ProhibitSubroutinePrototypes
        Subroutines::ProhibitUnusedPrivateSubroutines
        Subroutines::RequireArgUnpacking
        Subroutines::RequireFinalReturn
        ValuesAndExpressions::ProhibitEmptyQuotes
        ValuesAndExpressions::ProhibitInterpolationOfLiterals
        ValuesAndExpressions::ProhibitMagicNumbers
        ValuesAndExpressions::ProhibitNoisyQuotes
        Variables::ProhibitPunctuationVars
        Variables::RequireLocalizedPunctuationVars
    ) ],

);


all_critic_ok();
