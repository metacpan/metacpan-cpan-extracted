package Mojo::JSON::Any;

use strict;
use warnings;

our $VERSION = '0.990105';

use Mojo::JSON;

use constant JSONXS => ($ENV{MOJO_JSON})
  ? 0
  : eval { require JSON::XS; require Mojo::JSON::XS; 1 };

sub new { shift; JSONXS ? Mojo::JSON::XS->new(@_) : Mojo::JSON->new(@_) }

1;
__END__

=head1 NAME

Mojo::JSON::Any - Use JSON::XS when it's available (DEPRECATED)

=head1 SYNOPSIS

    use Mojo::JSON::Any;

    my $json   = Mojo::JSON::Any->new;
    my $string = $json->encode({foo => [1, 2], bar => 'hello!'});
    my $hash   = $json->decode('{"foo": [3, -2, 1]}');

=head1 DESCRIPTION

This modules is DEPRECATED. See L<MojoX::JSON::XS>

L<Mojo::JSON::Any> is a wrapper over L<Mojo::JSON> and L<JSON::XS>. When the last
is available it is used.

Interfaces are identical. Encoding parsing is the same as within L<Mojo::JSON>.

When using L<JSON::XS> is undesirable, even if it is available, set
C<MOJO_JSON> environment variable.

=head1 ATTRIBUTES

See L<Mojo::JSON>.

=head1 METHODS

See L<Mojo::JSON>.

=head1 SEE ALSO

L<Mojo::JSON>, L<JSON::XS>.

=head1 DEVELOPMENT

=head2 Repository

    http://github.com/vti/mojo-json-any

=head1 BUGS AND LIMITATIONS

In the following cases behavior of L<Mojo::JSON::Any> differs depending
on used backend module.

L<JSON::XS> doesn't support blessed references without TO_JSON method, so
L<Mojo::JSON::Any> doesn't support them too if L<JSON::XS> is used.

L<Mojo::JSON::Any> doesn't process error messages from backend modules,
this is why they differs depending on used backend module.

=head1 AUTHOR

The module is currently maintained by Yuriy Syrota, C<ysyrota@cpan.org>.

=head1 AUTHOR EMERITUS

Viacheslav Tykhanovskyi, C<vti@cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010, Viacheslav Tykhanovskyi.

This program is free software, you can redistribute it and/or modify
it under the terms of the Artistic License version 2.0.

=cut
