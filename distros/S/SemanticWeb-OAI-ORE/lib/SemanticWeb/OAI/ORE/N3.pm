package SemanticWeb::OAI::ORE::N3;
#$Id: N3.pm,v 1.14 2010-12-06 14:44:15 simeon Exp $

=head1 NAME

SemanticWeb::OAI::ORE::N3 - Parse/serialize OAI-ORE Resource Maps in N3 format

=head1 SYNPOSIS

Class to parse and serialize OAI-ORE ReMs in N3 format.

=head1 DESCRIPTION

Follows N3 specification defined by L<http://www.w3.org/DesignIssues/Notation3.html>.

=cut

use strict;
use warnings;
use Carp;

use SemanticWeb::OAI::ORE::ReM;
use SemanticWeb::OAI::ORE::Constant qw(:all);

use RDF::Notation3::RDFCore;
use RDF::Notation3::Triples;
use RDF::Core::Storage::Memory;
use RDF::Core::Model;
use RDF::Core::Resource;
use RDF::Core::Enumerator;
use Data::Dumper;

=head1 METHODS

=head2 new()

=cut

sub new {
  my $class=shift;
  my $self={'strict'=>'warn',
            @_};
  bless $self, (ref($class) || $class);
  return($self);
}


=head2 parse($src,$uri_rem)

Parse $src which is either a string containing the N3 serialization of 
the ReM with URI $uri_rem, or a filehandle.

=cut

sub parse {
  my $self=shift;
  my ($src,$uri_rem)=@_;  

  my $rdf = RDF::Notation3::RDFCore->new();
  $rdf->set_storage(RDF::Core::Storage::Memory->new());
  my $model;
  if (ref($src) eq 'IO::File') {
    $model = $rdf->parse_file($src); #takes IO::File or path
  } elsif (ref($src)) {
    croak("Attempt to parse N3 with a ".ref($src)." object supplied");
  } else {
    $model = $rdf->parse_string($src);
  }

  # $model is an RDF::Core::Model
  # Now we look for statements that are special to OAI-ORE
  #print "got $model ".ref($model)."\n";
  #print Dumper($model);  
  return($model);
}


=head3 serialize()

We could do this by simply converting all data to triples
and then dumping them as N3. However, we attempt to do a
nice "pretty print" specific to ORE, with a few comments for 
the parts.

=cut

sub serialize {
  my $self=shift;
  my $out='';
  my $rem=$self->{rem};
  if (ref($rem) and $rem->isa('SemanticWeb::OAI::ORE::ReM')) {
    # Get the info from the ReM
    my $uri_r=$rem->uri;
    my $uri_a=$rem->aggregation;
    my @rem_and_agg=();
    my @agg_res=();
    my @lines=();
    $self->_prefixify_setup;
    foreach my $statement (@{$rem->model->as_array()}) {
      my ($subject,$predicate,$object,$is_literal)=@$statement;
      my $line=$self->_make_n3_line(@$statement);
      if ($subject eq $uri_r and $predicate eq DESCRIBES) {
        push(@rem_and_agg,$line);
      } elsif ($subject eq $uri_a and $predicate eq AGGREGATES) {
        push(@agg_res,$line);
      } else {
        push(@lines,$line);
      }
      #FIXME
    }
    # Now print it
    $out.="### OAI-ORE Resource Map ($uri_r)\n";
    $out.=$self->_prefixes_section;
    $out.="\n# Resource Map and Aggregation\n";
    $out.=join('',(sort @rem_and_agg)) if (@rem_and_agg);
    $out.="\n# Aggregated resources\n";
    $out.=join('',(sort @agg_res)) if (@agg_res);
    $out.="\n# Relations\n";
    $out.=join('',(sort @lines)) if (@lines);
    $out.="\n### End Resource Map\n";
  } else {
    carp "Can't serialize something that isn't a rem: $rem, ".ref($rem)."\n";
  }
  return($out);
}


# Create a single N3 line from subject,predicate,object labels with 
# appropriate escaping.
#
sub _make_n3_line {
  my $self=shift;
  my ($subject,$predicate,$object,$object_is_literal)=@_;
  my $line='';
  if (my $psubject=$self->_prefixify($subject)) {
    $line.=$psubject.' ';
  } else {
    $line.='<'.$subject.'> ';
  }
  if (my $ppredicate=$self->_prefixify_predicate($predicate)) {
    $line.=$ppredicate.' ';
  } else {
    $line.='<'.$predicate.'> ';
  }
  if ($object_is_literal) {
    $line.='"'._n3_escape($object).'"';
  } elsif (my $pobject=$self->_prefixify($object)) {
    $line.=$pobject;
  } else {
    $line.='<'.$object.'>';
  }
  return($line.".\n");
}


# Escape a string for use in N3 quoted string.
# See: http://www.w3.org/DesignIssues/Notation3
#
sub _n3_escape {
  my ($sstr)=@_;
  my $rstr='';
  foreach my $c (split(//,$sstr)) {
    if ($c eq '\\') {
      $c='\\\\';
    } elsif ($c eq '"') {
      $c='\\"';
    } elsif ($c eq "\n") {
      $c='\\n';
    } elsif ($c eq "\r") {
      $c='\\r';
    } elsif ($c eq "\t") {
      $c='\\t';
    }
    $rstr.=$c;
  }
  return($rstr);
}


sub _parse_warning {
  my $self=shift;
  my $msg=shift;
  print "_parse_warning: $msg\n";
}


sub _parse_error { 
  my $self=shift;
  my $msg=shift;
  if ($self->{strict} eq 'warn') {
    return($self->_parse_warning($msg));
  }
  croak "_parse_error: $msg\n";
}


# Setup ready to use _prefixify.
#
# WARNING - have to be carefull that constants do not get quoted
# in the hash. See Caveats in http://perldoc.perl.org/constant.html
#
sub _prefixify_setup {
  my $self=shift;
  $self->{prefixes_known}={
    ORE_NS() => ORE_PREFIX(),
    DC_NS() => DC_PREFIX(),
    DCT_NS() => DCT_PREFIX(),
    RDF_NS() => RDF_PREFIX() };
  $self->{prefixes_used}={};    
}


# Return prefixes section of N3 output.
#
sub _prefixes_section {
  my $self=shift;
  my $out='';
  if (scalar(keys %{$self->{prefixes_used}})) {
    $out.="\n# Namespace prefixes\n";
    foreach my $prefix (sort keys %{$self->{prefixes_used}}) {
      $out.="\@prefix $prefix: <".$self->{prefixes_used}{$prefix}.">.\n";
    }
  }
  return($out);
}


# Takes input $uri, return possible prefixed $uri having added
# prefix to list of known used prefixes.
#
sub _prefixify {
  my $self=shift;
  my ($uri)=@_;
  foreach my $prefix (keys %{$self->{prefixes_known}}) {
    if ($uri=~s%^$prefix%%) {
      $self->{prefixes_used}{$self->{prefixes_known}{$prefix}}=$prefix;
      return($self->{prefixes_known}{$prefix}.':'.$uri);
    }
  }
  # Nothing found, return nothing
  return();
}


# Special support for predicates where N3 has certain shorthands
#
sub _prefixify_predicate {
  my $self=shift;
  my ($uri)=@_;
  if ($uri eq 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type') {
    return('a');
  } elsif ($uri eq 'http://www.w3.org/2002/07/owl#sameAs') {
    return('=');
  } elsif ($uri eq 'http://www.w3.org/2000/10/swap/log#implies') {
    return('=>');
  }
  # No specials for predicate found, try normal _prefixify
  return($self->_prefixify($uri));
}


=head1 SEE ALSO

L<SemanticWeb::OAI::ORE> and associated modules.

=head1 AUTHORS

Simeon Warner

=head1 LICENSE AND COPYRIGHT

Copyright 2007-2010 Simeon Warner.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

1;
