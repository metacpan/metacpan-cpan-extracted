package MooseX::AuthorizedMethodRoles;
use Moose ();
use Moose::Exporter;
use Sub::Name;

our $VERSION = 0.01;

Moose::Exporter->setup_import_methods
  ( with_meta => [ 'authorized_roles' ],
    also      => [ 'Moose' ],
  );


my $method_metaclass = Moose::Meta::Class->create_anon_class
  (
   superclasses => ['Moose::Meta::Method'],
   roles => [ 'MooseX::Meta::Method::Role::Authorized' ],
   cache => 1,
  );

sub authorized_roles {
    my ($meta, $name, $requires, $code) = @_;
    #warn($meta->name.",".$name);
    my $m = $method_metaclass->name->wrap
      (
       subname(join('::',$meta->name,$name),$code),
       package_name => $meta->name,
       name => $name,
       requires => $requires
      );

    $meta->add_method($name, $m);
}

1;


__END__

=head1 NAME

MooseX::AuthorizedMethodRole - Syntax sugar for authorized methods by MooseX::Role

=head1 SYNOPSIS

  package Foo::Bar;
  use MooseX::AuthorizedMethodRoles; # includes Moose
  with ('Role::Bill::Bloggins', 'Role::Blog::Save', 'Role::One::Two');
  
  authorized_roles foo => {one_of=>['Role::Bill::Bloggins','Role::Bilbo::Baggings']} sub {
     # this is going to happen only if the package impliments role 
     # 'Role::Bill::Bloggins' or 'Role::Bilbo::Baggings' or both.
  };

  authorized_roles bar => {required=>['Role::Blog::Save']} sub {
     # this is going to happen only if the package impliments role 
     # 'Role::Blog::Save'.
  };

=head1 DESCRIPTION

This method exports the "authorized_role" declarator that makes a
verification that the present package expresses the Moose::Roles as describebe by
the API. So far the API has two rules 'one_of', meaning the package must express at least
one of listed the Moose::Roles  and 'required' meaning is must express all of the listed
Moose::Roles.  


=head1 DECLARATOR

=over

=item authorized_roles $name => {one_of=>[],required=>[]}, $code

This declarator requres that you use at least one of the API keys, It checks the current
package's Roles and dies if the condtions are not met.

=back

=head1 CONFIGURATION

The curent API allows for two keywords, these keywords must be followed by an Array-Ref of Moose::Roles.

=head2 one_of=>[]

This keyword means the the current package must have at least one of the roles in the Array-Ref it points to. As 
soon as it finds one it returns true and fires the code otherwise it will die.

=head2 required=>[]

This keyword means the the current package must have all of the roles in the Array-Ref it points to. 
It will iterate over the list and die if as soon as one Moose::Role is not expressed.

=head3 multiple keywords

You can use both keywords at the same time so this 

  authorized_roles bar => {one_of=>['Role::Bill::Bloggins','Role::Bilbo::Baggings']}  required=>['Role::Blog::Save']} sub {
   ...
   };

is allowed.  It this type of configuation both the 'one_of' and 'required' must pass if the code is going to fire.

=head1 EXAMPLES

=head2 Expressing Business rules


  package Product::Order;
  use Moose;
    ... 
  authorized_roles shipping_authorized => {one_of=>[qw (Product::BRULE::PO Product::BRULE::Standing_Offer Product::BRULE::Paid_In_Full)]}  , sub {
     ...
  };
  
  authorized_roles bill_after_30_days => {requied=>[qw (Product::BRULE::PO)]}  , sub {
     ...
  };
  
  
  
  package Standing::Order;
  use Moose;
  extends 'Product::Order';
  with 'Product::BRULE::Standing_Offer';
  ...
  
  
The package Standing::Order can invoke 'shipping_authorized' but it cannot invoke 'bill_after_30_days'
  
  

=head1 SEE ALSO

 L<https://metacpan.org/pod/MooseX::Meta::Method::Authorized> for the insparation for this MooseX

=head1 AUTHOR

John Scoles, C<< <byterock at hotmail.com> >>

=head1 BUGS / CONTRIBUTING

Please report any bugs or feature requests through the web interface at L<https://github.com/byterock/Moosex-AuthorizedMethodRoles/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.
perldoc MooseX::AuthorizedMethodRoles
You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation L<http://annocpan.org/dist/MooseX-AuthorizedMethodRoles>

=item * CPAN Ratings L<http://cpanratings.perl.org/d/MooseX-AuthorizedMethodRoles>

=item * Search CPAN L<http://search.cpan.org/dist/MooseX-AuthorizedMethodRoles/>

=back

=head1 ACKNOWLEDGEMENTS

Daniel Ruoso (l<https://metacpan.org/author/DRUOSO>)

- For 'L<https://metacpan.org/pod/MooseX::Meta::Method::Authorized>' which I used completly wrong to start then had to 
scramble to create this one to cover my tracks

=head1 LICENSE AND COPYRIGHT

Copyright 2010 by John Scoles

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut




