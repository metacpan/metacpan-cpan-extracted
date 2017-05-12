package MooseX::amine;
# ABSTRACT: Examine Yr Moose
$MooseX::amine::VERSION = '0.6';
use Moose;
use Moose::Meta::Class;
use Moose::Meta::Role;
use Moose::Util::TypeConstraints;

use 5.010;
use autodie qw(open close);
use PPI;
use Test::Deep::NoTest qw/eq_deeply/;
use Try::Tiny;


has 'include_accessors_in_method_list' => (
  is      => 'ro' ,
  isa     => 'Bool' ,
  default => 0 ,
);

has 'include_moose_in_isa' => (
  is      => 'ro' ,
  isa     => 'Bool' ,
  default => 0 ,
);

has 'include_private_attributes' =>  => (
  is      => 'ro' ,
  isa     => 'Bool' ,
  default => 0 ,
);

has 'include_private_methods' =>  => (
  is      => 'ro' ,
  isa     => 'Bool' ,
  default => 0 ,
);

has 'include_standard_methods' => (
  is      => 'ro' ,
  isa     => 'Bool' ,
  default => 0 ,
);

has 'module' => ( is => 'ro' , isa => 'Str' );
has 'path'   => ( is => 'ro' , isa => 'Str' );

has '_attributes' => (
  is      => 'ro' ,
  isa     => 'HashRef' ,
  traits  => [ 'Hash' ] ,
  handles => {
    _get_attribute              => 'get' ,
    _store_attribute            => 'set' ,
    _check_for_stored_attribute => 'exists' ,
  },
);

has '_exclusions' => (
  is      => 'ro' ,
  isa     => 'HashRef' ,
  handles => {
    _add_exclusion   => sub { my( $self , $ex ) = @_; $self->{_exclusions}{$ex}++ } ,
    _check_exclusion => sub { my( $self , $ex ) = @_; return $self->{_exclusions}{$ex} } ,
  }
);

has '_metaobj' => (
  is      => 'ro' ,
  isa     => 'Object' ,
  lazy    => 1 ,
  builder => '_build_metaobj' ,
);

sub _build_metaobj {
  my $self = shift;
  return $self->{module}->meta
    || die "Can't get meta object for module!" ;
}

has '_methods' => (
  is      => 'ro' ,
  isa     => 'HashRef' ,
  traits  => [ 'Hash' ] ,
  handles => {
    _store_method => 'set' ,
  },
);

has '_sub_nodes' => (
  is      => 'ro' ,
  isa     => 'HashRef' ,
  traits  => [ 'Hash' ] ,
  handles => {
    _get_sub_node   => 'get' ,
    _store_sub_node => 'set' ,
  },
);

sub BUILDARGS {
  my $class = shift;

  my $args = _convert_to_hashref_if_needed( @_ );

  if ( $args->{module}) {
    eval "require $args->{module};";
    die $@ if $@;

    my $path = $args->{module} . '.pm';
    $path =~ s|::|/|g;
    $args->{path} = $INC{$path};
  }
  elsif ( $args->{path} ) {
    open( my $IN , '<' , $args->{path} );
    while (<$IN>) {
      if ( /^package ([^;]+);/ ) {
        my $module = $1;
        $args->{module} = _load_module_from_path( $module , $args->{path} );
        last;
      }
    }
    close( $IN );
  }
  else { die "Need to provide 'module' or 'path'" }
  return $args;
}


sub examine {
  my $self = shift;
  my $meta = $self->_metaobj;

  if ( $meta->isa( 'Moose::Meta::Role' )) {
    $self->_dissect_role( $meta );
  }
  else {
    foreach my $class ( reverse $meta->linearized_isa ) {
      if ( $class =~ /^Moose::/) {
        next unless $self->include_moose_in_isa;
      }
      $self->_dissect_class( $class );
    }
  }

  # Now that we've dissected everything, load the extracted sub nodes into the
  # appropriate methods
  foreach ( keys %{ $self->{_methods} } ) {
    $self->{_methods}{$_}{code} = $self->_get_sub_node( $_ );
  }

  return {
    attributes => $self->{_attributes} ,
    methods    => $self->{_methods} ,
  }
}

# given two attribute data structures, compare them. returns the older one if
# they're the same; the newer one if they're not.
#
# ignores the value of the 'from' key, since the point here is to check if two
# attributes from different packages are otherwise identical.
sub _compare_attributes {
  my( $new_attr , $old_attr ) = @_;

  my $new_from = delete $new_attr->{from};
  my $old_from = delete $old_attr->{from};

  if ( eq_deeply( $new_attr , $old_attr )) {
    $old_attr->{from} = $old_from;
    return $old_attr;
  }
  else {
    $new_attr->{from} = $new_from;
    return $new_attr;
  }
}

# given a list of args that may or may not be a hashref, do whatever munging
# is needed to return a hashref.
sub _convert_to_hashref_if_needed {
  my( @list_of_args ) = @_;

  return $_[0] if ref $_[0];

  return { module => $_[0] } if @_ == 1;

  my %hash = @_;
  return \%hash;
}

# given a meta object and an attribute name (that is an attribute of that meta
# object), extract a bunch of info about it and store it in the _attributes
# attr.
sub _dissect_attribute {
  my( $self , $meta , $attribute_name ) = @_;

  if ( $attribute_name =~ /^_/ ) {
    return unless $self->include_private_attributes;
  }

  my $meta_attr = $meta->get_attribute( $attribute_name );

  my $return;
  my $ref = ref $meta_attr;
  if ( $ref eq 'Moose::Meta::Role::Attribute' ) {
    $return = $meta_attr->original_role->name;
    $meta_attr = $meta_attr->attribute_for_class();
  }
  else {
    $return = $meta_attr->associated_class->name
  }

  my $extracted_attribute = $self->_extract_attribute_metainfo( $meta_attr );
  $extracted_attribute->{from} = $return;

  if ( $self->_check_for_stored_attribute( $attribute_name )) {
    $extracted_attribute = _compare_attributes(
      $extracted_attribute , $self->_get_attribute( $attribute_name )
    );
  }

  $self->_store_attribute( $attribute_name => $extracted_attribute );
}

# given a class name, extract and store info about it and any roles that it
# has consumed.
sub _dissect_class {
  my( $self , $class ) = @_;
  my $meta = $class->meta;

  map { $self->_dissect_role($_) } @{ $meta->roles } if ( $meta->can( 'roles' ));
  map { $self->_dissect_attribute( $meta , $_ ) } $meta->get_attribute_list;
  map { $self->_dissect_method( $meta , $_ )    } $meta->get_method_list;

  $self->_extract_sub_nodes( $meta->name );
}

# given a meta object and a method name (that is a method of that meta
# object), extract and store info about the method.
sub _dissect_method {
  my( $self , $meta , $method_name ) = @_;

  if ( $method_name =~ /^_/ ) {
    return unless $self->include_private_methods;
  }

  my $meta_method = $meta->get_method( $method_name );

  my $src = $meta_method->original_package_name;

  unless ( $self->include_accessors_in_method_list ) {
    return if $self->_check_exclusion( $method_name );
  }

  unless ( $self->include_standard_methods ) {
    my @STOCK = qw/ DESTROY meta new /;
    foreach ( @STOCK ) {
      return if $method_name eq $_;
    }
  }

  my $extracted_method =  $self->_extract_method_metainfo( $meta_method );
  $self->_store_method( $method_name => $extracted_method );
}

# extract and store information from a particular role
sub _dissect_role {
  my( $self , $meta ) = @_;

  map { $self->_dissect_attribute( $meta , $_ ) } $meta->get_attribute_list;
  map { $self->_dissect_method( $meta , $_ )    } $meta->get_method_list;

  my @names = split '\|' , $meta->name;
  foreach my $name ( @names ) {
    next if $name =~ /Moose::Meta::Role::__ANON/;
    $self->_extract_sub_nodes( $name );
  }
}

# given a meta attribute, extract a bunch of meta info and return a data
# structure summarizing it.
sub _extract_attribute_metainfo {
  my( $self , $meta_attr ) = @_;

  my $return = {};

  foreach ( qw/ reader writer accessor / ) {
    next unless my $fxn = $meta_attr->$_;
    $self->_add_exclusion( $fxn );
    $return->{$_} = $fxn;
  }

  $return->{meta}{documentation} = $meta_attr->documentation
    if ( $meta_attr->has_documentation );

  $return->{meta}{constraint} = $meta_attr->type_constraint->name
    if ( $meta_attr->has_type_constraint );

  $return->{meta}{traits} = $meta_attr->applied_traits
    if ( $meta_attr->has_applied_traits );

  foreach ( qw/
                is_weak_ref is_required is_lazy is_lazy_build should_coerce
                should_auto_deref has_trigger has_handles
              / ) {
    $return->{meta}{$_}++ if $meta_attr->$_ ;
  }

  ### FIXME should look at delegated methods and install exclusions for them

  return $return;

}

# given a meta method, extract a bunch of info and return a data structure
# summarizing it.
sub _extract_method_metainfo {
  my( $self , $meta_method ) = @_;

  return {
    from => $meta_method->original_package_name ,
  };
}

# given a module name, use PPI to extract the 'sub' nodes and store them.
sub _extract_sub_nodes {
  my( $self , $name ) = @_;

  my $path = $name . '.pm';
  $path =~ s|::|/|g;
  if ( $path = $INC{$path} ){
    try {
      my $ppi = PPI::Document->new( $path )
        or die "Can't load PPI for $path ($!)";

      my $sub_nodes = $ppi->find(
        sub{ $_[1]->isa( 'PPI::Statement::Sub' ) && $_[1]->name }
      );

      foreach my $sub_node ( @$sub_nodes ) {
        my $name = $sub_node->name;
        $self->_store_sub_node( $name => $sub_node->content );
      }
    };
    # FIXME should probably do something about errors here...
  }
}


# given a module name and a path to that module, dynamically load the
# module. figures out the appropriate 'use lib' statement based on the path.
sub _load_module_from_path {
  my( $module , $path ) = @_;

  $path =~ s/.pm$//;
  my @path_parts   = split '/'  , $path;
  my @module_parts = split /::/ , $module;
  my @inc_path     = ();

  while ( @path_parts ) {
    my $path = join '/' , @path_parts;
    my $mod  = join '/' , @module_parts;
    last if $path eq $mod;
    push @inc_path , shift @path_parts;
  }
  my $inc_path = join '/' , @inc_path;

  eval "use lib '$inc_path'; require $module";
  die $@ if $@;

  return $module;
}


#__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::amine - Examine Yr Moose

=head1 VERSION

version 0.6

=head1 SYNOPSIS

    my $mex  = MooseX::amine->new( 'MooseX::amine' );
    my $data = $mex->examine;

    my $attributes = $data->{attributes};
    my $methods    = $data->{methods};

=head1 METHODS

=head2 new

    # these two are the same
    my $mex = MooseX::amine->new( 'Module' );
    my $mex = MooseX::amine->new({ module => 'Module' });

    # or you can go from the path to the file
    my $mex = MooseX::amine->new({ path = 'path/to/Module.pm' });

    # there are a number of options that all pretty much do what they say.
    # they all default to off
    my $mex = MooseX::amine->new({
      module                           => 'Module' ,
      include_accessors_in_method_list => 1,
      include_moose_in_isa             => 1,
      include_private_attributes       => 1,
      include_private_methods          => 1,
      include_standard_methods         => 1,
    });

=head2 examine

    my $mex  = MooseX::amine( 'Module' );
    my $data = $mex->examine();

Returns a multi-level hash-based data structure, with two top-level keys,
C<attributes> and C<methods>. C<attributes> points to a hash where the keys
are attribute names and the values are data structures that describe the
attributes. Similarly, C<methods> points to a hash where the keys are method
names and the values are data structures describing the method.

A sample attribute entry:

    simple_attribute => {
      accessor => 'simple_attribute',
      from     => 'Module',
      meta     => {
        constraint => 'Str'
      }
    }

The prescence of an C<accessor> key indicates that this attribute was defined
with C<is => 'rw'>. A read-only attribute will have a C<reader> key. A
C<writer> key may also be present if a specific writer method was given when
creating the attribute.

Depending on the options given when creating the attribute there may be
various other options present under the C<meta> key.

A sample method entry:

    simple_method => {
      code => 'sub simple_method   { return \'simple\' }',
      from => 'Module'
    }

The C<code> key will contain the actual code from the method, extracted with
PPI. Depending on where the method code actually lives, this key may or may
not be present.

=head1 CREDITS

=over 4

=item Semi-inspired by L<MooseX::Documenter>.

=item Syntax highlighting Javascript/CSS stuff based on SHJS and largely stolen from search.cpan.org.

=back

=head1 AUTHOR

John SJ Anderson <genehack@genehack.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
