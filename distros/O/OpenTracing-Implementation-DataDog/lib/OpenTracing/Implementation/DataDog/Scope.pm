package OpenTracing::Implementation::DataDog::Scope;

=head1 NAME

OpenTracing::Implementation::DataDog::Scope - A DataDog specific Scope

=head1 DESCRIPTION

This class merely exists because of the wrong design choice, and having a
DataDog dependend ScopeManager.

The desire is to generate a generic OT ScopeManager for different types of
scopes and how they are handles in asynchronous environments. If ever.

=cut



our $VERSION = 'v0.46.0';

use Moo;

BEGIN {
    with 'OpenTracing::Role::Scope';
}



=head1 SEE ALSO

=over

=item L<OpenTracing::Implementation::DataDog>

Sending traces to DataDog using Agent.

=item L<OpenTracing::Role::Scope>

Role for OpenTracing Implementations.

=back



=head1 AUTHOR

Theo van Hoesel <tvanhoesel@perceptyx.com>



=head1 COPYRIGHT AND LICENSE

'OpenTracing::Implementation::DataDog'
is Copyright (C) 2019 .. 2021, Perceptyx Inc

This library is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0.

This package is distributed in the hope that it will be useful, but it is
provided "as is" and without any express or implied warranties.

For details, see the full text of the license in the file LICENSE.


=cut

1;
