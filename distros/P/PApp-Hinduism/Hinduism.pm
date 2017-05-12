package PApp::Hinduism;

require 5.005_62;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use PApp::Hinduism ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.09';


# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

PApp::Hinduism - database driven Hindu course database. 

=head1 SYNOPSIS

cannot be summarized here.

=head1 DESCRIPTION

This module exemplifies how to use DBIx::Recordset, DBIx::AnyDBD (now rolled into DBI), PApp::SQL,
and DBIx::Connect to create a database-driven application.

=head2 EXPORT

None by default.


=head1 AUTHOR

T. M. Brannon, <tbone@cpan.org>

=head1 SEE ALSO

perl(1).

=cut
