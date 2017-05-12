
use Test::More tests => 8;
use strict;
use warnings;
use FindBin;
BEGIN { use_ok('MooseX::Documenter') }

ok( MooseX::Documenter->new( "$FindBin::Bin/samplemoose/", 'Moose::Object' ),
  'simple usage of example works.' );

my $doc =
  MooseX::Documenter->new( "$FindBin::Bin/samplemoose/", 'Moose::Object' );
ok(
  $doc->setmooselib("$FindBin::Bin/samplemoose"),
  'able to set new moose lib location'
);

is_deeply( $doc->local_attributes, undef,
  'got expected return from local_attributes' );

is_deeply( $doc->inherited_attributes, undef,
  'got expected return from inherited_attributes' );

is_deeply(
  $doc->local_methods,
  {
    meta     => undef,
    DOES     => undef,
    BUILDALL => 'sub BUILDALL {

  # NOTE: we ask Perl if we even
  # need to do this first, to avoid
  # extra meta level calls
  return unless $_[0]->can(\'BUILD\');
  my( $self, $params ) = @_;
  foreach my $method ( reverse $self->meta->find_all_methods_by_name(\'BUILD\') )
  {
    $method->{code}->execute( $self, $params );
  }
}',
    BUILDARGS => 'sub BUILDARGS {
  my $class = shift;
  if( scalar @_ == 1 ) {
    if( defined $_[0] ) {
      ( ref( $_[0] ) eq \'HASH\' )
        || $class->meta->throw_error(
        "Single parameters to new() must be a HASH ref",
        data => $_[0] );
      return { %{ $_[0] } };
    }
    else {
      return {};    # FIXME this is compat behavior, but is it correct?
    }
  }
  else {
    return {@_};
  }
}',
    DEMOLISHALL => 'sub DEMOLISHALL {
  my $self = shift;

  # NOTE: we ask Perl if we even
  # need to do this first, to avoid
  # extra meta level calls
  return unless $self->can(\'DEMOLISH\');
  foreach my $method ( $self->meta->find_all_methods_by_name(\'DEMOLISH\') ) {
    $method->{code}->execute($self);
  }
}',
    DESTROY => 'sub DESTROY {

  # if we have an exception here ...
  if($@) {

    # localize the $@ ...
    local $@;

    # run DEMOLISHALL ourselves, ...
    $_[0]->DEMOLISHALL;

    # and return ...
    return;
  }

  # otherwise it is normal destruction
  $_[0]->DEMOLISHALL;
}',
    does => 'sub does {
  my( $self, $role_name ) = @_;
  my $meta = $self->meta;
  ( defined $role_name )
    || $meta->throw_error("You much supply a role name to does()");
  foreach my $class ( $meta->class_precedence_list ) {
    my $m = $meta->initialize($class);
    return 1
      if $m->can(\'does_role\') && $m->does_role($role_name);
  }
  return 0;
}',
    'dump' => 'sub dump {
  my $self = shift;
  require Data::Dumper;
  local $Data::Dumper::Maxdepth = shift if @_;
  Data::Dumper::Dumper $self;
}',
    'new' => 'sub new {

  #PART of MooseX::Documenter checks
  my $class  = shift;
  my $params = $class->BUILDARGS(@_);
  my $self   = $class->meta->new_object($params);
  $self->BUILDALL($params);
  return $self;
}'
  },
  'got expected return from local_methods'
);

is_deeply( $doc->inherited_methods, undef,
  'got expected return from inherited_methods' );

is_deeply( $doc->roles, undef, 'got expected return from roles' );

