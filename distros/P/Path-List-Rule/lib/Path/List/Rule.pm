package Path::List::Rule;

# ABSTRACT: Path::Iterator::Rule on an list of paths

use 5.012;

use strict;
use warnings;

our $VERSION = '0.02';

use File::Spec::Functions ();
use parent 'Path::Iterator::Rule';

{
    package    # avoid CPAN indexing
      Path::List::Rule::Entry;

    use overload
      '-X'     => '_statit',
      'bool'   => sub { 1 },
      '""'     => 'stringify',
      fallback => 1,
      ;

    sub _croak {
        require Carp;
        goto \&Carp::croak;
    }

    sub new {
        my ( $class, $fs, $path, $leaf ) = @_;

        substr($path,-1,1,'') if substr($path,-1,1) eq q{/};
        my %self = (
            exists => 1,
            path   => $path,
            leaf   => $leaf,
            fs     => {},
        );

        # doesn't exist
        if ( !defined $fs ) {
            $self{is_dir} = $self{is_file} = $self{exists} = 0;
        }
        # maybe a file
        elsif ( defined $leaf ) {
            $self{is_dir}  = defined $fs->{$leaf};
            $self{is_file} = !defined $fs->{$leaf};
            $self{fs}      = $fs->{$leaf} if $self{is_dir};
        }
        # not a file
        else {
            $self{is_dir}  = 1;
            $self{is_file} = 0;
            $self{fs}      = $fs;
        }

        return bless \%self, $class;
    }

    sub _children {
        my $self = shift;
        return map { __PACKAGE__->new( $self->{fs}, "$self->{path}/$_", $_ ) } keys %{ $self->{fs} };
    }

    sub _statit {
        my ( $self, $op ) = @_;
        if    ( $op eq 'e' ) { return $self->{exists} }
        if    ( $op eq 'l' ) { return 0; }
        if    ( $op eq 'r' ) { return 1; }
        elsif ( $op eq 'd' ) { return $self->{is_dir} }
        elsif ( $op eq 'f' ) { return $self->{is_file} }
        else                 { _croak( "unsupported file test: -$op\n" ) }
    }

    sub is_dir {
        return !! $_[0]->{is_dir};
    }

    sub is_file {
        return !! $_[0]->{is_file};
    }

    sub exists {
        return !! $_[0]->{exists};
    }

    sub stringify {
        return $_[0]->{path};
    }

}

sub _deconstruct_path {
    my $path = shift;
    my ( $volume, $directories, $file ) = File::Spec::Functions::splitpath( $path );
    my @dirs = File::Spec::Functions::splitdir( $directories );
    pop @dirs     if !length( $dirs[-1] );
    $file = undef if !length( $file );
    return ( $volume, $file, @dirs );
}

sub new {
    my $class = shift;
    my $paths = shift;
    my %fs;

    # let's create our "filesystem"! leafs which we know are
    # directories are set to an empty hash; otherwise undef.
    for my $path ( @{$paths} ) {
        my ( $volume, $file, @dirs ) = _deconstruct_path( $path );
        my $ref = \%fs;
        for my $entry ( $volume, @dirs ) {
            $ref->{$entry} = {} if !exists $ref->{$entry};
            $ref = $ref->{$entry};
        }
        $ref->{$file} = undef if defined $file;
    }

    my $self = $class->SUPER::new();
    $self->{_fs} = \%fs;

    return $self;
}

sub _objectify {
    my ( $self, $path ) = @_;

    my ( $volume, $file, @dirs ) = _deconstruct_path( $path );
    my $ref    = $self->{_fs};
    my $exists = 1;
    for my $entry ( $volume, @dirs ) {
        $exists = 0, last
          if !exists $ref->{$entry};
        $ref = $ref->{$entry};
    }
    return Path::List::Rule::Entry->new( $ref, $path, $file );
}

sub _children {
    my ( $self, $path ) = @_;
    return map { [ $_->{leaf}, $_ ] } $path->_children;
}

sub _defaults {
    return (
        _stringify      => 0,
        follow_symlinks => 1,
        depthfirst      => 0,
        sorted          => 1,
        loop_safe       => 1,
        error_handler   => sub { die sprintf( "%s: %s", @_ ) },
        visitor         => undef,
    );
}

sub _fast_defaults {

    return (
        _stringify      => 0,
        follow_symlinks => 1,
        depthfirst      => -1,
        sorted          => 0,
        loop_safe       => 0,
        error_handler   => undef,
        visitor         => undef,
    );
}

sub _iter {
    my $self     = shift;
    my $defaults = shift;
    $defaults->{loop_safe} = 0;
    $self->SUPER::_iter( $defaults, @_ );
}

1;

#
# This file is part of Path-List-Rule
#
# This software is copyright (c) 2022 by Smithsonian Astrophysical Observatory.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

Path::List::Rule - Path::Iterator::Rule on an list of paths

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  use Path::List::Rule;

  my $rule = Path::List::Rule->new([
    qw(
        Monkey/Plugin/Bonobo.pm
        Monkey/Plugin/Mandrill.pm
        Monkey/Plugin/Bonobo/Utilities.pm
        Monkey/See/Monkey/Do/
      );
  ]);

  $rule->clone->perl_module->all( 'Monkey' );
  # returns
  #   Monkey/Plugin/Bonobo.pm
  #   Monkey/Plugin/Mandrill.pm
  #   Monkey/Plugin/Bonobo/Utilities.pm

  $rule->clone->dirs->all( 'Monkey' );
  # returns
  #   Monkey
  #   Monkey/See
  #   Monkey/See/Monkey
  #   Monkey/See/Monkey/Do
  #   Monkey/Plugin
  #   Monkey/Plugin/Bonobo

=head1 DESCRIPTION

C<Path::List::Rule> is a subclass of L<Path::Iterator::Rule> which
uses a list of paths (passed to the constructor) as a proxy for a filesystem.

The list of paths doesn't contain any metadata to allow
C<Path::List::Rule> to distinguish between directories and files, so
it does its best:

=over

=item 1

If a path is used as a component in another path, it's a directory.

=item 2

If it ends with C</>, it's a directory.

=item 3

Otherwise it's a file.

=back

C<Path:List::Rule> objects behave just like L<Path::Iterator::Rule>
objects, except that methods which would ordinarily return paths as
strings return them as L</Path::List::Rule::Entry> objects instead.

=head2 Path::List::Rule::Entry

These objects overload the stringification operator to provide the
initial path.  (A C<stringify> method is also available).

They also respond to the standard Perl file test operators
(e.g. C<-f>, C<-d>).  The following operators are supported; all
others will result in a thrown exception.

=over

=item C<-e>

True if the object represents an entry
found in the paths passed to the C<Path::List::Rule> constructor.

=item C<-l>

Always returns false.

=item C<-r>

Always returns true.

=item C<-d>

Returns true if the object represents a directory
found in the paths passed to the C<Path::List::Rule> constructor.

=item C<-f>

Returns true if the object represents a file found
in the paths passed to the C<Path::List::Rule> constructor.

=back

B<Note!> This minimal set of file operations significantly limits the
L<Path::Iterator::Rule> tests which may be used.

=head3 Methods

=over

=item C<is_dir>

Returns true if the object represents a directory
found in the paths passed to the C<Path::List::Rule> constructor.

=item C<is_file>

Returns true if the object represents a file
found in the paths passed to the C<Path::List::Rule> constructor.

=item C<exists>

Returns true if the object represents a entry
found in the paths passed to the C<Path::List::Rule> constructor.

=item C<stringify>

Return the path as a string.

=back

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-path-list-rule@rt.cpan.org  or through the web interface at: https://rt.cpan.org/Public/Dist/Display.html?Name=Path-List-Rule

=head2 Source

Source is available at

  https://gitlab.com/djerius/path-list-rule

and may be cloned from

  https://gitlab.com/djerius/path-list-rule.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Path::Iterator::Rule|Path::Iterator::Rule>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Smithsonian Astrophysical Observatory.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
