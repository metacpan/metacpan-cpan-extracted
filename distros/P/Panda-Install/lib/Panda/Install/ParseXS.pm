package
    Panda::Install::ParseXS;
use strict;
use warnings;
use feature 'state';
use ExtUtils::ParseXS;
use ExtUtils::ParseXS::Eval;
use ExtUtils::ParseXS::Utilities;
use ExtUtils::Typemaps;
use ExtUtils::Typemaps::InputMap;
use ExtUtils::Typemaps::OutputMap;

our ($top_typemaps, $cur_typemaps);
our %code_params;

our $re_parens  = qr/(\((?:(?>[^()]+)|(?-1))*\))/;
our $re_gtlt    = qr/(<(?:(?>[^<>]+)|(?-1))*>)/;
our $re_braces  = qr/(\{(?:(?>[^{}]+)|(?-1))*\})/;
our $re_quot1 = qr/"(?:[^"\\]+|\\.)*"/;
our $re_quot2 = qr/'(?:[^'\\]+|\\.)*'/;
our $re_quot  = qr/(?:$re_quot1|$re_quot2)/;

sub map_postprocess {
    my $map = shift;
    my $is_output = $map->isa('ExtUtils::Typemaps::OutputMap') || 0;
    my $type = $is_output ? 'OUTPUT' : 'INPUT';
    my $code = $map->code;
    $code = "" unless $code =~ /\S/;
    $code =~ s/\s+$//;
    $code =~ s/\t/    /g;
    #$code =~ s#^(.*)$#sprintf("%-80s%s", "$1", "/* $map->{xstype} */")#mge if $code;
    my @attrs = qw/PREVENT_DEFAULT_DESTROY/;
    
    if ($map->{xstype} =~ s/^(.+?)\s+:\s+([^() ]+)\s*(\(((?:$re_quot|[^()]|(?3))*)\))?$/$1/) {
        my $parent_xstype = $2;
        my $parent_params = $4;
        my $parent_map = $is_output ? outmap($parent_xstype) : inmap($parent_xstype);
        die "\e[31m No parent $parent_xstype found in $type map \e[0m" unless $parent_map;
        my $parent_code = $parent_map->code;
        $map->{_init_code} = $parent_map->{_init_code};
        $map->{_attrs}{$_} = $parent_map->{_attrs}{$_} for @attrs;
        
        if ($parent_params and $parent_code) {
            $parent_params .= ',';
            $parent_params =~ s/^[\s,]+//;
            my %p = (xstype => $parent_xstype);
            while ($parent_params =~ s/^\s*((?:$re_quot|[^,])*)\s*,\s*//) {
                my $pair = $1;
                next unless defined $pair and $pair ne '' and $pair =~ /^((?:$re_quot|[^=])*)(?:=(.+))?$/;
                my ($k,$v) = ($1, $2);
                $v //= 1;
                foreach my $quot ('"', "'") {
                    for ($k, $v) {
                        if (index($_, '"') == 0 and rindex($_, '"') == length($_) - 1) {
                            substr($_, 0, 1, '');
                            chop($_);
                        }
                    }
                }
                $p{$k} = $v;
            }
            my $pstr = parent_typemap_serialize_params(\%p);
            $parent_code = "    \${\\\$self->eval_typemap($is_output, $pstr, 1)}";
        }
        
        if ($code =~ /TYPEMAP::SUPER\(\)\s*;/) {
            $code =~ s/\s*TYPEMAP::SUPER\(\)\s*;/$parent_code/;
        }
        elsif ($is_output) {
            $code .= "\n" if $code;
            $code .= $parent_code;
        } else {
            my $prevcode = $code;
            $code = $parent_code;
            $code .= "\n$prevcode" if $prevcode;
        }
    }
    
    die "Panda::Install::ParseXS: the old-style 'INIT: ...' line found in a typemap code. If it's not your line, please consider updating Panda::XS"
        if $code =~ /^\s*INIT:/m;
    
    # MOVE AWAY 'INIT {...}' blocks. It will later be used in fetch_para to insert it into the top of the function
    my $init_blocks = join("\n", extract_blocks('INIT', \$code));
    $map->{_init_code} .= "$init_blocks\n" if $init_blocks;

    foreach my $attr (@attrs) {
        next unless $code =~ s/^\s*\@$attr\s*(?:=\s*(.+))?$//mg;
        $map->{_attrs}{$attr} = $1 // 1;
        $map->{_attrs}{$attr} =~ s/\s+$//;
    }
    
    $map->code($code);
}

sub extract_blocks {
    my ($blkname, $coderef) = @_;
    return unless $$coderef;
    return if index($$coderef, $blkname) == -1;
    my @result;
    while ($$coderef =~ s/^\s*$blkname\s*(?<CONTENT>$re_braces)//m) {
        my $chunk = $+{CONTENT};
        substr($chunk, 0, 1, '');
        chop($chunk);
        $chunk =~ s/^\s+//;
        $chunk =~ s/\s+$//;
        next unless $chunk;
        push @result, $chunk;
    }
    return @result;
}

sub fix_newmortal {
    my ($arg, $coderef) = @_;
    # if code has '$arg = <something>' not in first line - prevent fuckin ExtUtils::ParseXS from adding '$arg = sv_newmortal()'
    # triggered by $arg = NULL which must firstly be set by typemap itself. Move it on top if inheriting
    #state $ppline = '    $arg = NULL; /* suppress xsubpp\'s pollution of $arg */';
    my $found = ($$coderef =~ s/^\s*\Q$arg\E\s*=\s*NULL\s*;\s*$//gm); # remove previous guardians;
    $$coderef = "    $arg = NULL;\n$$coderef" if $found;
}

sub prettify {
    my ($coderef) = @_;
    return unless $$coderef;
    $$coderef =~ s/\n\s*\n/\n/gm;
    $$coderef .= "\n" unless substr($$coderef, -1, 1) eq "\n"; # typemap must end with \n
}

sub sync_type {
    my ($type, $ntype, $subtype) = @_;
    $type //= '';
    return ($type, $type) unless $type;
    unless ($subtype) {
        $subtype = $type;
        $subtype =~ s/\s+//g;
        $subtype =~ s/\*$//;
    }
    unless ($ntype) {
        $ntype = $type;
        $ntype =~ s/\s+//g;
        $ntype =~ s/\*/Ptr/g;
    }
    return ($ntype, $subtype);
}

sub parent_typemap_serialize_params {
    my $hash = shift;
    my $str = '{%$params,';
    while (my ($k, $v) = each %$hash) {
        s/#/\\#/g for $k, $v;
        $str .= "qq#$k# => qq#$v#,";
    }
    chop($str);
    return "$str, %p}"; # custom params to typemap are not rewritable by typemap's params to it's parent
}

sub outmap { return $cur_typemaps->get_outputmap(xstype => $_[0]) || ($top_typemaps && $top_typemaps->get_outputmap(xstype => $_[0])); }
sub inmap  { return $cur_typemaps->get_inputmap(xstype => $_[0]) || ($top_typemaps && $top_typemaps->get_inputmap(xstype => $_[0])); }

package
    ExtUtils::ParseXS; # hide from pause
use strict;
use warnings;

    # pre process     # post process       # after preprocess
my ($orig_fetch_para, $orig_print_section, $after_fetch_para, $last_params);

BEGIN {
    $orig_fetch_para = \&fetch_para;
    $orig_print_section = \&print_section;
    no strict 'refs';
    delete ${__PACKAGE__.'::'}{fetch_para};
    delete ${__PACKAGE__.'::'}{print_section};
    delete ${__PACKAGE__.'::'}{eval_output_typemap_code};
    delete ${__PACKAGE__.'::'}{eval_input_typemap_code};
}

BEGIN {
    eval {require inc::MY::ParseXS; 1} and do {
        $after_fetch_para = *inc::MY::ParseXS::after_fetch_para{CODE};
    };
}

# pre process XS function
sub fetch_para {
    my $self = shift;
    my $ret = $orig_fetch_para->($self, @_);
    my $lines = $self->{line};
    my $linno = $self->{line_no};

    # concat 2 lines codes (functions with default behaviour) to make it preprocessed like C-like synopsis
    if (@$lines == 2) {
        $lines->[0] .= ' '.$lines->[1];
        splice(@$lines, 1, 1);
        splice(@$linno, 1, 1);
    }
    
    if ($lines->[0] and $lines->[0] =~ /^([A-Z]+)\s*\{/) {
        $lines->[0] = "$1:";
        if ($lines->[-1] =~ /^\}/) { pop @$lines; pop @$linno; }
    }
    
    if ($lines->[0] and $lines->[0] =~ /^(.+?)\s+([^\s()]+\s*(\((?:[^()]+|(?3))*\)))\s*(.*)/) {
        my ($type, $sig, $attrs) = ($1, $2, $4);
        $self->{_xsub_attrs} = { $attrs =~ /:\s*([A-Z]+)\s*(?:\(([^()]*)\)|)\s*/gc };
        my $alias = $self->{_xsub_attrs}->{ALIAS};
        my $remove_closing;
        
        if ((my $idx = index($lines->[0], '{')) > 0) { # move following text on next line
            $remove_closing = 1;
            my $content = substr($lines->[0], $idx);
            if ($content !~ /^\{\s*$/) {
                $content =~ s/^\{//;
                splice(@$lines, 1, 0, $content);
                splice(@$linno, 1, 0, $linno->[0]);
            }
        } elsif ($lines->[1] and $lines->[1] =~ s/^\s*\{//) { # '{' on next line
            $remove_closing = 1;
            if ($lines->[1] !~ /\S/) { # nothing remains, delete entire line
                splice(@$lines, 1, 1);
                splice(@$linno, 1, 1);
            }
        }

        if ($remove_closing) {
            $lines->[-1] =~ s/}\s*;?\s*$//;
            if ($lines->[-1] !~ /\S/) { pop @$lines; pop @$linno; }
            
            if (!$lines->[1] or $lines->[1] !~ /\S/) { # no code remains, but body was present ({}), add empty code to prevent default behaviour
                splice(@$lines, 1, 0, ' ');
                splice(@$linno, 1, 0, $linno->[0]);
            }
        }
        
        $lines->[0] = $type;
        
        $self->{_empty_func} = 0;
        if (!$lines->[1]) {{ # empty sub
            $self->{_empty_func} = 1;
            my ($class, $func, $var);
            if ($sig =~ /^([^:]+)::([a-zA-Z0-9_\$]+)/) {
                ($class, $func, $var) = ("$1*", $2, 'THIS');
            } elsif ($sig =~ /^([a-zA-Z0-9_\$]+)\s*\(\s*([a-zA-Z0-9_\$*]+)\s+\*?([a-zA-Z0-9_\$]+)\)/) {
                ($class, $func, $var) = ($2, $1, $3);
            } else { last }
            my $in_tmap = $self->{typemap}->get_inputmap(ctype => $class) or last;
            if ($func eq 'DESTROY' and $var eq 'THIS' and $in_tmap->{_attrs}{PREVENT_DEFAULT_DESTROY}) {
                splice(@$lines, 1, 0, ' ');
                splice(@$linno, 1, 0, $linno->[0]);
            }
        }}
                
        if ($lines->[1] and $lines->[1] !~ /^[A-Z]+\s*:/) {
            splice(@$lines, 1, 0, $type =~ /^void(\s|$)/ ? 'PPCODE:' : 'CODE:');
            splice(@$linno, 1, 0, $linno->[0]);
        }
        
        if ($alias) {
            my @alias = split /\s*,\s*/, $alias;
            if (@alias) {
                foreach my $alias_entry (reverse @alias) {
                    splice(@$lines, 1, 0, "    $alias_entry");
                    splice(@$linno, 1, 0, $linno->[0]);
                }
                splice(@$lines, 1, 0, 'ALIAS:');
                splice(@$linno, 1, 0, $linno->[0]);
            }
        }
        
        splice(@$lines, 1, 0, $sig);
        splice(@$linno, 1, 0, $linno->[0]);
    } else {
        %{$self->{_xsub_attrs}} = ();
    }

    my $para = join("\n", @$lines);
    
    if ($para =~ /^CODE\s*:/m and $para !~ /^OUTPUT\s*:/m) {
        push @$lines, 'OUTPUT:', '    RETVAL';
        push @$linno, $linno->[-1]+1 for 1..2;
        $para = join("\n", @$lines);
    }
    
    if (my $out_ctype = $lines->[0]) {{
        $out_ctype =~ s/^\s+//g;
        $out_ctype =~ s/\s+$//g;
        my $out_tmap = $self->{typemap}->get_outputmap(ctype => $out_ctype) or last;
        my $init_code = $out_tmap->{_init_code} or last;
        my $idx;
        for (my $i = 2; $i < @$lines; ++$i) {
            next unless $lines->[$i] =~ /^\s*[a-zA-Z0-9]+\s*:/;
            $idx = $i;
            last;
        }
        last unless $idx;
        splice(@$lines, $idx, 0, $init_code);
        splice(@$linno, $idx, 0, $linno->[0]);
    }}

    $after_fetch_para->($self) if $after_fetch_para;
    
    return $ret;
}

# post process XS function
sub print_section {
    my $self = shift;
    my $lines = $self->{line};
    my $linno = $self->{line_no};
    
    # find typemap_in|outcast<>()
    my $re_parens = $Panda::Install::ParseXS::re_parens;
    my $re_gtlt   = $Panda::Install::ParseXS::re_gtlt;
    my %gen_funcs;
    foreach my $row (['typemap_incast', 1], ['typemap_outcast', 0]) {
        my ($kword, $is_input) = @$row;
        my $re = qr/\b$kword\s*(?<CLASS>$re_gtlt)\s*(?<EXPR>$re_parens)/;
        foreach my $line (@$lines) {
            while ($line =~ $re) {
                my ($class, $expr) = @+{'CLASS', 'EXPR'};
                $class =~ s/^<//;
                $class =~ s/>$//;
                my @args;
                ($class, @args) = split /\s*,\s*/, $class;
                for (@args) {
                    s/^\s+//; s/\s+$//;
                    die "\e[31m Typemap parameter must have a type at '$_' \e[0m" unless /^(.+?)([a-zA-Z0-9_\$]+)$/;
                    my ($type, $name) = ($1, $2);
                    $type =~ s/\s+\*/*/g;
                    $type =~ s/\s+$//;
                    $_ = [$type, $name];
                }
                
                my $meth = $is_input ? 'get_inputmap' : 'get_outputmap';
                my $tmap = $self->{typemap}->$meth(ctype => $class);
                die "\e[31m No typemap found for '$kword<$class>()', line '$line' \e[0m" unless $tmap;
                my $subtype = $class; $subtype =~ s/\s*\*$//;
                my $ntype   = $class; $ntype   =~ s/\s*\*$/Ptr/;
                my $tmfunc_name = "_${kword}_${ntype}_".join("_", map {"@$_"} @args);
                $tmfunc_name =~ s/\*/Ptr/g;
                $tmfunc_name =~ s/\s/_/g;
                $tmfunc_name =~ s/::/__/g;
                unless ($gen_funcs{$tmfunc_name}) {
                    my $arg = 'arg';
                    my $other = {
                        var     => 'var',
                        type    => $class,
                        subtype => $subtype,
                        ntype   => $ntype,
                        arg     => $arg,
                    };
                    if ($is_input) {
                        $other->{num}          = -1; # not on stack
                        $other->{init}         = undef;
                        $other->{printed_name} = 0;
                        $other->{argoff}       = -1; # not on stack
                    }
                    $meth = $is_input ? 'eval_input_typemap_code' : 'eval_output_typemap_code';
                    my $tmcode = $tmap->code;
                    my $code = $self->$meth("qq\a$tmcode\a", $other);
                    my $arg_init = (!$is_input && $code =~ /^\s*$arg\s*=\s*NULL\s*;\s*$/m) ? '' : ' = newSV(0)';
                    my $tmfunc_code = $self->typemap_inline_func($tmfunc_name, $class, $code, $arg_init, $is_input, \@args, $tmap->{_init_code});
                    $gen_funcs{$tmfunc_name} = $tmfunc_code;
                }
                $expr =~ s/^\s*\(\s*/(aTHX_ /; # add interp to param for threaded perls
                $line =~ s/$re/${tmfunc_name}::get$expr/;
            }
        }
    }
    
    my $gen_code = join "", values %gen_funcs;
    print $gen_code;
    
    return $gen_code.$orig_print_section->($self, @_);
}

sub typemap_inline_func {
    my ($self, $tmfunc_name, $class, $code, $arg_init, $is_input, $args, $tm_init) = @_;
    $code =~ s/^\s+//s;
    $code =~ s/\s+$//s;
    my $additional_args = ($args && @$args) ? ", ".join(", ", map { "$_->[0] $_->[1]" } @$args) : '';
    
    if ($tm_init and @$args) {
        # if some custom typemap variable is defined and set in typemap INIT section, and is present in $args,
        # we must remove it to give user a chance to redefine it. Ugly, but there are no other chance with ugly ExtUtils::ParseXS.
        for (@$args) {
            my ($type, $name) = @$_;
            $type =~ s/\*/\\s*\\*/g;
            $tm_init =~ s/((?:^\s*|;\s*|\}\s*)$type\s+)($name)\b/${1}__pxs_${2}_off__/s;
        }
    }
    $code = "$tm_init\n    $code" if $tm_init;
    $code =~ s/^[\s;]+$//mg;
    $code =~ s/\n\n+/\n/g;
    
    $code =~ s/^/        /mg;
    return << "EOF" if $is_input;
        struct $tmfunc_name { static inline $class get (pTHX_ SV* arg$additional_args) {
            $class var;\n    $code;
            return var;
        }};
EOF
    return << "EOF";
        struct $tmfunc_name { static inline SV* get (pTHX_ $class var$additional_args) {
            SV* arg$arg_init;\n    $code;
            return arg;
        }};
EOF
}

sub eval_output_typemap_code {
    my ($self, $code, $args, $inner) = @_;
    return $self->eval_typemap_code(1, $code, $args, $inner);
}

sub eval_input_typemap_code {
    my ($self, $code, $args, $inner) = @_;
    return $self->eval_typemap_code(0, $code, $args, $inner);
}

sub eval_typemap_code {
    my ($self, $_is_output_, $_code_, $params, $inner) = @_;
    my %p = %{$params||{}};
    my ($Package, $ALIAS, $func_name, $Full_func_name, $pname) = @{$self}{qw(Package ALIAS func_name Full_func_name pname)};
    my ($var, $type, $num, $init, $printed_name, $arg, $argoff, $do_setmagic, $do_push) =
        delete @p{qw(var type num init printed_name arg argoff do_setmagic do_push)};
    my ($ntype, $subtype) = Panda::Install::ParseXS::sync_type($type, delete $p{ntype}, delete $p{subtype});
    $last_params = $params if delete $p{_extract_params_};

    my $rand = int(rand 2**63);
    my $is_destroy = !$_is_output_ && $func_name eq 'DESTROY' and $var =~ /^THIS/;
    my $is_empty_func = $self->{_empty_func};
    my $has_threads = eval "use threads; 1;";
    
    my $_need_print_ = $_code_ =~ s/^\s*print\s+// ? 1 : 0;
    $_code_ =~ s/["\a]\s*$//;
    $_code_ =~ s/^\s*"//;
    $_code_ =~ s/^qq\a//;
    $_code_ = "qq\a$_code_\a";
    $_code_ = "print $_code_" if $_need_print_;
    
    while (my ($k, $v) = each %p) { # place custom args in perl vars
        $v //= '';
        $_code_ = "my \$$k = '$v'; $_code_";
    }
    # need clean package everytime, because $code might set params which were not in %p, and therefore create a global var
    # which would not be cleaned up
    {
        my $fn = $func_name || '';
        my $pk = $Package || '';
        my $st = $type || '';
        s/[^a-zA-Z0-9_]/_/g for $fn, $pk, $st;
        my $_pack = "TMEvalPack_${pk}_${fn}_${st}_".int(rand 2**31).'_'.length($_code_).($_is_output_ ? "O" : "I");
        $_code_ = "{ package $_pack; $_code_ }";
    }

    my $_rv_;
    {        
        no strict;
        no warnings 'uninitialized';
        $_rv_ = eval $_code_;
        die "Error evaling typemap: $@\nTypemap code was:\n$_code_" if $@;
    }
    
    return $_rv_ if $inner; # don't post-process sub-typemaps separately, because INIT_OUTPUT, etc, behaviour won't be correct
    return $_rv_ unless $arg; # skip primitive typemaps

    if ($_is_output_) {
        my $pre_blocks = join("\n", reverse Panda::Install::ParseXS::extract_blocks('INIT_OUTPUT', \$_rv_));
        $_rv_ = "$pre_blocks\n$_rv_" if $pre_blocks;
        Panda::Install::ParseXS::fix_newmortal($arg, \$_rv_);
    } else {
        my $destroy_blocks = join("\n", Panda::Install::ParseXS::extract_blocks('DESTROY', \$_rv_));
        $_rv_ .= "\n$destroy_blocks" if $destroy_blocks and $is_destroy;
    }
    
    Panda::Install::ParseXS::prettify(\$_rv_);
    
    return $_rv_;
}

sub eval_output_typemap {
    my ($self, $args, $inner) = @_;
    return $self->eval_typemap(1, $args, $inner);
}

sub eval_input_typemap {
    my ($self, $args, $inner) = @_;
    return $self->eval_typemap(0, $args, $inner);
}

sub eval_typemap {
    my ($self, $is_output, $args, $inner) = @_;
    my %params;
    foreach my $k (qw/xstype ctype/) {
        $params{$k} = delete $args->{$k} if exists $args->{$k};
    }
    my $method = $is_output ? 'get_outputmap' : 'get_inputmap';
    my $typemap = $self->{typemap}->$method(%params);
    my $dbgstr = $params{xstype} || $params{ctype};
    die "\e[31m No typemap '$dbgstr' found for eval_typemap \e[0m" unless $typemap;
    return $self->eval_typemap_code($is_output, '"'.$typemap->code.'"', $args, $inner);
}

sub output_typemap_param {
    my ($self, $ctype, $pname) = @_;
    return $self->typemap_param(1, $ctype, $pname);
}

sub input_typemap_param {
    my ($self, $ctype, $pname) = @_;
    return $self->typemap_param(0, $ctype, $pname);
}

sub typemap_param {
    my ($self, $is_output, $ctype, $pname) = @_;
    $self->eval_typemap($is_output, {
        type  => $ctype,
        ctype => $ctype,
        arg   => 'dummy_arg',
        var   => 'dummy_var',
        _extract_params_ => 1,
    }, 1);
    return $last_params->{$pname};
}

package
    ExtUtils::Typemaps; # hide from pause
use strict;
use warnings;

my ($orig_merge, $orig_parse);

BEGIN {
    $orig_merge = \&merge;
    $orig_parse = \&_parse;
    no strict 'refs';
    delete ${__PACKAGE__.'::'}{merge};
    delete ${__PACKAGE__.'::'}{_parse};
}


sub merge {
    $Panda::Install::ParseXS::top_typemaps = $_[0];
    return $orig_merge->(@_);
}

sub _parse {
    local $Panda::Install::ParseXS::cur_typemaps = $_[0];
    return $orig_parse->(@_);
}

package
    ExtUtils::Typemaps::OutputMap; # hide from pause
use strict;
use warnings;

my $orig_onew;
BEGIN {
    $orig_onew = \&new;
    no strict 'refs';
    delete ${__PACKAGE__.'::'}{new};
}

sub new {
    my $proto = shift;
    my $self = $orig_onew->($proto, @_);
    Panda::Install::ParseXS::map_postprocess($self) unless ref $proto; # if $proto is object, it's cloning, no need to postprocess
    return $self;
}

package
    ExtUtils::Typemaps::InputMap; # hide from pause
use strict;
use warnings;

my $orig_inew;
BEGIN {
    $orig_inew = \&new;
    no strict 'refs';
    delete ${__PACKAGE__.'::'}{new};
}

sub new {
    my $proto = shift;
    my $self = $orig_inew->($proto, @_);
    Panda::Install::ParseXS::map_postprocess($self) unless ref $proto; # if $proto is object, it's cloning, no need to postprocess
    return $self;
};

package
    ExtUtils::ParseXS::Utilities; # hide from pause
use strict;
use warnings;
no warnings 'redefine';

# remove ugly default behaviour, it always overrides typemaps in xsubpp's command line
sub standard_typemap_locations {
    my $inc = shift;
    my @ret;
    push @ret , 'typemap' if -e 'typemap';
    return @ret;
}

1;
