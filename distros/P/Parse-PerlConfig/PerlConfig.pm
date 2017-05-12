# Parse::PerlConfig - parse a configuration file written in Perl

# Copyright (C) 1999 Michael Fowler, all rights reserved

# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.


package Parse::PerlConfig;

require Exporter;
use Fcntl qw(O_RDONLY);
use strict;
use vars (
    qw($VERSION @ISA @EXPORT_OK),
    qw($saved_dollar_slash),        # used in _do_file()
);


@ISA = qw(Exporter);

@EXPORT_OK = qw(parse);

$VERSION = '0.05';


my %thing_str2key = (
    '$'     =>      'SCALAR',
    '@'     =>      'ARRAY',
    '%'     =>      'HASH',
    '&'     =>      'CODE',
    '*'     =>      'GLOB',
    'i'     =>      'IO',
);


my %thing_key2str;

@thing_key2str{values %thing_str2key} = keys(%thing_str2key);



sub parse {
    local *FILE;
    my $subname = (caller(0))[3];

    my %args = (
        Namespace_Base          =>      __PACKAGE__ . '::ConfigFile',

        Thing_Order             =>       '$@%&i*',
        Taint_Clean             =>              0,

        Warn_default            =>         'noop',
        Warn_preparse           =>      'default',
        Warn_eval               =>      'default',

        Error_default           =>         'warn',
        Error_argument          =>      'default',
        Error_file_is_dir       =>      'default',
        Error_failed_open       =>      'default',
        Error_eval              =>      'default',
        Error_unknown_thing     =>      'default',
        Error_unknown_handler   =>      'default',
        Error_invalid_lexical   =>      'default',
        Error_invalid_namespace =>      'default',
    );


    if (ref($_[0]) eq 'HASH') {             # first argument is a hash..
        %args = (%args, %{+ shift }, @_);   # ..dereference it

    } elsif (ref($_[0]) eq 'ARRAY') {       # first argument is an array..
        %args = (%args, @{+ shift }, @_);   # ..dereference it

    } elsif (@_) {
        %args = (%args, @_);
    }


    my $def_errsub  = _errsub($args{'Error_default'});
    my $def_warnsub = _errsub($args{ 'Warn_default'});

    my(%errsubs, %warnsubs);
    foreach my $handler (qw(
        argument
        file_is_dir
        failed_open
        eval
        unknown_thing
        unknown_handler
        invalid_namespace
    )) {
        $errsubs{$handler} = _errsub($args{"Error_$handler"}, $def_errsub);
    }


    foreach my $handler (qw(preparse eval)) {
        $warnsubs{$handler} = _errsub($args{"Warn_$handler"}, $def_warnsub);
    }


    # This allows us to pass around %args, rather than each hash necessary.
    $args{'_errsubs'}  = \%errsubs;
    $args{'_warnsubs'} = \%warnsubs;



    my @files;
    push(@files, $args{File}) if defined($args{File});

    if (ref($args{Files}) eq 'ARRAY') {
        push(@files, @{ $args{Files} });

    } elsif (defined $args{Files}) {
        push(@files, $args{Files});
    }

    unless (@files) {
        $errsubs{'argument'}->(
            "Files or File argument required in call to $subname."
        );
        return;
    }


    my @handlers;
    push(@handlers, $args{Handler}) if defined($args{Handler});

    if (ref($args{Handlers}) eq 'ARRAY') {
        push(@handlers, @{ $args{Handlers} });

    } elsif (defined $args{Handlers}) {
        push(@handlers, $args{Handlers});
    }


    my %lexicals;
    if (ref $args{Lexicals} eq 'HASH') {
        %lexicals = %{ $args{Lexicals} };

    } elsif (defined $args{Lexicals}) {
        $errsubs{'argument'}->(
            "Lexicals argument must be a hashref in call to $subname."
        );
    }


    my @def_thing_order = _thingstr_to_array(\%args, $args{'Thing_Order'});

    my %custom_symbols;
    if (ref($args{Symbols}) eq 'HASH') {
        while (my($sym, $order) = each(%{$args{Symbols}})) {
            $custom_symbols{$sym} = [ _thingstr_to_array(\%args, $order) ];
        }
    }


    my $lexicals_string = _construct_lexicals_string(\%args, \%lexicals);



    # Having checked all of our arguments, we run through our files.
    my %parsed_symbols;
    FILE: foreach my $file (@files) {

        $errsubs{'file_is_dir'}->("Config file \"$file\" is a directory.")
            if -d $file;

        $warnsubs{'preparse'}->("Preparing to parse config file \"$file\".");




        unless (sysopen FILE, $file, O_RDONLY) {
            $errsubs{'failed_open'}->(
                "Unable to open config file \"$file\": \l$!."
            );
            return;
        }


        if ($args{'Taint_Clean'}) {
            require IO::Handle;
            FILE->untaint;
        }


        my $namespace = _construct_namespace(\%args, $file);

        unless (_valid_namespace($namespace)) {
            $errsubs{'invalid_namespace'}->(
                "Namespace \"$namespace\" is invalid."
            );
            return;
        }
            

        {
            my %parse_perl_config = (
                Parse_Args      =>      \%args,
                Filename        =>      $file,
                Namespace       =>      $namespace,
                Error           =>      undef,
            );

            my $eval_warn = $warnsubs{'eval'};

            local $SIG{__WARN__} = sub { $eval_warn->(join "", @_) };
            _do_file(\*FILE, $namespace, \%parse_perl_config, $lexicals_string);


            my $error;
            if (defined($error = $parse_perl_config{Error})) {
                $errsubs{'eval'}->(
                    "Configuration file raised an error: $error."
                );
                next FILE;

            } elsif ($@) {
                $error = $@;
                1 while chomp($error);

                $errsubs{'eval'}->("Error in configuration eval: $error.");
                next FILE;
            }
        }


        _parse_symbols(
            Namespace       =>  $namespace,
            Thing_Order     =>  \@def_thing_order,
            Symbols         =>  \%custom_symbols,
            Hash            =>  \%parsed_symbols,
        );
    }


    _dispatch_handlers(\%args, \@handlers, \%parsed_symbols);


    return \%parsed_symbols;
}




# _parse_symbols <hash argument>
#       Namespace       - namespace to parse symbols from
#       Symbols         - hashref of symbols with specific thing ordering
#       Thing_Order     - default thing order, arrayref
#       Hash            - a hashref into which parsed symbols are placed
#
# This an internal function used by parse() to do the actual parsing of
# symbols from a namespace.  This function has the potential to be a public
# one, if sanity checking on arguments is added.

sub _parse_symbols {
    my %args = @_;

    my $namespace           =   $args{'Namespace'};
    my %custom_symbols      =   %{ $args{'Symbols'} };
    my @def_thing_order     =   @{ $args{'Thing_Order'} };
    my $parsed_symbols      =   $args{'Hash'};


    no strict 'refs';
    while (my($symbol, $glob) = each(%{"$namespace\::"})) {
        my @thing_order;

        if (exists $custom_symbols{$symbol}) {
            @thing_order = @{ $custom_symbols{$symbol} };
        } else {
            @thing_order = @def_thing_order;
        }


        my $value;
        foreach my $thing (@thing_order) {
            if ($thing eq 'SCALAR') {
                # Special case for scalars; we always get a scalar
                # reference, even if the underlying scalar is undefined.
                if (defined ${ *$glob{SCALAR} }) {
                    $value = ${ *$glob{SCALAR} };
                    last;
                }

            } elsif (defined *$glob{$thing}) {
                $value = *$glob{$thing};
                last;
            }
        }


        $$parsed_symbols{$symbol} = $value if defined($value);


        # In order to prevent various warnings, and the symbols from still
        # being there (even though the symbol table isn't), we undef each
        # glob as we go.
        undef(*{"$namespace\::$symbol"});
    }


    return;
}




sub _dispatch_handlers {
    my($args, $handlers, $parsed_symbols) = (shift, shift, shift);

    foreach my $handler (@$handlers) {
        if (ref $handler eq 'CODE') {
            $handler->($parsed_symbols);

        } elsif (ref $handler eq 'HASH') {
            @$handler{keys %$parsed_symbols} = values %$parsed_symbols

        } else {
            $$args{'_errsubs'}{'unknown_handler'}->(
                'Unknown handler type "' . ref($handler) . '"'
            );
        }
    }
}




# _do_file <filehandle> <namespace> <parse_perl_config hashref>
#          <lexicals string>
#
#   Reads the given filename using sysopen and eval, in the specified
#   namespace.  The hash %parse_perl_config is set with the specified
#   hashref.
#
#   The reason this subroutine exists is to keep the lexical space as clean
#   as possible, while still allowing some lexicals through.  Were this
#   functionality inlined with the rest of parse(), a configuration file
#   would have access to parse()'s lexicals.  To keep things even cleaner
#   local() is used rather than my().  Obviously the latter is preferable,
#   but in this case, would cause problems

sub _do_file {
    # Arguments are accessed through @_ indexing, rather than shifting, to
    # keep the lexical space as clean as possible.

    local *FILE              =     $_[0]  ;
    my    %parse_perl_config = %{+ $_[2] };


    # We go to some lengths to be able to slurp the file, while
    # still keeping $/ intact.

    local $saved_dollar_slash = $/;
    local $/;

    no strict;
    eval    '$/ = $saved_dollar_slash;'     .
            "package $_[1];"                .
            $_[3]                           . # lexical definitions
            <FILE>
    ;
}




sub _construct_lexicals_string {
    my($args, $lexicals) = (shift, shift);

    return '' unless %$lexicals;

    require Data::Dumper;

    my $inv_lex_errsub = $$args{'_errsubs'}{'invalid_lexical'};

    my $lexicals_string = '';
    LEXICAL: while (my($key, $value) = each(%$lexicals)) {

        if ($key !~ /^([^_\W][\w\d]*|\w[\w\d]+)$/) {
            $inv_lex_errsub->(
                "Lexical name \"$key\" is invalid, must be a valid " .
                "identifier."
            );

            next LEXICAL;

        } elsif (ref($value) eq 'CODE') {
            $inv_lex_errsub->(
                "Lexical \"$key\" value is invalid, code references " .
                "are not allowed."
            );

            next LEXICAL;

        } elsif ($key eq 'parse_perl_config' && ref($value) eq 'HASH') {
            $inv_lex_errsub->(
                "Cannot have a hash lexical named \"parse_perl_config\"."
            );

            next LEXICAL;
        }

        $lexicals_string .= 'my ' . Data::Dumper->Dump([$value], ["*$key"]);
    }


    $lexicals_string;
}





sub _construct_namespace {
    my($args, $file) = (shift, shift);

    my $namespace;
    if (defined $$args{'Namespace'}) {
        $namespace = $$args{'Namespace'};

    } else {
        $namespace = "$$args{'Namespace_Base'}::" . _encode_namespace($file);
    }


    if ($$args{'Taint_Clean'}) {
        # We've already filtered the namespace, but perl doesn't know
        # that; fake it.
        ($namespace) = ($namespace =~ /(.*)/);
    }


    return $namespace;
}



sub _valid_namespace {
    my $namespace = shift;

    foreach my $ns_ele (split /::/, $namespace) {
        return 0 unless $ns_ele =~ /^[_A-Za-z][_A-Za-z0-9]*/;
    }

    return 1;
}



sub _encode_namespace {
    my $namespace = shift;

    my @namespace;
    foreach my $ns_ele (split /::/, $namespace) {
        # ^A-Za-z0-9 (as opposed to [\W\D]) is spelled out explicitly
        # because package names are not (yet?) locale-friendly.
        $ns_ele =~
            s{
                (
                    (?:^[^A-Za-z])      # first character must not be a number
                        |
                    [^A-Za-z0-9]        # any further characters can be
                )
            }{
                sprintf("_%2x", ord $1)
            }egx
        ;


        push(@namespace, $ns_ele);
    }


    return join("::", @namespace);
}





# _thingstr_to_array <args hashref> <string>
#
#   Translates a thing string ($%@*i&) into the associated glob keys:
#       $       SCALAR
#       @       ARRAY
#       %       HASH
#       *       GLOB
#       i       IO
#       &       CODE
#
#
#   Returns the keys as a list, in the same order.  The specified coderef is
#   an error function used to report when an unknown character is
#   encountered.
#
#   If the string is actually an array reference, the array is dereferenced,
#   checked for invalid keys, and returned.

sub _thingstr_to_array {
    my($args, $string) = (shift, shift);

    my $errsub = $$args{'_errsubs'}{'unknown_thing'};

    if (ref($string) eq 'ARRAY') {
        my @filtered;

        foreach my $thing (@$string) {
            $thing = uc($thing);
            if (!exists $thing_key2str{$thing}) {
                $errsub->("Unknown thing key \"$thing\".");
                next;
            }

            push(@filtered, $thing);
        }

        return @filtered;
    }


    my @keys;
    foreach my $c (split //, $string) {
        unless (defined $thing_str2key{$c}) {
            $errsub->("Undefined thing string \"$c\".");
            next;
        }

        push(@keys, $thing_str2key{$c});
    }

    return @keys;
}




sub _fwarn {  CORE::warn(shift() . "\n")          }
sub _warn  {  CORE::warn(shift() . "\n") if $^W   }
sub _die   {  CORE::die (shift() . "\n")          }
sub _noop  {                                      }

# _errsub <error spec> [<default coderef>]
#       Responsible for parsing the "default", "noop", "warn", "fwarn", and
#       "die" strings, and returning an appropriate code reference.

sub _errsub {
    my($spec, $default) = (shift, shift);
    $spec = lc($spec) unless ref($spec);

    (ref $spec eq 'CODE' )          &&      return $spec;
    (    $spec eq 'warn' )          &&      return \&_warn;
    (    $spec eq 'fwarn')          &&      return \&_fwarn;
    (    $spec eq 'die'  )          &&      return \&_die;
    (    $spec eq 'noop' )          &&      return \&_noop;

    # catch anything that falls through
    return (ref $default eq 'CODE') ? $default : \&_warn;
}




1;


__END__


=head1 NAME

Parse::PerlConfig - parse a configuration file written in Perl


=head1 SYNOPSIS

    use Parse::PerlConfig;
    my $parsed = Parse::PerlConfig::parse(
        File            =>      "/etc/perlapp/conf",
        Handlers        =>      [\%config, \&config],
    );



=head1 DESCRIPTION

This module is useful for parsing a configuration file written in Perl and
obtaining the values defined therein.  This is achieved through the parse()
function, which creates a namespace, reads in Perl code, evals it, and then
examines the namespace's symbol table.  Symbols are then processed into a
hash and returned.


=head2 Export

The parse() function is exportable upon request.


=head2 Parsing

Parsing is not a simple do("filename").  Instead the filenames specified are
opened, read, eval'd, and closed.  The justification for this being twofold:

=over 4

=item no @INC search

I did not want surprises in what file was found; do("file") searches @INC.

=item lexicals

I wanted to be able to insert lexicals for the code in the file to see.
Being able to define variables without having them parsed back out
(remember, the namespace is searched) is a nice feature.

=back


Parsing (in this manner) requires a namespace.  By default, the namespace is
constructed by appending Namespace_Base to a unique identifier (currently,
an encoded version of the filename, but don't rely on this).  You can
override this behaviour by specifying an explicit Namespace argument.

Prior to eval'ing the contents of a configuration file the lexical hash
%parse_perl_config is initialized with several keys (documented below); if a
Lexicals argument was given each of the lexicals specified are initialized.

There are a few caveats; lexicals specified in the Lexicals argument cannot
override %parse_perl_config; keys specified in Lexicals cannot be code
references, because code references cannot currently be reliably
reconstructed; modifications to %parse_perl_config keys (other than Error,
documented below) are discouraged, as the results are not defined.


The %parse_perl_config hash contains the following keys:

=over 4

=item Error

Making this key a true value will cause the error handler Error_eval to be
called with the value.


=item Namespace

The namespace the file is being evaluated in.


=item Filename

The name of the file being parsed.


=item Parse_Args

A hash of the arguments passed to parse().

=back


Once the namespace has been setup, and the code eval'd, it is then parse()'s
job to go through the namespace's symbol table and look for "things".  What
it looks for depends on the Thing_Order and Symbols arguments.

After that, handlers are updated, and a hash reference of what was parsed
out is returned.




=head1 The parse subroutine


=head2 Arguments

parse() takes a list of key-value pairs as its arguments and adds them to an
argument hash.  If the first argument to parse() is a hash or array
reference, it is dereferenced and used as if it were specified as a list.
All elements following this argument are added to the arguments hash, and
they override any settings specified by the reference.

This means the call:

    parse(
        { Files => "/home/me/config.conf", Error_default => 'fwarn' },
        Files => "/home/you/config.conf"
    );

causes parse()'s argument hash to consist of the following (ignoring default
settings):

    Files           =>  "/home/you/config.conf",
    Error_default   =>  "fwarn",

Simply replace the braces, {}, with brackets, [], and you get the same
result.  This makes it convenient to store commonly-used arguments to
parse() in a hash or array, and efficiently pass these arguments to parse(),
while still allowing a seperate Files argument for each call.


The below itemization of parse()'s arguments describes key-value pairs.
Each item consists of a key name and a description of the expected value for
that key.

The value description requires some explanation.

A single pipe, "|", indicates alternative values; only one of the values
must be specified.

Values bracketed with "<" and ">" indicate that value is not literal, but
figurative.  So, in the case of <coderef>, you must specify a code reference
(a closure or reference to a named subroutine), not the literal string
"<coderef>".  Values without such bracketing are literal.

Braces, {}, indicate a hash reference is required; brackets, [], indicate an
array reference is required.

Below each key-value description is a description of the default setting,
followed by a description of what the argument means.


=over 4

=item Files <filename> | [<filename> ...]

    default: none, this argument is required

This is the file or files you wish to parse.  If a file cannot be parsed for
any reason the entire parse is not abandoned, the file is simply skipped
(after calling an appropriate error handling function).


=item File <filename>

Equivalent to Files <filename>.


=item Handlers <hashref>|<coderef> | [<hashref>|<coderef> ...]

    default: none

By default, parse() simply returns a hash reference of symbol names and
their values.  Given a Handlers argument, parse() will add key-value pairs
to each hash reference specified, and call each code reference specified
with a single argument, the hash reference it returns.


=item Handler <hashref>|<coderef>

Equivalent to Handlers <hashref>|<coderef>.


=item Lexicals <hashref>

    default: none

The key-value pairs in the specified hashref are made into lexical variables
in the configuration eval.  See the section on Parsing for further
information.


=item Thing_Order <string>|<arrayref>

    default: '$@%&i*'

Specifies the default thing order for symbols parsed from each configuration
file.  See the section Things for further information.


=item Taint_Clean <boolean>

    default: false

If set to any true value the filehandle opened on the configuration file is
untainted before evaling the code contained therein.  Because this involves
loading IO::Handle, which involves quite a bit of code, the option is turned
off by default.  You I<will> get taint exceptions if you don't specify this
option while running in C<-T> mode.

Also, as the namespace is currently constructed, having a tainted filename
will cause the namespace name to be tainted, so it is also untainted.  In
the case of an explicitly specified Namespace value, it will also be
untainted.

No other values are untainted.  This includes any key-value pairs specified
by the Lexicals argument; you must untaint those yourself, since there is no
reasonable way for parse() to determine how best to untaint them.


=item Symbols <hashref>

    default: empty hashref

This is an override for the Thing_Order argument above.  The keys in the
specified hashref are symbols you want parsed specially, the values the
thing order (either a string or array reference).  See the section Things
for further information regarding thing order.


=item Namespace <string>

    default: generated from Namespace_Base and a unique identifier

This option explicitly specifies the namespace the files are parsed in.  See
the section Parsing for further information.


=item Namespace_Base <string>

    default: Parse::PerlConfig::ConfigFile

Unless the Namespace argument is specified, the namespace a file is parsed
in is generated by appending a cleaned up version of the filename to this
setting.  See the section Parsing for further information.


=item Error_*

See the section Error Handling for further information.


=back



=head2 Things

"Things" (as taken from the Perl documentation, regarding the *foo{THING}
syntax) are the Perl datatypes.  These include scalars, arrays, hashes,
subroutines, IO handles, and globs.

Anywhere a "things" argument is required you can specify one of two things;
a string containing the special "thing" characters, or an array reference of
each thing's actual name.  The thing characters are as follows: C<$> for
scalar, C<%> for a hash, C<@> for an array, C<&> for a subroutine, C<i> for
an IO handle, and C<*> for a glob.  The full name for each coincides with
the full name for each datatype in their respective glob slots: SCALAR for a
scalar, HASH for a hash, ARRAY for an array, CODE for a subroutine, IO for
an IO handle, and GLOB for a glob.



=head2 Exception Handling

parse() takes various Error_* and Warn_* arguments that determine how it
handles any problems it encounters.  Each argument can take one of several
values.


=over 4

=item default

The error handling specifed by Error_default in the case of an Error_*
argument, or Warn_default in the case of a Warn_* argument, is used.


=item noop

The error is ignored.


=item warn

Results in a call to CORE::warn() with a trailing newline, but only if
C<$^W> is set to a true value.


=item fwarn

Like I<warn>, but the warning is raised regardless of C<$^W>'s value.


=item die

Results in a call to CORE::die() with a trailing newline.


=item <code reference>

The code reference will be called with a single argument, that of the error
message.  The error message is guaranteed to contain no trailing newlines
(in case the code reference decides to die() or warn()).

=back



There are various handler arguments.  Unless otherwise specified, the
default handler is used (Error_default's or Warn_default's value).

=over 4

=item Warn_default

    default: noop

The default warning handler.


=item Warn_preparse

Called just before a file is parsed to indicate parsing is about to begin.


=item Warn_eval

Called with any warnings issued by the eval'd file.


=item Error_default

    default: warn

The default error handler.


=item Error_argument

Called if there is a problem with one of the arguments specified.


=item Error_file_is_dir

Called if a configuration file specified was discovered to be a directory.


=item Error_failed_open

Called if the open attempt on a configuration file fails.


=item Error_eval

Called if the variable $parse_perl_config{Error} is set in the configuration
file, or if there was an eval error.


=item Error_unknown_thing

Called if there is a problem with a thing character or thing name in a thing
argument (thing thing thing).


=item Error_unknown_handler

Called if an unknown reference is encountered in the Handlers argument.


=item Error_invalid_lexical

Called if an invalid lexical name or a CODE reference value is encountered in
the Lexicals argument.


=item Error_invalid_namespace

Called if either the constructed namespace (using Namespace_Base) or a
specified Namespace value is invalid.  This may indicate an error in the
construction of a namespace name (the generation of a unique identifier),
but it's most likely you specified Namespace_Base or Namespace with invalid
characters.


=back



=head1 BUGS

Due to the fact that the scalar slot in a glob is always filled it is not
possible to distinguish from a scalar that was never defined (e.g. C<@foo>
was, but C<$foo> was never mentioned) from one that is simply undef. 
Because of this, for example, if you have a thing order of C<$@> and code
along the lines of C<$foo = undef; @foo = ();> the 'foo' key of the hash
will be an array reference, despite there being a scalar and C<$> coming
first in the thing order.


=head1 TODO

t/parse/symbols.t, t/parse/multi-file.t, t/parse/namespace.t


=head1 AUTHOR

Michael Fowler <michael@shoebox.net>


=cut
