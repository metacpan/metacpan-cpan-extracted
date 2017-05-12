use 5.008;    # utf8
use strict;
use warnings;
use utf8;

package Path::IsDev::Object;

our $VERSION = '1.001003';

# ABSTRACT: Object Oriented guts for IsDev export

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY













our $ENV_KEY_DEBUG = 'PATH_ISDEV_DEBUG';
our $DEBUG = ( exists $ENV{$ENV_KEY_DEBUG} ? $ENV{$ENV_KEY_DEBUG} : undef );

our $ENV_KEY_DEFAULT = 'PATH_ISDEV_DEFAULT_SET';
our $DEFAULT =
  ( exists $ENV{$ENV_KEY_DEFAULT} ? $ENV{$ENV_KEY_DEFAULT} : 'Basic' );









use Class::Tiny 0.010 {
  set        => sub { $DEFAULT },
  set_prefix => sub { 'Path::IsDev::HeuristicSet' },
  set_module => sub {
    require Module::Runtime;
    return Module::Runtime::compose_module_name( $_[0]->set_prefix => $_[0]->set );
  },
  loaded_set_module => sub {
    require Module::Runtime;
    return Module::Runtime::use_module( $_[0]->set_module );
  },
};



















my $instances   = {};
my $instance_id = 0;

sub _carp { require Carp; goto &Carp::carp; }












sub _instance_id {
  my ($self) = @_;
  require Scalar::Util;
  my $addr = Scalar::Util::refaddr($self);
  return $instances->{$addr} if exists $instances->{$addr};
  $instances->{$addr} = sprintf '%x', $instance_id++;
  return $instances->{$addr};
}











sub _debug {
  my ( $self, $message ) = @_;

  return unless $DEBUG;
  my $id = $self->_instance_id;
  return *STDERR->printf( qq{[Path::IsDev=%s] %s\n}, $id, $message );
}












sub _with_debug {
  my ( $self, $code ) = @_;
  require Path::IsDev;
  ## no critic (ProhibitNoWarnings)
  no warnings 'redefine';
  local *Path::IsDev::debug = sub {
    $self->_debug(@_);
  };
  return $code->();
}










sub BUILD {
  my ($self) = @_;
  return $self unless $DEBUG;
  $self->_debug('{');
  $self->_debug( ' set               => ' . $self->set );
  $self->_debug( ' set_prefix        => ' . $self->set_prefix );
  $self->_debug( ' set_module        => ' . $self->set_module );
  $self->_debug( ' loaded_set_module => ' . $self->loaded_set_module );
  $self->_debug('}');
  return $self;
}











sub _matches {
  my ( $self, $path ) = @_;
  require Path::IsDev::Result;
  my $result_object = Path::IsDev::Result->new( path => $path );
  my $result;
  $self->_with_debug(
    sub {

      $self->_debug( 'Matching ' . $result_object->path );
      $result = $self->loaded_set_module->matches($result_object);
    },
  );
  if ( !!$result != !!$result_object->result ) {
    _carp(q[Result and Result Object missmatch]);
  }
  return $result_object;
}











sub matches {
  my ( $self, $path ) = @_;

  my $result_object = $self->_matches($path);

  if ( not $result_object->result ) {
    $self->_debug('no match found');
    return;
  }

  return $result_object->result;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Path::IsDev::Object - Object Oriented guts for IsDev export

=head1 VERSION

version 1.001003

=head1 SYNOPSIS

    use Path::IsDev::Object;

    my $dev = Path::IsDev::Object->new();
    my $dev = Path::IsDev::Object->new( set => 'MySet' );

    if ( $dev->matches($path) ){
        print "$path is dev";
    }

=head1 DESCRIPTION

Exporting functions is handy for end users, but quickly
becomes a huge headache when you're trying to chain them.

e.g: If you're writing an exporter yourself, and you want to wrap
responses from an exported symbol, while passing through user
configuration => Huge headache.

So the exporter based interface is there for people who don't need anything fancy,
while the Object based interface is there for people with more complex requirements.

=head1 METHODS

=head2 C<matches>

Determine if a given path satisfies the C<set>

    if( $o->matches($path) ){
        print "We have a match!";
    }

=head1 ATTRIBUTES

=head2 C<set>

The name of the C<HeuristicSet::> to use.

Default is C<Basic>, or the value of C<$ENV{PATH_ISDEV_DEFAULT_SET}>

=head2 C<set_prefix>

The C<HeuristicSet> prefix to use to expand C<set> to a module name.

Default is C<Path::IsDev::HeuristicSet>

=head2 C<set_module>

The fully qualified module name.

Composed by joining C<set> and C<set_prefix>

=head2 C<loaded_set_module>

An accessor which returns a module name after loading it.

=head1 PRIVATE METHODS

=head2 C<_instance_id>

An opportunistic sequence number for help with debug messages.

Note: This is not guaranteed to be unique per instance, only guaranteed
to be constant within the life of the object.

Based on C<refaddr>, and giving out new ids when new C<refaddr>'s are seen.

=head2 C<_debug>

The debugger callback.

    export PATH_ISDEV_DEBUG=1

to get debug info.

=head2 C<_with_debug>

Wrap calls to Path::IsDev::debug to have a prefix with an object identifier.

    $ob->_with_debug(sub{
        # Path::Tiny::debug now localised.

    });

=head2 C<BUILD>

C<BUILD> is an implementation detail of C<Class::Tiny>.

This module hooks C<BUILD> to give a self report of the object
to C<*STDERR> after C<< ->new >> when under C<$DEBUG>

=head2 C<_matches>

    my $result = $o->matches( $path );

$result here will be a constructed C<Path::IsDev::Result>.

Note this method may be handy for debugging, but you should still call C<matches> for all real code.

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Path::IsDev::Object",
    "interface":"class",
    "inherits":"Class::Tiny::Object"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
