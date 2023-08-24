package PICA::Writer::Binary;
use v5.14.1;

our $VERSION = '2.11';

use charnames qw(:full);

use parent 'PICA::Writer::Plus';

sub SUBFIELD_INDICATOR {"\N{INFORMATION SEPARATOR ONE}"}
sub END_OF_FIELD       {"\N{INFORMATION SEPARATOR TWO}"}
sub END_OF_RECORD      {"\N{INFORMATION SEPARATOR THREE}"}

1;
__END__

=head1 NAME

PICA::Writer::Binary - Binary PICA+ format serializer

=head2 DESCRIPTION

Binary PICA+ equals normalized PICA+ (L<PICA::Writer::Plus>) but uses
information separator three instead of newline as record separator.

See L<PICA::Writer::Base> for synopsis and details.

The counterpart of this module is L<PICA::Parser::Binary>.

=cut
