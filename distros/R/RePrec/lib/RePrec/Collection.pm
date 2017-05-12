######################### -*- Mode: Perl -*- #########################
##
## File          : $RCSfile: Collection.pm,v $
##
## Author        : Norbert Goevert
## Created On    : Thu Feb  6 17:43:59 1997
## Last Modified : Time-stamp: <2000-11-23 17:40:56 goevert>
##
## Description   : 
##
## $Id: Collection.pm,v 1.28 2003/06/13 12:29:30 goevert Exp $
##
######################################################################


use strict;


## ###################################################################
## package RePrec::Collection
## ###################################################################

package RePrec::Collection;


use Carp;

use vars qw($VERSION);

'$Name: release_0_32 $ 0_0' =~ /(\d+)[-_](\d+)/; $VERSION = sprintf '%d.%03d', $1, $2;


## public ############################################################

sub new {

  my $proto = shift;
  my $class = ref($proto) || $proto;
  my %params = @_;

  my $self  = {};

  bless $self => $class;

  $self->_init(%params);

  return $self;
}


sub get_numdocs {

  my $self = shift;
  return $self->{numdocs};
}


sub relevant {

  my $self = shift;
  my($qid, $docid) = @_;

  $self->{qrels}->{$qid}->{$docid};
}


sub get_numrels {

  my $self = shift;
  my $qid = shift;

  return 0 unless defined $self->{numrels}->{$qid};

  $self->{numrels}->{$qid};
}


## private ###########################################################

sub _init {

  my $self = shift;
  my %parms = @_;

  my $file   = $parms{file};
  my $sep    = defined $parms{separator} ? $parms{separator} : ' +';
  my $ignore = defined $parms{ignore}    ? $parms{ignore}    : undef;
  my $qid    = defined $parms{qid}       ? $parms{qid}       : 0;
  my $docid  = defined $parms{docid}     ? $parms{docid}     : 1;
  my $judge  = defined $parms{judge}     ? $parms{judge}     : 2;
  $self->{numdocs} = $parms{numdocs}
    or croak "`Number of documents in collection' parameter missing\n";

  my $QRELS = IO::File->new($file)
    or croak "Couldn't read open file `$file': $!\n";

  my(%qrels, %numrels);
  local $_;
  while (<$QRELS>) {
    chomp;
    next if defined $ignore and /$ignore/;
    my($_qid, $_docid, $_judge) = (split /$sep/)[$qid, $docid, $judge];
    if ($_judge == 1) {
      $qrels{$_qid}->{$_docid} = 1;
      $numrels{$_qid}++;
    }
  }

  $self->{qrels}   = \%qrels;
  $self->{numrels} = \%numrels;
}


1;
__END__
## ###################################################################
## pod
## ###################################################################

=head1 NAME

RePrec::Collection - Parse relevance judgements for evaluation purposes

=head1 SYNOPSIS

  require RePrec::Collection;

=head1 DESCRIPTION

To do an evaluation of effectiveness of information retrieval methods
one needs relevance judgements for queries and a collection under
consideration. These need to be parsed for doing the evaluation. Class
B<RePrec::Collection> provides for means to do so which should suit
for most formats of relevance judgments. In case it doesn't suit one
can subclass this class. From a list of relevance judgements one needs
to filter the query ID (QID), the document ID (DOCID) and a judgement
(JUDGE) wether DOCID is relevant with respect to QID. As an additional
parameter the number of documents in the collection under
consideration is needed.

=head1 METHODS

=over

=item new %parms

Constructor which does the parsing of a given judgements file. The
constructor calls the private method C<_init> (with %parms as
argument) in order to do the parsing. The argument %parms is described
within the documentation of that method.

=item _init %parms

The file parsing method, which should be the only method to replace in
subclasses of B<RePrec::Collection>. Within this baseclass it is
assumed that the data in $file comes as an table, with each row
containing a QID, a DOCID and the judgement (JUDGE) itself. A document
is marked relevant if the value of JUDGE equals 1. Argument %parms
keep the following parameters (defaults are given in parens):

=over

=item separator (' +')

perl regular expression separating columns

=item qid

column which holds the QIDs

=item docid

column which holds the DOCIDs

=item judge

column which holds the JUDGEs

=item ignore (undef)

perl regular expression; matching rows are ignored

=item numdocs (undef)

number of documents in the collection under consideration.

=back

=item relevant $qid, $docid

returns 1 if document with ID $docid is relevant with respect to query
with ID $qid. Else returns C<undef>.

=item get_numdocs

returns number of documents with respect to the collection under
consideration.

=item get_numrels $qid

returns number of relevant documents for query with ID $qid with
respect to the collection under consideration.

=back

=head1 BUGS

Yes. Please let me know!

=head1 SEE ALSO

perl(1).

=head1 AUTHOR

Norbert GE<ouml>vert E<lt>F<goevert@ls6.cs.uni-dortmund.de>E<gt>

=cut
