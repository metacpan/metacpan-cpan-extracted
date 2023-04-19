package OpenTracing::Implementation::DataDog::ID;

=head1 NAME

OpenTracing::Implementation::DataDog::ID - 64bit integers for DataDog

=head1 SYNOPSIS

    use OpenTracing::Implementation::DataDog::ID qw/random_datadog_id/;
    
    my $data_struct = {
        some_id => random_datadog_id();
    };

and later:

    print $data_struct->{some_id}->TO_JSON;

=cut



=head1 DESCRIPTION

This package ensures nice 64bit integers, as expected by DataDog. However, some
architectures do not support 64bit ints, and only go for 4 bytes.

Under the hood, this is just a nice abstract way to deal with a C<Math::BigInt>.

=cut



our $VERSION = 'v0.46.0';


use parent 'Math::BigInt';
use Math::BigInt::Random::OO;
#
# $random
#
# our internal BigInt::Random generator, we only instantiate once
#
my $random = Math::BigInt::Random::OO->new( length_bin => 63 );

use Exporter qw/import/;

our @EXPORT_OK = qw/random_datadog_id/;

=head1 EXPORTS OK

The following subroutines can be imported into your namespance:

=cut



=head2 random_datadog_id

Generates a 64bit integer (or actually a 63bit)

=cut

sub random_datadog_id { bless $random->generate() }



sub TO_JSON { $_[0]->bstr() };




=head1 SEE ALSO

=over

=item L<OpenTracing::Implementation::DataDog>

Sending traces to DataDog using Agent.

=back

=item L<Trace and Span ID Formats|https://docs.datadoghq.com/tracing/guide/span_and_trace_id_format/>

If you write code that interacts directly with Datadog tracing spans and traces,
here’s what you need to know about how span IDs and trace IDs are generated and
accepted by Datadog tracing libraries.

=back


=head1 AUTHOR

Theo van Hoesel <tvanhoesel@perceptyx.com>



=head1 COPYRIGHT AND LICENSE

'OpenTracing::Implementation::DataDog'
is Copyright (C) 2019 .. 2023, Perceptyx Inc

This library is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0.

This package is distributed in the hope that it will be useful, but it is
provided "as is" and without any express or implied warranties.

For details, see the full text of the license in the file LICENSE.


=cut

1;
