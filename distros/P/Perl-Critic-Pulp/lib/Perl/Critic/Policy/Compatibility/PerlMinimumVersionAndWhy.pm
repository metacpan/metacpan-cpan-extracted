# Copyright 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2019, 2021 Kevin Ryde

# Perl-Critic-Pulp is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Perl-Critic-Pulp is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Perl-Critic-Pulp.  If not, see <http://www.gnu.org/licenses/>.

package Perl::Critic::Policy::Compatibility::PerlMinimumVersionAndWhy;
use 5.006;
use strict;
use warnings;
use version (); # but don't import qv()

# 1.208 for PPI::Token::QuoteLike::Regexp get_modifiers()
use PPI 1.208;

# 1.084 for Perl::Critic::Document highest_explicit_perl_version()
use Perl::Critic::Policy 1.084;
use base 'Perl::Critic::Policy';
use Perl::Critic::Utils qw(parse_arg_list);
use Perl::Critic::Pulp::Utils;

# uncomment this to run the ### lines
# use Smart::Comments;

our $VERSION = 99;

use constant supported_parameters =>
  ({ name        => 'above_version',
     description => 'Check only things above this version of Perl.',
     behavior    => 'string',
     parser      => \&Perl::Critic::Pulp::Utils::parameter_parse_version,
   },
   { name        => 'skip_checks',
     description => 'Version checks to skip (space separated list).',
     behavior    => 'string',
   });
use constant default_severity => $Perl::Critic::Utils::SEVERITY_LOW;
use constant default_themes   => qw(pulp compatibility);
use constant applies_to       => 'PPI::Document';


sub initialize_if_enabled {
  my ($self, $config) = @_;
  # ask that Perl::MinimumVersion is available and still has its
  # undocumented %CHECKS to mangle below
  eval { require Perl::MinimumVersion;
         scalar %Perl::MinimumVersion::CHECKS }
    or return 0;

  _setup_extra_checks();
}

sub violates {
  my ($self, $document) = @_;

  my %skip_checks;
  if (defined (my $skip_checks = $self->{_skip_checks})) {
    @skip_checks{split / /, $self->{_skip_checks}} = (); # hash slice
  }

  my $pmv = Perl::MinimumVersion->new ($document);
  my $config_above_version = $self->{'_above_version'};
  my $explicit_version = _highest_explicit_perl_version($document);

  my @violations;
  foreach my $check (sort keys %Perl::MinimumVersion::CHECKS) {
    next if exists $skip_checks{$check};
    next if $check eq '_constant_hash'; # better by ConstantPragmaHash
    # next if $check =~ /_pragmas$/;  # usually impossible in earlier
    next if $check =~ /_modules$/;  # wrong for dual-life stuff

    my $check_version = $Perl::MinimumVersion::CHECKS{$check};
    next if (defined $explicit_version
             && $check_version <= $explicit_version);
    next if (defined $config_above_version
             && $check_version <= $config_above_version);
    ### $check

    my $elem = do {
      no warnings 'redefine';
      local *PPI::Node::find_any = \&PPI::Node::find_first;
      $pmv->$check
    } || next;
    #     require Data::Dumper;
    #     print Data::Dumper::Dumper($elem);
    #     print $elem->location,"\n";
    push @violations,
      $self->violation ("$check requires $check_version",
                        '',
                        $elem);
  }
  return @violations;
}

my $v5010 = version->new('5.010');

# Some controversy:
#   https://github.com/Perl-Critic/Perl-Critic/issues/270
#   http://elliotlovesperl.com/2009/05/17/the-problem-with-modernperl/
#
sub _highest_explicit_perl_version {
  my ($document) = @_;
  ### _highest_explicit_perl_version() ...
  my $ver = $document->highest_explicit_perl_version;
  if ($ver < $v5010
      && Perl::Critic::Policy::Compatibility::Gtk2Constants::_document_uses_module($document,'Modern::Perl')) {
    ### increase to 5.010 ...
    $ver = $v5010;
  }
  return $ver;
}


#---------------------------------------------------------------------------
# Crib note: $document->find_first wanted func returning undef means the
# element is unwanted and also don't descend into its sub-elements.
#

sub _setup_extra_checks {

  # 5.12.0
  my $v5012 = version->new('5.012');
  $Perl::MinimumVersion::CHECKS{_Pulp__keys_of_array}   = $v5012;
  $Perl::MinimumVersion::CHECKS{_Pulp__values_of_array} = $v5012;
  $Perl::MinimumVersion::CHECKS{_Pulp__each_of_array}   = $v5012;

  # 5.10.0
  unless (eval { Perl::MinimumVersion->VERSION(1.28); 1 }) {
    # fixed in 1.28 up
    $Perl::MinimumVersion::CHECKS{_Pulp__5010_magic__fix}     = $v5010;
    $Perl::MinimumVersion::CHECKS{_Pulp__5010_operators__fix} = $v5010;
  }
  $Perl::MinimumVersion::CHECKS{_Pulp__5010_qr_m_propagate_properly} = $v5010;
  $Perl::MinimumVersion::CHECKS{_Pulp__5010_stacked_filetest} = $v5010;

  # 5.8.0
  my $v5008 = version->new('5.008');
  $Perl::MinimumVersion::CHECKS{_Pulp__fat_comma_across_newline} = $v5008;
  $Perl::MinimumVersion::CHECKS{_Pulp__eval_line_directive_first_thing} = $v5008;

  # 5.6.0
  my $v5006 = version->new('5.006');
  $Perl::MinimumVersion::CHECKS{_Pulp__exists_subr}       = $v5006;
  $Perl::MinimumVersion::CHECKS{_Pulp__exists_array_elem} = $v5006;
  $Perl::MinimumVersion::CHECKS{_Pulp__delete_array_elem} = $v5006;
  $Perl::MinimumVersion::CHECKS{_Pulp__0b_number}         = $v5006;
  $Perl::MinimumVersion::CHECKS{_Pulp__syswrite_length_optional} = $v5006;
  $Perl::MinimumVersion::CHECKS{_Pulp__open_my_filehandle} = $v5006;
  $Perl::MinimumVersion::CHECKS{_Pulp__var_method_without_parens} = $v5006;

  # 5.005
  my $v5005 = version->new('5.005');
  unless (exists
          $Perl::MinimumVersion::CHECKS{_bareword_ends_with_double_colon}) {
    # adopted into Perl::MinimumVersion 1.28
    $Perl::MinimumVersion::CHECKS{_Pulp__bareword_double_colon} = $v5005;
  }
  $Perl::MinimumVersion::CHECKS{_Pulp__my_list_with_undef} = $v5005;

  # 5.004
  my $v5004 = version->new('5.004');
  $Perl::MinimumVersion::CHECKS{_Pulp__special_literal__PACKAGE__} = $v5004;
  $Perl::MinimumVersion::CHECKS{_Pulp__use_version_number}         = $v5004;
  $Perl::MinimumVersion::CHECKS{_Pulp__for_loop_variable_using_my} = $v5004;
  $Perl::MinimumVersion::CHECKS{_Pulp__arrow_coderef_call}         = $v5004;
  $Perl::MinimumVersion::CHECKS{_Pulp__sysseek_builtin}            = $v5004;

  # UNIVERSAL.pm
  $Perl::MinimumVersion::CHECKS{_Pulp__UNIVERSAL_methods_5004} = $v5004;
  $Perl::MinimumVersion::CHECKS{_Pulp__UNIVERSAL_methods_5010} = $v5010;

  # pack()/unpack()
  $Perl::MinimumVersion::CHECKS{_Pulp__pack_format_5004} = $v5004;
  $Perl::MinimumVersion::CHECKS{_Pulp__pack_format_5006} = $v5006;
  $Perl::MinimumVersion::CHECKS{_Pulp__pack_format_5008} = $v5008;
  $Perl::MinimumVersion::CHECKS{_Pulp__pack_format_5010} = $v5010;
}

{
  # Perl::MinimumVersion prior to 1.28 had 'PPI::Token::Operator' and
  # 'PPI::Token::Magic' swapped between the respective operator/magic tests

  package Perl::MinimumVersion;
  use vars qw(%MATCHES);
  sub _Pulp__5010_operators__fix {
    shift->Document->find_first
      (sub {
         $_[1]->isa('PPI::Token::Operator')
           and
             $MATCHES{_perl_5010_operators}->{$_[1]->content};
           } );
  }
  sub _Pulp__5010_magic__fix {
    shift->Document->find_first
      (sub {
         $_[1]->isa('PPI::Token::Magic')
           and
             $MATCHES{_perl_5010_magic}->{$_[1]->content};
           } );
  }
}

sub Perl::MinimumVersion::_Pulp__5010_qr_m_propagate_properly {
  my ($pmv) = @_;
  ### _Pulp__5010_qr_m_propagate_properly() check ...
  $pmv->Document->find_first
    (sub {
       my ($document, $elem) = @_;
       $elem->isa('PPI::Token::QuoteLike::Regexp') || return 0;
       my %modifiers = $elem->get_modifiers;
       ### content: $elem->content
       ### modifiers: \%modifiers
       return ($modifiers{'m'} ? 1 : 0);
     });
}

# new in 5.010 as described in perlfunc.pod
sub Perl::MinimumVersion::_Pulp__5010_stacked_filetest {
  my ($pmv) = @_;
  ### _Pulp__5010_stacked_filetest() check ...
  $pmv->Document->find_first
    (sub {
       my ($document, $elem) = @_;
       return (_elem_is_filetest_operator($elem)     # -X
               && ($elem = $elem->snext_sibling)     # has a next sibling
               && _elem_is_filetest_operator($elem)  # -X
               ? 1 : 0);
     });
}
# $elem is a PPI::Element
# Return true if it's a -X operator.
sub _elem_is_filetest_operator {
  my ($elem) = @_;
  return ($elem->isa('PPI::Token::Operator')
          && $elem =~ /^-./);
}


#-----------------------------------------------------------------------------
# foo \n => fat comma across newline new in 5.8.0
# extra code in 5.8 toke.c under comment "not a keyword" checking for =>
#

sub Perl::MinimumVersion::_Pulp__fat_comma_across_newline {
  my ($pmv) = @_;
  ### _Pulp__fat_comma_across_newline() check
  $pmv->Document->find_first
    (sub {
       my ($document, $elem) = @_;
       ### elem: "$elem"
       if ($elem->isa('PPI::Token::Operator')
           && $elem->content eq '=>') {
         my ($prev, $saw_newline) = sprevious_sibling_and_newline($elem);
         ### prev: "$prev"
         ### $saw_newline
         if ($saw_newline
             && $prev
             && $prev->isa('PPI::Token::Word')
             && $prev !~ /^-/   # -foo self-quotes
             && ! Perl::Critic::Utils::is_method_call($prev)) { # ->foo
           return 1; # found
         }
       }
       return 0; # continue searching
     });
}

sub sprevious_sibling_and_newline {
  my ($elem) = @_;
  ### sprevious_sibling_and_newline()
  my $saw_newline;
  for (;;) {
    $elem = $elem->previous_sibling || last;
    if ($elem->isa('PPI::Token::Whitespace')) {
      $saw_newline ||= ($elem->content =~ /\n/);
    } elsif ($elem->isa('PPI::Token::Comment')) {
      $saw_newline = 1;
    } else {
      last;
    }
  }
  return ($elem, $saw_newline);
}

#-----------------------------------------------------------------------------

# delete $array[0] and exists $array[0] new in 5.6.0
# two functions so the "exists" or "delete" appears in the check name
#
sub Perl::MinimumVersion::_Pulp__exists_array_elem {
  my ($pmv) = @_;
  ### _Pulp__exists_array_elem() check
  return _exists_or_delete_array_elem ($pmv, 'exists');
}
sub Perl::MinimumVersion::_Pulp__delete_array_elem {
  my ($pmv) = @_;
  ### _Pulp__delete_array_elem() check
  return _exists_or_delete_array_elem ($pmv, 'delete');
}
sub _exists_or_delete_array_elem {
  my ($pmv, $which) = @_;
  ### _exists_or_delete_array_elem()
  $pmv->Document->find_first
    (sub {
       my ($document, $elem) = @_;
       if ($elem->isa('PPI::Token::Word')
           && $elem eq $which
           && Perl::Critic::Utils::is_function_call($elem)
           && _arg_is_array_elem($elem->snext_sibling)) {
         return 1;
       } else {
         return 0;
       }
     });
}
sub _arg_is_array_elem {
  my ($elem) = @_;
  ### _arg_is_array_elem: "$elem"

  (($elem = _descend_through_lists($elem))
   && $elem->isa('PPI::Token::Symbol')
   && $elem->raw_type eq '$'
   && ($elem = $elem->snext_sibling))
    or return 0;

  my $ret = 0;
  for (;;) {
    if ($elem->isa('PPI::Structure::Subscript')) {
      # adjacent $x{key}[123]
      $ret = ($elem->start eq '[');
    } elsif ($elem->isa('PPI::Structure::List')) {
      # $x[0]->() function call
      return 0;
    } elsif ($elem->isa('PPI::Token::Operator')
             && $elem eq '->') {
      # subscript ->, continue
    } else {
      # anything else below -> precedence, stop
      last;
    }
    $elem = $elem->snext_sibling || last;
  }
  ### $ret
  return $ret;
}

sub _descend_through_lists {
  my ($elem) = @_;
  while ($elem
         && ($elem->isa('PPI::Structure::List')
        || $elem->isa('PPI::Statement::Expression')
             || $elem->isa('PPI::Statement'))) {
    $elem = $elem->schild(0);
  }
  return $elem;
}

# exists(&subr) new in 5.6.0
#
sub Perl::MinimumVersion::_Pulp__exists_subr {
  my ($pmv) = @_;
  ### _Pulp__exists_subr() check
  $pmv->Document->find_first
    (sub {
       my ($document, $elem) = @_;
       if ($elem->isa('PPI::Token::Word')
           && $elem eq 'exists'
           && Perl::Critic::Utils::is_function_call($elem)
           && ($elem = _symbol_or_list_symbol($elem->snext_sibling))
           && $elem->symbol_type eq '&') {
         return 1;
       } else {
         return 0;
       }
     });
}

# 0b110011 binary literals new in 5.6.0
#
sub Perl::MinimumVersion::_Pulp__0b_number {
  my ($pmv) = @_;
  ### _Pulp__0b_number() check
  $pmv->Document->find_first
    (sub {
       my ($document, $elem) = @_;
       if ($elem->isa('PPI::Token::Number::Binary')) {
         return 1;
       } else {
         return 0;
       }
     });
}

# syswrite($fh,$str) length optional in 5.6.0
#
sub Perl::MinimumVersion::_Pulp__syswrite_length_optional {
  my ($pmv) = @_;
  ### _Pulp__syswrite_length_optional() check
  $pmv->Document->find_first
    (sub {
       my ($document, $elem) = @_;
       my @args;
       if ($elem->isa('PPI::Token::Word')
           && $elem eq 'syswrite'
           && Perl::Critic::Utils::is_function_call($elem)
           && (@args = Perl::Critic::Utils::parse_arg_list($elem)) == 2) {
         return 1;
       } else {
         return 0;
       }
     });
}

# open(my $fh,...) auto-creating a handle glob new in 5.6.0
#
my %open_func = (open       => 1,
                 opendir    => 1,
                 pipe       => 2,
                 socketpair => 2,
                 sysopen    => 1,
                 socket     => 1,
                 accept     => 1);
sub Perl::MinimumVersion::_Pulp__open_my_filehandle {
  my ($pmv) = @_;
  ### _Pulp__open_my_filehandle() check
  $pmv->Document->find_first
    (sub {
       my ($document, $elem) = @_;
       my ($count, $my, $fh);
       unless ($elem->isa('PPI::Token::Word')
               && ($count = $open_func{$elem})
               && Perl::Critic::Utils::is_function_call($elem)) {
         return 0;
       }
       $my = $elem->snext_sibling;

       # with parens is
       #   PPI::Token::Word         'open'
       #    PPI::Structure::List    ( ... )
       #      PPI::Statement::Variable
       #       PPI::Token::Word     'my'
       #       PPI::Token::Symbol   '$fh'
       #       PPI::Token::Operator         ','
       #
       if ($my->isa('PPI::Structure::List')) {
         $my = $my->schild(0) || return 0;
       }
       if ($my->isa('PPI::Statement::Variable')) {
         $my = $my->schild(0) || return 0;
       }

       foreach (1 .. $count) {
         ### my: "$my"
         if (_is_uninitialized_my($my)) {
           return 1;
         }
         $my = _skip_to_next_arg($my) || last;
       }
       return 0;
     });
}

sub _is_uninitialized_my {
  my ($my) = @_;
  my ($fh, $after);
  return ($my->isa('PPI::Token::Word')
          && $my eq 'my'
          && ($fh = $my->snext_sibling)
          && $fh->isa('PPI::Token::Symbol')
          && $fh->symbol_type eq '$'
          && ! (($after = $fh->snext_sibling)
                && $after->isa('PPI::Token::Operator')
                && $after eq '='));
}

# FIXME: is this enough for prototyped funcalls in the args?
sub _skip_to_next_arg {
  my ($elem) = @_;
  for (;;) {
    my $next = $elem->snext_sibling || return undef;
    if ($elem->isa('PPI::Token::Operator')
        && $Perl::Critic::Pulp::Utils::COMMA{$elem}) {
      return $next;
    }
    $elem = $next;
  }
}

# $obj->$method; omit parens new in 5.6.0
# previously required parens like $obj->$method();
#
sub Perl::MinimumVersion::_Pulp__var_method_without_parens {
  my ($pmv) = @_;
  ### _Pulp__var_method_without_parens() ...
  $pmv->Document->find_first
    (sub {
       my ($document, $elem) = @_;
       my $next;
       if ($elem->isa('PPI::Token::Symbol')
           && $elem->symbol_type eq '$'
           && Perl::Critic::Utils::is_method_call($elem)
           # must be followed by "()" for earlier perl, so if not then it
           # means 5.6.0 required
           && ! (($next = $elem->snext_sibling)
                 && $next->isa('PPI::Structure::List'))) {
         return 1;
       } else {
         return 0;
       }
     });
}

#-----------------------------------------------------------------------------
# Foo::Bar:: bareword new in 5.005
# generally a compile-time syntax error in 5.004
#
sub Perl::MinimumVersion::_Pulp__bareword_double_colon {
  my ($pmv) = @_;
  ### _Pulp__bareword_double_colon() check
  $pmv->Document->find_first
    (sub {
       my ($document, $elem) = @_;
       if ($elem->isa('PPI::Token::Word')
           && $elem =~ /::$/) {
         return 1;
       } else {
         return 0;
       }
     });
}

# my ($x, undef, $y), undef in a my() list new in 5.005
# usually something like my (undef, $x) = @values
#
sub Perl::MinimumVersion::_Pulp__my_list_with_undef {
  my ($pmv) = @_;
  ### _Pulp__my_list_with_undef() check
  $pmv->Document->find_first
    (sub {
       my ($document, $elem) = @_;
       if ($elem->isa('PPI::Token::Word')
           && $elem eq 'my'
           && _list_contains_undef ($elem->snext_sibling)) {
         return 1;
       } else {
         return 0;
       }
     });
}

# $elem is a PPI::Element or false
# return true if it's a list and there's an 'undef' element in the list
#
#     PPI::Structure::List    ( ... )
#       PPI::Statement::Expression
#         PPI::Token::Symbol   '$x'
#         PPI::Token::Operator         ','
#         PPI::Token::Word     'undef'
#         PPI::Token::Operator         ','
#         PPI::Token::Symbol   '$y'
#
# Or for multi-parens: my ((undef)) with PPI::Statement in the middle
#
#     PPI::Structure::List    ( ... )
#       PPI::Statement
#         PPI::Structure::List        ( ... )
#           PPI::Statement::Expression
#            PPI::Token::Word         'undef'
#
sub _list_contains_undef {
  my ($elem) = @_;
  ### _list_contains_undef: "$elem"
  $elem or return;
  $elem->isa('PPI::Structure::List') or return;
  my @search = ($elem);
  while (@search) {
    $elem = pop @search;
    ### elem: "$elem"
    if ($elem->isa('PPI::Structure::List')
        || $elem->isa('PPI::Statement::Expression')
        || $elem->isa('PPI::Statement')) {
      push @search, $elem->schildren;
    } elsif ($elem->isa('PPI::Token::Word')
             && $elem eq 'undef') {
      return 1;
    }
  }
}


#-----------------------------------------------------------------------------
# pack() / unpack()
#
# Nothing new in 5.12, nothing new in 5.14.

sub Perl::MinimumVersion::_Pulp__pack_format_5004 {
  my ($pmv) = @_;
  # w - BER integer
  return _pack_format ($pmv, qr/w/);
}
sub Perl::MinimumVersion::_Pulp__pack_format_5006 {
  my ($pmv) = @_;
  # Z - asciz
  # q - signed quad
  # Q - unsigned quad
  # ! - native size
  # / - counted string
  # # - comment
 return _pack_format ($pmv, qr{[ZqQ!/#]});
}
sub Perl::MinimumVersion::_Pulp__pack_format_5008 {
  my ($pmv) = @_;
  # F - NV
  # D - long double
  # j - IV
  # J - UV
  # ( - group
  # [ - in a repeat count like "L[20]"
  return _pack_format ($pmv, qr/[FDjJ([]/);
}
sub Perl::MinimumVersion::_Pulp__pack_format_5010 {
  my ($pmv) = @_;
  # < - little endian
  # > - big endian
  return _pack_format ($pmv, qr/[<>]/);
}
# Think nothing new in 5012 ...

my %pack_func = (pack => 1, unpack => 1);
sub _pack_format {
  my ($pmv, $regexp) = @_;
  require Perl::Critic::Policy::Miscellanea::TextDomainPlaceholders;
  $pmv->Document->find_first
    (sub {
       my ($document, $elem) = @_;

       $elem->isa ('PPI::Token::Word') || return 0;
       $pack_func{$elem->content} || return 0;
       Perl::Critic::Utils::is_function_call($elem) || return 0;

       my @args = parse_arg_list ($elem);
       my $format_arg = $args[0];
       ### format: @$format_arg

       my ($str, $any_vars) = Perl::Critic::Policy::Miscellanea::TextDomainPlaceholders::_arg_string ($format_arg, $document);
       ### $str
       ### $any_vars

       if ($any_vars) { return 0; }
       return ($str =~ $regexp);
     });
}

# 5.004 new __PACKAGE__
#
sub Perl::MinimumVersion::_Pulp__special_literal__PACKAGE__ {
  my ($pmv) = @_;
  ### _Pulp__special_literal__PACKAGE__
  $pmv->Document->find_first
    (sub {
       my ($document, $elem) = @_;
       if ($elem->isa('PPI::Token::Word')
           && $elem eq '__PACKAGE__'
           && ! Perl::Critic::Utils::is_hash_key($elem)) {
         return 1;
       } else {
         return 0;
       }
     });
}

# 5.004 new "use VERSION"
#
# "use MODULE VERSION" is not as easy, fairly sure it depends whether the
# target module uses Exporter.pm or not since the VERSION part is passed to
# import() and Exporter.pm checks it.
#
sub Perl::MinimumVersion::_Pulp__use_version_number {
  my ($pmv) = @_;
  ### _Pulp__use_version_number
  $pmv->Document->find_first
    (sub {
       my ($document, $elem) = @_;
       $elem->isa('PPI::Statement::Include') or return 0;
       $elem->type eq 'use' or return 0;
       if ($elem->version ne '') {  # empty string '' for not a "use VERSION"
         return 1;
       } else {
         return 0;
       }
     });
}

# 5.004 new "foreach my $i" lexical loop variable
#
sub Perl::MinimumVersion::_Pulp__for_loop_variable_using_my {
  my ($pmv) = @_;
  ### _Pulp__for_loop_variable_using_my
  $pmv->Document->find_first
    (sub {
       my ($document, $elem) = @_;
       $elem->isa('PPI::Statement::Compound') or return 0;
       $elem->type eq 'foreach' or return 0;
       my $second = $elem->schild(1) || return 0;
       $second->isa('PPI::Token::Word') or return 0;
       if ($second eq 'my') {
         return 1;
       } else {
         return 0;
       }
     });
}

# 5.004 new "$foo->(PARAMS)" coderef call
#
sub Perl::MinimumVersion::_Pulp__arrow_coderef_call {
  my ($pmv) = @_;
  ### _Pulp__arrow_coderef_call
  $pmv->Document->find_first
    (sub {
       my ($document, $elem) = @_;
       $elem->isa('PPI::Token::Operator') or return 0;
       ### operator: "$elem"
       $elem eq '->' or return 0;
       $elem = $elem->snext_sibling || return 0;
       ### next: "$elem"
       if ($elem->isa('PPI::Structure::List')) {
         return 1;
       } else {
         return 0;
       }
     });
}

# 5.004 new sysseek() function
#
# Crib note: the prototype() function is newly documented in 5.004 but
# existed earlier, or something.  Might have returned a trailing "\0" in
# 5.003.
#
sub Perl::MinimumVersion::_Pulp__sysseek_builtin {
  my ($pmv) = @_;
  ### _Pulp__sysseek_builtin
  $pmv->Document->find_first
    (sub {
       my ($document, $elem) = @_;
       if ($elem->isa('PPI::Token::Word')
           && ($elem eq 'sysseek' || $elem eq 'CORE::sysseek')
           && Perl::Critic::Utils::is_function_call ($elem)) {
         return 1;
       } else {
         return 0;
       }
     });
}


#---------------------------------------------------------------------------
# UNIVERSAL.pm methods
#
{
  my $methods = { VERSION => 1,
                  isa     => 1,
                  can     => 1 };
  sub Perl::MinimumVersion::_Pulp__UNIVERSAL_methods_5004 {
    my ($pmv) = @_;
    ### _Pulp__UNIVERSAL_methods_5004() ...
    return _any_method($pmv,$methods);
  }
}
{
  my $methods = { DOES => 1 };
  sub Perl::MinimumVersion::_Pulp__UNIVERSAL_methods_5010 {
    my ($pmv) = @_;
    ### _Pulp__UNIVERSAL_methods_5010() ...
    return _any_method($pmv,$methods);
  }
}
sub _any_method {
  my ($pmv, $hash) = @_;
  $pmv->Document->find_first
    (sub {
       my ($document, $elem) = @_;
       if ($elem->isa('PPI::Token::Word')
           && $hash->{$elem}
           && Perl::Critic::Utils::is_method_call ($elem)) {
         return 1;
       } else {
         return 0;
       }
     });
}


#------------------------------------------------------------------------------
# keys @foo, values @foo, each @foo new in 5.12.0
#
sub Perl::MinimumVersion::_Pulp__keys_of_array {
  my ($pmv) = @_;
  return _keys_etc_of_array ($pmv, 'keys');
}
sub Perl::MinimumVersion::_Pulp__values_of_array {
  my ($pmv) = @_;
  return _keys_etc_of_array ($pmv, 'values');
}
sub Perl::MinimumVersion::_Pulp__each_of_array {
  my ($pmv) = @_;
  return _keys_etc_of_array ($pmv, 'each');
}
sub _keys_etc_of_array {
  my ($pmv, $which) = @_;
  ### _keys_etc_of_array() ...
  $pmv->Document->find_first
    (sub {
       my ($document, $elem) = @_;
       if ($elem->isa('PPI::Token::Word')
           && $elem eq $which
           && Perl::Critic::Utils::is_function_call($elem)
           && _arg_is_array($elem->snext_sibling)) {
         return 1;
       } else {
         return 0;
       }
     });
}
sub _arg_is_array {
  my ($elem) = @_;
  ### _arg_is_array "$elem"

  $elem = _descend_through_lists($elem) || return 0;

  if ($elem->isa('PPI::Token::Symbol')
      && $elem->raw_type eq '@') {
    return 1;
  }
  if ($elem->isa('PPI::Token::Cast') && $elem eq '@') {
    return 1;
  }
  return 0;
}


#------------------------------------------------------------------------------
# eval '#line ...' with the #line the very first thing,
# the #line doesn't take effect until 5.008,
# in 5.006 need a blank line or something first

{
  my $initial_line_re = qr/^#[ \t]*line/;

  sub Perl::MinimumVersion::_Pulp__eval_line_directive_first_thing {
    my ($pmv) = @_;
    ### _Pulp__eval_line_directive_first_thing() ...
    $pmv->Document->find_first
      (sub {
         my ($document, $elem) = @_;
         if ($elem->isa('PPI::Token::Word')
             && $elem eq 'eval'
             && Perl::Critic::Utils::is_function_call($elem)
             && ($elem = $elem->snext_sibling)
             && ($elem = _descend_through_lists($elem))) {
           ### eval of: "$elem"

           if ($elem->isa('PPI::Token::Quote')) {
             if ($elem->string =~ $initial_line_re) {
               return 1;
             }
           } elsif ($elem->isa('PPI::Token::HereDoc')) {
             my ($str) = $elem->heredoc; # first line
             if ($str =~ $initial_line_re) {
               return 1;
             }
           }
         }
         return 0;
       });
  }
}


#---------------------------------------------------------------------------
# generic

# if $elem is a symbol or a List of a symbol then return that symbol elem,
# otherwise return an empty list
#
sub _symbol_or_list_symbol {
  my ($elem) = @_;
  if ($elem->isa('PPI::Structure::List')) {
    $elem = $elem->schild(0) || return;
    $elem->isa('PPI::Statement::Expression') || return;
    $elem = $elem->schild(0) || return;
  }
  $elem->isa('PPI::Token::Symbol') || return;
  return $elem;
}


#---------------------------------------------------------------------------

1;
__END__

=for stopwords config MinimumVersion Pragma CPAN prereq multi-constant concats pragma endianness filehandle asciz builtin Ryde no-args parens BER lexically-scoped

=head1 NAME

Perl::Critic::Policy::Compatibility::PerlMinimumVersionAndWhy - explicit Perl version for features used

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
add-on.  It requires that you have an explicit C<use 5.XXX> etc for the Perl
syntax features you use, as determined by
L<C<Perl::MinimumVersion>|Perl::MinimumVersion>.

    use 5.010;       # the // operator is new in perl 5.010
    print $x // $y;  # ok

If you don't have the C<Perl::MinimumVersion> module then nothing is
reported.  Certain nasty hacks are used to extract reasons and locations
from C<Perl::MinimumVersion>.

This policy is under the "compatibility" theme (see L<Perl::Critic/POLICY
THEMES>).  Its best use is when it picks up things like C<//> or C<qr> which
are only available in a newer Perl than you meant to target.

An explicit C<use 5.xxx> can be a little tedious, but has the advantage of
making it clear what's needed (or supposed to be needed) and it gives a good
error message if run on an older Perl.

=head2 Disabling
 
The config options below let you limit how far back to go.  Or if you don't
care at all about this sort of thing you can always disable the policy
completely from your F<~/.perlcriticrc> file in the usual way (see
L<Perl::Critic/CONFIGURATION>),

    [-Compatibility::PerlMinimumVersionAndWhy]

=head2 MinimumVersion Mangling

Some mangling is applied to what C<Perl::MinimumVersion> normally reports
(as of its version 1.28).

=over 4

=item *

A multi-constant hash with the L<C<constant>|constant> module is not
reported, since that's covered better by
L<Compatibility::ConstantPragmaHash|Perl::Critic::Policy::Compatibility::ConstantPragmaHash>.

=item *

Module requirements for things like C<use Errno> are dropped, since you
might get a back-port from CPAN etc and the need for a module is better
expressed in a distribution "prereq".

But pragma modules like C<use warnings> are still reported.  They're
normally an interface to a feature new in the Perl version it comes with and
can't be back-ported.  (See L</OTHER NOTES> below too.)

=back

=head2 MinimumVersion Extras

The following extra checks are added to C<Perl::MinimumVersion>.

=over

=item 5.12 for

=over

=item *

new C<keys @array>, C<values @array> and C<each @array>

=back

=item 5.10 for

=over

=item *

C<qr//m>, since "m" modifier doesn't propagate correctly on a C<qr> until
5.10

=item *

C<-e -f -x> stacked filetest operators.

=item *

C<pack()> new C<E<lt>> and C<E<gt>> endianness.

=item *

new C<UNIVERSAL.pm> method C<DOES()>

=back

=item 5.8 for

=over

=item *

new C<word [newline] =E<gt>> fat comma quoting across a newline

For earlier Perl C<word> ended up a function call.  It's presumed such code
is meant to quote in the 5.8 style, and thus requires 5.8 or higher.

=item *

C<eval '#line ...'> with C<#line> the very first thing

In earlier Perl a C<#line> as the very first thing in an C<eval> doesn't
take effect.  Adding a blank line so it's not first is enough.

=item *

C<pack()> new C<F> native NV, C<D> long double, C<i> IV, C<j> UV, C<()>
group, C<[]> repeat count

=back

=item 5.6 for

=over

=item *

new C<exists &subr>, C<exists $array[0]> and C<delete $array[0]>

=item *

new C<0b110011> binary number literals

=item *

new C<open(my $fh,...)> etc auto-creation of filehandle

=item *

C<syswrite()> length parameter optional

=item *

C<Foo-E<gt>$method> no-args call without parens

For earlier Perl a no-args call to a method named in a variable must be
C<Foo-E<gt>$method()>.  The parens are optional in 5.6 up.

=item *

C<pack()> new C<Z> asciz, C<q>,C<Q> quads, C<!> native size, C</> counted
string, C<#> comment

=back

=item 5.005 for

=over

=item *

new C<Foo::Bar::> double-colon package name quoting

=item *

new C<my ($x, undef, $y) = @values>, using C<undef> as a dummy in a C<my>
list

=back

=item 5.004 for

=over

=item *

new C<use 5.xxx> Perl version check through C<use>.  For earlier Perl it can
be C<BEGIN { require 5.000 }> etc

=item *

new C<__PACKAGE__> special literal

=item *

new C<foreach my $foo> lexical loop variable

=item *

new C<$coderef-E<gt>()> call with C<-E<gt>>

=item *

new C<sysseek()> builtin function

=item *

C<pack()> new C<w> BER integer

=item *

new C<UNIVERSAL.pm> with C<VERSION()>, C<isa()> and C<can()> methods

=back

=back

C<pack()> and C<unpack()> format strings are only checked if they're literal
strings or here-documents without interpolations, or C<.> operator concats
of those.

The C<qr//m> report concerns a misfeature fixed in perl 5.10.0 (see
L<perl5101delta>).  In earlier versions a regexp like C<$re = qr/^x/m>
within another regexp like C</zz|$re/> loses the C</m> attribute from
C<$re>, changing the interpretation of the C<^> (and C<$> similarly).  Forms
like C<(\A|\n)> are a possible workaround, though are uncommon so may be a
little obscure.  C<RegularExpressions::RequireLineBoundaryMatching> asks for
C</m> in all cases so if think you want that then you probably want Perl
5.10 or up for the fix too.

=head2 C<Modern::Perl>

C<use Modern::Perl> is taken to mean Perl 5.10.  This is slightly
experimental and in principle the actual minimum it implies is forever
rising, and even now could be more, or depends on it date argument scheme.
Maybe if could say its actual current desire then an installed version could
be queried.

=head1 CONFIGURATION

=over 4

=item C<above_version> (version string, default none)

Set a minimum version of Perl you always use, so that reports are only about
things higher than this and higher than what the document declares.  The
value is anything the L<C<version.pm>|version> module can parse.

    [Compatibility::PerlMinimumVersionAndWhy]
    above_version = 5.006

For example if you always use Perl 5.6 and set 5.006 like this then you can
have C<our> package variables without an explicit C<use 5.006>.

=item C<skip_checks> (list of check names, default none)

Skip the given MinimumVersion checks (a space separated list).  The check
names are shown in the violation message and come from
C<Perl::MinimumVersion::CHECKS>.  For example,

    [Compatibility::PerlMinimumVersionAndWhy]
    skip_checks = _some_thing _another_thing

This can be used for checks you believe are wrong, or where the
compatibility matter only affects limited circumstances which you
understand.

The check names are likely to be a moving target, especially the Pulp
additions.  Unknown checks in the list are quietly ignored.

=back

=head1 OTHER NOTES

C<use warnings> is reported as a Perl 5.6 feature since the lexically-scoped
fine grain warnings control it gives is new in that version.  If targeting
earlier versions then it's often enough to drop C<use warnings>, ensure your
code runs cleanly under S<< C<perl -w> >>, and leave it to applications to
use C<-w> (or set C<$^W>) if they desire.

C<warnings::compat> offers a C<use warnings> for earlier Perl, but it's not
lexical, instead setting C<$^W> globally.  In a script this might be an
alternative to S<C<#!/usr/bin/perl -w>> (per L<perlrun>), but in a module
it's probably not a good idea to change global settings.

The C<UNIVERSAL.pm> methods C<VERSION()>, C<isa()>, C<can()> or C<DOES()>
might in principle be implemented explicitly by a particular class, but it's
assumed that's not so and that any call to those requires the respective
minimum Perl version.

=head1 SEE ALSO

L<Perl::Critic::Pulp>,
L<Perl::Critic>

L<Perl::Critic::Policy::Modules::PerlMinimumVersion>, which is similar, but
compares against a Perl version configured in your F<~/.perlcriticrc> rather
than a version in the document.

L<Perl::Critic::Policy::Modules::RequirePerlVersion>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/perl-critic-pulp/index.html>

=head1 COPYRIGHT

Copyright 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2019, 2021 Kevin Ryde

Perl-Critic-Pulp is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Perl-Critic-Pulp is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Perl-Critic-Pulp.  If not, see <http://www.gnu.org/licenses/>.

=cut
