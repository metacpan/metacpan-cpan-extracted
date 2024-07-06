package Multi::Dispatch;

use 5.022;
use warnings;
use warnings::register 'noncontiguous';
use re 'eval';
use mro;
use Data::Dump;

our $VERSION = '0.000004';

use Keyword::Simple;
use PPR;

# Implement expectation tracking for regexes...
{
    my $expected = q{};
    my $lastpos  = -1;

    sub expect {
        my $pos = pos();
        if ($pos > $lastpos) {
            $expected = $_[0];
            $lastpos  = $pos;
        }
        elsif ($pos == $lastpos) {
            if (index($expected, $_[0]) < 0) {
                $expected .= " or $_[0]";
            }
        }
        return;
    }

    sub expect_first {
        ($expected) = @_;
        $lastpos    = pos();
        return;
    }

    sub expect_status {
        my ($source, $prefix) = @_;

        my $before = substr($source, 0, $lastpos) =~ s/\s/ /gxmsr;
        my $after  = substr($source, $lastpos)    =~ s/\n.*//xmsr;
        my $indent = "$prefix$before"             =~ s/\S/ /gxmsr;

        return "Expected $expected here:\n\n"
             . "    $prefix$before$after\n"
             . "    $indent^\n"
    }
}

# This parses a single :where(<constraint>)...
my $WHERE_ATTR_PARSER = qr{
    (?<where_attr>
        : (?&PerlOWS) where
        (?{ expect 'the opening paren of the :where constraint' })
        \(
        (?&PerlOWS)
        (?{ expect 'a valid constraint (a value, regex, type, or block)' })
        (?>(?<where_expr>
            (?>  (?<where_num>        (?>(?&PerlNumber))      )
            |    (?<where_str>        (?>(?&PerlString))      )
            |    (?<where_pat>        (?>(?&PerlRegex))       )
            |    (?<where_bool>       (?> true | false )      )
            |    (?<where_class>      (?>(?&complex_type))    )
            |    (?<where_undef>             undef            )
            |    (?<where_block>      (?>(?&PerlBlock))       )
            |    (?<where_sub>    \\& (?>(?&PerlIdentifier))  )
            )
        |
            (?= (?<where_error>  [^\)]*+ ) )      # (
            (?!)
        ))
        (?{ expect('the closing paren of the :where constraint') })
        (?&PerlOWS) \)
    )

    (?(DEFINE)
        (?<complex_type>  (?>(?&unary_type))
                          (?: (?>(?&PerlOWS)) [|&] (?>(?&PerlOWS)) (?>(?&unary_type)) )*+
        )

        (?<unary_type>    \~ (?>(?&PerlOWS)) (?>(?&unary_type))
                     |    (?>(?&atomic_type))
        )

        (?<atomic_type>   \( (?>(?&PerlOWS)) (?>(?&complex_type)) (?>(?&PerlOWS)) \)
                      |   (?> (?>(?&PerlQualifiedIdentifier)) | [[:alpha:]_]\w*:: )
                          (?: (?>(?&PerlOWS)) \[ (?>(?&PPR_balanced_squares)) \] )?+
        )
    )

    $PPR::GRAMMAR
}xms;

my $HAS_RETURN_STATEMENT = qr{
    (?&PerlEntireDocument)

    (?(DEFINE)
        (?<PerlTerm>
            (?>
                return \b (?: (?>(?&PerlOWS)) (?&PerlExpression) )?+
                (?{ $Multi::Dispatch::has_return = 1 })
            |
                (?> my | state | our ) \b           (?>(?&PerlOWS))
                (?: (?&PerlQualifiedIdentifier)        (?&PerlOWS)  )?+
                (?>(?&PerlLvalue))                  (?>(?&PerlOWS))
                (?&PerlAttributes)?+
            |
                (?&PerlAnonymousSubroutine)
            |
                (?&PerlVariable)
            |
                (?>(?&PerlNullaryBuiltinFunction))  (?! (?>(?&PerlOWS)) \( )
            |
                (?> do | eval ) (?>(?&PerlOWS)) (?&PerlBlock)
            |
                (?&PerlCall)
            |
                (?&PerlTypeglob)
            |
                (?>(?&PerlParenthesesList))
                (?: (?>(?&PerlOWS)) (?&PerlArrayIndexer) )?+
                (?:
                    (?>(?&PerlOWS))
                    (?>
                        (?&PerlArrayIndexer)
                    |   (?&PerlHashIndexer)
                    )
                )*+
            |
                (?&PerlAnonymousArray)
            |
                (?&PerlAnonymousHash)
            |
                (?&PerlDiamondOperator)
            |
                (?&PerlContextualMatch)
            |
                (?&PerlQuotelikeS)
            |
                (?&PerlQuotelikeTR)
            |
                (?&PerlQuotelikeQX)
            |
                (?&PerlLiteral)
            )
        ) # End of rule (?<PerlTerm>)

    )

    $PPR::GRAMMAR
}xms;

# This parses a single parameter specification (they're complicated!)...
my $PARAMETER_PARSER = qr{
    (?<parameter>
        (?: (?<type>
                (?! undef | true | false )
                (?: (?<antitype> ! (?&ows) ) )?+
                (?&PerlQualifiedIdentifier) (?: :: )?+
                (?: \[ (?>(?&PPR_balanced_squares)) \] )?+
                (?! (?&ows) => )    # Not a named parameter introducer
            )
            (?>(?&PerlOWS))
        )?+
        (?>
            (?> (?<alias>  \\                                 )
                (?<var>    (?<sigil> [\$\@%] | (?<subby> \& ) )
                           (?<name> (?&varname)               )
                )
            |   (?<num>    (?>(?&PerlNumber))   )
            |   (?<str>    (?>(?&PerlString))   )
            |   (?<bool>   (?> true | false )   )
            |   (?<pat>    (?>(?&PerlRegex))    )
            |   (?<undef>  undef                )
            |   (?<array>
                    (?: (?<var> (?<slurpy> (?<sigil> \@ ) ) (?<name> (?&varname) ) ) :
                      |         (?<slurpy> (?<sigil> \@ ) )                          :
                    )?+
                    \[ (?&ows)
                        (?<subparams> (?: (?>(?&parameter))
                                      (?: (?&comma) (?>(?&parameter)) )*+ )?+
                        )
                        (?&comma)?+
                    (?&ows) \]
                )
            |   (?<hash>
                    (?<slurpy>)
                    (?<hashreq> (?>(?&keyedparam)) (?: (?&comma) (?>(?&keyedparam)) )*+ )
                    (?> (?&comma) (?<hashslurpy> (?&hashvar) | % (?! (?&ows) \w) ) | )
                        (?&comma)?+
                |
                    \{ (?&ows)
                        (?>
                            (?<hashreq> (?>(?&keyedparam)) (?: (?&comma) (?>(?&keyedparam)) )*+ )
                            (?> (?&comma) (?<hashslurpy> (?&hashvar) | % (?! (?&ows) \w) ) | )
                                (?&comma)?+
                        |
                            (?<hashreq>)
                            (?> (?<hashslurpy> (?&hashvar)  | % (?! (?&ows) \w)) (?&comma)?+
                            |   (?<hashslurpy>)              (?&ows)
                            )
                        )
                    (?&ows) \}
                )
            |   (?=
                    (?<var>    (?<sigil> \$ | (?<slurpy> [\@%] ) )
                               (?<name> (?&varname) )
                    )
                )
                (?<expr> (?>(?&PerlBinaryExpression)) )
            |   (?<var>    (?<sigil> \$ | (?<slurpy> [\@%] ) | (?<subby> \& ) )
                           (?<name> (?&varname) )
                )
            )
            (?: (?&ows) (?<constraint> (?&where_attr) ) )?+
            (?: (?&ows) (?<optional> = )
                (?&ows) (?<default> (?>(?&PerlConditionalExpression)) )
            )?+
        |
            (?<sigil> \$ )
            (?: (?&ows)  (?<optional> = )
                (?&ows)  (?<default> (?&PerlConditionalExpression)?+ )
            )?+
        |
            (?<slurpy> (?<sigil>  [\@%]  ))
        )
    )

    (?(DEFINE)
        (?<PerlKeyword>  multi  )

        (?<keyedparam>
            (?>
                (?<key> (?>(?&PerlIdentifier)) | (?>(?&PerlString)) )?+
                (?&ows) => (?&ows)
                (?<subparam> (?&parameter) )
            )
        )

        (?<ows>      (?>(?&PerlOWS))                          )
        (?<comma>    (?> (?>(?&PerlOWS)) , (?>(?&PerlOWS)) )  )
        (?<varname>  (?> _ \w++ | [[:alpha:]] \w*+)           )
        (?<hashvar>  % (?> _ \w++ | [[:alpha:]] \w*+)         )

        $WHERE_ATTR_PARSER
    )
}xms;

our $errpos = 0;
my $MULTI_PARSER = qr{
        (?<multi>
            (?&ows)
            (?{ expect_first('the name of the multi') })
            (?<name> (?>(?&PerlIdentifier)) )

            (?>
                (?&ows)  (?{ expect('a valid attribute') })      : (?&ows) (?<autofrom> auto)?+ from
                         (?{ expect('opening paren') })          \(
                (?&ows)  (?{ expect('module name or qualified multi name') })
                         (?<from>
                             (?<frommodule>  (?>(?&PerlQualifiedIdentifier)))
                         |
                             \& (?<fromname> (?>(?&PerlQualifiedIdentifier)))
                         )
                (?&ows)  (?{ expect('closing paren')      })     \)
                (?&ows)  (?{ expect('end of declaration') })     (?= ; | \} | \z )
            |
                (?&ows)  (?{ expect('a valid attribute') })      : (?&ows) (?<export> export)
            |
                (?{ expect('a valid attribute') })
                (?<attributes>
                    (?: (?&ows)
                        (?: (?&where_attr)
                        |   (?&before_attr)
                        |   (?&common_attr)
                        |   (?&permute_attr)
                        )
                    )*+
                )

                (?&ows)
                (?{ expect('a signature') })
                \(

                (?&ows)
                (?<params>
                    (?{ expect('a parameter declaration') })
                    (?:
                        (?>(?&parameter))
                        (?: (?&comma)
                            (?{ expect('a parameter declaration') })
                            (?>(?&parameter)) )*+
                    )?+
                )
                (?&comma)?+

                (?&ows)
                (?{ expect('the closing paren of the signature') })
                \)

                (?&ows)
                (?{ expect('a valid code block') })
                (?<body> (?>(?&PerlBlock)) )
            )

            (?=
                (?: ; | \} | (?&ows) )*+   (?<nextkeyword> multimethod | multi )
                             (?&ows)       (?<nextname> (?>(?&PerlIdentifier)) )
            )?
        )

        (?(DEFINE)
            (?<before_attr>  : (?&ows) before \b )
            (?<common_attr>  : (?&ows) common \b )
            (?<permute_attr> : (?&ows) permute \b )
            $PARAMETER_PARSER
        )
}xms;

my $KEYEDPARAM_PARSER = qr{
    (?<keyedparam>
        (?>
            (?<key> (?>(?&PerlIdentifier)) | (?>(?&PerlString)) )?+
            (?&ows) => (?&ows)
            (?<subparam> $PARAMETER_PARSER )
        )
    )
}xms;

# Try to work out what went wrong, if something goes wrong...
my $ERROR_PARSER = qr{
    (?>(?&PerlOWS))
    (?<context>
        (?<name>                  (?>(?&PerlIdentifier))   )
        (?<name2> (?>(?&PerlOWS)) (?>(?&PerlIdentifier)) | )
    |
        [^;\}\s]*+
    )

    $PPR::GRAMMAR
}xms;

# Default redispatcher just punishes bad behaviour...
sub next::variant {
    my $subname = (caller 1)[3] || 'main scope';
    _die(0, "Can't redispatch via next::variant <at>",
            "(attempted to redispatch from $subname, which is not a multi)" );
}

sub gen_handler_for {
    my ($keyword, $package) = @_;

    my $object_pad_active = $^H{'Object::Pad/method'};

    return sub {
        my ($src_ref) = @_;
        my ($caller_package, $file, $line) = caller();

        # Track each multi...
        state $multi_ID; $multi_ID++;

        # Parse the entire multi declaration (if possible)...
        ${$src_ref} =~ s{\A $MULTI_PARSER }{}xo
            # Otherwise, report the error...
            or do {
                ${$src_ref} =~ m{\A $ERROR_PARSER }xo;
                my %found = %+;
                my $what = $keyword . ($found{name}  ? " $found{name}" : q{});
                my $DYM = $keyword ne 'multi'         ? q{}
                        : $found{name} =~ /\bsub$/    ? qq{(Did you mean: $keyword$found{name2} ...)\n}
                        : $found{name} =~ /\bmethod$/ ? qq{(Did you mean: multimethod$found{name2} ...)\n}
                        :                              q{};
                die "Invalid declaration of $what at $file line $line\n"
                  . expect_status( ${$src_ref}, $keyword)
                  . $DYM;
            };

        # Unpack and normalize the various components of the declaration...
        my (        $name, $attrs,    $params, $body, $nextkeyword, $nextname)
            = @+{qw< name   attributes params   body   nextkeyword   nextname >};
        my (        $from, $autofrom, $frommodule, $fromname, $export)
            = @+{qw< from   autofrom   frommodule   fromname   export>};
        if ($from && $frommodule) {
            $fromname //= $name;
        }
        elsif ($from && $fromname) {
            ($frommodule, $fromname) = $fromname =~ m{(.*)::(.*)};
        }
        $from       //= 0;
        $frommodule //= q{};
        $params     //= q{};
        $body       //= q{};

        my ($common, $before, $permute, $constraint) = (q{}, q{}, q{});
        if ($attrs) {
            $common     = $attrs =~ m{ : (?&PerlOWS) common  \b $PPR::GRAMMAR }xo         ? $& : q{};
            $before     = $attrs =~ m{ : (?&PerlOWS) before  \b $PPR::GRAMMAR }xo         ? $& : q{};
            $permute    = $attrs =~ m{ : (?&PerlOWS) permute \b $PPR::GRAMMAR }xo         ? $& : q{};
            $constraint = $attrs =~ m{ (?&where_attr) (?(DEFINE) $WHERE_ATTR_PARSER ) }xo ? $& : q{};
        }

        # Track contiguity of this declaration...
        my $noncontiguous = !$nextkeyword || $nextkeyword ne $keyword || $nextname ne $name ? 1 : 0;

        # Where are we installing the new variant (normally into the package where it's declared)???
        my $target_package = '__PACKAGE__()';
        my $target_name    = $name;

        # Handle :from imports...
        my $new_variants;
        if ($from) {
            # Find out where the multisub is coming from, and what it's called...
            my $from_arg = $name eq $fromname ? $from : "&${frommodule}::$fromname";
            if ($keyword eq 'multimethod') {
                _die(0, qq{Can't import multimethod variants via a :from attribute <at>\n}
                      . qq{(Did you mean: "multi $name :from($from_arg)" instead?)});
            }

            # Are there any variants to be imported???
            my $extra_variants = $Multi::Dispatch::impl{$fromname}{$frommodule};
            if (!$extra_variants) {
                # Try loading the module, if necessary...
                eval "require $frommodule";
                $extra_variants = $Multi::Dispatch::impl{$fromname}{$frommodule};
                if (!$extra_variants) {
                    _die(0, "Can't find any variants of $keyword $fromname() in package $frommodule");
                }
            }

            # Is the requested multi of the right type???
            {
                no warnings 'once';
                no strict 'refs';
                my $from_info
                    = $Multi::Dispatch::dispatcher_info_for{*{"${frommodule}::$fromname"}{CODE}};
                if ($from_info->{keyword} ne $keyword) {
                    _die(0, "Can't import $keyword $name() variants from $from <at>\n"
                          . "(${from}::$name() is a $from_info->{keyword}, not a $keyword)");
                }
            }

            # If we get to here, we have variants, so remember them...
            $new_variants = qq{ \@{ \$Multi::Dispatch::impl{'$fromname'}{'$frommodule'} } };
        }

        # Handle :export requests...
        elsif ($export) {
            $new_variants   = qq{ \@{ \$Multi::Dispatch::impl{'$name'}{__PACKAGE__()} } };
            $target_package = q{caller()};
            $target_name    = qq{{caller()."::$name"}};
        }

        # Can't use :common on multis (only on multimethods)...
        _die(0, "The multi $name can't be given a :common attribute <at>",
                "(Did you mean: multimethod $name :common...?)"
            ) if $keyword eq 'multi' && $common;

        # Normalize the :before counter...
        $before = $before ? '1' : '0';

        # Add the appropriate parameters for methods...
        if ($keyword eq 'multimethod' && !$object_pad_active) {
            $params = ($common ? '$class :where({$class = ref($class) || $class; 1}), '
                               : '$self  :where({ref $self}), '
                      )
                      . $params;
        }

        my $declarator = $object_pad_active && $keyword eq 'multimethod' ? 'method' : 'sub';
        my $invocant = $declarator eq 'sub' ? undef
                     : $common              ? '$class'
                     :                        '$self'
                     ;

        # Remember the line number after the keyword (so we can reset it after the new code)...
        my $endline = $line + ($& =~ tr/\n//);

        # Unpack the constraint...
        my $global_constraint = 0;
        my $constraint_desc = $constraint;
        if ($constraint) {
            # It's not a per-parameter constraint...
            $global_constraint++;

            # Unpack it and normalize it...
            $constraint =~ $WHERE_ATTR_PARSER;
            my %match = %+;
            $match{where_class} //= q{};

            # Constraints are tested one level down the call tree (so we need a special wantarray)...
            state $WANTARRAY = q{((caller 1)[5])};
            state $WANTARRAY_DEF = q{ no warnings 'once'; use experimental 'lexical_subs'; my sub wantarray () { (caller 2)[5] }; };

            # Build the code that implements it...
            $constraint
                = $match{where_block}                ? "do { $WANTARRAY_DEF do $match{where_block} }"
                : $match{where_sub}                  ? "(($match{where_sub})->())"
                : $match{where_class} eq 'LIST'      ? "do {  $WANTARRAY                        }"
                : $match{where_class} eq 'NONLIST'   ? "do { !$WANTARRAY                        }"
                : $match{where_class} eq 'SCALAR'    ? "do { !$WANTARRAY &&  defined $WANTARRAY }"
                : $match{where_class} eq 'NONSCALAR' ? "do {  $WANTARRAY || !defined $WANTARRAY }"
                : $match{where_class} eq 'VOID'      ? "do {                !defined $WANTARRAY }"
                : $match{where_class} eq 'NONVOID'   ? "do {                 defined $WANTARRAY }"
                : $match{where_error}                ? _die(0,
                                        "Incomprehensible constraint: :where($match{where_expr})",
                                        "in declaration of $keyword $name() <at>")
                :                                      _die(0,
                                        "Invalid $keyword constraint:  :where($match{where_expr})",
                                        "in declaration of $keyword $name() <at>",
                                        "(Can't use a literal value or regex or classname there. "
                                         ."What would it be compared to?)" );
        }


        # First test the variant's overall constraint (if any)...
        my $precode = q{};
        if ($constraint) {
            if ($keyword eq 'multimethod' && !$object_pad_active) {
                if ($common) {
                    $constraint = "do {my \$class = \$_[0]; $constraint}";
                }
                else {
                    $constraint = "do {my \$self  = \$_[0]; $constraint}";
                }
            }

            $precode .= "return q{Did not satisfy constraint on entire variant: $constraint_desc}
                        unless $constraint;\n"
        }

        # Dispense with :common from here if implementation will be via sub instead of method...
        $common = q{} if $declarator eq 'sub';

        # Construct the code that inserts the variant impl into the precedence list...
        my $existing_variants
            = $keyword eq 'multimethod'
                ? "map( {\@{\$Multi::Dispatch::impl{$name}{\$_} // []}} \@{mro::get_linear_isa(__PACKAGE__)} )"
                :       "\@{\$Multi::Dispatch::impl{$name}{$target_package}}";

        my $update_derived_classes
            = $keyword eq 'multimethod'
                ? qq{   for my \$class (\@{mro::get_isarev(__PACKAGE__)}) {
                            next if \$class eq __PACKAGE__;
                            my \$namespace = \$Multi::Dispatch::impl{$name};
                            \@{\$namespace->{\$class}}
                                = Multi::Dispatch::_AtoIsort(
                                    map {\@{\$namespace->{\$_} // []}} \@{mro::get_linear_isa(\$class)}
                                  );
                        }
                }
                : q{};

        # Extract the parameters...
        my $orig_param_list = _split_params($params);

        # Build a list of parameter lists (normally just one, unless permuted)...
        my @param_lists;
        if ($export) {
            # No parameter list to process
        }
        elsif (!$permute) {
            @param_lists = $orig_param_list;
        }
        else { # Deep copy each permutation (to avoid aliasing issues)...
            my @optionals = grep {  $_->{optional} ||  $_->{slurpy} } @{$orig_param_list};
            my @requireds = grep { !$_->{optional} && !$_->{slurpy} } @{$orig_param_list};
            use Algorithm::FastPermute;
            permute { push @param_lists, [map { {%$_} } @requireds, @optionals] } @requireds;
        }

        # Iterate all permutations and build appropriate variant implementations...
        for my $param_list (@param_lists) {
            my $constraint_count = $global_constraint;

            # Convert them to argument-processing and validation code (plus other useful info)...
            $params = _extract_params($package, $keyword, $name, $constraint_count, $param_list, '@_', undef, $before);
            my $code = $precode . $params->{code};
            $constraint_count += $params->{constraint_count};

            # Construct the code that detects and allows for the possibility of Object::Pad roles...
            my $add_role_variants = $keyword eq 'multimethod' && exists $INC{'Object/Pad.pm'}
                ? qq{map {\@{\$Multi::Dispatch::impl{$name}{\$_->name}}} eval {use Object::Pad::MOP::Class ':experimental(mop)'; Object::Pad::MOP::Class->for_class(__PACKAGE__())->direct_roles() }}
                : q{};

            # Implement this as a sub or a method???
            if ($declarator eq 'method') {
                $params->{min_args}++;
                $params->{max_args}++;
            }

            # Generate a suitable signature for use in diagnostic messages...
            my $signature = join ', ', map { $_->{source} } @{$param_list};
            if (length($signature) > 50) { $signature = substr($signature,0,50).' ...'; }
            $signature =~ s/[{}]/\\$&/g;


            # Create data structure for new variant (if not already imported via a :from)...
            if (!$from) {
                $new_variants .= qq{
                            {
                                pack      => $target_package,
                                file      => q{$file},
                                line      => $line,
                                name      => q{$name ($signature)},
                                before    => $before,
                                prec      => q{$params->{precedence}},
                                sig       => $params->{sig},
                                level     => '$params->{level}',
                                min       => $params->{min_args},
                                max       => $params->{max_args},
                                ID        => $multi_ID,
                                inception => do { no warnings 'once'; ++\$Multi::Dispatch::inception},
                                code      => $declarator $common { no warnings 'redefine'; $code return sub { local *next::variant; *next::variant = pop; local *__ANON__ = q{$name}; <BODY> } },
                            }, $add_role_variants,
                };
            }
        }

        my $implementation = qq{
            \@{\$Multi::Dispatch::impl{$name}{$target_package}}
                = Multi::Dispatch::_AtoIsort( $existing_variants, $new_variants );
            $update_derived_classes
        };

        my $redispatches = $body =~ /\b next::variant \b/x ? 1 : 0;
        my $dispatcher_code = _build_dispatcher_sub( debug      => $^H{'Multi::Dispatch debug'},
                                                     verbose    => $^H{'Multi::Dispatch verbose'},
                                                     name       => $name,
                                                     keyword    => $keyword,
                                                     as_sub     => $redispatches,
                                                     invocant   => $invocant,
                                                   );

        # Do we need to clone an existing dispatcher sub that was imported from elsewhere???
        my $clone_multi = q{};
        if ($keyword eq 'multi' && !$autofrom) {
            no strict 'refs';
            no warnings 'once';
            my $qualified_name = $caller_package.'::'.$name;
            if (*{$qualified_name}{CODE}) {
                my $info = $Multi::Dispatch::dispatcher_info_for{*{$qualified_name}{CODE}};
                if ($info && $info->{package} ne $caller_package) {
                    $clone_multi = "multi $name :autofrom($info->{package}); BEGIN { no warnings;"
                                 . "\$Multi::Dispatch::closed{'$keyword'}{'$name'}{$target_package}=0;}";
                }
            }
        }

        # Some components are unnecessary under :export...
        my $BEGIN = q{BEGIN};
        my $ISOLATION_TEST = qq{
                if (\$Multi::Dispatch::closed{'$keyword'}{'$name'}{$target_package}) {
                    package Multi::Dispatch::Warning;
                    warn "Isolated variant of $keyword $name()"
                        if warnings::enabled('Multi::Dispatch::noncontiguous');
                }
                else {
                    \$Multi::Dispatch::closed{'$keyword'}{'$name'}{$target_package} = $noncontiguous;
                }
        };
        if ($export) {
            $BEGIN = $ISOLATION_TEST = q{};
        }

        my $annotator = $^H{'Multi::Dispatch annotate'}
                            ? q{ UNITCHECK { Multi::Dispatch::_annotate(__PACKAGE__, __FILE__) } }
                            : q{};

        my $installer = qq{
            $BEGIN {
                no strict 'refs';
                $ISOLATION_TEST
                my \$redefining = $redispatches;
                if (*$target_name {CODE}) {
                    my \$info = \$Multi::Dispatch::dispatcher_info_for{*$target_name {CODE}};
                    if (!\$info) {
                        \$redefining = 1;
                        package Multi::Dispatch::Warning;
                        warn 'Subroutine $name() redefined as $keyword $name()'
                            if warnings::enabled('redefine');
                    }
                    elsif (\$info->{keyword} ne '$keyword') {
                        die qq{Can't declare a \$info->{keyword} and a $keyword of the same name ("$name") in a single package};
                    }
                    elsif (\$info->{package} ne $target_package ) {
                        \$redefining = 1;
                        package Multi::Dispatch::Warning;
                        warn ucfirst "\$info->{keyword} $name() [imported from \$info->{package}] redefined as $keyword $name()"
                            if ('$frommodule' ne \$info->{package})
                            && warnings::enabled('redefine');
                    }
                }
                else {
                    \$redefining = 1;
                }
                if (\$redefining) {
                    no warnings 'redefine';
                    my \$impl = $declarator $common {
                                my \@variants = \@{\$Multi::Dispatch::impl{'$name'}{$target_package}};
                                $dispatcher_code;
                             };
                    *$target_name = \$impl;
                    \$Multi::Dispatch::dispatcher_info_for{\$impl} = {
                        keyword => '$keyword',
                        package => $target_package,
                    };
                }
                $annotator
                $implementation
            }
        } =~ s/\n//gr
          =~ s/<BODY>/_fix_state_vars($body)/egr;

        # Install that code (and adjust the line numbering)...
        ${$src_ref} = $clone_multi . $installer . "\n#line $endline\n" . ${$src_ref};
    };
}

# Export the two new keywords...
sub import {
  my $package = shift;

  if (grep /\A-?debug\Z/, @_)         { $^H{'Multi::Dispatch verbose'}  = 1;
                                        $^H{'Multi::Dispatch debug'}    = 1; }
  if (grep /\A-?verbose\Z/, @_)       { $^H{'Multi::Dispatch verbose'}  = 1; }
  if (grep /\A-?annotate\Z/, @_)      { $^H{'Multi::Dispatch annotate'} = 1; }

  # Set up for redispatch...
  my $redispatcher = '$' . join q{}, map { ('a'..'z', 'A'..'Z')[rand 52] } 1..20;

  # Enable warnings for this module class...
  warnings->import('Multi::Dispatch');

  Keyword::Simple::define multi       => gen_handler_for('multi', (caller)[0]);
  Keyword::Simple::define multimethod => gen_handler_for('multimethod', (caller)[0]);
}

sub _annotate {
    my ($package, $file) = @_;

    # Only call once per file...
    state $seen;
    return if $seen->{$file}++;

    # Iterate the package's various multis...
    my %line;
    for my $impl (values %Multi::Dispatch::impl) {

        # Rank each variant of the multi...
        for my $n (keys @{$impl->{$package} // [] }) {

            # Extract the variant and convert it's index to an ordinal...
            my $variant = $impl->{$package}[$n];
            my $nth     = _ordinal($n);

            # Create (or append) the ordinal to the annotation for that line...
            my $linenum = $variant->{line};
            $line{$linenum} .= ', ' if $line{$linenum};
            $line{$linenum} .= "$nth ($variant->{level})";
        }
    }

    # Print out the rankings...
    for my $n (sort {$a<=>$b} keys %line) {
        warn "$line{$n} at $file line $n\n";
    }
}

sub _fix_state_vars {
    use PPR::X;
    my $str = PPR::X::decomment(shift);

    local %Multi::Dispatch::____STATEEND;
    state $STATE_EXTRACTOR = qr{ (?&PerlEntireDocument)
                                 (?(DEFINE)
                                     (?<PerlVariableDeclaration>
                                         (?{ pos })
                                         ((?&PerlStdVariableDeclaration))
                                         (?= (?>(?&PerlOWS)) = (?{ -$^R }) )?+
                                         (?{ $Multi::Dispatch::____STATEEND{$^R} = pos(); })
                                     )
                                  )
                                  $PPR::X::GRAMMAR
                                }xms;

    $str =~ $STATE_EXTRACTOR;

    return $str if !keys %Multi::Dispatch::____STATEEND;

    for my $start (reverse sort { abs($a) <=> abs($b) } keys %Multi::Dispatch::____STATEEND) {
        my $assign = $start < 0;
        my $end = $Multi::Dispatch::____STATEEND{$start};
        $start = -$start if $assign;
        my $len = $end - $start;
        my $state_var = substr( $str, $start, $len);
        $state_var =~ m{
            \A state \s*+
            (?>          (?<single>   (?<sigil> [\$\@%]) \s*+ \w++ )  \s*+
            | \( \s*+  (?<multiple> [^)]*+            )  \s*+ \)
            )
        }xms
            or next;
        my %cap = %+;
        state $next_varname = 'static0000000000';
        if (exists $cap{single}) {
            my $varname = 'Multi::Dispatch::_____' . $next_varname++;
            substr($str, $start, $len) = "\\state $cap{single} = \\$cap{sigil}$varname;"
                                    . ($assign ? "\$${varname}_init++ or $cap{single}" : q{});
        }
        elsif (exists $+{multiple}) {
            my $replacement;
            for my $state_var (split /\s*+,\s*+/, $cap{multiple}) {
                my $sigil = substr($state_var,0,1);
                my $varname = 'Multi::Dispatch::_____' . $next_varname++;
                $replacement .= "\\state $state_var = \\$sigil$varname;";
            }
            substr($str, $start, $len) = $replacement;
        }
    }

    return $str;
}

# Topological sort of a list of signatures...
sub _AtoIsort {
    return
        _toposort_sigs( grep {  $_->{before} } @_ ),
        _toposort_sigs( grep { !$_->{before} } @_ );
}

sub _toposort_sigs {
    my @sigs = @_;

    # 0. Build look-up table for signature records and original ordering...
    my %sig       = map { $_ => $_        }      @sigs;

    # 1. Compute narrowness relationships between signatures...
    my %narrowness;
    for my $i (keys @sigs) {
        for my $j ($i+1..$#sigs) {
            my $narrower = _narrowness($sigs[$i], $sigs[$j]);
            $narrowness{ $sigs[$i] }{ $sigs[$j] } =  $narrower;
            $narrowness{ $sigs[$j] }{ $sigs[$i] } = -$narrower;
        }
    }

    # 2. Compute relative narrowness of all possible pairs of signatures...
    my %less_narrow = map { $_ => {} } keys %sig;
    for my $sig1 (keys %narrowness) {
    for my $sig2 (keys %narrowness) {
        next if $sig1 eq $sig2;

        my $narrowness = $narrowness{$sig1}{$sig2};
           if ($narrowness > 0) { $less_narrow{$sig1}{$sig2} = 1; }
        elsif ($narrowness < 0) { $less_narrow{$sig2}{$sig1} = 1; }
    }}

    # 3. Partition into sets of equally narrow signatures...
    my @partitions;
    while ( my @narrowest = grep { ! %{ $less_narrow{$_} } } keys %less_narrow ) {

        # Put full signature records into each partition (not just signature descriptors)...
        push @partitions, [map { $sig{$_} } @narrowest];

        # Update graph by removing now-partitioned nodes...
        delete @less_narrow{@narrowest};
        delete @{$_}{@narrowest} for values %less_narrow;
    }

    # 4. Sort each partition by its precedence or originating class/package or inception...
    for my $partition (@partitions) {
        $partition = [sort { $b->{prec} cmp $a->{prec}
                                        ||
                             ( $a->{pack}  eq  $b->{pack}   ?  0
                             : $a->{pack}->isa($b->{pack})  ? -1
                             : $b->{pack}->isa($a->{pack})  ? +1
                             :                                 0
                             )
                                        ||
                               $a->{inception} <=> $b->{inception}
                           } @{$partition}
                       ];
    }

    # 5. Concatenate all partitions and return...
    return map { @{$_} } @partitions;
}

sub _narrowness {
    my ($x, $y) = map { $_->{sig} } @_;
    my $order = 0;

    for my $n (0..($#$x < $#$y ? $#$y : $#$x)) {
        my ($xn, $yn) = ($x->[$n], $y->[$n]);

           if (!defined($xn) && !defined($yn))      { next;                                }
        elsif ( defined($xn) && !defined($yn))      { return 0 if $order > 0; $order = -1; }
        elsif (!defined($xn) &&  defined($yn))      { return 0 if $order < 0; $order = +1; }
        elsif (     ref($xn) &&  ref($yn) ) {
              if ($xn->is_subtype_of($yn) )         { return 0 if $order > 0; $order = -1; }
           elsif ($yn->is_subtype_of($xn) )         { return 0 if $order < 0; $order = +1; }
        }
        elsif (    !ref($xn) && !ref($yn) ) {
               if ($xn eq $yn)                      { next }
            elsif ($yn eq 'OBJ' || eval{$xn->isa($yn)})  { return 0 if $order > 0; $order = -1; }
            elsif ($xn eq 'OBJ' || eval{$yn->isa($xn)} )  { return 0 if $order < 0; $order = +1; }
            else                                    { return 0; }
        }
    }

    return $order;
}

sub _build_dispatcher_sub {
    my %arg = @_;

    # Code to redispatch to deepest non-multi ancestor method, if no suitable multimethod...
    my $updispatch = $arg{keyword} eq 'multimethod'
        ? qq{ { no strict 'refs'; my \$uptarget; for my \$nexttarget (\@{mro::get_linear_isa(__PACKAGE__)} ) { next if exists \$Multi::Dispatch::impl{'$arg{name}'}{\$nexttarget} || ! *{\$nexttarget . '::$arg{name}'}{CODE}; \$uptarget = \$nexttarget; last; } goto &{\$uptarget . '::$arg{name}'} if \$uptarget; } }
        : q{};

    # Generate the dispatch code...
    my $code = q{
            <ADDSELF>
            <VERBOSE>
            my @failures;
            </VERBOSE>
            <DEBUG>
            warn sprintf "\nDispatching call to <NAME>("
                        . join(', ', map({Data::Dump::dump($_)} @_))
                        . ") at %s line %s\\n", (caller)[1,2];
            </DEBUG>
            while (my $variant = shift @variants) {
                # Skip variants that can't possibly work...
                <VERBOSE>
                # Extract the debugging information...
                my ($level, $name, $package, $file, $line)
                    = @{$variant}{qw<level name pack file line>};
                $name = $package.'::'.$name;
                </VERBOSE>

                if (@_ < $variant->{min}) {
                    <VERBOSE>
                    # Record skipped dispatch candidates...
                    my $at_least = $variant->{min} == $variant->{max} ? 'exactly' : 'at least';
                    push @failures, qq{    $level: $name\n},
                                    qq{        defined at $file line $line\n},
                                    qq{        --> SKIPPED: need $at_least $variant->{min} args but found only }. scalar(@_) . "\n";
                    </VERBOSE>
                    next;
                }
                if (@_ > $variant->{max}) {
                    <VERBOSE>
                    # Record skipped dispatch candidates...
                    my $at_most = $variant->{min} == $variant->{max} ? 'exactly' : 'at most';
                    push @failures, qq{    $level: $name\n},
                                    qq{        defined at $file line $line\n},
                                    qq{        --> SKIPPED: need $at_most $variant->{max} args but found }. scalar(@_) . "\n";
                    </VERBOSE>
                    next;
                }

                # Test the viability of this variant...
                my $handler = <VARIANT_CODE>;

                # Execute the variant if appropriate...
                if (ref $handler) {
                    <DEBUG>
                    # Report the successful dispatch (and the preceding failures)...
                    warn $_ for @failures,
                                qq{    $level: $name\n},
                                qq{        defined at $file line $line\n},
                                qq{        ==> SUCCEEDED\n};
                    </DEBUG>

                    # Add the redispatch mechanism to the argument list...
                    push @_, __SUB__();

                    # And then execute the variant...
                    goto &{$handler};
                }
                <VERBOSE>
                # Otherwise, record another unviable variant...
                else {
                    push @failures, qq{    $level: $name\n},
                                    qq{        defined at $file line $line\n},
                                    qq{        --> $handler\n};
                }
                </VERBOSE>
            }

            <UPDISPATCH>

            # If no viable variant, throw an exception (with the extra debugging info)...
            <VERBOSE>
            if (1 == grep /-->/, @failures) {
                die sprintf( "Can't call <NAME>(%s)\\n"
                        . "at %s line %s\\n",
                            join(', ', map({Data::Dump::dump($_)} @_)),
                            (caller)[1,2]), map { s/SKIPPED: //r } grep /-->/, @failures;
            }
            </VERBOSE>
            die sprintf( "No suitable variant for call to <KEYWORD> <NAME>()\\n"
                       . "with arguments: (%s)\\n"
                       . "at %s line %s\\n",
                         join(', ', map({Data::Dump::dump($_)} @_)),
                         (caller)[1,2]) <VERBOSE>, @failures</VERBOSE>;

    } =~ s{ <VERBOSE> (.*?) </VERBOSE> }{ $arg{verbose}  ? $1                             : q{} }egxmsr
      =~ s{   <DEBUG> (.*?) </DEBUG>   }{ $arg{debug}    ? $1                             : q{} }egxmsr
      =~ s{       <VARIANT_CODE>       }{ $arg{invocant} ? q{$_[0]->${\$variant->{code}}(@_[1..$#_])}
                                                         : q{&{$variant->{code}}} }egxmsr
      =~ s{        <ADDSELF>           }{ $arg{invocant} ? "unshift \@_, $arg{invocant};" : q{} }egxmsr
      =~ s{       <UPDISPATCH>         }{ $updispatch }egxmsr
      =~ s{      < ([A-Z_]++) >        }{ $arg{lc $1} // die 'Internal error' }egxmsr
      =~ s{        \s \# \N*           }{}gxmsr;

    if ($arg{as_sub}) {
        $code = "goto &{sub{$code}}";
    }
    return $code;
}

# Break a single parameter list into individual parameters, classifying their components...
sub _split_params {
    my ($params) = @_;

    my @split_params;
    while ($params =~ m{\G (?&comma)?+ (?<source> $PARAMETER_PARSER ) }gxmso) {
        push @split_params, {%+};
    }

    return \@split_params;
}

# Convert a textual parameter list to an actual list of params...
sub _extract_params {
    my ($package, $keyword, $name, $constraint_count, $params, $source_var, $source_var_desc, $before) = @_;

    my $seen_option;
    my $seen_slurpy = 0;
    my ($req_count, $opt_count, $destructure_count) = (0,0,0);

    # "Nameless" parameters get an improbable name...
    state $nameless_name = '$______' . join('', map { ('a'..'Z','A'..'Z')[rand 52] } 1..20) . '_____';
    state $nameless_num  = 1;

    # Split parameter list (if not already done)...
    if (!ref $params) {
        $params = _split_params($params);
    }

    # Extract and process each parameter...
    my @params;
    my @sig;
    for my $param (@{$params}) {

        # Extend signature (trivially, so far)...
        push @sig, 'undef';

        # Handle defaults...
        $param->{default} = 'undef'
            if exists $param->{default} && $param->{default} =~ /\A\s*\Z/;
        my $default = $param->{default};
        if (defined $default) {
            if (exists $param->{slurpy}) {
                _die(1, "A slurpy parameter ($param->{var}) may not have a default value: = $default");
            }

            local $Multi::Dispatch::has_return = 0;
            if ($default =~ /\b return \b/x
            &&  $default =~ $HAS_RETURN_STATEMENT
            &&  $Multi::Dispatch::has_return) {
                    _die(1, "Default value for parameter $param->{var} "
                        . "cannot include a 'return' statement\n<at>");
            }
        }
        if ($seen_slurpy) {
            _die(1,"Can't specify another parameter ($param->{parameter}) after the slurpy parameter",
                    "in declaration of $keyword $name()")
        }
        elsif ($seen_option && !$param->{slurpy} && !$param->{optional}) {
            _die(1, "Can't specify a required parameter ($param->{parameter}) "
                   ."after an optional or slurpy parameter",
                    "in declaration of $keyword $name()");
        }

        $seen_option ||= $param->{optional};
        $seen_slurpy++ if $param->{slurpy};

        # Track number of constraints on this param...
        my $param_constraint_count = 0;
        my $param_constraint = undef;

        # Normalize code parameters...
        $param->{subby} = '\\' if $param->{subby};

        # Name any unnamed parameter...
        $param->{var} //= $nameless_name . $nameless_num++;

        # Convert constraints to code (if not already done)...
        if (!exists $param->{constraint_code}) {
            # Handle prefix type constraints...
            if ($param->{type}) {
                $param_constraint_count++;
                $param->{constraint_desc} = $param->{type};

                $param_constraint = do {
                    my $type = $param->{type} =~ s{^!}{}r;
                    my $not  = $param->{antitype} ? '!' : '';
                    if ($type eq 'OBJ') {
                        $sig[-1] = qq{q{$not$type}};
                        $param->{antitype}
                            ? qq{ (eval { !Scalar::Util::blessed($param->{var}) || Scalar::Util::reftype($param->{var}) eq 'REGEXP'}) }
                            : qq{ (eval {  Scalar::Util::blessed($param->{var}) && Scalar::Util::reftype($param->{var}) ne 'REGEXP'}) };
                    }
                    elsif ($type =~ m{ \A [[:upper:]]++ \Z }xms) {
                        $param->{antitype}
                            ? "((Scalar::Util::reftype($param->{var})//q{}) ne '$type')"
                            : "((Scalar::Util::reftype($param->{var})//q{}) eq '$type')";
                    }
                    else {
                        my $sigil = substr($param->{var}//'$',0,1);
                        _die(1, "Can't specify return type ($not$type) on code parameter $param->{var}\nin declaration of $keyword $name()")
                            if $sigil eq '&';
                        my $type_check = eval qq{ no warnings; package $package; } .
                        ( $sigil eq '@'   ? qq{ ((ArrayRef[$type])->inline_check('\\$param->{var}')) }
                        : $param->{array} ? qq{ ((ArrayRef[$type])->inline_check(  '$param->{var}')) }
                        : $sigil eq '%'   ? qq{ (( HashRef[$type])->inline_check('\\$param->{var}')) }
                        : $param->{hash}  ? qq{ (( HashRef[$type])->inline_check(  '$param->{var}')) }
                        :                   qq{ (($type)->isa('Type::Tiny') || die
                                                and      ( $type )->inline_check(  '$param->{var}')) }
                        );
                        if (defined $type_check) {
                            state %seen;
                            if (!$seen{$type}++
                            &&  eval qq{ no warnings; grep defined, \@${type}::{qw<new DESTROY>} }
                            &&  warnings::enabled('ambiguous')
                            ) {
                                warn qq{"$type" constraint is ambiguous (did you mean "Object::" instead?)}
                                . ' at ' . join(' line ', (caller 1)[1,2]) . "\n";
                            }
                            $sig[-1] = "($not$type)";
                            "$not$type_check";
                        }
                        else {
                            $type =~ s/^::|::$//g;
                            $sig[-1] = qq{q{$not$type}};
                            $param->{antitype}
                                ? qq{ (eval { !Scalar::Util::blessed($param->{var}) || !$param->{var}->isa(q{$type}) }) }
                                : qq{ (eval {  Scalar::Util::blessed($param->{var}) &&  $param->{var}->isa(q{$type}) }) };
                        }
                    }
                };
            }

            # Handle expression constraints...
            if ($param->{expr} && $param->{expr} ne $param->{var}) {
                $param_constraint_count++;
                $param_constraint .= '&&' if defined $param_constraint;
                $param_constraint .= qq{eval{$param->{expr}}};
                $param->{constraint_desc} .= ' and ' if $param->{constraint_desc};
                $param->{constraint_desc} .= $param->{expr};
            }

            # Handle :where constraints...
            if ($param->{constraint}) {
                $param_constraint_count++;
                $param->{constraint_desc} .= ' and ' if $param->{constraint_desc};
                $param->{constraint_desc} .= $param->{constraint} =~ s{\A:where\(\{? | \}?\)\Z}{}gxmsr;
                $param_constraint .= '&&' if defined $param_constraint;
                $param->{constraint} =~ $WHERE_ATTR_PARSER;
                my %match = %+;
                $param_constraint
                .= $match{where_block} ? "do $match{where_block}"
                    : $match{where_sub}   ? "(($match{where_sub})->($param->{var}))"
                    : $match{where_undef} ? "do { ! defined($param->{var}) }"
                    : $match{where_bool}  ? "do { BEGIN { die 'Use of $match{where_bool} as a parameter"
                                        .                   "constraint requires Perl v5.36 or later'"
                                        .                   "if \$] < 5.036 }"
                                        .       "use builtin 'is_bool';"
                                        .       "defined($param->{var})"
                                        .       "!ref($param->{var})"
                                        .       "&& $param->{var} == $match{where_bool}"
                                        .       "&& builtin::is_bool($param->{var})"
                                        . "}"
                    : exists $match{where_num}
                                        ? "do { no warnings 'numeric';"
                                        .       "defined($param->{var})"
                                        .       "&& ($match{where_num} == $param->{var}) }"
                    : $match{where_error} ? _die(1, "Incomprehensible constraint: "
                                                    . "$param->{constraint}",
                                                    "in declaration of parameter $param->{var} "
                                                    . "of $keyword $name()\n<at>"
                                                )
                    : $match{slurpy}      ? _die(1, "Slurpy parameter $param->{var} can't be given"
                                                    . " a string, an undef, or a regex"
                                                    . " as a constraint: "
                                                    . "$param->{constraint}",
                                                    "in declaration of parameter $param->{var} "
                                                    . "of $keyword $name() <at>",
                                                    "(Perhaps you wanted: "
                                                    . ":where({ $param->{var} ~~ $match{where_expr} })"
                                                )
                    : $match{where_str}   ? "(defined($param->{var}) && $match{where_str} eq $param->{var})"
                    : $match{where_pat}   ? "(defined($param->{var}) && $param->{var} =~ $match{where_pat})"

                    : $match{where_class} ? do {
                                                my $type = $match{where_class};
                                                if ($type =~ m{ \A [[:upper:]]++ \Z }xms) {
                                                    "((Scalar::Util::reftype($param->{var})//q{}) eq q{$type})"
                                                }
                                                else {
                                                    my $type_check = eval qq{ package $package; ($type)->isa('Type::Tiny') || die and ($type)->inline_check(q{$param->{var}}); };
                                                    if (defined $type_check) {
                                                        $sig[-1] = $sig[-1] eq 'undef' || $sig[-1] =~ /^q\{/
                                                                    ? "($type)"
                                                                    : "(($sig[-1])&($type))";
                                                        $type_check;
                                                    }
                                                    else {
                                                        _die(1, "Can't parameterize a Perl class ($type})\nin a :where constraint")
                                                            if $match{where_class_params};
                                                        $type =~ s/^::|::$//g;
                                                        $sig[-1] = qq{q{$type}}
                                                            if $sig[-1] eq 'undef';
                                                        "(eval { Scalar::Util::blessed($param->{var}) && $param->{var}->isa(q{$type}) })";
                                                    }
                                                }
                                            }
                    :                       _die(1, "Internal error in constraint processing")
                    ;
            }

            # Finalize constraints...
            $param->{constraint_code} = $param_constraint;
        }

        # Handle aliasing...
        if ($param->{alias}) {
            $param_constraint_count++;
            $param->{alias_constraint}
                = $param->{sigil} eq '$' ? 'SCALAR'
                : $param->{sigil} eq '@' ? 'ARRAY'
                : $param->{sigil} eq '%' ? 'HASH'
                : $param->{sigil} eq '&' ? 'CODE'
                : _die(1, "Internal error in alias processing");
        }

        # Track the precedence and arities of the surrounding variant...
        $constraint_count += $param_constraint_count;
        $destructure_count++ if  $param->{array} || $param->{hash};
        $req_count++         if !$param->{optional} && !exists $param->{slurpy};
        $opt_count++         if  $param->{optional};

        # Remember the parameter...
        push @params, $param;
    }

    # Convert the parameter to inlineable code...
    my $code = q{};

    # Does the variant handle this many arguments???
    my $invocant_count = ($keyword eq 'multimethod' ? 1 : 0);
    if ($source_var ne '@_') {
        my $min_args = $req_count - $invocant_count;
        my $max_args = $req_count - $invocant_count + $opt_count;
        $code .= "return q{Not enough arguments (need at least $min_args)}
                    if $source_var < $req_count;\n";
        if (!$seen_slurpy) {
            $code .= "return q{Too many arguments (need at most $max_args)}
                        if $source_var > $req_count + $opt_count;\n";
        }
    }

    # Validate slurpy (if any)...
    my $slurpables = "($source_var - $req_count - $opt_count)";
    if ($seen_slurpy && $params[-1]{sigil} eq '%') {
        $code .= "{Multi::Dispatch::_die(1, 'Odd number of arguments passed to slurpy "
              . (!$params[-1]{var} || $params[-1]{var} =~ /\A._____/ ? 'final' : $params[-1]{var})
              .  " parameter of $keyword $name()') if $slurpables > 0 && $slurpables % 2;}\n"
    }

    # Install defaults and check constraints on aliased params and code params...
    for my $param_num (0..$#params) {
        my $param     = $params[$param_num];
        my $param_ord = _ordinal($param_num);

        $code .= "local \$_[$param_num] = $param->{default} if \$#_ < $param_num;"
            if exists $param->{default};

        if ($param->{subby}) {
            $code .= "{ use Scalar::Util 'reftype'; return q{$param_ord argument was not a subroutine reference, so it could not be bound to code parameter $param->{var}} if \@_ > $param_num && (reftype(\$_[$param_num])//'') ne 'CODE';}";

            # For unaliased code parameters, have to "copy" the sub...
            if (!$param->{alias}) {
                $code .= "local \$_[$param_num] = do{ my \$s = \$_[$param_num]; sub { goto &\$s }; };";
            }
        }
        elsif ($param->{alias}) {
            my $desc = lc($param->{alias_constraint});
            $code .= "{ use Scalar::Util 'reftype'; return q{$param_ord argument was not a $desc reference, so it could not be aliased to parameter \\$param->{var}} if \@_ > $param_num && (reftype(\$_[$param_num])//'') ne '$param->{alias_constraint}';}";
            }
    }

    # Declare and initialize non-slurpy parameters...
    my $paramassignlist  = '('.join(', ', map {($_->{subby}//$_->{alias}//q{}).$_->{var}} @params).')';
    my $paramdecllist    = '('.join(', ', map { $_->{subby} ? () : $_->{var}            } @params).')';
    my $paramsubdecllist =     join(' ',  map { $_->{subby} ? "sub $_->{name};" : ()    } @params);

    $code .= "my $paramdecllist; $paramsubdecllist { no warnings 'misc'; $paramassignlist = $source_var;}\n";

    # Construct the code to destructure and validate each argument...
    for my $param_num (keys @params) {
        my $param     = $params[$param_num];
        my $param_ord = _ordinal($param_num);
        my $varname   = $param->{var};
        my $showname  = $varname =~ /\A\Q$nameless_name/ ? $source_var_desc // "\\\$ARG[$param_num]"
                      :                                    $varname;

        # Handle implicit value constraints and destructures...
        if (exists $param->{bool}) {
            $constraint_count++;
            $code .= "BEGIN { die 'Use of $param->{bool} as a parameter constraint requires Perl v5.36 or later' if \$] < 5.036 } use builtin 'is_bool'; return q{$param_ord argument did not satisfy parameter constraint: $showname must be the distinguished boolean $param->{bool} value}
                        unless do { no warnings 'numeric';
                                    defined($varname)
                                    && !ref($varname)
                                    && $varname == $param->{bool}
                                    && builtin::is_bool($varname) };\n";
        }
        elsif (exists $param->{num}) {
            $constraint_count++;
            $code .= "return q{$param_ord argument did not satisfy parameter constraint: $showname must be the number $param->{num}}
                        unless do { no warnings 'numeric';
                                    defined($varname) && $varname == $param->{num} };\n";
        }
        elsif (exists $param->{str}) {
            $constraint_count++;
            $code .= "return q{$param_ord argument did not satisfy parameter constraint: $showname must be the string $param->{str}}
                        unless defined($varname) && $varname eq $param->{str};\n";
        }
        elsif (exists $param->{pat}) {
            $constraint_count++;
            $code .= "return q{$param_ord argument did not satisfy parameter constraint: $showname must match the pattern $param->{pat}}
                        unless defined($varname) && $varname =~ $param->{pat};\n";
        }
        elsif (exists $param->{undef}) {
            $constraint_count++;
            $code .= "return q{$param_ord argument did not satisfy parameter constraint: $showname must be undefined}
                        unless !defined($varname);\n";
        }
        elsif (exists $param->{array}) {
            $constraint_count++; # Must be an array ref
            $param->{array} =~ $PARAMETER_PARSER;
            $code .= "return q{$param_ord argument did not satisfy parameter constraint: $showname must be an array ref} unless do{ use Scalar::Util 'reftype'; (reftype($varname)//'') eq 'ARRAY' }\n;";
            my $subparams
            #                     Desc of this multi, Constraints, Params,       Arg source
            #                          |         |    |             /                 |
                = _extract_params($package, $keyword, $name, 0, $param->{subparams}, "\@{$varname}");
            $constraint_count  += $subparams->{constraint_count};
            $destructure_count += $subparams->{destructure_count};
            $code .= $subparams->{code};
        }
        elsif (exists $param->{hash}) {
            # Is it an implicit slurpy hash sequence???
            my $implicit_slurpy = exists $param->{slurpy};
            my $internal_slurpy = $param->{hashslurpy};

            # Track degree of slurpiness (which affects the ordering of variants)...
            $seen_slurpy++ if $implicit_slurpy;
            $seen_slurpy++ if length $internal_slurpy;

            # Set up internal slurpy var...
            my $internal_slurpy_varname = substr($nameless_name,1) . $nameless_num++;

            # Destructuring hashes expect hashrefs unless they're slurpy...
            if ($implicit_slurpy) {
                $code .= "return q{Can't pass odd number of arguments to named parameter sequence}"
                      .  "    unless (\$#_ - $param_num) % 2;\n"
                      .  "my %$internal_slurpy_varname = \@_[$param_num..\$#_];\n";
            }
            else {
                $constraint_count++; # Must be a hash ref
                $code .= "return q{$param_ord argument did not satisfy parameter constraint: "
                      .  "$showname must be a hash ref} unless do{ use Scalar::Util 'reftype'; (reftype($varname)//q{}) eq 'HASH'};\n"
                      .  "my %$internal_slurpy_varname = %{$varname};\n";
            }

            # Check that the hashref has sufficient entries...
            my $arity = 0;
            $code .= "<ARITY_CHECK>;\n";

            # Then check that every specified key exists in the hashref and extract it...
            my $has_optionals;
            while ($param->{hashreq} =~ m{\G (?&comma)?+ $KEYEDPARAM_PARSER $PPR::GRAMMAR}gcxmso) {
                my %cap = %+;
                $cap{key} //= $cap{name};
                my $entry      = '$'.$internal_slurpy_varname . '{'.Data::Dump::dump($cap{key}).'}';
                my $entry_desc = $showname                    . '{'.Data::Dump::dump($cap{key}).'}';

                if (!exists $cap{default}) {
                    $arity++;
                    $code .= $implicit_slurpy
                        ? "return q{Required named argument ('$cap{key}') not found in argument list} unless exists $entry;\n"
                        : "return q{Required key (\->{'$cap{key}'}) not found in hashref argument $showname} unless exists $entry;\n";
                }
                else {
                    $has_optionals = 1;
                }

                my $default_val = $cap{default} // 'undef';
                my $subparam
                    = _extract_params($package, $keyword, $name, 0, $cap{subparam}, "\@{[exists $entry ? $entry : $default_val]}", $entry_desc);
                $constraint_count  += $subparam->{constraint_count};
                $destructure_count += $subparam->{destructure_count};
                $code .= $subparam->{code};
                $code .= qq{$entry = $cap{default} if !exists $entry;} if exists $cap{default};
                $code .= 'delete $' . $internal_slurpy_varname . '{' . Data::Dump::dump($cap{key}) . "};\n"
            }

            # Insert the early arity check (once we know the correct arity...
            my $op      = length $internal_slurpy || $has_optionals  ? '>= '      : '== ';
            my $op_desc = length $internal_slurpy || $has_optionals  ? 'at least' : 'exactly';
            $code =~ s{<ARITY_CHECK>}
                      { $implicit_slurpy
                          ? qq{return q{Incorrect number of named arguments: expected $op_desc $arity but found } . keys(%{$internal_slurpy_varname}) unless keys %{$internal_slurpy_varname} $op $arity;\n}
                          : qq{return q{Incorrect number of entries in hashref argument $param_num: expected $op_desc $arity entries but found } . keys(%{$internal_slurpy_varname}) unless keys %{$internal_slurpy_varname} $op $arity;\n}
                      }xmse;

            # If no internal slurpy, make sure no other args were passed...
            if (!length $internal_slurpy) {
                $code .= $implicit_slurpy
                    ? "return qq{Invalid named argument} . (keys(%$internal_slurpy_varname)==1 ? '' : 's') . qq{ found in argument list:  } . substr(Data::Dump::dump(\\%$internal_slurpy_varname),1,-1) if keys %$internal_slurpy_varname;\n"
                    : "return qq{Invalid entr} . (keys(%$internal_slurpy_varname)==1 ? 'y' : 'ies') . qq{ found in hashref argument $showname: } . substr(Data::Dump::dump(\\%$internal_slurpy_varname),1,-1) if keys %$internal_slurpy_varname;\n";
            }
            # If named internal slurpy, copy remaining named args into it...
            elsif (length($internal_slurpy) > 1) {
                $code .= "my $internal_slurpy = %$internal_slurpy_varname;\n";
            }
        }


        # Finally, validate the parameter against its constraint (if any)...
        if (defined $param->{constraint_code}) {
            $code .= "return q{$param_ord argument did not satisfy constraint on parameter $showname: "
                  .  "$param->{constraint_desc}} unless $param->{constraint_code};\n"
        }
    }

    # Do we have a sig???
    my $sig_count = grep( {/[[:upper:]]/} @sig);
    my $sig       = $sig_count ? '['.join(',', @sig).']' : '[]';

    # Build a precedence string (variants are sorted on this)...
    my $precedence
        = sprintf("%07dA%07dC%07dD%07dE%07dF%01dG1H",
                    $sig_count,
                    $constraint_count, $destructure_count, $req_count,
                    1e7-1-$opt_count, (9-$seen_slurpy));
    my $level = $before && $before =~ 1                                     ? "B1"
              : $constraint_count && $constraint_count > $destructure_count ? "C$constraint_count"
              : $destructure_count                                          ? "D$destructure_count"
              : $req_count                                                  ? "E$req_count"
              : $opt_count                                                  ? "F$opt_count"
              :                                                               "G" . (9-$seen_slurpy);

    return {
        min_args          => $req_count,
        max_args          => ($seen_slurpy ? 1_000_000_000_000 : $req_count + $opt_count),
        precedence        => $precedence,
        level             => $level,
        code              => $code,
        constraint_count  => $constraint_count,
        destructure_count => $destructure_count,
        sig               => $sig,
    };
}

# Compute the 1-based ordinal position of a zero-based index...
sub _ordinal {
    my ($n) = 1 + shift();

    return $n =~ s{ (?: 1\d(?<th>) | 1(?<st>) | 2(?<nd>) | 3(?<rd>) | (?<th>) ) \K\z }
                  { (keys %+)[0] }exmsr;
}

# Use this to throw exceptions inside keyword processors...
sub _die {
    my $level = shift;
    my (undef, $file, $line) = caller($level+1);
    my $msg = join("\n", @_);
       $msg =~ s{ \n  <at>}{\nat $file line $line}gxms
    or $msg =~ s{ \h* <at>}{ at $file line $line}gxms
    or $msg =~ s{ \h* \Z}  { at $file line $line}gxms;
    die "$msg\n";
}

1; # Magic true value required at end of module
__END__

=encoding utf8

=head1  NAME

Multi::Dispatch - Multiple dispatch for Perl subs and methods


=head1  VERSION

This document describes Multi::Dispatch version 0.000004


=head1  SYNOPSIS

    use Multi::Dispatch;

    # Create a mini Data::Dumper clone that outputs in void context...
    multi dd :before :where(VOID) (@data)  { say &next::variant }

    # Format pairs and array/hash references...
    multi dd ($k, $v)  { dd($k) . ' => ' . dd($v) }
    multi dd (\@data)  { '[' . join(', ', map {dd($_)}                 @data) . ']' }
    multi dd (\%data)  { '{' . join(', ', map {dd($_, $data{$_})} keys %data) . '}' }

    # Format strings, numbers, regexen...
    multi dd ($data)                             { '"' . quotemeta($data) . '"' }
    multi dd ($data :where(\&looks_like_number)) { $data }
    multi dd ($data :where(Regexp))              { 'qr{' . $data . '}' }
    multi dd ($data :where(GLOB))                { "" . *$data }


    use Object::Pad;  # or use feature 'class', when it's available

    class MyClass {
        field $status;

        multimethod status ()            { return $status }
        multimethod status ($new_status) { $status = $new_status }
        multimethod status ("")          { die "New status cannot be empty" }
    }


=head1  DESCRIPTION

This module provides two new keywords: C<multi> and C<multimethod>
which allow you to define multiply dispatched subroutines and methods
with sophisticated signatures that may include aliasing, context constraints,
type constraints, value constraints, argument destructuring, and literal
value matching.


=head2  Multisubs

The keyword C<multi> declares a B<I<multisub:>> a multiply dispatched subroutine.
You can declare two or more multisub B<I<variants>> with the same name, as long as
they have distinct signatures. For example, here are three variants of the C<expect()>
multisub:

    multi expect ($expected, $msg) { die $msg               if !$expected  }
    multi expect (&expected, $msg) { die $msg               if !expected() }
    multi expect ($expected      ) { die "Unexpected error" if !$expected  }

With those declarations in place, the following calls to C<expect()>
will each invoke a different variant:

    expect(      $x > 0                          );   # Invokes 3rd variant
    expect(      $x > 0,   'Expected positive $x');   # Invokes 1st variant
    expect(sub { $x > 0 }, 'Expected positive $x');   # Invokes 2nd variant

Calling C<expect()> without arguments or with more than two arguments
produces an exception indicating that there was no suitable variant
that could handle the specified argument list.


=head2  Multimethods

The keyword C<multimethod> declares a multiply dispatched instance method.
You can declare two or more multimethod variants with the same name, as long as
they have distinct signatures. For example:

    package MyClass {
        multimethod name ()          { return $self->{name} }
        multimethod name ($new_name) { $self->{name} = $new_name }
        ...
    }

Now any call to S<C<< $obj->name() >>> without an argument simply returns
the current value of the C<'name'> entry in the hash-based object.
Whereas, calling S<C<< $obj->name($value) >>> with a single argument
assigns that argument to the same hash entry.

Calling S<C<< $obj->name($value1, $value2) >>> with two (or more) arguments
produces an exception indicating that there was no suitable variant
of C<name()> that could handle the specified argument list.

Note that every multimethod has an implicit first parameter (C<$self>)
which is automatically assigned a reference to the invocant object.

Multi::Dispatch can also be used in classes created using the L<Object::Pad>
module (and, eventually, using the new built-in C<class> mechanism):

    use Object::Pad;

    class MyClass {
        field $name;

        multimethod name ()          { return $name }
        multimethod name ($new_name) { $name = $new_name }
        ...
    }

In such cases, the underlying dispatcher will be implemented as a proper
Object::Pad C<method>, rather than as a simple Perl C<sub>.

Note that all subsequent class-based examples in this document
will be shown using the Object::Pad/S<C<use experimental 'class'>> syntax,
but would all work equally well using the classic Perl C<package>/C<sub>
OO mechanism.


=head3  Multimethod inheritance

A multimethod spans all the base classes of its own class.
That is: a multimethod in a derived class inherits the variants
defined in all of its base classes. For example:

    class Account {
        field $balance :reader;

        multimethod debit ($amount :where({$amount <= $balance})) {
            $balance -= $amount;
        }
        multimethod debit ($amount :where({$amount > $balance}) {
            die "Insufficient funds";
        }
    }

    class Account::Overdraft :isa(Account) {
        field $overdraft;

        multimethod debit ($amount :where({$amount > $self->balance})) {
            my $balance = $self->balance;
            $self->debit($balance);
            $overdraft += $amount - $balance;
        }
    }

When called on an object of class Account::Overdraft, the C<debit()> multimethod
has access to three variants: the one defined in its own class, and the two
inherited from Account.

The variant defined in Account::Overdraft overrides the
S<C<< :where({$amount > $balance}) >>> variant inherited from Account, because derived
variants always preempt base class variants with the same number of arguments
and constraints (see L<"How variants are selected for dispatch">).

Note, however, that the inherited S<C<< :where({$amount <= $balance}) >>> variant
continues to be available, because its constraint is mutually exclusive with
that of the derived variant.


=head3  C<:common> multimethods

Multimethods are normally per-object methods, but they can be declared
as per-class methods instead, by including the C<:common> attribute in their
declaration. For example:

    class Sequence {
        field $from :param;
        field $to   :param;
        field $step :param;

        multimethod of :common ($to) {
            $class->new(from=>0, to=>$to-1);
        }

        multimethod of :common ($from, $to) {
            $class->new(from=>$from, to=>$to);
        }

        multimethod of :common ($from, $then, $to) {
            $class->new(from=>$from, to=>$to, step=>$then-$from);
        }
    }

The Sequence class declares three variants of the C<of()> multimethod, each of
which allows the user to call them on the class, rather than on an object:

    $seq = Sequence->of(100);           # 0..99
    $seq = Sequence->of(1, 99);         # 1..99
    $seq = Sequence->of(1, 3, 99);      # 1, 3, 5,...99

Note that every C<:common> multimethod has an implicit first parameter
(C<$class>), which is automatically assigned a string containing the
name of the class through which it was invoked. Such multimethods
I<don't> have an automatic C<$self> parameter. This is true, even if
the C<:common> multimethod is invoked on a class instance (i.e. an object),
rather than on the class itself.


=head3  Multimethod inheritance of non-multi methods

As explained earlier, a multimethod in a derived class inherits
all the variants of the same name from all its parent classes,
and considers all of them when dispatching a call.

If a parent class declares a B<non->multi method of the same name,
that method would normally B<not> be considered when a call to the
multimethod is dispatched...because the inherited method isn't
an inherited variant; it's a separate method that has been overridden
by the derived-class multimethod of the same name.

For example, if the base class Debitable defines a C<debit()>
method:

    class DebitReporter {
        method debit($amount) { _report_deposit_attempt($amount) }
        ...
    }

    class Account :isa(DebitReporter) {
        field $balance :reader;

        multimethod debit ($amount :where({$amount <= $balance})) {
            $balance -= $amount;
        }
        multimethod debit ($amount :where({$amount > $balance}) {
            die "Insufficient funds";
        }
    }

...then that base-class method would B<not> be considered as a dispatch
target when an object of the derived class Account calls
C<< $acct_obj->debit($amount) >> and thereby invokes the derived
class's C<debit()> multimethod. Because C<method DebitReporter::debit()>
isn't a variant of C<multimethod Account::debit()>.

However, in such situations, Multi::Dispatch recognizes the relationship between
the base-class method and the derived-class multimethod, and uses the inherited
(non-multi) method as a fallback, if no variant of the derived-class
multimethod can be selected for dispatch.

In other words, each multimethod has an extra implicit variant that
attempts to redispatch calls in the traditional Perl OO fashion
(i.e. via C<next::method>). So, for example, Account's C<debit()>
multimethod effectively has an automatically supplied extra
lowest-precedence variant:

    # Implicitly added variant...
    multimethod debit (@args) { $self->next::method(@args) }

Note that, in such cases, the inherited non-multi method that is selected
as the fallback is determined entirely by the standard behaviour of
C<next::method>; That is, by the current C<use mro> semantics in effect
within the derived class.

Note too, that if you want to disable (or change) this fallback behaviour,
you can just explicitly define your own low-precedence variant in the
derived class. For example:

    # Explicitly switch off fallback behaviour...
    multimethod debit (@args) { die "Can't debit @args" }


=head2  Multisub and multimethod signatures

Multisubs and multimethods select which variant to call based
on how well a given argument list matches the B<I<signature>> of
each variant.

A variant's signature consists of the cumulative number, constraints, structure,
requiredness, optionality, and slurpiness of its various parameter variables.

The details of how a particular variant is selected are given in
L<"How variants are selected for dispatch"> but, in general, the dispatch mechanism
favours the most extensive, precise, specific, and constrained signature
that is compatible with the actual argument list.

For example, if a multisub has two variants:

    multi handle(@args)                                         {...}

    multi handle(Int $count, \%data :where({exists $data{name}) {...}

...then a call such as:

    handle(7, {name=>'demo', values=>[1,2,3]})

...would be compatible with the signatures of both variants, but will be
dispatched to the second variant, because that variant defines a signature that
is more extensive (two parameters vs one), more precise (exactly two arguments
required vs any number allowed), more specific (the first argument must be
an integer and the second argument must be a hashref), and more constrained
(the hashref must have a C<'name'> key).

In order to allow for this kind of precision and specificity in signatures,
the module provides a large number of parameter features (far larger
than Perl's built-in subroutine signatures). These are described in
the following sections.


=head3  Required parameters

Any scalar parameter that is included in a variant's signature, and which does
I<not> have a default value specified (see L<"Optional parameters">) is treated as
a required parameter.

When a multisub or multimethod is called with I<N> arguments, only those of its
variants with at most I<N> required parameters will be considered for final dispatch.
Variants with fewer than I<N> required parameters may also be considered if they have
additional optional or slurpy parameters to which the extra arguments can
be assigned.

For example, given the following declarations:

    multi compare ($x, $y)      {...}
    multi compare ($x, $y, $op) {...}

...the C<compare()> multisub can only be successfully called with
either two or three arguments. Any other number of arguments will
produce a "no suitable variant" exception.


=head3  Optional parameters

A required parameter may be made optional by appending an C<=>
after the parameter name, followed by an expression that produces
a suitable default value. For example:

    multi check ($test, $msg = 'Failed check') { croak $msg if !$test; }
    multi check (&test, $msg = 'Failed check') { croak $msg if !test(); }

Now the C<check()> multisub may be called with either one or two arguments,
and the second parameter will be "filled in" with the default string if only
one argument is passed.

Note that, if a multisub or multimethod has variants with either required
or optional arguments, the variant with the greater number of required
arguments will be preferred. For example, given:

    multimethod handle ($event, $comment = '???') {...}
    multimethod handle ($event, $comment        ) {...}

...a two-argument call to:

    $obj->handle($event, 'Normal event');

...will always call the second variant, because all of that variant's parameters
are required, whereas the second parameter of the first variant is only optional.

Note that, as with regular Perl subroutine signatures, all optional parameters
in the signature of a C<multi> or C<multimethod> must come I<after> any required
parameters, and before any final "slurpy" parameter.


=head4  C<return> as a default value

Perl's built-in signature mechanism for subroutines allows any parameter default
expression to include a C<return> statement. For example:

    sub name ($new_name = return $old_name) {
        $old_name = $new_name;
    }

This means that if the C<name()> subroutine is called without
an argument, it immediately returns the value of C<$old_name>,
without bothering to invoke the body of the subroutine.

The multisubs and multimethods provided by Multi::Dispatch
B<do not> allow parameter default values to include a C<return>,
because this would interfere with the variant selection process,
which must bind every compatible variant's signature to the argument
list, evaluating defaults as it goes, I<before> it decides which
variant to dispatch to. Encountering a C<return> in the middle of
that process would short-circuit the variant-selection process,
leading to incorrect dispatches.

Hence, Multi::Dispatch detects the presence of a C<return> statement
within a parameter default and issues a compile-time error.

Note that the use of C<return> statements in parameter defaults
is usually just a workaround for the lack of multiple dispatch
in standard Perl. The correct way to accomplish the same effect
with multiple dispatch is to define two variants, like so:

    sub name ()          { return $old_name }
    sub name ($new_name) { $old_name = $new_name }


=head3  Slurpy parameters

So far, all the parameters specified in a variant's signature must
be scalars (either required or optional). However, the final parameter
in a variant's signature may also be specified as either an array or
a hash, in which case all of the remaining arguments not yet assigned
to a preceding parameter are slurped up into that final array or hash.
Such a final parameter is therefore known as a "slurpy" parameter.
(This feature is also available in regular Perl subroutine signatures):

    multi sublist( $from, $to, @list ) {...}
    #                          ↑↑↑↑↑

    multi tidy( $str, %options) {...}
    #                 ↑↑↑↑↑↑↑↑

If the final slurpy parameter is an array, it will consume as many extra
arguments as are left in the argument list (or none, if the entire
argument list has already been allocated to preceding parameters).

If the final slurpy parameter is a hash, it will treat any remaining
arguments as a list of S<B<I<key>> C<< => >> B<I<value>>> pairs, and use that
list to initialize the slurpy hash. If the number of remaining arguments is
odd, this will throw a run-time exception (just as a regular Perl subroutine
signature would).

As with regular Perl subroutine signatures, the final slurpy of a variant
cannot be given a default value.


=head3  Anonymous parameters

In some cases you may need to ensure a parameter is passed to
a multisub or multimethod, but you may not care what value the
corresponding argument had. In such cases, you can leave out the
actual name of the parameter, and merely specify its sigil.

For example:

    class Event {
        multimethod handle ($timestamp, @log_msgs) {
            $log->report(time=>$timestamp, msg=> "@log_msgs");
            ...
        }
    }

    class Event::Unlogged :isa(Event) {
        multimethod handle ($, @) {
            ...
        }
    }

Here the derived Event::Unlogged has no need of the arguments passed to its
C<handle()> method, except that (to preserve Liskov Substitutability) they must
still be present. So, in the derived class, those parameters can be specified as
being anonymous, which ensures that their presence will still be verified,
but that no parameter variables will be allocated or initialized.

Note that any kind of simple parameter (scalar, array, hash, code) may be declared
anonymous. However, aliased parameters (see L<Aliased Parameters>) may not.

Anonymous scalar parameters may also be specified as optional:

        multimethod handle ($=undef, @) {
            ...
        }

Just as in regular Perl subroutine signatures, an anonymous optional
parameter may also omit the actual default value entirely:

        multimethod handle ($=, @) {
            ...
        }


=head3  Aliased parameters

Arguments passed to a multisub or multimethod are normally
copied into the relevant parameters. However, you can also
pass arguments as references, by placing a backslash in front
of the parameter:

    multi foo (\$s, \@a, \%h) {...}

Each such parameter expects to be passed a reference to the corresponding
type, and aliases that reference to the parameter using the built-in
"refaliasing" mechanism (see L<perlref|"Assigning to References">).

So the C<foo()> multisub defined above could be called like so:

    foo(\$name, \@scores, \%options)

...in which case the C<$s> parameter would be aliased to the C<$name> variable,
the C<@a> parameter would be aliased to the C<@scores> variable,
and the C<%h> parameter would be aliased to the C<@options> variable
I<(but B<please> choose better parameter names in real life!)>

An aliased parameter can be bound to any form of reference of
the appropriate kind, so you could also call C<foo()> like so:

    foo(\'my name', [1..99], {quiet=>1, overwrite=>0})

Note that any argument intended to be passed to an aliased parameter
I<must> be a reference of the appropriate type. If it isn't, the
entire variant will be excluded from the dispatch process.

Note too that, because each aliased parameter is bound to a reference
(i.e. a scalar value) you can specify as many array- or hash-alias
parameters as you wish. For example:

    multi merge(\@listA, \@listB) {
        return !@listA                ?  @listB
             : !@listB                ?  @listA
             : $listA[0] < $listB[0]  ?  ($listA[0], merge(\@listA[1..$#listA], \@listB)
             :                           ($listB[0], merge(\@listA, \@listB[1..$#listB])
    }

    merge(\@left, \@right);

Aliased array and hash parameters are B<not> slurpy in nature.
Each such parameter expects exactly one array reference or one hash reference only.
Of course, you can still place a single unaliased slurpy array or hash I<after> one
or more aliased arrays or hashes, to sop up any extra arguments.

=head3  Optional aliased parameters

Aliased parameters can also be specified as optional, in the usual way
(with a trailing C<=> and a default value):

    multi handle (\$event = \undef, \@data = [], \%options = {}) {...}

However, for obvious reasons, the default value should be a reference
of the appropriate kind. If it isn't, the non-reference default value
will cause the variant to immediately be excluded from the dispatch
process (because the non-reference default value cannot be aliased
to the parameter).

This will either cause a different variant to be selected, or else
(if there is no other compatible variant) a run-time I<"no suitable variant">
exception will be thrown.


=head3  Codelike parameters

Unlike Perl's regular subroutine signatures, multisubs and multimethods
can specify parameters that are subroutines. For example:

    # Functional composition: f ∘ g
    multi compose (&f, &g)   { ... }
    #              ↑↑  ↑↑

    # Callbacks...
    multimethod handle ($event, &on_success, &on_failure) {...}
    #                           ↑↑↑↑↑↑↑↑↑↑↑  ↑↑↑↑↑↑↑↑↑↑↑

Code parameters expect an argument that is a subroutine reference:

    my $normalize = compose( \&casefold, \&uniq );
    #                        ↑↑↑↑↑↑↑↑↑↑  ↑↑↑↑↑↑

    $obj->handle($next_event, sub {$success++}, sub {die "failed: @_'});
    #                         ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑  ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑


Each code parameter creates a lexical subroutine within the block of its
variant, and that lexical subroutine can then be called in the usual way
within the variant to invoke the corresponding coderef argument:

    multi compose (&f, &g)   { return sub { f(g(@_)) }
    #                                       ↑↑↑↑↑↑↑↑

    multimethod handle ($event, &on_success, &on_failure) {
        ...
        if ($handled) { on_success($event) }
        else          { on_failure($event) }
        #               ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑
    }


You can also specify code parameters as aliases:

    multi compose (\&f, \&g)  { return sub { f(g(@_)) }

    multimethod handle ($event, \&on_success, \&on_failure) {
        ...
        if ($handled) { on_success($event) }
        else          { on_failure($event) }
    }

As you see, in most cases aliased code parameters behave
exactly the same as unaliased code parameters...I<except>
if you take the address of the parameter:

    # This version is broken...
    multi call_once_bad (&fn) {
        state %already_called;
        die "Can't call that twice" if $already_called{\&fn}++;
        goto &fn;                   #                  ↑↑↑↑
    }

    # This version works as expected...
    multi call_once_good (\&fn) {
        state %already_called;
        die "Can't call that twice" if $already_called{\&fn}++;
        goto &fn;                   #                  ↑↑↑↑
    }

The first version is broken because each call to C<call_once_bad()>
effectively copies the subroutine argument (C<&fn>) to a new lexical subroutine,
which may have a different address in every call...and will definitely have
a different address from the original argument.

The second version works as intended because, in C<call_once_good()>,
the original subroutine-reference argument is I<aliased> to C<&fn>,
so C<&fn> has the same address as the argument itself.


=head2  Parameter constraints

So far, the different variants of a multisub or multimethod
have been distinguished solely by the number and kind of parameters
they define.

However, it is also possible to define two or more variants
with the same number of arguments, so long as they are distinguished
in some other way. One way two variants can be distinguished
is by the B<I<constraints>> placed upon their parameters.

A parameter constraint specifies that the value of the corresponding
argument must meet some condition. If any argument does not meet the
condition of its parameter, the variant is immediately rejected during
the dispatch process.

Multi::Dispatch allows parameters to be specified with two different kinds of
constraints: type tests and value tests, In keeping with long Perl tradition,
the module provides multiple mechanisms and multiple syntaxes for specifying
these tests. Specifically, parameter constraints can be specified via a
prefix typename or classname, via an infix expression on the parameter,
or via a postfix C<:where> attribute.


=head3  Prefix type constraints

If a parameter variable is preceded by an identifier, that identifier is
taken to be the name of a class, type, or "reftype", and the corresponding
argument must be compatible with that type, or else dispatch to the variant
will be rejected.

If the prefix identifier is entirely uppercased, then it is treated as a Perl
reference type and the corresponding argument must be of the same referential
type. That is, the argument must satisfy the constraint: C<reftype($arg) eq 'REFTYPE'>,
where C<'REFTYPE'> is one the type descriptor
strings returned by C<Scalar::Util::reftype()> or C<builtin::reftype()>.

For example, the following multisub defines three variants that can
accept (only) references to arrays, hashes, or subroutines:

    multi report (ARRAY $data) {...}
    multi report (HASH  $data) {...}
    multi report (CODE  $data) {...}

As a special case of this kind of constraint, if the prefix identifier is C<OBJ>:

    multi report (OBJ   $data) {...}

...then it specifies that the corresponding argument must be an object of some user-defined class.
In other words, the argument must satisfy the constraint: C<blessed($arg)>.
I<< (Note that Perl's built-in C<qr//> anonymous regexes are deliberately B<not> accepted
by the C<OBJ> constraint, because most people think of regexes as simple values,
rather than as objects.) >>

Otherwise, if the prefix identifier is a L<Type::Tiny> typename, it is treated as a type,
and the corresponding argument must satisfy the constraint: C<< TypeName->check($arg) >>.
Note, however, that this test is always inlined, so no extra method call is
actually involved.

For example, the following multimethod defined five variants that can accept
a variety of types of argument:

    use Types::Standard ':all';

    multimethod add (Int           $i   ) {...}
    multimethod add (StrictNum     $n   ) {...}
    multimethod add (Str           $s   ) {...}
    multimethod add (ArrayRef[Num] $aref) {...}
    multimethod add (FileHandle    $fh  ) {...}

Note that, in order to use such types, the specified type must already be
defined in the scope where the multisub or multimethod is defined. Typically
this means that the L<Types::Standard> module (or another module providing
Type::Tiny types, such as L<Types::Common::Numeric> or L<Types::Common::String>)
must already have been loaded in that scope.

If the prefix identifier is not a reference type or a defined Type::Tiny typename,
it will be treated as the name of a class, and the corresponding argument
must satisfy the constraint: C<< blessed($arg) && $arg->isa('Class::Name') >>.
That is, the argument must be an object (as defined by C<Scalar::Util::blessed()>
or C<builtin::blessed()>) of the specified class...or of one of its derived classes.

For example, the following multimethod provides three variants that can
accept either a Status::Message object, or an Event::Result object or a
Transaction object:

    multimethod update_status(Status::Msg   $m) {...}
    multimethod update_status(Event::Result $r) {...}
    multimethod update_status(Transaction   $t) {...}


There is some overlap in the capabilities of these three type-specification
mechanisms, so it is often possible to specify a particular type constraint
in multiple ways. For example:

    multi filter (Regexp::   $pat, IO::File   $fh) {...}   # Blessed objects
    multi filter (REGEXP     $pat, GLOB       $fh) {...}   # Builtin reftypes
    multi filter (RegexpRef  $pat, FileHandle $fh) {...}   # Type::Tiny types

Generally, constraints based on built-in reftypes are the quickest to verify,
but Type::Tiny types are more robust and reliable, whilst classnames will be
most appropriate in predominantly OO code. If you specify separate variants
with all three kinds of type constraint (as in the preceding example),
Type::Tiny types will take precedence over class types, which take precedence
over reftypes. Hence, in the preceding example, the C<filter(RegexpRef, FileHandle)>
variant will always be selected over the other two variants.

The precedence of Type::Tiny types over classnames also applies if a given
type specifier is I<both> a Type::Tiny typename and a Perl classname. For
example, given the following definitions:

    class Value { field $val :param :reader; }
    use Types::Standard 'Value';

    multi report(Value $v)  { say $v }

...the type-constraint on C<$v> will be S<C<< Value->check($v) >>>,
I<not> S<C<< $v->isa('Value') >>>. If you want an ambiguous type specifier
to be interpreted as a classname instead, either specify it that
way using Type::Tiny:

    use Types::Standard 'InstanceOf';

    multi report(InstanceOf['Value'] $v)  { say $v }

...or else just append a C<::> to the type specifier to mark
it unambiguously as a Perl classname:

    multi report(Value:: $v)  { say $v }


=head4  Class and type precedence

There is a broader issue of type precedence than just class vs type vs reftype.
Even when you are just using classes or just using Type::Tiny types, two
or more variants may both be valid alternatives. For example, if two or
more classname parameter constraints are in the same type hierarchy:

    multi handle (Event                   $e) {...}
    multi handle (Event::Priority         $e) {...}
    multi handle (Event::Priority::Urgent $e) {...}

...or if two or more parameter types are subtypes and supertypes:

    multimethod add (Int       $i) {...}
    multimethod add (StrictNum $n) {...}
    multimethod add (Str       $s) {...}
    multimethod add (Value     $v) {...}

If Event and Event::Priority are base classes of Event::Priority::Urgent,
then a call to C<handle($urgent_priority_event)> will satisfy the
parameter constraints of all three variants, as an Event::Priority::Urgent
object C<isa> Event::Priority object and also C<isa> Event object.
Likewise, a call to C<$obj.add(42)> will satisfy all four variants,
as 42 is an integer, a strict number, and a value, and can be trivially
coerced to a string.

The question then is how Multi::Dispatch selects the variant to be called
when two or more class/type constraints are equally well satisfied.
The answer is that Multi::Dispatch chooses the variant with the "most specific"
constraint. For classes, a derived class is "more specific" than all its base
classes, so the module prefers the variant with the most-derived class constraint.
For types, Type::Tiny defines an C<is_subtype_of()> method, and Multi::Dispatch
chooses the variant whose type constraint is a subtype of I<all> of the others.

The effect of these tie-breaking rules is that, generally, you simply get the
most specifically applicable variant for the actual type/class of argument passed.
Or, in other words: the least amount of surprise.

Ordering type-constrained variants like this is relatively easy when there is
only a single typed parameter involved. But things rapidly get more complex
when two or more parameters have class or type constraints. For example,
consider the following two situations:

    # Compare events...
    multi compare_events (Event           $e1, Event::Priority $e2) {...}
    multi compare_events (Event::Priority $e1, Event           $e2) {...}

    compare_events( Event::Priority->new, Event::Priority->new );


    # Implement a ternary $from <= $x <= $to operator...
    multi contains (Num $x, Int $from, Int $to) {...}
    multi contains (Int $x, Num $from, Num $to) {...}

    my $in_range = contains($n, 0, 9);

In each case, the constraints of both available variants are satisfied,
but which one will be called?

If we just consider the constraint on the first parameter, then
clearly the second variant is a better match. But if we consider
the second parameter's constraints, then the first variant is more specific (as
it also is for the third parameter of C<contains()>).

Hence, a set of variants can be intrinsically unordered where there are two or
more type-constrained parameters. Any language that supports multiple dispatch
based on argument types must handle these kinds of situations, but they may do
so in quite different ways. Some languages simply proceed left-to-right and
choose according to the leftmost constraint where a clear ordering is detected.
Others add up the number of most-specific constraints in each variant and select
the variant with the highest total. Others detect the inherent conflict and
produce either a compiler error or a run-time exception.

Multi::Dispatch simply detects that the two variants are not sortable by their
type constraints, and silently falls back on other means of selecting between
them (as described in L<"How variants are selected for dispatch">). In the
above cases, this would result in the first variant of each multisub being
called I<(because the variants are not distinguishable by the structure,
number, or requiredness of their parameters, so the module sorts them
earliest-declaration-first)>.

Note that in such situations, if the fallback selection doesn't do what you
want, the correct solution is to provide I<yet another> variant; one that is
unambiguously more precise than the existing choices. For example:

    # Variant in which both constraints are most specific...
    multi compare_events (Event::Priority $e1, Event::Priority $e2) {...}

    # Variant in which all three constraints are most specific...
    multi contains (Int $x, Int $from, Int $to) {...}


=head4  Anti-type prefix constraints

Instead of specifying that a parameter must satisfy a specific type-constraint,
you can also specify that a particular parameter must I<not> satisfy a specific constraint.
For example, you can specify that a parameter must not be an integer, or not a regex,
or not an object of a particular class.

You can specify this kind of "antitype" for all three kinds of prefix type constraints,
simply by prefixing the type-specifier with a C<!>, like so:

    # First argument must NOT be a regular expression...
    #             ↓
    multi filter( !Regexp::  $str, IO::File   $fh ) {...}
    multi filter( !REGEXP    $str, GLOB       $fh ) {...}
    multi filter( !RegexpRef $str, FileHandle $fh ) {...}


    # The argument must NOT be an instance of the Value class...
    #             ↓
    multi report( !InstanceOf['Value'] $v )  { say $v }
    multi report( !Value::             $v )  { say $v }


    # Second argument must NOT be a hash of integers...
    #                           ↓
    multi hoi_map( Code $block, !HashRef[Int] $data )  {
        die "hoi_map() requires a hash of integers";
    }


=head3  Postfix C<:where> blocks

Type constraints focus on the kind of argument that is passed to a parameter,
but you can also test the actual value of an argument as a parameter constraint,
by specifying a C<:where> attribute immediately after the parameter name.
For example:

    #                   ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
    multi factorial ($n :where({$n <  2})) { 1 }
    multi factorial ($n :where({$n >= 2})) { $n * factorial($n-1); }

    #                 ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
    multi alert ($msg :where({length($msg) == 0})) {}
    multi alert ($msg :where({length($msg) >  0})) { Alert->new($msg)->raise }

    #                              ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
    multimethod deposit ( @amounts :where({sum(@amounts) < 0}) ) {
        die "Can't deposit a negative total: use withdraw() instead.";
    }
    #                              ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
    multimethod deposit ( @amounts :where({sum(@amounts) > 10000}) ) {
        die "Can't deposit a large total: use report_deposit() instead.";
    }
    #                             ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
    multimethod deposit (@amounts :where({0 < sum(@amounts) < 10000}) ) {
        $balance += $_ for @amounts;
    }

Note that in each case, the condition in the parens of the C<:where> attribute
is a block of code, which tests some property of the value assigned to the
corresponding parameter. A variant is rejected as a candidate for dispatch
if any of its parameter's C<:where> blocks returns a false value.

C<:where> blocks can also refer to other parameters declared earlier
in the variant's parameter list:

    # Swap back range boundaries if they were passed in the wrong order...
    #                                ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
    multimethod set_range($from, $to :where({$to >  $from}) ) { ($min, $max) = ($from, $to) }
    multimethod set_range($from, $to :where({$to <= $from}) ) { ($min, $max) = ($to, $from) }

...or to external variables:

    # Ignore alerts if global $SILENT variable is set...
    #                 ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
    multi alert ($msg :where({$SILENT})) {}

...or even to stateful operators or functions:

    # Ignore alerts if non-interactive input or closed output...
    #                 ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
    multi alert ($msg :where({ not -t *STDOUT })) {}
    multi alert ($msg :where({ !eof()         })) {}

Note that, because variants with C<:where> constraints are considered
for dispatch ahead of variants without constraints, you can dispense
with the parameter constraint on a subsequent variant if that constraint
is mutually exclusive with the constraint on the equivalent parameter in
a preceding variant. For example:

    multi factorial ($n :where({$n == 0})) { 1 }
    multi factorial ($n                  ) { $n * factorial($n-1); }

    multi alert ($msg                            ) {}
    multi alert ($msg :where({length($msg) >  0})) { Alert->new($msg)->raise }

    multimethod deposit ( @amounts :where({sum(@amounts) < 0})     ) {...}
    multimethod deposit ( @amounts :where({sum(@amounts) > 10000}) ) {...}
    multimethod deposit ( @amounts                                 ) {...}

    multimethod set_range($from, $to                        ) {...}
    multimethod set_range($from, $to :where({$to <= $from}) ) {...}


=head3  Postfix C<:where> values

A common use of C<:where> blocks is to select a special behaviour
for particular argument values. For example:

    multi factorial ($n :where({$n == 0}))  { 1 }
    multi factorial ($n                  )  { $n * factorial($n-1) }

    multi alert ($msg :where({$msg eq ""})) {}
    multi alert ($msg                     ) { Alert->new($msg)->raise }

This is somewhat tedious and potentially error prone. So C<:where> constraints
can also be specified as a literal value: a number, a string, a regular expression,
an C<undef>, a sigiled subroutine name, or a class or type name. When specified with
such a value, a C<:where> attribute smart-matches the parameter variable against that
value, as follows:

=over

=item *

C<:where(12345)>    ––––>    C<< :where({ $PARAM == 12345  }) >>

=item *

C<:where('str')>    ––––>    C<< :where({ $PARAM eq 'str'  }) >>

=item *

C<:where(/pat/)>    ––––>    C<< :where({ $PARAM =~ /pat/  }) >>

=item *

C<:where(undef)>    ––––>    C<< :where({ !defined($PARAM) }) >>

=item *

C<:where(\&fun)>    ––––>    C<< :where({ fun($PARAM) }) >>

=item *

C<:where(X::IO)>    ––––>    C<< :where({ $PARAM->isa(X::IO) }) >>

=item *

C<:where(Value)>    ––––>    C<< :where({ Value->check($PARAM) }) >>

=item *

C<:where(ARRAY)>    ––––>    C<< :where({ reftype($PARAM) eq 'ARRAY' }) >>

=back

So, for example, the previous examples could also be specified like so:

    multi factorial ($n :where(0))  { 1 }
    multi factorial ($n          )  { $n * factorial($n-1) }

    multi alert ($msg :where(""))   {}
    multi alert ($msg           )   { Alert->new($msg)->raise }


=head3  Infix expression constraints

C<:where> values parameters simplify the specification of constraints that
require an argument to be a specific value or type, but many constraints involve
operations other than some form of identity, equality, or matching. For example:

    multi alert   ($msg :where({ $msg ne "" })) {...}

    multi factorial ($n :where({ $n > 0 })    ) {...}

    multi add_ID   ($ID :where({ $ID !~ /X\w{4}\d{6}/ })) {...}

    multimethod set_range($from, $to :where({ $to > $from })    ) {...}

    multimethod debug ($obj :where({ $obj->DOES('Debugging') }) ) {...}

As all those examples illustrate, these expressions frequently involve the
parameter variable as the left operand. In such cases, Multi::Dispatch allows
you to simplify and de-noise the entire parameter specification by appending
the operator and right operand directly after the declaration of the
parameter itself:

    multi alert ($msg ne "") {...}

    multi factorial ($n > 0) {...}

    multi add_ID ($ID !~ /X\w{4}\d{6}/) {...}

    multimethod set_range($from, $to > $from) {...}

    multimethod debug ($obj -> DOES('Debugging')) {...}

The constraint expression can be as complex as you wish:

    multi factorial ($n > 0 && $n < 200) {...}

    multimethod set_range($from, $to > $from > 0) {...}

Note, however, that in these kinds of constraints, the parameter being declared
must be the leftmost element of the constraining expression. For example, you
can't declare the constrained C<$to> parameter of C<set_range()> like so:

    # Not a valid parameter declaration here (attempts to redeclare $from)
    multimethod set_range($from, $from < $to) {...}

Generally, it's better to confine such inlined constraints to
single simple arithmetic or string operators:

    multi factorial ($n == 0) { 1 }
    multi factorial ($n >  0) { $n * factorial($n-1) }
    multi factorial ($n <  0) { die "Can't take the factorial of a negative number" }

    multi alert ($msg eq "") {}
    multi alert ($msg ne "") { Alert->new($msg)->raise }

More complicated constraints are usually easier to detect and understand
within the code if they're visually quarantined in a C<:where> attribute:

    multimethod set_range($from, $to :where({0 < $from < $to})) {...}

    multimethod debug ($obj :where({$obj->DOES('Debugging')})) {...}


=head3  Literal value parameters

C<:where> attributes and inline constraint expressions allow any computable
constraint to be applied to any parameter of any variant. But even simple
inlined constraints aren't always as clean or as readable as we might wish.
Especially when the constraint is testing whether an argument is a particular value.
There's still a lot of visual noise in declarations such as:

    multi factorial ($n == 0)    { 1 }

    multi alert ($msg eq "")     {}
    multi alert ($msg ~~ undef)  {}

    multimethod add_client ($data, $ID =~ /X\w{4}\d{6}/) {
        die "Can't add an X ID";
    }

Observe too that in each of these cases, the actual value of the parameter
variable is not used within the body of the variant. So you might infer that
you could shorten each declaration (and also ensure that the parameter is not
"accidentally" used) by declaring the parameter as anonymous:

    multi factorial ($ == 0)    { 1 }

    multi alert ($ == "")     {}
    multi alert ($ == undef)  {}

    multimethod add_client ($data, $ =~ /X\w{4}\d{6}/) {
        die "Can't add an X ID";
    }

Unfortunately that doesn't work, because the constraints are no longer valid
Perl code. Or, perhaps we should say: B<fortunately> that doesn't work,
because the constraints are no longer valid Perl code, and much less readable.

But the idea of dispensing with the parameter variable and just checking whether
an argument matches a particular value is still worthwhile. So Multi::Dispatch
allows that too...by permitting any parameter of a variant to be defined by specifying
I<only> the value that the corresponding argument it must match (rather than specifying
a variable into which that argument must be placed). For example:

    multi factorial (0)  { 1 }    # Argument must == 0

    multi alert ("")     {}       # Argument must eq ""
    multi alert (undef)  {}       # Argument must == undef

                                  # Argument must =~ pattern
    multimethod add_client ($data, /X\w{4}\d{6}/) {
        die "Can't add an X ID";
    }

If a variant is specified with a literal string or number, or an C<undef>,
or a regex at a point where a parameter is expected, then that specification
is treated as an anonymous parameter, with the value being treated as if it
were a smart-matched C<:where> constraint.

The effect is very like the "parameter pattern matching"
syntax provided in languages such as Raku, Haskell, or Mathematica:

    # Perl (with Multi::Dispatch)...
    multi factorial (0)  { 1 }
    multi factorial ($n) { $n * factorial($n-1) }

    # Raku...
    multi factorial (0)  { 1 }
    multi factorial ($n) { $n * factorial($n-1) }

    -- Haskell...
    factorial :: (Integral a) => a -> a
    factorial 0 = 1
    factorial n = n * factorial (n-1)

    (* Mathematica... *)
    factorial[0]  := 1
    factorial[n_] := n * factorial[n-1]


=head3  Multiple constraints on a parameter

The three general forms of parameter constraint (prefix types, inline
expressions, and postfix C<:where> attributes) are I<not> mutually exclusive.
You can apply any two – or even all three – of them to a single parameter.

For example, the Bernoulli numbers have an interesting property that
computing I<B(n)> for integer values of I<n> is generally
an expensive and complex operation for even values of I<n>, but is trivial
(i.e. always zero) for odd values of I<n> greater than two.
You could implement that as:

    multi B( Int $N > 2 :where($N % 2) )  { 0 }
    multi B( Int $N                    )  { compute_B_of_even($N) }

You can also combine literal parameter constraints with types constraints
and/or C<:where> attributes, though there are admittedly fewer cases
where it is useful to do so. For example:

    multimethod set_ID (StrongPassword 'qwerty123') {
        die "You're kidding, right?"
    }

Note that, when a parameter specifies two or more kinds of constraints, those
constraints are tested left-to-right. That is: type constraints are tested
before inlined literal or expression constraints, which are in turn tested before
a C<:where> attribute.


=head2  Parameter destructuring

So far, we have seen that Multi::Dispatch can differentiate variants,
and select between them, based on the number of parameters and any
specified constraints on their values. But the module can also
distinguish between variants based on the I<structure> of their
parameters. And, in the process, extract relevant elements of those
those structures automatically.

This facility is available for parameters that expect an array reference,
or a hash reference (as those are the kinds of arguments in Perl that
can actually have some non-trivial structure).


=head3  Array destructuring

Consider a multisub that expects a single argument that is an array reference,
and responds according to the number and value of arguments in that array:

    multi handle(ARRAY $event) {
        my $cmd = $event->[0];
        if (@{$event} == 2 && $cmd eq 'delete') {
            my $ID = $event->[1];
            _delete_ID($ID);
        }
        elsif (@{$event} == 3 && $cmd eq 'insert') {
            my ($data, $ID) = $event->@[1,2];
            _insert_ID($ID, $data);
        }
        elsif (@{$event} >= 2 && $cmd eq 'report') {
            my ($ID, $fh) = $event->@[1,2];
            print {$fh // *STDOUT} _get_ID($ID);
        }
        elsif (@{$event} == 0) {
            die "Empty event array";
        }
        else {
            die "Unknown command: $cmd";
        }
    }

This code uses a single multisub with a signature, to ensure that it receives
the correct kind of argument. But then it unpacks the contents of that argument
"manually", and determines what action to take by explicitly deciphering the
structure of the argument in a cascaded S<C<if>-C<elsif>> sequence...all in that
single variant.

Avoiding that kind of all-in-one hand-coded infrastructure is the entire
reason for having multiple dispatch, so it won't come as much of a surprise
that Multi::Dispatch offers a much cleaner way of achieving the same goal:

    multi handle( ['delete',        $ID]       ) { _delete_ID($ID)             }
    multi handle( ['insert', $data, $ID]       ) { _insert_ID($ID, $data)      }
    multi handle( ['report', $ID, $fh=*STDOUT] ) { print {$fh} _get_ID($ID)    }
    multi handle( [ ]                          ) { die "Empty event array"     }
    multi handle( [$cmd, @]                    ) { die "Unknown command: $cmd" }

Instead of specifying the single argument as a scalar that must be an array
reference, each variant in this version of the multisub specifies that single
argument as an anonymous array (i.e. as an actual array reference), with zero or
more B<I<subparameters>> inside it. These subparameters are then matched (for
number, type, value, etc.) against each of the elements of the arrayref in the
corresponding argument, in just the same way that regular parameters are matched
against a regular argument list.

If the contents of the argument arrayref match the specified subparameters,
the argument as a whole is considered to have matched the parameter as a whole,
and so the variant may be selected.

Thus, in the preceding example:

=over

=item *

If the single arrayref argument contains exactly two elements,
the first of which is the string C<'delete'>, then the first variant
will be selected.

=item *

If the arrayref contains exactly three elements, the first being the string
C<'insert'>, then the second variant will be selected.

=item *

If the arrayref contains either two or three elements, the first being the string
C<'report'>, then the third variant will be selected.

=item *

If the arrayref contains no elements, then the fourth variant will be selected.

=item *

If the arrayref contains at least one element, but any number of extras (which
are permitted because they will be assigned to the anonymous slurpy array
subparameter), then the fifth variant will be selected.

=back

In other words, destructured array parameters allow you to "draw a picture"
of what an arrayref parameter should look like internally, and have the multisub
or multimethod work out whether the actual arrayref argument has a compatible
internal structure.

Subparameters may be specified with all the features of regular parameters:
named vs anonymous, copied vs aliased, required vs optional vs slurpy
I<(as in the previous example)>, prefix types, infix expression constraints,
literal value constraints I<(as in the previous example)>, or postfix C<:where>
constraints. Subparameters can even be specified as nested destructures, if you
happen to need to distinguish variants to that degree of structural detail.

For example, if the C<$ID> subparameter of the first three C<handle()> variants
has to conform to a particular pattern, and the C<$data> subparameter must
a nested hashref (which it would be more convenient to alias, than to copy)
and the filehandle argument of the third variant must actually be a filehandle,
you could add those constraints to the relevant subparameters:

    multi handle( ['delete',         $ID :where(/^X\d{6}$/)] )        {...}
    #                                    ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑

    multi handle( ['insert', \%data, $ID :where(/^X\d{6}$/)] )        {...}
    #                        ↑↑↑↑↑↑      ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑

    multi handle( ['report', $ID =~ /^X\d{6}$/, GLOB $fh = *STDOUT] ) {...}
    #                            ↑↑↑↑↑↑↑↑↑↑↑↑↑  ↑↑↑↑

All these variants still expect a single arrayref as their argument, but now the
contents of that arrayref must conform to the various constraints specified on
the corresponding subparameters.

Array destructuring is particularly useful in pure functional programming.
For example, here's a very clean implementation of mergesorting, with no
explicit control structures whatsoever:

    multi merge ( [@x],     []             )  { @x }
    multi merge ( [],       [@y]           )  { @y }
    multi merge ( [$x, @x], [$y <= $x, @y] )  { $y, merge [$x, @x], \@y }
    multi merge ( [$x, @x], [$y >  $x, @y] )  { $x, merge \@x, [$y, @y] }

    multi mergesort (@list <= 1) { @list }
    multi mergesort (@list >  1) {
        merge
            [ mergesort @list[      0..@list/2-1] ],
            [ mergesort @list[@list/2..$#list]    ]
    }


=head3  Hash destructuring

Arrayref destructuring is extremely powerful, but the ability to specify
destructured hashref parameters is even more useful.

For example, passing complex datasets around in tuples is generally considered a
bad idea, because positional look-ups (C<< $event->[2] >>, C<< $client->[17] >>)
are considerably more error-prone than named look-ups
(C<< $event->{ID} >>, C<< $client->{overdraft_limit} >>)

So it's actually quite unlikely that the C<handle()> multisub used as an
example in the previous section would pass in each event as an arrayref. It's
much more likely that an experienced programmer would structure events as
hashrefs instead:

    multi handle(HASH $event) {
        if ($event->{cmd} eq 'delete') {
            _delete_ID($event->{ID});
        }
        elsif ($event->{cmd} eq 'insert') {
            _insert_ID($event->@{'ID', 'data'});
        }
        elsif ($event->{cmd} eq 'report') {
            print {$event->{fh} // *STDOUT} _get_ID($event->{ID});
        }
        elsif (exists $event->{cmd}) {
            die "Unknown command: $event->{cmd}";
        }
        else {
            die "Not a valid event";
        }
    }

While this is a arguably little cleaner than the array-based version,
and certainly a lot safer I<(are you B<sure> all the array indexes
were correct in the array-based version???)>, it still suffers from
the "all-in-one-cascade" problem.

Fortunately, Multi::Dispatch can also destructure hashref parameters,
allowing them to be specified as destructuring anonymous hashes:

    multi handle( { cmd=>'delete', ID=>$ID }                    ) {...}
    multi handle( { cmd=>'insert', ID=>$ID, data=>$data }       ) {...}
    multi handle( { cmd=>'report', ID=>$ID, fh=>$fh = *STDOUT } ) {...}
    multi handle( { }                                           ) {...}
    multi handle( { cmd=>$cmd, % }                              ) {...}

Within a destructuring hash, each subparameter is specified as a
S<B<I<key>>C<< => >>B<I<value>>> pair, with the keys specifying the
keys to be expected within the corresponding hashref argument,
and the values specifying the subparameter variables into which
the corresponding values from the hashref argument will be assigned.

Unlike destructuring arrays, the order in which subparameters are
specified in a destructuring hash doesn't matter. Each entry from
the hashref argument is matched to the corresponding subparameter
by its key.

Another important difference is that, if you want to specify a
destructuring hash that can match a hashref argument with extra
keys, you need to specify a named or anonymous slurpy hash
as the final subparameter I<(as in the final variant in the
preceding example)>. Without a trailing slurpy subparameter,
a destructuring hash will only match a hashref argument that
has exactly the same set of keys as the destructuring hash itself.

As with destructuring array parameters, the subparameters of
destructuring hashes can take advantage of all the features
of regular parameters (required/optional, copy/alias, constraints, etc.).
So, this version of the C<handle()> multisub could still impose
all the additional constraints that were previously required:

    multi handle( {cmd => 'delete', ID => $ID =~ /^X\d{6}$/} )
    {...}

    multi handle( {cmd => 'insert', ID => $ID =~ /^X\d{6}$/, data => \%data} )
    {...}

    multi handle( { cmd => 'report',
                    ID  => $ID =~ /^X\d{6}$/,
                    fh  => GLOB $fh = *STDOUT
                  } )
    {...}

As a second example, consider the common way of cleanly passing named
optional arguments to a subroutine: bundling them into a single hash reference:

    my @sorted = mysort({foldcase=>1}, @unsorted);

    my @sorted = mysort({reverse=>1, unique=>1}, @unsorted);

    my @sorted = mysort({key => sub { /\d+$/ ? $& : Inf }}, @unsorted);

The subroutine then pulls these options out of the corresponding C<$opts>
parameter by name:

    sub mysort ($opts, @data) {
        if ($opts->{uniq}) {
            @data = uniq @data;
        }

        if ($opts->{key}) {
            if ($opts->{fold}) {
                @data = map { [$_, fc $opts->{key}->($_)] } @data;
            }
            else {
                @data = map { [$_,    $opts->{key}->($_)] } @data;
            }
            if ((ArrayRef[Tuple[Num,Any]])->check(\@data)) {
                @data = sort { $a->[1] <=> $b->[1] } @data;
            }
            else {
                @data = sort { $a->[1] cmp $b->[1] } @data;
            }
            @data = map { $_->[0] } @data;
        }
        elsif ((ArrayRef[Num])->check(\@data)) {
            @data = sort { $a <=> $b } @data;
        }
        elsif ($opts->{fold}) {
            @data = sort { fc $a cmp fc $b } @data;
        }
        else {
            @data = sort @data;
        }
        if ($opts->{rev}) {
            return reverse @data;
        }
        else {
            return @data;
        }
    }

Passing named options in a hashref is certainly a useful API technique, but with
multiple dispatch – and especially with hash destructuring – the code can be
much cleaner...and entirely declarative:

    multi rank (Tuple[Num,Any] @data) { map {$_->[0]} sort {$a->[1] <=> $b->[1]} @data }
    multi rank (      ArrayRef @data) { map {$_->[0]} sort {$a->[1] cmp $b->[1]} @data }
    multi rank (           Num @data) {               sort {$a      <=> $b     } @data }
    multi rank (               @data) {               sort                       @data }

    multi mysort ({fold=>1, key=>$k, %opt}, @data)
                                           { mysort {%opt, key=>sub{fc $k->($_)}}, @data }
    multi mysort ({fold=>1,  %opt}, @data) { mysort {%opt, key => \&CORE::fc}, @data }
    multi mysort ({uniq=>1,  %opt}, @data) { mysort \%opt, uniq @data }
    multi mysort ({ rev=>1,  %opt}, @data) { reverse mysort \%opt, @data }
    multi mysort ({ key=>$k, %opt}, @data) { rank map {[$_, $k->($_)]} @data }
    multi mysort ({          %opt}, @data) { rank @data }

Notice that each variant only handles one particular option (or combination of
options), and hence requires no conditional tests whatsoever within its code.
Each variant simply destructures the initial hashref argument to pick out the
relevant option(s), and then uses those option(s) to implement each phase of the
overall sorting process by:

=over

=item *

adding case-folding to the key extractor if both
the C<'fold'> and C<'key'> options are specified (variant 1),

=item *

using case-folding I<as> the key extractor
if only the C<'fold'> option is specified (variant 2),

=item *

preprocessing the data with the C<uniq()> function
if the C<'uniq'> option is specified (variant 3)

=item *

postprocessing the sorted data with C<reverse()>
if the C<'rev'> option is specified (variant 4)

=item *

extracting keys and sorting by them in a Schwartzian transform
if the C<'key'> option is specified (variant 5)

=item *

doing a simple sort otherwise (variant 6)

=back

Meanwhile the various variants of the C<rank()> multisub ensure that the correct
type of sorting (numeric or stringific, Schwartzian or direct) is applied each time.


=head4  DRY hash subparameters

The only real annoyance in using destructuring hashes instead of arrays is the
frequent necessity to type each subparameter name twice: once for the key and
once for the associated subparameter variable.

Of course, this is not strictly necessary: as long as the key names match
the argument's keys, the associated subparameter variables can be named
anything you prefer:

    multi handle( {cmd => 'insert', ID => $new_ID, data => \%new_record} )
    {...}

    multi handle( {cmd => 'report', ID => $snorkel, fh => $Albuquerque = *STDOUT} )
    {...}

But, more often than not, the key name is also the most sensible name for
the subparameter variable, which means the code frequently has to repeat itself:

    multi handle( {cmd => 'insert', ID => $ID, data => \%data} )
    {...}       #                   ↑↑.....↑↑  ↑↑↑↑......↑↑↑↑

    multi handle( {cmd => 'report', ID => $ID, fh => $fh = *STDOUT} )
    {...}       #                   ↑↑.....↑↑  ↑↑.....↑↑

To make hash destructures less tedious, less error-prone, and more DRY,
the key of any named subparameter can simply be omitted entirely, in which
case the missing key is inferred from the name of the associated variable.
Thus, the above examples could be rewritten as:

    multi handle( {cmd => 'insert',  => $ID,  => \%data} )
    {...}       #                    ↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑↑

    multi handle( {cmd => 'report',  => $ID,  => $fh = *STDOUT} )
    {...}       #                    ↑↑↑↑↑↑   ↑↑↑↑↑↑

Note that the "fat commas" (now prefix operators) are still required...
to clearly indicate that the missing keys were I<intentionally> omitted
and that the module is being explicitly requested to figure them out.


=head3  Slurpy hash destructuring

Passing named arguments in a hashref is a convenient technique,
but it can also be useful to be able to pass named arguments
directly:

    EventLoop->add(ID => $ID, cmd => $action, data => $info);

This can, of course, be accomplished with a standard Perl subroutine
signature:

    sub add ($classname, %args) {...}

...or an Object::Pad method:

    method add :common (%args) {...}

...but neither solution actually checks that the correct keys
(and I<only> those keys) were passed in, nor does any other
kind of type- or constraint-checking.

You could, of course, use a destructuring hashref parameter:

    multimethod add :common ( {ID => Num $ID, cmd => Str $c, data => \%d, %etc} )
    {...}

...but now the user has to bundle the named arguments in a hashref when they are
passed to the method.

To avoid this, Multi::Dispatch allows an I<implicit> destructuring hash to be
declared, simply by omitting the curly brackets around an explicit destructuring hash.
That is, if the preceding example were rewritten as:

    multimethod add :common ( ID => Num $ID, cmd => Str $c, data => \%d, %etc )
    {...}

...it's the equivalent of specifying an anonymous slurpy hash parameter:

    multimethod add :common (%) {...}

...except that the contents of that anonymous slurpy hash are also
destructured into the various subparameters.

That is, the named arguments passed to the multimethod must match the keys of
the destructure, and must be present (unless the corresponding subparameter
is optional). The values for each key must satisfy any constraints on the
subparameter as well. No named argument whose key is not in the destructure
specification may be passed...unless the destructure ends with a slurpy
hash parameter.

Note that, because this slurpy destructuring syntax is equivalent to
a single explicit slurpy parameter, it can only be declared at the end
of a parameter list (i.e. after any required or optional unnamed positional
parameters). Furthermore, if one or more named parameters are declared, they can
only be followed by a(n optional) slurpy hash parameter, I<not> a slurpy array
parameter.


=head2  Permuted parameter lists

One of the principle uses of multisubs and multimethods is to implement
interactions or operations between two or more objects or values.
The classic example used throughout the multiply dispatched world
is the 70s arcade game: I<Asteroids>. In that game, things can collide
with each other, and the result is determined by the nature of the
things that are colliding.

That interaction couldl be implemented via multiple dispatch, like so:

    multi collide (Asteroid $a,                     $obj )  { $a->split,      $obj->explode  }
    multi collide (         $obj,            Asteroid $a )  { $a->split,      $obj->explode  }

    multi collide (Ship     $s->shielded,           $obj )  { $s->bounce,     $obj->bounce   }
    multi collide (         $obj,      Ship $s->shielded )  { $s->bounce,     $obj->bounce   }

    multi collide (Ship     $s->shielded,    Missile  $m )  { $s->bounce,     $m->explode    }
    multi collide (Missile  $m,        Ship $s->shielded )  { $s->bounce,     $m->explode    }

    multi collide (Asteroid $a1,            Asteroid $a2 )  { $a1->split,     $a2->split     }

    multi collide (         $obj1,                 $obj2 )  { $obj1->explode, $obj2->explode }

Note that all the collisions between different kinds of objects
require two variants...to cover the possibility that the objects
will be passed in either order. This is a common occurrence when
using multisubs or multimethods to implement interactions, so the
module provides a shortcut to simplify specifying multis where the
required arguments can be specified in any order: the C<:permute>
attribute. For example, we could create the same set of variants
as in the preceding example with just:

    multi collide :permute (Asteroid $a,                  $obj )  { $a->split,  $obj->explode  }
    multi collide :permute (Ship     $s->shielded,        $obj )  { $s->bounce, $obj->bounce   }
    multi collide :permute (Ship     $s->shielded, Missile  $m )  { $s->bounce, $m->explode    }

    multi collide (Asteroid $a1,            Asteroid $a2 )  { $a1->split,     $a2->split     }
    multi collide (         $obj1,                 $obj2 )  { $obj1->explode, $obj2->explode }

Adding the C<:permute> attribute to a multisub or multimethod declaration
causes that declaration to create multiple variants in which all the required
arguments are permuted in every possible way...just like in the earlier example,
where all the variants were explicity declared.

For the two required arguments in the preceding example, that means each
C<:permute> declaration produces two variants. If a C<:permute> multi
declaration has three required arguments, then you get six variants. Et cetera.

Each permutation changes the order of the required parameters, but not their
names, types, constraints, or any destructuring they may have. Every permutation
has exactly the same body too.

Note that the order in which the permutations of a variant are created
is not predictable, and should not be relied upon, except that it is
guaranteed that the signature of the first permutation generated
will always be identical to the permuted variant's actual declaration.


=head2  Variant constraints

In addition to specifying constraints on the individual parameters
of a variant, you can also place constraints directly on the entire
variant itself, by adding a C<:where> attribute between the variant's
name and its parameter list.

For example, you might want to specify two different behaviours for
a multimethod, depending on whether a particular field is set:

    field $verbose :param;

    multimethod report :where({$verbose})  ($msg) {...}
    multimethod report                     ($msg) {...}

Now, when you call:

    $obj->report($msg);

...the variant selected depends on whether or not the particular object's
C<$verbose> field is true.

Or you could specify a particular variant to be selected only
the first time a given multisub is called:

    my $called;
    multi report :where({!$called++})  ()  { say 'first'     }
    multi report                       ()  { say 'not first' }

Note that all of the above examples of variant constraints are block-based. In
fact, variant constraints can I<only> be specified as a code block (or a
subroutine reference). Unlike parameter constraints, you can't specify a number,
string, regex, or type...because a variant itself has no value against which
that number, string, regex, or type could be compared.


=head3  Context constraints

Yet another use of variant constraints is to select different variants
to invoke in different call contexts:

    #         ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
    multi now :where({not defined wantarray})  () { say scalar localtime    }
    multi now :where({not         wantarray})  () { return time             }
    multi now :where({            wantarray})  () { return scalar localtime }

In fact, this is sufficiently useful that the module provides a shorthand
for it:

    #         ↓↓↓↓↓↓↓↓↓↓↓↓↓↓
    multi now :where(VOID)    () { say scalar localtime    }
    multi now :where(SCALAR)  () { return time             }
    multi now :where(LIST)    () { return scalar localtime }

You can also specify "not C<VOID>", "not C<SCALAR>", and "not C<LIST>",
by prefixing the special keywords with C<NON>, like so:

    # Only print out report in void context...
    multi report :where(   VOID)  () { say $report }
    multi report :where(NONVOID)  () { return $report }

    # Only return raw time() in scalar context, otherwise the pretty version...
    multi now :where(   SCALAR)  () { return time }
    multi now :where(NONSCALAR)  () { return scalar localtime }

    # Only allow this multisub to be called in list context...
    multi get_data :where(   LIST)  () { return @data }
    multi get_data :where(NONLIST)  () { die "get_data() not in list context" }


=head3  C<:before> variants and variant redispatch

There is one other kind of constraint (or, rather, I<anti>-constraint)
that can be applied to an entire variant: it can be promoted to
a higher priority in the dispatch process.

Normally, variants are examined from most- to least-specific
signatures. That is: variants with more constraints, more
destructuring, more required parameters, etc. are tried
before variants with fewer of these properties, in a particular
ordering described in L<"How variants are selected for dispatch">.

But it is also possible to mark one (or more) variants as being
pre-eminent, as coming before all the others in the dispatch process.
To do this, you simply mark the variant with a C<:before> attribute.
Every variant specified with a C<:before> attribute is tried before
any variant without that attribute.

The C<:before> variant is also useful for optimizing the performance
of variants whose only real task is to convert one or more arguments
to make them compatible with existing variants. For example, suppose
you had a multisub whose variants all expected a temperature value,
expressed in Celsius:

    multi set_temp(Celsius $temp < -273.15  ) {...}
    multi set_temp(Celsius $temp < 0        ) {...}
    multi set_temp(Celsius $temp > 100      ) {...}
    multi set_temp(Celsius $temp            ) {...}

...and you now also wanted to handle temperatures specified in Fahrenheit
or Kelvin. You could achieve that by adding eight more variants
(four each for the two new temperature scales), or you could achieve
it by adding just two generic "adaptor" variants:

    multi set_temp(Fahrenheit $temp) {
        set_temp( Celsius->new(($temp - 32) / 1.8) );
    }

    multi set_temp(Kelvin $temp) {
        set_temp( Kelvin->new($temp - 273.15) );
    }

However, this solution requires two entire dispatch processes: first
dispatching the original call to select the appropriate Fahrenheit
or Kelvin variant, and second to independently dispatch the nested call
to select the appropriate Celsius variant.

You could halve the cost of that by placing the two "adaptor" variants
at the start of the original dispatch process by marking them with
C<:before>:

    multi set_temp :before (Fahrenheit $temp) {...}
    multi set_temp :before (Kelvin     $temp) {...}

You would then have each new variant resume the dispatch process of
the original call, moving on down the list of variants to consider the (now
lower precedence) original variants for dispatch instead.

This is known as B<I<redispatching>> a multisub (or multimethod)
and is achieved under Multi::Dispatch by calling the special
C<next::variant> function. Like so:

    multi set_temp :before (Fahrenheit $temp) {
        next::variant( Celsius->new(($temp - 32) / 1.8) );
    }

    multi set_temp :before (Kelvin $temp) {
        next::variant( Celsius->new($temp - 273.15) );
    }

Effectively, any call to C<next::variant()> from within a multisub
or multimethod means: I<"Forget that the original call was dispatched
to this variant. Go back to the dispatching process and keep looking
for another (less specific) variant to dispatch to instead.">

Just like any other Perl subroutine, C<next::variant> can be called
in five ways (each with slightly different effect):

=over

=item C<next::variant( @ARGLIST )>

This form finds the next suitable variant in the original dispatch search
and calls it with the given arguments. In other words: it resumes the
original dispatch process, but now with a different argument list.
When the redispatched call completes, control returns to the
current variant, with the return value of the redispatched call
being returned as the value of the C<next::variant()> call.

=item C<next::variant @ARGLIST>

This form does exactly the same thing.

=item C<&next::variant(@ARGLIST)>

This variant does exactly the same thing too.
Technically, it also circumvents the multisub's prototype,
but this is unimportant, because multisubs don't have prototypes.

=item C<&next::variant>

This form finds the next variant in the original dispatch search
and calls it with the original argument list that was passed
to the current variant. Once again, after the redispatched call,
control (and any return value) returns to the current variant.

=item C<goto &next::variant>

This form finds the next variant in the original dispatch search
and calls it with the given arguments. However, control B<never>
returns to the current variant; instead the call I<replaces>
the current variant on the call stack. (See L<perlfunc/goto>)

=back


=head4  Debugging via C<:before> variants

C<:before> variants also make it possible to inject a "catch-all" variant at the
start of the dispatch process. This is particularly useful for debugging. If you
have an existing class (say, Value) with multimethods you need to track,
you could derive a new class (say, Value::Tracked) and insert a "tracking variant"
of each multimethod, like so:

    class Value::Tracked :isa(Value) {

        # Tracking variant...
        multimethod get_value :before (@args) {
            say "Calling get_value(@args)...";
            my $return_value = &next::variant;

            say "get_value(@args) returned: $return_value";
            return $return_value;
        }

        ...
    }

As usual, the Value::Tracked class will inherit all the C<get_value()>
variants that were defined in the Value class. Then the derived class adds a
generic C<get_value(@args)> variant. Normally that variant, with its highly
non-specific single slurpy parameter, would be considered very late in the
dispatch process and so would likely never be called at all.

However, because the variant is specified with a C<:before> attribute,
it is promoted up the dispatch list, ahead of every variant without
such an attribute. Therefore, despite being very generic, the new
C<get_value()> variant will be selected first, and is able to report
the call and its result.

Note that it's critically important in situations like these to preserve
the actual inherited behaviour(s) of the multimethod. However, the C<:before>
variant doesn't actually attempt to replicate the behaviour of the existing
inherited variants. Instead it simply redispatches the call directly I<to>
those other variants, using the C<next::variant> feature.

In fact, in this instance, it's I<essential> that it use C<next::variant>,
rather than recursively calling C<get_value()> explicitly:

    multimethod get_value :before (@arglist) {
        say "Calling get_value(@arglist)...";
        my $return_value = $self->get_value(@arglist);   # <–– DON'T DO THIS!!!

        say "get_value(@arglist) returned: $return_value";
        return $return_value;
    }

Because the parameter list of the C<:before> variant is so high-priority and also
so general, that variant will I<always> be selected at the start of any call,
so if that variant calls the same multimethod recursively, the nested call will
start back at the C<:before> variant again, select it again, and recurse again...forever.

But if the C<:before> variant redispatches using C<next::variant>, the multimethod
will step back into to the previous dispatch process (which had already selected
the C<:before> variant)...and will simply continue onwards to find the next most
suitable variant instead.

Whenever you encounter a situation where a recursive call within a
variant seems needed, consider whether you could use C<next::variant>
instead. Most of the time, you probably can, and will improve the
robustness and efficiency of you code if you do.

For example, in L<"Hash destructuring"> we saw how a powerful sorting
function could be implemented cleanly using multisubs:

    multi mysort ({fold=>1, key=>$k, %opt}, @data)
                                           { mysort {%opt, key=>sub{fc $k->($_)}}, @data }
    multi mysort ({fold=>1,  %opt}, @data) { mysort {%opt, key => \&CORE::fc}, @data }
    multi mysort ({uniq=>1,  %opt}, @data) { mysort \%opt, uniq @data }
    multi mysort ({ rev=>1,  %opt}, @data) { reverse mysort \%opt, @data }
    multi mysort ({ key=>$k, %opt}, @data) { rank map {[$_, $k->($_)]} @data }
    multi mysort ({          %opt}, @data) { rank @data }

But this code can be significantly optimized by noting that every recursive call
to C<mysort()> within any of the variants can actually only select one of the variants
following it...because each variant effectively removes the named option(s) that
caused it to be selected from the C<%opt> hash before recursing.

This strict ordering of the variants means you can eliminate all the expensive
recursion by replacing each nested call to C<mysort()> with a C<next::variant>
redispatch instead:

    multi mysort ({fold=>1, key=>$k, %opt}, @data)
                                           { next::variant {%opt, key=>sub{fc $k->($_)}}, @data }
    multi mysort ({fold=>1,  %opt}, @data) { next::variant {%opt, key => \&CORE::fc}, @data }
    multi mysort ({uniq=>1,  %opt}, @data) { next::variant \%opt, uniq @data }
    multi mysort ({ rev=>1,  %opt}, @data) { reverse next::variant \%opt, @data }
    multi mysort ({ key=>$k, %opt}, @data) { rank map {[$_, $k->($_)]} @data }
    multi mysort ({          %opt}, @data) { rank @data }

Each call to C<mysort()> now only invokes a single subroutine, which works its
way progressively through the appropriate variants, without ever reconsidering
or re-invoking variants that have already been invoked (or rejected).

Note, however, that in general C<next::variant> B<I<doesn't>> mean:
I<"Go to the next variant declared below this one">.
It means: I<"Go to next variant in the intrinsic I<most-specific-first>
order in which variants are always considered from dispatch">.
The following section explains that intrinsic order more fully.


=head2  How variants are selected for dispatch

The goal of defining a multisub or multimethod is to provide a range of
distinct and specific behaviours that are invoked in response to distinct
and specific lists of arguments...without having to explicitly code
endless tests within a subroutine to determine which particular behaviour
should be selected for a given argument list.

The goal is to have the most appropriate and most relevant behaviour (i.e. variant)
automatically selected each time a given multisub or multimethod is called,
and to have that selection made as quickly and efficiently as possible.

Unfortunately, I<"appropriate"> and I<"relevant"> are extremely nebulous terms,
which have been interpreted and realized differently in almost every
programming language or language-extension module that supports multiple dispatch.

This particular language-extension module aims to provide a reasonable and
predictable interpretation of I<appropriate> and I<relevant>; one that incorporates
the best features of many of those other implementations, while imposing
as little runtime overhead as possible on individual multisub and multimethod calls.

To this end, Multi::Dispatch defines a static strict total ordering on the variants
of a given multisub or multimethod, and then sorts those variants into that order
at compile-time. The ordering is I<static> because it can be determined entirely
from compile-time information; the ordering is I<strict> because the precedence
of any two variants is never ambiguous, undefined, or "equal"; and the ordering
is I<total> because every possible pair of variants can be strictly compared.

Then, when it is actually invoked with an argument list, each multisub or
multimethod simply steps through its ordered list of variants, considering each in turn,
until it finds one that can successfully handle that argument list (i.e. the
first variant whose arity matches the number of arguments and whose parameter
constraints are satisfied by each argument).

The first such successful variant is then immediately called, without considering any
others later in the variant list. Because later variants are, I<ipso facto>, inherently
less I<appropriate> or I<relevant>.

To ensure that the earlier variants in the list are indeed the most
I<appropriate> and I<relevant> ones, the variants are sorted (at compile-time)
according to the following nine successive criteria I<(yeah, I know, that sounds
horribly complicated and not at all "intuitive", but it's actually as easy as
A-B-C...D-E-F-G-H-I):>

=over

=item I<B<A>rity>

If a multisub or multimethod is called with I<N> arguments,
only its variants that define sufficient parameters to
contain all I<N> arguments are ever considered for dispatch.

That is, the only variants that are considered are those
that define at least I<N> scalar parameters, plus those
that define fewer than I<N> scalar parameters plus a slurpy parameter.

Similarly, only those variants that define no more than
I<N> required parameters are considered.

For example:

    foo(1,2);

    multi foo ($i)             {...}  # Excluded   (too few params)
    multi foo ($i, $j)         {...}  # Considered (correct number of params)
    multi foo ($i, $j, $k)     {...}  # Excluded   (too many required params)
    multi foo ($i, $j, $k = 0) {...}  # Considered (can accept 2 args)
    multi foo ($i, @etc)       {...}  # Considered (can accept 2 args)
    multi foo ($i, $j, @etc)   {...}  # Considered (can accept 2 args)
    multi foo ($i, %etc)       {...}  # Excluded   (cannot accept 2 args)
    multi foo (%etc)           {...}  # Considered (can accept 2 args)


=item I<B<B>eforeness>

If two or more variants all have the correct arity, the variants with a
C<:before> attribute will be considered for dispatch before any variant
without a C<:before>.


=item I<B<C>onstraint>

If two or more variants all have the same C<:before> status,
the variant with a greatest total number of constraints will be considered
for dispatch before any variants with fewer constraints. For example:

    multi foo ($x)           {...}  # Tried third (no constraints)
    multi foo (Int $x < 10)  {...}  # Tried first (two constraints)
    multi foo ($x :where(0)) {...}  # Tried second (one constraint)


If two or more variants all have a type constraint on the same parameter,
the variant with the more restrictively typed parameter will be considered
for dispatch first. For example:

    multi foo (Value $x) {...}    # Tried third
    multi foo (Int   $x) {...}    # Tried first
    multi foo (Num   $x) {...}    # Tried second

...because C<Int> is a tighter constraint on argument values than C<Num>,
which in turn is a tighter constraint than C<Value>.

Likewise, type constraints that specify class membership
are ordered most-derived-first. For example:

    multi foo (Animal::         $x) {...}    # Tried third
    multi foo (Animal::Primate  $x) {...}    # Tried first
    multi foo (Animal::Mammal   $x) {...}    # Tried second

...because C<Animal::Primate> I<isa> C<Animal::Mammal>
and C<Animal::Mammal> I<isa> C<Animal>.


=item I<B<D>estructuring>

If two or more variants have the same degree of constraint,
the variant with a greatest total number of destructuring parameters
will be considered for dispatch before any variants with fewer destructures.
For example:

    multi foo ($x,    {=>$name}) {...}  # Tried second (one destructure)
    multi foo ([$x0], {=>$name}) {...}  # Tried first  (two destructures)
    multi foo ($x,    $y       ) {...}  # Tried third  (no destructures)


=item I<B<E>ssentials>

If two or more variants define the same number of destructuring parameters,
the variant with a greatest number of required (i.e. essential) parameters
will be considered for dispatch before any variants with fewer required parameters.

In other words, a variant with a given number of required parameters
will be considered for dispatch before a variant with
the same number of parameters where some of them are optional.

For example:

    multi foo ($x,     $y = 1) {...}  # Tried second (one required param)
    multi foo ($x,     $y    ) {...}  # Tried first  (two required params)
    multi foo ($x = 0, $y = 1) {...}  # Tried third  (no required params)


=item I<B<F>acultativity>

I<(Facultativity: n. The state of being optional)>

If two or more variants have the same number of required parameters, the variant
with the B<fewest> optional parameters will be considered for dispatch before any
variant with a greater number of optional parameters (because a variant that has
fewer optional parameters can be considered to be I<more specific> in its requirements).

For example:

    multi foo ($x, $y = 1        ) {...}  # Tried second (one optional param)
    multi foo ($x                ) {...}  # Tried first  (no optional params)
    multi foo ($x, $y = 1, $z = 2) {...}  # Tried third  (two optional params)


=item I<B<G>reed>

If two or more variants have the same number of optional parameters, the
variants B<without> slurpy parameters will be considered for dispatch before any
variants with slurpy parameters (again, because being able to accept an argument
list of any length is inherently I<less specific> than being restricted to a
fixed number of arguments).

Alternatively, you can think of a single slurpy parameter as being equivalent
to an infinite number of optional parameters, so variants with a slurpy array or
hash are always considered I<after> variants without a slurpy, regardless of the
actual number of optional scalar parameters each has.

For example:

    multi foo ($x, @etc ) {...}  # Tried second (one slurpy param)
    multi foo ($x       ) {...}  # Tried first  (no slurpy param)


=item I<B<H>eredity>

If two or more variants of a multimethod have the same number of slurpy parameters,
then any multimethod variant that was defined in a derived class will be considered
for dispatch ahead of any variant defined in one of its base classes.

In other words, the complete set of variants defined directly in a given class
are always considered ahead of any variants that have been inherited from some
base class in its hierarchy.

Note that this sorting criterion does not apply to the variants of multisubs,
even if they are defined within related classes (because multisubs are not methods,
so multisub variants are never inherited).


=item I<B<I>nception>

If two or more variants cannot be distinguished by I<any> of the preceding
criteria, then they are considered for dispatch in the order they came into
being (i.e. the order in which they were declared).

Note that every possible set of variants is strictly linearly ordered
by this final criterion, so no further sorting criteria are required.

=back


=head2  Debugging multiply dispatched calls

When you have numerous variants of a multisub or multimethod all vying for the
same call dispatch, it may not always be obvious why one particular variant was
selected for a given argument list. Especially with multimethods, where inherited
variants may sometimes be chosen in preference to in-class variants.

Moreover, sometimes B<no> variant at all can be selected, and it won't
always be obvious why. To assist in debugging unexpected or unsuccessful
dispatches, Multi::Dispatch offers three flags that provide more information.

Normally, when a dispatch fails, the module throws an exception that
succinctly reports that failure:

    No suitable variant for call to multi handle()
    with arguments: ({ cmd => "del", data => undef, key => "acct1" })
    at demo.pl line 18

However, if the module was loaded with the C<-verbose> flag specified:

    use Multi::Dispatch -verbose;

...then a more detailed explanation of which variants were considered,
and why they were rejected, is printed to STDERR:

    No suitable variant for call to multi handle()
    with arguments: ({ cmd => "del", data => undef, key => "acct1" })
    at demo.pl line 18
        B1: main::handle (\@args)
            defined at demo.pl line 14
            --> 1st argument was not a array reference,
                so it could not be aliased to parameter \@args
        C2: main::handle (ARRAY $argref != undef)
            defined at demo.pl line 13
            --> 1st argument did not satisfy constraint on
                parameter $argref: ARRAY and $argref != undef
        D1: main::handle ({cmd=>'set', key=>$key, data=>$data})
            defined at demo.pl line 10
            --> Incorrect number of entries in hashref argument 0:
                expected exactly 3 entries
        D1: main::handle ({cmd=>'del', key=>$key})
            defined at demo.pl line 11
            --> Required key (->{'key'}) not found in hashref argument $ARG[0]
        E3: main::handle ($x, $y, $z)
            defined at demo.pl line 16
            --> SKIPPED: need at least 3 args but found only 1
        F2: main::handle (\@args = [], $opt = undef)
            defined at demo.pl line 15
            --> 1st argument was not a array reference,
                so it could not be aliased to parameter \@args

The two-character prefix on each report indicates why the variant was considered
at that point in the overall dispatch process. The letters correspond to the
I<A-to-I> precedence categories of variants (see L<"How variants are selected for dispatch">),
and the number indicates the degree of precedence within each category.

Hence, in the preceding example, the B<B1> prefix indicates that the first
variant considered was a C<:before> variant, which is why it was tried
before the variant with 2 constraints (B<C2>), which in turn was tried ahead
of the two variants with a single destructuring parameter (B<D1>),
then the variant with exactly three required parameters (B<E3>),
and finally the I<"fuzzy"> variant with two optional parameters (B<F2>).

The C<-verbose> option only affects the reporting of failed dispatches; successful
dispatches remain silent. But if a "successful" dispatch doesn't do what you wanted,
that's a bug of some kind I<(even if it's just a bug in your understanding)>,
so the module also allows you to investigate how any particular successful
dispatch decided which variant to actually call.

If the module is loaded with the C<-debug> flag:

    use Multi::Dispatch -debug;

...then the entire dispatch process of every multisub or multimethod call
(successful or not) is reported to STDERR.

For example, a successful dispatch of the C<handle()> multisub might report:

    Dispatching call to handle({ cmd => "del", key => "acct2" })
    at demo.pl line 19
        B1: main::handle (\@args)
            defined at demo.pl line 14
            --> 1st argument was not a array reference,
                so it could not be aliased to parameter \@args
        C2: main::handle (ARRAY $argref != undef )
            defined at demo.pl line 13
            --> 1st argument did not satisfy constraint on parameter $argref:
                also still and $argref != undef
        D1: main::handle ({cmd=>'set', key=>$key, data=>$data})
            defined at demo.pl line 10
            --> Incorrect number of entries in hashref argument 0:
                expected exactly 3 entries
        D1: main::handle ({cmd=>'del', key=>$key })
            defined at demo.pl line 11
            ==> SUCCEEDED

...indicating that three higher-precedence variants were considered and rejected,
before the fourth variant was selected.

Note that the report format under C<-debug> is exactly the same as under
C<-verbose>, and that failed dispatches are also still reported in full.

If you are only interested in checking the order in which variants would be
dispatched, load the module with the C<-annotate> option. This causes the module
to output (at compile-time, and to STDERR) a list of warnings indicating the
order in which each variant would be tested during dispatch. For example,
under the C<-annotate> flag, you might get:

    1st (B1) at demo/demo_dd.pl line 12
    9th (E2) at demo/demo_dd.pl line 15
    5th (C1) at demo/demo_dd.pl line 16
    6th (C1) at demo/demo_dd.pl line 17
    10th (E1) at demo/demo_dd.pl line 20
    7th (C1) at demo/demo_dd.pl line 21
    3rd (C1) at demo/demo_dd.pl line 22
    4th (C1) at demo/demo_dd.pl line 25
    2nd (C2) at demo/demo_dd.pl line 26
    8th (C1) at demo/demo_dd.pl line 29

This indicates the order of the ten variants of the C<dd> multisub
within the demo/demo_dd.pl file. A suitable editor or environment
(such as Vim with the ALE plugin) would be able to actually annotate
each of these source lines, indicating the ordering right at the
variant declarations. For example:

    # Create a mini Data::Dumper clone that outputs in void context...
    multi dd :before :where(VOID) (@data)  { say &next::variant }                       # 1st (B1)

    # Format pairs and array/hash references...
    multi dd ($k, $v)  { dd($k) . ' => ' . dd($v) }                                     # 9th (E2)
    multi dd (\@data)  { '[' . join(', ', map {dd($_)}                 @data) . ']' }   # 5th (C1)
    multi dd (\%data)  { '{' . join(', ', map {dd($_, $data{$_})} keys %data) . '}' }   # 6th (C1)

    # Format strings, numbers, regexen...
    multi dd ($data)                             { '"' . quotemeta($data) . '"' }       # 10th (E1)
    multi dd ($data :where(\&looks_like_number)) { $data }   # 7th (C1)
    multi dd ($data :where(Regexp))              { 'qr{' . $data . '}' }                # 3rd (C1)

    # Format objects...
    multi dd (Object $data)               { '<' .ref($data).' object>' }                # 4th (C1)
    multi dd (Object $data -> can('dd'))  { $data->dd(); }                              # 2nd (C2)

    # Format typeglobs...
    multi dd (GLOB $data)                { "" . *$data }                                # 8th (C1)

Note that the ordering also reports I<why> the variant is in that position in
the dispatch sequence, by reporting its I<A-to-I> precedence category and score.

All three of these debugging flags are lexical in scope. That is, they only
apply to multisubs and multimethods defined in the lexical scope where they were
specified.


=head2  Object::Pad integration

When creating multimethods, Multi::Dispatch will detect if the Object::Pad
module is active at the point a multimethod variant is declared. If it is,
the overall multimethod dispatcher, as well as every individual variant of
the multimethod, will be implemented as an Object::Pad C<method>. This
means that Multi::Dispatch multimethods have access to any fields or other
methods declared in an Object::Pad-based class.

In all other respects, multimethods are the same as in non-Object::Pad classes,
especially with respect to inheritance.

Eventually, it is hoped that Multi::Dispatch will be similarly aware
of the new builtin class mechanism currently being added to Perl.


=head2  Exporting a multisub to another module

Internally, a multisub is implemented as a regular subroutine,
so it may be exported from a module in the same way as any other
subroutine (e.g. via one of the many C<Exporter> modules,
or by direct typeglob assignment inside an C<import()> method)

For example:

    package FooSource;
    use Multi::Dispatch;

    multi foo ($x)     { say 1 }
    multi foo ($x, $y) { say 2 }

    use Exporter 'import';
    our @EXPORT = 'foo';

However, if your code first defines one or more variants of a multisub
and I<only then> imports the same multisub from a module:

    use Multi::Dispatch;

    multi foo ($x, $y, $z) { say 3 }   # First define a multisub

    use FooSource;                     # Then import a multisub of the same name

...then the imported C<foo()> multisub will B<overwrite> the locally defined
C<foo()> multisub (or, technically, the imported sub-implementing-your-C<foo()>-multisub
will overwrite the locally defined sub-implementing-your-C<foo()>-multisub).
When this happens you will get a I<"Subroutine main::foo redefined at..."> warning.

This outcome is inevitable, because C<Multi::Dispatch> has no control over the
behaviour of the module's export mechanism, so it can't intercept and correct
the subroutine definition.

To avoid this issue, import C<FooSource>'s C<foo()> multisub B<before> declaring
any extra local variants:

    use Multi::Dispatch;

    use FooSource;                     # First import the multisub

    multi foo ($x, $y, $z) { say 3 }   # Then define another variant of the same name

This works because the following C<multi> declaration can detect the previously imported
multisub and will avoid redeclaring the handler sub.

For other approaches, which I<do> allow you to import multisub variants after
having declared local variants, see the following two sections.


=head2  Importing multisub variants from another module

Unlike multimethods, a given multisub normally consists of only those variants
that have been declared in the same package. Variants with the same name,
but which were declared in a different package are B<never> considered during
the dispatch process, even when a particular multisub is called outside its
own package.

However, it is also possible to pre-import multisub variants from other namespaces
and still have them included in the list of dispatch candidates for a particular
multisub. This is accomplished via the C<:from> attribute.

If you declare a multisub I<without> a code block, but with a C<:from>
attribute, that declaration will import all the variants from the nominated
package into the corresponding multisub in the current package. For example, to
add all the variants of the C<Logger::debug()> multisub to the candidate list of
C<MyModule::debug()> multisub:

    package MyModule;

    multi debug :from(Logger);

There is no requirement that a local variant of the C<debug()> multisub has
already be defined when the C<:from> declaration is made, so this mechanism also
provides a way of simply importing a multisub from another package, without
extending it in any way (even if that module doesn't explicitly export the multisub).

You can import other variants from as many other packages as you wish, by adding
further C<:from> declarations within the current package, as well as adding
extra variants explicitly (either before or after the imports):

    multi debug ($level, $msg) { warn $msg if $level >= $THRESHOLD }

    multi debug :from( Debugger::Remote       );
    multi debug :from( Console::Reporter::DBX );
    multi debug :from( Term::Debug            );

    multi debug (@msg)         { warn @msg }

In the preceding examples, the imported variants are imported from multisubs
of the same name (i.e. C<debug>) from the specified packages. However, you can
also import variants from a I<differently named> multisub, by specifying the
different name of that multisub explicitly (with a leading C<&> to indicate
that it's a multisub name, not a package name). Like so:

    multi debug :from( &Debugger::Remote::rdebug    );
    multi debug :from( &Console::Reporter::DBX::dbx );
    multi debug :from( &Term::Debug::show           );

Note that all these variants of the C<rdebug()>, C<dbx()>, and C<show()> multimethods
are imported as local variants of the C<debug()> multisub, despite their different original names.

Each C<:from> declaration will attempt to C<require> the specified package, but
will not C<use> it. If a particular module (for example: C<Console::Reporter::DBX>)
needs to be loaded with specific arguments in order to work correctly,
then you must do that explicitly, prior to the C<:from> declaration:

    use Console::Reporter::DBX (output => \*STDERR, level => 'warn');

    multi debug :from( &Console::Reporter::DBX::dbx );


=head2  Exporting multisub variants to another module

In addition to importing multisub variants from a module,
you can also export a multisub and its variants from a module,
by using another declarative syntax within the C<import()>
of the module. Like so:

    sub import {
        ...
        multi dd :export;   # Export this module's dd multis at this point
        ...
    }

    # Then later...

    multi dd (ARRAY  $a) {...}
    multi dd (HASH   $h) {...}
    multi dd (Regexp $r) {...}
    multi dd (Num    $n) {...}
    # et cetera...

That is, if you declare a multisub with a name and the C<:export> attribute,
but with no code block, then all the variants of correspondingly named multisub
from the current module will be exported to the caller's namespace at that point.

Note that this kind of declarative C<:export> request B<must> be attached to
an "empty" multi declaration inside the body of the C<import()> subroutine,
I<not> on any of the actual variants declared within the module.

Declarative exports of the type do not suffer from the overriding issues and
order limitations that were discussed in L<"Exporting a multisub to another module">.


=head1  DIAGNOSTICS

=over

=item C<< Isolated variant of multi(method) <NAME> >>

The module detected two variant declarations belonging to the same multisub
or multimethod, separated by a non-trivial amount of unrelated code.

Multisubs and multimethods distribute their behaviour across multiple variants.
If those variants are spread at random through the code, they are
often much harder to understand, to predict, or to debug.

To disable this warning, either collect all the variants together in one
location within the package, or else turn off the warning explicitly:

    no warnings 'Multi::Dispatch::noncontiguous';

I<(And, yes that's deliberately ponderous...in order to discourage its use. ;-)>


=item C<< A slurpy parameter (<NAME>) may not have a default value: <DEFAULT> >>

Slurpy parameters are inherently optional, and indicate the absence of
corresponding arguments simply by remaining empty. So it is not
necessary – or possible – to specify a default value for them.
Just as with regular Perl slurpy parameters.

I<(Providing a default mechanism for slurpies was considered and even
prototyped, but in testing it was found that that permitting a list of default
values to be specified for a slurpy within the context of the surrounding
parameter list led to frequent syntax errors because of list flattening. Note,
however, that if a more robust solution can be found, this prohibition may
eventually be revoked.)>

Meanwhile, it's easy enough to test for an empty slurpy and to populate it with
default values if necessary:

    multi mysort(@list) {
        @list = @DEFAULTS if !@list;
        ...
    }

=item C<< Can't redispatch via next::variant >>

Your code requested some form of redispatch using the C<next::variant> mechanism,
but that code was not within a multisub or multimethod, which is the only place
C<next::variant> is available (or makes sense).

Either remove the call to C<next::variant>, or convert it to something that will
work correctly: perhaps C<next::method>, or a named subroutine or method call.
Alternatively, convert your subroutine/method into a multisub/multimethod.


=item C<< Can't specify a required parameter (<NAME>) after an optional or slurpy parameter >>

Required parameters must be defined at the start of a parameter list,
before any optional or slurpy parameter.

Move the parameter to the left of the first such optional.
Alternatively, was this supposed to be an optional parameter,
but you forget the C<=> and default value?


=item C<< Can't parameterize a Perl class (<NAME>) in a type constraint >>

Only Type::Tiny named types can be parameterized (e.g. C<ArrayRef[Int]>)
as part of of type constraint. You attempted to append square brackets
to something that was not recognized as a Type::Tiny type.

Did you misspell the type name?


=item C<< Can't specify return type (<NAME>) on code parameter <NAME> >>

There is no way to detect the return type of a Perl subroutine.
Code parameters are always bound to subroutines, so there is no point in
trying to specify the return type of a code parameter, as that return type
could never be tested.

Simply remove the type specifier associated with the parameter.


=item C<< Could not load type <TYPENAME> >>

You specified a Type::Tiny-style typename as a parameter constraint,
but the specified type could not be loaded.

Did you forget to C<use Types::Standard>, or some other type-defining module?
Or did you forget to specify which types the module should export?
Types::Standard and its ilk don't export any types by default.
So perhaps you need: C<use Types::Standard ':all'>

Alternatively, were you attempting to use a simple classname that doesn't have a
C<::> in it? If so, add a C<::> to either the beginning or end of the classname.


=item C<< <TYPENAME> constraint is ambiguous (did you mean <TYPENAME>:: instead?) >>

You specified a valid Type::Tiny typename as a parameter constraint,
but the type's name is also the name of a defined class, which means
it's possible you might have wanted the class instead of the type.

If you wanted the class, add a C<::> before or after the constraint name.

If you wanted the type, but don't want the warning, either rename the class
or else specify C<no warnings 'ambiguous';> before the declaration.


=item C<< Default value for parameter <NAME> cannot include a 'return' statement >>

Although C<return> expressions are permitted in regular Perl subroutine signatures,
they are not permitted in multisubs and multimethods, because they interfere with the
internal variant-selection process.

Instead of a short-circuited return from within the parameter list:

    method name ($newname = return $name) {
        $name = $newname;
    }

...just specify the appropriate variants directly:

    multimethod name ()         { return $name;     }
    multimethod name ($newname) { $name = $newname; }


=item C<< Incomprehensible constraint: <CONSTRAINT> >>

You specified a C<:where(...)> constraint that could not be
recognized as a value, a regular expression, a code block,
a subroutine reference, or a typename.

Did you misspell the constraint?


=item C<< Invalid declaration of multi(method) >>

The module detected that something wasn't right with your declaration.
It will do its best to indicate what and where the unacceptable syntax occurred.


=item C<< Invalid multi(method) constraint: <CONSTRAINT> >>

A C<:where(...)> constraint that's applied to an entire multisub or multimethod
can only be a code block, a subroutine reference, or a context specifier.
You can't use a literal value or regex or typename or classname as a constraint
for an entire multisub or multimethod variant, because the variant as a whole
has no value against which that literal, regex, typename, or classname
could be compared.

Reconsider what you meant by comparing the entire variant against a literal value,
and reformulate that goal as a block of code instead.


=item C<< Can't declare a multi and a multimethod of the same name in a single package >>

Like regular Perl subs and methods, multisubs and multimethods are both just
subroutine references stored in the local symbol table. This means you can't
have both a multisub and a multimethod of the same name in the same package,
because they would both require a dispatching subroutine of that name...and
there can be only one subroutine of a given name per package.

To avoid this compile-time error, change the name of either the multisub or the
multimethod to something unique in the namespace.


=item C<< Subroutine <NAME> redefined as multi(method) <NAME> >>

You already had a regular Perl subroutine of the specified name defined within
the current package (or possibly imported into the current package from some
other module). This warning is reminding you that defining a multisub or a multimethod
of that same name causes the pre-existing regular subroutine to be replaced by the
dispatcher subroutine for the multisub/multimethod. You probably didn't want that.

To avoid this compile-time warning, change the name of either the
pre-existing regular subroutine, or of the new multisub/multimethod.

Or, if you really do want to replace the pre-existing subroutine with a
multisub or multimethod of the name name, you can silence the warning
with a: C<no warnings 'redefine';>


=item C<< Multi(method) <NAME> [imported from <PACKAGE>] redefined as multi(method) <NAME> >>

There was already a multisub or multimethod of the specified name installed in the
current package, which must have been imported from some other package using the
standard Perl module export mechanism. Variants defined in the current package won't
be added to the variants of a regularly imported multisub or multimethod. Instead,
they will I<replace> that imported multisub or multimethod entirely. This compile-time
warning is reminding you about that.

If you did intend to I<replace> the imported multisub or multimethod,
you can silence this warning with a: C<no warnings 'redefine';>

If you intended to I<extend> the imported multisub or multimethod,
you'll have to import it with the module's own multiple-dispatch-aware
import mechanism instead. (See L<"Importing variants from another module">).

If you I<didn't> intend to either replace or extend the imported
multisub or multimethod, maybe just choose another name for the one
you are now defining.


=item C<< Can't import variants for multimethod <NAME> via a :from attribute >>

The C<:from> import mechanism (see: L<"Importing variants from another module">)
will only import variants for a multisub, not a multimethod.

If you need extra multimethod variants from some other class or role,
inherit from the class, or compose in the role.


=item C<< No suitable variant for call to multi(method) <NAME> >>

You called the named multi(method) with a particular list of arguments,
but none of the multi(method)'s variants could be bound successfully
to those arguments.

This probably indicates that you're missing at least one variant,
which could handle that particular set of arguments. Or else, the
set of arguments itself was a mistake.

To get more detail on why none of the variants matched,
add the C<-verbose> option to your S<C<use Multi::Dispatch>> statement.
See L<"Debugging multiply dispatched calls">.


=item C<< Slurpy parameter <NAME> can't be given a string, an undef, or a regex as a constraint >>

Slurpy parameters can be assigned multiple arguments,
so the meaning of smartmatching a single-valued C<:where> constraint
against the contents of a slurpy array or hash is inherently ambiguous.
It could mean any of the following:

=over

=item *

I<Match if B<every> element in the slurpy matches the single value>;

=item *

I<Match if B<at least one> element in the slurpy matches the single value>;

=item *

I<Match the scalar value (i.e. the count) of the slurpy against the single value>;

=item *

I<Match the string-concatenation of the slurpy against the single value>.

=back

If you want the literal value or regex constraint to be tested for every element,
use the following alternatives I<(each of which makes use of the C<all()> function
from L<List::MoreUtils>)>:

    # Instead of...                     Use...
    @slurpy :where(42)          ––––>   @slurpy :where({all {$_ == 42 }      @slurpy})

    @slurpy :where('string')    ––––>   @slurpy :where({all {$_ eq 'string'} @slurpy})

    @slurpy :where(undef)       ––––>   @slurpy :where({all {!defined}       @slurpy})

    @slurpy :where(/regexp?/)   ––––>   @slurpy :where({all {/regexp?/}      @slurpy})

Or you could specify your constraint as a specialized Types::Standard type
I<(because prefix types are automatically applied to every value in a slurpy)>:

    # Instead of...                     Use...
    @slurpy :where('string')    ––––>   Enum['string'] @slurpy

    @slurpy :where(undef)       ––––>   Undef @slurpy

    @slurpy :where(/regexp?/)   ––––>   StrMatch[qr/regexp?/] @slurpy


If you want one of the other three possible interpretations,
just write the appropriate C<:where> block instead:

    # Instead of...               Use one of these...
    @slurpy :where(42)    ––––>   @slurpy :where({ grep {$_ == 42} @slurpy})
                          ––––>   @slurpy :where({ @slurpy  == 42}         )
                          ––––>   @slurpy :where({"@slurpy" eq 42}         )


=item C<< The multi <NAME> can't be given a :common attribute >>

The C<:common> attribute is only meaningful for multimethods
(it gives them an automatic C<$class> variable and makes them
callable on classes as well as on individual objects).

Either change the C<multi> keyword to C<multimethod>,
or else delete the attribute.


=item C<< Internal error <DESCRIPTION>  >>

Well that certainly shouldn't have happened!

Congratulations, you found a lurking bug in the module itself.
Please consider reporting it, so it can be fixed.

=back


=head1  CONFIGURATION AND ENVIRONMENT

None. The module requires no configuration files or environment variables.


=head1  DEPENDENCIES

This module only works under Perl v5.22 and later.

The module requires the CPAN modules L<Data::Dump>, L<Keyword::Simple>,
L<Algorithm::FastPermute>, and L<PPR>.

If L<Type::Tiny> types are used within the signature of a multi or multimethod,
then the actual module (L<Types::Standard>, L<Types::Common::Numeric>,
L<Types::Common::String>, I<etc.>) that provides the types must also be loaded
within the scope of that declaration.

The L<Object::Pad> module is I<not> required, but Multi::Dispatch will make use of it,
provided it has been loaded at the point where a particular multimethod is declared.


=head1  INCOMPATIBILITIES

None reported.

However, this module parses multi and multimethod code blocks
using PPR, so if you are using other modules that add keywords to Perl,
those keywords are unlikely to be usable within such code blocks.

The one exception to this general rule is the Object::Pad
module, whose extended keyword syntax Multi::Dispatch knows about
and handles correctly.


=head1  LIMITATIONS

Multimethod variants cannot at present be composed in from an Object::Pad C<role>.
There is currently no satisfactory workaround for this.


=head1  BUGS

No bugs have been reported.

Please report any bugs or feature requests to
S<C<bug-multi-dispatch@rt.cpan.org>>, or through the web interface at
L<http://rt.cpan.org>.


=head1  ACKNOWLEDGEMENTS

My sincere thanks to Curtis "Ovid" Poe, for asking a simple question
that, at the time, had no good answer. I hope you find this answer
at least reasonable, Ovid.

My deepest appreciation to:

=over

=item *

Paul Evans, for his extraordinary work on Object::Pad and the new Perl OO mechanism

=item *

Toby Inkster, for the remarkable Type::Tiny ecosystem

=item *

Lukas Mai, for the invaluable Keyword::Simple module

=back

My profound gratitude to Larry Wall, and everyone else in the Raku development team,
for creating something so wonderful...and so eminently worth stealing from. :-)


=head1  AUTHOR

Damian Conway  C<< <DCONWAY@CPAN.org> >>


=head1  LICENCE AND COPYRIGHT

Copyright (c) 2022, Damian Conway C<< <DCONWAY@CPAN.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1  DISCLAIMER OF WARRANTY

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
