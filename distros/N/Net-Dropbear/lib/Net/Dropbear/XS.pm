package Net::Dropbear::XS;

use strict;
use warnings;

our $VERSION = '0.16';

require XSLoader;
XSLoader::load( 'Net::Dropbear', $VERSION );

use parent qw/Exporter/;
our @EXPORT_OK = qw/HOOK_COMPLETE HOOK_CONTINUE HOOK_FAILURE/;

# Preloaded methods go here.

1;
__END__

=encoding utf-8

=head1 NAME

Net::Dropbear::XS - XS interface to Dropbear

=head1 DESCRIPTION

See L<Net::Dropbear::SSHd>.

=cut
