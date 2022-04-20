package PICA::Writer::Plus;
use v5.14.1;

our $VERSION = '2.03';

use charnames qw(:full);

use parent 'PICA::Writer::Base';

sub SUBFIELD_INDICATOR {"\N{INFORMATION SEPARATOR ONE}"}
sub END_OF_FIELD       {"\N{INFORMATION SEPARATOR TWO}"}
sub END_OF_RECORD      {"\N{LINE FEED}";}

1;
__END__

=head1 NAME

PICA::Writer::Plus - Normalized PICA+ format serializer

=head2 DESCRIPTION

See L<PICA::Writer::Base> for synopsis and details.

The counterpart of this module is L<PICA::Parser::Plus>.

=cut
