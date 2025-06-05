## no critic qw(ProhibitUselessNoCritic PodSpelling ProhibitExcessMainComplexity)  # DEVELOPER DEFAULT 1a: allow unreachable & POD-commented code, must be on line 1; SYSTEM SPECIAL 4: allow complex code outside subroutines, must be on line 1

# DEV NOTE: this package exists to serve as the header file for Perl/Types.pm itself,
# as well as for Perl/Types.pm dependencies such as Class.pm, HelperFunctions_cpp.pm, and perltypes.pm
package Perl::Config;
use strict;
use warnings;
our $VERSION = 0.017_000;
our $IS_PERL_CONFIG = 1;  # DEV NOTE, CORRELATION #rp027: Perl::Config, MathPerl::Config, PhysicsPerl::Config, etc

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils
## no critic qw(ProhibitUnreachableCode RequirePodSections RequirePodAtEnd)  # DEVELOPER DEFAULT 1b: allow POD & unreachable or POD-commented code, must be after line 1
## no critic qw(ProhibitStringyEval)  # SYSTEM DEFAULT 1: allow eval()
## no critic qw(ProhibitExplicitStdin)  # USER DEFAULT 4: allow <STDIN> prompt
## no critic qw(Capitalization ProhibitMultiplePackages ProhibitReusedNames)  # SYSTEM DEFAULT 3: allow multiple & lower case package names
## no critic qw(ProhibitAutomaticExportation)  # SYSTEM SPECIAL 14: allow global exports from Config.pm

# [[[ PRE-DECLARED TYPES ]]]
# DEV NOTE: pre-declare base scalar data types, for use within their own Boolean.pm and Integer.pm etc files,
# as well as numerous other Perl::Types files which can `use Perl::Config;` but can't `use Perl::Type::Integer;` etc
package    # hide from PAUSE indexing
    void;
package    # hide from PAUSE indexing
    boolean;
package     # hide from PAUSE indexing
    nonsigned_integer;
package     # hide from PAUSE indexing
    integer;
package    # hide from PAUSE indexing
    number;
package    # hide from PAUSE indexing
    character;
package    # hide from PAUSE indexing
    string;

# [[[ SWITCH CONTEXT BACK TO PRIMARY PACKAGE ]]]
package Perl::Config;
use strict;
use warnings;

# [[[ EXPORTS ]]]
# NEED FIX: duplicate export code
# DEV NOTE: these essential modules are exported automatically into all code which calls `use Perl::Config;` or, by association,
# either `use Perl::Types;` or `use perltypes;`; done via EXPORTS below
use Data::Dumper;  # enable expressive Dumper() in addition to print(); LMPC #4: Thou Shalt ... Create ... Bug-Free, High-Quality Code ...
$Data::Dumper::Sortkeys = 1;    # Dumper() output must sort hash keys for t/lib/Perl/Types/Test/Hash* etc.
use English qw(-no_match_vars);  # prefer more expressive @ARG over @_, etc; LMPC #23: Thou Shalt Not Use ... Punctuation Variables ...
use Carp;  # enable expressive carp()/croak() in addition to warn()/die();  LMPC #8: Thou Shalt ... Create Maintainable, Re-Grokkable Code ...
use POSIX qw(ceil floor modf getcwd);
use Exporter 'import';

# DEV NOTE, CORRELATION #rp008: can't include to_string(), type(), types(), name(), or scope_type_name_value() in @EXPORT here or in Perl:: namespace below
# DEV NOTE, CORRELATION #rp034: enable @ARG in all packages (class & non-class)
# export all symbols imported from essential modules
our @EXPORT    = (@Data::Dumper::EXPORT,    @English::EXPORT,    @Carp::EXPORT,    @POSIX::EXPORT);
our @EXPORT_OK = (@Data::Dumper::EXPORT_OK, @English::EXPORT_OK, @Carp::EXPORT_OK, @POSIX::EXPORT_OK);
# DEV NOTE: do not export individual variables such as $ARG or @ARG, causes unexplainable errors such as incorrect subroutine arguments;
# export subroutines and typeglobs only;
# "Exporting variables is not a good idea. They can change under the hood, provoking horrible effects at-a-distance that are too hard to track and to fix. Trust me: they are not worth it."   https://perldoc.perl.org/Exporter#What-Not-to-Export
# @ARG == @_, $OS_ERROR == $ERRNO == $!, $EVAL_ERROR == $@, $CHILD_ERROR == $?, $EXECUTABLE_NAME == $^X, $PROGRAM_NAME == $0, $OSNAME == $^O
#our @EXPORT = qw(Dumper carp croak confess *ARG $OS_ERROR $EVAL_ERROR $CHILD_ERROR $EXECUTABLE_NAME $PROGRAM_NAME $OSNAME);

1;  # end of package


# [[[ ADDITIONAL PACKAGES SPECIAL ]]]
package    # hide from PAUSE indexing
    Perl;
use File::Find qw(find);
use File::Spec;
use IPC::Cmd qw(can_run);       # to check for `reset`

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils
## no critic qw(ProhibitUnreachableCode RequirePodSections RequirePodAtEnd)  # DEVELOPER DEFAULT 1b: allow POD & unreachable or POD-commented code, must be after line 1
## no critic qw(ProhibitStringyEval)  # SYSTEM DEFAULT 1: allow eval()
## no critic qw(ProhibitExplicitStdin)  # USER DEFAULT 4: allow <STDIN> prompt
## no critic qw(Capitalization ProhibitMultiplePackages ProhibitReusedNames)  # SYSTEM DEFAULT 3: allow multiple & lower case package names
## no critic qw(ProhibitAutomaticExportation)  # SYSTEM SPECIAL 14: allow global exports from Config.pm

# [[[ EXPORTS SPECIAL ]]]
# export $Perl::MODES into all code which calls `use Perl;`
our $MODES = {                  # see perl_modes.txt for more info
    0 => { ops => 'PERL', types => 'PERL' },    # NEED FIX: should be types => 'PERL_STATIC'
    1 => { ops => 'CPP',  types => 'PERL' },    # NEED FIX: should be types => 'PERL_STATIC'
    2 => { ops => 'CPP',  types => 'CPP' }
};

# NEED FIX: duplicate export code
# DEV NOTE: these essential modules are exported automatically into all code which calls `use Perl;`; done via EXPORTS below
use Data::Dumper;  # enable expressive Dumper() in addition to print(); LMPC #4: Thou Shalt ... Create ... Bug-Free, High-Quality Code ...
$Data::Dumper::Sortkeys = 1;    # Dumper() output must sort hash keys for t/lib/Perl/Types/Test/Hash* etc.
use English qw(-no_match_vars);  # prefer more expressive @ARG over @_, etc; LMPC #23: Thou Shalt Not Use ... Punctuation Variables ...
use Carp;  # allow expressive carp()/croak() in addition to warn()/die();  LMPC #8: Thou Shalt ... Create Maintainable, Re-Grokkable Code ...
use POSIX qw(ceil floor modf getcwd);
use Exporter 'import';
# DEV NOTE, CORRELATION #rp034: enable @ARG in all packages (class & non-class)
# export all symbols imported from essential modules
our @EXPORT    = (@Data::Dumper::EXPORT,    @English::EXPORT,    @Carp::EXPORT,    @POSIX::EXPORT);
our @EXPORT_OK = (@Data::Dumper::EXPORT_OK, @English::EXPORT_OK, @Carp::EXPORT_OK, @POSIX::EXPORT_OK);

# [[[ INCLUDES SPECIAL ]]]
use File::Basename qw(fileparse);

# [[[ OO CLASS PROPERTIES SPECIAL ]]]

# data type checking mode, disabled in Perl system code which calls 'use Perl;',
# changed on a per-file basis by preprocessor directive, see Perl::CompileUnit::Module::Class::INIT
# NEED UPGRADE: enable in Perl system code when bootstrapping compiler
our $CHECK    = 'OFF';
our $DEBUG    = 0;       # $Perl::DEBUG & env var PERL_DEBUG are equivalent, default to off, see debug*() & diag*() below
our $VERBOSE  = 0;       # $Perl::VERBOSE & env var PERL_VERBOSE are equivalent, default to off, see verbose*() below
our $WARNINGS = 1;       # $Perl::WARNINGS & env var PERL_WARNINGS are equivalent, default to on, see warn*() below
our $TYPES_CCFLAG = ' -D__CPP__TYPES'; # perltypes_mode.h & here default to CPPTYPES if PERLTYPES not explicitly set in this variable via perltypes::types_enable()
our $BASE_PATH    = undef;                             # all target software lives below here
our $INCLUDE_PATH = undef;                             # all target system modules live here
our $SCRIPT_PATH  = undef;                             # interpreted target system programs live here
our $CORE_PATH    = undef;                             # all Perl core components (perl.h, etc) live here

# DEV NOTE, CORRELATION #rp032: NEED UPGRADE: properly determine whether to use DBL_EPSILON or FLT_EPSILON below
use constant EPSILON => POSIX::DBL_EPSILON();
#use constant EPSILON => POSIX::FLT_EPSILON();

# [[[ SUBROUTINES SPECIAL ]]]

# DEV NOTE, RPERL REFACTOR: copied filename_short_to_namespace_root_guess() from the old 'lib/RPerl/AfterSubclass.pm' module
# NEED ANSWER: does this subroutine really belong here in 'lib/Perl/Config.pm', or do we need to create `lib/Perl/HelperFunctions.pm` etc?
sub filename_short_to_namespace_root_guess {
    ( my $filename_short ) = @ARG;
#    print {*STDERR} 'in Perl::filename_short_to_namespace_root_guess(), received $filename_short = ' . $filename_short . "\n";
    # # DEV NOTE, CORRELATION #rp021: remove hard-coded fake 'perl::' namespace?
    if ($filename_short eq 'perl') { return 'perl::'; }
    my $namespace_root = q{};
    ( my $filename_prefix, my $filename_path, my $filename_suffix ) = fileparse( $filename_short, qr/[.][^.]*/xms );
    # DEV NOTE: allow *.pl files to guess a namespace instead of empty string, both here and in filename_short_to_package_guess() below
    # due to Perl core and/or Perl::Types deps calls to 'use' or 'require' *.pl files, such as Config_git.pl and Config_heavy.pl
#    if ( $filename_suffix eq '.pm' ) {
    if ( ( $filename_suffix eq '.pm' ) or ( $filename_suffix eq '.pl' ) ) {
        my $filename_path_split;
        if ( $OSNAME eq 'MSWin32' ) {
            $filename_path_split = [ split /[\/\\]/, $filename_path ];
            #absolute paths cant go through here anymore, this was dropping the
            #first part of the package on some modules
            #shift @{$filename_path_split};    # discard leading drive letter
        }
        else {
            $filename_path_split = [ split /\//, $filename_path ];
        }

        # join then re-split in case there are no directories in path, only the *.pm filename
        my $namespace_root_split = [ split /::/, ( join '::', ( @{$filename_path_split}, $filename_prefix ) ) ];
        if ( $namespace_root_split->[0] eq '.' ) {
            shift @{$namespace_root_split};
        }
#        print {*STDERR} 'in Perl::filename_short_to_namespace_root_guess(), have $namespace_root_split = ' . Dumper($namespace_root_split) . "\n";
        $namespace_root = $namespace_root_split->[0] . '::';
    }
#    print {*STDERR} 'in Perl::filename_short_to_namespace_root_guess(), about to return $namespace_root = ' . $namespace_root . "\n";
    return $namespace_root;
}


# DEV NOTE, RPERL REFACTOR: copied post_processor__absolute_path_delete() from the old 'lib/RPerl/Compiler.pm' module
# NEED ANSWER: does this subroutine really belong here in 'lib/Perl/Config.pm', or do we need to create `lib/Perl/HelperFunctions.pm` etc?
# DEV NOTE, CORRELATION #rp055: handle removal of current directory & all @INC directories, so as not to hard-code system-specific dirs in #include statements
# remove unnecessary absolute paths
sub post_processor__absolute_path_delete {
    { my string $RETURN_TYPE };
    ( my string $input_path ) = @ARG;

#Perl::diag( 'in Perl::post_processor__absolute_path_delete(), received $input_path = ' . $input_path . "\n" );

    # replace M$ backslashes with *nix forward slashes as path delimiter characters
    if ( $OSNAME eq 'MSWin32' ) {
        $input_path =~ s/\\/\//gxms;
#Perl::diag( 'in Perl::post_processor__absolute_path_delete(), Windows OS detected, have possibly-reformatted $input_path = ' . $input_path . "\n" );
    }

    # get the CWD, which we want to remove from the $input_path
    my string $current_working_directory = getcwd();

#Perl::diag( 'in Perl::post_processor__absolute_path_delete(), have $current_working_directory = ' . $current_working_directory . "\n" );

    # if $input_path starts with $current_working_directory, then remove the CWD and return
    if ( ( substr $input_path, 0, ( length $current_working_directory ) ) eq $current_working_directory ) {
        return substr $input_path, ( ( length $current_working_directory ) + 1 );
    }

#Perl::diag( 'in Perl::post_processor__absolute_path_delete(), about to return $input_path = ' . $input_path . "\n" );

    # else return the unmodified $input_path
    return $input_path;
}




# use a possibly-compiled Perl package during runtime
sub eval_use {
    (my $package_name, my $display_errors) = @ARG;
#    Perl::debug('in Perl::eval_use(), received $package_name = ', $package_name, "\n");
#    Perl::debug('in Perl::eval_use(), CHECKPOINT c000', "\n");

    my $INC_ref_pre = {};
    foreach my $INC_key_pre (keys %INC) { $INC_ref_pre->{$INC_key_pre} = 1; }
#    Perl::debug('in Perl::eval_use(), have $INC_ref_pre = ', Dumper($INC_ref_pre), "\n");
#    Perl::debug('in Perl::eval_use(), CHECKPOINT c001', "\n");

    my $eval_string =<<"EOL";
#   no warnings 'all';               # DOES NOT SUPPRESS
    local \$SIG{__WARN__} = sub {};  # DOES     SUPPRESS
#    BEGIN { Perl::debug('in Perl::eval_use() eval, about to call use $package_name...', "\\n"); }

#   use $package_name;      # DOES NOT SUPPRESS, THIS IS THE HIDDEN PERPETRATOR OF UNSUPPRESSABLE WARNINGS!  'Too late to call INIT block' inside multi-class module files
    require $package_name;  # DOES     SUPPRESS

#    BEGIN { Perl::debug('in Perl::eval_use() eval, ret from use $package_name...', "\\n"); }

    # detect compiled C++ code and call cpp_load() accordingly
    if (defined \&$package_name\:\:cpp_load) {
#        Perl::debug('in Perl::eval_use() eval, $package_name\:\:cpp_load() is defined, calling...', "\\n");
        $package_name\:\:cpp_load();
#        Perl::debug('in Perl::eval_use() eval, $package_name\:\:cpp_load() is defined, returned from call', "\\n");
    }
#    else { Perl::debug('in Perl::eval_use() eval, $package_name\:\:cpp_load() is NOT defined, skipping...', "\\n"); }
EOL

#    Perl::debug('in Perl::eval_use(), have $eval_string = ', "\n\n", $eval_string, "\n\n");
#    Perl::debug('in Perl::eval_use(), CHECKPOINT c002', "\n");

    $eval_string .=<<'EOL';
    my $INC_ref_post = {};
    foreach my $INC_key_post (keys %INC) {
        if (not exists $INC_ref_pre->{$INC_key_post}) {
            $INC_ref_post->{$INC_key_post} = $INC{$INC_key_post};
        }
    }
#    Perl::debug('in Perl::eval_use() eval, have $INC_ref_post = ', Dumper($INC_ref_post), "\n");
    Perl::CompileUnit::Module::Class::create_symtab_entries_and_accessors_mutators($INC_ref_post);
EOL
#    Perl::debug('in Perl::eval_use(), CHECKPOINT c003', "\n");

    my $eval_retval = eval $eval_string;
#    Perl::debug('in Perl::eval_use(), CHECKPOINT c004', "\n");

    # FOR DEBUG PURPOSES
#    if (defined $eval_retval) { print 'have $eval_retval = ', $eval_retval, "\n"; }
#    else { print 'have $eval_retval = undef, have $EVAL_ERROR = ', $EVAL_ERROR, "\n"; }

    if ($display_errors and (defined $EVAL_ERROR) and ($EVAL_ERROR ne q{})) {
        Perl::warning( 'WARNING WCOEU00, EVAL USE: Failed to eval-use package ' . q{'}
            . $package_name . q{'} . ', fatal error trapped and delayed' . "\n" );
        Perl::diag( '                                                Trapped the following error message...' . "\n\n" . $EVAL_ERROR . "\n" );
        Perl::warning("\n");
    }
#    Perl::debug('in Perl::eval_use(), CHECKPOINT c005', "\n");

    return $eval_retval;
}

# NEED UPGRADE: replace Data::Dumper with pure-Perl equivalent?
#sub DUMPER {
#    ( my $dumpee ) = @ARG;
#	die ('in Perl::DUMPER(), received undef argument, dying') if (not(defined($_[0])));
#    return '**UNDEF**' if ( not( defined $dumpee ) );
#    return $dumpee->DUMPER()
#        if ( defined( eval( q{$} . ref($dumpee) . q{::DUMPER} ) ) );
#    return Dumper($dumpee);
#}

# DEV NOTE: to make diag*() & debug*() & verbose*() & warning() truly variadic, do not accept args as first line in subroutine

# DEV NOTE: diag() is simply a wrapper around debug(), they are 100% equivalent; likewise diag_pause() and debug_pause()
sub diag { return debug(@ARG); }
sub diag_pause { return debug_pause(@ARG); }

# print debugging AKA diagnostic message to STDERR, if either PERL_DEBUG environmental variable or $Perl::DEBUG global variable are true
sub debug {
#    print {*STDERR} 'in debug(), have $ENV{PERL_DEBUG} = ' . $ENV{PERL_DEBUG} . "\n";

    # DEV NOTE, CORRELATION #rp017: default to off; if either variable is set to true, then do emit messages
    if ( $ENV{PERL_DEBUG} or $Perl::DEBUG ) { print {*STDERR} @ARG; }

#    if ( $ENV{PERL_DEBUG} or $Perl::DEBUG ) { print {*STDERR} "\e[1;31m $message \e[0m"; }  # print in red
    return 1;    # DEV NOTE: this must be here to avoid 'at -e line 0. INIT failed--call queue aborted.'... BUT WHY???
}

# same as debug(), except require <ENTER> to continue
sub debug_pause {
    if ( $ENV{PERL_DEBUG} or $Perl::DEBUG ) {
        print {*STDERR} @ARG;
        my $stdin_ignore = <STDIN>;
    }
    return 1;
}

# print verbose user-friendly message to STDOUT, if either PERL_VERBOSE environmental variable or $Perl::VERBOSE global variable are true
sub verbose {
    # DEV NOTE, CORRELATION #rp017: default to off; if either variable is set to true, then do emit messages
    if ( $ENV{PERL_VERBOSE} or $Perl::VERBOSE ) {
        print {*STDOUT} @ARG;
    }
    return 1;
}

# same as verbose(), except require <ENTER> to continue
sub verbose_pause {
    if ( $ENV{PERL_VERBOSE} or $Perl::VERBOSE ) {
        print {*STDOUT} @ARG;
        my $stdin_ignore = <STDIN>;
    }
    return 1;
}

# clear STDOUT, if either PERL_VERBOSE environmental variable or $Perl::VERBOSE global variable are true
sub verbose_clear_screen {
    if ( $ENV{PERL_VERBOSE} or $Perl::VERBOSE ) {
        if ( $OSNAME eq 'linux' ) {
            my $reset_path = can_run('reset');
            if ( defined $reset_path ) {
                system $reset_path;
            }
        }
        elsif ( $OSNAME eq 'MSWin32' ) {

            # cls is a shell builtin, not a command which can be found by can_run()
            system 'cls';
        }
        else {
            Perl::warning(
                q{WARNING WOSCLSC00: Unknown operating system '} . $OSNAME . q{' where 'linux' or 'Win32' expected, skipping screen clearing} . "\n" );
            return 0;
        }
    }
    return 1;
}

# print non-fatal warning message to STDERR, unless either PERL_WARNINGS environmental variable or $Perl::WARNINGS global variable are false
sub warning {
    # default to on; if either variable is set to false, then do not emit messages
    if ( ( ( not defined $ENV{PERL_WARNINGS} ) or $ENV{PERL_WARNINGS} )
        and $Perl::WARNINGS )
    {
        # NEED ADDRESS? the two following lines should be equivalent, but warn causes false ECOPAPL03
        print {*STDERR} @ARG;

        #        warn $message . "\n";
    }
    return 1;
}

sub analyze_class_symtab_entries {
    ( my $class ) = @ARG;
    my $retval    = q{};
    my @isa_array = eval q{@} . $class . q{::ISA};

    #print Dumper(\@isa_array);
    my $isa_string = join ', ', @isa_array;
    $retval .= '<<<<< BEGIN SYMTAB ENTRIES >>>>>' . "\n";
    $retval .= $class . ' ISA (' . $isa_string . ')' . "\n\n";

    #foreach my $entry ( sort keys %Perl::CompileUnit::Module::Header:: ) {
    my @keys = eval q{sort keys %} . $class . q{::};
    foreach my $entry (@keys) {

        #    my $glob = $Perl::CompileUnit::Module::Header::{$entry};
        my $glob = eval q{$} . $class . q{::{$entry}};

        $retval .= q{-} x 50;
        $retval .= "\n";
        $retval .= $entry . "\n";

        #    $retval .= ref \$glob, "\n";  # always says GLOB

        if ( defined ${$glob} ) {
            $retval .= "\t" . 'scalar';
            my $ref_type = ref ${$glob};
            if ( $ref_type ne q{} ) {
                $retval .= "\t" . $ref_type . 'ref';
            }
        }
        if ( @{$glob} ) {
            $retval .= "\t" . 'array';
        }
        if ( %{$glob} ) {
            $retval .= "\t" . 'hash';
        }
        if ( defined &{$glob} ) {
            $retval .= "\t" . 'code';
        }

        $retval .= "\n";
    }
    $retval .= '<<<<< END SYMTAB ENTRIES >>>>>' . "\n";
    return $retval;
}

# [ AUTOMATICALLY SET SYSTEM-DEPENDENT PATH VARIABLES ]
sub set_system_paths {
    ( my $target_file_name_config, my $target_package_name_config, my $target_file_name_pm, my $target_file_name_script ) = @ARG;
    if (( not exists $INC{$target_file_name_config} )
        or ( not defined $INC{$target_file_name_config} )
        )
    {
        Carp::croak 'BIZARRE ERROR EINPL00: Non-existent or undefined Perl %INC path entry for '
            . $target_file_name_config
            . ', reported from within '
            . $target_package_name_config
            . ', croaking';
    }
    my $target_config_pm_loaded = $INC{$target_file_name_config};
    if ( not -e $target_config_pm_loaded ) {
        Carp::croak 'BIZARRE ERROR EINPL01: Non-existent file ',
            $target_config_pm_loaded,
            ' supposedly loaded in %INC, reported from within ' . $target_package_name_config . ', croaking';
    }
    ( my $volume_loaded, my $directories_loaded, my $file_loaded ) = File::Spec->splitpath( $target_config_pm_loaded, my $no_file = 0 );
    my @directories_loaded_split = File::Spec->splitdir($directories_loaded);

    #print {*STDERR} 'in ' . $target_package_name_config . ', have pre-pop @directories_loaded_split = ', "\n", Dumper(@directories_loaded_split), "\n";

    # pop twice if empty entry on top
    if ( pop @directories_loaded_split eq q{} ) { pop @directories_loaded_split; }
    my $target_pm_wanted = File::Spec->catpath( $volume_loaded, ( File::Spec->catdir(@directories_loaded_split) ), $target_file_name_pm );

    #print {*STDERR} 'in ' . $target_package_name_config . ', have post-pop @directories_loaded_split = ', "\n", Dumper(@directories_loaded_split), "\n";
    #print {*STDERR} 'in ' . $target_package_name_config . ', have $target_config_pm_loaded = ', $target_config_pm_loaded, "\n";
    #print {*STDERR} 'in ' . $target_package_name_config . ', have $target_pm_wanted = ', $target_pm_wanted, "\n";

    my $target_pm_loaded = undef;
    if ( ( exists $INC{$target_file_name_pm} ) and ( defined $INC{$target_file_name_pm} ) ) {
        $target_pm_loaded = $INC{$target_file_name_pm};

        # BULK88 20150608 2015.159: Win32 Bug Fix
        #    if ( not -e $target_pm_loaded ) {
        if ( not -f $target_pm_loaded ) {
            Carp::croak 'BIZARRE ERROR EINPL02: Non-existent file ', $target_pm_loaded,
                ' supposedly loaded in %INC, reported from within ' . $target_package_name_config . ', croaking';
        }
    }

    # strip trailing '/'
    if ( ( substr $directories_loaded, -1, 1 ) eq q{/} ) {
        $directories_loaded = substr $directories_loaded, 0, -1;
    }

    #print {*STDERR} 'in ' . $target_package_name_config . ', have $directories_loaded = ', $directories_loaded, "\n";
    #print {*STDERR} 'in ' . $target_package_name_config . ', have $target_pm_loaded = ', ( $target_pm_loaded or '<undef>' ), "\n";

    my $target_scripts_found = [];
    my $target_pms_found     = [];

    # BULK88 20150608 2015.159: Win32 Bug Fix
    #foreach my $inc_path ( $directories_loaded, @INC ) {  # this doesn't work with Win32
    # DEV NOTE: search order precedence for script command is OS paths, path of loaded TARGET/Config.pm (this file), Perl INC paths
    foreach my $inc_path ( ( split ':', $ENV{PATH} ), File::Spec->catpath( $volume_loaded, $directories_loaded, '' ), @INC ) {

        #    print {*STDERR} 'in ' . $target_package_name_config . ', top of main foreach() loop, have $inc_path = ', $inc_path, "\n";
        my $sub_inc_paths = [];

        #    push @{$sub_inc_paths}, $inc_path;
        ( my $inc_volume, my $inc_directories, my $inc_file ) = File::Spec->splitpath( $inc_path, my $no_file = 1 );

        push @{$sub_inc_paths}, $inc_directories;

        my @directories_split = File::Spec->splitdir($inc_directories);
        pop @directories_split;
        push @{$sub_inc_paths}, File::Spec->catdir(@directories_split);
        pop @directories_split;
        push @{$sub_inc_paths}, File::Spec->catdir(@directories_split);

        #    print {*STDERR} 'in ' . $target_package_name_config . ', in main foreach() loop, have $sub_inc_paths = ', "\n", Dumper($sub_inc_paths), "\n";
        #    print {*STDERR} 'in ' . $target_package_name_config . ', in main foreach() loop, have $inc_volume = ', "\n", Dumper($inc_volume), "\n";
        #    print {*STDERR} 'in ' . $target_package_name_config . ', in main foreach() loop, have $inc_directories = ', "\n", Dumper($inc_directories), "\n";
        #    print {*STDERR} 'in ' . $target_package_name_config . ', in main foreach() loop, have $inc_file = ', "\n", Dumper($inc_file), "\n";

        my $possible_target_scripts = [];
        foreach my $sub_inc_path ( @{$sub_inc_paths} ) {
            push @{$possible_target_scripts}, File::Spec->catpath( $inc_volume, $sub_inc_path, $target_file_name_script );
            if ( $sub_inc_path ne q{} ) {
                push @{$possible_target_scripts}, File::Spec->catpath( $inc_volume, File::Spec->catdir( $sub_inc_path, 'script' ), $target_file_name_script );
                push @{$possible_target_scripts}, File::Spec->catpath( $inc_volume, File::Spec->catdir( $sub_inc_path, 'bin' ),    $target_file_name_script );
            }
            else {
                push @{$possible_target_scripts}, File::Spec->catpath( $inc_volume, 'script', $target_file_name_script );
                push @{$possible_target_scripts}, File::Spec->catpath( $inc_volume, 'bin',    $target_file_name_script );
            }
        }

        foreach my $possible_target_script ( @{$possible_target_scripts} ) {

            #        print {*STDERR} 'in ' . $target_package_name_config . ', have $possible_target_script = ', $possible_target_script, "\n";
            # BULK88 20150608 2015.159: Win32 Bug Fix
            #        if ( ( -e $possible_target_script ) and ( -x $possible_target_script ) ) {
            if ( ( -f $possible_target_script ) and ( $OSNAME eq 'MSWin32' ? 1 : -x $possible_target_script ) ) {
                my $is_unique = 1;
                foreach my $target_script_found ( @{$target_scripts_found} ) {
                    if ( $target_script_found eq $possible_target_script ) { $is_unique = 0; }
                }
                if ($is_unique) { push @{$target_scripts_found}, $possible_target_script; }
            }
        }

        if ( not defined $target_pm_loaded ) {
            my $possible_target_pm = File::Spec->catfile( $inc_path, $target_file_name_pm );

            # BULK88 20150608 2015.159: Win32 Bug Fix
            #        if ( -e $possible_target_pm ) {
            if ( -f $possible_target_pm ) {
                my $is_unique = 1;
                foreach my $target_pm_found ( @{$target_pms_found} ) {
                    if ( $target_pm_found eq $possible_target_pm ) {
                        $is_unique = 0;
                    }
                }
                if ($is_unique) { push @{$target_pms_found}, $possible_target_pm; }
            }
        }
    }

    #print {*STDERR} 'in ' . $target_package_name_config . ', have $target_scripts_found = ', "\n", Dumper($target_scripts_found), "\n";
    #print {*STDERR} 'in ' . $target_package_name_config . ', have $target_pms_found = ', "\n", Dumper($target_pms_found), "\n";

    if ( scalar @{$target_scripts_found} == 0 ) {
        die 'ERROR EEXRP00: Failed to find `' . $target_file_name_script . '` executable, dying' . "\n";
    }
    my $target_script_found = $target_scripts_found->[0];
    if ( scalar @{$target_scripts_found} > 1 ) {
        Perl::warning( 'WARNING WEXRP00: Found multiple `' . $target_file_name_script . '` executables, using first located, ' . 
            q{`} . $target_script_found . q{`} . '; other locations include ' . 
            (join ', ', (map {q{`} . $_ . q{`}} @{$target_scripts_found}[1 .. ((scalar @{$target_scripts_found} - 1))])) . "\n" );
    }

    my $target_pm_found = undef;
    if ( defined $target_pm_loaded ) {
        $target_pm_found = $target_pm_loaded;
    }
    else {

        if ( scalar @{$target_pms_found} == 0 ) {
            die 'ERROR EINRP00: Failed to find ' . $target_file_name_pm . ' module, croaking';
#            Carp::croak 'ERROR EINRP00: Failed to find ' . $target_file_name_pm . ' module, croaking';
        }
        foreach my $target_pm_found_single ( @{$target_pms_found} ) {
            # strip leading './' and '.\', for matching purposes only, do not actually save stripped filename
            my $target_pm_found_single_stripped = $target_pm_found_single;
            if (((substr $target_pm_found_single, 0, 2) eq './') or ((substr $target_pm_found_single, 0, 2) eq '.\\')) {
                substr $target_pm_found_single_stripped, 0, 2, q{};
            }
            if ( $target_pm_found_single_stripped eq $target_pm_wanted ) {
                $target_pm_found = $target_pm_found_single;
            }
        }
        if ( not defined $target_pm_found ) {
            Carp::croak 'ERROR EINRP01: Expected to find ', $target_pm_wanted, ' but instead found ', "\n", Dumper($target_pms_found), ', croaking';
        }
    }

    #print {*STDERR} 'in ' . $target_package_name_config . ', have $target_pm_found = ', $target_pm_found, "\n";
    #print {*STDERR} 'in ' . $target_package_name_config . ', have $target_script_found = ', $target_script_found, "\n";

    #( my $volume_target_pm, my $directories_target_pm, my $file_target_pm ) = File::Spec->splitpath( $target_pm_found, $no_file = 0 );
    #( my $volume_target_script, my $directories_target_script, my $file_target_script ) = File::Spec->splitpath( $target_script_found, $no_file = 0 );
    ( undef, my $directories_target_pm,     my $file_target_pm )     = File::Spec->splitpath( $target_pm_found,     $no_file = 0 );
    ( undef, my $directories_target_script, my $file_target_script ) = File::Spec->splitpath( $target_script_found, $no_file = 0 );

    #print {*STDERR} 'in ' . $target_package_name_config . ', have $volume_target_pm = ', $volume_target_pm, "\n";
    #print {*STDERR} 'in ' . $target_package_name_config . ', have $directories_target_pm = ', $directories_target_pm, "\n";
    #print {*STDERR} 'in ' . $target_package_name_config . ', have $file_target_pm = ', $file_target_pm, "\n";
    #print {*STDERR} 'in ' . $target_package_name_config . ', have $volume_target_script = ', $volume_target_script, "\n";
    #print {*STDERR} 'in ' . $target_package_name_config . ', have $directories_target_script = ', $directories_target_script, "\n";
    #print {*STDERR} 'in ' . $target_package_name_config . ', have $file_target_script = ', $file_target_script, "\n";

    my @directories_target_pm_split     = File::Spec->splitdir($directories_target_pm);
    my @directories_target_script_split = File::Spec->splitdir($directories_target_script);
    my @directories_base_split          = ();

    for my $i ( 0 .. ( ( scalar @directories_target_pm_split ) - 1 ) ) {
        if ( $directories_target_pm_split[$i] eq $directories_target_script_split[$i] ) {
            push @directories_base_split, $directories_target_pm_split[$i];
        }
        else {
            for my $j ( 0 .. ( $i - 1 ) ) {
                shift @directories_target_pm_split;
                shift @directories_target_script_split;
            }
            last;
        }
    }

    #print {*STDERR} 'in ' . $target_package_name_config . ', have @directories_base_split = ', "\n", Dumper(\@directories_base_split), "\n";
    #print {*STDERR} 'in ' . $target_package_name_config . ', have @directories_target_pm_split = ', "\n", Dumper(\@directories_target_pm_split), "\n";
    #print {*STDERR} 'in ' . $target_package_name_config . ', have @directories_target_script_split = ', "\n", Dumper(\@directories_target_script_split), "\n";

    my $MY_BASE_PATH;
    my $MY_INCLUDE_PATH;
    my $MY_SCRIPT_PATH;
    my $MY_CORE_PATH;

    # NEED FIX: how do we catpath() with some $volume instead of catdir() below, without breaking relative paths?
    $MY_BASE_PATH = File::Spec->catpath( $volume_loaded, File::Spec->catdir(@directories_base_split), '' );
    if ( $MY_BASE_PATH eq q{} ) {
        $MY_INCLUDE_PATH = File::Spec->catpath( $volume_loaded, File::Spec->catdir(@directories_target_pm_split),     '' );
        $MY_SCRIPT_PATH  = File::Spec->catpath( $volume_loaded, File::Spec->catdir(@directories_target_script_split), '' );
        #print {*STDERR} 'in ' . $target_package_name_config . ', have $MY_BASE_PATH eq q{} = ', $MY_BASE_PATH, "\n";
    }
    else {
        $MY_INCLUDE_PATH = File::Spec->catdir( $MY_BASE_PATH, @directories_target_pm_split );
        $MY_SCRIPT_PATH  = File::Spec->catdir( $MY_BASE_PATH, @directories_target_script_split );
        #print {*STDERR} 'in ' . $target_package_name_config . ', have $MY_BASE_PATH ne q{} ', $MY_BASE_PATH, "\n";
    }

    foreach my $inc_path (@INC) {
        $MY_CORE_PATH = File::Spec->catdir( $inc_path, 'CORE' );
        my $inc_core_perl_h_path = File::Spec->catfile( $MY_CORE_PATH, 'perl.h' );
        if   ( ( -e $inc_core_perl_h_path ) and ( -r $inc_core_perl_h_path ) and ( -f $inc_core_perl_h_path ) ) { last; }
        else                                                                                                    { $MY_CORE_PATH = q{}; }
    }

    #print {*STDERR} 'in ' . $target_package_name_config . ', have $MY_BASE_PATH = ', $MY_BASE_PATH, "\n";
    #print {*STDERR} 'in ' . $target_package_name_config . ', have $MY_INCLUDE_PATH = ', $MY_INCLUDE_PATH, "\n";
    #print {*STDERR} 'in ' . $target_package_name_config . ', have $MY_SCRIPT_PATH = ', $MY_SCRIPT_PATH, "\n";
    #print {*STDERR} 'in ' . $target_package_name_config . ', have $MY_CORE_PATH = ', $MY_CORE_PATH, "\n";
    
    return [$MY_BASE_PATH, $MY_INCLUDE_PATH, $MY_SCRIPT_PATH, $MY_CORE_PATH];
}

# [[[ OPERATIONS SPECIAL ]]]

my $file_name_config    = 'Perl/Config.pm';    # this file name
my $package_name_config = 'Perl::Config';      # this file's primary package name
my $file_name_pm        = 'Perl.pm';
my $file_name_script    = 'perl';
($BASE_PATH, $INCLUDE_PATH, $SCRIPT_PATH, $CORE_PATH) = @{set_system_paths($file_name_config, $package_name_config, $file_name_pm, $file_name_script)};

1;                                                     # end of package


# [[[ ADDITIONAL PACKAGES SPECIAL ]]]
# export system paths to main:: namespace for use by PMC files
package main;

# [[[ OO CLASS PROPERTIES SPECIAL ]]]
# DEV NOTE: duplicate lines to avoid 'used only once' warnings
our $BASE_PATH = $Perl::BASE_PATH;
$BASE_PATH = $Perl::BASE_PATH;
our $INCLUDE_PATH = $Perl::INCLUDE_PATH;
$INCLUDE_PATH = $Perl::INCLUDE_PATH;
our $SCRIPT_PATH  = $Perl::SCRIPT_PATH;
$SCRIPT_PATH  = $Perl::SCRIPT_PATH;

1;                                                 # end of package
