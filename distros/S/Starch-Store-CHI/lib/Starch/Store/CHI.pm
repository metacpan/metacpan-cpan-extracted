package Starch::Store::CHI;

$Starch::Store::CHI::VERSION = '0.04';

=head1 NAME

Starch::Store::CHI - Starch storage backend using CHI.

=head1 SYNOPSIS

    my $starch = Starch->new(
        store => {
            class => '::CHI',
            chi => {
                driver => 'File',
                root_dir => '/path/to/root',
            },
        },
        ...,
    );

=head1 DESCRIPTION

This L<Starch> store uses L<CHI> to set and get state data.

=head1 EXCEPTIONS

By default L<CHI> will catch errors and log them using L<Log::Any>
and keep on going as if nothing went wrong.  In Starch, stores are
expected to loudly throw exceptions, so it is suggested that you
specify these arguments to your CHI driver:

    on_get_error => 'die',
    on_set_error => 'die',

And then, if you still want the errors logged, you can use
L<Starch::Plugin::LogStoreExceptions>.  This is especially
important if you are using the L<Starch::Plugin::TimeoutStore>
plugin which will throw an exception when the timeout is exceeded
which then CHI will catch and log by default, which is not what
you want.

=head1 PERFORMANCE

When using CHI there are various choices you need to make:

=over

=item *

Which backend to use?  If data persistence is not an issue, or
you're using CHI as your outer store in L<Starch::Store::Layered>
then Memcached or Redis are common solutions which have high
performance.

=item *

Which serializer to use?  Nowadays L<Sereal> is the serialization
performance heavyweight, with L<JSON::XS> coming up a close second.

=item *

Which driver to use?  Some backends have more than one driver, and
some drivers perform better than others.  The most common example of
this is Memcached which has three drivers which can be used with
CHI.

=back

Make sure you ask these questions when you implement CHI for
Starch, and take the time to answer them well.  It can make a big
difference.

=cut

use CHI;
use Types::Standard -types;
use Types::Common::String -types;
use Scalar::Util qw( blessed );

use Moo;
use strictures 2;
use namespace::clean;

with qw(
    Starch::Store
);

after BUILD => sub{
  my ($self) = @_;

  # Get this loaded as early as possible.
  $self->chi();

  return;
};

=head1 REQUIRED ARGUMENTS

=head2 chi

This must be set to either hash ref arguments for L<CHI> or a
pre-built CHI object (often retrieved using a method proxy).

When configuring Starch from static configuration files using a
L<method proxy|Starch/METHOD PROXIES>
is a good way to link your existing L<CHI> object constructor
in with Starch so that starch doesn't build its own.

=cut

has _chi_arg => (
    is       => 'ro',
    isa      => (InstanceOf[ 'CHI::Driver' ]) | HashRef,
    init_arg => 'chi',
    required => 1,
);

has chi => (
    is       => 'lazy',
    isa      => InstanceOf[ 'CHI::Driver' ],
    init_arg => undef,
);
sub _build_chi {
    my ($self) = @_;

    my $chi = $self->_chi_arg();
    return $chi if blessed $chi;

    return CHI->new( %$chi );
}

=head1 METHODS

=head2 set

Set L<Starch::Store/set>.

=head2 get

Set L<Starch::Store/get>.

=head2 remove

Set L<Starch::Store/remove>.

=cut

sub set {
    my ($self, $id, $namespace, $data, $expires) = @_;

    local $Carp::Interal{ (__PACKAGE__) } = 1;

    $self->chi->set(
        $self->stringify_key( $id, $namespace ),
        $data,
        $expires ? ($expires) : (),
    );

    return;
}

sub get {
    my ($self, $id, $namespace) = @_;

    local $Carp::Interal{ (__PACKAGE__) } = 1;

    return $self->chi->get(
        $self->stringify_key( $id, $namespace ),
    );
}

sub remove {
    my ($self, $id, $namespace) = @_;

    local $Carp::Interal{ (__PACKAGE__) } = 1;

    $self->chi->remove(
        $self->stringify_key( $id, $namespace ),
    );

    return;
}

1;
__END__

=head1 SUPPORT

Please submit bugs and feature requests to the
Starch-Store-CHI GitHub issue tracker:

L<https://github.com/bluefeet/Starch-Store-CHI/issues>

=head1 AUTHOR

Aran Clary Deltac <bluefeetE<64>gmail.com>

=head1 ACKNOWLEDGEMENTS

Thanks to L<ZipRecruiter|https://www.ziprecruiter.com/>
for encouraging their employees to contribute back to the open
source ecosystem.  Without their dedication to quality software
development this distribution would not exist.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

