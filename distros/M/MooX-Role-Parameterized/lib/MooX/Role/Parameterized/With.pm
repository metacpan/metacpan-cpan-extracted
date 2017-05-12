package MooX::Role::Parameterized::With;
{
    $MooX::Role::Parameterized::With::VERSION = '0.082';
}
use strict;
use warnings;

# ABSTRACT: MooX::Role::Parameterized:With - dsl to apply roles with composition parameters

use Exporter;    # qw(import);
use Module::Runtime qw(use_module);
use List::MoreUtils qw(natatime);

sub import {
    my $package = shift;
    my $target  = caller;

    my $it = natatime( 2, @_ );

    while ( my ( $role, $params ) = $it->() ) {
        use_module($role)->apply( $params, target => $target );
    }
}

1;

__END__

=head1 NAME

MooX::Role::Parameterized:With - dsl to apply roles with composition parameters

=head1 SYNOPSYS

    package FooWith;

    use Moo;
    use MooX::Role::Parameterized::With Bar => {
        attr => 'baz', 
        method => 'run'
    }, Other::Role => { ... };

    has foo => ( is => 'ro');

=head1 DESCRIPTION

This B<experimental> package try to offer an easy way to add parametrized roles.

Will load and apply L<MooX::Roles::Parameterized> roles, just need use this package
with a hash of role => parameters. 

=head1 AUTHOR

Tiago Peczenyj <tiago (dot) peczenyj (at) gmail (dot) com>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
