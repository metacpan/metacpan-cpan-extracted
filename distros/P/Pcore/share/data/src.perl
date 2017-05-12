{   EXIT_CODES => {
        SOURCE_VALID  => 0,
        RUNTIME_ERROR => 1,
        PARAMS_ERROR  => 2,
        SOURCE_ERROR  => 3,
    },
    SEVERITY => {
        VALID    => 0,
        GENTLE   => 1,
        STERN    => 2,
        HARSH    => 3,
        CRUEL    => 4,
        BRUTAL   => 5,
        PERLTIDY => 6,    # perltidy error
        OPEN     => 7,    # file open error
        BINARY   => 8,    # file is binary
        ENCODING => 9,    # couldn't guess encoding
    },
    SEVERITY_RANGE => {
        VALID   => 0,
        WARNING => 1,
        ERROR   => 4,
    },

    MIME_TYPE => {
        'text/x-script.perl' => {    # .pl, .t, or shebang
            type        => 'Perl',
            filter_args => {
                perl_critic               => 1,
                perl_compress_end_section => 1,
            },
        },
        'text/x-script.perl-module' => {    # .pm
            type        => 'Perl',
            filter_args => {                #
                perl_critic => 1,
            },
        },
        'text/x-script.perl-config' => {    # .perl
            type        => 'Perl',
            filter_args => {                #
                perl_critic => 'pcore-config',
            },
        },
        'text/x-script.perl-auto' => {      # .PL
            type        => 'Perl',
            filter_args => {
                perl_critic               => 0,
                perl_compress_end_section => 1,
            },
        },
        'text/x-script.perl-cpanfile' => {    # cpanfile
            type        => 'Perl',
            filter_args => {                  #
                perl_critic => 0,
            },
        },
        'text/html' => {                      # .html, ...
            type => 'HTML',
        },
        'text/css' => {                       # .css
            type => 'CSS',
        },
        'application/javascript' => {         # .js, .javascript
            type => 'JS',
        },
        'application/json' => {               # .json
            type => 'JS',
        },
    },

    DEFAULT_GUESS_ENCODING => ['cp1251'],

    # http://perltidy.sourceforge.net/perltidy.html
    PERLTIDY => q[--perl-best-practices --tight-secret-operators --continuation-indentation=2 --maximum-line-length=0 --format-skipping --format-skipping-begin="# <<<" --format-skipping-end="# >>>" --converge --nostandard-output --character-encoding=utf8],

    HTML_BEAUTIFY => q[--indent-scripts normal],

    HTML_PACKER_MINIFY => {
        remove_comments => 0,
        remove_newlines => 1,
        html5           => 1,
    },

    JS_BEAUTIFY => q[--indent-size 4 --indent-char " " --indent-level 0 --no-preserve-newlines --max-preserve-newlines 2 --jslint-happy --brace-style collapse --good-stuff],

    JS_HINT => q[--verbose],    # --show-non-errors

    # perlcritic profiles
    PERLCRITIC => {
        common => {
            __autodetect__ => sub {
                return $_[0] !~ /^use\s+Pcore(?:\s|;)/sm;
            },

            __defaults__ => { severity => 1 },

            # BuiltinFunctions
            'BuiltinFunctions::ProhibitUselessTopic' => { severity => 4 },

            # ClassHierarchies
            'ClassHierarchies::ProhibitAutoloading' => { severity => 5 },

            # CodeLayout
            'CodeLayout::RequireTidyCode' => undef,    # covered by running perltidy separately

            # ControlStructures
            'ControlStructures::ProhibitCascadingIfElse' => { max_elsif => 5 },
            'ControlStructures::ProhibitPostfixControls' => { allow     => 'if unless' },
            'ControlStructures::ProhibitUnlessBlocks'    => undef,
            'ControlStructures::ProhibitYadaOperator'    => { severity  => 3 },

            # Documentation
            'Documentation::RequirePodSections' => undef,

            # InputOutput
            'InputOutput::ProhibitBacktickOperators' => { only_in_void_context => 1 },

            # Modules
            'Modules::RequireNoMatchVarsWithUseEnglish' => undef,

            # Modules
            'Modules::ProhibitEvilModules' => {
                modules => join(
                    q[ ],
                    (   'indirect',    # !!! exporting indirect pragma cause random crashes under windows
                    )
                ),
            },

            # Miscellanea
            'Miscellanea::ProhibitUselessNoCritic' => { severity => 4 },

            # NamingConventions
            'NamingConventions::Capitalization' => undef,

            # References
            # TODO enable, when bug with ->%* will be fixed, https://github.com/adamkennedy/PPI/issues/88
            'References::ProhibitDoubleSigils' => undef,    # { severity => 4 },

            # RegularExpressions
            'RegularExpressions::RequireDotMatchAnything'       => { severity           => 4 },
            'RegularExpressions::RequireLineBoundaryMatching'   => { severity           => 4 },
            'RegularExpressions::RequireExtendedFormatting'     => undef,
            'RegularExpressions::ProhibitEscapedMetacharacters' => { severity           => 4 },
            'RegularExpressions::ProhibitUselessTopic'          => { severity           => 4 },
            'RegularExpressions::ProhibitUnusualDelimiters'     => { allow_all_brackets => 1 },
            'RegularExpressions::RequireBracesForMultiline'     => { allow_all_brackets => 1 },

            # Subroutines
            'Subroutines::ProhibitAmpersandSigils'          => { severity           => 4 },
            'Subroutines::ProhibitUnusedPrivateSubroutines' => { private_name_regex => '_(?!_?build_)\w+', },
            'Subroutines::RequireArgUnpacking'              => undef,
            'Subroutines::ProhibitSubroutinePrototypes'     => undef,               # TODO [PCORE-27] - remove this policy, https://github.com/Perl-Critic/Perl-Critic/issues/591

            # TestingAndDebugging
            'TestingAndDebugging::RequireUseStrict'   => { equivalent_modules              => 'common::header Pcore' },
            'TestingAndDebugging::RequireUseWarnings' => { equivalent_modules              => 'common::header Pcore' },
            'TestingAndDebugging::ProhibitNoStrict'   => { allow                           => 'subs refs' },
            'TestingAndDebugging::ProhibitNoWarnings' => { allow_with_category_restriction => 1 },

            # ValuesAndExpressions
            'ValuesAndExpressions::ProhibitInterpolationOfLiterals' => { severity => 3 },
            'ValuesAndExpressions::ProhibitMagicNumbers'            => undef,
            'ValuesAndExpressions::ProhibitNoisyQuotes'             => undef,
            'ValuesAndExpressions::ProhibitVersionStrings'          => undef,

            # Variables
            'Variables::ProhibitPackageVars'     => undef,
            'Variables::ProhibitPunctuationVars' => undef,
            'Variables::ProhibitReusedNames'     => { severity => 4 },
            'Variables::ProhibitUnusedVariables' => { severity => 4 },
        },
        'pcore-script' => {
            __parent__ => 'common',

            __autodetect__ => sub {
                return $_[0] =~ /^use\s+Pcore(?:\s|;)/sm;
            },

            # ErrorHandling
            'ErrorHandling::RequireCarping' => undef,

            # InputOutput
            'InputOutput::RequireCheckedSyscalls' => {
                severity          => 4,
                functions         => ':builtins',
                exclude_functions => 'print say sleep',
            },
            'InputOutput::RequireCheckedOpen'  => { severity => 4, },
            'InputOutput::RequireCheckedClose' => { severity => 4, },

            # Modules
            'Modules::ProhibitEvilModules' => {
                modules => join(
                    q[ ],
                    (   'autodie',
                        'indirect',    # !!! exporting indirect pragma cause random crashes under windows

                        '/\Aconstant/',
                        '/\AReadonly/',
                        'Const::Fast',

                        'English',
                        'Encode',

                        'Sys::Hostname',

                        'Scalar::Util',
                        'List::Util',
                        'List::Util::XS',
                        'List::AllUtils',
                        'Hash::Util',
                        'Sub::Util',

                        '/JSON/',
                        '/Data::Dump/',
                        'Data::Printer',
                        'File::Path',
                        'File::Slurp',
                        'File::Temp',
                        'Path::Tiny',
                        'File::Copy',
                        'Cwd',
                        'File::Spec',
                        'File::Basename',
                        'File::Find',
                        '/Data::UUID/',
                        '/Data::Serializer/',
                        'Capture::Tiny',

                        'HTTP::Tiny',

                        'Sub::Name',
                        'Sub::Identify',

                        'MIME::Base64',
                        '/URI::Escape/',
                        'URL::Encode',
                        '/Geo::IP/',

                        'Moo',
                        'Moo::Role',
                        'MooX::late',
                        '/MooX::Types::MooseLike/',
                        '/Type::Tiny/',
                        '/\ATypes::/',
                    )
                ),
            },
            'Modules::RequireVersionVar'        => undef,
            'Modules::ProhibitMultiplePackages' => undef,
        },
        'pcore-config' => {
            __parent__ => 'pcore-script',

            # Modules
            'Modules::RequireExplicitPackage' => undef,
            'Modules::RequireEndWithOne'      => undef,

            # TestingAndDebugging
            'TestingAndDebugging::RequireUseStrict'   => undef,
            'TestingAndDebugging::RequireUseWarnings' => undef,

            # ValuesAndExpressions
            'ValuesAndExpressions::RequireInterpolationOfMetachars' => undef,
            'ValuesAndExpressions::ProhibitInterpolationOfLiterals' => undef,
            'ValuesAndExpressions::ProhibitNoisyQuotes'             => undef,
            'ValuesAndExpressions::ProhibitEmptyQuotes'             => undef,
        },
    },
}
