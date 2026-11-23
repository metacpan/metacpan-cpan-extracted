package Protobuf::Engine;

use strict;
use warnings;
use Carp qw(croak);

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

# Abstract Methods

sub create_message { croak "Abstract method" }
sub parse          { croak "Abstract method" }
sub serialize      { croak "Abstract method" }
sub merge          { croak "Abstract method" }
sub copy           { croak "Abstract method" }
sub to_json        { croak "Abstract method" }
sub from_json      { croak "Abstract method" }
sub to_perl        { croak "Abstract method" }
sub to_text        { croak "Abstract method" }

1;

__END__

=encoding UTF-8

=head1 NAME

Protobuf::Engine - Abstract base class for Protobuf execution engines

=head1 VERSION

version 0.14

=head1 SYNOPSIS

    # Select an engine via Protobuf::Message->new(profile => 'xs' | 'pure_perl')
    use Protobuf::Engine::XS;
    use Protobuf::Engine::PurePerl;

=head1 DESCRIPTION

C<Protobuf::Engine> defines the abstract interface implemented by the two
L<Protobuf> runtime backends: L<Protobuf::Engine::XS> (backed by C<upb> C/XS)
and L<Protobuf::Engine::PurePerl> (pure-Perl wire/JSON codec).

=head1 METHODS

Subclasses must implement:

=over 4

=item * C<create_message($class, $mdef, $arena, $flags)>

=item * C<parse($class, $data, $options)>

=item * C<serialize($msg)>

=item * C<merge($dst, $src)>

=item * C<copy($dst, $src)>

=item * C<to_json($msg)> / C<from_json($class, $json, $options)>

=item * C<to_perl($msg)> / C<to_text($msg)>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Engine::XS>, L<Protobuf::Engine::PurePerl>

=cut
