[![Build Status](https://travis-ci.org/kan/p5-smart-options.svg?branch=master)](https://travis-ci.org/kan/p5-smart-options) [![Coverage Status](https://img.shields.io/coveralls/kan/p5-smart-options/master.svg?style=flat)](https://coveralls.io/r/kan/p5-smart-options?branch=master)
# NAME

Smart::Options - smart command line options processor

# SYNOPSIS

    use Smart::Options;

    my $argv = Smart::Options->new->argv;

    if ($argv->{rif} - 5 * $argv->{xup} > 7.138) {
        say 'Buy more fiffiwobbles';
    }
    else {
       say 'Sell the xupptumblers';
    }

    # $ ./example.pl --rif=55 --xup=9.52
    # Buy more fiffiwobbles
    #
    # $ ./example.pl --rif 12 --xup 8.1
    # Sell the xupptumblers

# DESCRIPTION

Smart::Options is a library for option parsing for people tired option parsing.
This module is analyzed as people interpret an option intuitively.

# METHOD

## new()

Create a parser object.

    use Smart::Options;

    my $argv = Smart::Options->new->parse(qw(-x 10 -y 2));

## parse(@args)

parse @args. return hashref of option values.
if @args is empty Smart::Options use @ARGV

## argv(@args)

shortcut method. this method auto export.

    use Smart::Options;
    say argv(qw(-x 10))->{x};

is the same as

    use Smart::Options ();
    Smart::Options->new->parse(qw(-x 10))->{x};

## alias($alias, $option)

set alias for option. you can use "$option" field of argv.

    use Smart::Options;
    
    my $argv = Smart::Options->new->alias(f => 'file')->parse(qw(-f /etc/hosts));
    $argv->{file} # => '/etc/hosts'

## default($option, $default\_value)

set default value for option.

    use Smart::Options;
    
    my $argv = Smart::Options->new->default(y => 5)->parse(qw(-x 10));
    $argv->{x} + $argv->{y} # => 15

## describe($option, $msg)

set option help message.

    use Smart::Options;
    my $opt = Smart::Options->new()->alias(f => 'file')->describe('Load a file');
    say $opt->help;

    # Usage: ./example.pl
    #
    # Options:
    #    -f, --file  Load a file
    #

## boolean($option, $option2, ...)

interpret 'option' as a boolean.

    use Smart::Options;
    
    my $argv = Smart::Options->new->parse(qw(-x 11 -y 10));
    $argv->{x} # => 11
    
    my $argv2 = Smart::Options->new->boolean('x')->parse(qw(-x 11 -y 10));
    $argv2->{x} # => true (1)

## demand($option, $option2, ...)

show usage (showHelp()) and exit if $option wasn't specified in args.

    use Smart::Options;
    my $opt = Smart::Options->new()->alias(f => 'file')
                                   ->demand('file')
                                   ->describe('Load a file');
    $opt->argv(); # => exit

    # Usage: ./example.pl
    #
    # Options:
    #    -f, --file  Load a file [required]
    #

## options($key => $settings, ...)

    use Smart::Options;
    my $opt = Smart::Options->new()
      ->options( f => { alias => 'file', default => '/etc/passwd' } );

is the same as

    use Smart::Options;
    my $opt = Smart::Options->new()
                ->alias(f => 'file')
                ->default(f => '/etc/passwd');

## type($option => $type)

set type check for option value

    use Smart::Options;
    my $opt = Smart::Options->new()->type(foo => 'Int');

    $opt->parse('--foo=bar') # => fail
    $opt->parse('--foo=3.14') # => fail
    $opt->parse('--foo=1') # => ok

support type is here.

    Bool
    Str
    Int
    Num
    ArrayRef
    HashRef
    Config

### Config

'Config' is special type.
The contents will be read into each option if a file name is specified as a Config type option. 

    use Smart::Options;
    my $opt = Smart::Options->new()->type(conf => 'Config');
    $opt->parse(qw(--conf=.optrc));

config file format is simple. see http://en.wikipedia.org/wiki/INI\_file

    ; this is comment
    [section]
    key=value
    key2=value2

## coerce( $newtype => $sourcetype, $generator )

define new type and convert logic.

    use Smart::Options;
    use Path::Class; # export 'file'
    my $opt = Smart::Options->new()->coerce(File => 'Str', sub { file($_[0]) })
                                   ->type(file => 'File');
    
    $opt->parse('--foo=/etc/passwd');
    $argv->{file} # => Path::Class::File instance

## usage

set a usage message to show which command to use. default is "Usage: $0".

## help

return help message string

## showHelp($fh)

print usage message. default output STDERR.

## subcmd($cmd => $parser)

set a sub command. $parser is another Smart::Option object.

    use Smart::Options;
    my $opt = Smart::Options->new()
                ->subcmd(add => Smart::Options->new())
                ->subcmd(minus => Smart::Options->new());

# DSL

see also [Smart::Options::Declare](https://metacpan.org/pod/Smart::Options::Declare)

# PARSING TRICKS

## stop parsing

use '--' to stop parsing.

    use Smart::Options;
    use Data::Dumper;

    my $argv = argv(qw(-a 1 -b 2 -- -c 3 -d 4));
    warn Dumper($argv);

    # $VAR1 = {
    #        'a' => '1',
    #        'b' => '2',
    #        '_' => [
    #                 '-c',
    #                 '3',
    #                 '-d',
    #                 '4'
    #               ]
    #      };

## negate fields

'--no-key' set false to $key.

    use Smart::Options;
    argv(qw(-a --no-b))->{b}; # => 0

## duplicates

If set flag multiple times it will get arrayref.

    use Smart::Options;
    argv(qw(-x 1 -x 2 -x 3))->{x}; # => [1, 2, 3]

## dot notation

    use Smart::Optuions;
    argv(qw(--foo.x 1 --foo.y 2)); # => { foo => { x => 1, y => 2 } }

# AUTHOR

Kan Fushihara <kan.fushihara@gmail.com>

# SEE ALSO

https://www.npmjs.com/package/minimist

[GetOpt::Casual](https://metacpan.org/pod/GetOpt::Casual), [opts](https://metacpan.org/pod/opts), [GetOpt::Compat::WithCmd](https://metacpan.org/pod/GetOpt::Compat::WithCmd)

# LICENSE

Copyright (C) Kan Fushihara

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
