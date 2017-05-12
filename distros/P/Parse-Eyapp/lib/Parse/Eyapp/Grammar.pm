#
# Module Parse::Eyapp::Grammar
#
# (c) Copyright 1998-2001 Francois Desarmenien, all rights reserved.
# (c) Copyright 2006-2008 Casiano Rodriguez-Leon, all rights reserved.
# 
package Parse::Eyapp::Grammar;
@ISA=qw( Parse::Eyapp::Options );

require 5.004;

use Carp;
use strict;
use Parse::Eyapp::Options;
use Parse::Eyapp::Parse;
use Scalar::Util qw{reftype};
use Data::Dumper;

###############
# Constructor #
###############
sub new {
    my($class)=shift;
    my($values);

    my($self)=$class->SUPER::new(@_);

    my($parser)=new Parse::Eyapp::Parse;

        defined($self->Option('input'))
    or  croak "No input grammar";

    $values = $parser->Parse($self->Option('input'),      # 1 input
                             $self->Option('firstline'),  # 2 Line where the grammar source starts
                             $self->Option('inputfile'),  # 3 The file or program containing the grammar
                             $self->Option('tree'),       # 4 %tree activated
                             $self->Option('nocompact'),  # 5 %nocompact
                             $self->Option('lexerisdefined'),    # 6 lexer is defined
                             $self->Option('prefix'),            # 7 accept prefix
                             $self->Option('start'),            # 8 specify start symbol
                             #$self->Option('prefixname'),  # yyprefix
                             #$self->Option('buildingtree')  # If building AST
                            );

    undef($parser);

    $$self{GRAMMAR}=_ReduceGrammar($values);

        ref($class)
    and $class=ref($class);

    bless($self, $class);

    my $ns = $self->{GRAMMAR}{NAMINGSCHEME} ;
    if ($ns && reftype($ns) eq 'ARRAY') {
      $ns = eval "sub { $ns->[0]; }; ";
      warn "Error in \%namingscheme directive $@" if $@;
      $ns = $ns->($self);
    }
    $ns ||= \&give_default_name;
    $self->{GRAMMAR}{NAMINGSCHEME} = $ns; # added to allow programmable production naming schemes (%name)

    $self;
}

###########
# Methods #
###########
##########################
# Method To View Grammar #
##########################
sub ShowRules {
    my($self)=shift;
    my($rules)=$$self{GRAMMAR}{RULES};
    my($ruleno)=-1;
    my($text);

    for (@$rules) {
        my($lhs,$rhs)=@$_;

        $text.=++$ruleno.":\t".$lhs." -> ";
        if(@$rhs) {
            $text.=join(' ',map { $_ eq chr(0) ? '$end' : $_ } @$rhs);
        }
        else {
            $text.="/* empty */";
        }
        $text.="\n";
    }
    $text;
}

sub give_default_name {
  my ($self, $index, $lhs) = @_;

  my $name = "$lhs"."_$index";
  return $name;
}

sub give_lhs_name {
  my ($self, $index, $lhs, $rhs) = @_;

  my $name = $lhs;
  return $name;
}

sub give_token_name {
  my ($self, $index, $lhs, $rhs) = @_;

  my @rhs = @$rhs;
  $rhs = '';

  unless (@rhs) { # Empty RHS
    return $lhs.'_is_empty';
  }

  my $names = $self->{GRAMMAR}{TOKENNAMES} || {};
  for (@rhs) {
    if ($self->is_token($_)) { 
      s/^'(.*)'$/$1/;
      my $name = $names->{$_} || '';
      unless ($name) {
        $name = $_ if /^\w+$/;
      }
      $rhs .= "_$name" if $name;
    }
  }

  unless ($rhs) { # no 'word' tokens in the RHS
    for (@rhs) {
      $rhs .= "_$_" if /^\w+$/;
    }
  }

  # check if another production with such name exists?
  my $name = $lhs.'_is'.$rhs;
  return $name;
}

sub camelize
{
    my $s = shift;

    my @a = split(/(?<=[A-Za-z])_(?=[A-Za-z])|\b/, $s);
    my $a = shift @a;
    @a = map { ucfirst $_ } @a;
    join('', ($a, @a));
}

sub give_rhs_name {
  my ($self, $index, $lhs, $rhs) = @_;

  my @rhs = @$rhs;
  $rhs = '';

  unless (@rhs) { # Empty RHS
    return camelize($lhs).'_is_empty';
  }

  my $names = $self->{GRAMMAR}{TOKENNAMES} || {};
  for (@rhs) {
    if ($self->is_token($_)) { 
      # remove apostrophes
      s/^'(.*)'$/$1/;

      # explicit name given ?
      my $name = $names->{$_} || '';

      # no name was given, use symbol if is an ID
      unless ($name) {
        $name = $_ if /^\w+$/;
      }
      $rhs .= "_$name" if $name;
    }
    else { # syntactic variable
      next if exists $self->{GRAMMAR}{CONFLICTHANDLERS}{$_};
      $rhs .= '_'.camelize($_) if /^\w*$/;
    }
  }

  # check if another production with such name exists?
  my $name = camelize($lhs).'_is'.$rhs;
  return $name;
}

sub classname {
  my ($self, $name, $index, $lhs, $rhs) = @_;

  $name = $name->[0];

  unless (defined($name)) {
    if ($lhs =~ /\$start/) {
      $name = "_SUPERSTART"
    }
    elsif ($lhs =~ /\@(\d+)-(\d+)/) {
      $name = "_CODE" 
    }
    elsif ($lhs =~ /PAREN-(\d+)/) {
      $name = "_PAREN" 
    }
    elsif ($lhs =~ /STAR-(\d+)/) {
      $name = "_STAR_LIST"
    }
    elsif ($lhs =~ /PLUS-(\d+)/) {
      $name = "_PLUS_LIST"
    }
    elsif ($lhs =~ /OPTIONAL-(\d+)/) {
      $name = "_OPTIONAL"
    }
  }

  my $naming_scheme = $self->{GRAMMAR}{NAMINGSCHEME};
  if (!$name) {
    $name = $naming_scheme->($self, $index, $lhs, $rhs);
  }
  elsif ($name =~ /^:/) { # it is a label only
    $name = $naming_scheme->($self, $index, $lhs, $rhs).$name;
  }

  return $name;
}

# Added by Casiano
#####################################
# Method To Return the Grammar Rules#
#####################################
sub Rules { # TODO: find proper names
    my($self)=shift;
    my($rules)=$$self{GRAMMAR}{RULES};
    my($text) = "[#[productionNameAndLabel => lhs, [ rhs], bypass]]\n";
    my $packages = q{'TERMINAL', '_OPTIONAL', '_STAR_LIST', '_PLUS_LIST', };

    my $index = 0;
    my $label = "{\n"; # To huild a reverse map label => production number
    for (@$rules) {
        my($lhs,$rhs,$prec,$name)=@$_;

        my $bypass = $name->[2];
        $bypass = $self->Bypass unless defined($bypass);

        $label .= "  '$1' => $index,\n" if defined($name->[0]) and $name->[0] =~ /(:.*)/;

        # find an acceptable perl identifier as name
        $name = $self->classname($name, $index, $lhs, $rhs);
        $label .= "  '$name' => $index,\n";

        $packages .= "\n".(" "x9)."'$name', ";

        $text.= "  [ '$name' => '$lhs', [ ";
        $text.=join(', ',map { $_ eq chr(0) ? "'\$end'" : $_ =~ m{^'} ? $_ : "'$_'" } @$rhs);
        $text.=" ], $bypass ],\n";
        $index++;
    }
    $text .= ']';
    $label .= '}';
    return ($text, $packages, $label);
}

# Added by Casiano
#####################################
# Method To Return the Grammar Terms#
#####################################
sub Terms {
    my($self)=shift;
    my(@terms)= sort(keys(%{$$self{GRAMMAR}{TERM}}));
    my %semantic = %{$self->{GRAMMAR}{SEMANTIC}};

    my $text = "{ ";
    $text .= join(",\n\t",
                         # Warning! bug. Before: map { $_ eq chr(0) ? "'\$end' => 0" : "$_ => $semantic{$_}"} @terms);
                         map { $_ eq chr(0) ? "'' => { ISSEMANTIC => 0 }" : "$_ => { ISSEMANTIC => $semantic{$_} }"} @terms); 
    $text .= ",\n\terror => { ISSEMANTIC => 0 },\n}";
}

sub conflictHandlers {
  my $self = shift;

  my $t = Dumper $self->{GRAMMAR}{CONFLICTHANDLERS};
  $t =~ s/^\$VAR\d*\s*=\s*//;
  $t =~s/;$//;
  $t =~s/\\'//g; # quotes inside quotes
  $t;
}


# produces the text mapping states to conflicthandlers
sub stateConflict {
  my $self = shift;

  my $c = $self->{GRAMMAR}{CONFLICTHANDLERS};
  my %stateConflict;

  my %t = ();
  for my $cn (keys %$c) {
    my $ce = $c->{$cn};
    my $codeh = $ce->{codeh};
    $codeh = "sub { $codeh }";
    my @s = defined($ce->{states}) ?  @{$ce->{states}} : ();
    for my $s (@s) {
        my ($sn) = keys %$s;
        #my ($tokens) = values %$s;
        #$tokens = join ',', @$tokens;
        $t{$sn} = '' unless defined($t{$sn});
        $t{$sn} .= << "NEWSTATECONFLICTENTRY";
                   { 
                      name => '$cn', 
                      codeh => $codeh,
                   },
NEWSTATECONFLICTENTRY
    } #for states
  } #for  conflict names
 
  my $t = '{ ';
  for my $s (keys %t) {
    $t .= "$s => [ $t{$s} ],";
  }
  $t .= ' }';
}

#####################################
# Method To Return the Bypass Option#
#####################################
sub Bypass {
  my($self)=shift;
    
  return  $$self{GRAMMAR}{BYPASS}
}

#####################################
# Method To Return the Prefix Option#
#####################################
sub Prefix {
  my($self)=shift;
    
  return  $$self{GRAMMAR}{PREFIX}
}


sub Buildingtree {
  my($self)=shift;
    
  return  $$self{GRAMMAR}{BUILDINGTREE}
}

sub Prompt {
  my $self = shift;

  return  "our \$PROMPT = $$self{GRAMMAR}{INCREMENTAL};\n" if defined($$self{GRAMMAR}{INCREMENTAL});
  return '';
}

sub is_token {
  my($self)=shift;

  exists($self->{GRAMMAR}{TERM}{$_[0]})
}

#####################################
# Method To Return the ACCESSORS
#####################################
sub Accessors {
  my($self)=shift;
    
  return  $$self{GRAMMAR}{ACCESSORS}
}

###########################
# Method To View Warnings #
###########################
sub Warnings {
    my($self)=shift;

    return '' if $self->Option('start');

    my($text) = '';
    my($grammar)=$$self{GRAMMAR};

        exists($$grammar{UUTERM})
    and    do {
            $text="Unused terminals:\n\n";
            for (@{$$grammar{UUTERM}}) {
                $text.="\t$$_[0], declared line $$_[1]\n";    
            }
        $text.="\n";
        };
        exists($$grammar{UUNTERM})
    and    do {
            $text.="Useless non-terminals:\n\n";
            for (@{$$grammar{UUNTERM}}) {
                $text.="\t$$_[0], declared line $$_[1]\n";    
            }
        $text.="\n";
        };
        exists($$grammar{UURULES})
    and    do {
            $text.="Useless rules:\n\n";
            for (@{$$grammar{UURULES}}) {
                $text.="\t$$_[0] -> ".join(' ',@{$$_[1]})."\n";    
            }
        $text.="\n";
        };
    $text;
}

######################################
# Method to get summary about parser #
######################################
sub Summary {
    my($self)=shift;
    my($text);

    $text ="Number of rules         : ".
            scalar(@{$$self{GRAMMAR}{RULES}})."\n";
    $text.="Number of terminals     : ".
            scalar(keys(%{$$self{GRAMMAR}{TERM}}))."\n";
    $text.="Number of non-terminals : ".
            scalar(keys(%{$$self{GRAMMAR}{NTERM}}))."\n";
    $text;
}

###############################
# Method to Ouput rules table #
###############################
sub RulesTable {
    my($self)=shift;
    my($inputfile)=$self->Option('inputfile');
    my($linenums)=$self->Option('linenumbers');
    my($rules)=$$self{GRAMMAR}{RULES};
    my $ruleno = 0;
    my($text);

        defined($inputfile)
    or  $inputfile = 'unknown';

    $text="[\n\t";

    $text.=join(",\n\t",
                map {
                    my($lhs,$rhs,$rname,$code)=@$_[0,1,3,4];
                    my($len)=scalar(@$rhs);

                    my($text);

                    $rname = $self->classname($rname, $ruleno, $lhs, $rhs);

                    $ruleno++;
                    $text.="[#Rule $rname\n\t\t '$lhs', $len,";
                    if($code) {
                        $text.= "\nsub {".
                                (  $linenums
                                 ? qq(\n#line $$code[1] "$inputfile"\n)
                                 : " ").
                                "$$code[0]}";
                    }
                    else {
                        $text.=' undef';
                    }
                    $text.="\n$Parse::Eyapp::Output::pattern\n\t]";

                    $text;
                } @$rules);

    $text.="\n]";

    $text;
}

################################
# Methods to get HEAD and TAIL #
################################
sub Head {
    my($self)=shift;
    my($inputfile)=$self->Option('inputfile');
    my($linenums)=$self->Option('linenumbers');
    my($text);

        $$self{GRAMMAR}{HEAD}[0]
    or  return '';

        defined($inputfile)
    or  $inputfile = 'unkown';

    for (@{$$self{GRAMMAR}{HEAD}}) {
            $linenums
        and $text.=qq(#line $$_[1] "$inputfile"\n);
        $text.=$$_[0];
    }
    $text
}

sub Tail {
    my($self)=shift;
    my($inputfile)=$self->Option('inputfile');
    my($linenums)=$self->Option('linenumbers');
    my($text);

        ((reftype $$self{GRAMMAR}{TAIL} eq 'ARRAY') and 
        $$self{GRAMMAR}{TAIL}[0])
    or  return '';

        defined($inputfile)
    or  $inputfile = 'unkown';

        $linenums
    and $text=qq(#line $$self{GRAMMAR}{TAIL}[1] "$inputfile"\n);
    $text.=$$self{GRAMMAR}{TAIL}[0];

    $text
}


#################
# Private Stuff #
#################

sub _UsefulRules {
    my($rules,$nterm) = @_;
    my($ufrules,$ufnterm);
    my($done);

    $ufrules=pack('b'.@$rules);
    $ufnterm={};

    vec($ufrules,0,1)=1;    #start rules IS always useful

    RULE:
    for (1..$#$rules) { # Ignore start rule
        for my $sym (@{$$rules[$_][1]}) {
                exists($$nterm{$sym})
            and next RULE;
        }
        vec($ufrules,$_,1)=1;
        ++$$ufnterm{$$rules[$_][0]};
    }

    do {
        $done=1;

        RULE:
        for (grep { vec($ufrules,$_,1) == 0 } 1..$#$rules) {
            for my $sym (@{$$rules[$_][1]}) {
                    exists($$nterm{$sym})
                and not exists($$ufnterm{$sym})
                and next RULE;
            }
            vec($ufrules,$_,1)=1;
                exists($$ufnterm{$$rules[$_][0]})
            or  do {
                $done=0;
                ++$$ufnterm{$$rules[$_][0]};
            };
        }

    }until($done);

    ($ufrules,$ufnterm)

}#_UsefulRules

sub _Reachable {
    my($rules,$nterm,$term,$ufrules,$ufnterm)=@_;
    my($reachable);
    my(@fifo)=( 0 );

    $reachable={ '$start' => 1 }; #$start is always reachable

    while(@fifo) {
        my($ruleno)=shift(@fifo);

        for my $sym (@{$$rules[$ruleno][1]}) {

                exists($$term{$sym})
            and do {
                ++$$reachable{$sym};
                next;
            };

                (   not exists($$ufnterm{$sym})
                 or exists($$reachable{$sym}) )
            and next;

            ++$$reachable{$sym};
            push(@fifo, grep { vec($ufrules,$_,1) } @{$$nterm{$sym}});
        }
    }

    $reachable

}#_Reachable

sub _SetNullable {
    my($rules,$term,$nullable) = @_;
    my(@nrules);
    my($done);

    RULE:
    for (@$rules) {
        my($lhs,$rhs)=@$_;

            exists($$nullable{$lhs})
        and next;

        for (@$rhs) {
                exists($$term{$_})
            and next RULE;
        }
        push(@nrules,[$lhs,$rhs]);
    }

    do {
        $done=1;

        RULE:
        for (@nrules) {
            my($lhs,$rhs)=@$_;

                    exists($$nullable{$lhs})
                and next;

                for (@$rhs) {
                        exists($$nullable{$_})
                    or  next RULE;
                }
            $done=0;
            ++$$nullable{$lhs};
        }

    }until($done);
}

sub _ReduceGrammar {
    my($values)=@_;
    my($ufrules,$ufnterm,$reachable);

    my($grammar)= bless { 
                   HEAD => $values->{HEAD},
                   TAIL => $values->{TAIL},
                   EXPECT => $values->{EXPECT},
                   # Casiano modifications
                   SEMANTIC          => $values->{SEMANTIC},          # added to simplify AST
                   BYPASS            => $values->{BYPASS},            # added to simplify AST
                   BUILDINGTREE      => $values->{BUILDINGTREE},      # influences the semantic of lists * + ?
                   ACCESSORS         => $values->{ACCESSORS},         # getter-setter for %tree and %metatree
                   PREFIX            => $values->{PREFIX},            # yyprefix
                   NAMINGSCHEME      => $values->{NAMINGSCHEME},      # added to allow programmable production naming schemes (%name)
                   NOCOMPACT         => $values->{NOCOMPACT},         # Do not compact action tables. No DEFAULT field for "STATES"
                   CONFLICTHANDLERS  => $values->{CONFLICTHANDLERS},  # list of conflict handlers
                   TERMDEF           => $values->{TERMDEF},           # token => associated regular expression (for lexical analyzer)
                   WHITES            => $values->{WHITES},            # string with the code to skip whites (for lexical analyzer)
                   LEXERISDEFINED    => $values->{LEXERISDEFINED},    # true if %lexer was used
                   INCREMENTAL       => $values->{INCREMENTAL},       # true if '%incremental lexer' was used
                   MODULINO          => $values->{MODULINO},          # hash perlpath => path, prompt => question
                   STRICT            => $values->{STRICT},            # true if %stric
                   DUMMY             => $values->{DUMMY},             # array ref 
                   TOKENNAMES     => {},                              # for naming schemes
                 }, __PACKAGE__;

    my($rules,$nterm,$term) =  @$values {'RULES', 'NTERM', 'TERM'};

    ($ufrules,$ufnterm) = _UsefulRules($rules,$nterm);

        exists($$ufnterm{$values->{START}})
    or  die "*Fatal* Start symbol $values->{START} derives nothing, at eof\n";

    $reachable = _Reachable($rules,$nterm,$term,$ufrules,$ufnterm);

    $$grammar{TERM}{chr(0)}=undef;
    for my $sym (keys %$term) {
            (   exists($$reachable{$sym})
             or exists($values->{PREC}{$sym}) )
        and do {
            $$grammar{TERM}{$sym}
                = defined($$term{$sym}[0]) ? $$term{$sym} : undef;
            next;
        };
        push(@{$$grammar{UUTERM}},[ $sym, $values->{SYMS}{$sym} ]);
    }

    $$grammar{NTERM}{'$start'}=[];
    for my $sym (keys %$nterm) {
            exists($$reachable{$sym})
        and do {
                exists($values->{NULL}{$sym})
            and ++$$grammar{NULLABLE}{$sym};
            $$grammar{NTERM}{$sym}=[];
            next;
        };
        push(@{$$grammar{UUNTERM}},[ $sym, $values->{SYMS}{$sym} ]);
    }

    for my $ruleno (0..$#$rules) {
            vec($ufrules,$ruleno,1)
        and exists($$grammar{NTERM}{$$rules[$ruleno][0]})
        and do {
            push(@{$$grammar{RULES}},$$rules[$ruleno]);
            push(@{$$grammar{NTERM}{$$rules[$ruleno][0]}},$#{$$grammar{RULES}});
            next;
        };
        push(@{$$grammar{UURULES}},[ @{$$rules[$ruleno]}[0,1] ]);
    }

    _SetNullable(@$grammar{'RULES', 'TERM', 'NULLABLE'});

    $grammar;
}#_ReduceGrammar

sub tokennames {
  my $self = shift;

  my $grammar = $self->{GRAMMAR};
  $grammar->{TOKENNAMES} = { (%{$grammar->{TOKENNAMES}}, @_) } if (@_);
  $grammar->{TOKENNAMES}
}

1;

