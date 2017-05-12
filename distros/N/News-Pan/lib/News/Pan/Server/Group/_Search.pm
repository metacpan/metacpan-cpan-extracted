package News::Pan::Server::Group::_Search;
use strict;
use warnings;
use Carp;
use LEOCHARRE::DEBUG;






sub _search_set_subjects_matching {
   my ($self,$arg) = @_;
   defined $arg or confess('missing arg');
   ref $arg eq 'ARRAY' or confess('not array ref');
   $self->{_data_}->{search_subjects_matching} = $arg;
   return 1;
}

sub _search_subjects_matching {
   my $self = shift;
   unless (defined $self->{_data_}->{search_subjects_matching}){
      $self->{_data_}->{search_subjects_matching} = $self->subjects;   
   }   
   return $self->{_data_}->{search_subjects_matching};
}




sub _search_filter {
   my ($self,$term,$case_sensitive,$negative) = @_;
   defined $term or confess('missing arg');   
   $case_sensitive ||= 0;
   $negative ||=0;
   
   debug(sprintf "count before %s, ", $self->search_count );
   
   my @filtered;
   
   if ($case_sensitive and $negative){   
      @filtered = grep { !/$term/ } @{$self->_search_subjects_matching};
      debug("[$term] case sensitive and negative, ");
   }   
   
   elsif ($case_sensitive){   
      @filtered = grep { /$term/ } @{$self->_search_subjects_matching};
      debug("[$term] case sensitive, ");      
   }
   
   elsif ($negative){
      @filtered = grep { !/$term/ } @{$self->_search_subjects_matching};
      debug("[$term] negative, ");      
   }
   
   else {
      @filtered = grep { /$term/i } @{$self->_search_subjects_matching};   
      debug("[$term] positive match, ");      
   }
   $self->_search_set_subjects_matching(\@filtered);

   if (DEBUG){
      for (@filtered){
         print STDERR "   -ok: $_ \n";
      }
   }

   debug(sprintf "count after %s\n\n", $self->search_count );
  
   return 1;
} 


sub _search_subjects_matching_count {
   my $self = shift;
   my $count = scalar @{$self->_search_subjects_matching};
   return $count;
}




sub search_add {
   my ($self,$string) = @_; 
   defined $string or confess('missing arg');
   $string=~/\w/ or warn("will not filter, no word chars") and return;

   $string=~/^\s|\s$/g;
   my @terms = split(/\W/,$string);

   for (@terms){
      $self->_search_filter($_);
   }
   return 1;   
}

sub search_add_exact {
   my ($self,$string) = @_; 
   defined $string or confess('missing arg');
   $self->_search_filter($string,1);
   return 1;
}



sub search_negative {
   my ($self,$string) = @_; 
   defined $string or confess('missing arg');
   $string=~/\w/ or warn("will not filter, no word chars") and return;

   $string=~/^\s|\s$/g;
   my @terms = split(/\W/,$string);

   for (@terms){
      $self->_search_filter($_,0,1);
   }
   return 1; 
}

sub search_negative_exact {
   my ($self,$string) = @_; 
   defined $string or confess('missing arg');
   $self->_search_filter($string,1,1);
   return 1;
}

sub search_count {
   my $self = shift;
   return $self->_search_subjects_matching_count;
}

sub search_results {
   my $self = shift;
   return $self->_search_subjects_matching;
}

sub search_reset {
   my $self = shift;
   $self->{_data_}->{search_subjects_matching} = undef;
   return 1;
}


1;

__END__

=pod

=head1 NAME

News::Pan::Server::Group::_Search - search methods for group object

=head1 DESCRIPTION

This module is inherited by News::Pan::Server::Group. 
This is to perform a search of a pan file for article subjects.

=head1 SYNOPSIS
   
   my $search = new News::Pan::Server::Group({ abs_path =>'/home/myself/.pan/astraweb/alt.binaries.sounds.mp3' });

   $search->search_add('elvis');
   $search->search_add('presley');
   $search->search_add('.mp3');
   $search->search_negative('lisa');

   $search->search_count;

   $search->search_subjects;

   $search->search_reset;

=head1 SEARCH METHODS

Calling any of the term setters starts a search. the term setters are search add and search negative methods.

=head2 search_add_exact()

argument is a string. will match case sensitive.

   $g->search_add_exact('James Mason');

=head2 search_add()

argument is a string, will split on non word chars and do insensitive inclusive match

   $g->search_add('Lisa Loeb');

matches all article subjects with lisa and loeb, in any order.

=head2 search_negative_exact()

reverse of search_add_exact()

=head2 search_negative()

reverse of search_add().

=head2 search_reset()

reset the search for a new search to be made.

=head2 search_count()

returns number of article subjects matching at present.

=head2 search_results()

returns array ref with subjects of matching articles.

=head1 SEE ALSO

L<News::Pan>

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=cut
