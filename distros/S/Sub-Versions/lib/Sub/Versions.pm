package Sub::Versions;
# ABSTRACT: Subroutine versioning syntactic sugar

use 5.014;
use exact;

use Sub::Util 'subname';
use Devel::Hook;

our $VERSION = '1.06'; # VERSION

my $versions;
my $subspaces;

sub import {
    my $package = ( caller() )[0];
    my $mca     = \&{"$package\::MODIFY_CODE_ATTRIBUTES"};

    _eq_sub( $package . '::MODIFY_CODE_ATTRIBUTES', sub {
        my ( $package, $code, @attrs ) = @_;
        $mca->(@_) if ( defined &$mca );

        my $version = substr( ( grep { /^v\d+$/ } @attrs )[0] || ' ', 1 );
        return unless ($version);

        my $name = subname($code);
        my ( $class, $method ) = $name =~ m/^(.+)::(.+?)$/;

        # store sub ref along with version in $versions for later use
        $versions->{$package}{$method} = [
            sort { $b->{version} <=> $a->{version} } (
                @{ $versions->{$package}{$method} || [] },
                {
                    version => $version,
                    code    => $code,
                },
            )
        ];

        # remove existing sub
        {
            no strict 'refs';
            undef *{$name};
        }

        # setup versioned sub
        _eq_sub( "${name}_v${version}", $code );

        # setup version interstitial objects
        my $subspace = __PACKAGE__ . "::Subspace::${package}::v${version}";
        unless ( defined &{"${package}::v${version}"} ) {
            _eq_sub( "${subspace}::new", sub {
                my ( $self, $object ) = @_;
                return bless( { version => $version, object => $object }, $self );
            } );
            _eq_sub( "${package}::v${version}", sub {
                return $subspaces->{"${package}::v${version}"} ||= "$subspace"->new(shift);
            } );
        }
        _eq_sub( "${subspace}::$method", sub {
            my $self = shift;
            my $target_method = "${method}_v${version}";
            $self->{object}->$target_method(@_);
        } );

        # setup most recent version as default sub
        Devel::Hook->push_INIT_hook( sub {
            for my $method ( keys %{ $versions->{$package} } ) {
                _eq_sub( $package . '::' . $method, $versions->{$package}{$method}[0]{code} );
            }
        } );

        # setup the subver() method functionality
        _eq_sub( "$package\::subver", sub {
            my ( $self, $version, $method ) = @_;
            ( my $v = $version ) =~ s/\s+//g;

            my ( $v_vector, $v_number ) = $v =~ /^([<>=]{0,2})(\d+)$/;
            $v_vector ||= '=';
            croak(qq{"$version" not a valid version criteria}) unless ( defined $v_number );

            # unique version numbers of any method matching the name $method
            my %versions_found = map {
                map { $_->{version} => 1 } @{ $versions->{$_}{$method} || [] }
            } keys %$versions;

            # valid version numbers based on version vector input
            my @valid_versions = sort { $b <=> $a } grep {
                ( $v_vector eq '='  ) ? $_ == $v_number :
                ( $v_vector eq '==' ) ? $_ == $v_number :
                ( $v_vector eq '>=' ) ? $_ >= $v_number :
                ( $v_vector eq '<=' ) ? $_ <= $v_number :
                ( $v_vector eq '>'  ) ? $_ >  $v_number :
                ( $v_vector eq '<'  ) ? $_ <  $v_number : $_ != $v_number
            } keys %versions_found;

            # pick the highest version that can be called off the object
            my $selected_version = ( grep { $self->can( $method . '_v' . $_ ) } @valid_versions )[0];

            if ( defined $selected_version ) {
                $selected_version = 'v' . $selected_version;
                return sub { $self->$selected_version->$method(@_) };
            }

            return sub { $self->$method(@_) } if ( $self->can($method) );

            croak(qq{No "$method" subroutine with "$version" version});
        } ) unless ( defined &{"$package\::subver"} );

        return;
    } );
}

sub _eq_sub {
    my ( $name, $code ) = @_;

    {
        no strict 'refs';
        *{$name} = $code;
    }

    return $code;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sub::Versions - Subroutine versioning syntactic sugar

=head1 VERSION

version 1.06

=for markdown [![test](https://github.com/gryphonshafer/Sub-Versions/workflows/test/badge.svg)](https://github.com/gryphonshafer/Sub-Versions/actions?query=workflow%3Atest)
[![codecov](https://codecov.io/gh/gryphonshafer/Sub-Versions/graph/badge.svg)](https://codecov.io/gh/gryphonshafer/Sub-Versions)

=head1 SYNOPSIS

    # ...in a class somewhere...

    package MyExampleClass;
    use strict;
    use warnings;
    use Sub::Versions;

    sub new {
        return bless( {}, shift );
    }

    sub simple_method : v1 {
        return 'version 1';
    }

    sub simple_method : v2 {
        return 'version 2';
    }

    # ...and just for this inline example:
    BEGIN { $INC{'MyExampleClass.pm'} = 1 }

    # ...meanwhile, elsewhere...

    use MyExampleClass;
    my $object = MyExampleClass->new;

    $object->simple_method;     # returns "version 2"
    $object->v1->simple_method; # returns "version 1"

    # select "simple_method" version 42 or higher if available
    $object->subver( '>= 42', 'simple_method' )->();

    # ...or with Moose...

    package MyOtherExampleClass;
    use Moose;
    use Sub::Versions;

    sub simple_method : v1 {
        return 'version 1';
    }

    sub simple_method : v2 {
        return 'version 2';
    }

=head1 DESCRIPTION

This module provides automatic syntactic sugar for simple subroutine versioning.
By specifying a version in the form "v#" as a subroutine attributes, this
module will perform a series of compile time symbol table surgeries so you
can call subroutines by explicit version or the latest version implicitly.

    use MyExampleClass;
    my $object = MyExampleClass->new;

    $object->simple_method;     # calls the latest version of the method
    $object->v1->simple_method; # calls version 1 of the method

Versions must be specified in the form C</v\d+/>. The exact version number you
use is irrelevant. The only importance is the relative value of the version
numbers to each other. The largest version number is considered the most
current version of the subroutine.

    package MyExampleClass;
    use Sub::Versions;

    sub simple_method : v1 {
        return 'version 1';
    }

    sub simple_method : v2 {
        return 'version 2';
    }

=head2 Explicit Versioned Methods

The compile time symbol table surgeries will result in a subroutine being
injected into your class a name that is the combination of the original
subroutine name and the version. So for example, if you have "simple_method"
and you specify it as the "v2" version, then "simple_method_v2" gets injected
into your class. You can access the method directly with this name if you
prefer. But the key thing to keep in mind is that if you write a
"simple_method_v2" method and have a "simple_method" method tied to the "v2"
version, then you'll get a subroutine redefined warning.

=head2 Motivation and Purpose

In the process of building an REST/JSON API web service, I found I needed a way
to very simply version calls to parts of the model. I needed to support legacy
versions in parallel with the most recent version and allow consumers to
explicitly call a particular version.

=head2 Sub Version Selection Method

If you don't know the version you want to access exactly, call the method
C<subver()> and provide it with a version vector and method name.

    # select "simple_method" version 42 or higher if available
    $object->subver( '>= 42', 'simple_method' )->();

You can: >, <, >=, <=, or =, with or without a space between that and the
version number. Only specifying a version number implies a = vector.

=head1 SEE ALSO

L<Sub::Util>, L<Devel::Hook>.

You can also look for additional information at:

=over 4

=item *

L<GitHub|https://github.com/gryphonshafer/Sub-Versions>

=item *

L<MetaCPAN|https://metacpan.org/pod/Sub::Versions>

=item *

L<GitHub Actions|https://github.com/gryphonshafer/Sub-Versions/actions>

=item *

L<Codecov|https://codecov.io/gh/gryphonshafer/Sub-Versions>

=item *

L<CPANTS|http://cpants.cpanauthors.org/dist/Sub-Versions>

=item *

L<CPAN Testers|http://www.cpantesters.org/distro/D/Sub-Versions.html>

=back

=for Pod::Coverage import

=head1 AUTHOR

Gryphon Shafer <gryphon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016-2050 by Gryphon Shafer.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
