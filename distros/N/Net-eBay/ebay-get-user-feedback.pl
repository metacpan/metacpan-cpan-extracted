#!/usr/bin/perl

use strict;
use warnings;
  
use Net::eBay;
use Data::Dumper;
use DateTime::Precise;
use Getopt::Long;

sub usage {
  my ($msg) = @_;

  print STDERR "Error!  $msg \n\n
USAGE: $0 [userid]
";
  exit 1;
}

sub printable {
  my $str = shift;
  $str =~ tr/\x80-\xFF//d;
  $str =~ tr/\x00-\x1F//d;
  return "$str";
}

my $eBay = new Net::eBay;

my ($userid);

my $count = 25;
my $filter = undef;
my $negs = 1;
my $detail = undef;

GetOptions(
           "count=i"  => \$count,
           "filter=s" => \$filter,
           "negs!"    => \$negs,
           "detail!"  => \$detail,
          );

$userid = shift;

# use new eBay API
$eBay->setDefaults( { API => 2, debug => 0, compatibility => 415 } );

my $request = { DetailLevel => 'ReturnAll' };

$request->{UserID} = $userid if defined $userid;

$request->{Pagination}->{EntriesPerPage} = $count;

my $result = $eBay->submitRequest( "GetFeedback", $request );

#print Dumper( $result );

my $retcode = 1;

if( ref $result ) {
  print "Score $result->{FeedbackSummary}->{UniquePositiveFeedbackCount} -$result->{FeedbackSummary}->{UniqueNegativeFeedbackCount}\n" unless $filter;
  
  my $items = $result->{FeedbackDetailArray}->{FeedbackDetail};
  if( $items ) { 
    $items = [$items] if( ref $items eq 'HASH' );
    
    foreach my $i (@$items) {
      last if $count-- <= 0;
      
      print Dumper( $i ) if $detail;
      next if $filter && (!defined( $i->{ItemTitle} ) || ($i->{ItemTitle} !~ /$filter/i ));
        
      if( 0 ) {
        my $dummy = {
                     'FeedbackID' => '5556342524',
                     'CommentType' => 'Positive',
                     'Role' => 'Buyer',
                     'TransactionID' => '519332864',
                     'ItemID' => '260013673812',
                     'CommentTime' => '2006-08-05T21:06:21.000Z',
                     'CommentingUserScore' => '4',
                     'CommentingUser' => 'spuds6014',
                     'CommentText' => 'Excellent Bidder!!!!! CONGRATS.....:)'
                    };
      }

      my $title = "";
      if( $i->{ItemTitle} ) {
        $title .= "\n\t-- $i->{ItemTitle}";
      }

      # when we do not want negs
      next if (!$negs && $i->{CommentType} ne 'Positive' );
      
      print "$i->{CommentType} $i->{ItemID} " .  sprintf( "%15s", $i->{CommentingUser} ) . " $i->{Role} " . printable( $i->{CommentText} ) . " $title\n";
      #print "\n";

      $retcode = 0;
    }
  } else {
    #print Dumper( $result );
  }
} else {
  print "Unparsed result: \n$result\n\n";
}


exit $retcode;
