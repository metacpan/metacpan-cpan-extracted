package Net::Curl::Easier;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Net::Curl::Easier - Convenience wrapper around L<Net::Curl::Easy>

=head1 SYNOPSIS

    my $easy = Net::Curl::Easier->new( url => 'http://perl.org' )->perform();

    print $easy->body();

    # … or, to dig in to the response:
    my $response = HTTP::Response->parse( $easy->head() . $easy->body() );

=head1 DESCRIPTION

L<Net::Curl> is wonderful, but L<Net::Curl::Easy> is a bit clunky for
day-to-day use. This library attempts to make that, well, “easier”. :-)

This module extends Net::Curl::Easy, with differences as noted here:

=head1 DIFFERENCES FROM Net::Curl::Easy

=over

=item * The response headers and body go to an internal buffer by default.
Net::Curl::Easy simply adopts libcurl’s defaults, which is understandable
but frequently unhelpful.

=item * Character encoding. As of this writing Net::Curl::Easy uses
L<SvPV|https://perldoc.perl.org/perlapi#SvPV> to translate Perl strings to C,
which means that what libcurl receives depends on how Perl internally stores
your string. Thus, the same string given to Net::Curl::Easy can yield
different input to libcurl depending on how Perl has decided to store that
string.

This library fixes that by requiring all strings that it receives
to be B<byte> B<strings> and normalizing Perl’s internal storage before
calling into Net::Curl::Easy.

=item * Several methods are wrapped, as described below.

=back

=head1 SEE ALSO

=over

=item * L<Net::Curl::Promiser> wraps L<Net::Curl::Multi> with promises.
Recommended for concurrent queries!

=item * L<Net::Curl::Simple> takes a similar approach to this module but
presents a substantially different interface.

=back

=cut

#----------------------------------------------------------------------

use parent 'Net::Curl::Easy';

our $VERSION = '0.01';

#----------------------------------------------------------------------

=head1 METHODS

Besides those inherited from Net::Curl::Easy, this class defines:

=head2 $obj = I<OBJ>->set( $NAME1 => $VALUE1, $NAME2 => $VALUE2, .. )

C<setopt()>s multiple values in a single call. Instead of:

    $easy->setopt( Net::Curl::Easy::CURLOPT_URL, 'http://perl.org' );
    $easy->setopt( Net::Curl::Easy::CURLOPT_VERBOSE, 1 );

… you can do:

    $easy->set( url => 'http://perl.org', verbose => 1 );

See L<curl_easy_setopt(3)> for the full set of options you can give here.

Note that, since I<OBJ> is returned, you can chain calls to this with
calls to other methods like C<perform()>.

You may not need to call this method since C<new()> calls it for you.

=cut

sub set {
    splice @_, 1, 0, 'setopt';
    &_set_or_push;
}

=head2 $obj = I<OBJ>->push( $NAME1 => \@VALUES1, $NAME2 => \@VALUES2, .. )

Like C<set()>, but for C<pushopt()>.

=cut

sub push {
    splice @_, 1, 0, 'pushopt';
    &_set_or_push;
}

sub _set_or_push {
    my $self = shift;
    my $method = shift;

    my @to_set;
    while (my ($k, $v) = splice @_, 0, 2) {
        $k =~ tr<a-z><A-Z>;

        $k = __PACKAGE__->can("CURLOPT_$k") || do {
            require Carp;
            Carp::croak("CURLOPT_$k doesn’t exist!");
        };

        $k = $k->();

        CORE::push @to_set, [$k, $v];
    }

    $self->$method(@$_) for @to_set;

    return $self;
}

=head2 $value = I<OBJ>->get($NAME)

Like C<set()>, but for C<getinfo()>. This, of course, doesn’t return
I<OBJ>, so it can’t be chained.

=cut

sub get {
    my ($self, $name) = @_;

    $name =~ tr<a-z><A-Z>;

    my $nameval = __PACKAGE__->can("CURLINFO_$name") || do {
        require Carp;
        Carp::croak("CURLINFO_$name doesn’t exist!");
    };

    return $self->getinfo($nameval->());
}

=head2 $str = I<OBJ>->head()

Returns I<OBJ>’s internal HTTP response header buffer, as a byte string.

=cut

sub head { $_[0]{'head'} }

=head2 $str = I<OBJ>->body()

Returns the HTTP response body, as a byte string.

=cut

sub body { $_[0]{'body'} }

#----------------------------------------------------------------------

=head1 WRAPPED METHODS

=over

=item * C<new()> takes a list of key/value pairs and passes it to
an internal call to C<set()>. The returned object will always be a
(newly-created) hash reference.

=item * C<escape()> and C<send()> apply the character encoding fix described
above.

=item * C<setopt()> and C<pushopt()> fix character encoding and return
the instance object.

=item * C<perform()> returns the instance object.

=back

=cut

sub escape {
    utf8::downgrade($_[1]);

    return $_[0]->SUPER::escape($_[1]);
}

sub send {
    utf8::downgrade($_[1]);

    return $_[0]->SUPER::send($_[1]);
}

sub setopt {
    my ($self, $key, $value) = @_;

    utf8::downgrade($value) if !ref $value;

    $self->SUPER::setopt($key, $value);

    return $self;
}

sub pushopt {
    my ($self, $key, $values_ar) = @_;

    ref || utf8::downgrade($_) for @$values_ar;

    $self->SUPER::pushopt($key, $values_ar);

    return $self;
}

sub perform {
    my $self = shift;

    $self->SUPER::perform(@_);

    return $self;
}

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( { head => '', body => ''} );

    return $self->set(
        file => \$self->{'body'},
        headerdata => \$self->{'head'},
        @_,
    );
}

=head1 STATIC FUNCTIONS

For convenience, C<Net::Curl::Easy::strerror()> is aliased in this module.

=cut

*strerror = *Net::Curl::Easy::strerror;

#----------------------------------------------------------------------

=head1 LICENSE & COPYRIGHT

Copyright 2021 by Gasper Software Consulting. All rights reserved.

This library is licensed under the same terms as Perl itself.
See L<perlartistic> for details.

=cut

1;
