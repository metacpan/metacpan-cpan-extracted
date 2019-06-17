package PMLTQ::TypeMapper;
our $AUTHORITY = 'cpan:MATY';
$PMLTQ::TypeMapper::VERSION = '3.0.2';
# ABSTRACT: Helper methods for PML::Schema, relations and PML::Node types

use 5.006;
use strict;
use warnings;
use Treex::PML::Schema;
use Carp;

use PMLTQ::Common (qw(uniq first));
use PMLTQ::Relation;
use UNIVERSAL::DOES;

PMLTQ::Relation->load();

BEGIN { # TredMacro should work in TrEd 2.0
    eval {
        require TrEd::MacroAPI::Default;
        TrEd::MacroAPI::Default->import;
    };
}

sub new {
  my ($class,$opts)=@_;
  $opts||={};
  my $what = ($opts->{file}?1:0) +
             ($opts->{fsfile}?1:0) +
             ($opts->{filelist}?1:0);
  croak("Neither file, fsfile, nor filelist were specified!") unless $what;
  croak("Options file, fsfile, filelist are exclusive!") if $what>1;
  my $self = bless {
    fsfile => $opts->{fsfile},
    file => $opts->{file},
    filelist => $opts->{filelist},
  }, $class;
  return $self;
}

sub get_schema_for_query_node {
  my ($self,$node)=@_;
  my $decl = $self->get_type_decl_for_query_node($node);
  return $decl && $decl->schema;
}
sub get_schema_for_type {
  my ($self,$type)=@_;
  if ($type eq '*') {
    my @schemas = $self->get_schemas;
    if (@schemas == 1) {
      return $schemas[1];
    } else {
      return undef;
    }
  } elsif ($type =~ m{^(?:([^/]+):)\*$}) {
    my $schema_name = $1;
    my ($schema) = grep { $_->get_root_name eq $schema_name } $self->get_schemas;
    return $schema;
  }
  my $decl = $self->get_decl_for($type);
  return $decl && $decl->get_schema;
}

sub get_schema_name_for {
  my ($self,$type)=@_;

  my $schema = $self->get_schema_for_type($type);
  return $schema ? $schema->get_root_name : undef;
}

sub _get_fsfile {
  my ($self)=@_;
  my $fsfile = $self->{fsfile};
  return $fsfile if $fsfile;
  my $file = $self->{file};
  my $fl;
  if ($file) {
    if (ref($file) and UNIVERSAL::DOES::does($file,'Treex::PML::Document')) {
      $self->{file} = $file->filename;
      return $self->{fsfile} = $file;
    } else {
      return ($self->{fsfile} =
		((first { $_->filename eq $file } TredMacro::GetOpenFiles())
		   || TredMacro::Open($file, {-preload=>1})));
    }
  } elsif ($fl = TredMacro::GetFileList($self->{filelist})) {
    my %fl;
    my @files = $fl->files;
    @fl{ @files } = ();
    return $self->{fsfile} = ((first { exists($fl{$_->filename}) } TredMacro::GetOpenFiles())||
				$files[0] && TredMacro::Open(TredMacro::AbsolutizeFileName($files[0],$fl->filename),{-preload=>1}));
  }
}

sub get_schema {
  my ($self,$schema_name)=@_;
  if ($schema_name) {
    my ($ret) = grep { $_->get_root_name eq $schema_name } $self->get_schemas;
    return $ret;
  }
  my $fsfile = $self->_get_fsfile || return;
  return PML::Schema($fsfile);
}

sub get_schemas {
  my ($self)=@_;
  my $fsfile = $self->_get_fsfile || return;
  return uniq( map PML::Schema($_), ($fsfile,  TredMacro::GetSecondaryFiles($fsfile)));
}

sub get_schema_names {
  my ($self)=@_;
  return [uniq(grep { defined } map { $_->get_root_name }  $self->get_schemas)];
}

sub get_type_decl_for_query_node {
  my ($self,$node)=@_;
  return $self->get_decl_for(PMLTQ::Common::GetQueryNodeType($node));
}

sub get_decl_for {
  my ($self,$type)=@_;
  my $ret = eval { PMLTQ::Common::QueryTypeToDecl($type,$self->get_schemas) };
  warn $@ if $@;
  return $ret;
}

sub get_node_types {
  my ($self,$schema_name)=@_;
  return [sort map PMLTQ::Common::DeclToQueryType( $_ ), map $_->node_types,
	  grep { $schema_name ? ($_->get_root_name eq $schema_name) : 1 }
	  $self->get_schemas
	 ];
}

sub _find_pmlrf_relations {
  my ($self)=@_;
  my @schemas = $self->get_schemas;
  my @relations=();
  my %relations;
  for my $schema (@schemas) {
    for my $type ($schema->node_types) {
      my $type_name = PMLTQ::Common::DeclToQueryType($type);
      for my $path ($type->get_paths_to_atoms({ no_nodes=>1, no_childnodes => 1 })) {
	my $decl = $type->find($path);
	$decl=$decl->get_content_decl unless $decl->is_atomic;
	if ($decl->get_decl_type == PML_CDATA_DECL and
	    $decl->get_format eq 'PMLREF') {
	  push @relations, $path;
	  $relations{$type_name}{$path}='#any';
	}
      }
    }
  }
  $self->{pmlrf_relations_hash}=\%relations;
  return $self->{pmlrf_relations} = [sort @relations];
}

sub _find_pmlrf_relations_for_type {
  my ($self,$type_name)=@_;
  my @schemas = $self->get_schemas;
  my @relations=();
  my $relations_hash = $self->get_pmlrf_relations_hash; # init
  my $decl = $self->get_decl_for($type_name);
  return [] unless $decl;
  for my $path ($decl->get_paths_to_atoms({ no_nodes=>1, no_childnodes => 1 })) {
    my $mdecl = $decl->find($path);
    next if $mdecl->get_role eq '#KNIT';
    unless ($mdecl->is_atomic) {
      $mdecl=$mdecl->get_content_decl ;
      next if $mdecl->get_role eq '#KNIT';
    }
    if ($mdecl->get_decl_type == PML_CDATA_DECL and
	$mdecl->get_format eq 'PMLREF') {
      push @relations, $path;
      $relations_hash->{$type_name}{$path}='#any';
    }
  }
  return [sort @relations];
}

sub get_pmlrf_relations {
  my ($self,$qnode_or_type)=@_;
  if ($qnode_or_type) {
    my $type = ref($qnode_or_type) ? PMLTQ::Common::GetQueryNodeType($qnode_or_type,$self) : $qnode_or_type;
    my $rels = ref($self->{pmlrf_relations_hash}) && $self->{pmlrf_relations_hash}{$type};
    if ($rels) {
      return [ uniq( sort keys %$rels ) ];
    } else {
      return $self->_find_pmlrf_relations_for_type($type);
    }
  } else {
    return $self->{pmlrf_relations} || $self->_find_pmlrf_relations;
  }
}

sub get_pmlrf_relations_hash {
  my ($self,$type)=@_;
  my $hash = $self->{pmlrf_relations_hash};
  if ($type) {
    $hash = $hash->{$type} if $hash;
    return $hash if $hash;
    $self->_find_pmlrf_relations_for_type($type);
    $hash = $self->{pmlrf_relations_hash}{$type};
  } elsif (!$hash) {
    $self->_find_pmlrf_relations;
    $hash = $self->{pmlrf_relations_hash};
  }
  return $hash;
}

sub get_specific_relations {
  my ($self,$qnode_or_type)=@_;
  return [uniq(sort(
	  @{$self->get_user_defined_relations($qnode_or_type)},
	  @{$self->get_pmlrf_relations($qnode_or_type)}))];
}

sub get_user_defined_relations {
  my ($self,$qnode_or_type)=@_;
  if ($qnode_or_type) {
    my $type = ref($qnode_or_type) ? PMLTQ::Common::GetQueryNodeType($qnode_or_type,$self) : $qnode_or_type;
    my $schema_name = $self->get_schema_name_for($type);
    return $schema_name ? PMLTQ::Relation->relations_for_node_type($schema_name, $type) : []; # Ignore if it doesn't have schema_name
  }
  return [
    map @{$self->get_user_defined_relations($_)}, grep $_, @{$self->get_node_types}
  ];
}

my %known_pmlref_relations = (
  't-root' => {
    'a/lex.rf' => 'a-root',
  },
  't-node' => {
    'a/lex.rf' => 'a-node',
    'a/aux.rf' => 'a-node',
    'val_frame.rf' => 'v-frame',
    'coref_text.rf' => 't-node',
    'coref_gram.rf' => 't-node',
    'compl.rf' => 't-node',
  },
  'a-node' => {
    'p/terminal.rf' => 'english_p_terminal',
    'p/nonterminals.rf' => 'english_p_nonterminal',
  },
);

sub get_relation_target_type {
  my ($self,$node_type,$relation,$category)=@_;
  my $type;
  if (!$category or $category eq 'pmlrf') {
    $type = $known_pmlref_relations{$node_type} && $known_pmlref_relations{$node_type}{$relation};
    return $type if $type;
    my $pmlref_relations_hash = $self->get_pmlrf_relations_hash($node_type);
    $type = $pmlref_relations_hash && $pmlref_relations_hash->{$relation};
    return $type if $type;
  }
  if (!$category or $category eq 'implementation') {
    return PMLTQ::Relation->target_type($self->get_schema_name_for($node_type),$node_type, $relation);
  }
  return;
}

1; # End of PMLTQ::TypeMapper

__END__

=pod

=encoding UTF-8

=head1 NAME

PMLTQ::TypeMapper - Helper methods for PML::Schema, relations and PML::Node types

=head1 VERSION

version 3.0.2

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
