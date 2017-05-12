package MooseX::Meta::Method::Role::Authorized;
use  MooseX::Meta::Method::Role::Authorized::Meta::Role;

has requires =>
  ( is => 'ro',
    isa => 'HashRef',
    default => sub { [] } );

around wrap => sub {
    my ($wrap, $method, $code, %options) = @_;
 
    my $requires = $options{requires};
    
    die "requires hash-ref must have either a 'required' or 'one_of' or both key that points to an array-ref of Roles!"
      unless (((exists($requires->{required}) and ref($requires->{required}) eq 'ARRAY')) or
              ((exists($requires->{one_of}) and ref($requires->{one_of}) eq 'ARRAY')));
    
    my $meth_obj;
    $meth_obj = $method->$wrap
      (
       sub {
           $meth_obj->authorized_do($meth_obj, $code, @_)
       },
       %options
      );
     
    return $meth_obj;
};

sub authorized_do {
    my $self = shift;
    my $method = shift;
    my $requires = $method->requires;
    my $code = shift;
 
    my ($instance) = @_;
    foreach my $key (keys($requires)){
      my $author_sub = '_authorize_'.$key;
      next
        unless ($self->can($author_sub));
      $self->$author_sub($requires->{$key},$instance,$method);
      
      
    }
     $code->(@_);

}

sub _authorize_required {
  my $self    = shift;
  my ($roles,$instance,$method) = @_;
  
  foreach my $role (@{$roles}){
    die ref($instance). " must express the Role $role to use method ".$method->name()."!" 
      if !Moose::Util::does_role($instance,$role);
 }
}

sub _authorize_one_of {
  my $self    = shift;
  my ($roles,$instance,$method) = @_;
  my $message =  ref($instance). " must express on of these Roles: ";
  my $comma = "";
  foreach my $role (@{$roles}){
    return 1
      if (Moose::Util::does_role($instance,$role));
    $message.=$comma.$role;
    $comma=',';
  }
  $message.=" to use  method ".$method->name()."!";
  die $message;

}
1;

__END__

=head1 NAME

MooseX::Meta::Method::Role::Authorized

=head1 DESCRIPTION

This trait provides support for verifying roles before calling
a method.

=head1 ATTRIBUTES

=over

=item requires

This attribute is an hash reference with the values that are going to
be used by the authorized_do method when checking this invocation.

=head1 METHODS

=item authorized_do

Call the Api keys in trun.  If you want to expand on this API simply add in 
you _sub and validation  like the others

=head1 METHOD


=item wrap

This role overrides wrap so that the actual method is only invoked
after the authorization being checked.

=back

=head1 SEE ALSO

L<http://search.cpan.org/dist/MooseX-AuthorizedMethodRoles/>, L<Class::MOP::Method>

=head1 AUTHOR

John Scoles, C<< <byterock at hotmail.com> >>


=head1 COPYRIGHT AND LICENSE

Copyright 2010 by Daniel Ruoso et al

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
