=head1 NAME

Pipeline::Config - configuration files for building Pipelines.

=head1 SYNOPSIS

  use Error qw( :try );
  use Pipeline::Config;

  my $config = Pipeline::Config->new();

  try {
      my $pipe  = $config->load( 'somefile.type' );
      my $pipe2 = $config->load( 'somefile', 'type' );
  } catch Error with {
      print shift;
  }

=cut

package Pipeline::Config;

use strict;
use warnings::register;

use Error;
use Pipeline::Config::LoadError;
use Pipeline::Config::UnknownTypeError;

use base qw( Pipeline::Base );

our $VERSION  = '0.05';
our $REVISION = (split(/ /, ' $Revision: 1.13 $ '))[2];
our $TYPES    = { # maybe should use regexps here?
		 'yml'  => 'Pipeline::Config::YAML',
		 'yaml' => 'Pipeline::Config::YAML',
		};

sub types {
    my $self = shift;
    if (@_) { $TYPES = shift; return $self; }
    else { return $TYPES; }
}

sub load {
    my $self = shift;
    my $file = shift;
    my $type = shift;

    $type = $self->resolve_type( $file ) unless ($type);

    return $self->load_type( $file, $type );
}

sub load_type {
    my $self   = shift;
    my $file   = shift;
    my $type   = shift;
    my $parser = $self->new_object( $type );
    return $parser->load( $file );
}

sub resolve_type {
    my $self = shift;
    my $file = shift;
    foreach my $type (keys %{ $self->types }) {
	return $type if ($file =~ /\.$type/i)
    }
    throw Pipeline::Config::UnknownTypeError( "can't resolve type of [$file]!" );
}

sub new_object {
    my $self  = shift;
    my $type  = shift;
    my $class = $self->get_types_class( $type )
      || throw Pipeline::Config::UnknownTypeError( "unknown type: $type" );
    return $self->load_class( $class )->new( @_ )->debug( $self->debug );
}

sub get_types_class {
    my $self = shift;
    my $type = shift;
    return Pipeline::Config->types->{$type};
}

sub load_class {
    my $self  = shift;
    my $class = shift;
    unless (UNIVERSAL::can( $class, 'new' )) {
	eval "require $class";
	throw Pipeline::Config::LoadError( "error loading $class: $@" ) if $@;
    }
    return $class;
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

Pipeline::Config lets you specify the structure of a Pipeline in a configuration
file.  This means you don't have to use() every Segment, call its constructor,
and add it to the pipeline, because Pipeline::Config does it for you.  It also
means the flow of logic through your Pipeline is in one place, in a format that
is easily read.

"How nice", you say?  Well, this all assumes you have relatively simple Pipeline
Segments that don't need lots of configuration.  If you don't, then maybe this
module is not for you.

C<Pipeline::Config> is the frontend to various types of pipeline configuration
files.

=head1 SUPPORTED FILE TYPES

At the moment, only C<YAML> is supported.

=head1 METHODS

=over 4

=item $class->types

Get/set the hash of known pipeline config types & their class names.  This is
used to lookup & load config classes.  If you write your own config parser you
should register it like this:

  Pipeline::Config->types->{type} => 'MyConfig::Type';

=item $pipe = $obj->load( $file [, $type ] )

Load the config file given.  Currently $file must be a valid path (file handles
and text references are not yet supported).  If $type is not passed, attempts
to resolve it by seeing if the filename's suffix matches any of the known types
listed in $class->types().

Throws a C<Pipeline::Config::UnknownTypeError> if the type could not be
resolved, or a C<Pipeline::Config::LoadError> if there was an error loading the
config file.

=back

=head1 EXAMPLE

Here's an example YAML config file:

  # Pipeline configuration file
  ---
  search-packages:
    - MyApp::Segment
  pipeline:
    - MyApp::Segment::Foo
    # you don't have to name segments explicitly
    # if you're using search-packages:
    - Foo
    - this is a sub pipe:
        # anything with the word 'pipe' creates a new Pipeline
        # named sub-pipes are not yet supported
        - another sub pipe:
            - DeclineNoBar
            - GetDrink
        # this calls the 'foo' method with 'bar' as an argument:
        - Baz: { foo: "bar" }
    - AnotherApp::Segment::GoFish
  cleanups:
    # if you really need to, set cleanup segments here...
    - Cleanup::Segment

=head1 AUTHOR

Steve Purkis <spurkis@epn.nu>

=head1 COPYRIGHT

Copyright (c) 2003 Steve Purkis.  All rights reserved.
Released under the same license as Perl itself.

=head1 SEE ALSO

L<Pipeline>

=cut

