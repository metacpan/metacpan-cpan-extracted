package Object::Result;

use 5.014; use warnings; use autodie;

our $VERSION = '0.000003';

use Method::Signatures;
use Keyword::Simple;
use Hash::Util::FieldHash 'fieldhash';
use PPI;

# Storage for all inside-out result objects...
fieldhash my %impl_of;

# Create the new keyword in the caller scope...
method import {
    Keyword::Simple::define 'result', func ($src_ref) {
        ${$src_ref} = _inject_result($src_ref);
    };
}

# Remove the keyword upon request...
method unimport {
    Keyword::Simple::undefine 'result';
}


# Parse source cleanly and convert new syntax to old...
func _inject_result ($src_ref) {
    state $WS = qr{ (?: \s++ | \# [^\n]*+ \n )*+ }x;

    # Check for missing argument (i.e. immediate semicolon or end-of-block)...
    my ($block) = ${$src_ref} =~ m{\A $WS ([;\}]) }xms;

    # Otherwise parse trailing source and extract top-level structure...
    my ($doc, $post_block_line_number);
    if (!$block) {
        # Convert empty block to <FAIL> block...
        ${$src_ref} =~ s{\A $WS \{ $WS \}  }{ {<FAIL>} }xms;

        # Extract structure...
        $doc = PPI::Document->new($src_ref);
        $doc->index_locations;

        # First significant element should be a block...
        $block = $doc->schild(0)->schild(0)->remove;

        # Determine line number after block replacement...
        $post_block_line_number = (caller 1)[2] + $block->location->[0] + $block =~ tr/\n// - 1;
    }

    # If block, convert to a ctor call)...
    if (ref($block) && $block->isa("PPI::Structure::Block")) {
        return _transform_result->($block)
             . "\n#line $post_block_line_number\n" . $doc;
    }

    # Or a syntax error...
    else {
        _die_on_invalid_syntax($block);
    }
}

func _die_on_invalid_syntax ($block) {
    state $reclassify = {
        Word          => 'identifier',
        DashedWord    => 'identifier',
        Magic         => 'variable',
        ArrayIndex    => 'array index',
        Cast          => 'operator',
        Single        => 'character string',
        Double        => 'character string',
        Interpolate   => 'character string',
        Words         => 'list constructor',
        Transliterate => 'transliteration',
        Match         => 'regex match',
        Substitute    => 'regex substitution',
        Data          => 'end of source code',
        End           => 'end of source code',
        Unknown       => 'a syntax error',
    };
    # Classify what we actually got...
    my $unexpected_construct = ref($block) || 'end of statement';

    # Make classification more readable...
    $unexpected_construct =~ s{.*::}{};
    $unexpected_construct  = $reclassify->{$unexpected_construct} // $unexpected_construct;
    $unexpected_construct =~ s{Constructor}{$block =~ /^\{/ ? 'hashref' : 'arrayref' }e;
    $block =~ s{\n.*}{...}xms;

    # Report the error...
    _croak(
        "Invalid syntax for 'result' statement.\n",
        "Expected block but found \L$unexpected_construct\E ('$block') instead"
    );
}

# Default behaviour on any use of a <FAIL> object...
method _default_fail ($requested_coercion, ...) {
    my $object_impl = $impl_of{$self};

    # Work out what to report...
    my $call_desc
        = sprintf( "call to %s() at %s line %s", @{$object_impl->{'<CONTEXT>'}}[3,1,2] );

    # Report it...
    _croak( "Object returned by $call_desc\ncan't be used as $requested_coercion" );
}

# Default behaviour for <BOOL> coercion...
method _default_bool (...) {
    return 1;
}

# This converts the 'result' block back to standard Perl 5...
func _transform_result ($block) {
    # Initialize the ctor args with explicit empty list to allow leading commas thereafter...
    my $transformed_block = q{()};

    # Extract and iterate components insode block...
    my @tokens = $block->schild(0)->schildren;
    TOKEN:
    while (my $token = shift @tokens) {

        # Consolidate <TYPE> coercions that were parsed as 3 tokens...
        if ($token eq '<' && @tokens >= 2 && $tokens[1] eq '>') {
            $token = join(q{}, "$token", splice(@tokens, 0, 2));
        }

        # Classify token and trailing context...
        my $next_token_type = substr($tokens[0]//q{}, 0, 1);
        my $token_type = $token =~ / < [^)]* > /x        ? 'coercion'
                       : $token->isa('PPI::Token::Word') ? 'named'
                       :                                   'other';

        # Handle <FAIL>...
        if ($token eq '<FAIL>') {
            my $MSG = $next_token_type eq '{' ? 'eval'.shift(@tokens) : q{};
            my $CROAK_FAILURE
                = qq{ Object::Result::_croak_failure(\$self,errmsg=>\$errmsg,msg=>[$MSG]) };

            $transformed_block
                .=  q[ , do{ my $errmsg = $@ // $! // @?; my $tested;                      ]
                 .  q[       '<BOOL>'     => method (...) { $tested++; 0 },                ]
                 . qq[       '<AUTOLOAD>' => method (...) { \$tested++; $CROAK_FAILURE },  ]
                 . qq[       '<DEFAULT>'  => method (...) { \$tested++; $CROAK_FAILURE },  ]
                 . qq[       '<DESTROY>'  => method (...) { $CROAK_FAILURE if !\$tested }, ]
                 .  q[     }                                                               ]
                 ;
            next TOKEN;
        }

        # Handle syntax errors...
        elsif ($token_type ne 'other' && !@tokens) {
             _croak("Missing definition for $token() method");
        }
        elsif ($token_type ne 'other' && $next_token_type !~ /[(\{]/) {
            _croak(
                "Invalid definition for $token() method\n",
                "Expected parameter list or method block, but found '$next_token_type'"
            );
        }

        # Handle all <TYPE> coercions (with relaxed default parameter checking)...
        if ($token_type eq 'coercion') {
            $transformed_block .= " , '$token' => method ";
            $transformed_block .= '(...)' if $next_token_type ne '(';
        }

        # Handle bareword method names...
        elsif ($token_type eq 'named') {
            $transformed_block .= " , $token => method ";
        }

        # Pass anything else through unchanged...
        else {
            $transformed_block .= $token;
        }
    }

    # The transformed code needs Method::Signatures to function, so prepend it...
    return "{ use Method::Signatures; return Object::Result::_build_result { $transformed_block } }";
}

# This builds type coercion subroutines...
func _handler_for (@op_names) {
    # Convert each operator name to <OPNAME>...
    @op_names = map {"<$_>"} @op_names;

    # Each type coercion is a method...
    return method (...) {
        @_ = $self;

        # Find implementation of coercion or else default to normal behaviour...
        use List::Util 'first';
        my $object_impl = $impl_of{$self};
        my $op_name     = first {exists $object_impl->{$_}} @op_names;

        # Fall back on <DEFAULT> handler...
        if (!defined $op_name) {
            $op_name = '<DEFAULT>';
            my $call_desc = sprintf( "call to %s() at %s line %s", @{$object_impl->{'<CONTEXT>'}}[3,1,2] );
            push @_, $op_names[0], $call_desc;
        }

        # Grab the handler (if any)...
        my $method_impl = $object_impl->{$op_name};

        # Fake out any error messages...
        no strict 'refs';
        *{$object_impl->{'<CONTEXT>'}[0].'::__ANON__'} = $op_name;

        # Execute the implementation of the coercion...
        goto &{$method_impl};
    };
}

# Ctor for Object::Result::Object objects...
func _build_result ($hash_ref) {
    # The result object has to know where it was produced and how to fail...
    $hash_ref->{ '<CONTEXT>' }   = [ caller 1 ];
    $hash_ref->{ '<DEFAULT>' } //= \&_default_fail;
    $hash_ref->{ '<BOOL>'    } //= \&_default_bool;

    # It's an inside-out object...
    my $newobj = bless \do{my $scalar}, 'Object::Result::Object';

    # So it's internal data is cached inside the module...
    $impl_of{$newobj} = $hash_ref;

    # And it just returns an empty blessed scalar...
    return $newobj;
}

# Be invisible to carp and croak and lazy about importing them...
$Carp::Internal{ (__PACKAGE__) }++;

func _croak (@msg) {
    require Carp;
    Carp::croak( @msg );
}

# Generate exceptions for <FAIL>...
method _croak_failure (:$errmsg, :$msg) {
    state $TRAILING_AT_LINE
        = qr{ \s++ at \s++ .+? \s++ line \s++ \d++ [\s\S]*+ \Z }xms;

    # Skip immediate caller unconditionally
    require Carp;
    local $Carp::CarpLevel = 1;

    # Define message...
    @$msg = grep { defined } @$msg;

    # Handle non-strings...
    if ( @$msg == 1 && ref($msg->[0]) ) {
        Carp::croak @$msg;
    }

    # Clean up message and locator...
    my $carp_where = Carp::shortmess( '' );
       $carp_where =~ s{\A .* \s at \s }{}xms;

    my $carp_what = @$msg ? join( q{}, @$msg ) : $errmsg;
       $carp_what =~ s{ $TRAILING_AT_LINE }{}xms;
       $carp_what =~ s{ \s+ }{ }xms;
       if (length($carp_what) > 78) {
            $carp_what =~ s{ (?<last>  .{1,73}         ) \Z
                           | (?<line>  .{1,72}         ) \s+
                           | (?<line>  .{1,72} [^\w\s] )
                           }
                           { ':    ' . (exists $+{line} ? "$+{line}\n" : $+{last}) }gexms;
            $carp_what = ":\n$carp_what\n:";
       }
       elsif (length($carp_what) > 0) {
            $carp_what = "    $carp_what";
       }

    # Handle non-messages...
    die sprintf(
       "Call to %s() at %s line %s failed%s\nFailure detected at %s\n",
            @{$impl_of{$self}{'<CONTEXT>'}}[3,1,2],
            ($carp_what ? " because:\n$carp_what" : q{}),
            $carp_where,
    );
}

# The class of all result objects...
package Object::Result::Object {
    use Method::Signatures;

    # Be invisible to carp and croak...
    $Carp::Internal{ (__PACKAGE__) }++;

    # Overload all possible coercions to call the corresponding type converter...
    use overload (
        q{""}    => Object::Result::_handler_for(qw[ STR                             ]),
        q{bool}  => Object::Result::_handler_for(qw[ BOOL                            ]),
        q{int}   => Object::Result::_handler_for(qw[ INT                             ]),
        q{0+}    => Object::Result::_handler_for(qw[ NUM                             ]),
        q{qr}    => Object::Result::_handler_for(qw[ REGEXP REGEXPREF REGEX REGEXREF ]),
        q{${}}   => Object::Result::_handler_for(qw[ SCALAR SCALARREF                ]),
        q{@{}}   => Object::Result::_handler_for(qw[ ARRAY  ARRAYREF                 ]),
        q{%{}}   => Object::Result::_handler_for(qw[ HASH   HASHREF                  ]),
        q{&{}}   => Object::Result::_handler_for(qw[ CODE   CODEREF   SUB   SUBREF   ]),
        q{*{}}   => Object::Result::_handler_for(qw[ GLOB   GLOBREF                  ]),

        # With the usual magic autogeneration...
        fallback => 1,
    );

    # All methods must be autoloaded, since each result object may have different methods...
    func AUTOLOAD ($self, ...) {
        # Work out the method name...
        our $AUTOLOAD;
        my $method_name = $AUTOLOAD =~ s/.*:://r;

        # Find the corresponding implementation for the object...
        my $object_impl = $impl_of{$self};
        my $method_impl = $object_impl->{$method_name} // $object_impl->{'<AUTOLOAD>'};
        if (!defined $method_impl) {
            my $call_desc = sprintf( "call to %s() at %s line %s", @{$object_impl->{'<CONTEXT>'}}[3,1,2] );
            Object::Result::_croak(
                "Object returned by $call_desc\ndoesn't have method $method_name()"
            );
        }

        # Fake out any internal error messages...
        no strict 'refs';
        *{$object_impl->{'<CONTEXT>'}[0].'::__ANON__'} = $method_name;

        # Execute the method implementation...
        goto &{$method_impl};
    }

    # Because we have an AUTOLOAD(), we need this separate...
    func DESTROY ($self) {
        my $object_impl = $impl_of{$self};

        # Execute destructor, faking out error messages...
        if (exists $object_impl->{'<DESTROY>'}) {
        no strict 'refs';
            *{$object_impl->{'<CONTEXT>'}[0].'::__ANON__'} = '<DESTROY>';
            goto &{$object_impl->{'<DESTROY>'}};
        }
    }
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Object::Result - Allow subs to build and return objects on-the-fly


=head1 VERSION

This document describes Object::Result version 0.000003


=head1 SYNOPSIS

    use Object::Result;

    sub get_time {
        # Return an object indicating failure...
        if (!load Time::HiRes => 'time') {
            result { <FAIL> }
        }

        # Set up some lexical state information...
        my $time = time();

        # Return an object with methods that use that information...
        result {
            # Named methods for returned object...
            timestamp  { return scalar localtime($time) }

            delay (Num $offset)  { $time += $offset }

            # Coercions for returned object...
            <STR>  { $self->timestamp; }  # String --> timestamp method
            <NUM>  { time() - $time;   }  # Number --> age of object
            <BOOL> { $self < 60;       }  # True for the first minute
        }
    };


    # And later...

    # Get back an object...
    my $now = get_time();

    # Use it (as a string, as an object, as a number)...
    say "It's $now";
    say $now->timestamp;
    say 'Recent' if $now < 0.1;

    # Change the object's internal state...
    $now->delay(50);

    # Use the object as a (dynamically valued) boolean...
    while ($now) {
        sleep 5;
        say "Are we there yet?";
    }



=head1 DESCRIPTION

This module adds a new keyword to Perl: C<result>

That keyword acts like a C<return>, but instead of a list of values to
return, it takes a single block which specifies the behaviour
(i.e. the methods and operator overloading) of an object to be returned.

The intention is to make it much less onerous to return clean,
properly encapsulated objects...instead of returning lists of values
or references to arrays or hashes.

For example, instead of:

    my ($ID, $name, $uptime, $load, $users, $location, $contact)
        = get_server_status($server_ID);

    if ($uptime) {
        say "$ID ($name) load: $load";
    }

or:

    my $server = get_server_status($server_ID);

    if ($server->{uptime}) {
        say "$server->{ID} ($server->{name) load: $server->{load}";
    }

you can arrange the API to be object-based:

    my $server = get_server_status($server_ID);

    if ($server->is_up) {
        say $server->describe, ' load: ', $server->load;
    }

The real advantage is that, inside the module providing
C<get_server_status()> you don't have to define a separate class
implementing the objects returned by that subroutine. More importantly,
if you have a dozen subroutines returning specialized objects, you don't
have to define a dozen separate classes to support them.


=head2 RATIONALE

I<(Skip straight ahead to L<INTERFACE> if you already get it...or just
don't care why this approach is better.)>

Subroutines that return lists of values make client code brittle: it's far too
easy to mess up the unpacking:

    my ($ID, $name, $uptime, $users, $load, $contact, $location)
        = get_server_status($server_ID);

Subroutines that return hash references aren't much better: they do keep 
all the information together, and eliminate the order dependency of unpacking
it, but it's also very easy to misspell a key and thereby create a silent bug:

    my $server = get_server_status($server_ID);

    if ($server->{up_time}) {
        say "$server->{id} ($server->{name) load: $server->{load}";
    }

Like hashrefs, properly encapsulated objects keep all the returned
information together and allow it to be retrieved by name, but they can
also provide extra methods to simplify common tasks, and the OO syntax
makes it a fatal error to misspell any access attempt:

    my $server = get_server_status($server_ID);

    if ($server->up_time) {
        say $server->describe, ' load: ', $server->lode;
    }
    # dies with: "No such method 'lode' at demo.pl line 27"

The only downside is that object-based return values are tedious to set
up. If you have multiple subroutines in your API, each of them may need
to return a unique type of object, which means you have to define as
many distinct support classes as you have subroutines. And even with
helper modules (such as Moose or Object::InsideOut) that's a substantial
amount of extra work:

    sub get_server_status ($server_ID)  {
        my $status_ref = _acquire_status_somehow_for($server_ID);

        return GSS::Result->new(status => $status_ref);
    }

    # Class implementing result objects for get_server_status()...
    package GSS::Result {
        use Moose;

        has status => (is => 'ro', required => 1);

        sub ID       { my $self = shift; $self->status->{ID}       }
        sub name     { my $self = shift; $self->status->{name}     }
        sub uptime   { my $self = shift; $self->status->{uptime}   }
        sub load     { my $self = shift; $self->status->{load}     }
        sub users    { my $self = shift; $self->status->{users}    }
        sub location { my $self = shift; $self->status->{location} }
        sub contact  { my $self = shift; $self->status->{contact}  }

        sub is_up    { my $self = shift; $self->uptime > 0         }

        sub describe {
            my $self = shift;
            $self->ID . ' (' . $self->name . ')';
        }
    }

The Object::Result module allows you to have your cake
(per-subroutine return objects) without requiring quite
so much baking (of per-subroutine support clases).


=head1 INTERFACE

The module lexically inserts a new keyword (C<result>) into any scope
when it is loaded.

That keyword takes a single block of code containing zero or more method
specifications, and builds an object which supplies those methods. The
keyword then causes the surrounding subroutine to immediately return
that object.


=head2 Defining named methods

To define a normal named method for the result object, specify its
name followed by a block implementing its body. For example, to
specify that the result object has two methods: C<succeeded()> and
C<fitness()>:

    result {
        succeeded { return $outcome > 0 }
        fitness   { return $outcome * $sample->{metric} }
    }

Methods may be specifed with parameter lists (which are implemented
by the Method::Signatures module):

    result {
        succeeded (Num $threshold = 0) {
            return $outcome > $threshold
        }

        fitness {
            return $outcome * $sample->{metric}
        }
    }

If not specified with a parameter list, C<result> methods are assumed to
take no arguments (which is Method::Signatures' default behaviour).


=head1 Data storage for result objects

Result methods get their information (e.g. C<$outcome> and C<$sample>)
from the lexical variables declared in the surrounding subroutine.
For example:

    sub estimate_fitness ($sample, $environment) {
        my $outcome = $sample->{metric} < $environment->{max_impact}
            ? $environment->{fitness_func}->($sample->{max})
            : $environment->{max_survivability};

        result {
            succeeded (Num $threshold = 0) {
                return $outcome > $threshold
            }

            fitness {
                return $outcome * $sample->{metric}
            }
        }
    }

In other words, the various methods defined in the C<result> block
become closures over the variables inside the surrounding subroutine,
and the result object can use those variables as its private storage
(i.e. its attributes/fields).

For example, the full C<get_server_status()> subroutine shown earlier in
L<RATIONALE> could be implemented as:

    sub get_server_status ($server_ID)  {
        my $status_ref = _acquire_status_somehow_for($server_ID);

        result {
            ID       { $status_ref->{ID}         }
            name     { $status_ref->{name}       }
            uptime   { $status_ref->{uptime}     }
            load     { $status_ref->{load}       }
            users    { $status_ref->{users}      }
            location { $status_ref->{location}   }
            contact  { $status_ref->{contact}    }
            is_up    { $status_ref->{uptime} > 0 }
            describe { "$status_ref->{ID} ($status_ref->{name})" }
    }

using the lexical C<$status_ref> as the object's attribute storage.

Note that methods can also modify this private data, so the result
object from C<get_server_status()> could also support subsequent
annotations on the result:

    sub get_server_status ($server_ID)  {
        my $status_ref = _acquire_status_somehow_for($server_ID);
        my @annotations;

        result {
            # All the methods defined in the previous version, plus...

            add_note  ($msg) { push @annotations, $msg; }
            get_notes        { return @annotations;     }

    }


=head2 Coercions

Perl allows classes to specify coercive overloadings, so that their
objects can then be treated as if they were booleans, strings, numbers,
integers, or references to scalars, arrays, hashes, regexes, subroutines,
or typeglobs.

The C<result> keyword supports this kind of type-coercion too. Coercion
methods can be specified by naming the specific type in angle brackets.
For example, C<get_server_status()> could return a result object that is
true only if the server is up, and which stringifies to a printable
summary of the status, like so:

    sub get_server_status ($server_ID)  {
        my $status_ref = _acquire_status_somehow_for($server_ID);

        result {
            # All the methods defined in the previous version, plus...

            <BOOL>  { return $status_ref->{uptime} > 0;          }
            <STR>   { return $self->describe . ': ' $self->load; }
    }

Note that, because all methods (named or coercive) are implemented
via the Method::Signatures module, they automagically get a
C<$self> variable.

The following coercions are supported:

    Treat object as boolean:                  <BOOL>
    Treat object as string:                   <STR>
    Treat object as integer:                  <INT>
    Treat object as number:                   <NUM>
    Treat object as scalar ref:               <SCALAR>
    Treat object as array ref:                <ARRAY>
    Treat object as hash ref:                 <HASH>
    Treat object as typeblob ref/filehandle:  <GLOB>
    Treat object as regex:                    <REGEXP>  or <REGEX>
    Treat object as subroutine ref:           <CODE>    or <SUB>

In addition, the coercions to reference types can have the suffix C<REF>
appended to their names (e.g. C<< <HASHREF> >>, C<< <ARRAYREF> >>, 
C<< <SUBREF> >>, etc.)

Coercion methods take no arguments (except the implicit C<$self>) and
are expected to return either a value of the appropriate type, or some
other object with a suitable coercion overloading (i.e. the same
requirements as for coercions specified via C<use overload>).

By default, if a result object is asked for a particular coercion (apart
from boolean; see L<"Boolean coercions">), but did not have that
coercion explicitly defined, then the result object immediately throws
an exception. See L<"Default coercions"> for a way to change this
behaviour.


head3 Boolean coercions

By default, any result object that has at least one method or coercion
defined will evaluate true in a boolean context...as if they all had the
following coercion implicitly defined:

    result {
        <BOOL> { return 1 }
        ...
    }

However, as a special case, result objects with no methods at all:

    result { }

always evaluate false (besides having several other useful features; see
L<"Result objects for failure signalling">).

You can override these default boolean coercion behaviours simply by
defining an explicit C<< <BOOL> >> coercion yourself:

    result {
        <BOOL> { return defined $outcome }
        ...
    }

Or, if a result object has other methods, but should nevertheless always
evaluate false, you can define that explicitly too:

    result {
        <BOOL> { return 0 }
        ...
    }

Note, however, that in such cases it may be more effective to use a
L<I<failure object>|"Result objects for failure signalling">.


=head3 Default coercions

Although "missing" coercions default to throwing an exception,
it's also possible to specify that something else should happen when an
unimplemented coercion is requested...by using the C<< <DEFAULT> >> specifier.

For example, to convert the normal exception-throwing response
into merely warning about an unimplemented coercion:

    result {
        # Actual methods and coercions here

        <DEFAULT> ($requested_coercion, $obj_origin) {
            carp "Can't convert result of $obj_origin to $requested_coercion";
        }
    }

Or to revert the object to Perl's built-in behaviours
(i.e. address-as-integer in a numeric context,
C<"REFTYPE=CLASSNAME(0xADDRESS)"> in a string context, etc.)
you could specify:

    result {
        # Actual methods and coercions here

        <DEFAULT> { return $self }
    }

As the first example implies, the C<< <DEFAULT> >> coercion method
is passed two extra arguments apart from the usual C<$self>. The first
argument is a string containing the name of the missing coercion that
was requested: C<< '<STR>' >>, or C<< '<NUM>' >>, or C<< '<HASH>' >>,
etc. The second argument is a string indicating the origin of the result
object being coerced. That second argument is of the form:

    'call to __SUBNAME__() at __FILE__ line __LINE__'

and may be useful for generating more informative warnings or errors
within a C<< <DEFAULT> >> coercion.


=head2 Cleaning up result objects

If a result object manages some external resource, you can also set 
up a destructor for that object, using the C<< <DESTROY> >> pseudo-coercion:

    sub open_output_file ($filename) {
        open my $fh, '>', $filename or croak $!;

        result {
            write   (@whatever)  { print @whatever; }
            writeln (@whatever)  {   say @whatever; }

            <BOOL> { return not $fh->eof  }
            <GLOB> { return $fh           }

            # Make sure file is flushed before closing...
            <DESTROY> {
                $fh->flush();
                $fh->close();
            }
        }
    }


=head2 Result objects for failure signalling

The default behaviour of missing coercions provides an easy way to
produce so-called I<"contingent exceptions"> (a.k.a. I<"failure
objects">).

In particular, a C<result> statement of the form:

    result { <FAIL> }

or its exact equivalent, an "empty" C<result>:

    result { }

returns an object that evaluates false in boolean contexts and throws an
exception when used in any other way (i.e. whenever it has a method
called on it, or it is used as a string, number, regex, or reference).
The result object also throws an exception if it is destroyed without
having been tested in a boolean context.

That is, the two forms shown above are equivalent to something like:

    {
        my $tested_as_boolean = 0;
        my $error_msg = $@ // $! // $?;
        result {
            <BOOL>    { $tested_as_boolean++; return 0;          }
            <DEFAULT> { croak $error_msg;                        }
            <DESTROY> { croak $error_msg if !$tested_as_boolean; }
        }
    }

If you want the exceptions to throw something else, you can give the
C<< <FAIL> >> specifier a block, which will then be called instead
to generate the argument(s) to C<<croak()>:

    # Throw a different string as the exception...
    result {
        <FAIL> { "Could not load file: $!" }
    }

    # Throw an exception object...
    result {
        <FAIL> { X::File::NoLoad->new($!) }
    }

I<Failure objects> such as these are a useful way of signalling errors,
because the client code can test the result object (in which case it
evaluates false like a typical C<undef> or C<0> or C<""> failure value):

    my $status = get_server_status();

    if ($status) {     # 'if' test fails if sub returned failure object
        say $status;
    }

Or the client code can decide not to bother testing it, in which case it
dies when used in any non-boolean way (or not used at all):

    my $status = get_server_status();

    say $status;       # Dies here if sub returned failure object

Thus the exception-on-failure is contingent: it will be thrown if the
object is used in (almost) any way, unless the failure object has been
"defused" by testing it for in a boolean context.


=head1 DIAGNOSTICS

=head2 Compile-time diagnostics

=over

=item C<"Invalid syntax for 'result' statement. Expected block but found %s">

The C<result> keyword take a single block after it.
You put something else there instead.

Maybe you just needed a regular C<return>, instead of C<result>?


=item C<"Missing definition for %s method">

You declared the name of a method or coercion within the C<result>'s block,
but didn't give it an implementation (i.e. a block of code for it to execute).


=item C<"Invalid definition for %s method. Expected parameter list or method block, but found %s">

You declared the name of a method or coercion within the C<result>'s
block, so the module next expected to see either a parameter list
specification or else a block implementing the method or coercion.
It reported the syntax error, because it found something else instead
immediately after the method name.

=back

=head2 Run-time diagnostics

=over

=item C<"Object returned by %s can't be used as %s">

You tried to coerce a result object returned by C<result>
to some other type (a number, a string, a reference, etc.)
but the C<result> block didn't explicitly specify that coercion.

Add the appropriate coercion specification to the C<result> block.

Or, if you just wanted the vanilla Perl behaviours when coercing
such result objects, add:

    <DEFAULT> { $self }

to the C<result> block.


=item C<"Call to %s failed: %s  Failure detected at %s">

You called a subroutine that returned a I<failure object>
(i.e. a C<< result {<FAIL>} >>).

Such I<failure objects> can only be tested for their boolean value.
Doing anything else with them (or nothing at all with them) will produce
this exception...because that's what C<< <FAIL> >> is supposed to do.

=back


=head1 CONFIGURATION AND ENVIRONMENT

Object::Result requires no configuration files or environment variables.


=head1 DEPENDENCIES

=over

=item Keyword::Simple

To install the C<result> keyword.

=item PPI

To parse the new C<result>-block syntax cleanly.

=item Method::Signatures

To support signatures on methods declared within a
C<result> block.  Also used internally within the module's
own implementation.

=back


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-object-result@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Damian Conway  C<< <DCONWAY@CPAN.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2014, Damian Conway C<< <DCONWAY@CPAN.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
