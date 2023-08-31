package PICA::Parser::Binary;
use v5.14.1;

our $VERSION = '2.12';

use charnames qw(:full);

use parent 'PICA::Parser::Plus';

sub SUBFIELD_INDICATOR {"\N{INFORMATION SEPARATOR ONE}"}
sub END_OF_FIELD       {"\N{INFORMATION SEPARATOR TWO}"}
sub END_OF_RECORD      {"\N{INFORMATION SEPARATOR THREE}"}

1;
__END__

=head1 NAME

PICA::Parser::Binary - Binary PICA+ format parser

=head1 DESCRIPTION

See L<PICA::Parser::Base> for synopsis and configuration.

The counterpart of this module is L<PICA::Writer::Binary>.

=cut
