package    # HIDE FROM PAUSE INDEXER
  LWP::UserAgent;

use strict;
use warnings;
use unmocked 'Data::Dumper';

sub new { my $class = shift; bless {@_}, $class; }
sub agent { shift->{agent} }

our $LAST_POST_URL;
our $LAST_POST_ARGUMENTS;

sub post {
  my ( $self, $url, $args ) = @_;
  $LAST_POST_URL       = $url;
  $LAST_POST_ARGUMENTS = {%$args};

  return HTTP::Response->new();
}

package    # HIDE FROM PAUSE INDEXER
  HTTP::Response;

use strict;
use warnings;

our $CONTENT = '';
our $SUCCESS = 1;
our $STATUS  = '';

sub new { my $class = shift; bless {@_}, $class; }
sub is_success  { $SUCCESS }
sub content     { $CONTENT }
sub status_line { $STATUS }
1;
