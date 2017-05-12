package MooX::Role::Parameterized;
{
    $MooX::Role::Parameterized::VERSION = '0.082';
}
use strict;
use warnings;
use Carp;

# ABSTRACT: MooX::Role::Parameterized - roles with composition parameters
use MooX::Role::Parameterized::Proxy;
use Exporter qw(import);
use Module::Runtime qw(use_module);
our @EXPORT = qw(role method apply hasp);

my %code_for;

sub hasp { carp "hasp deprecated"; }

sub apply {
    my ( $role, $args, %extra ) = @_;

    return if !exists $code_for{$role};

    $args = [$args] if ref($args) ne ref( [] );

    my $target = $extra{target} // caller;

    {
        no strict 'refs';
        no warnings 'redefine';

        # necessary for magic
        *{ $role . '::hasp' } = sub {

            #        carp 'hasp deprecated, use $object->has instead.';
            goto &{ $target . '::has' };
        };
        *{ $role . '::method' } = sub {

            #        carp 'method deprecated, use $object->method instead.';
            my ( $name, $code ) = @_;
            no strict 'refs';
            *{"$target\::$name"} = $code;
        };
    }
    my $p =
      MooX::Role::Parameterized::Proxy->new( target => $target, role => $role );
    $code_for{$role}->( $_, $p ) foreach ( @{$args} );

    use_module('Moo::Role')->apply_roles_to_package( $target, $role );
}

sub role(&) {
    my $package = (caller)[0];

    $code_for{$package} = shift;
}

sub method { carp "hasp deprecated"; }

1;
__END__

=head1 NAME

MooX::Role::Parameterized - roles with composition parameters

=head1 SYNOPSYS

    package My::Role;

    use Moo::Role;
    use MooX::Role::Parameterized;

    role {
        my $params = shift;
        my $mop    = shift;

        $mop->has( $params->{attr} => ( is => 'rw' ));

        $mop->method($params->{method} => sub {
            1024;
        });
    };

    package My::Class;

    use Moo;
    # experimental way of add roles
    use MooX::Role::Parameterized::With My::Role => {
        attr => 'baz',
        method => 'run'
    };

    package My::OldClass;

    use Moo;
    use My::Role;

    My::Role->apply([{    # original way of add this role
        attr => 'baz',    # add attribute read-write called 'baz' 
        method => 'run'   # add method called 'run' and return 1024 
    }
     ,                    # and if the apply receives one arrayref
    {   attr => 'bam',    # will call the role block multiple times.
        method => 'jump'  # PLEASE CALL apply once
    }]);      

=head1 DESCRIPTION

It is an B<experimental> port of L<MooseX::Role::Parameterized> to L<Moo>.

=head1 FUNCTIONS

This package exports four subroutines: C<role>, C<apply>, C<hasp> and C<method>. The last two are now consider deprecated and will be removed soon.

=head2 role

This function accepts just B<one> code block. Will execute this code then we apply the Role in the 
target class, and will receive the parameter list + one B<mop> object.

The B<mop> object is a proxy to the target class. It offer a better way to call C<has>, C<requires> or C<after> without side effects. 

The old way to create parameterized roles was calling C<has> or C<method>, but there is too much problems with this approach. To solve part of them
we add the L<hasp> but it solve part of the problem. To be clean, we decide be explicit and offer one object with full Role capability.

Instead do

  my ($p) = @_;
  ...
  hasp $p->{attribute} => (...);

We prefer

  my ($p, $mop) = @_;
  ...
  $mop->has($p->{attribute} =>(...));

Less magic, less problems.

=head2 apply

When called, will apply the L</role> on the current package. The behavior depends of the parameter list.

This will install the role in the target package. Does not need call C<with>.

Important, if you want to apply the role multiple times, like to create multiple attributes, please pass an B<arrayref>.

=head1 DEPRECATED FUNCTIONS

=head2 hasp

IMPORTANT: until the version 0.06 we have a terrible bug when you try to add the same role in two or more different classes.
To avoid this we should not call the C<has> method to specify attributes but the method C<hasp> (means 'has parameterized').

=head2 method

Add one method based on the parameter list, for example.

=head1 MooX::Role::Parameterized::With

See L<MooX::Role::Parameterized::With> package to easily load and apply roles.

=head1 SEE ALSO

L<MooseX::Role::Parameterized> - Moose version

=head1 LICENSE
The MIT License
 
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated
 documentation files (the "Software"), to deal in the Software
 without restriction, including without limitation the rights to
 use, copy, modify, merge, publish, distribute, sublicense,
 and/or sell copies of the Software, and to permit persons to
 whom the Software is furnished to do so, subject to the
 following conditions:
  
  The above copyright notice and this permission notice shall
  be included in all copies or substantial portions of the
  Software.
   
   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT
   WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
   INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
   MERCHANTABILITY, FITNESS FOR A PARTICULAR
   PURPOSE AND NONINFRINGEMENT. IN NO EVENT
   SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
   LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
   TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
   CONNECTION WITH THE SOFTWARE OR THE USE OR
   OTHER DEALINGS IN THE SOFTWARE.

=head1 AUTHOR

Tiago Peczenyj <tiago (dot) peczenyj (at) gmail (dot) com>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
