package MooseX::Has::Options::Handler::NativeTypes;
{
  $MooseX::Has::Options::Handler::NativeTypes::VERSION = '0.003';
}

# ABSTRACT: Option shortcuts for native types

use strict;
use warnings;

sub handles
{
    return (
        array   => { traits => ['Array']   },
        bool    => { traits => ['Bool']    },
        code    => { traits => ['Code']    },
        counter => { traits => ['Counter'] },
        hash    => { traits => ['Hash']    },
        number  => { traits => ['Number']  },
        string  => { traits => ['String']  },
    );
}

1;


__END__
=pod

=for :stopwords Peter Shangov hashrefs

=head1 NAME

MooseX::Has::Options::Handler::NativeTypes - Option shortcuts for native types

=head1 VERSION

version 0.003

=head1 DESCRIPTION

This module provides the following shortcut options for L<MooseX::Has::Options>:

=over

=item :array

Translates to C<< traits => ['Array'] >>

=item :bool

Translates to C<< traits => ['Bool'] >>

=item :code

Translates to C<< traits => ['Code'] >>

=item :counter

Translates to C<< traits => ['Counter'] >>

=item :hash

Translates to C<< traits => ['hash'] >>

=item :number

Translates to C<< traits => ['Number'] >>

=item :string

Translates to C<< traits => ['String'] >>

=back

=head1 AUTHOR

Peter Shangov <pshangov@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Peter Shangov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

