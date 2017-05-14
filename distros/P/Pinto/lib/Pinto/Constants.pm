# ABSTRACT: Constants used across the Pinto utilities

package Pinto::Constants;

use strict;
use warnings;

use Readonly;

use base 'Exporter';

#------------------------------------------------------------------------------

our $VERSION = '0.097'; # VERSION

#------------------------------------------------------------------------------

Readonly our @EXPORT_OK => qw(

    $PINTO_SERVER_DEFAULT_PORT
    $PINTO_SERVER_DEFAULT_HOST
    $PINTO_SERVER_DEFAULT_ROOT

    $PINTO_SERVER_STATUS_OK
    $PINTO_SERVER_DIAG_PREFIX
    $PINTO_SERVER_NULL_MESSAGE
    $PINTO_SERVER_PROGRESS_MESSAGE

    $PINTO_DEFAULT_COLORS
    $PINTO_COLOR_0
    $PINTO_COLOR_1
    $PINTO_COLOR_2

    $PINTO_LOCK_TYPE_SHARED
    $PINTO_LOCK_TYPE_EXCLUSIVE

    $PINTO_STACK_NAME_ALL

    $PINTO_AUTHOR_REGEX
    $PINTO_USERNAME_REGEX
    $PINTO_STACK_NAME_REGEX
    $PINTO_PROPERTY_NAME_REGEX
    $PINTO_REVISION_ID_REGEX

    $PINTO_MINIMUM_CPANM_VERSION
);

Readonly our %EXPORT_TAGS => (
    all    => \@EXPORT_OK,
    color  => [ grep {m/COLOR/x} @EXPORT_OK ],
    server => [ grep {m/SERVER/x} @EXPORT_OK ],
    regex  => [ grep {m/REGEX/x} @EXPORT_OK ],
    lock   => [ grep {m/LOCK/x} @EXPORT_OK ],
);

#------------------------------------------------------------------------------

Readonly our $PINTO_SERVER_DEFAULT_HOST => 'localhost';

Readonly our $PINTO_SERVER_DEFAULT_PORT => 3111;

Readonly our $PINTO_SERVER_DEFAULT_ROOT => "http://$PINTO_SERVER_DEFAULT_HOST:$PINTO_SERVER_DEFAULT_PORT";

#------------------------------------------------------------------------------

Readonly our $PINTO_SERVER_DIAG_PREFIX => '## ';

Readonly our $PINTO_SERVER_STATUS_OK => "${PINTO_SERVER_DIAG_PREFIX}Status: ok";

Readonly our $PINTO_SERVER_NULL_MESSAGE => "${PINTO_SERVER_DIAG_PREFIX}-- ##";

Readonly our $PINTO_SERVER_PROGRESS_MESSAGE => "${PINTO_SERVER_DIAG_PREFIX}. ##";

#------------------------------------------------------------------------------

Readonly our $PINTO_DEFAULT_COLORS => [qw(green yellow red)];

Readonly our $PINTO_COLOR_0 => 0;
Readonly our $PINTO_COLOR_1 => 1;
Readonly our $PINTO_COLOR_2 => 2;

#------------------------------------------------------------------------------

Readonly our $PINTO_LOCK_TYPE_SHARED    => 'SH';
Readonly our $PINTO_LOCK_TYPE_EXCLUSIVE => 'EX';

#------------------------------------------------------------------------------

Readonly our $PINTO_STACK_NAME_ALL => '%';

#------------------------------------------------------------------------------

Readonly my $PINTO_ALPHANUMERIC_REGEX     => qr{^ [a-zA-Z0-9-._]+ $}x;
Readonly my $PINTO_HEXADECIMAL_UUID_REGEX => qr{^ [a-f0-9-]+      $}x;

Readonly our $PINTO_AUTHOR_REGEX        => qr/^ [A-Z]{2} [-A-Z0-9]* $/x;
Readonly our $PINTO_USERNAME_REGEX      => $PINTO_ALPHANUMERIC_REGEX;
Readonly our $PINTO_STACK_NAME_REGEX    => $PINTO_ALPHANUMERIC_REGEX;
Readonly our $PINTO_PROPERTY_NAME_REGEX => $PINTO_ALPHANUMERIC_REGEX;
Readonly our $PINTO_REVISION_ID_REGEX   => $PINTO_HEXADECIMAL_UUID_REGEX;

#------------------------------------------------------------------------------

Readonly our $PINTO_MINIMUM_CPANM_VERSION => '1.6920';

#------------------------------------------------------------------------------
1;

__END__

=pod

=encoding UTF-8

=for :stopwords Jeffrey Ryan Thalhammer BenRifkah Fowler Jakob Voss Karen Etheridge Michael
G. Bergsten-Buret Schwern Oleg Gashev Steffen Schwigon Tommy Stanton
Wolfgang Kinkeldei Yanick Boris Champoux hesco popl Däppen Cory G Watson
David Steinbrunner Glenn

=head1 NAME

Pinto::Constants - Constants used across the Pinto utilities

=head1 VERSION

version 0.097

=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@stratopan.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jeffrey Ryan Thalhammer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
