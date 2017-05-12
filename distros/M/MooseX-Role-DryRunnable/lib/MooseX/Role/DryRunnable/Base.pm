use strict;
use warnings;
package MooseX::Role::DryRunnable::Base;
{
  $MooseX::Role::DryRunnable::Base::VERSION = '0.006';
}

use Moose::Role;

requires 'is_dry_run';
requires 'on_dry_run';  

1;

__END__

=head1 NAME

MooseX::Role::DryRunnable::Base - base role for add a dry_run option into your Moose Class

=head1 SYNOPSIS

  package Foo;
  use Moose;
  with 'MooseX::Role::DryRunnable::Base' ;

  sub is_dry_run { # required !
    1
  }

  sub on_dry_run { # required !
    Test::More::ok(1, "should be called");
  }

=head1 DESCRIPTION

Base role for MooseX::Role::DryRunnable, you can combine this role with MooseX::Role::DryRunnable::Attribute

=head1 REQUIRES

=head2 is_dry_run

This method must return one boolean value. If true, we will execute the alternate code described in `on_dry_run`. You must implement!

=head2 on_dry_run

This method will receive the method name and all of the parameters form the original method. You must implement!

=head1 SEE ALSO

L<MooseX::Role::DryRunnable::Attribute>, L<MooseX::Role::DryRunnable>

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Tiago Peczenyj <tiago.peczenyj@gmail.com>, or (preferred)
to this package's RT tracker at <bug-MooseX-Role-DryRunnable@rt.cpan.org>.

=head1 AUTHOR

Tiago Peczenyj <tiago.peczenyj@gmail.com>