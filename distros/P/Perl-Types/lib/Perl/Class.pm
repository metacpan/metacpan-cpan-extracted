#
# This file is part of Perl-Types
#
# This software is copyright (c) 2025 by Auto-Parallel Technologies, Inc.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
# [[[ HEADER ]]]
package Perl::Class;
use strict;
use warnings;
use Perl::Config;  # don't use Perl::Types inside itself, in order to avoid circular includes
our $VERSION = 0.006_000;

# [[[ OO INHERITANCE ]]]
# BASE CLASS HAS NO INHERITANCE
# "The Buck Stops Here"

# [[[ CRITICS ]]]
## no critic qw(ProhibitStringyEval)  # SYSTEM DEFAULT 1: allow eval()
## no critic qw(ProhibitAutoloading RequireArgUnpacking)  # SYSTEM SPECIAL 2: allow Autoload & read-only @ARG
## no critic qw(ProhibitExcessComplexity)  # SYSTEM SPECIAL 5: allow complex code inside subroutines, must be after line 1
## no critic qw(ProhibitDeepNests)  # SYSTEM SPECIAL 7: allow deeply-nested code
## no critic qw(ProhibitNoStrict)  # SYSTEM SPECIAL 8: allow no strict
## no critic qw(RequireBriefOpen)  # SYSTEM SPECIAL 10: allow complex processing with open filehandle

# [[[ INCLUDES ]]]
use File::Basename;
use File::Spec;  # for splitpath() to test if @INC file entries are absolute or relative
use Scalar::Util 'reftype';  # to test for HASH ref when given initialization values for new() method
use perltypesnamespaces_generated;  # load auto-generated skip-list data

# [[[ OO PROPERTIES ]]]
# BASE CLASS HAS NO PROPERTIES

# [[[ OO PROPERTIES SPECIAL ]]]
# after compiling but before runtime: create symtab entries & accessors/mutators
INIT { create_symtab_entries_and_accessors_mutators(\%INC); }

# [[[ SUBROUTINES & OO METHODS ]]]

# Perl object constructor, SHORT FORM
sub new {
    no strict;
    if ( not defined ${ $_[0] . '::properties' } ) {
        croak 'ERROR ECOOOCO00, SOURCE CODE, OO OBJECT CONSTRUCTOR: Undefined hashref $properties for class ' . $_[0] . ', croaking' . "\n";
    }
#    return bless { %{ ${ $_[0] . '::properties' } } }, $_[0];  # DOES NOT INHERIT PROPERTIES FROM PARENT CLASSES
#    return bless { %{ ${ $_[0] . '::properties' } }, %{ properties_inherited($_[0]) } }, $_[0];  # WHAT DOES THIS DO???
#    return bless { %{ properties_inherited($_[0]) } }, $_[0];  # WORKS PROPERLY, BUT DOES NOT INITIALIZE PROPERTIES
    return bless { %{ properties_inherited_initialized($_[0], $_[1]) } }, $_[0];
}


# allow properties to be initialized by passing them as hashref arg to new() method
sub properties_inherited_initialized {
#    print {*STDERR} 'in Class::properties_inherited_initialized(), top of subroutine, received $ARG[0] = ', $ARG[0], "\n";
#    print {*STDERR} 'in Class::properties_inherited_initialized(), top of subroutine, received $ARG[1] = ', Dumper($ARG[1]), "\n";

    my $properties_inherited = properties_inherited($_[0]);

    if (defined $_[1]) {
        if ((not defined reftype($_[1])) or (reftype($_[1]) ne 'HASH')) {
            croak 'ERROR ECOOOCO01, SOURCE CODE, OO OBJECT CONSTRUCTOR: Initialization values for new() method must be key-value pairs inside a hash reference, croaking';
        }
        foreach my $property_name (sort keys %{$_[1]}) {
            if (not exists $properties_inherited->{$property_name}) {
                croak 'ERROR ECOOOCO02, SOURCE CODE, OO OBJECT CONSTRUCTOR: Attempted initialization of invalid property ' . q{'} . $property_name . q{'} . ', croaking';
            }
            $properties_inherited->{$property_name} = $_[1]->{$property_name};
        }
    }

    return $properties_inherited;
}


# inherit properties from parent and grandparent classes
sub properties_inherited {
#    print {*STDERR} 'in Class::properties_inherited(), top of subroutine, received $ARG[0] = ', $ARG[0], "\n";
    no strict;

    # always keep self class' $properties
    my $properties = { %{ ${ $ARG[0] . '::properties' } } };

    # inherit parent & (great*)grandparent class' $properties
    foreach my $parent_package_name (@{ $ARG[0] . '::ISA' }) {
#        print {*STDERR} 'in Class::properties_inherited(), top of foreach() loop, have $parent_package_name = ', $parent_package_name, "\n";

        # DEV NOTE: changed from original RPerl version, WBRASWELL 20230219
        # DEV NOTE: changed from original RPerl version, WBRASWELL 20230219
        # DEV NOTE: changed from original RPerl version, WBRASWELL 20230219
        # base class has no $properties, skip
        if ($parent_package_name eq 'Perl::Class') {
        # Perl base class & Eyapp classes have no $properties, skip
#        if (($parent_package_name eq 'Perl::Class') or
#            ($parent_package_name eq 'Parse::Eyapp::Node')) {
                next;
        }

        # recurse to get inherited $properties
        my $parent_and_grandparent_properties = properties_inherited($parent_package_name);

        # self class' $properties override inherited $properties, same as C++
        foreach my $parent_property_key (keys %{ $parent_and_grandparent_properties }) {
            if (not exists $properties->{$parent_property_key}) {
                $properties->{$parent_property_key} = $parent_and_grandparent_properties->{$parent_property_key};
            }
        }
    }
    return $properties;
}


# DEV NOTE, RPERL REFACTOR: copied create_symtab_entries_and_accessors_mutators() from the old 'lib/RPerl/CompileUnit/Module/Class.pm' module
# NEED ANSWER: does this subroutine really belong here in 'lib/Perl/Class.pm', or do we need to create `lib/Perl/HelperFunctions.pm` etc?
# create symbol table entries for all Perl::Types subroutines/methods, and accessors/mutators for all Perl::Types class properties
sub create_symtab_entries_and_accessors_mutators {
    (my $INC_ref) = @ARG;
#    $Perl::DEBUG                   = 1;
#    $Perl::VERBOSE                 = 1;

    # add calling .pl driver to INC for subroutine activation;
    # DEV NOTE: should be safe to use basename() here instead of fileparse(), because $PROGRAM_NAME should never end in a directory
    $INC{ basename($PROGRAM_NAME) } = $PROGRAM_NAME;

#    Perl::diag('in Class::INIT() block, have $INC_ref =' . "\n" . Dumper($INC_ref) . "\n");
#    Perl::diag('in Class::INIT() block, have $perltypesnamespaces_generated::CORE =' . "\n" . Dumper($perltypesnamespaces_generated::CORE) . "\n");

    my $module_filename_long;           # string
    my $module_filename_long_processed = {}; # hashref::boolean
    my $module_file_line_remainder;     # string
    my $use_perltypes;                  # boolean
    my $inside_package;                 # boolean
    my $package_name;                   # string
    my $package_name_underscores;       # string
    my $namespace_root;                 # string
    my $object_properties;              # hashref
    my $object_properties_string;       # string
    my $object_properties_types;        # hashref
    my $inside_object_properties;       # boolean
    my $subroutine_type;                # string
    my $subroutine_name;                # string
    my $CHECK;                          # string
    my $inside_subroutine;              # boolean
    my $inside_subroutine_header;       # boolean
    my $inside_subroutine_arguments;    # boolean
    my $subroutine_arguments_line;      # string
    my $TYPES_SUPPORTED = {};           # hashref::string

#    Perl::diag(q{in Class::INIT() block, have $PROGRAM_NAME = '} . $PROGRAM_NAME . "'\n");

    foreach my $type (@{$perltypes::SUPPORTED}, @{$perltypes::SUPPORTED_SPECIAL}) {
        $TYPES_SUPPORTED->{$type} = 1;
    }
#    Perl::diag(q{in Class::INIT() block, have $TYPES_SUPPORTED = } . Dumper($TYPES_SUPPORTED) . "\n");

    MODULE_SCAN: foreach my $module_filename_short ( sort keys %{$INC_ref} ) {
#        Perl::diag('in Class::INIT() block, have $module_filename_short = ', q{'}, $module_filename_short, q{'}, "\n");

        # skip special entry created by Filter::Util::Call
        if ( $module_filename_short eq '-e' ) {
            next;
        }
        # skip autosplit index files
        elsif (( substr $module_filename_short, -3, 3 ) eq '.ix') {
            next;
        }
        # skip test files
        elsif (( substr $module_filename_short, -2, 2 ) eq '.t') {
            next;
        }

        $module_filename_long = $INC{$module_filename_short};
#        Perl::diag( 'in Class::INIT() block, have $module_filename_long = ' . $module_filename_long . "\n" );

        # determine if both short & long module filenames are absolute;
        # file names w/out any volume or directories are not absolute, allows 'use Foo;' where "Foo.pm" exists in current directory w/out any volume or directory
        my $module_is_absolute = 0;
        if (defined $module_filename_long) {
            # skip already-processed modules, triggered by imaginary $module_filename_short created by Perl in %INC when one .pm file contains multiple packages
            if (exists $module_filename_long_processed->{$module_filename_long}) {
#                Perl::diag( 'in Class::INIT() block, skipping due to already-processed PM file, have $module_filename_long = ', q{'}, $module_filename_long, q{'}, ', $module_filename_short = ', q{'}, $module_filename_short, q{'}, "\n" );
                next;
            }
            $module_filename_long_processed->{$module_filename_long} = 1;

            (my $module_volume, my $module_directories, my $module_file) = File::Spec->splitpath( $module_filename_long );
#            Perl::diag( 'in Class::INIT() block, have $module_volume = ' . q{'} . $module_volume . q{'} . "\n" );
#            Perl::diag( 'in Class::INIT() block, have $module_directories = ' . q{'} . $module_directories . q{'} . "\n" );
#            Perl::diag( 'in Class::INIT() block, have $module_file = ' . q{'} . $module_file . q{'} . "\n" );
#            if (($module_volume ne q{}) or ($module_directories ne q{})) {  # DEV NOTE: this isn't right, if the volume is empty then it can't be absolute regardless of directories
            if ($module_volume ne q{}) {
                if ( $module_filename_long eq $module_filename_short ) {
                    # absolute module names include volume, and must match both short & long filenames
                    $module_is_absolute = 1;
                }
            }
        }

#        Perl::diag( 'in Class::INIT() block, have $module_is_absolute = ' . $module_is_absolute . "\n" );

        # skip absolute file names (such as Komodo's perl5db.pl) which came from a runtime `require $scalar` or `require 'foo.pm'`,
        # because we can not determine the correct package from the absolute path name, and we don't know how to figure out which part was in @INC from the absolute path;
        if ((not defined $module_filename_long) or $module_is_absolute) {
#            Perl::diag( 'in Class::INIT() block, skipping due to undefined or absolute module filename' . "\n" );
            next;
        }

        # skip already-compiled files with PMC counterparts
        if (-e ($module_filename_long . 'c')) {
#            Perl::diag( 'in Class::INIT() block, skipping due to already-compiled PMC file' . "\n" );
            next;
        }

        $module_file_line_remainder  = q{};
        $use_perltypes                   = 0;
        $inside_package              = 0;
        $package_name                = q{};
        $CHECK                       = $Perl::CHECK;    # reset data type checking to Perl::Types default for every file
        $object_properties_string    = q{};
        $object_properties_types     = {};
        $inside_object_properties    = 0;
        $inside_subroutine           = 0;
        $inside_subroutine_header    = 0;
        $inside_subroutine_arguments = 0;
        $subroutine_arguments_line   = q{};

        $namespace_root = Perl::filename_short_to_namespace_root_guess($module_filename_short);
        # detect if this module declares OO properties
        my $has_properties = 0;
        if (defined $module_filename_long) {
            open my $FH, '<', $module_filename_long or croak $OS_ERROR;
            local $/ = undef;
            my $text = <$FH>;
            close $FH or croak $OS_ERROR;
            $has_properties = 1 if $text =~ /\bour\s+hashref\s+\$properties\b/;
        }

#        Perl::diag(q{in Class::INIT() block, have $namespace_root = '} . $namespace_root . "'\n");  # repeated below, inside if() statement for concise debug output

        # DEV NOTE: avoid error...
        # Name "perltypesnamespaces_generated::PERLTYPES_DEPS" used only once: possible typo
        my $tmp = $perltypesnamespaces_generated::NONCOMPILED;
        $tmp = $perltypesnamespaces_generated::CORE;
        $tmp = $perltypesnamespaces_generated::PERLTYPES_DEPS;

        # do NOT skip these file(s): compilable driver, modules with OO properties, or those not in skip-lists
        if (   (substr($module_filename_short, -13, 13) eq 'Compilable.pm')
            or $has_properties
            or (   (not exists $perltypesnamespaces_generated::NONCOMPILED->{$namespace_root})
                and (not exists $perltypesnamespaces_generated::CORE->{$namespace_root})
                and (not exists $perltypesnamespaces_generated::PERLTYPES_DEPS->{$namespace_root})
                and (not exists $perltypesnamespaces_generated::PERLTYPES_FILES->{$module_filename_short})
               )
           )
        {
#            Perl::diag("\n\n", '=' x 50, "\n" );
#            Perl::diag( 'in Class::INIT() block, not skipping due to CORE & PERLTYPES_DEPS namespaces, $module_filename_long = ' . $module_filename_long . "\n" );
#            Perl::diag(q{in Class::INIT() block, have $namespace_root = '} . $namespace_root . "'\n");

            # debug: report module reaching scan stage (has properties = $has_properties)
            Perl::diag("DEBUG: scanning module short='$module_filename_short', long='$module_filename_long', root='$namespace_root', has_properties=$has_properties\n");
            # proceed to parse this module for OO properties
            open my $MODULE_FILE, '<', $module_filename_long or croak $OS_ERROR;
        MODULE_FILE_LINE_LOOP:
            while ( my $module_file_line = <$MODULE_FILE> ) {
        MODULE_FILE_LINE_LOOP_INNER:
                chomp $module_file_line;

#                Perl::diag('in Class::INIT() block, have $module_file_line =' . "\n" . $module_file_line . "\n");

                # set data type checking mode
                if ( $module_file_line =~ /^\s*\#\s*\<\<\<\s*TYPE_CHECKING\s*\:\s*(\w+)\s*\>\>\>/xms ) {

#                    Perl::diag( "in Class::INIT() block, have \$module_filename_long = '$module_filename_long'\n" );
                    if ($inside_subroutine) {

#                        Perl::diag( 'in Class::INIT() block, found <<< TYPE_CHECKING: ' . $1 . ' >>> while inside subroutine ' . $subroutine_name . '(), aborting Perl::Types activation of entire file' . "\n" );
                        last;
                    }
                    else {
#                        Perl::diag( 'in Class::INIT() block, found <<< TYPE_CHECKING: ' . $1 . " >>>\n" );
                        $CHECK = $1;
                    }
                }

                # skip single-line comments
                next if ( $module_file_line =~ /^\s*\#/xms );

                # skip multi-line POD comments
                if ( $module_file_line =~ /^\=(\w+)/xms ) {

#                    Perl::diag("in Class::INIT() block, skipping multi-line POD comment, have \$1 = '$1'\n");
                    $module_file_line = <$MODULE_FILE>;
                    if ( not defined $module_file_line ) {
                        Perl::warning( "End of file '$module_filename_long' reached without finding '=cut' end of multi-line POD comment '=$1'\n" );
                        last;
                    }
                    while ( $module_file_line !~ /^\=cut/xms ) {
                        if ( not defined $module_file_line ) {
                            Perl::warning( "End of file '$module_filename_long' reached without finding '=cut' end of multi-line POD comment '=$1'\n" );
                            last;
                        }
                        $module_file_line = <$MODULE_FILE>;
                    }
                    next;
                }

                # skip multi-line heredocs
                if (   ( $module_file_line =~ /\=\s*\<\<\s*(\w+)\s*\;\s*$/xms )
                    or ( $module_file_line =~ /\=\s*\<\<\s*\'(\w+)\'\s*\;\s*$/xms )
                    or ( $module_file_line =~ /\=\s*\<\<\s*\"(\w+)\"\s*\;\s*$/xms ) )
                {
                    #                    Perl::diag("in Class::INIT() block, skipping multi-line heredoc, have \$1 = '$1'\n");
                    $module_file_line = <$MODULE_FILE>;
                    if ( not defined $module_file_line ) {
                        Perl::warning( "End of file '$module_filename_long' reached without finding '$1' end of multi-line heredoc string\n" );
                        last;
                    }
                    while ( $module_file_line !~ /^$1/xms ) {
                        $module_file_line = <$MODULE_FILE>;
                        if ( not defined $module_file_line ) {
                            Perl::warning( "End of file '$module_filename_long' reached without finding '$1' end of multi-line heredoc string\n" );
                            last;
                        }
                    }
                    next;
                }

                # skip __DATA__ footer
                if ( $module_file_line eq '__DATA__' ) {
#                    if ($inside_subroutine) { Perl::diag( 'in Class::INIT() block, skipping __DATA__ footer while inside subroutine ' . $subroutine_name . '(), aborting Perl::Types activation of entire file' . "\n" ); }
#                    else { Perl::diag('in Class::INIT() block, skipping __DATA__ footer' . "\n"); }
                    last;
                }

                # skip __END__ footer
                if ( $module_file_line eq '__END__' ) {
#                    if ($inside_subroutine) { Perl::diag( 'in Class::INIT() block, skipping __END__ footer while inside subroutine ' . $subroutine_name . '(), aborting Perl::Types activation of entire file' . "\n" ); }
#                    else { Perl::diag('in Class::INIT() block, skipping __END__ footer' . "\n"); }
                    last;
                }

                if ($module_file_line =~ m/sub\s*/xms) {
#                    Perl::diag("in Class::INIT() block, have \$module_file_line =\n$module_file_line\n");
                }

                # create ops/types reporting subroutine & accessor/mutator object methods for each Perl::Types package

                # user-style Perl::Types header: accept 'use Perl::Types;', 'use perltypes;', or 'use types;'
                if ( $module_file_line =~ /^\s*use\s+((?:Perl::Types|perltypes|types))\s*;/xms ) {
#                    Perl::diag(q{in Class::INIT() block, found user-style Perl::Types header '} . $1 . q{' in $module_filename_short = } . $module_filename_short . "\n");
                    $use_perltypes = 1;
                    next;
                }

                # package declaration
                if ( $module_file_line =~ /^\s*package\s+/xms ) {
#                    Perl::diag( 'in Class::INIT() block, found package declaration', "\n" );

                    # object properties, save types from just-finished package
                    if ($inside_package) {
#                        Perl::diag( 'in Class::INIT() block, already $inside_package, about to call save_object_properties_types()...', "\n" );
                        $object_properties_types = save_object_properties_types( $package_name, $object_properties_string, $object_properties_types );
#                        Perl::diag( 'in Class::INIT() block, already $inside_package, ret from save_object_properties_types()', "\n" );
                        $object_properties_string = q{};
                    }
                    $inside_package = 1;

                    # one-line package declaration, indexed by PAUSE unless listed in no_index in Makefile.PL
                    if ( $module_file_line =~ /^\s*package\s+(\w+(::\w+)*)\;.*$/xms ) {
                        $package_name = $1;
#                        Perl::diag( 'in Class::INIT() block, one-line package declaration, have $package name = ' . $package_name . "\n" );
                    }

                    # two-line package declaration, not indexed by PAUSE
                    elsif ( $module_file_line =~ /^\s*package\s*\#\s*hide.*$/xms ) {    # EX.    package  # hide from PAUSE indexing
                        $module_file_line = <$MODULE_FILE>;
                        chomp $module_file_line;
                        if ( $module_file_line =~ /^\s*(\w+(::\w+)*)\;.*$/xms ) {
                            $package_name = $1;
#                            Perl::diag( 'in Class::INIT() block, two-line package declaration, have $package name = ' . $package_name . "\n" );
                        }
                        else {
                            Perl::warning( q{Improperly formed two-line package declaration found in file '}
                                . $module_filename_long
                                . q{' near '}
                                . $module_file_line
                                . q{'});
                        }
                    }
                    else {
                        Perl::warning( q{Improperly formed package declaration found in file '}
                            . $module_filename_long
                            . q{' near '}
                            . $module_file_line
                            . q{'});
                    }

                    if ($inside_subroutine) {
#                            Perl::diag( 'in Class::INIT() block, have $package name = ' . $package_name . 'while inside subroutine ' . $subroutine_name . '(), aborting Perl::Types activation of entire file' . "\n" );
                        last;
                    }
#                    else { Perl::diag( 'in Class::INIT() block, have $package name = ' . $package_name . "\n" ); }

                    # system-style Perl::Types header: 3 different lines containing 'use strict;', 'use warnings;', 
                    # then any of 'use Perl::Types;', 'use perltypes;', or 'use types;';
                    # don't check for $VERSION due to numerous un-versioned subtypes
                    if ( not $use_perltypes ) {
                        # first line, check strict
                        $module_file_line = <$MODULE_FILE>;
                        chomp $module_file_line;
                        if ($module_file_line !~ /^\s*use\s+strict\s*;/xms) {
#                            Perl::diag(q{in Class::INIT() block, failed to find Perl::Types header line 'use strict;' for $module_filename_short = } . $module_filename_short . ', aborting Perl::Types activation of entire file' . "\n");
                            next MODULE_FILE_LINE_LOOP;
                        }

                        # second line, check warnings
                        $module_file_line = <$MODULE_FILE>;
                        chomp $module_file_line;
                        if ($module_file_line !~ /^\s*use\s+warnings\s*;/xms) {
#                            Perl::diag(q{in Class::INIT() block, failed to find Perl::Types header line 'use warnings;' for $module_filename_short = } . $module_filename_short . ', aborting Perl::Types activation of entire file' . "\n");
                            next MODULE_FILE_LINE_LOOP;

                        }

                        # third line, accept any of the Perl::Types pragmas
                        $module_file_line = <$MODULE_FILE>;
                        chomp $module_file_line;
                        if ($module_file_line !~ /^\s*use\s+((?:Perl::Types|perltypes|types))\s*;/xms) {
#                            Perl::diag(q{in Class::INIT() block, failed to find Perl::Types header line 'use Perl::Types;' or 'use perltypes;' or 'use types;' for $module_filename_short = } . $module_filename_short . ', aborting Perl::Types activation of entire file' . "\n");
                            next MODULE_FILE_LINE_LOOP;
                        }

#                        Perl::diag(q{in Class::INIT() block, found system-style Perl::Types header '} . $1 . q{' in $module_filename_short = } .  $module_filename_short . "\n");
                        $use_perltypes = 1;
                    }

#                    Perl::diag(q{in Class::INIT() block, have $use_perltypes, enabling package in $module_filename_short = } . $module_filename_short . "\n");

# ops/types reporting subroutine
# DEV NOTE, CORRELATION #rp018: Perl::DataStructure::Array & Hash can not 'use Perl::Types;' so they are skipped in the header-checking loop above, their *__MODE_ID() subroutines are not created below
                    $package_name_underscores = $package_name;
                    $package_name_underscores =~ s/::/__/g;
                    if ( not eval( 'defined &main::' . $package_name_underscores . '__MODE_ID' ) ) {
                        eval( '*main::' . $package_name_underscores . '__MODE_ID = sub { return 0; };' )    # PERLOPS_PERLTYPES is 0

                         #                        eval(     'sub main::' . $package_name_underscores . '__MODE_ID { return 0; }' ) # equivalent to previous line
                            or croak($EVAL_ERROR);
                        if ($EVAL_ERROR) { croak($EVAL_ERROR); }
                    }

                    next;
                }

                # object properties, remember types for deferred accessor/mutator generation below
                if ( $module_file_line =~ /^\s*our\s+hashref\s+\$properties/xms ) {

                    # hard-coded example
                    #our hashref $properties = { foo => my arrayref::Foo::Bar $TYPED_foo = undef, quux => my hashref::integer $TYPED_quux = {a => 12, b => 21} };
                    $inside_object_properties = 1;
                    chomp $module_file_line;    # strip trailing newline
                    $object_properties_string .= $module_file_line;
                    next;
                }

                # create symbol table entries for methods and plain-old non-method subroutines
                # DEPRECATED, CORRELATION #rp120: old subroutine header
#                if ( $module_file_line =~ /^\s*our\s+([\w:]+)\s+\$(\w+)\s+\=\s+sub\s+\{/xms ) {
#                if ( $module_file_line =~ /^\s*sub\s+(\w+)\s*\{[\s\n\r]*\{\s*my\s+([\w:]+)\s+\$RETURN_TYPE\s*\};/xms ) {  # can't match multi-line content against single-line input

                # first half of subroutine header (name)
                if ( $module_file_line =~ /^\s*sub\s+(\w+)\s*\{\s*(.*)$/xms ) {
#                    Perl::diag(q{in Class::INIT() block, found first half of subroutine header for } . $1 . q{() in $module_filename_short = } . $module_filename_short . "\n");
                    if ($inside_subroutine_header) {
#                        Perl::diag(q{in Class::INIT() block, found first half of subroutine header for } . $1 . q{() when already marked as $inside_subroutine_header for } . $subroutine_name . q{(), skipping activation of non-Perl::Types subroutine } . $subroutine_name . q{() in $module_filename_short = } . $module_filename_short . "\n");
                        $inside_subroutine_header = 0;
                    }
                    else {
                        $inside_subroutine_header = 1;
                    }
                    $inside_object_properties = 0;
                    $inside_subroutine = 0;
                    if ( not $use_perltypes ) {
#                        Perl::diag(q{in Class::INIT() block, do NOT have $use_perltypes, skipping subroutine } . $1 . q{() in $module_filename_short = } . $module_filename_short . "\n");
                        $subroutine_name = q{};
                        next;
                    }
#                    else { Perl::diag(q{in Class::INIT() block, have $use_perltypes, looking for second half of header for subroutine } . $1 . q{() in $module_filename_short = } . $module_filename_short . "\n"); }

                    # NEED ANSWER: should this be a croak() or die() statement instead of just an abort?
                    if ($inside_subroutine_arguments) {
                        Perl::warning( q{WARNING WCOPR00, PRE-PROCESSOR: Found header for subroutine $subroutine_name = } . $1 . '() while we should still be inside arguments of subroutine ' . $subroutine_name . '(), aborting Perl::Types activation of entire file' . "\n" );
                        $subroutine_name = q{};
                        last;    # last line of file
                    }

                    # DEV NOTE, CORRELATION #rp053: even with the upgrade to normal Perl subroutine headers, we must still activate subroutines w/out args or when type-checking is explicitly disabled with CHECK OFF, in order for Perl::Exporter to work properly, presumably because Exporter.pm runs before Class.pm and thus we can not test for the existence of __CHECKED_*() subroutines in Perl::Exporter::import()
                    # activate previous subroutine, no arguments
                    if ($inside_subroutine) {
#                        Perl::diag( q{in Class::INIT() block, have $inside_subroutine = } . $inside_subroutine . q{, about to call activate_subroutine_args_checking() while inside subroutine } . $subroutine_name . '(), no arguments assumed' . "\n" );
                        activate_subroutine_args_checking( $package_name, $subroutine_name, $subroutine_type, q{}, $module_filename_long );
                    }

                    $subroutine_name = $1;

                    # enable single-line subroutine headers, continue parsing same input line if it contains more data
                    if ($2 ne q{}) {
                        $module_file_line = $2;
                        goto MODULE_FILE_LINE_LOOP_INNER;
                    }

                    next;
                }

                # second half of subroutine header (return type), TYPO WARNING
                if ( $module_file_line =~ /^\s*\{\s*my\s+([\w:]+)\s+\$RETURN_VALUE\s*\}\s*;/xms ) {
                    Perl::warning(q{WARNING WCOPR01, PRE-PROCESSOR: Likely typo of '$RETURN_VALUE' instead of '$RETURN_TYPE' in subroutine } . $subroutine_name . q{() in $module_filename_short = } . $module_filename_short . "\n");
                }
                # second half of subroutine header (return type)
                if ( $module_file_line =~ /^\s*\{\s*my\s+([\w:]+)\s+\$RETURN_TYPE\s*\}\s*;\s*(.*)/xms ) {
#                    Perl::diag(q{in Class::INIT() block, found second half of subroutine header for } . $subroutine_name . q{() in $module_filename_short = } . $module_filename_short . "\n");
                    if ($inside_subroutine_header) {
                        $inside_subroutine_header = 0;
                    }
                    else {
#                        Perl::diag(q{in Class::INIT() block, found second half of subroutine header with $RETURN_TYPE } . $1 . q{ when not already marked as $inside_subroutine_header for } . $subroutine_name . q{(), skipping activation of unknown subroutine in $module_filename_short = } . $module_filename_short . "\n");
                        next;
                    }
                    $subroutine_type = $1;

#                    Perl::diag( q{in Class::INIT() block, have $subroutine_type = } . $subroutine_type . q{, and $subroutine_name = } . $subroutine_name . "()\n" );
#                    Perl::diag( q{in Class::INIT() block, have $CHECK = '} . $CHECK . "'\n" );

                    # DEV NOTE, CORRELATION #rp053: even with the upgrade to normal Perl subroutine headers, we must still activate subroutines w/out args or when type-checking is explicitly disabled with CHECK OFF, in order for Perl::Exporter to work properly, presumably because Exporter.pm runs before Class.pm and thus we can not test for the existence of __CHECKED_*() subroutines in Perl::Exporter::import()
                    if ( $CHECK eq 'OFF' ) {
##                        Perl::diag( q{in Class::INIT() block, CHECK IS OFF, about to call activate_subroutine_args_checking()...} . "\n" );
                        activate_subroutine_args_checking( $package_name, $subroutine_name, $subroutine_type, q{}, $module_filename_long );
                    }
                    elsif ( ( $CHECK ne 'ON' ) and ( $CHECK ne 'TRACE' ) ) {
                        croak(    'Received invalid value '
                                . $CHECK
                                . ' for Perl::Types preprocessor directive CHECK to control data type checking, valid values are OFF, ON, and TRACE, croaking' );
                    }
                    else {
                        $inside_subroutine = 1;
                    }

                    # enable single-line subroutine headers, continue parsing same input line if it contains more data
                    if ($2 ne q{}) {
                        $module_file_line = $2;
                        goto MODULE_FILE_LINE_LOOP_INNER;
                    }

                    next;
                }

                # skip class properties AKA package variables
                if ( $module_file_line =~ /^\s*our\s+[\w:]+\s+\$\w+\s+\=/xms ) {
                    $inside_object_properties = 0;
                }

                # skip non-Perl::Types-enabled subroutine/method, using normal Perl 'sub foo {}' syntax instead of Perl::Types syntax
                # DEPRECATED, CORRELATION #rp120: old subroutine header
#                if ( $module_file_line =~ /^\s*sub\s+[\w:]+\s+\{/xms ) {
#                    $inside_object_properties = 0;
#                }

                # skip end-of-module line
                if ( $module_file_line =~ /^\s*1\;\s+\#\ end\ of/xms ) {
                    $inside_object_properties = 0;
                }

                # object properties, continue to aggregate types
                if ($inside_object_properties) {
                    chomp $module_file_line;    # strip trailing newline
                    $object_properties_string .= $module_file_line;
                    next;
                }

                # subroutine/method, process arguments and activate type checking
                if ($inside_subroutine) {
                    if ( not $use_perltypes ) {
#                        Perl::diag(q{in Class::INIT() block, do NOT have $use_perltypes, skipping inside subroutine in $module_filename_short = } . $module_filename_short . "\n");
                        next;
                    }
#                    else { Perl::diag(q{in Class::INIT() block, have $use_perltypes, enabling inside subroutine in $module_filename_short = } . $module_filename_short . "\n"); }

#                    Perl::diag('in Class::INIT() block, have $inside_subroutine = 1', "\n");
#                    Perl::diag("in Class::INIT() block, have \$module_file_line =\n$module_file_line\n");
                    if ( $module_file_line =~ /^\s*\(\s*my/xms ) {
                        $inside_subroutine_arguments = 1;
                    }

#                    Perl::diag( q{in Class::INIT() block, have $inside_subroutine_arguments = }, $inside_subroutine_arguments, "\n" );
                    if ($inside_subroutine_arguments) {
                        $subroutine_arguments_line .= $module_file_line;
                        if ( $subroutine_arguments_line =~ /\@ARG\;/xms ) {    # @ARG; found
                            if ( not( $subroutine_arguments_line =~ /\@ARG\;\s*$/xms ) ) {    # @ARG; found not at end-of-line
#                                Perl::diag( q{in Class::INIT() block, found @ARG; NOT at end-of-line while inside subroutine } . $subroutine_name . '(), have $subroutine_arguments_line = ' . "\n" . $subroutine_arguments_line . "\n\n" . 'continuing Perl::Types activation of file' . "\n" );

                                # separate @ARG statement from remainder of line
                                my $after_arg_index = (index $subroutine_arguments_line, '@ARG;') + 5;
                                $module_file_line_remainder = substr $subroutine_arguments_line, $after_arg_index;
                                $subroutine_arguments_line  = substr $subroutine_arguments_line, 0, $after_arg_index;

#                                Perl::diag( 'in Class::INIT() block, set $subroutine_arguments_line =' . "\n>>>" . $subroutine_arguments_line . "<<<\n" );
#                                Perl::diag( 'in Class::INIT() block, set $module_file_line_remainder =' . "\n>>>" . $module_file_line_remainder . "<<<\n" );

                                # DEV NOTE: do not abort if @ARG; found not at end-of-line, separate line and continue
#                                Perl::diag( q{in Class::INIT() block, found @ARG; NOT at end-of-line while inside subroutine } . $subroutine_name . '(), have $subroutine_arguments_line = ' . "\n" . $subroutine_arguments_line . "\n\n" . 'aborting Perl::Types activation of entire file' . "\n" );
#                                last;
                            }

#                            Perl::diag( q{in Class::INIT() block, found @ARG; at end-of-line while inside subroutine } . $subroutine_name . '(), have $subroutine_arguments_line = ' . "\n" . $subroutine_arguments_line . "\n" );

                            my $subroutine_arguments = [];                                # arrayref::arrayref::string

                            # loop once per subroutine argument
#                            while ( $subroutine_arguments_line =~ m/my\s+(\w+)\s+\$(\w+)/g ) {  # WRONG: does not match scoped Class names
                            while ( $subroutine_arguments_line =~ m/my\s+([\w:]+)\s+\$(\w+)/g ) {
                                push @{$subroutine_arguments}, [ $1, $2 ];
#                                Perl::diag( q{in Class::INIT() block, have subroutine argument type = } . $1 . q{ and subroutine argument name = } . $2 . "\n" );
                            }

#                            Perl::diag( q{in Class::INIT() block, have $subroutine_arguments = } . "\n" . Dumper($subroutine_arguments) . "\n" );

                            my $subroutine_arguments_check_code = "\n";                   # string

                            if ( $CHECK eq 'ON' ) {
#                                Perl::diag( 'in Class::INIT() block, CHECK IS ON' . "\n" );
                                my $i = 0;                                                # integer
                                foreach my $subroutine_argument ( @{$subroutine_arguments} ) {
                                    # only enable type-checking for arguments of supported type;
                                    # NEED UPGRADE: enable checking of user-defined Class types & all other remaining Perl::Types types
                                    if (exists $TYPES_SUPPORTED->{$subroutine_argument->[0]}) {
#                                        $subroutine_arguments_check_code .= q{    } . $subroutine_argument->[0] . '_CHECK( $_[' . $i . '] );' . "\n";  # DOES NOT WORK, fails to find Perl::Exporter::integer_CHECKTRACE() etc.
#                                        $subroutine_arguments_check_code .= q{    ::} . $subroutine_argument->[0] . '_CHECK( $_[' . $i . '] );' . "\n";  # DOES NOT WORK, we no longer export all the type-checking subroutines to the main '::' namespace
                                        $subroutine_arguments_check_code .= q{    perltypes::} . $subroutine_argument->[0] . '_CHECK( $_[' . $i . '] );' . "\n";  # does work, hard-code all automatically-generated type-checking code to 'perltypes::' namespace
                                    }
                                    $i++;
                                }

#                                Perl::diag( 'in Class::INIT() block, CHECK IS ON, have $subroutine_arguments_check_code = ', "\n", $subroutine_arguments_check_code, "\n" );
#                                Perl::diag( 'in Class::INIT() block, CHECK IS ON, about to call activate_subroutine_args_checking()...' . "\n" );
                                activate_subroutine_args_checking( $package_name, $subroutine_name, $subroutine_type, $subroutine_arguments_check_code, $module_filename_long );
                                $inside_subroutine         = 0;
                                $subroutine_arguments_line = q{};
                            }
                            elsif ( $CHECK eq 'TRACE' ) {
#                                Perl::diag( 'in Class::INIT() block, CHECK IS TRACE' . "\n" );
#                                Perl::diag( 'in Class::INIT() block, CHECK IS TRACE, have $subroutine_name = ' . $subroutine_name . "\n" );

                                my $i = 0;    # integer
                                foreach my $subroutine_argument ( @{$subroutine_arguments} ) {
#                                    Perl::diag( 'in Class::INIT() block, CHECK IS TRACE, have $subroutine_argument->[0] = ' . $subroutine_argument->[0] . "\n" );
#                                    Perl::diag( 'in Class::INIT() block, CHECK IS TRACE, have $subroutine_argument->[1] = ' . $subroutine_argument->[1] . "\n" );

                                    # only enable type-checking for arguments of supported type;
                                    # NEED UPGRADE: enable checking of user-defined Class types & all other remaining Perl::Types types
                                    if (exists $TYPES_SUPPORTED->{$subroutine_argument->[0]}) {
#                                        $subroutine_arguments_check_code .= q{    } . $subroutine_argument->[0] . '_CHECKTRACE( $_[' . $i . q{], '$} . $subroutine_argument->[1] . q{', '} . $subroutine_name . q{()' );} . "\n";  # DOES NOT WORK
#                                        $subroutine_arguments_check_code .= q{    ::} . $subroutine_argument->[0] . '_CHECKTRACE( $_[' . $i . q{], '$} . $subroutine_argument->[1] . q{', '} . $subroutine_name . q{()' );} . "\n";  # DOES NOT WORK
                                        $subroutine_arguments_check_code .= q{    perltypes::} . $subroutine_argument->[0] . '_CHECKTRACE( $_[' . $i . q{], '$} . $subroutine_argument->[1] . q{', '} . $subroutine_name . q{()' );} . "\n";
                                    }
                                    $i++;
                                }
#                                Perl::diag( 'in Class::INIT() block, CHECK IS TRACE, about to call activate_subroutine_args_checking()...' . "\n" );
                                activate_subroutine_args_checking( $package_name, $subroutine_name, $subroutine_type, $subroutine_arguments_check_code, $module_filename_long );
                                $inside_subroutine         = 0;
                                $subroutine_arguments_line = q{};
                            }
                            else {
                                croak(    'Received invalid value '
                                        . $CHECK
                                        . ' for Perl::Types preprocessor directive CHECK to control data type checking, valid values are OFF, ON, and TRACE, croaking'
                                );
                            }
                            $inside_subroutine_arguments = 0;
#                            Perl::diag( 'in Class::INIT() block, have $subroutine_arguments_check_code =' . "\n" . $subroutine_arguments_check_code . "\n" );
                        }

                        # enable @ARG; not at end-of-line, continue parsing same input line if it contains more data
                        if ($module_file_line_remainder ne q{}) {
#                            Perl::diag( 'in Class::INIT() block, have non-empty $module_file_line_remainder =' . "\n>>>" . $module_file_line_remainder . "<<<\n" );
                            $module_file_line = $module_file_line_remainder;
                            $module_file_line_remainder = q{};
                            goto MODULE_FILE_LINE_LOOP_INNER;
                        }

                        next;    # next file line
                    }
                }
            }

            close $MODULE_FILE or croak $OS_ERROR;

            # activate final subroutine in file, no arguments
            if ($inside_subroutine) {
                if ($inside_subroutine_arguments) {
                    croak('Did not find @ARG to end subroutine arguments before end of file, croaking');
                }

                # DEV NOTE, CORRELATION #rp053: even with the upgrade to normal Perl subroutine headers, we must still activate subroutines w/out args or when type-checking is explicitly disabled with CHECK OFF, in order for Perl::Exporter to work properly, presumably because Exporter.pm runs before Class.pm and thus we can not test for the existence of __CHECKED_*() subroutines in Perl::Exporter::import()
#                Perl::diag( 'in Class::INIT() block, activating final subroutine in file, no subroutine arguments found' . "\n" );
                activate_subroutine_args_checking( $package_name, $subroutine_name, $subroutine_type, q{}, $module_filename_long );
                $inside_subroutine = 0;
            }

            # object properties, save final package's types
            $object_properties_types = save_object_properties_types( $package_name, $object_properties_string, $object_properties_types );

#            Perl::diag( 'in Class::INIT() block, have $object_properties_types = ' . "\n" . Dumper($object_properties_types) . "\n" ) if ( keys %{$object_properties_types} );

            # accessor/mutator object methods, deferred creation for all packages found in this file
            foreach $package_name ( sort keys %{$object_properties_types} ) {
#                Perl::diag("in Class::INIT() block, about to create accessors/mutators, have \$package_name = '$package_name'\n");
                $object_properties = eval "\$$package_name\:\:properties";

                foreach my $property_name ( sort keys %{$object_properties} ) {

#                    Perl::diag("in Class::INIT() block, about to create accessors/mutators, have \$property_name = '$property_name'\n");
                    # DEV NOTE, CORRELATION #rp003: avoid re-defining class accessor/mutator methods; so far only triggered by Perl::CodeBlock::Subroutine
                    # because it has a special BEGIN{} block with multiple package names including it's own package name

                    my $property_type = $object_properties_types->{$package_name}->{$property_name};
                    my $eval_string;
                    my $return_whole = 0;

#                    Perl::diag("in Class::INIT() block, about to create accessors/mutators, have \$property_type = '$property_type'\n");

                    # array element accessor/mutator
                    if (    ( $property_type =~ /^arrayref::/ )
                        and ( not eval( 'defined &' . $package_name . '::get_' . $property_name . '_element' ) ) )
                    {
                        # HARD-CODED EXAMPLE
                        # sub get_foo_size { { my integer $RETURN_TYPE }; ( my Foo::Bar $self ) = @ARG; return (scalar @{$self->{foo}}); }
                        # sub get_foo_element { { my Foo::Quux $RETURN_TYPE }; ( my Foo::Bar $self, my integer $i ) = @ARG; return $self->{foo}->[$i]; }
                        # sub set_foo_element { { my void $RETURN_TYPE }; ( my Foo::Bar $self, my integer $i, my Foo::Quux $foo_element ) = @ARG; $self->{foo}->[$i] = $foo_element; }

#                        Perl::diag('in Class::INIT() block, about to create accessors/mutators, have arrayref type' . "\n");
                        # DEV NOTE, CORRELATION #rp054: auto-generation of OO property accessors/mutators checks the auto-generated Perl::Types type list for base data types to determine if the entire data structure can be returned by setting ($return_whole = 1)
                        my $property_element_type = substr $property_type, 10;  # strip leading 'arrayref::'
                        if ( exists $perltypesnamespaces_generated::PERLTYPES->{ $property_element_type . '::' } ) {
#                            Perl::diag('in Class::INIT() block, about to create accessors/mutators, have Perl::Types arrayref type, setting $return_whole flag' . "\n");
                            $return_whole = 1;
                        }
                        # DEV NOTE: do not enable "else" below, because we always want to enable special array accessors/mutators for all array types, not just for user-defined types;
                        # use of these special accessors/mutators provide additional OO encapsulation for Perl::Types types, which is purely optional;
                        # since Perl::Types types set ($return_whole = 1) above, you can bypass getting/setting individual array elements and simply access the entire data structure directly
#                        else {
                            $eval_string
                                = '*{'
                                . $package_name
                                . '::get_'
                                . $property_name . '_size'
                                . '} = sub { ( my '
                                . $package_name
                                . ' $self ) = @ARG; return (scalar @{$self->{'
                                . $property_name
                                . '}}); };' . "\n";
                            $eval_string
                                .= '*{'
                                . $package_name
                                . '::get_'
                                . $property_name
                                . '_element'
                                . '} = sub { ( my '
                                . $package_name
                                . ' $self, my integer $i ) = @ARG; return $self->{'
                                . $property_name
                                . '}->[$i]; };' . "\n";
                            $eval_string
                                .= '*{'
                                . $package_name
                                . '::set_'
                                . $property_name
                                . '_element'
                                . '} = sub { ( my '
                                . $package_name
                                . ' $self, my integer $i, my '
                                . $property_element_type . ' $'
                                . $property_name
                                . '_element ) = @ARG; $self->{'
                                . $property_name
                                . '}->[$i] = $'
                                . $property_name
                                . '_element; };';

#                            Perl::diag( 'in Class::INIT() block, have user-defined object array element accessor $eval_string = ' . "\n" . $eval_string . "\n" );
                            eval($eval_string) or croak($EVAL_ERROR);
                            if ($EVAL_ERROR) { croak($EVAL_ERROR); }
#                        }
                    }

                    # hash value accessor/mutator
                    elsif ( ( $property_type =~ /^hashref::/ )
                        and ( not eval( 'defined &' . $package_name . '::get_' . $property_name . '_entry_value' ) ) )
                    {
                        # HARD-CODED EXAMPLE
                        # sub get_foo_keys { { my arrayref::string $RETURN_TYPE }; ( my Foo::Bar $self ) = @ARG; return [sort keys %{$self->{foo}}]; }
                        # sub get_foo_entry_value { { my Foo::Quux $RETURN_TYPE }; ( my Foo::Bar $self, my string $key ) = @ARG; return $self->{foo}->{$key}; }
                        # sub set_foo_entry_value { { my void $RETURN_TYPE }; ( my Foo::Bar $self, my string $key, my Foo::Quux $foo_entry_value ) = @ARG; $self->{foo}->{$key} = $foo_entry_value; }

#                        Perl::diag('in Class::INIT() block, about to create accessors/mutators, have hashref type' . "\n");
                        # DEV NOTE, CORRELATION #rp054: auto-generation of OO property accessors/mutators checks the auto-generated Perl::Types type list for base data types to determine if the entire data structure can be returned by setting ($return_whole = 1)
                        my $property_value_type = substr $property_type, 9;  # strip leading 'hashref::'
#                        Perl::diag('in Class::INIT() block, about to create accessors/mutators, have $property_value_type = ' . q{'} . $property_value_type . q{'} . "\n");
#                        Perl::diag('in Class::INIT() block, about to create accessors/mutators, have $perltypesnamespaces_generated::PERLTYPES = ' . Dumper($perltypesnamespaces_generated::PERLTYPES) . "\n");

                        if ( exists $perltypesnamespaces_generated::PERLTYPES->{ $property_value_type . '::' } ) {
#                            Perl::diag('in Class::INIT() block, about to create accessors/mutators, have Perl::Types hashref type, setting $return_whole flag' . "\n");
                            $return_whole = 1;
                        }
                        # DEV NOTE: do not enable "else" below, because we always want to enable special array accessors/mutators for all array types, not just for user-defined types;
                        # use of these special accessors/mutators provide additional OO encapsulation for Perl::Types types, which is purely optional;
                        # since Perl::Types types set ($return_whole = 1) above, you can bypass getting/setting individual array elements and simply access the entire data structure directly
#                        else {
                            $eval_string
                                = '*{'
                                . $package_name
                                . '::get_'
                                . $property_name . '_keys'
                                . '} = sub { ( my '
                                . $package_name
                                . ' $self ) = @ARG; return [sort keys %{$self->{'
                                . $property_name
                                . '}}]; };' . "\n";
                            $eval_string
                                .= '*{'
                                . $package_name
                                . '::get_'
                                . $property_name
                                . '_entry_value'
                                . '} = sub { ( my '
                                . $package_name
                                . ' $self, my string $key ) = @ARG; return $self->{'
                                . $property_name
                                . '}->{$key}; };' . "\n";
                            $eval_string
                                .= '*{'
                                . $package_name
                                . '::set_'
                                . $property_name
                                . '_entry_value'
                                . '} = sub { ( my '
                                . $package_name
                                . ' $self, my string $key, my '
                                . $property_value_type . ' $'
                                . $property_name
                                . '_entry_value ) = @ARG; $self->{'
                                . $property_name
                                . '}->{$key} = $'
                                . $property_name
                                . '_entry_value; };';

#                            Perl::diag( 'in Class::INIT() block, have user-defined object hash value accessor $eval_string = ' . "\n" . $eval_string . "\n" );
                            eval($eval_string) or croak($EVAL_ERROR);
                            if ($EVAL_ERROR) { croak($EVAL_ERROR); }
#                        }
                    }

                    # scalar accessor/mutator
                    else {
                        $return_whole = 1;
                    }

                    # return whole values for scalars, scalar arrayrefs, and scalar hashrefs
                    if ($return_whole) {
                        if ( not eval( 'defined &' . $package_name . '::get_' . $property_name ) ) {
                            $eval_string = '*{' . $package_name . '::get_' . $property_name . '} = sub { return $_[0]->{' . $property_name . '}; };';
#                            Perl::diag( 'in Class::INIT() block, have $return_whole accessor $eval_string = ' . "\n" . $eval_string . "\n" );
                            eval($eval_string) or croak($EVAL_ERROR);
                            if ($EVAL_ERROR) { croak($EVAL_ERROR); }
                        }

                        if ( not eval( 'defined &' . $package_name . '::set_' . $property_name ) ) {
                            $eval_string
                                = '*{'
                                . $package_name
                                . '::set_'
                                . $property_name
                                . '} = sub { $_[0]->{'
                                . $property_name
                                . '} = $_[1]; return $_[0]->{'
                                . $property_name . '}; };';
#                            Perl::diag( 'in Class::INIT() block, have $return_whole mutator $eval_string = ' . "\n" . $eval_string . "\n" );
                            eval($eval_string) or croak($EVAL_ERROR);
                            if ($EVAL_ERROR) { croak($EVAL_ERROR); }
                        }
                    }
                }
            }
        }
#        else { Perl::diag('in Class::INIT() block, found existing $perltypesnamespaces_generated::CORE->{' . $namespace_root . '}, aborting Perl::Types activation of entire file' . "\n"); }
    }
}


sub save_object_properties_types {
    ( my $package_name, my $object_properties_string, my $object_properties_types ) = @ARG;
    if ( $object_properties_string eq q{} ) {

        #        Perl::diag( 'in Class::save_object_properties_types(), have NO PROPERTIES $object_properties_string ' . "\n" );
    }
    elsif ( $object_properties_string =~ /^\s*our\s+hashref\s+\$properties\s*=\s*\{\s*\}\;/xms ) {

#        Perl::diag( 'in Class::save_object_properties_types(), have EMPTY PROPERTIES $object_properties_string = ' . "\n" . $object_properties_string . "\n" );
    }
    else {
        my $object_property_key             = undef;
        my $object_property_type            = undef;
        my $object_property_inner_type_name = undef;

        $object_properties_string =~ s/^\s*our\s+hashref\s+\$properties\s*=\s*\{(.*)\}\;\s*$/$1/xms;    # strip everything but hash entries

#        Perl::diag( 'in Class::save_object_properties_types(), have NON-EMPTY PROPERTIES $object_properties_string = ' . "\n" . $object_properties_string . "\n\n" );

        if ( $object_properties_string =~ /(\w+)\s*\=\>\s*my\s+([\w:]+)\s+\$TYPED_(\w+)/gxms ) {
            $object_property_key             = $1;
            $object_property_type            = $2;
            $object_property_inner_type_name = $3;
        }

#        Perl::diag( 'in Class::save_object_properties_types(), before while() loop, have $object_property_key = ' . $object_property_key . "\n" );
#        Perl::diag( 'in Class::save_object_properties_types(), before while() loop, have $object_property_type = ' . $object_property_type . "\n" );
#        Perl::diag( 'in Class::save_object_properties_types(), before while() loop, have $object_property_inner_type_name = ' . $object_property_inner_type_name . "\n" );

        while ( ( defined $object_property_key ) and ( defined $object_property_type ) and ( defined $object_property_inner_type_name ) ) {
            if ( $object_property_key ne $object_property_inner_type_name ) {
                die 'ERROR ECOGEPPRP20, CODE GENERATOR, INTERPRETED PERL TO COMPILED PERL, NAME-CHECKING MISMATCH: redundant inner type name ' . q{'}
                    . $object_property_inner_type_name . q{'}
                    . ' does not equal OO properties key ' . q{'}
                    . $object_property_key . q{'}
                    . ', dying' . "\n";
            }
            $object_properties_types->{$package_name}->{$object_property_key} = $object_property_type;

            if ( $object_properties_string =~ /(\w+)\s*\=\>\s*my\s+([\w:]+)\s+\$TYPED_(\w+)/gxms ) {
                $object_property_key             = $1;
                $object_property_type            = $2;
                $object_property_inner_type_name = $3;
            }
            else {
                $object_property_key             = undef;
                $object_property_type            = undef;
                $object_property_inner_type_name = undef;
            }

#            Perl::diag( 'in Class::save_object_properties_types(), bottom of while() loop, have $object_property_key = ' . $object_property_key . "\n" );
#            Perl::diag( 'in Class::save_object_properties_types(), bottom of while() loop, have $object_property_type = ' . $object_property_type . "\n" );
#            Perl::diag( 'in Class::save_object_properties_types(), bottom of while() loop, have $object_property_inner_type_name = ' . $object_property_inner_type_name . "\n" );
        }
    }
    return $object_properties_types;
}


# create Perl symbol table entries for Perl::Types subroutines and methods
sub activate_subroutine_args_checking {
    ( my $package_name, my $subroutine_name, my $subroutine_type, my $subroutine_arguments_check_code, my $module_filename_long ) = @ARG;

#    Perl::diag('in Class::activate_subroutine_args_checking(), received $package_name = ' . $package_name . "\n");
#    Perl::diag('in Class::activate_subroutine_args_checking(), received $subroutine_name = ' . $subroutine_name . "\n");
#    Perl::diag('in Class::activate_subroutine_args_checking(), received $subroutine_type = ' . $subroutine_type . "\n");
#    Perl::diag('in Class::activate_subroutine_args_checking(), received $subroutine_arguments_check_code = ' . $subroutine_arguments_check_code . "\n");
#    Perl::diag('in Class::activate_subroutine_args_checking(), received $module_filename_long = ' . $module_filename_long . "\n");

    my $package_name_tmp;              # string
    my $subroutine_definition_code = q{};    # string
    my $subroutine_definition_diag_code = q{};    # string
    my $check_code_subroutine_name = q{};  # string

# RPERL REFACTOR, NEED FIX: removed old '::method' types, need to check if first argument is '$self' with matching package name
# RPERL REFACTOR, NEED FIX: removed old '::method' types, need to check if first argument is '$self' with matching package name
# RPERL REFACTOR, NEED FIX: removed old '::method' types, need to check if first argument is '$self' with matching package name
#    if ( $subroutine_type =~ /\::method$/xms ) {
##        Perl::diag("in Class::activate_subroutine_args_checking(), $subroutine_name is a method\n");
#        if ( $package_name eq q{} ) {
#            croak( 'ERROR ECOPR01, PRE-PROCESSOR: Received no package name for method ', $subroutine_name, ' in file ' . $module_filename_long . ' ... croaking' );
#        }
#    }
#    else {
##        Perl::diag("in Class::activate_subroutine_args_checking(), $subroutine_name is not a method\n");
        # non-method subroutines which are not inside any package are actually in the 'main' package namespace
        if ( $package_name eq q{} ) { $package_name = 'main'; }
#    }

#    $subroutine_definition_diag_code = "\n    " . q{Perl::diag("IN POST-INIT, direct call MODE } . $package_name . '::' . $subroutine_name . q{\n"); };

=comment DEPRECATED
    # set symbol table entry for subroutine to new anonymous subroutine containing dereferenced call to real anonymous subroutine, old header style
    $subroutine_definition_code
        = '*{'
        . $package_name . '::'
        . $subroutine_name
        . '} = sub { '
        . $subroutine_definition_diag_code
        . $subroutine_arguments_check_code
        . 'return &${'
        . $package_name . '::'
        . $subroutine_name
        . '(@ARG); };';
=cut

    # re-define subroutine call to include type checking code; new header style
    do
    {
        no strict;

        # create unchecked symbol table entry for original subroutine
        *{ $package_name . '::__UNCHECKED_' . $subroutine_name } = \&{ $package_name . '::' . $subroutine_name };  # short form, symbol table direct, not strict

        # delete original symtab entry
        undef *{ $package_name . '::' . $subroutine_name };

        # re-create new symtab entry pointing to checking code plus unchecked symtab entry
        $subroutine_definition_code .=
            '*' . $package_name . '::' . $subroutine_name . ' = sub { ' .
            $subroutine_definition_diag_code .
            ($subroutine_arguments_check_code or "\n") .
            '    return ' . $package_name . '::__UNCHECKED_' . $subroutine_name . '(@ARG);' . "\n" . '};';

        # create new checked symtab entries, for use by Exporter
        $check_code_subroutine_name = $package_name . '::__CHECK_CODE_' . $subroutine_name;
        $subroutine_definition_code .= "\n" . '*' . $package_name . '::__CHECKED_' . $subroutine_name . ' = \&' . $package_name . '::' . $subroutine_name . "\n" . ';';
#        ${ $check_code_subroutine_name } = $subroutine_arguments_check_code;  # DOES NOT WORK
#        $subroutine_definition_code .= "\n" . '    $' . $check_code_subroutine_name . q{ =<<'EOF';} . "\n" . $subroutine_arguments_check_code . "\n" . 'EOF' . "\n";  # DOES NOT WORK
#        Perl::diag('in Class::activate_subroutine_args_checking(), have $' . $check_code_subroutine_name . '  = ' . "\n" . '[BEGIN_CHECK_CODE]' . "\n" . ${ $check_code_subroutine_name } . "\n" . ' [END_CHECK_CODE]' . "\n");
#        Perl::diag('in Class::activate_subroutine_args_checking(), have $' . $check_code_subroutine_name . '  = ' . "\n" . '[BEGIN_CHECK_CODE]' . "\n" . $check_code_subroutine_name . "\n" . ' [END_CHECK_CODE]' . "\n");

        $subroutine_definition_code .= "\n" . '*' . $check_code_subroutine_name . ' = sub {' . "\n" . '    my $retval ' . q{ =<<'EOF';} . "\n" . $subroutine_arguments_check_code . "\n" . 'EOF' . "\n" . '};' . "\n";
    };

#    if ($subroutine_arguments_check_code ne q{}) {
#        Perl::diag('in Class::activate_subroutine_args_checking(), have method $subroutine_definition_code =' . "\n" . $subroutine_definition_code . "\n");
#    }

#    eval($subroutine_definition_code) or (croak 'ERROR ECOPR02, PRE-PROCESSOR: Failed to enable type checking for subroutine ' . $package_name . '::' . $subroutine_name . '(),' . "\n" . $EVAL_ERROR . "\n" . 'croaking');  # TRIGGERS FALSE ALARMS ON OUTPUT FROM Perl::diag()
    eval($subroutine_definition_code) or (Perl::diag('ERROR ECOPR02, PRE-PROCESSOR: Possible failure to enable type checking for subroutine ' . $package_name . '::' . $subroutine_name . '(),' . "\n" . $EVAL_ERROR . "\n" . 'not croaking'));
    if ($EVAL_ERROR) { croak 'ERROR ECOPR03, PRE-PROCESSOR: Failed to enable type checking for subroutine ' . $package_name . '::' . $subroutine_name . '(),' . "\n" . $EVAL_ERROR . "\n" . 'croaking'; }

#    do { no strict;
#        Perl::diag('in Class::activate_subroutine_args_checking(), have ' . $check_code_subroutine_name . '() = ' . "\n" . '[BEGIN_CHECK_CODE]' . "\n" . &{ $check_code_subroutine_name } . "\n" . ' [END_CHECK_CODE]' . "\n");
#    };
}
