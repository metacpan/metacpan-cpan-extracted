######################### -*- Mode: Perl -*- #########################
##
## File          : $RCSfile: Searchresult.pm,v $
##
## Author        : Norbert Goevert
## Created On    : Mon Nov  9 16:54:39 1998
## Last Modified : Time-stamp: <2000-12-20 16:49:12 goevert>
##
## Description   : 
##
## $Id: Searchresult.pm,v 1.28 2003/06/13 12:29:30 goevert Exp $
##
######################################################################


use strict;


## ###################################################################
## package RePrec::Searchresult
## ###################################################################

package RePrec::Searchresult;


use Carp;


our $VERSION;
'$Name: release_0_32 $ 0_0' =~ /(\d+)[-_](\d+)/; $VERSION = sprintf '%d.%03d', $1, $2;


## public ############################################################

sub new {

  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self  = {};
  my($qid, $results, @parms) = @_;

  bless $self => $class;

  if (defined $results) {
    if (ref $results eq 'ARRAY') {
      foreach (@{$results}) {
        croak "Wrong type of search result element"
          unless ref $_ eq 'ARRAY' and @$_ == 2;
      }
      $self->{results} = $results;
    } elsif (ref $results) {
      croak "Wrong reference type for results parameter";
    } else {
      $self->_init($results, @parms);
    }
  } else {
    croak "filename or array with searchresults needed";
  }

  $self->{qid} = $qid;

  return $self;
}


sub distribution {

  my $self = shift;
  my $judgements = shift;

  return $self->{distribution} if $self->{distribution};

  croak "wrong type of judgements parameter"
    unless ref $judgements and $judgements->isa('RePrec::Collection');

  $self->{numdocs} = $judgements->get_numdocs;
  $self->{rels} = 0;
  $self->{nrels} = 0;

  my @distribution;
  my($rels,     $nrels)     = (0, 0);
  my $rank;
  foreach (@{$self->{results}}) {
    $rank = $_->[0] unless $rank;
    if ($rank != $_->[0]) {
      push @distribution, [ $rels, $nrels ];
      $rank = $_->[0];
      ($rels, $nrels) = (0, 0);
    }
    if ($judgements->relevant($self->{qid}, $_->[1])) {
      $rels++;
      $self->{rels}++;
    } else {
      $nrels++;
      $self->{nrels}++;
    }
  }
  push @distribution, [ $rels, $nrels ];

  # create entry for very last rank if necessary
  if ($self->{numdocs} > $self->{rels} + $self->{nrels}) {
    my $rels_tot = $judgements->get_numrels($self->{qid});
    my $nrels_tot = $self->{numdocs} - $rels_tot;
    push @distribution, [ $rels_tot  - $self->{rels},
                          $nrels_tot - $self->{nrels}
                        ];
  }

  $self->{distribution} = \@distribution;
}


sub numdocs {

  my $self = shift;
  $self->{numdocs}
}


sub rels {

  my $self = shift;
  $self->{rels};
}


sub nrels {

  my $self = shift;
  $self->{nrels};
}


## private ###########################################################

sub _init {

  my $self = shift;
  my $file = shift;
  my %parm = @_;

  my $sep    = defined $parm{separator} ? $parm{separator} : '\s+';
  my $ignore = defined $parm{ignore}    ? $parm{ignore}    : undef;
  my $docid  = defined $parm{docid}     ? $parm{docid}     : 0;
  my($rate, $rank) = ( 1, undef );
  if (defined $parm{rsv}) {
    $rate = $parm{rsv};
  } elsif (defined $parm{rank}) {
    $rate = $parm{rank};
    $rank = 1;
  }

  my $fh = IO::File->new($file)
    or croak "Couldn't read open file `$file': $!\n";

  my @results;
  local $_;
  while (<$fh>) {
    chomp;
    next if defined $ignore and /$ignore/;
    my($_rate, $_docid) = (split /$sep/)[$rate, $docid];
    $_rate = - $_rate if $rank; # convert rank into RSV if necessary
    push @results, [ $_rate, $_docid ];
  }

  if ($parm{sorted}) {
    $self->{results} = \@results;
  } else {
    $self->{results} = [ sort { $b->[0] <=> $a->[0] } @results ];
  }
}


1;
__END__
## ###################################################################
## pod
## ###################################################################

=head1 NAME

RePrec::Searchresult - Parse search result for evaluation purposes

=head1 SYNOPSIS

  require RePrec::Searchresult;

=head1 DESCRIPTION

To do an evaluation of effectiveness of information retrieval methods
one needs to parse the results of a query run. From a ranking of
documents one needs to filter out the document IDs (DOCIDs) and their
respective ranks or retrieval status values (RSVs). Since rank and RSV
provide for equivalent information only one of them is needed. The
B<RePrec::Searchresult> class provides for means to do so which should
suit for most formats of search results. In case it doesn't suit one
can subclass this class.

=head1 METHODS

=over

=item $result = Searchresult->new($query, $result)

where $query is the ID of the query under consideration and where
$result is an array reference holding array references containing each
a (RSV, DOCID) pair. These pairs must be sorted by decreasing RSV.

=item $result = Searchresult->new($query, $file, %parms)

where $file is the name of the file containing the results. This file
is parsed then in order to extract DocIDs and ranks or RSVs. The
constructor calls the private method C<_init> (with $file and %parms
as arguments) in order to do the parsing. The argument %parms is
described within the documentation of that method.

=item $result->_init($file, %parms)

The file parsing method, which should be the only method to replace in
subclasses of B<RePrec::Searchresult>. Within this baseclass it is
assumed that the data in $file comes as an table, with each row
containing RSV/rank of a single document. Argument %parms keep the
following parameters (defaults are given in parens):

=over

=item separator ('\s+')

perl regular expression separating columns

=item docid (0)

column which holds the DOCIDs (index of first column is 0)

=item rsv (1)

column which holds the RSVs (index of first column is 0)

=item rank (undef)

column which holds the rank (index of first column is 0)

=item ignore (undef)

perl regular expression; matching rows are ignored

=item sorted (undef)

if true it is assumed that the results are sorted according to RSV or
rank (highest rated document at the top). Else results are sorted
which takes some time in case of huge rankings.

=back

If both I<rank> and I<rsv> are given, the I<rank> parameter is ignored.

=item $distribution = $result->distribution($judgements)

Get relevance distribution. $judgements must contain the relevance
assesments as described in RePrec::Collection(3). The result is a
reference to an array containing a two element array reference for
each rank (top most rank first). The first element within the
references contains the number of relevant documents while the second
one contains the number of non-relevant documents.

=item $rels = $result->rels

returns the number of relevant documents found or undef if the
distribution method has not been called before.

=item nrels

returns the number of non-relevant documents found or undef if the
distribution method has not been called before.

=back

=head1 BUGS

Yes. Please let me know!

=head1 SEE ALSO

perl(1).

=head1 AUTHOR

Norbert GE<ouml>vert E<lt>F<goevert@ls6.cs.uni-dortmund.de>E<gt>

=cut
