[![Actions Status](https://github.com/kan/p5-smart-options/actions/workflows/test.yml/badge.svg?branch=master)](https://github.com/kan/p5-smart-options/actions?workflow=test)
# NAME

Smart::Options - smart command line options processor

# SYNOPSIS

```perl
use 5.010;
use Smart::Options;

my $argv = Smart::Options->new->parse;    # parses @ARGV

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
```

# DESCRIPTION

Smart::Options is a library for option parsing for people tired option parsing.
This module is analyzed as people interpret an option intuitively.

# METHOD

## new(%args)

Create a parser object.

```perl
use Smart::Options;

my $argv = Smart::Options->new->parse(qw(-x 10 -y 2));
```

By default the parser has a `-h, --help` option, which prints the help and dies.
Pass `add_help => 0` to leave it out.

```perl
my $opt = Smart::Options->new(add_help => 0);
```

## parse(@args)

parse @args. return hashref of option values.
if @args is empty Smart::Options use @ARGV.
The arguments that are not options are in `$argv->{_}` (an arrayref).

## argv(@args)

shortcut function, exported by default. Call it as a function, not as a method.

```perl
use Smart::Options;
say argv(qw(-x 10))->{x};
```

is the same as

```perl
use Smart::Options ();
Smart::Options->new->parse(qw(-x 10))->{x};
```

## alias($alias, $option)

set alias for option. you can use "$option" field of argv.

```perl
use Smart::Options;

my $argv = Smart::Options->new->alias(f => 'file')->parse(qw(-f /etc/hosts));
$argv->{file} # => '/etc/hosts'
```

## default($option, $default\_value)

set default value for option.

```perl
use Smart::Options;

my $argv = Smart::Options->new->default(y => 5)->parse(qw(-x 10));
$argv->{x} + $argv->{y} # => 15
```

## describe($option, $msg)

set option help message.

```perl
use Smart::Options;
my $opt = Smart::Options->new()->alias(f => 'file')->describe(f => 'Load a file');
print $opt->help;

# Usage: ./example.pl
#
# Options:
#   -f, --file  Load a file
#   -h, --help  Show help
#
```

## boolean($option, $option2, ...)

interpret 'option' as a boolean.

```perl
use Smart::Options;

my $argv = Smart::Options->new->parse(qw(-x 11 -y 10));
$argv->{x} # => 11

my $argv2 = Smart::Options->new->boolean('x')->parse(qw(-x 11 -y 10));
$argv2->{x} # => true (1)
```

## demand($option, $option2, ...)

show usage (`showHelp()`) and die if $option wasn't specified in args.

```perl
use Smart::Options;
my $opt = Smart::Options->new()->alias(f => 'file')
                               ->demand('file')
                               ->describe(file => 'Load a file');
$opt->parse(); # => die

# Usage: ./example.pl
#
# Options:
#   -f, --file  Load a file    [required]
#   -h, --help  Show help
#
#
# Missing required arguments: file
```

## options($key => $settings, ...)

```perl
use Smart::Options;
my $opt = Smart::Options->new()
  ->options( f => { alias => 'file', default => '/etc/passwd' } );
```

is the same as

```perl
use Smart::Options;
my $opt = Smart::Options->new()
            ->alias(f => 'file')
            ->default(f => '/etc/passwd');
```

## type($option => $type)

set type check for option value

```perl
use Smart::Options;
my $opt = Smart::Options->new()->type(foo => 'Int');

$opt->parse('--foo=bar') # => fail
$opt->parse('--foo=3.14') # => fail
$opt->parse('--foo=1') # => ok
```

support type is here.

```
Bool
Str
Int
Num
ArrayRef
HashRef
Config
```

### Config

'Config' is special type.
The contents will be read into each option if a file name is specified as a Config type option. 

```perl
use Smart::Options;
my $opt = Smart::Options->new()->type(conf => 'Config');
$opt->parse(qw(--conf=.optrc));
```

config file format is simple. see [https://en.wikipedia.org/wiki/INI\_file](https://en.wikipedia.org/wiki/INI_file).
Sections are ignored, so every key is read as a top-level option.

```
; this is comment
[section]
key=value
key2=value2
```

## coerce( $newtype => $sourcetype, $generator )

define new type and convert logic.

```perl
use Smart::Options;
use Path::Class; # export 'file'
my $opt = Smart::Options->new()->coerce(File => 'Str', sub { file($_[0]) })
                               ->type(file => 'File');

my $argv = $opt->parse('--file=/etc/passwd');
$argv->{file} # => Path::Class::File instance
```

## env($option, $option2, ...)

read the value of $option from an environment variable, when it is not given in args.
The name of the variable is `uc("${prefix}_$option")`, where $prefix is set by
["env\_prefix($prefix)"](#env_prefix-prefix).

```perl
use Smart::Options;
# $ MYAPP_PORT=8080 ./example.pl
my $argv = Smart::Options->new->env_prefix('myapp')->env('port')->parse;
$argv->{port} # => 8080
```

## env\_prefix($prefix)

set the prefix of the environment variables read by ["env($option, $option2, ...)"](#env-option-option2).

## usage($message)

set a usage message to show which command to use. default is "Usage: $0".

## help

return help message string

## showHelp($fh)

print usage message. default output STDERR.

## subcmd($cmd => $parser)

set a sub command. $parser is another Smart::Options object.
The name of the sub command is in `$argv->{command}`, and the options after it,
parsed by $parser, are in `$argv->{cmd_option}`.

```perl
use Smart::Options;
my $opt = Smart::Options->new()
            ->subcmd(add => Smart::Options->new())
            ->subcmd(minus => Smart::Options->new());

my $argv = $opt->parse(qw(add -x 1));
$argv->{command}         # => 'add'
$argv->{cmd_option}{x}   # => 1
```

# DSL

see also [Smart::Options::Declare](https://metacpan.org/pod/Smart%3A%3AOptions%3A%3ADeclare)

# PARSING TRICKS

## stop parsing

use '--' to stop parsing.

```perl
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
```

## negate fields

'--no-key' set false to $key.

```perl
use Smart::Options;
argv(qw(-a --no-b))->{b}; # => 0
```

## duplicates

If set flag multiple times it will get arrayref.

```perl
use Smart::Options;
argv(qw(-x 1 -x 2 -x 3))->{x}; # => [1, 2, 3]
```

## dot notation

```perl
use Smart::Options;
argv(qw(--foo.x 1 --foo.y 2)); # => { foo => { x => 1, y => 2 } }
```

# AUTHOR

Kan Fushihara <kan.fushihara@gmail.com>

# SEE ALSO

[https://www.npmjs.com/package/minimist](https://www.npmjs.com/package/minimist)

[Getopt::Casual](https://metacpan.org/pod/Getopt%3A%3ACasual), [opts](https://metacpan.org/pod/opts), [Getopt::Compact::WithCmd](https://metacpan.org/pod/Getopt%3A%3ACompact%3A%3AWithCmd)

# LICENSE

Copyright (C) Kan Fushihara

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
