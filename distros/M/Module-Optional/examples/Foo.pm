Package Foo;

use strict;

=head1 NAME

Foo - Example of a module which can optionally use Params::Validate

=head1 SYNOPSYS

  use Foo

  my $obj=Foo->new('fred');

=head1 DESCRIPTION

This is an example of how you would write a module that optionally uses 
Params::Validate. If the target machine has Params::Validate installed, 
the user gets the benefit of full blown parameter validation.

If not, the code will still work, but callers may pass in unexpected data
types that cause the module to blow in unexpected ways,

=cut

use Params::Validate::Dummy qw();
use Module::Optional qw(Params::Validate :all);

sub new {
    my $pkg = shift;

    my %par = validate( @_, {
        name => {
            regex => qr/[:alpha:]+/,
            type => SCALAR
        }});

    ...
}
