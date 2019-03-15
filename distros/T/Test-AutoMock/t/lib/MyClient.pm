package SuperClient;

sub get { MyClient::Response->new }

package MyClient;
use strict;
use warnings;
use parent -norequire => 'SuperClient';

sub new { bless {}, $_[0] }

package MyClient::Response;

sub new { bless {}, $_[0] }

sub is_success { 1 }

sub content { "BODY\n" }

1;
