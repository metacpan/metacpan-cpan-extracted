# NAME

MooX::Options - Explicit Options eXtension for Object Class

# SYNOPSIS

In myOptions.pm :

    package myOptions;
    use Moo;
    use MooX::Options;

    option 'show_this_file' => (
        is => 'ro',
        format => 's',
        required => 1,
        doc => 'the file to display'
    );
    1;

In myTool.pl :

    use myOptions;
    use Path::Class;

    my $opt = myOptions->new_with_options;

    print "Content of the file : ",
         file($opt->show_this_file)->slurp;

To use it :

    perl myTool.pl --show_this_file=myFile.txt
    Content of the file: myFile content

The help message :

    perl myTool.pl --help
    USAGE: myTool.pl [-h] [long options...]

        --show_this_file: String
            the file to display

        -h --help:
            show this help message

        --man:
            show the manual

The usage message :

    perl myTool.pl --usage
    USAGE: myTool.pl [ --show_this_file=String ] [ --usage ] [ --help ] [ --man ]

The manual :

    perl myTool.pl --man

# DESCRIPTION

Create a command line tool with your [Mo](https://metacpan.org/pod/Mo), [Moo](https://metacpan.org/pod/Moo), [Moose](https://metacpan.org/pod/Moose) objects.

Everything is explicit. You have an `option` keyword to replace the usual `has` to explicitly use your attribute into the command line.

The `option` keyword takes additional parameters and uses [Getopt::Long::Descriptive](https://metacpan.org/pod/Getopt::Long::Descriptive)
to generate a command line tool.

# IMPORTANT CHANGES IN 4.100

## Enhancing existing attributes

One can now convert an existing attribute into an option for obvious reasons.

    package CommonRole;

    use Moo::Role;

    has attr => (is => "ro", ...);

    sub common_logic { ... }

    1;

    package Suitable::Cmd::CLI;

    use Moo;
    use MooX::Cmd;
    use MooX::Options;

    with "CommonRole";

    option '+attr' => (format => 's', repeatable => 1);

    sub execute { shift->common_logic }

    1;

    package Suitable::Web::Request::Handler;

    use Moo;

    with "CommonRole";

    sub all_suits { shift->common_logic }

    1;

    package Suitable::Web;

    use Dancer2;
    use Suitable::Web::Request::Handler;

    set serializer => "JSON";

    get '/suits' => sub {
        $my $reqh = Suitable::Web::Request::Handler->new( attr => config->{suit_attr} );
        $reqh->all_suits;
    };

    dance;

    1;

Of course there more ways to to it, [Jedi](https://metacpan.org/pod/Jedi) or [Catalyst](https://metacpan.org/pod/Catalyst) shall be fine, either.

## Rename negativable into negatable

Since users stated that `negativable` is not a reasonable word, the flag is
renamed into negatable. Those who will 2020 continue use negativable might
or might not be warned about soon depreciation.

## Replace Locale::TextDomain by MooX::Locale::Passthrough

[Locale::TextDomain](https://metacpan.org/pod/Locale::TextDomain) is broken (technically and functionally) and causes a
lot of people to avoid `MooX::Options` or hack around. Both is unintened.

So introduce [MooX::Locale::Passthrough](https://metacpan.org/pod/MooX::Locale::Passthrough) to allow any vendor to add reasonable
localization, eg. by composing [MooX::Locale::TextDomain::OO](https://metacpan.org/pod/MooX::Locale::TextDomain::OO) into it's
solution and initialize the localization in a reasonable way.

## Make lazy loaded features optional

Since some features aren't used on a regular basis, their dependencies have
been downgraded to `recommended` or `suggested`. The optional features are:

- autosplit

    This feature allowes one to split option arguments at a defined character and
    always return an array (implicit flag `repeatable`).

        option "search_path" => ( is => "ro", required => 1, autosplit => ":", format => "s" );

    However, this feature requires following modules are provided:

    - [Data::Record](https://metacpan.org/pod/Data::Record)
    - [Regexp::Common](https://metacpan.org/pod/Regexp::Common)

- json format

    This feature allowes one to invoke a script like

        $ my-tool --json-attr '{ "gem": "sapphire", "color": "blue" }'

    It might be a reasonable enhancement to _handles_.

    Handling JSON formatted arguments requires any of those modules
    are loded:

    - [JSON::MaybeXS](https://metacpan.org/pod/JSON::MaybeXS)
    - [JSON::PP](https://metacpan.org/pod/JSON::PP) (in Core since 5.14).

## Decouple autorange and autosplit

Until 4.023, any option which had autorange enabled got autosplit enabled, too.
Since autosplit might not work correctly and for a reasonable amount of users
the fact of

    $ my-tool --range 1..5

is all they desire, autosplit will enabled only when the dependencies of
autosplit are fulfilled.

# IMPORTED METHODS

The list of the methods automatically imported into your class.

## new\_with\_options

It will parse your command line params and your inline params, validate and call the `new` method.

    myTool --str=ko

    t->new_with_options()->str # ko
    t->new_with_options(str => 'ok')->str #ok

## option

The `option` keyword replaces the `has` method and adds support for special options for the command line only.

See ["OPTION PARAMETERS"](#option-parameters) for the documentation.

## options\_usage | --help

It displays the usage message and returns the exit code.

    my $t = t->new_with_options();
    my $exit_code = 1;
    my $pre_message = "str is not valid";
    $t->options_usage($exit_code, $pre_message);

This method is also automatically fired if the command option "--help" is passed.

    myTool --help

## options\_man | --man

It displays the manual.

    my $t = t->new_with_options();
    $t->options_man();

This is automatically fired if the command option "--man" is passed.

    myTool --man

## options\_short\_usage | --usage

It displays a short version of the help message.

    my $t = t->new_with_options();
    $t->options_short_usage($exit_code);

This is automatically fired if the command option "--usage" is passed.

    myTool --usage

# IMPORT PARAMETERS

The list of parameters supported by [MooX::Options](https://metacpan.org/pod/MooX::Options).

## flavour

Passes extra arguments for [Getopt::Long::Descriptive](https://metacpan.org/pod/Getopt::Long::Descriptive). It is useful if you
want to configure [Getopt::Long](https://metacpan.org/pod/Getopt::Long).

    use MooX::Options flavour => [qw( pass_through )];

Any flavour is passed to [Getopt::Long](https://metacpan.org/pod/Getopt::Long) as a configuration, check the doc to see what is possible.

## protect\_argv

By default, `@ARGV` is protected. If you want to do something else on it, use this option and it will change the real `@ARGV`.

    use MooX::Options protect_argv => 0;

## skip\_options

If you have Role with options and you want to deactivate some of them, you can use this parameter.
In that case, the `option` keyword will just work like an `has`.

    use MooX::Options skip_options => [qw/multi/];

## prefer\_commandline

By default, arguments passed to `new_with_options` have a higher priority than the command line options.

This parameter will give the command line an higher priority.

    use MooX::Options prefer_commandline => 1;

## with\_config\_from\_file

This parameter will load [MooX::Options](https://metacpan.org/pod/MooX::Options) in your module. 
The config option will be used between the command line and parameters.

myTool :

    use MooX::Options with_config_from_file => 1;

In /etc/myTool.json

    {"test" : 1}

## with\_locale\_textdomain\_oo

This Parameter will load [MooX::Locale::TextDomain::OO](https://metacpan.org/pod/MooX::Locale::TextDomain::OO) into your module as
well as into [MooX::Options::Descriptive::Usage](https://metacpan.org/pod/MooX::Options::Descriptive::Usage).

No further action is taken, no language is chosen - everything keep in
control.

Please read [Locale::TextDomain::OO](https://metacpan.org/pod/Locale::TextDomain::OO) carefully how to enable the desired
translation setup accordingly.

# usage\_string

This parameter is passed to Getopt::Long::Descriptive::describe\_options() as
the first parameter.  

It is a "sprintf"-like string that is used in generating the first line of the
usage message. It's a one-line summary of how the command is to be invoked. 
The default value is "USAGE: %c %o".

%c will be replaced with what Getopt::Long::Descriptive thinks is the
program name (it's computed from $0, see "prog\_name").

%o will be replaced with a list of the short options, as well as the text
"\[long options...\]" if any have been defined.

The rest of the usage description can be used to summarize what arguments
are expected to follow the program's options, and is entirely free-form.

Literal "%" characters will need to be written as "%%", just like with
"sprintf".

## spacer

This indicate the char to use for spacer. Please only use 1 char otherwize the text will be too long.

The default char is " ".

    use MooX::Options space => '+'

Then the "spacer\_before" and "spacer\_after" will use it for "man" and "help" message.

    option 'x' => (is => 'ro', spacer_before => 1, spacer_after => 1);

# OPTION PARAMETERS

The keyword `option` extend the keyword `has` with specific parameters for the command line.

## doc | documentation

Documentation for the command line option.

## long\_doc

Documentation for the man page. By default the `doc` parameter will be used.

See also [Man parameters](https://metacpan.org/pod/MooX::Options::Manual::Man) to get more examples how to build a nice man page.

## required

This attribute indicates that the parameter is mandatory.
This attribute is not really used by [MooX::Options](https://metacpan.org/pod/MooX::Options) but ensures that consistent error message will be displayed.

## format

Format of the params, same as [Getopt::Long::Descriptive](https://metacpan.org/pod/Getopt::Long::Descriptive).

- i : integer
- i@: array of integer
- s : string
- s@: array of string
- f : float value

By default, it's a boolean value.

Take a look of available formats with [Getopt::Long::Descriptive](https://metacpan.org/pod/Getopt::Long::Descriptive).

You need to understand that everything is explicit here. 
If you use [Moose](https://metacpan.org/pod/Moose) and your attribute has `isa => 'Array[Int]'`, that will **not** imply the format `i@`.

## format json : special format support

The parameter will be treated like a json string.

    option 'hash' => (is => 'ro', json => 1);

You can also use the json format

    option 'hash' => (is => 'ro', format => "json");

    myTool --hash='{"a":1,"b":2}' # hash = { a => 1, b => 2 }

## negatable

It adds the negative version for the option.

    option 'verbose' => (is => 'ro', negatable => 1);

    myTool --verbose    # verbose = 1
    myTool --no-verbose # verbose = 0

The former name of this flag, negativable, is discouraged - since it's not a word.

## repeatable

It appends to the ["format"](#format) the array attribute `@`.

I advise to add a default value to your attribute to always have an array.
Otherwise the default value will be an undefined value.

    option foo => (is => 'rw', format => 's@', default => sub { [] });

    myTool --foo="abc" --foo="def" # foo = ["abc", "def"]

## autosplit

For repeatable option, you can add the autosplit feature with your specific parameters.

    option test => (is => 'ro', format => 'i@', default => sub {[]}, autosplit => ',');
    
    myTool --test=1 --test=2 # test = (1, 2)
    myTool --test=1,2,3      # test = (1, 2, 3)
    

It will also handle quoted params with the autosplit.

    option testStr => (is => 'ro', format => 's@', default => sub {[]}, autosplit => ',');

    myTool --testStr='a,b,"c,d",e,f' # testStr ("a", "b", "c,d", "e", "f")

## autorange

For another repeatable option you can add the autorange feature with your specific parameters. This 
allows you to pass number ranges instead of passing each individual number.

    option test => (is => 'ro', format => 'i@', default => sub {[]}, autorange => 1);
    
    myTool --test=1 --test=2 # test = (1, 2)
    myTool --test=1,2,3      # test = (1, 2, 3)
    myTool --test=1,2,3..6   # test = (1, 2, 3, 4, 5, 6)
    

It will also handle quoted params like `autosplit`, and will not rangify them.

    option testStr => (is => 'ro', format => 's@', default => sub {[]}, autorange => 1);

    myTool --testStr='1,2,"3,a,4",5' # testStr (1, 2, "3,a,4", 5)

`autosplit` will be set to ',' if undefined. You may set `autosplit` to a different delimiter than ','
for your group separation, but the range operator '..' cannot be changed. 

    option testStr => (is => 'ro', format => 's@', default => sub {[]}, autorange => 1, autosplit => '-');

    myTool --testStr='1-2-3-5..7' # testStr (1, 2, 3, 5, 6, 7) 

## short

Long option can also have short version or aliased.

    option 'verbose' => (is => 'ro', short => 'v');

    myTool --verbose # verbose = 1
    myTool -v        # verbose = 1

    option 'account_id' => (is => 'ro', format => 'i', short => 'a|id');

    myTool --account_id=1
    myTool -a=1
    myTool --id=1

You can also use a shorter option without attribute :

    option 'account_id' => (is => 'ro', format => 'i');

    myTool --acc=1
    myTool --account=1

## order

Specifies the order of the attribute. If you want to push some attributes at the end of the list.
By default all options have an order set to `0`, and options are sorted by their names.

    option 'at_the_end' => (is => 'ro', order => 999);

## hidden

Hide option from doc but still an option you can use on command line.

    option 'debug' => (is => 'ro', doc => 'hidden');

Or

    option 'debug' => (is => 'ro', hidden => 1);

## spacer\_before, spacer\_after

Add spacer before or after or both the params

    option 'myoption' => (is => 'ro', spacer_before => 1, spacer_after => 1);

# ADDITIONAL MANUALS

- [Man parameters](https://metacpan.org/pod/MooX::Options::Manual::Man)
- [Using namespace::clean](https://metacpan.org/pod/MooX::Options::Manual::NamespaceClean)
- [Manage your tools with MooX::Cmd](https://metacpan.org/pod/MooX::Options::Manual::MooXCmd)

# EXTERNAL EXAMPLES

- [Slide3D about MooX::Options](http://perltalks.celogeek.com/slides/2012/08/moox-options-slide3d.html)

# Translation

Translation is now supported.

Use the dzil command to update the pot and merge into the po files.

- dzil msg-init

    Create a new language po

- dzil msg-scan

    Scan and generate or update the pot file

- dzil msg-merge

    Update all languages using the pot file

## THANKS

- sschober

    For implementation and German translation.

# THANKS

- Matt S. Trout (mst) &lt;mst@shadowcat.co.uk>

    For his patience and advice.

- Tomas Doran (t0m) &lt;bobtfish@bobtfish.net>

    To help me release the new version, and using it :)

- Torsten Raudssus (Getty)

    to use it a lot in [DuckDuckGo](http://duckduckgo.com) (go to see [MooX](https://metacpan.org/pod/MooX) module also)

- Jens Rehsack (REHSACK)

    Use with [PkgSrc](http://www.pkgsrc.org/), and many really good idea ([MooX::Cmd](https://metacpan.org/pod/MooX::Cmd), [MooX::Options](https://metacpan.org/pod/MooX::Options), and more to come I'm sure)

- All contributors

    For improving and add more feature to MooX::Options

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooX::Options

You can also look for information at:

- RT: CPAN's request tracker (report bugs here)

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooX-Options](http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooX-Options)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/MooX-Options](http://annocpan.org/dist/MooX-Options)

- CPAN Ratings

    [http://cpanratings.perl.org/d/MooX-Options](http://cpanratings.perl.org/d/MooX-Options)

- Search CPAN

    [http://search.cpan.org/dist/MooX-Options/](http://search.cpan.org/dist/MooX-Options/)

# AUTHOR

celogeek &lt;me@celogeek.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by celogeek &lt;me@celogeek.com>.

This software is copyright (c) 2017 by Jens Rehsack.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
