package Playwright::Base;
$Playwright::Base::VERSION = '1.532';
use strict;
use warnings;

use v5.28;

use Sub::Install();

use JSON;
use Playwright::Util();

#ABSTRACT: Object representing Playwright pages

no warnings 'experimental';
use feature qw{signatures};

sub new ( $class, %options ) {

    my $self = bless(
        {
            type   => $options{type},
            guid   => $options{id},
            ua     => $options{handle}{ua},
            port   => $options{handle}{port},
            host   => $options{handle}{host},
            parent => $options{parent},
        },
        $class
    );

    return ($self);
}

sub _coerce ( $spec, %args ) {

    #Coerce bools correctly
    my @argspec = values( %{ $spec->{ $args{command} }{args} } );
    @argspec = sort { $a->{order} <=> $b->{order} } @argspec;

    for ( my $i = 0 ; $i < scalar(@argspec) ; $i++ ) {
        next unless $i < @{ $args{args} };
        my $arg  = $args{args}[$i];
        my $type = $argspec[$i]->{type};
        if ( $type->{name} eq 'boolean' ) {
            my $truthy = int( !!$arg );
            $args{args}[$i] = $truthy ? JSON::true : JSON::false;
        }
        elsif ( $type->{name} eq 'Object' ) {
            $type->{properties} =
              Playwright::Util::arr2hash( $type->{properties}, 'name' )
              if ref $type->{properties} eq 'ARRAY';
            foreach my $prop ( keys( %{ $type->{properties} } ) ) {
                next unless exists $arg->{$prop};
                my $truthy = int( !!$arg->{$prop} );
                next unless $type->{properties}{$prop}{type}{name} eq 'boolean';
                $args{args}[$i]->{$prop} = $truthy ? JSON::true : JSON::false;
            }
        }
    }

    return %args;
}

sub _api_request ( $self, %args ) {

    %args = Playwright::Base::_coerce( $self->spec(), %args );

    return Playwright::Util::async(
        sub { &Playwright::Base::_do( $self, %args ) } )
      if $args{command} =~ m/^waitFor/;

    my $msg = Playwright::Base::_do->( $self, %args );

    if ( ref $msg eq 'ARRAY' ) {
        @$msg = map {
            my $subject = $_;
            $subject = $Playwright::mapper{ $_->{_type} }->( $self, $_ )
              if ( ref $_ eq 'HASH' )
              && $_->{_type}
              && exists $Playwright::mapper{ $_->{_type} };
            $subject
        } @$msg;
    }
    return $Playwright::mapper{ $msg->{_type} }->( $self, $msg )
      if ( ref $msg eq 'HASH' )
      && $msg->{_type}
      && exists $Playwright::mapper{ $msg->{_type} };
    return $msg;
}

sub _do ( $self, %args ) {
    return Playwright::Util::request( 'POST', 'command', $self->{host},
        $self->{port}, $self->{ua}, %args );
}

sub spec {
    return $Playwright::spec;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Playwright::Base - Object representing Playwright pages

=head1 VERSION

version 1.532

=head2 DESCRIPTION

Base class for each Playwright class magic'd up by Sub::Install in Playwright's BEGIN block.
You probably shouldn't use this.

The specification for each class can be inspected with the 'spec' method:

    use Data::Dumper;
    my $object = Playwright::Base->new(...);
    print Dumper($object->spec());

=head1 CONSTRUCTOR

=head2 new(HASH) = (Playwright::Base)

Creates a new page and returns a handle to interact with it.

=head3 INPUT

    handle (Playwright)    : Playwright object.
    id (STRING)            : _guid returned by a response from the Playwright server with the provided type.
    type (STRING)          : Type to actually use
    parent (Playwright::*) : Parent Object (such as a page)

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Playwright|Playwright>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/teodesian/playwright-perl/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <teodesian@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2020 Troglodyne LLC


Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
