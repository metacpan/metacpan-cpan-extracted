# $Id: Options.pm,v 1.8 2003/11/04 01:01:32 cavs Exp $
# @@banner@@

=head1 NAME

Prospect::Options -- Package for representing options

S<$Id: Options.pm,v 1.8 2003/11/04 01:01:32 cavs Exp $>

=head1 SYNOPSIS

 use Prospect::Options;
 use Prospect::LocalClient;
 use Bio::SeqIO;
                                                                                                                                    
 my $in = new Bio::SeqIO( -format=> 'Fasta', '-file' => $ARGV[0] );
 my $po = new Prospect::Options( seq=>1, svm=>1, global_local=>1,
                 templates=>[qw(1bgc 1alu 1rcb 1eera)] );
 my $pf = new Prospect::LocalClient( {options=>$po} );

 while ( my $s = $in->next_seq() ) {
   my @threads = $pf->thread( $s );
 }

=head1 DESCRIPTION

B<Prospect::Options> represent options. 

=cut

package Prospect::Options;

use warnings;
use strict;
use fields qw/ global fssp scop seqfile phdfile tfile
				templates /;
use vars qw( $VERSION );
$VERSION = sprintf( "%d.%02d", q$Revision: 1.8 $ =~ /(\d+)\.(\d+)/ );



sub new
  {
  my $type = shift;
  my $self = @_ ? initialize(@_) : {};
  return( bless($self, $type) );
  }

sub initialize
  {
  my %self;
  if (ref $_[0])							# new blah ( { opt=>arg, ... } )
	{ %self = %{$_[0]}; }
  elsif ( $#_ % 2 )							# new blah (   opt=>arg, ...   )
	{ %self = @_; }
  return \%self;
  }

1;
