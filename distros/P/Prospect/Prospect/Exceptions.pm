# $Id: Exceptions.pm,v 1.11 2003/11/04 15:02:19 rkh Exp $
# @@banner@@

=head1 NAME

Prospect::Exceptions -- Set of Prospect specific exceptions.

S<$Id: Exceptions.pm,v 1.11 2003/11/04 15:02:19 rkh Exp $>

=head1 SYNOPSIS

=head1 DESCRIPTION

B<Prospect::Exceptions> is a set of exceptions specifically for
the Prospect perl package.  There excpetions are derived from
CBT::Exception

=head1 SEE ALSO

B<CBT::Exception>

=cut

use Error qw(:try);
use strict;
use warnings;


# include this directory so that we can use CBT::Execption
BEGIN {
  (my $thisDir = __FILE__) =~ s#Exceptions.pm$##;
  unshift(@INC,$thisDir);
}

package Prospect::Exception;
use base 'CBT::Exception';
use vars qw( $VERSION );
$VERSION = sprintf( "%d.%02d", q$Revision: 1.11 $ =~ /(\d+)\.(\d+)/ );


package Prospect::SequenceTooLarge;
use base 'Prospect::Exception';

package Prospect::BadUsage;
use base 'Prospect::Exception';

package Prospect::RuntimeError;
use base 'Prospect::Exception';

1;
