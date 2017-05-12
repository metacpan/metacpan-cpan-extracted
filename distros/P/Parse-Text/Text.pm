package Parse::Text;

use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Parse::Text ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.02';


# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Parse::Text - Perl module for parsing plain text files

=head1 SYNOPSIS

  use Parse::Text;

=head1 DESCRIPTION

This is currently a place holder for a very powerful, full feature plain
text parser.

=head2 EXPORT

None by default.


=head1 AUTHOR

Casey Tweten, E<lt>crt@kiski.netE<gt>

=head1 SEE ALSO

L<perl>.

=cut
