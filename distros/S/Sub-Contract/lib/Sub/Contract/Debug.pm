#
#   Sub::Contract::Debug - Guess once...
#
#   $Id: Debug.pm,v 1.11 2009/06/16 12:23:58 erwan_lemonnier Exp $
#

package Sub::Contract::Debug;

use strict;
use warnings;
use Carp qw(croak);

use base qw(Exporter);

our $VERSION = '0.12';

our @EXPORT = ();
our @EXPORT_OK = ('debug');

# to turn on debugging output in Sub::Contract, just
# set $DEBUG to more than 0:

my $DEBUG = 0;

#---------------------------------------------------------------
#
#   debug - print a debug message to stdout
#

sub debug {
    my ($level,$text) = @_;

    if ($level <= $DEBUG) {
	chomp $text;
	my (undef, undef, $line) = caller(0);
	my (undef, undef, undef, $func) = caller(1);
	print "# DEBUG $func, l.".sprintf("%- 5s","$line:")." $text\n";
    }
}

1;

__END__

=head1 NAME

Sub::Contract::Debug - Display debug information

=head1 SYNOPSIS

    use Sub::Contract::Debug qw(debug);

    debug(1,"doing that");
    debug(2,"and that");

=head1 DESCRIPTION

To turn on debug information at various levels of verbosity,
set the variable $DEBUG within Sub::Contract::Debug to a
positive integer. The higher the value, the higher the
verbosity.

=head1 API

=over 4

=item C<< debug($level,$message) >>;

Print a debug message to stdout if C<$level> is lower or equal
to C<$Sub::Contract::Debug::DEBUG>.

=back

=head1 SEE ALSO

See 'Sub::Contract'.

=head1 VERSION

$Id: Debug.pm,v 1.11 2009/06/16 12:23:58 erwan_lemonnier Exp $

=head1 AUTHOR

Erwan Lemonnier C<< <erwan@cpan.org> >>

=head1 LICENSE

See Sub::Contract.

=cut



