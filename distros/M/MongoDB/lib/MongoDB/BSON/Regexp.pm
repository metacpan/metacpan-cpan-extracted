use strict;
use warnings;
package MongoDB::BSON::Regexp;
# ABSTRACT: Regular expression type

use version;
our $VERSION = 'v1.8.1';

use Moo;
use MongoDB::Error;
use Types::Standard qw(
    Str
);
use namespace::clean -except => 'meta';

#pod =attr pattern
#pod
#pod A string containing a regular expression pattern (without slashes)
#pod
#pod =cut

has pattern => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

#pod =attr flags
#pod
#pod A string with regular expression flags
#pod
#pod =cut

has flags => (
    is        => 'ro',
    isa       => Str,
    required  => 0,
    predicate => 'has_flags',
    writer    => '_set_flags',
);

my %ALLOWED_FLAGS = (
    i   => 1,
    m   => 1,
    x   => 1,
    l   => 1,
    s   => 1,
    u   => 1
);

sub BUILD {
    my $self = shift;

    if ( $self->has_flags ) {
        my %seen;
        my @flags = grep { !$seen{$_}++ } split '', $self->flags;
        foreach my $f( @flags ) {
            MongoDB::UsageError->throw("Regexp flag $f is not supported by MongoDB")
              if not exists $ALLOWED_FLAGS{$f};
        }

        $self->_set_flags( join '', sort @flags );
    }
}

#pod =method try_compile
#pod
#pod     my $qr = $regexp->try_compile;
#pod
#pod Tries to compile the C<pattern> and C<flags> into a reference to a regular
#pod expression.  If the pattern or flags can't be compiled, a
#pod C<MongoDB::DecodingError> exception will be thrown.
#pod
#pod B<SECURITY NOTE>: Executing a regular expression can evaluate arbitrary
#pod code.  You are strongly advised never to use untrusted input with
#pod C<try_compile>.
#pod
#pod =cut

sub try_compile {
    my ($self) = @_;
    my ( $p, $f ) = map { $self->$_ } qw/pattern flags/;
    my $re = eval { qr/(?$f:$p)/ };
    MongoDB::DecodingError->throw("error compiling regex 'qr/$p/$f': $@")
      if $@;
    return $re;
}


1;

# vim: set ts=4 sts=4 sw=4 et tw=75:

__END__

=pod

=encoding UTF-8

=head1 NAME

MongoDB::BSON::Regexp - Regular expression type

=head1 VERSION

version v1.8.1

=head1 ATTRIBUTES

=head2 pattern

A string containing a regular expression pattern (without slashes)

=head2 flags

A string with regular expression flags

=head1 METHODS

=head2 try_compile

    my $qr = $regexp->try_compile;

Tries to compile the C<pattern> and C<flags> into a reference to a regular
expression.  If the pattern or flags can't be compiled, a
C<MongoDB::DecodingError> exception will be thrown.

B<SECURITY NOTE>: Executing a regular expression can evaluate arbitrary
code.  You are strongly advised never to use untrusted input with
C<try_compile>.

=head1 AUTHORS

=over 4

=item *

David Golden <david@mongodb.com>

=item *

Rassi <rassi@mongodb.com>

=item *

Mike Friedman <friedo@friedo.com>

=item *

Kristina Chodorow <k.chodorow@gmail.com>

=item *

Florian Ragwitz <rafl@debian.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by MongoDB, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
