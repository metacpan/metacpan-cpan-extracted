#!/usr/bin/perl

package MooseX::Compile::Compiler;
use base qw(MooseX::Compile::Base);

use strict;
use warnings;

use Data::Dump qw(dump);
use Data::Visitor::Callback;
use Storable;
use B;
use B::Deparse;
use PadWalker;
use Class::Inspector;

our %compiled_classes;

use constant DEBUG => MooseX::Compile::Base::DEBUG();

# FIXME make this Moose based eventually
sub new {
    my ( $class, %args ) = @_;
    bless \%args, $class;
}

sub compile_class {
    my ( $self, %args ) = @_;
    my $class = $args{class};

    ( my $short_name = "$class.pm" ) =~ s{::}{/}g;
    $args{short_name} = $short_name;

    unless ( defined $args{file} ) {
        $args{file} = $INC{$short_name};
    }

    unless ( defined $args{pmc_file} ) {
        $args{pmc_file} = "$args{file}c";
    }

    if ( $compiled_classes{$class}++ ) {
        warn "already compiled class '$class'\n" if DEBUG;
        return;
    }

    my $t = times;

    $self->cache_meta(%args);
    $self->write_pmc_file(%args);

    warn "compilation of .pmc and .mopc for class '$class' took " . ( times - $t ) . "s\n" if DEBUG;
}

# FIXME these should really be methods, I suppose

sub sym ($$;@) {
    my ( $sym, $type, @args ) = @_;
    bless { @args, name => $sym }, "MooseX::Compile::mangled::$type";
}

sub package_name ($;$) {
    my ( $code, $cv ) = @_;
    $cv ||= B::svref_2object($code);
    local $@;
    return eval { $cv->GV->STASH->NAME };
}

sub code_name ($;$) {
    my ( $code, $cv ) = @_;
    $cv ||= B::svref_2object($code);
    local $@;
    return eval { join("::", package_name($code, $cv), $cv->GV->NAME) };
}

sub verified_code_name ($;$) {
    my ( $code, $cv ) = @_;

    if ( my $name = code_name($code, $cv) ) {
        if ( verify_code_name($code, $name) ) {
            return $name;
        }
    }

    return;
}

sub verify_code_name ($$) {
    my ( $code, $name ) = @_;

    no strict 'refs';
    \&$name == $code;
}

sub subref ($;$) {
    my ( $code, $name ) = @_;

    if ( ref $code ) {
        my $cv = B::svref_2object($code);
        $name ||= code_name($code, $cv);
        if ( $name && verify_code_name($code,$name) ) {
            my @args;
            if ( -f ( my $file = $cv->FILE ) ) {
                my %rev_inc = reverse %INC;
                push @args, file => $rev_inc{$file} if $rev_inc{$file} !~ /^(?:Moose|metaclass)\.pm$/;
            }
            return sym( $name, "subref", @args );
        } else {
            warn "$code has name '$name', but it doesn't point back to the cv" if $name;
            require Data::Dumper;
            no strict 'refs';
            local $Data::Dumper::Deparse = 1;
            warn Data::Dumper::Dumper({
                name => $name,
                name_strval => ("". \&$name),
                name_ref => \&$name,
                arg_ref => $code,
                arg_strval => "$code",
            });
            die "Can't make a symbolic ref to $code, it has no name or the name is invalid";
        }
    } else {
        return sym($code, "subref");
    }
}

sub create_visitor {
    my ( $self, %args ) = @_;
    my $class = $args{class};

    Data::Visitor::Callback->new(
        "object" => sub {
            my ( $self, $obj ) = @_;

            return $obj if $obj->isa("Moose::Meta::TypeConstraint");

            $self->visit_ref($obj);
        },
        object_final => sub {
            my ( $self, $obj ) = @_;

            if ( ref($obj) =~ /^Class::MOP::Class::__ANON__::/x ) {
                die "Instance of anonymous class cannot be thawed: $obj";
            }

            return $obj;
        },
        "Class::MOP::Class" => sub {
            my ( $self, $meta ) = @_;

            if ( $meta->is_immutable ) {
                my $options = $meta->immutable_transformer->options;
                bless( $meta, $meta->{___original_class} ), # it's a copy, we can rebless
                return bless {
                    class      => $meta,
                    options    => $options,
                }, "MooseX::Compile::mangled::immutable_metaclass";
            }
            
            if ( $meta->is_anon_class ){
                warn "Can't reliably store anonymouse metaclasses yet";
            }

            return $meta;
        },
        "Moose::Meta::TypeConstraint" => sub {
            my ( $self, $constraint ) = @_;

            if ( defined ( my $name = $constraint->name ) ) {
                return sym $name, "constraint";
            } else {
                warn "Anonymous constraint $constraint left in metaclass";
                return $constraint;
            }
        },
        code => sub {
            my ( $self, $code ) = @_;

            if ( my $subname = code_name($code) ) {
                if ( $subname =~ /^Moose::Meta::Method::\w+::(.*)$/ ) {
                    # FIXME should this be verified more closely?
                    # sometimes the coderef $code doesn't match \&{ $class::$1 }
                    return subref "${class}::$1";
                } elsif ( $subname =~ /^(?:Moose|metaclass)::([^:]+)$/ ) {
                    my $method = $1;

                    if ( $method eq 'meta' ) {
                        return subref "${class}::meta";
                    } else {
                        die "subname: $subname";
                    }
                } elsif ( $subname !~ /__ANON__$/ ) {
                    return subref $code, $subname;
                } else {
                    warn "Unable to locate symbol for $code ($subname) found in $class";
                    use B::Deparse;
                    warn B::Deparse->new->coderef2text($code);
                    return $code;
                }
            }

            return $code;
        },
    );
}

sub deflate_meta {
    my ( $self, %args ) = @_;
    my $meta = $args{meta};
    
    my $visitor = $self->create_visitor(%args);
    
    $visitor->visit($meta);
}

sub cache_meta {
    my ( $self, %args ) = @_;
    my $class = $args{class};

    my $meta = $self->deflate_meta( %args, meta => $class->meta  );
    $self->store_meta( %args, meta => $meta );
}

sub store_meta {
    my ( $self, %args ) = @_;
    my $meta = $args{meta};

    my $mopc_file = $self->cached_meta_file(%args);
    $mopc_file->dir->mkpath;

    local $@;
    eval { Storable::nstore( $meta, $mopc_file ) };

    if ( $@ ) {
        require YAML;
        no warnings 'once';
        $YAML::UseCode = 1;
        die join("\n", $@, YAML::Dump($meta) );
    }
    
    if ( DEBUG ) {
        warn "stored $meta in '$mopc_file'\n";
    }

    return 1;
}

sub method_category_filters {
    my ( $self, %args ) = @_;

    return (
        # FIXME recognize aliased methods
        sub {
            my ( $self, $entry ) = @_;
            no warnings 'uninitialized';
            return "meta" if $entry->{name} eq 'meta' and package_name($entry->{body}) =~ /^(?: Moose | metaclass )/x,
        },
        sub {
            my ( $self, $entry ) = @_;
            return "generated" if $entry->{meta}->isa("Class::MOP::Method::Generated");
        },
        sub {
            my ( $self, $entry ) = @_;
            return "file" if B::svref_2object($entry->{body})->FILE eq $args{file};
        },
        sub { "unknown_methods" },
    );
}

sub function_category_filters {
    my ( $self, %args ) = @_;
    
    return (
        # FIXME check for Moose exports, too (Scalar::Util stuff, etc)
        sub {
            my ( $self, $entry ) = @_;
            no warnings 'uninitialized';
            return "moose_sugar" if package_name($entry->{body}) eq 'Moose';
        },
        sub { "unknown_functions" },
    );
}

sub extract_code_symbols {
    my ( $self, %args ) = @_;
    my $class = $args{class};

    my %seen;
    my %categorized_symbols;

    {
        my @method_filters = $self->method_category_filters(%args);
        my $method_map = $class->meta->get_method_map;

        foreach my $name ( sort keys %$method_map ) {
            $seen{$name}++;

            my $method = $method_map->{$name};
            my $body = $method->body;

            my $entry = { name => $name, meta => $method, body => $body };

            foreach my $filter ( @method_filters ) {
                if ( my $category = $self->$filter($entry) ) {
                    push @{ $categorized_symbols{$category} ||= [] }, $entry;
                    last;
                }
            }
        }
    }

    {
        my %symbols; @symbols{@{ Class::Inspector->functions($class) || [] }} = @{ Class::Inspector->function_refs($class) || [] };

        my @function_filters = $self->function_category_filters(%args);

        foreach my $name ( sort grep { not $seen{$_}++ } keys %symbols ) {
            my $body = $symbols{$name};
            my $entry = { name => $name, body => $body };

            foreach my $filter ( @function_filters ) {
                if ( my $category = $self->$filter($entry) ) {
                    push @{ $categorized_symbols{$category} ||= [] }, $entry;
                    last;
                }
            }
        }
    }

    return %categorized_symbols;
}

sub compile_code_symbols {
    my ( $self, %args ) = @_;

    my $symbols = $args{all_symbols};

    my @ret;

    foreach my $category ( @{ $args{'symbol_categories'} } ) {
        my $method = "compile_${category}_code_symbols";
        push @ret, $self->$method( %args, symbols => delete($symbols->{$category}) );
    }

    @ret;
}

sub compile_file_code_symbols {
    # this is already taken care of by the inclusion of the whole .pm after the preamble
    return;
}

sub compile_meta_code_symbols {
    # we fake this one 
    return;
}

sub compile_moose_exports_code_symbols {
    # not yet implemented
    return;
}

sub compile_moose_sugar_code_symbols {
    my ( $self, %args ) = @_;
    return map {
        my $name = $_->{name};
        my $proto = prototype($_->{body});
        $proto = $proto ? " ($proto)" : "";
        "*$name = Sub::Name::subname('Moose::$name', sub$proto { });";
    } @{ $args{symbols} || [] };
}


sub compile_generated_code_symbols {
    my ( $self, %args ) = @_;
    map { sprintf "*%s = %s;", $_->name => $self->compile_method(%args, method => $_) } map { $_->{meta} } @{ $args{symbols} };
}

sub compile_aliased_code_symbols {
    return;
}

sub compile_unknown_method_code_symbols {
    return;
}

sub compile_unknown_function_code_symbols {
    return;
}

sub compile_method {
    my ( $self, %args ) = @_;
    my ( $class, $method ) = @args{qw(class method)};

    my $d = B::Deparse->new;

    my $body = $method->body;

    my $body_str = $d->coderef2text($body);

    my $closure_vars = PadWalker::closed_over($body);

    my @env;

    if ( my $constraints = delete $closure_vars->{'@type_constraints'} ) {
        my @constraint_code = map {
            my $name = $_->name;

            defined $name
                ? "Moose::Util::TypeConstraints::find_type_constraint(". dump($name) .")"
                : "die 'missing constraint'"
        } @$constraints;
        
        push @env, "CORE::require Moose::Util::TypeConstraints::OptimizedConstraints", join("\n    ", 'my @type_constraints = (', map { "$_," } @constraint_code ) . "\n)",
    }
    
    push @env, map {
        my $ref = $closure_vars->{$_};

        my $scalar = ref($ref) eq 'SCALAR' || ref($ref) eq 'REF';

        "my $_ = " . ( $scalar
            ? $self->_value_to_perl($$ref)
            : "(" . join(", ", map { $self->_value_to_perl($_) } @$ref ) . ")" )
    } keys %$closure_vars;

    my $name = code_name($body);
    my $quoted_name = dump($name);

    if ( @env ) {
        my $env = join(";\n\n", @env);
        $env =~ s/^/    /gm;
        return "Sub::Name::subname( $quoted_name, do {\n$env;\n\n\nsub $body_str\n})";
    } else {
        return "Sub::Name::subname( $quoted_name, sub $body_str )";
    }
}

sub _value_to_perl {
    my ( $self, $value ) = @_;

    ( (ref($value)||'') eq 'CODE'
        ? $self->_subref_to_perl($value)
        : Data::Dump::dump($value) ) 
}

sub _subref_to_perl {
    my ( $self, $subref ) = @_;

    my %rev_inc = reverse %INC;

    if ( ( my $name = code_name($subref) ) !~ /__ANON__$/ ) {
        if ( -f ( my $file = B::svref_2object($subref)->FILE ) ) {
            return "do { require " . dump($rev_inc{$file}) . "; \\&$name }";
        } else {
            return '\&' . $name;
        }
    } else {
        "sub " . B::Deparse->new->coderef2text($subref);
    }
}

sub write_pmc_file {
    my ( $self, %args ) = @_;

    my ( $class, $short_name, $file, $pmc_file ) = @args{qw(class short_name file pmc_file)};

    $pmc_file->dir->mkpath;

    open my $pm_fh, "<", $file or die "open($file): $!";
    open my $pmc_fh, ">", "$pmc_file" or die "Can't write .pmc, open($pmc_file): $!";

    local $/;

    my $pm = <$pm_fh>;

    close $pm_fh;

    print $pmc_fh "$1\n\n" if $pm =~ /^(\#\!.*)/; # copy shebang

    print $pmc_fh $self->pmc_preamble( %args ), "\n";

    print $pmc_fh "# verbatim copy of $file follows\n";
    print $pmc_fh "# line 1\n";

    print $pmc_fh $pm;

    close $pmc_fh or die "Can't write .pmc, close($pmc_file): $!";

    warn "wrote PMC file '$pmc_file'\n" if DEBUG;
}

sub pmc_preamble_comment {
    my ( $self, %args ) = @_;

    return <<COMMENT;
# This file is generated by MooseX::Compile, and contains a cached
# version of the class '$args{class}'.
COMMENT
}

sub pmc_preamble_header {
    my( $self, %args ) = @_;
    my $class = $args{class};

    return join("\n\n\n", map { my $method = "pmc_preamble_header_$_"; $self->$method(%args) } $self->pmc_preamble_header_pieces(%args) );
}

sub pmc_preamble_header_pieces {
    return qw(timing modules register_pmc hide_moose);
}

sub pmc_preamble_header_timing {
    return <<'TIMING';
# used in debugging output if any
my $__mx_compile_t; BEGIN { $__mx_compile_t = times }
TIMING
}

sub pmc_preamble_header_modules {
    return <<'MODULES'
# load a few modules we need
use Sub::Name ();
use Scalar::Util ();
MODULES
}

sub pmc_preamble_header_register_pmc {
    my ( $self, %args ) = @_;
    my ( $quoted_class, $version ) = @args{qw(quoted_class quoted_compiler_version)};

    return <<REGISTER;
# Register this file as a PMC
use MooseX::Compile::Bootstrap (
    class   => $quoted_class,
    file    => __FILE__,
    version => $version,
);
REGISTER
}

sub pmc_preamble_header_hide_moose {
    my ( $self, %args ) = @_;

    my $hide = <<'#\'HIDE_MOOSE';
#\
# disable requiring and importing of Moose from this compile class
my ( $__mx_compile_prev_require, %__mx_compile_overridden_imports );

BEGIN {
    $__mx_compile_prev_require = defined &CORE::GLOBAL::require ? \&CORE::GLOBAL::require : undef;

    no warnings 'redefine';

    # FIXME move this to Bootstrap? Bootstrap->override_global_require( class => $$quoted_class$$ )?
    *CORE::GLOBAL::require = sub {
        my ( $faked_class ) = ( $_[0] =~ m/^ ( Moose | metaclass ) \.pm $/x );

        return 1 if caller() eq $$quoted_class$$ and $faked_class;

        my $hook;

        if ( $faked_class and not $INC{$_[0]} ) {
            # load Moose or metaclass in a clean env, and then wrap it's import()
            no strict 'refs';

            my $import = "${faked_class}::import";

            my $wrapper = \&$import;

            undef *$import; # clean out the symbol so it doesn't warn about redefining

            $hook = bless [sub {
                $__mx_compile_overridden_imports{$faked_class} = \&$import; # stash the real import
                *$import = $wrapper;
            }], "MooseX::Compile::Scope::Guard";
        }

        if ( $__mx_compile_prev_require ) {
            &$__mx_compile_prev_require;
        } else {
            require $_[0];
        }
    };

    foreach my $class qw(Moose metaclass) {
        no strict 'refs';

        my $import = "${class}::import";

        $__mx_compile_overridden_imports{$class} = defined &$import && \&$import;

        *$import = sub {
            if ( caller eq $$quoted_class$$ ) {
                if ( $class eq 'Moose' ) {
                    strict->import;
                    warnings->import;
                }

                return;
            }

            if ( my $sub = $__mx_compile_overridden_imports{\$class} ) {
                goto $sub;
            }

            return;
        };
    }
}
#'HIDE_MOOSE

    $hide =~ s/\$\$(\w+)\$\$/$args{$1}/ge;

    return $hide;
}

sub pmc_preamble_setup_env {
    my ( $self, %args ) = @_;

    my $class = $args{class};

    my $quoted_class = dump($class);

    my $decl = $self->pmc_preamble_class_def_for_begin(%args);

    return <<ENV;
# stub the sugar
BEGIN {
    package $class;

    my \$fake_meta = bless { name => $quoted_class }, "MooseX::Compile::MetaBlackHole";
    sub meta { \$fake_meta }

$decl

    our \$__mx_is_compiled = 1;
}
ENV
}

sub pmc_preamble_class_def_for_begin {
    my ( $self, %args ) = @_;

    join("\n\n", $self->compile_code_symbols( %args, symbol_categories => [qw(moose_sugar moose_exports)] ) );
}

sub pmc_preamble_at_end {
    my ( $self, %args ) = @_;
    my ( $class, $code ) = @args{qw(class code)};

    return <<HOOK
# try to approximate the time that Moose generated code enters the class
# this presumes you didn't stick the moose sugar in a BEGIN { } block
my \$__mx_compile_run_at_end = bless [ sub {

$code

   } ], "MooseX::Compile::Scope::Guard";
HOOK
}

sub pmc_preamble_unhide_moose {
    my ( $self, %args ) = @_;

    return <<'#\'UNHIDE_MOOSE';
#\
    # un-hijack CORE::GLOBAL::require so that it no longer hides Moose from this class
    # and undo the import wrappers that likewise prevent importing if it's already loaded

    foreach my $class ( keys %__mx_compile_overridden_imports ) {
        my $import = "${class}::import";
        no strict 'refs';
        if ( my $prev = delete $__mx_compile_overridden_imports{$class} ) {
            no warnings 'redefine';
            *$import = $prev;
        } else {
            delete ${ "${class}::" }{import};
        }
    }

    if ( $__mx_compile_prev_require ) {
        no warnings 'redefine';
        *CORE::GLOBAL::require = $__mx_compile_prev_require;
    } else {
        delete $CORE::GLOBAL::{require};
    }
#'UNHIDE_MOOSE
}

sub pmc_preamble_generated_code {
    my ( $self, %args ) = @_;

    my $class = $args{class};

    return $self->pmc_preamble_at_end(
        %args,
        code => join("\n\n",
            $self->pmc_preamble_unhide_moose(%args),
            $self->pmc_preamble_generated_code_body(%args),
            qq{warn "loading of class '$class' finished in " . (times - \$__mx_compile_t) . "s\\n" if MooseX::Compile::Base::DEBUG();},
        ),
    );
}

sub pmc_preamble_generated_code_body {
    my ( $self, %args ) = @_;

    my $class = $args{class};

    my $quoted_class = dump($class);

    return join("\n",
        "package $class;",
        $self->pmc_preamble_class_def_for_end(%args),
        qq{warn "bootstrap of class '$class' finished in " . (times - \$__mx_compile_t) . "s\\n" if MooseX::Compile::Base::DEBUG();},
    );
}

sub pmc_preamble_class_def_for_end {
    my ( $self, %args ) = @_;

    return (
        $self->pmc_preamble_define_isa(%args),
        $self->pmc_preamble_define_code_symbols(%args),
        $self->pmc_preamble_call_post_hook(%args),
    );
}

sub pmc_preamble_define_isa {
    my ( $self, %args ) = @_;

    my $ISA = dump($args{class}->meta->superclasses);

    return <<ISA
our \@ISA = $ISA;
MooseX::Compile::Bootstrap->load_classes(\@ISA);
ISA
}

sub pmc_preamble_define_code_symbols {
    my ( $self, %args ) = @_;

    return (
        $self->compile_code_symbols(%args, symbol_categories => [qw(generated aliased)]),
        $self->pmc_preamble_faked_code_symbols(%args),
    );
}

sub pmc_preamble_faked_code_symbols {
    my ( $self, %args ) = @_;

    return <<METHODS
{
    no warnings 'redefine';
    *meta = Sub::Name::subname("Moose::meta", sub { MooseX::Compile::Bootstrap->load_cached_meta( class => __PACKAGE__, pmc_file => __FILE__ . 'c' ) });
}
METHODS
}

sub pmc_preamble_call_post_hook {
    my ( $self, %args ) = @_;
    my $class = $args{class};

    return <<HOOK
${class}::__mx_compile_post_hook()
    if defined \&${class}::__mx_compile_post_hook;
HOOK
}

sub pmc_preamble {
    my ( $self, %args ) = @_;
    my ( $class, $file ) = @args{qw(class file)};

    ( my $short_name = "$class.pm" ) =~ s{::}{/}g;

    $args{short_name} = $short_name;

    $args{quoted_class} = dump($class);

    $args{compiler_version} = $MooseX::Compile::Base::VERSION;

    $args{quoted_compiler_version} = dump($MooseX::Compile::Base::VERSION);

    $args{all_symbols} = { $self->extract_code_symbols(%args) };

    my $code = join("\n",
        $self->pmc_preamble_comment(%args),
        $self->pmc_preamble_header(%args),
        $self->pmc_preamble_setup_env(%args),
        $self->pmc_preamble_generated_code(%args),
        $self->pmc_preamble_footer(%args),
    );

    delete @{ $args{all_symbols} }{qw(file meta unknown_methods unknown_functions)};

    if ( DEBUG && keys %{ $args{all_symbols} } ) {
        use Data::Dumper;
        warn "leftover symbols: " . Dumper($args{all_symbols});
    }

    return $code;
}

sub pmc_preamble_footer {
    my ( $self, %args ) = @_;
    return <<FOOTER
BEGIN { warn "giving control back to original '$args{short_name}', bootstrap preamble took " . (times - \$__mx_compile_t) . "s\\n" if MooseX::Compile::Base::DEBUG() }
FOOTER
}

__PACKAGE__

__END__

=pod

=head1 NAME

MooseX::Compile::Compiler - The Moose metaclass C<.pmc> compiler

=head1 SYNOPSIS

    my $compiler = MooseX::Compile::Compiler->new();

    $compiler->compile_class(
        class => "Foo::Bar",
        file  => $INC{"Foo/Bar.pm"},
        pmc_file => "my/pmc/lib/Foo/Bar.pmc",
    );

=head1 DESCRIPTION

This class does the heavy lifting of emitting a C<.pmc> and a C<.mopc> for a
given class.

=head1 HERE BE DRAGONS

This is alpha code. You can tinker, subclass etc but beware that things
definitely will change in the near future.

When a final version comes out there will be a documented process for how to
extend the compiler to handle your classes, whether by subclassing or using
various hooks.

=cut
