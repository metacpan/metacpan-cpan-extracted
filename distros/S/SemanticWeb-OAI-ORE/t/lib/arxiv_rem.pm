package arxiv_rem;

=head1 NAME

arxiv_rem - arXiv specific handling of resource map

=head1 SYNOPSIS

=cut

use strict;
use base qw(SemanticWeb::OAI::ORE::ReM);
use SemanticWeb::OAI::ORE::Agent;
use SemanticWeb::OAI::ORE::Constant qw(:all);


=head1 METHODS

=head2 ARXIV SPECIFIC METHODS

These methods extract and return data in a format useful for ingest into arXiv.

=head3 article_title

Returns title string from resource map

=cut

sub article_title {
  my $self=shift;
  return( $self->aggregation_metadata_literal('dc:title') );
}


=head3 article_authors 

Extract author information and create arXiv format authors string.

Will die on failure

=cut

sub article_authors {
  my $self=shift;

  my @authors=$self->_sorted_authors;

  my @authorlist=();
  foreach my $author ($self->_sorted_authors) {
    my $d=$self->_author_name_mbox_affil($author);
    die "Author without name" unless ($d->{name});
    # Fix "last, first" to "first last"
    my ($last, $first)=split(',',$d->{name},2);
    $first=~s/^\s+//;
    my $entry="$first $last";
    $entry.=" (".$d->{affil}.")" if ($d->{affil});
    push(@authorlist,$entry);
  }

  return(join(', ',@authorlist)); 
}


=head3 article_abstract

Extract abstract from resource map and return string.

=cut

sub article_abstract {
  my $self=shift;
  return( $self->aggregation_metadata_literal('dcterms:abstract') );
}


=head3 article_categories

Returns string formatted category information. First is primary and any subsequent
values are secondary categories.

Will die is data cannot be extracted but does not check validity of category names
and/or combinations.

=cut

sub article_categories {
  my $self=shift;
  my $primary=$self->_primary_category;
  my $secs=$self->_secondary_categories;
  if ($secs->{$primary}) {
    delete($secs->{$primary});
  }
  return(join(' ',$primary,sort keys %$secs))
}


=head3 article_files

Returns a hashref where each entry is indexed by the file name in the 
submission package.

=cut

sub article_files {
  my $self=shift;
  return($self->_aggregated_resources_that_conform_to('http://purl.org/dc/dcmitype/Text'));
}


=head3 article_datasets

Returns a hashref where each entry is indexed by the file name in the 
submission package.

=cut

sub article_datasets {
  my $self=shift;
  return($self->_aggregated_resources_that_conform_to('http://datapub.dataconservancy.org/type/DataPub-DS'));
}


=head3 article_contact_email

Return the contact email for this article. It is taken from the first
author with an mbox specified. Any mailto: prefix will be removed.

Will die if no email can be extracted.

=cut

sub article_contact_email {
  my $self=shift;
  foreach my $author ($self->_sorted_authors) {
    my $d=$self->_author_name_mbox_affil($author);
    if ($d->{mbox}) {
      $d->{mbox}=~s/^mailto://;
      return($d->{mbox});
    }
  }
  die "Failed to extract contact email from authors listed";
}


=head2 INTERNAL METHODS

=head3 _sorted_authors

Returns an array of author resources, sorted by rank into "article order". 

Will die if no authors can be extracted.

=cut

sub _sorted_authors {
  my $self=shift;
  my @authors=$self->aggregation_metadata('dcterms:creator');
  @authors=$self->_sort_authors_by_rank(@authors);
  die "No authors!" unless (@authors);
  return(@authors);
}


=head3 _sort_authors_by_rank

Assumes that there is a rank predicate for each author and sorts the 
array or author resources by that. Will die with appropriate error
if the rank information is missing or incorrect.

=cut

sub _sort_authors_by_rank {
  my $self=shift;

  my $rankpredicate='http://datapub.dataconservancy.org/terms/rank';

  # Find rank for each author
  my %ranks=();
  foreach my $author (@_) {
    my $rankstr=$self->model->literal_matching($author,$rankpredicate);
    if (defined $rankstr) {
      my ($rank)=$rankstr=~/(\d+)/;
      if ($rankstr ne "$rank") {
        die("Bad rank number, rank='$rankstr' for ".$author->getURI);
      } elsif ($ranks{$rank}) {
        die("Multiple authors with same rank=$rank: ".$ranks{$rank}->getURI." and ".$author->getURI); 
      } else {
        $ranks{$rank}=$author;
      }
    } else {
      die("No rank for author: ".$author->getURI." (name=".$self->model->literal_matching($author,'foaf:name').")");
    }    
  }

  # Create new arrays from these ranks
  my @authors=();
  foreach my $rank (sort {$a<=>$b} keys %ranks) {
    push(@authors,$ranks{$rank});
  }

  return(@authors);
}


=head3 _author_name_mbox_affil($author)

For a single author resource $author in the resourcemap $self, find
the name, mbox and affil data and return hashref

=cut

sub _author_name_mbox_affil {
  my ($self,$author)=@_;
  
  my %data=();
  $data{name}=$self->model->literal_matching($author,'foaf:name');
  $data{mbox}=$self->model->literal_matching($author,'foaf:mbox');
  $data{affil}=$self->model->literal_matching($author,'foaf:Organization');

  return(\%data);
}


=head3 _aggregated_resources_that_conform_to($fmt)

Extract information about all aggregated resources that dcterms:conformTo
the format $fmt.

=cut

sub _aggregated_resources_that_conform_to {
  my ($self,$fmt)=@_;

  my %conforming=();
  foreach my $ar ($self->aggregated_resources) {
    foreach my $ar_fmt ($self->model->objects_matching($ar,'dcterms:conformsTo',RESOURCE)) {
      if ($ar_fmt eq $fmt) {
        my $file=$ar;
        $file=~s%^file:///?%% or die("Bad file location '$ar'");
        $conforming{$file}={};
        # look for dcterms:type and dcterms:description
        if (my $type=$self->model->literal_matching($ar,'dcterms:type')) {
          $conforming{$file}{type}=$type;
	}
        if (my $description=$self->model->literal_matching($ar,'dcterms:description')) {
          $conforming{$file}{description}=$description;
	}
      }
    }
  }
  return(\%conforming);
}


=head3 _primary_category

Extract and return the primary category. Will die if there is no primary category
or if there is more than one.

=cut

sub _primary_category {
  my $self=shift;

  my @primary=$self->model->objects_matching($self->aggregation,'http://arxiv.org/schemas/atom/primary_category',RESOURCE);
  if (scalar(@primary)==0) {
    die "Failed to extract arxiv:primary_category";
  } elsif (scalar(@primary)>1) {
    die "More than one arxiv:primary_category element (found ".scalar(@primary).")";
  }
  
  my $primary_uri=shift(@primary);
  my $primary=$self->_uri_to_category($primary_uri);
  if (not $primary) {
    die "Bad primary category URI: $primary_uri";
  }
  return($primary);
}


=head3 _secondary_categories

Extract and return the secondary categories. Does not check to see whether one of the secondaries
is a duplicate of the primary. There may be zero of more of these. Returns a hashref where each 
element is a secondary category (key) with count of occurences as value.

=cut

sub _secondary_categories {
  my $self=shift;

  my %secs=();
  foreach my $sec_uri ($self->model->objects_matching($self->aggregation,'dcterms:subject',RESOURCE)) {
    my $sec=$self->_uri_to_category($sec_uri);
    if (not $sec) {
      die "Bad secondary category URI: $sec_uri";
    }
    $secs{$sec}++;
  }
  return(\%secs);
}


=head3 _uri_to_category($uri)

Extract arXiv category name from category URI. Will return nothing if the extraction
is not possible because the URI is obviously incorrect. Does not check the category
name in detail.

=cut

sub _uri_to_category {
  my $self=shift;
  my ($uri)=@_;
  return() unless ($uri=~s%^http://arxiv.org/terms/arXiv/%%); #correct namespace
  return() unless ($uri=~/^[a-z-]+(\.[a-zA-Z-]+)$/);   #correct form
  return($uri);
}
 
1;
