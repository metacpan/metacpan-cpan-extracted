use strict;
use warnings;
package MooseX::Role::DryRunnable::Attribute;
{
  $MooseX::Role::DryRunnable::Attribute::VERSION = '0.006';
}

use Moose::Util;
use Attribute::Handlers;

sub UNIVERSAL::dry_it :ATTR(CODE) { 
  my $package = shift;
  my $glob    = shift;
  my $method  = *{$glob}{NAME};
  
  warn "MooseX::Role::DryRunnable::Attribute is Experimental! Be careful!";
  
  Moose::Util::add_method_modifier($package => around => [ $method => sub { 
      my $code   = shift;
      my $self = shift;

      die "Should be MooseX::Role::DryRunnable::Base\n" 
        unless $self->DOES('MooseX::Role::DryRunnable::Base');

      $self->is_dry_run($method, @_) 
        ? $self->on_dry_run($method, @_) 
        : $self->$code(@_)
      }
  ]);
}

1;

__END__

=head1 NAME

MooseX::Role::DryRunnable::Attribute - EXPERIMENTAL - attribute to add a Dry Run Capability in some methods

=head1 SYNOPSIS

  package Foo;
  use Data::Dumper;
  use Moose;
  use MooseX::Role::DryRunnable::Attribute;
  with 'MooseX::Role::DryRunnable::Base';

  has dry_run => (is => 'ro', isa => 'Bool', default => 0);

  sub bar :dry_it {
    shift;
    print "Foo::bar @_\n";
  }

  sub is_dry_run { # required !
    shift->dry_run
  }

  sub on_dry_run { # required !
    my $self   = shift;
    my $method = shift;
    $self->logger("Dry Run method=$method, args: \n", @_);
  }

=head1 DESCRIPTION

This module can be used in Moose classes who uses the role MooseX::Role::DryRunnable::Base. Provides an Attribute :dry_it. EXPERIMETAL

My idea is put the information about the dry run capability close to the method.

=head1 PARAMETERS

=head2 dry_it (CODE)

This method export to UNIVERSAL one parameter called dry_it, and it works with MooseX::Role::DryRunnable

=head1 SEE ALSO

L<Moose::Role>, L<Attribute::Handlers>, L<MooseX::Role::DryRunnable>.

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Tiago Peczenyj <tiago.peczenyj@gmail.com>, or (preferred)
to this package's RT tracker at <bug-MooseX-Role-DryRunnable@rt.cpan.org>.

=head1 AUTHOR

Tiago Peczenyj <tiago.peczenyj@gmail.com>