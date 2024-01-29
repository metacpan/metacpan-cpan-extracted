package Ryu;
# ABSTRACT: stream and data flow handling for async code
use strict;
use warnings;

# Older versions cannot complete the test suite successfully
use 5.018;

our $VERSION = '3.005';
our $AUTHORITY = 'cpan:TEAM'; # AUTHORITY

=encoding utf8

=head1 NAME

Ryu - asynchronous stream building blocks

=head1 SYNOPSIS

 #!/usr/bin/env perl
 use strict;
 use warnings;
 use Ryu qw($ryu);
 my ($lines) =
 	$ryu->from(\*STDIN)
 		->by_line
 		->filter(qr/\h/)
 		->count
 		->get;
 print "Had $lines line(s) containing whitespace\n";

=head1 DESCRIPTION

Provides data flow processing for asynchronous coding purposes. It's a bit like L<ReactiveX|https://reactivex.io> in
concept. Where possible, it tries to provide a similar API. It is not a directly-compatible implementation, however.

For more information, start with L<Ryu::Source>. That's where most of the
useful parts are.

=head2 Why would I be using this?

Eventually some documentation pages might appear, but at the moment they're unlikely to exist.

=over 4

=item * Network protocol implementations - if you're bored of stringing together C<substr>, C<pack>, C<unpack>
and C<vec>, try L<Ryu::Manual::Protocol> or L<Ryu::Buffer>.

=item * Extract, Transform, Load workflows (ETL) - need to pull data from somewhere, mangle it into shape, push it to
a database? that'd be L<Ryu::Manual::ETL>

=item * Reactive event handling - L<Ryu::Manual::Reactive>

=back

As an expert software developer with a keen eye for useful code, you may already be bored of this documentation
and on the verge of reaching for alternatives. The L</SEE ALSO> section may speed you on your way.

=head2 Compatibility

Since L<RxPerl> follows the ReactiveX conventions quite closely, we'd expect to have
the ability to connect L<RxPerl> observables to a L<Ryu::Source>, and provide an
adapter from a L<Ryu::Source> to act as an L<RxPerl>-style observable. This is not yet
implemented, but may be added in a future version.

Most of the other modules in L<SEE ALSO> are either not used widely enough or not a good
semantic fit for a compatibility layer - but if you're interested in this,
L<please ask about it|https://github.com/team-at-cpan/Ryu/issues> or provide patches!

=head2 Components

=head3 Sources

A source emits items. See L<Ryu::Source>. If in doubt, this is likely to be the class
that you wanted.

Items can be any scalar value - some examples:

=over 4

=item * a single byte

=item * a character

=item * a byte string

=item * a character string

=item * an object instance

=item * an arrayref or hashref

=back

=head3 Sinks

A sink receives items. It's the counterpart to a source. See L<Ryu::Sink>.

=head3 Streams

A stream is a thing with a source. See L<Ryu::Stream>, which is likely to be something that does not yet
have much documentation - in practice, the L<Ryu::Source> implementation covers most use-cases.

=head2 So what does this module do?

Nothing. It's just a top-level loader for pulling in all the other components.
You wanted L<Ryu::Source> instead, or possibly L<Ryu::Buffer>.

=head2 Some notes that might not relate to anything

With a single parameter, L</from> and L</to> will use the given
instance as a L<Ryu::Source> or L<Ryu::Sink> respectively.

Multiple parameters are a shortcut for instantiating the given source
or sink:

 my $stream = Ryu::Stream->from(
  file => 'somefile.bin'
 );

is equivalent to

 my $stream = Ryu::Stream->from(
  Ryu::Source->new(
   file => 'somefile.bin'
  )
 );

=head1 Why the name?

=over 4

=item * C< $ryu > lines up with typical 4-character indentation settings.

=item * there's Rx for other languages, and this is based on the same ideas

=item * 流 was too hard for me to type

=back

=cut

use Exporter qw(import export_to_level);

use Ryu::Source;

our $ryu = __PACKAGE__->new;

our @EXPORT_OK = qw($ryu);

our $FUTURE_FACTORY = sub {
    Future->new->set_label($_[1])
};

=head1 METHODS

Note that you're more likely to find useful methods in the following classes:

=over 4

=item * L<Ryu::Source>

=item * L<Ryu::Sink>

=item * L<Ryu::Observable>

=back

=cut

=head2 new

Instantiates a L<Ryu> object, allowing L</from>, L</just> and other methods.

=cut

sub new { bless { @_[1..$#_] }, $_[0] }

=head2 from

Helper method which returns a L<Ryu::Source> from a list of items.

=cut

sub from {
    my $self = shift;
    my $src = Ryu::Source->new;
    $src->from(@_)
}

=head2 just

Helper method which returns a single-item L<Ryu::Source>.

=cut

sub just {
    my $self = shift;
    my $src = Ryu::Source->new;
    $src->from(shift);
}

1;

__END__

=head1 SEE ALSO

=head2 Other modules

Some perl modules of relevance:

=over 4

=item * L<Future> - fundamental building block for one-shot tasks

=item * L<Future::Queue> - a FIFO queue for L<Future> tasks

=item * L<Future::Buffer> - provides equivalent functionality to L<Ryu::Buffer>

=item * L<POE::Filter> - venerable and battle-tested, but slightly short on features due to the focus on protocols

=item * L<Data::Transform> - standalone version of L<POE::Filter>

=item * L<List::Gen> - list mangling features

=item * L<HOP::Stream> - based on the Higher Order Perl book

=item * L<Flow> - quite similar in concept to this module, maybe a bit short on documentation, doesn't provide integration with other sources such as files or L<IO::Async::Stream>

=item * L<Flux> - more like the java8 streams API, sync-based

=item * L<Message::Passing> - on initial glance seemed more of a commandline tool, sadly based on L<AnyEvent>

=item * L<Rx.pl|https://github.com/eilara/Rx.pl> - a Perl version of the L<http://reactivex.io> Reactive API

=item * L<Perlude> - combines features of the shell / UNIX streams and Haskell, pipeline
syntax is "backwards" (same as grep/map chains in Perl)

=item * L<IO::Pipeline>

=item * L<DS>

=item * L<Evo>

=item * L<Async::Stream> - early release, but seems to be very similar in concept to L<Ryu::Source>

=item * L<Data::Monad>

=item * L<RxPerl> - previously known as L<Mojo::Rx>, targets close compatibility with L<rxjs|https://rxjs-dev.firebaseapp.com/guide/overview>

=back

=head2 Other references

There are various documents, specifications and discussions relating to the concepts we use. Here's a few:

=over 4

=item * L<http://www.reactivemanifesto.org/>

=item * Java 8 L<streams API|https://docs.oracle.com/javase/8/docs/api/java/util/stream/package-summary.html>

=item * C++ L<range-v3|https://github.com/ericniebler/range-v3>

=back

=head1 AUTHOR

Tom Molesworth C<< <TEAM@cpan.org> >> with contributions from:

=over 4

=item * Mohammad S Anwar

=item * Michael Mueller

=item * Zak Elep

=item * Mohanad Zarzour

=item * Nael Alolwani

=item * Amin Marashi

=back

=head1 LICENSE

Copyright Tom Molesworth 2011-2023. Licensed under the same terms as Perl itself.

