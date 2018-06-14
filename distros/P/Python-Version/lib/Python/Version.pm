package Python::Version;

#ABSTRACT: Python PEP440 compatible version string parser in Perl

use 5.010;
use strict;
use warnings;

our $VERSION = '0.0001'; #VERSION

use Sort::Versions;

use overload (
    'cmp'    => \&vcmp,
    '<=>'    => \&vcmp,
    fallback => 1,
);

# obtained from https://www.python.org/dev/peps/pep-0440
use constant RE_python_version => qr/^
    v?
    (?:
        (?:(?P<epoch>[0-9]+)!)?                           # epoch
        (?P<release>[0-9]+(?:\.[0-9]+)*)                  # release segment
        (?P<pre>                                          # pre-release
            [-_\.]?
            (?P<pre_l>(a|b|c|rc|alpha|beta|pre|preview))
            [-_\.]?
            (?P<pre_n>[0-9]+)?
        )?
        (?P<post>                                         # post release
            (?:-(?P<post_n1>[0-9]+))
            |
            (?:
                [-_\.]?
                (?P<post_l>post|rev|r)
                [-_\.]?
                (?P<post_n2>[0-9]+)?
            )
        )?
        (?P<dev>                                          # dev release
            [-_\.]?
            (?P<dev_l>dev)
            [-_\.]?
            (?P<dev_n>[0-9]+)?
        )?
    )
    (?:\+(?P<local>[a-z0-9]+(?:[-_\.][a-z0-9]+)*))?       # local version
$/x;


sub parse {
    my ( $proto, $version_str ) = @_;
    my $class = ref($proto) || $proto;

    if ( $version_str =~ RE_python_version ) {
        my (
            $epoch, $release, $pre,     $post,   $dev,     $local,
            $pre_l, $pre_n,   $post_n1, $post_l, $post_n2, $dev_n
          )
          = map { $+{$_} }
          qw(
          epoch release pre post dev local
          pre_l pre_n post_n1 post_l post_n2 dev_n
        );

        my $self = bless { _original => $version_str }, $class;
        $self->{_base_version} =
          [ map { int($_) } split( /\./, $release ) ];
        if ( defined $epoch ) {
            $self->{_epoch} = $epoch;
        }
        if ( defined $pre ) {
            $self->{_prerelease} = [ $self->_normalize_prerelease_label($pre_l),
                int( $pre_n // 0 ) ];
        }
        elsif ( defined $post ) {
            $self->{_postrelease} =
              [ 'post', int( $post_n1 // $post_n2 // 0 ) ];
        }
        if ( defined $dev ) {
            $self->{_devrelease} = [ 'dev', int( $dev_n // 0 ) ];
        }
        if ( defined $local ) {
            $self->{_local_version} =
              [ split( /[-_\.]/, $local ) ];
        }
        return $self;
    }
    else {
        die "Cannot parse Python version string '$version_str'";
    }
}

sub _normalize_prerelease_label {
    my ( $self, $label ) = @_;
    return 'a'  if $label eq 'alpha';
    return 'b'  if $label eq 'beta';
    return 'rc' if ( grep { $label eq $_ } qw(c pre preview) );
    return $label;
}


sub base_version {
    my $self = shift;
    return join( '.', @{ $self->{_base_version} } );
}


sub is_prerelease {
    my $self = shift;
    return !!( $self->{_prerelease} );
}

sub is_postrelease {
    my $self = shift;
    return !!( $self->{_postrelease} );
}

sub is_devrelease {
    my $self = shift;
    return !!( $self->{_devrelease} );
}


sub local {
    my $self = shift;
    if ( defined $self->{_local_version} ) {
        return join( '.', @{ $self->{_local_version} } );
    }
    else {
        return '';
    }
}


sub normal {
    my $self = shift;

    my $s = $self->public;
    if ( my $local = $self->local ) {
        $s .= "+$local";
    }
    return $s;
}


sub original {
    my ($self) = @_;
    return $self->{_original};
}


sub public {
    my $self = shift;

    my $s = '';
    if ( $self->{_epoch} ) {
        $s .= $self->{_epoch} . '!';
    }
    $s .= $self->base_version;
    if ( $self->is_prerelease ) {
        $s .= join( '', @{ $self->{_prerelease} } );
    }
    elsif ( $self->is_postrelease ) {
        $s .= '.' . join( '', @{ $self->{_postrelease} } );
    }
    if ( $self->is_devrelease ) {
        $s .= '.' . join( '', @{ $self->{_devrelease} } );
    }
    return $s;
}

sub vcmp {
    my ( $left, $right ) = @_;
    my $class = ref($left);
    unless ( UNIVERSAL::isa( $right, $class ) ) {
        $right = $class->parse($right);
    }

    my ( $l_epoch, $r_epoch ) = map { $_->{_epoch} // 0 } ( $left, $right );
    my $rslt_epoch = versioncmp( $l_epoch, $r_epoch );
    return $rslt_epoch if ( $rslt_epoch != 0 );

    my ( $l_base, $r_base ) =
      map { $_->base_version } ( $left, $right );
    my $rslt_base = versioncmp( $l_base, $r_base );
    return $rslt_base if ( $rslt_base != 0 );

    my ( $l_converted, $r_converted ) =
      map { $_->_convert_prepostdev; } ( $left, $right );
    my $rslt_converted =
      versioncmp( join( '.', @$l_converted ), join( '.', @$r_converted ) );
    return $rslt_converted if ( $rslt_converted != 0 );

    return versioncmp( $left->local, $right->local );
}

sub _convert_prepostdev {
    my $self = shift;

    # dev < pre < nothing < post
    my ( $dev, $pre, $final, $post ) = ( 0, 1, 2, 3 );

    my @segments;
    my $is_prerelease  = $self->is_prerelease;
    my $is_postrelease = $self->is_postrelease;
    my $is_devrelease  = $self->is_devrelease;
    if ( $is_prerelease or $is_postrelease ) {
        if ($is_prerelease) {
            push @segments, $pre, ( $self->{_prerelease}->[1] // 0 );
        }
        else {
            push @segments, $post, ( $self->{_postrelease}->[1] // 0 );
        }
        if ($is_devrelease) {
            push @segments, $dev, ( $self->{_devrelease}->[1] // 0 );
        }
        else {
            push @segments, $final;
        }
    }
    elsif ($is_devrelease) {
        push @segments, $dev;
    }
    else {
        push @segments, $final;
    }

    return \@segments;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Python::Version - Python PEP440 compatible version string parser in Perl

=head1 VERSION

version 0.0001

=head1 SYNOPSIS

    use Python::Version;
    
    my $v = Python::Version->parse("1.2.3pre2.dev1+ubuntu-1");
    
    print($v->normal);
    print($v->original);

    # Comparing versions
     
    if ( version->parse($vstr1) == version->parse($vstr2) ) {
      # do stuff
    }
     
    # Sorting versions
     
    my @ordered = sort { version->parse($a) <=> version->parse($b) } @list;

=head1 DESCRIPTION

This module provides a parser as well as comparion method for Python PEP440
compatible version string.

=head1 METHODS

=head2 parse($version_str)

Class method. It takes a PEP440-compatible string and returns a Python::Version
object.

    my $v = Python::Version->parse($version_str);

=head2 base_version()

Returns the normalized base part of the version.

=head2 is_prerelease()

Returns a boolean value for if the version is a pre-release.

=head2 is_postrelease()

Returns a boolean value for if the version is a post-release.

=head2 is_devrelease()

Returns a boolean value for if the version is a dev-release.

=head2 local()

Returns the normalized local version label.

=head2 normal()

Returns a string with a standard normalized form.  

=head2 original()

Returns the original version string which was used to create the object.

=head2 public()

Returns the normalized public version.

=head1 SEE ALSO

PEP 440 L<https://www.python.org/dev/peps/pep-0440/>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
