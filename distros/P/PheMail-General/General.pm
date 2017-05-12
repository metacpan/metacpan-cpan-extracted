package PheMail::General;

use 5.006;
use strict;
use warnings;
use vars qw($file);
require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use PheMail::General ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
ReadConfig	
);
our $VERSION = '0.01';

$file = "/usr/local/phemail/etc/phemail.conf";

# Preloaded methods go here.
sub ReadConfig($) {
    my $get = shift;
    open(CONF,"<$file");
    while(<CONF>) {
	chomp;
	return $1 if /^$get=(.+)/;
    }
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

PheMail::General - Perl extension for reading PheMail's configuration file.

=head1 SYNOPSIS

  use PheMail::General;
  print "Type: ".ReadConfig("type");

=head1 DESCRIPTION

This is used in project PheMail to extract directives from the configuration file.
This module is shared among the modules, so the ReadConfig method is globally shared.


=head2 EXPORT

ReadConfig();


=head1 AUTHOR

Jesper Noehr, E<lt>jesper@noehr.orgE<gt>

=head1 SEE ALSO

L<perl>.

=cut

