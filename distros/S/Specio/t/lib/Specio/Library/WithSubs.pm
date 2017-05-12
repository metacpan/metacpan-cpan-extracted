package Specio::Library::WithSubs;

use strict;
use warnings;

use parent 'Specio::Exporter';

use Specio::Library::Builtins -reexport;
use Specio::Library::Numeric -reexport;
use Specio::Subs qw( Specio::Library::Builtins Specio::Library::Numeric );

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _also_export {
    return Specio::Subs::subs_installed_into(__PACKAGE__);
}

1;
