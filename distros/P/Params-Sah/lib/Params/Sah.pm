package Params::Sah;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-10'; # DATE
our $DIST = 'Params-Sah'; # DIST
our $VERSION = '0.072'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Exporter qw(import);
our @EXPORT_OK = qw(gen_validator);

our $OPT_BACKEND        = 'Data::Sah';
our $OPT_ON_INVALID     = 'croak';
our $OPT_INVALID_DETAIL = 0;
our $OPT_NAMED          = 0;
our $OPT_DISABLE        = 0;
our $OPT_ALLOW_EXTRA    = 0;
our $DEBUG;

sub _plc {
    require Data::Sah;
    state $sah = Data::Sah->new;
    state $plc = $sah->get_compiler('perl');
    $plc;
}

sub gen_validator {
    my ($opt_backend,
        $opt_on_invalid, $opt_named, $opt_disable, $opt_allow_extra,
        $opt_invalid_detail, $opt_optional_params);
    {
        my $opts;
        if (ref($_[0]) eq 'HASH') {
            $opts = {%{shift()}};
        } else {
            $opts = {};
        }

        $opt_backend = delete $opts->{backend} // $OPT_BACKEND // 'Data::Sah';
        die "Invalid backend value, must be: Data::Sah|Data::Sah::Tiny"
            unless $opt_backend =~ /\A(Data::Sah::Tiny|Data::Sah)\z/;
        $opt_on_invalid = delete $opts->{on_invalid} // $OPT_ON_INVALID //
            'croak';
        die "Invalid on_invalid value, must be: croak|carp|warn|die|return"
            unless $opt_on_invalid =~ /\A(croak|carp|warn|die|return)\z/;

        $opt_invalid_detail = delete $opts->{invalid_detail} // $OPT_INVALID_DETAIL // 0;
        die "Data::Sah::Tiny does not support invalid_detail=>1"
            if $opt_backend eq 'Data::Sah::Tiny' && $opt_invalid_detail;
        $opt_named = delete $opts->{named} // $OPT_NAMED // 0;
        $opt_disable = delete $opts->{disable} // $OPT_DISABLE // 0;
        $opt_allow_extra = delete $opts->{allow_extra} // $OPT_ALLOW_EXTRA // 0;
        $opt_optional_params = delete $opts->{optional_params} // [];
        keys(%$opts) and die "Uknown gen_validator() option(s) specified: ".
            join(", ", sort keys %$opts);
    }
    if ($opt_disable) {
        return $opt_on_invalid eq 'str' ? sub {''} : sub {1};
    }

    require Carp;
    require Data::Dmp;

    my %schemas;
    my @schema_keys;
    if ($opt_named) {
        %schemas = @_;
        @schema_keys = sort keys %schemas;
        for (@schema_keys) {
            Carp::croak("Invalid argument name, must be alphanums only")
                  unless /\A[A-Za-z_][A-Za-z0-9_]*\z/;
        }
    } else {
        my $i = 0;
        %schemas = map {$i++ => $_} @_;
        @schema_keys = reverse 0..$i-1;
    }

    my $src = '';

    my $i = 0;
    my @modules_for_all_args;
    my %mentioned_vars;

    my $code_get_err_stmt = sub {
        my ($err_term_detail, $err_term_generic) = @_;
        if ($opt_on_invalid =~ /\A(croak|carp|warn|die)\z/) {
            my $stmt = $opt_on_invalid =~ /\A(croak|carp)\z/ ?
                "Carp::$opt_on_invalid" : $opt_on_invalid;
            return "$stmt(".($opt_invalid_detail ? $err_term_detail : $err_term_generic // $err_term_detail).")";
        } else {
            # return
            if ($opt_invalid_detail) {
                return "return $err_term_detail";
            } else {
                return "return 0";
            }
        }
    };

    # currently prototype won't force checking
    #if ($opt_named) {
    #    $src .= "sub(\\%) {\n";
    #} else {
    #    $src .= "sub(\\@) {\n";
    #}
    $src .= "sub {\n";

    $src .= "    my \$_ps_args = shift;\n";
    $src .= "    my \$_ps_res;\n" if $opt_invalid_detail;

    unless ($opt_allow_extra) {
        $src .= "\n    ### checking unknown arguments\n";
        if ($opt_named) {
            $src .= "    state \$_ps_known_args = ".Data::Dmp::dmp({map {$_=>1} @schema_keys}).";\n";
            $src .= "    my \@_ps_unknown_args;\n";
            $src .= "    for (keys %\$_ps_args) { push \@_ps_unknown_args, \$_ unless exists \$_ps_known_args->{\$_} }\n";
            $src .= "    if (\@_ps_unknown_args) { ".$code_get_err_stmt->(qq("There are extra unknown parameter(s): ".join(", ", \@_ps_unknown_args)))." }\n";
        } else {
            $src .= "    if (\@\$_ps_args > ".(scalar keys %schemas).") {\n";
            $src .= "        ".$code_get_err_stmt->(qq("There are extra additional parameter(s)")).";\n";
            $src .= "    }\n";
        }
    }

    for my $argname (@schema_keys) {
        unless (grep { $argname eq $_ } @$opt_optional_params) {
            $src .= "\n    ### checking $argname exists:\n";
            if ($opt_named) {
                $src .= "\n    unless (exists \$_ps_args->{".Data::Dmp::dmp($argname)."}) { ".$code_get_err_stmt->(qq("Missing required parameter '$argname'"))." }\n";
            } else {
                $src .= "\n    if (\@\$_ps_args <= $argname) { ".$code_get_err_stmt->(qq("Missing required parameter [$argname]"))." }\n";
            }
        }

        $src .= "\n    ### validating $argname:\n";
        my ($argterm, $data_name);
        if ($opt_named) {
            $argterm = '$_ps_args->{'.Data::Dmp::dmp($argname).'}';
            $data_name = $argname;
        } else {
            $argterm = '$_ps_args->['.$argname.']';
            $data_name = "arg$argname";
        }
        my $cd;
        if ($opt_backend eq 'Data::Sah') {
            $cd = _plc->compile(
                data_name    => $data_name,
                data_term    => $argterm,
                err_term     => '$_ps_res',
                schema       => $schemas{$argname},
                return_type  => $opt_invalid_detail ? 'str' : 'bool',
                indent_level => 1,
            );
        } else {
            require Data::Sah::Tiny;
            $cd = Data::Sah::Tiny::gen_validator($schemas{$argname}, {
                hash => 1,
                data_term => $argterm,
            });
        }
        die "Incompatible Data::Sah version (cd v=$cd->{v}, expected 2)" unless $cd->{v} == 2;
        for my $mod_rec (@{ $cd->{modules} }) {
            next unless $mod_rec->{phase} eq 'runtime';
            next if grep { ($mod_rec->{use_statement} && $_->{use_statement} && $_->{use_statement} eq $mod_rec->{use_statement}) ||
                               $_->{name} eq $mod_rec->{name} } @modules_for_all_args;
            push @modules_for_all_args, $mod_rec;
            $src .= "    ".($mod_rec->{use_statement} // "require $mod_rec->{name}").";\n";
        }
        for my $var (sort keys %{$cd->{vars}}) {
            next if $mentioned_vars{$var}++;
            my $val = $cd->{vars}{$var};
            $src .= "    my \$$var" . (defined($val) ? " = ".Data::Dmp::dmp($val) : "").
                ";\n";
        }
        $src .= "    undef \$_ps_res;\n" if
            $i && $opt_on_invalid =~ /\A(carp|warn)\z/;
        $src .= "    ".$code_get_err_stmt->(qq("$data_name: \$_ps_res"), qq("$data_name: fail schema ".).Data::Dmp::dmp($schemas{$argname}))." if !($cd->{result});\n";
        $i++;
    } # for $argname

    if ($opt_invalid_detail) {
        $src .= "\n    return '';\n";
    } else {
        $src .= "\n    return 1;\n";
    }

    $src .= "\n};";
    if ($DEBUG) {
        require String::LineNumber;
        say "DEBUG: Validator code:\n" . String::LineNumber::linenum($src);
    }

    my $code = eval $src;
    $@ and die
        "BUG: Can't compile validator code: $@\nValidator code: $code\n";
    $code;
}

1;
# ABSTRACT: Validate method/function parameters using Sah schemas

__END__

=pod

=encoding UTF-8

=head1 NAME

Params::Sah - Validate method/function parameters using Sah schemas

=head1 VERSION

This document describes version 0.072 of Params::Sah (from Perl distribution Params-Sah), released on 2020-05-10.

=head1 SYNOPSIS

 use Params::Sah qw(gen_validator);

 # for subroutines that accept positional parameters. all parameters required,
 # but you can pass undef to the third param.
 sub mysub1 {
     state $validator = gen_validator('str*', ['array*', min_len=>1], 'int');
     $validator->(\@_);
     ...
 }
 mysub1("john", ['a']);        # dies, the third argument is not passed
 mysub1("john", ['a'], 2);     # ok
 mysub1("john", ['a'], 2, 3);  # dies, extra parameter
 mysub1("john", ['a'], undef); # ok, even though the third argument is undef
 mysub1([],     ['a'], undef); # dies, first argument does not validate
 mysub1("john", [], undef);    # dies, second argument does not validate

 # for subroutines that accept positional parameters (this time arrayref instead
 # of array), some parameters optional. also this time we use 'allow_extra'
 # option to allow additional positional parameters.
 sub mysub1b {
     my $args = shift;
     state $validator = gen_validator({optional_params=>[2], allow_extra=>1}, 'str*', 'array*', 'int');
     $validator->($args);
     ...
 }
 mysub1b(["john", ['a']]);        # ok, the third argument is optional
 mysub1b(["john", ['a'], 2]);     # ok
 mysub1b(["john", ['a'], undef]); # ok
 mysub1b(["john", ['a'], 2, 3]);  # ok, extra params allowed

 # for subroutines that accept named parameters (as hash). all parameters
 # required, but you can pass undef to the 'age' parameter.
 sub mysub2 {
     my %args = @_;

     state $validator = gen_validator({named=>1}, name=>'str*', tags=>['array*', min_len=>1], age=>'int');
     $validator->(\%args);
     ...
 }
 mysub2(name=>"john", tags=>['a']);             # dies, the 'age' argument is not passed
 mysub2(name=>"john", tags=>['a'], age=>32);    # ok
 mysub2(name=>"john", tags=>['a'], age=>undef); # ok, even though the 'age' argument is undef
 mysub2(name=>[],     tags=>['a'], age=>undef); # dies, the 'name' argument does not validate
 mysub2(name=>"john", tags=>[],    age=>undef); # dies, the 'tags' argument does not validate

 # for subroutines that accept named parameters (this time as hashref). some
 # parameters optional. also this time we want to allow extra named parameters.
 sub mysub2b {
     my $args = shift;

     state $validator = gen_validator(
         {named=>1, optional_params=>['age'], allow_extra=>1},
         name=>'str*',
         tags=>['array*', min_len=>1],
         age=>'int*',
     );
     $validator->($args);
     ...
 }
 mysub2b({name=>"john", tags=>['a']});                  # ok
 mysub2b({name=>"john", tags=>['a'], age=>32});         # ok
 mysub2b({name=>"john", tags=>['a'], age=>32, foo=>1}); # ok, extra param 'foo' allowed
 mysub2b({name=>"john", tags=>['a'], age=>undef});      # dies, this time, 'age' cannot be undef

Example with more complex schemas, with default value and coercion rules:

 sub mysub2c {
     my %args = @_;
     state $validator = gen_validator(
         {named => 1, optional_params => ['age']},
         name => ['str*', min_len=>4, match=>qr/\S/, default=>'noname'],
         age  => ['int', min=>17, max=>120],
         tags => ['array*', min_len=>1, of=>['str*', match=>qr/\A\w+\z/], 'x.perl.coerce_rules'=>['From_str::comma_sep']],
     );
     $validator->(\%args);
     ...
 }
 mysub2c(tags=>['a']);                   # after validation, %args will be: (name=>'noname', tags=>['a'])
 mysub2c(name=>"mark", tags=>['b,c,d']); # after validation, %args will be: (name=>'mark', tags=>['b','c','d'])

Validator generation options:

 # default is to 'croak', valid values include: carp, die, warn, bool, str
 gen_validator({on_invalid=>'croak'}, ...);

=head1 DESCRIPTION

This module provides a way for functions to validate their parameters using
L<Sah> schemas.

=head1 VARIABLES

=head2 $DEBUG

Bool. If set to true will print validator code when generated.

=head2 $OPT_BACKEND

Str. Used to set default for C<backend> option.

=head2 $OPT_ALLOW_EXTRA

Bool. Used to set default for C<allow_extra> option.

=head2 $OPT_ON_INVALID

String. Used to set default for C<on_invalid> option.

=head2 $OPT_ERR_DETAIL

Bool. Used to set default for C<err_detail> option.

=head2 $OPT_DISABLE

Bool. Used to set default for C<disable> option.

=head2 $OPT_NAMED

Bool. Used to set default for C<named> option.

=head1 PERFORMANCE NOTES

See benchmarks in L<Bencher::Scenarios::ParamsSah>.

=head1 FUNCTIONS

None exported by default, but exportable.

=head2 gen_validator([\%opts, ] ...) => code

Generate code for subroutine validation. It accepts an optional hashref as the
first argument for options. The rest of the arguments are Sah schemas that
correspond to the function parameters in the same position, i.e. the first
schema will validate the function's first argument, and so on. Example:

 gen_validator('schema1', 'schema2', ...);
 gen_validator({option=>'val', ...}, 'schema1', 'schema2', ...);

Will return a coderef which is the validator code. The code accepts an arrayref
(usually C<< \@_ >>).

Known options:

=over

=item * backend => str (default: Data::Sah)

Can be set to the experimental L<Data::Sah::Tiny> to speed up validator
generation for simpler schemas.

=item * named => bool (default: 0)

If set to true, it means we are generating validator for subroutine that accepts
named parameters (e.g. C<< f(name=>'val', other=>'val2') >>) instead of
positional (e.g. C<< f('val', 'val2') >>). The validator will accept the
parameters as a hashref. And the arguments of C<gen_validator> are assumed to be
a hash of parameter names and schemas instead of a list of schemas, for example:

 gen_validator({named=>1}, arg1=>'schema1', arg2=>'schema2', ...);

=item * optional_params => array

By default all parameters are required. This option specifies which parameters
should be made optional. For positional parameters, specify the index (0-based).

=item * allow_extra => bool (default: 0)

If set to one then additional positional or named parameters are allowed (and
not validated). By default, no extra parameters are allowed.

=item * on_invalid => str (default: 'croak')

What should the validator code do when function parameters are invalid? The
default is to croak (see L<Carp>) to report error to STDERR from the caller
perspective. Other valid choices include: C<warn>, C<carp>, C<die>, C<bool>
(return false on invalid, or true on valid), C<str> (return an error message on
invalid, or empty string on valid).

=item * invalid_detail => bool (default: 0)

If set to true, will generate a more detailed error message. For example, with
this schema:

 [str => {min_len=>4}]

then the string C<'foo'> will fail to validate with this error message "Length
must be at least 4". Otherwise, the error message will just be something like:
"Fail schema ['str', {min_len=>1}]". By default this option is set to false for
slightly faster validation.

=item * disable => bool (default: 0)

If set to 1, will return an empty coderef validator. Used to disable parameter
checking. Usually via setting L</$OPT_DISABLE> to disable globally.

=back

=head1 FAQ

=head2 How do I learn more about Sah (the schema language)?

See the specification: L<Sah>. The L<Sah::Examples> distribution also contains
more examples. Also, for other examples, lots of my distributions contain
L<Rinci> metadata which includes schemas for each function arguments.

=head2 Why does the validator code accept arrayref/hashref instead of array/hash?

To be able to modify the original array/hash, e.g. set default value.

=head2 What if my subroutine accepts a mix of positional and named parameters?

You can put all your parameters in a hash first, then feed it to the validator.
For example:

 sub mysub {
     my %args;
     %args = %{shift} if req $_[0] eq 'HASH'; # accept optional hashref
     ($args{x}, $args{y}) = @_; # positional params
     state $validator = gen_validator(
         {named=>1, optional_params=>['opt1','opt2']},
         x=>"posint*",
         y=>"negint*",
         opt1=>"str*",
         opt2=>"str",
     );
     $validator->(\%args);
     ...
 }
 mysub(1, -2);                # ok, after validation %args will become (x=>1, y=>-2)
 mysub({}, 1, -2);            # ok, after validation %args will become (x=>1, y=>-2)
 mysub({opt1=>"foo"}, 1, -2); # ok, after validation %args will become (x=>1, y=>-2, opt1=>"foo")
 mysub({opt3=>"foo"}, 1, -2); # dies, unknown option 'opt3'
 mysub({opt1=>"foo"}, 1);     # dies, missing required arg 'x'
 mysub({opt1=>[]}, 1, -2);    # dies, 'opt1' argument doesn't validate

=head2 How to give default value to parameters?

By using the Sah C<default> clause in your schema:

 gen_validator(['str*', default=>'green']);

=head2 How to make some parameters optional?

By using the C<optional_params> option, which is an array of parameter names to make
optional. To set a positional parameter optional, specify its index (0-based) as name.

=head2 Why is my program failing with error message: Can't call method "state" on an undefined value?

You need to specify that you want to use C<state> variables, either by:

 # at least
 use 5.010;

or:

 use feature 'state';

=head2 How do I see the validator code being generated?

Set C<$Params::Sah::DEBUG=1> before C<gen_validator()>, for example:

 use Params::Sah qw(gen_validator);

 $Params::Sah::DEBUG = 1;
 gen_validator('int*', 'str');

Sample output:

   1|sub(\@) {
   2|    my $_ps_args = shift;
   3|    my $_ps_res;
    |
    |
   6|    ### validating 0:
   7|    no warnings 'void';
   8|    my $_sahv_dpath = [];
   9|    Carp::croak("arg0: $_ps_res") if !(    # req #0
  10|    ((defined($_ps_args->[0])) ? 1 : (($_ps_res //= (@$_sahv_dpath ? '@'.join("/",@$_sahv_dpath).": " : "") . "Required but not specified"),0))
    |
  12|    &&
    |
  14|    # check type 'int'
  15|    ((Scalar::Util::Numeric::isint($_ps_args->[0])) ? 1 : (($_ps_res //= (@$_sahv_dpath ? '@'.join("/",@$_sahv_dpath).": " : "") . "Not of type integer"),0)));
    |
    |
  18|    ### validating 1:
  19|    Carp::croak("arg1: $_ps_res") if !(    # skip if undef
  20|    (!defined($_ps_args->[1]) ? 1 :
    |
  22|    (# check type 'str'
  23|    ((!ref($_ps_args->[1])) ? 1 : (($_ps_res //= (@$_sahv_dpath ? '@'.join("/",@$_sahv_dpath).": " : "") . "Not of type text"),0)))));
  24|    return;
    |
  26|};

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Params-Sah>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Params-Sah>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Params-Sah>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Sah>, L<Data::Sah>

Alternative modules: L<Params::ValidationCompiler> (a compiled version of
L<Params::Validate>), L<Type::Params> (from L<Type::Tiny>).

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
