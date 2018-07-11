# This module comes from Inline::Module share file: 'CPPConfig.pm'

use strict; use warnings;
package Inline::CPP::Config;

use Config;
use ExtUtils::CppGuess;

our ($compiler, $libs, $iostream_fn, $cpp_flavor_defs) = guess();

sub guess {
    my ($compiler, $libs, $iostream_fn, $cpp_flavor_defs);
    $iostream_fn = 'iostream';
    $cpp_flavor_defs = <<'.';
#define __INLINE_CPP_STANDARD_HEADERS 1
#define __INLINE_CPP_NAMESPACE_STD 1
.

    if ($Config::Config{osname} eq 'freebsd'
        && $Config::Config{osvers} =~ /^(\d+)/
        && $1 >= 10
    ) {
        $compiler = 'clang++';
        $libs = '-lc++';
    }
    else {
        my $guesser = ExtUtils::CppGuess->new;
        my %configuration = $guesser->module_build_options;
        if( $guesser->is_gcc ) {
            $compiler = 'g++';
        }
        elsif ( $guesser->is_msvc ) {
            $compiler = 'cl';
        }

        $compiler .= $configuration{extra_compiler_flags};
        $libs = $configuration{extra_linker_flags};

        ($compiler, $libs) = map {
            _trim_whitespace($_)
        } ($compiler, $libs);
    }
    return ($compiler, $libs, $iostream_fn, $cpp_flavor_defs);
}

sub throw {
    my $os = $^O;
    my $msg = "Unsupported OS/Compiler for Inline::Module+Inline::CPP '$os'";
    die $msg unless
        $ENV{PERL5_MINISMOKEBOX} ||
        $ENV{PERL_CR_SMOKER_CURRENT};
    eval 'use lib "inc"; use Inline::Module; 1' or die $@;
    Inline::Module->smoke_system_info_dump($msg);
}

sub _trim_whitespace {
    my $string = shift;
    $string =~ s/^\s+|\s+$//g;
    $string =~ s/\s+/ /g;
    return $string;
}

1;
