package Silki::Exceptions;
{
  $Silki::Exceptions::VERSION = '0.29';
}

use strict;
use warnings;

my %E;

BEGIN {
    %E = (
        'Silki::Exception' => {
            alias       => 'error',
            description => 'Generic super-class for Silki exceptions'
        },

        'Silki::Exception::DataValidation' => {
            isa         => 'Silki::Exception',
            alias       => 'data_validation_error',
            fields      => ['errors'],
            description => 'Invalid data given to a method/function'
        },
    );
}

{

    package Silki::Exception::DataValidation;
{
  $Silki::Exception::DataValidation::VERSION = '0.29';
}

    sub messages { @{ $_[0]->errors || [] } }

    sub full_message {
        if ( my @m = $_[0]->messages ) {
            return join "\n", 'Data validation errors: ',
                map { ref $_ ? $_->{message} : $_ } @m;
        }
        else {
            return $_[0]->SUPER::full_message();
        }
    }
}

use Exception::Class (%E);

Silki::Exception->Trace(1);

use Exporter qw( import );

our @EXPORT_OK = map { $_->{alias} || () } values %E;

1;

# ABSTRACT: Exception classes used by Silki

__END__
=pod

=head1 NAME

Silki::Exceptions - Exception classes used by Silki

=head1 VERSION

version 0.29

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut

