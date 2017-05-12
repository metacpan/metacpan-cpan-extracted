package Seis::Exceptions;
use strict;
use warnings;
use utf8;
use 5.010_001;

package Seis::Exception::ParsingError;
use parent qw(Seis::Exception);

package Seis::Exception::NotImplemented;
use parent qw(Seis::Exception);

package Seis::Exception::UnknownNode;
use parent qw(Seis::Exception);

package Seis::Exception::CompilationFailed;
use parent qw(Seis::Exception);

package Seis::Exception::ArgumentCount;
use parent qw(Seis::Exception);

package Seis::Exception::IO;
use parent qw(Seis::Exception);

1;

