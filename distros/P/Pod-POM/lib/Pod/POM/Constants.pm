#============================================================= -*-Perl-*-
#
# Pod::POM::Constants
#
# DESCRIPTION
#   Constants used by Pod::POM.
#
# AUTHOR
#   Andy Wardley   <abw@kfs.org>
#   Andrew Ford    <a.ford@ford-mason.co.uk>
#
# COPYRIGHT
#   Copyright (C) 2000, 2001 Andy Wardley.  All Rights Reserved.
#   Copyright (C) 2009 Andrew Ford.  All Rights Reserved.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
# REVISION
#   $Id: Constants.pm 89 2013-05-30 07:41:52Z ford $
#
#========================================================================

package Pod::POM::Constants;
$Pod::POM::Constants::VERSION = '2.01';
require 5.006;

use strict;
use warnings;

use parent qw( Exporter );

our @SEQUENCE  = qw( CMD LPAREN RPAREN FILE LINE CONTENT );
our @STATUS    = qw( IGNORE REDUCE REJECT );
our @EXPORT_OK = ( @SEQUENCE, @STATUS );
our %EXPORT_TAGS = ( 
    status => [ @STATUS ], 
    seq    => [ @SEQUENCE ],
    all    => [ @STATUS, @SEQUENCE ], 
);

# sequence items
use constant CMD     => 0;
use constant LPAREN  => 1;
use constant RPAREN  => 2;
use constant FILE    => 3;
use constant LINE    => 4;
use constant CONTENT => 5;

# node add return values
use constant IGNORE => 0;
use constant REDUCE => 1;
use constant REJECT => 2;


1;

=head1 NAME

Pod::POM::Constants - constants used for Pod::POM

=head1 DESCRIPTION

Constants used by Pod::POM.

=head1 AUTHOR

Andy Wardley E<lt>abw@kfs.orgE<gt>

Andrew Ford E<lt>a.ford@ford-mason.co.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2000, 2001 Andy Wardley.  All Rights Reserved.

Copyright (C) 2009 Andrew Ford.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
