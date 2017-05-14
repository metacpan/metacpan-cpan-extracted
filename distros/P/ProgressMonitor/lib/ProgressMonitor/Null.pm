package ProgressMonitor::Null;

use warnings;
use strict;

require ProgressMonitor if 0;

use classes
  extends => 'ProgressMonitor',
  new     => 'new',
  methods => {
			  begin           => 'EMPTY',
			  end             => 'EMPTY',
			  isCanceled      => 'EMPTY',
			  prepare         => 'EMPTY',
			  setCanceled     => 'EMPTY',
			  setMessage      => 'EMPTY',
			  setErrorMessage => 'EMPTY',
			  tick            => 'EMPTY',
			  subMonitor      => 'subMonitor',
			 },
  class_attrs_pr => [ 'instance' ],
  ;

sub new
{
	my $class = shift;
	my $cfg   = shift;

	no strict 'refs';
	unless ($$CLASS_ATTR_instance)
		{
		# don't pass any cfg; just discard it
		#
		$$CLASS_ATTR_instance = classes::new_only($class);
		}

	return $$CLASS_ATTR_instance;
}

sub subMonitor
{
	no strict 'refs';
	return $$CLASS_ATTR_instance;
}

###

package ProgressMonitor::NullConfiguration;

use strict;
use warnings;

use classes
  extends => 'ProgressMonitor::AbstractConfiguration',
  ;

############################

=head1 NAME

ProgressMonitor::Null - a monitor implementation which doesn't render anything.
Useful if a receiver insists on a monitor impl to talk to.

=head1 SYNOPSIS

  ...
  $someObj->someLongRunningMethod(ProgressMonitor::Null->new);
  ...

  ####
  
  useful pattern inside a method that takes a monitor instance
  but can accept undef for it:
  
  someMethod
  {
    my $monitor = shift;
    
    monitor = ProgressMonitor::Null->new unless $monitor;
    
    ...
    #now the rest of the code is guaranteed a monitor
    ...
  }

=head1 DESCRIPTION

This is a 'null' implementation of the ProgressMonitor interface. It will simply
ignore to render anything, thus it's a good dropin for a method that requires
a monitor instance but you don't wish anything shown. 

Inherits from AbstractStatefulMonitor.

=head1 AUTHOR

Kenneth Olwing, C<< <knth at cpan.org> >>

=head1 BUGS

I wouldn't be surprised! If you can come up with a minimal test that shows the
problem I might be able to take a look. Even better, send me a patch.

Please report any bugs or feature requests to
C<bug-progressmonitor at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ProgressMonitor>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find general documentation for this module with the perldoc command:

    perldoc ProgressMonitor

=head1 ACKNOWLEDGEMENTS

Thanks to my family. I'm deeply grateful for you!

=head1 COPYRIGHT & LICENSE

Copyright 2006,2007 Kenneth Olwing, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of ProgressMonitor::Null
