package PostgreSQL::PLPerl::Call;
our $VERSION = '1.006';

=head1 NAME

PostgreSQL::PLPerl::Call - Simple interface for calling SQL functions from PostgreSQL PL/Perl

=head1 VERSION

version 1.006

=head1 SYNOPSIS

    use PostgreSQL::PLPerl::Call;

Returning single-row single-column values:

    $pi = call('pi'); # 3.14159265358979

    $net = call('network(inet)', '192.168.1.5/24'); # '192.168.1.0/24';

    $seqn = call('nextval(regclass)', $sequence_name);

    $dims = call('array_dims(text[])', '{a,b,c}');   # '[1:3]'

    # array arguments can be perl array references:
    $ary = call('array_cat(int[], int[])', [1,2,3], [2,1]); # '{1,2,3,2,1}'

Returning multi-row single-column values:

    @ary = call('generate_series(int,int)', 10, 15); # (10,11,12,13,14,15)

Returning single-row multi-column values:

    # assuming create function func(int) returns table (r1 text, r2 int) ...
    $row = call('func(int)', 42); # returns hash ref { r1=>..., r2=>... }

Returning multi-row multi-column values:

    @rows = call('pg_get_keywords'); # ({...}, {...}, ...)

Alternative method-call syntax:

    $pi   = PG->pi();
    $seqn = PG->nextval($sequence_name);

Here C<PG> simply means PostgreSQL. (C<PG> is actually an imported constant whose
value is the name of a package containing an AUTOLOAD function that dispatches
to C<call()>. In case you wanted to know.)

=head1 DESCRIPTION

The C<call> function provides a simple efficient way to call SQL functions
from PostgreSQL PL/Perl code.

The first parameter is a I<signature> that specifies the name of the function
to call and, optionally, the types of the arguments.

Any further parameters are used as argument values for the function being called.

=head2 Signature

The first parameter to C<call()> is a I<signature> that specifies the name of
the function.

Immediately after the function name, in parenthesis, a comma separated list of
type names can be given. For example:

    'pi'
    'generate_series(int,int)'
    'array_cat(int[], int[])'
    'myschema.myfunc(date, float8)'

The types specify how the I<arguments> to the call should be interpreted.
They don't have to exactly match the types used to declare the function you're
calling.

You also don't have to specify types for I<all> the arguments, just the
left-most arguments that need types.

The function name should be given in the same way it would in an SQL statement,
so if identifier quoting is needed it should be specified already enclosed in
double quotes.  For example:

    call('myschema."Foo Bar"');

=head2 Array Arguments

The argument value corresponding to a type that contains 'C<[]>' can be a
string formated as an array literal, or a reference to a perl array. In the
later case the array reference is automatically converted into an array literal
using the C<encode_array_literal()> function.

=head2 Varadic Functions

Functions with C<variadic> arguments can be called with a fixed number of
arguments by repeating the type name in the signature the same number of times.
For example, given:

    create function vary(VARIADIC int[]) as ...

you can call that function with three arguments using:

    call('vary(int,int,int)', $int1, $int2, $int3);

Alternatively, you can append the string 'C<...>' to the last type in the
signature to indicate that the argument is variadic. For example:

    call('vary(int...)', @ints);

Type names must be included in the signature in order to call variadic functions.

Functions with a variadic argument must have at least one value for that
argument. Otherwise you'll get a "function ... does not exist" error.

=head2 Method-call Syntax

An alternative syntax can be used for making calls:

    PG->function_name(@args)

For example:

    $pi   = PG->pi();
    $seqn = PG->nextval($sequence_name);

Using this form you can't easily specify a schema name or argument types, and
you can't call variadic functions. (For various technical reasons.)
In cases where a signature is needed, like variadic or polymorphic functions,
you might get a somewhat confusing error message. For example:

    PG->generate_series(10,20);

fails with the error "there is no parameter $1". The underlying problem is that
C<generate_series> is a polymorphic function: different versions of the
function are executed depending on the type of the arguments.

=head2 Wrapping and Currying

It's simple to wrap a call into an anonymous subroutine and pass that code
reference around. For example:

    $nextval_fn = sub { PG->nextval(@_) };
    ...
    $val = $nextval_fn->($sequence_name);

or

    $some_func = sub { call('some_func(int, date[], int)', @_) };
    ...
    $val = $some_func->($foo, \@dates, $debug);

You can take this approach further by specifying some of the arguments in the
anonymous subroutine so they don't all have to be provided in the call:

    $some_func = sub { call('some_func(int, date[], int)', $foo, shift, $debug) };
    ...
    $val = $some_func->(\@dates);


=head2 Results

The C<call()> function processes return values in one of four ways depending on
two criteria: single column vs. multi-column results, and list context vs scalar context.

If the results contain a single column with the same name as the function that
was called, then those values are extracted and returned directly. This makes
simple calls very simple:

    @ary = call('generate_series(int,int)', 10, 15); # (10,11,12,13,14,15)

Otherwise, the rows are returned as references to hashes:

    @rows = call('pg_get_keywords'); # ({...}, {...}, ...)

If the C<call()> function was executed in list context then all the values/rows
are returned, as shown above.

If the function was executed in scalar context then an exception will be thrown
if more than one row is returned. For example:

    $foo = call('generate_series(int,int)', 10, 10); # 10
    $bar = call('generate_series(int,int)', 10, 11); # dies

If you only want the first result you can use list context;

    ($bar) =  call('generate_series(int,int)', 10, 11);
     $bar  = (call('generate_series(int,int)', 10, 11))[0];

=head1 ENABLING

In order to use this module you need to arrange for it to be loaded when
PostgreSQL initializes a Perl interpreter.

Create a F<plperlinit.pl> file in the same directory as your
F<postgres.conf> file, if it doesn't exist already.

In the F<plperlinit.pl> file write the code to load this module.

=head2 PostgreSQL 8.x

Set the C<PERL5OPT> before starting postgres, to something like this:

    PERL5OPT='-e "require q{plperlinit.pl}"'

The code in the F<plperlinit.pl> should also include C<delete $ENV{PERL5OPT};>
to avoid any problems with nested invocations of perl, e.g., via a C<plperlu>
function.

=head2 PostgreSQL 9.0

For PostgreSQL 9.0 you can still use the C<PERL5OPT> method described above.
Alternatively, and preferably, you can use the C<plperl.on_init> configuration
variable in the F<postgres.conf> file.

    plperl.on_init='require q{plperlinit.pl};'

=head plperl

You can use the L<PostgreSQL::PLPerl::Injector> module to make the
call() function available for use in the C<plperlu> language:

   use PostgreSQL::PLPerl::Injector;
   inject_plperl_with_names_from(PostgreSQL::PLPerl::Call => 'call'); 

=head1 OTHER INFORMATION

=head2 Performance

Internally C<call()> uses C<spi_prepare()> to create a plan to execute the
function with the typed arguments.

The plan is cached using the call 'signature' as the key. Minor variations in
the signature will still reuse the same plan.

For variadic functions, separate plans are created and cached for each distinct
number of arguments the function is called with.

=head2 Limitations and Caveats

Requires PostgreSQL 9.0 or later.

Types that contain a comma can't be used in the call signature. That's not a
problem in practice as it only affects 'C<numeric(p,s)>' and 'C<decimal(p,s)>'
and the 'C<,s>' part isn't needed. Typically the 'C<(p,s)>' portion isn't used in
signatures.

The return value of functions that have a C<void> return type should not be
relied upon, naturally.

=head2 Author and Copyright

Tim Bunce L<http://www.tim.bunce.name>

Copyright (c) Tim Bunce, Ireland, 2010. All rights reserved.
You may use and distribute on the same terms as Perl 5.10.1.

With thanks to L<http://www.TigerLead.com> for sponsoring development.

=cut

use strict;
use warnings;
use Exporter;
use Carp;

our @ISA = qw(Exporter);
our @EXPORT = qw(call PG);

my %sig_cache;
our $debug = 0;

# encapsulated package to provide an AUTOLOAD interface to call()
use constant PG => do { 
    package PostgreSQL::PLPerl::Call::PG;
our $VERSION = '1.006';

    sub AUTOLOAD {
        #(my $function = our $AUTOLOAD) =~ s/.*:://;
        our $AUTOLOAD =~ s/.*:://;
        shift;
        return PostgreSQL::PLPerl::Call::call($AUTOLOAD, @_);
    }

    __PACKAGE__;
};


sub call {
    my $sig = shift;

    my $arity = scalar @_; # argument count to handle variadic subs

    my $how = $sig_cache{"$sig.$arity"} ||= do {

        # get a normalized signature to recheck the cache with
        # and also extract the SP name and argument types
        my ($stdsig, $fullspname, $spname, $arg_types) = _parse_signature($sig, $arity)
            or croak "Can't parse '$sig'";
        warn "parsed call($sig) => $stdsig\n"
            if $debug;

        # recheck the cache with with the normalized signature
        $sig_cache{"$stdsig.$arity"} ||= [ # else a new entry (for both caches)
            $spname,     # is name of column for single column results
            scalar _mk_process_args($arg_types),
            scalar _mk_process_call($fullspname, $arity, $arg_types),
            $fullspname, # is name used in SQL to make the call
            $stdsig,
        ];
    };

    my ($spname, $prepargs, $callsub) = @$how;

    my $rv = $callsub->( $prepargs ? $prepargs->(@_) : @_ );

    my $rows = $rv->{rows};
    my $row1 = $rows->[0] # peek at first row
        or return;        # no row: undef in scalar context else empty list

    my $is_single_column = (keys %$row1 == 1 and exists $row1->{$spname});

    if (wantarray) {                   # list context - all rows

        return map { $_->{$spname} } @$rows if $is_single_column;
        return @$rows;
    }
    elsif (defined wantarray) {        # scalar context - single row

        croak "$sig was called in scalar context but returned more than one row"
            if @$rows > 1;

        return $row1->{$spname} if $is_single_column;
        return $row1;
    }
    # else void context - nothing to do
    return;
}


sub _parse_signature {
    my ($sig, $arity) = @_;

    # extract types from signature, if any
    my $arg_types;
    if ($sig =~ s/\s*\((.*?)\)\s*$//) {
        $arg_types = [ split(/\s*,\s*/, lc($1), -1) ];
        s/^\s+// for @$arg_types;
        s/\s+$// for @$arg_types;

        # if variadic, replace '...' marker with the appropriate number
        # of copies of the preceding type name
        if (@$arg_types and $arg_types->[-1] =~ s/\s*\.\.\.//) {
            my $variadic_type = pop @$arg_types;
            push @$arg_types, $variadic_type
                until @$arg_types >= $arity;
        }
    }

    # the full name is what's left in sig
    my $fullspname = $sig;

    # extract the function name and un-escape it to get the column name
    (my $spname = $fullspname) =~ s/.*\.//; # remove schema, if any
    if ($spname =~ s/^"(.*)"$/$1/) { # unescape
        $spname =~ s/""/"/;
    }

    # compose a normalized signature
    my $stdsig = "$fullspname".
        ($arg_types ? "(".join(",",@$arg_types).")" : "");

    return ($stdsig, $fullspname, $spname, $arg_types);
}


sub _mk_process_args {
    my ($arg_types) = @_;

    return undef unless $arg_types;

    # return a closure that pre-processes the arguments of the call
    # else undef if no argument pre-processing is required

    my $hooks;
    my $i = 0;
    for my $type (@$arg_types) {
        if ($type =~ /\[/) {    # ARRAY
            $hooks->{$i} = sub { return ::encode_array_literal(shift) };
        }
        ++$i;
    }

    return undef unless $hooks;

    my $sub = sub {
        my @args = @_;
        while ( my ($argidx, $preproc) = each %$hooks ) {
            $args[$argidx] = $preproc->($args[$argidx]);
        }
        return @args;
    };

    return $sub;
}


sub _mk_process_call {
    my ($fullspname, $arity, $arg_types) = @_;

    # return a closure that will execute the query and return result ref

    my $placeholders = join ",", map { '$'.$_ } 1..$arity;
    my $sql = "select * from $fullspname($placeholders)";
    my $plan = eval { ::spi_prepare($sql, $arg_types ? @$arg_types : ()) };
    if ($@) { # internal error, should never happen
        chomp $@;
        croak "$@ while preparing $sql";
    }

    my $sub = sub {
        # XXX need to catch exceptions from here and rethrow using croak
        # to appear to come from the callers location (outside this package)
        warn "calling $sql(@_) [@{$arg_types||[]}]"
            if $debug;
        return ::spi_exec_prepared($plan, @_)
    };

    return $sub;
}

1;

=begin Pod::Coverage

call

=end Pod::Coverage

# vim: ts=8:sw=4:sts=4:et