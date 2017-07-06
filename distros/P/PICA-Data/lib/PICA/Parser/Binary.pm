package PICA::Parser::Binary;
use strict;
use warnings;

our $VERSION = '0.32';

use charnames qw(:full);
use Carp qw(croak);

use parent 'PICA::Parser::Plus';

sub SUBFIELD_INDICATOR { "\N{INFORMATION SEPARATOR ONE}" }
sub END_OF_FIELD       { "\N{INFORMATION SEPARATOR TWO}" }
sub END_OF_RECORD      { "\N{INFORMATION SEPARATOR THREE}" }

1;

__END__

=head1 NAME

PICA::Parser::Binary - Binary PICA+ format parser

=head2 DESCRIPTION

See L<PICA::Parser::Base> for synopsis and details.

The counterpart of this module is L<PICA::Writer::Binary>.

=cut
