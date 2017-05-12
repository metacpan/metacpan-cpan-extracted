package B::Module::Info;

use 5.006;
use strict;
our $VERSION = '0.37';

use B;
use B::Utils 0.27 qw(walkoptree_filtered walkoptree_simple
                     opgrep all_roots);
@B::Utils::bad_stashes = qw();  # give us everything.
our ($Start, $End, $File, $CurCV);

=head1 NAME

B::Module::Info - information about Perl modules

=cut

{
    # From: Roland Walker <walker@ncbi.nlm.nih.gov>
    # "Syntax OK" may land inside output and render it unusable
    my $oldfh = select STDERR; $| = 1; # STDERR is unbuffered, but just in case
    select STDOUT; $| = 1;
    select $oldfh;
}

my $the_file = $0; # when walking all subroutines, you need to skip
                   # the ones in other modules

sub state_change {
    return opgrep {name => [qw(nextstate dbstate setstate)]}, @_
}

my $cur_pack;
sub state_call {
    my($op) = shift;
    my $pack = $op->stashpv;
    print "$pack\n" if !defined($cur_pack) || $pack ne $cur_pack;
    $cur_pack = $pack;
}


sub filtered_roots {
    my %roots = all_roots;
    my %filtered_roots = ();
    while( my($name, $op) = each %roots ) {
        next if $name eq '__MAIN__';
        $filtered_roots{$name} = $op;
    }
    return %filtered_roots;
}


=head2 roots_cv_pairs_recursive

Returns a list of pairs, each containing a root with the relative
B::CV object; this list includes B::main_root/cv and all anonymous
subroutines defined therein.

=cut

sub roots_cv_pairs_recursive {
    my @queue = roots_cv_pairs();
    my @roots;

    my $anon_sub = sub {
        B::class($_[0]) ne 'NULL' && $_[0]->name eq 'anoncode';
    };

    my $anon_check = sub {
        my $cv = const_sv($_[0]);
        push @queue, [ $cv->ROOT, $cv ];
    };

    while( @queue ) {
        my $p = shift @queue;
        push @roots, $p;
        local $CurCV = $p->[1];
        walkoptree_filtered($p->[0],
                            $anon_sub,
                            $anon_check );
    }

    return @roots;
}

=head2 roots_cv_pairs

Returns a list of pairs, each containing a root with the relative
B::CV object for named subroutines; this list includes B::main_root/cv.

=cut

sub roots_cv_pairs {
    my %roots = filtered_roots;
    my @roots = ( [ B::main_root, B::main_cv ],
                  map { [ $roots{$_},
                          B::svref_2object(\&{$_}) ] }
                  keys %roots );
}


my %modes = (
             packages => sub {
                 walkoptree_filtered(B::main_root,
                                     \&state_change,
                                     \&state_call );
             },
             subroutines => sub {
                 my %roots = filtered_roots();
                 while( my($name, $op) = each %roots ) {
                     local($File, $Start, $End);
                     walkoptree_simple($op, \&sub_info);
                     print "$name at \"$File\" from $Start to $End\n";
                 }
             },
             modules_used => sub {
                 # begin_av is an undocumented B function.
                 # note: if module hasn't any BEGIN block,
                 #       begin_av will be a B::SPECIAL
                 my @arr = B::begin_av->isa('B::SPECIAL') ?
                           () :
                           B::begin_av->ARRAY;
                 foreach my $begin_cv (@arr) {
                     my $root = $begin_cv->ROOT;
                     local $CurCV = $begin_cv;

                     next unless $begin_cv->FILE eq $the_file;
                     # cheat otherwise show_require guard prevents display
                     local $B::Utils::file = $begin_cv->FILE;
                     local $B::Utils::line = $begin_cv->START->line;

                     # this is from $ENV{PERL5OPT}, skip it
                     next if $B::Utils::line == 0;

                     my $lineseq = $root->first;
                     next if $lineseq->name ne 'lineseq';

                     my $req_op = $lineseq->first->sibling;
                     if( $req_op->name eq 'require' ) {
                         my $module;
                         if( $req_op->first->private & B::OPpCONST_BARE ) {
                             $module = const_sv($req_op->first)->PV;
                             $module =~ s[/][::]g;
                             $module =~ s/.pm$//;
                         }
                         else {
                             # if it is not bare it can't be an "use"
                             show_require($req_op);
                             next;
                         }

                         printf "use %s (%s) at \"%s\" line %s\n",
                             $module,
                             get_required_version($req_op, $module),
                             $begin_cv->FILE,
                             $begin_cv->START->line;
                     }
                     # it can't be an use, scan the optree
                     else {
                         walkoptree_filtered($root,
                                     \&is_require,
                                     \&show_require,
                                    );
                     }
                 }

                 {
                     foreach my $p ( roots_cv_pairs_recursive ) {
                         local $CurCV = $p->[1];
                         walkoptree_filtered($p->[0],
                                     \&is_require,
                                     \&show_require,
                                    );
                     }
                 }
             },
             subs_called => sub {
                 foreach my $p ( roots_cv_pairs_recursive ) {
                     local $CurCV = $p->[1];
                     walkoptree_filtered($p->[0],
                                         \&sub_call,
                                         \&sub_check );
                 }
             }
            );


sub const_sv {
    my $op = shift;
    my $sv;
    
    if ($op->name eq 'method_named' && $op->can('meth_sv')) {
        $sv = $op->meth_sv;
    }
    elsif ($op->can('sv')) {
        $sv = $op->sv;
    }
    # the constant could be in the pad (under useithreads)
    $sv = padval($op->targ) unless ref($sv) && $$sv;
    return $sv;
}

# Don't do this for regexes
sub unback {
    my($str) = @_;
    $str =~ s/\\/\\\\/g;
    return $str;
}

sub const {
    my $sv = shift;
    if (B::class($sv) eq "SPECIAL") {
        return ('undef', '1', '0')[$$sv-1]; # sv_undef, sv_yes, sv_no
    } elsif (B::class($sv) eq "NULL") {
        return 'undef';
    } elsif ($sv->FLAGS & B::SVf_IOK) {
        return $sv->int_value;
    } elsif ($sv->FLAGS & B::SVf_NOK) {
        # try the default stringification
        my $r = "".$sv->NV;
        if ($r =~ /e/) {
            # If it's in scientific notation, we might have lost information
            return sprintf("%.20e", $sv->NV);
        }
        return $r;
    } elsif ($sv->FLAGS & B::SVf_ROK && $sv->can("RV")) {
        return "\\(" . B::const($sv->RV) . ")"; # constant folded
    } elsif ($sv->FLAGS & B::SVf_POK) {
        my $str = $sv->PV;
        if ($str =~ /[^ -~]/) { # ASCII for non-printing
            return single_delim("qq", '"', uninterp escape_str unback $str);
        } else {
            return single_delim("q", "'", unback $str);
        }
    } else {
        return "undef";
    }
}


sub single_delim {
    my($q, $default, $str) = @_;
    return "$default$str$default" if $default and index($str, $default) == -1;
    my($succeed, $delim);
    ($succeed, $str) = balanced_delim($str);
    return "$q$str" if $succeed;
    for $delim ('/', '"', '#') {
        return "$q$delim" . $str . $delim if index($str, $delim) == -1;
    }
    if ($default) {
        $str =~ s/$default/\\$default/g;
        return "$default$str$default";
    } else {
        $str =~ s[/][\\/]g;
        return "$q/$str/";
    }
}


sub padval {
    my $targ = shift;
    return (($CurCV->PADLIST->ARRAY)[1]->ARRAY)[$targ];
}


sub sub_info {
    $File = undef if $File eq '__none__';
    $File  ||= $B::Utils::file;
    $Start = $B::Utils::line if !$Start || $B::Utils::line < $Start;
    $End   = $B::Utils::line if !$End   || $B::Utils::line > $End;
}

sub is_begin {
    my($op) = shift;
    my $name = $op->GV;
    print $name;
    return $name eq 'BEGIN';
}

sub begin_is_use {
    my($op) = shift;
    print "Saw begin\n";
}


sub grep_magic {
    my($pvmg, $type) = @_;
    my $magic = $pvmg->MAGIC;

    while ($$magic) {
        return $magic if $magic->TYPE eq $type;
    }

    return $magic; # false
}

sub get_required_version {
    my($req_op, $module) = (shift, shift);

    my $version;
    my $version_op = $req_op->sibling;
    return if B::class($version_op) eq 'NULL';
    if ($version_op->name eq 'lineseq') {
        # We have a version parameter; skip nextstate &
        # pushmark
        my $constop = $version_op->first->next->next;

        return '' unless const_sv($constop)->PV eq $module;
        $constop = $constop->sibling;
        $version = const_sv($constop);
        my $class = B::class($version);
        my $magic;
        $version = $class eq 'IV'   ? $version->int_value :
                   $class eq 'NV'   ? $version->NV :
                  ($class eq 'PVMG' && ($magic = grep_magic($version, 'V'))
                        && $$magic) ? 'v' . $magic->PTR :
                 ((($class eq 'PVNV' && $] < 5.009) || $class eq 'PVMG')
                       && length($version->PV)) ?
                     'v' . join('.', map(ord,
                                         split(//,
                                               $version->PV)
                                        ))         :
                   $class eq 'PVIV' ? $version->int_value :
                                      $version->NV;

        $constop = $constop->sibling;
        return '' if $constop->name ne "method_named";
        return '' if const_sv($constop)->PV ne "VERSION";
    }

    return $version;
}


sub is_require {
    B::class($_[0]) ne 'NULL' && $_[0]->name eq 'require';
}

sub show_require {
    return unless $B::Utils::file eq $the_file;
    my($op) = shift;

    my($name, $bare);
    if( B::class($op) eq "UNOP" and $op->first->name eq 'const'
        and $op->first->private & B::OPpCONST_BARE ) {
        $bare = 'bare';
        $name = const_sv($op->first)->PV;
    }
    else {
        $bare = 'not bare';
        if ($op->flags & B::OPf_KIDS) {
            my $kid = $op->first;
            if (defined prototype("CORE::$name") 
                && prototype("CORE::$name") =~ /^;?\*/
                && $kid->name eq "rv2gv") {
                $kid = $kid->first;
            }

            my $sv = const_sv($kid);
            return unless defined $sv && !$sv->isa('B::NULL');
            $name   = $sv->isa("B::NV") ? $sv->NV : 0;
            $name ||= $sv->isa("B::PV") ? $sv->PV : '';
            $name ||= $sv->IV;
        }
        else {
            $name = "";
        }
    }
    printf "require %s %s at line %d\n", $bare, $name, $B::Utils::line;
}


sub compile {
    my($mode) = shift;

    return $modes{$mode};
}


sub sub_call {
    B::class($_[0]) ne 'NULL' && $_[0]->name eq 'entersub';
}

sub sub_check {
    my($op) = shift;

    unless( $op->name eq 'entersub' ) {
        warn "sub_check only works with entersub ops";
        return;
    }

    my @kids = $op->kids;

    # static method call
    if( my($kid) = grep $_->name eq 'method_named', @kids ) {
        my $class = _class_or_object_method(@kids);
        printf "%s method call to %s%s at \"%s\" line %d\n", 
          $class ? "class" : "object",
          const_sv($kid)->PV,
          $class ? " via $class" : '',
          $B::Utils::file, $B::Utils::line;
    }
    # dynamic method call
    elsif( my($kid) = grep $_->name eq 'method', @kids ) {
        my $class = _class_or_object_method(@kids);
        printf "dynamic %s method call%s at \"%s\" line %d\n",
          $class ? "class" : "object",
          $class ? " via $class" : '',
          $B::Utils::file, $B::Utils::line;
    }
    # function call
    else {
        my $gv_op;
        my ($filename, $line) = ($B::Utils::file, $B::Utils::line);
        walkoptree_simple($op,
            sub { my $op = shift; $gv_op = $op if $op->name eq 'gv'; }
        );
        if ($gv_op) {
            my $gv = gv_or_padgv($gv_op);
            printf "function call to %s at \"%s\" line %d\n", 
              $gv->NAME, $filename, $line;
        }
        else {
            printf "function call using symbolic ref at \"%s\" line %d\n",
              $filename, $line;
        }
    }
}


sub gv_or_padgv {
#    my $self = shift;
    my $op = shift;
    if ($op->isa("B::PADOP")) {
        return padval($op->padix);
    }
    else { # class($op) eq "SVOP"
        return $op->gv;
    }
}


sub _class_or_object_method {
    my @kids = @_;

    my $class;
    my($classop) = $kids[1];
    if( $classop->name eq 'const' ) {
        $class = const_sv($classop)->PV;
    }

    return $class;
}


1;
