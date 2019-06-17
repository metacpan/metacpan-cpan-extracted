package PMLTQ::NG2PMLTQ;
our $AUTHORITY = 'cpan:MATY';
$PMLTQ::NG2PMLTQ::VERSION = '3.0.2';
# ABSTRACT: [DEPRECATED] Conversion functions from NetGraph to PML-TQ


use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;
import Exporter qw( import );

use List::Util qw(first);

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
  ng2pmltq
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(  );

sub ng2pmltq {
  local $_=shift;
  my $opts = shift || {};
  parse_tree(1,{},$opts);
}

our $indent = 0;
sub indent (@) {
  join('', @_)."\n"." " x (2*$indent);
}
sub report {
  my ($fmt,@args)=@_;
  return "\n # WARNING: ".sprintf($fmt, @args)."\n";
}
sub parse_tree {
  my ($is_top,$parent_meta,$opts)=@_;
  local $indent= $is_top ? 0 : $indent;
  my $result='';
  while (length) {
    if ( s/^
	  \[
	  (
	    (?:
	      [^]"\\]+
	    |
	      "[^"]*"
	    |
	      \\.
	    | \]\|\[
	    )*
	  )
	  \]
	 //x) {
      my $tok = $1;
      my %meta;
      my $children='';
      $indent ++;
      {
	$indent ++;
	if ($tok) {
	  $children = indent().parse_condition($tok,\%meta,$parent_meta,$opts);
	}
	if (s/^\(//) {
	  if (length $children and $children !~ /(^|[\[(,])\s*$/) {
	    $children.=indent(',');
	  }
	  $children .= parse_tree(0,\%meta,$opts);
	  $children =~ s/,?\s*$//;
	  unless (s/^\)//) {
	    $result.=report(q{missing ')'});
	  }
	}
	$indent --;
      }
      if (!$is_top) {
	if (defined $meta{'_#occurrences'}) {
	  $result .= $meta{'_#occurrences'}."x ";
	} elsif (defined $meta{_optional} and $meta{_optional}=~/^\s*(1|yes|true)\s*/) {
	  $result .= '? ';
	}
      }
      if (defined $meta{hide}) {
	if ($meta{hide}=~/^\s*(1|yes|true|hide)\s*/) {
	  if ($is_top) {
	    $result .= q(a-node );
	  } elsif (!$parent_meta->{type} and $opts->{type} eq 'a-node'
		   or ($parent_meta->{type}||'') eq 'a-node') {
	    $result .= q();
	  } else {
	    $result .= q(a/lex.rf|a/aux.rf a-node );
	  }
	}
      } else {
	if (defined $meta{_transitive}) {
	  $result .= 'descendant ';
	}
	my $type = $meta{type} || $opts->{type};
	if (defined($type)) {
	  $result .= $type.' ' #if !defined($parent_meta->{type}) or $parent_meta->{type} ne $type;
	}
      }
      if (defined $meta{_name}) {
	$result .= '$'.lc($meta{_name}).' := ';
      }
      $result .= "[".$children;
      $indent --;
      $result .= indent()."]";
    } elsif (s/^,//) {
      $result .= indent(',') unless $result =~ /(^|[\[(,])\s*$/;
    } elsif (s/^([^\[\(\),]+)//) {
      $result.=report(q(unrecognized sequence '%s'),$1);
    } elsif (/\)/ and !$is_top) {
      return $result;
    } elsif (s/^(.)//) {
      $result.=report(q(had to skip '%s'),$1);
    }
  }
  return $result;
}

my @attrs = map { 'UNKNOWN-'.$_ } 1..50;

sub fix {
  my ($val,$meta,$parent_meta,$opts)=@_;
  if (!$opts->{'no-fix'}) {
    $val=~s{^a/}{}g;
    if ($val =~ /^(?:tag|lemma|form)$/) {
      $val='m/'.$val;
    } elsif ($val eq 'token') {
      $val='m/w/'.$val;
    } elsif ($val eq 'func') {
      $val = 'functor';
    } elsif ($val eq 'tlemma') {
      $val = 't_lemma';
    } elsif ($val eq 'm_lemma') {
      $val = 'lemma';
    } elsif ($val eq 'AID') {
      $val = 'id';
    }
  }
  if ($val =~ s/^_#//) {
    return $val.'()';
  } elsif ($val eq '_depth') {
    return 'depth()';
  }
  if (!defined($meta->{type})) {
    if ($val=~/^(?:lemma|tag|ord|form|afun|token)$/) {
      $meta->{type}='a-node';
      unless (defined($parent_meta->{type}) and $parent_meta->{type} eq 'a-node') {
	$meta->{hide}=1;
      }
    } elsif ($val=~m{^(?:t_lemma|functor|gram/.*|tfa|deepord)}) {
      $meta->{type}='t-node';
    }
  }
  return $val;
}

sub quote {
  my ($str)=@_;
  $str=~s/'/\\'/g;
  return qq('$str');
}

sub parse_condition {
  local $_ = shift;
  my $meta = shift || {};
  my $parent_meta = shift || {};
  my $opts = shift || {};
  my $result = ''; #"### $_\n";
  my $or = 1 if (/^(?:[^"]|"[^"]*")*\]\|\[/);
  if ($or) {
    $indent++;
    $result .= indent "(";
  }
  my $next_attr = $attrs[0];
  while (length) {
    if (s/^\]\|\[//) {
      $result .= indent ' or'
	unless $result =~ /(^|[\[(,]| or)\s*$/;
    } elsif (s/^([{}_\/\#[:alnum:].]+)(?=[!]?=|<|>)//) {
      $next_attr=$1;
      unless(
	$next_attr=~s[{([^}.]+)\.([^}.]+)}][
	  my ($id,$val)=(lc($1),$2);
	  $val=fix($val,$meta,$parent_meta,$opts);
	  qq{\$$id.$val}
	 ]eg or
	$next_attr=~s[{([^}.]+)\.([^}.]+)\.(\d+)}][
	  my ($id,$val,$pos)=(lc($1),$2,$3);
	  $val=fix($val,$meta,$parent_meta,$opts);
	  $pos-=1;
	  qq{substr(\$$id.$val,$pos,1)}
	 ]eg
       ) {
	$next_attr=fix($1,$meta,$parent_meta,$opts);
      }
    } elsif (s/^,//) {
      my $next_attr_idx = first { $attrs[$_-1] eq $next_attr } 1..$#attrs;
      $next_attr = $attrs[$next_attr_idx||0];
      $result .= indent(',') unless $result =~ /(^|[\[(,]| or)\s*$/;
    } elsif (s/^((?:!?=|[<>]=?)?)((?:[^\\\]=,"]+|"[^"]*"|\\.)*)(?=[,\]]|$)// and length $2) {
      my $next_op = $1 || '=';
      my $vals = $2;
      if ($next_attr =~ /^(?:_transitive|_optional|_name|hide)$/) {
	$meta->{$next_attr} = $vals;
	next;
      } elsif ($next_attr eq '_#occurrences') {
	my @vals = sort {$a<=>$b} split /\|/,$vals;
	my @tests;
	if ($next_op eq '=') {
	  @tests = @vals;
	} elsif ($next_op eq '!=') {
	  my $prev = shift @vals;
	  if ($prev>0) {
	    push @tests,($prev-1)."-";
	  }
	  for (@vals) {
	    next if $prev==$_;
	    push @tests,($prev+1)."..".($_-1);
	    $prev=$_;
	  }
	  push @tests,($prev+1)."+";
	} elsif ($next_op eq '<=') {
	  push @tests, $vals[-1]."-" ;
	} elsif ($next_op eq '>=') {
	  push @tests, $vals[0]."+" ;
	} elsif ($next_op eq '<') {
	  push @tests, ($vals[-1]-1)."-" ;
	} elsif ($next_op eq '>') {
	  push @tests, ($vals[0]+1)."+" ;
	} else {
	  warn "Unsupported operator for meta-attribute _#occurrences: $next_op\n";
	}
	$meta->{$next_attr} = join '',map { "|" } @tests;
	next;
      }
      my @vals =
	($vals=~/^"(.*)"$/) ? ($vals) :	split /\|/,$vals;
      my $neg = $next_op eq '!=' ? 1 : 0;
      if ($neg) {
	$result .= q{!};
	$next_op = '=';
      }
      if (@vals>1 and ($next_op eq '=')) {
	$indent ++;
	$result .= qq($next_attr in { ).join(',',map quote($_), @vals).qq( } );
	$indent --;
      } else {
	if (@vals>1) {
	  $result .= "(";
	  $indent ++;
	}
	for my $val (@vals) {
	  my $op = $next_op;
	  if ($val=~/^"(.*)"$/) {
	    $op = '~';
	    $val=$1;
	  } else {
	    if ($opts->{'no-fix'}) {
	      $val=~s/\.(?![^{}]+})/?/g;
	    }
	    if ($val=~/[?*]/) {
	      $val=~s/([^[:alnum:]_?*])/\\$1/g;
	      $val=~y/?/./;
	      $val=~s/\*/.*/g;
	      $val='^'.$val.'$';
	      $op = '~'
	    }
	  }
	  $val=quote($val);
	  $val=~s[{([^}.]+)\.([^}.]+)}][
	    my ($id,$val)=(lc($1),$2);
	    $val=fix($val,$meta,$parent_meta,$opts);
	    qq{'&\$$id.$val&'}
	   ]eg;
	  $val=~s[{([^}.]+)\.([^}.]+)\.(\d+)}][
	    my ($id,$val,$pos)=(lc($1),$2,$3);
	    $val=fix($val,$meta,$parent_meta,$opts);
	    qq{'&substr(\$$id.$val,$pos,1)&'}
	   ]eg;
	  $val=~s/^  ''&
                |  &''
		  $//xg;
	  $val=~s/&''&/ & /g;
	  $indent ++;
	  $result .= qq($next_attr $op $val);
	  if (@vals>1) {
	    $result.=' or ';
	  }
	  $indent --;
	}
	if (@vals>1) {
	  $result.=')';
	  $indent --;
	}
      }
    } elsif (s/^(.)//) {
      my $q = quote($1);
      $result.=report("had to skip test $q");
    }
  }
  if ($or) {
    $indent--;
    $result .= indent().")";
  }
  return $result;
}





1; # End of PMLTQ::NG2PMLTQ

__END__

=pod

=encoding UTF-8

=head1 NAME

PMLTQ::NG2PMLTQ - [DEPRECATED] Conversion functions from NetGraph to PML-TQ

=head1 VERSION

version 3.0.2

=head1 SYNOPSIS

   use PMLTQ::NG2PMLTQ qw(ng2pmtq);
   my $pmltq_query_string = ng2pmltq( $netgraph_query_string, { options });

=head1 DESCRIPTION

This module provides the function C<ng2pmltq> which takes a NetGraph
query and attempts to translate it to an equivalent PMLTQ query.

=head2 EXPORT

None by default. Optionally exports the function C<ng2pmltq>.

=head2 EXPORT TAGS

The tag C<:all> exports the function C<ng2pmltq>.

=head1 AUTHORS

=over 4

=item *

Petr Pajas <pajas@ufal.mff.cuni.cz>

=item *

Jan Štěpánek <stepanek@ufal.mff.cuni.cz>

=item *

Michal Sedlák <sedlak@ufal.mff.cuni.cz>

=item *

Matyáš Kopp <matyas.kopp@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Institute of Formal and Applied Linguistics (http://ufal.mff.cuni.cz).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
