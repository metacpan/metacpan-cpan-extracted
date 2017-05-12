package MultiProcFactory::Generic;
# @(#) $Name:  $ $Id: Generic.pm,v 1.3 2004/09/14 18:44:16 aaron Exp $
## Aaron Dancygier

use strict;
use vars qw(@ISA $VERSION);
$VERSION = '0.01';

@ISA = qw(MultiProcFactory);

sub init {
  my $self = shift;

  unless (@{$self->{partition_list}} - 0) {
    croak("must pass partition_list\n");
  }

  foreach my $url (@{$self->{partition_list}}) {
    $self->{partition_hash}{$url} = 1;
  }

  $self->{timeout} ||= 30;
}

sub do_child_init {
  my $self = shift;

  return 1;
}

sub work {
  my $self = shift;

  $self->do_child();
}

1;

__END__

=head1 NAME

MultiProcFactory::Generic - product class returned by factory class MultiProcFactory. Generic class that forks off children defined in partition_list.

=head1 DESCRIPTION

This Class is an implementation of the interface for the parent factory object whew.  That might not have made too much sense because perl doesnt really enforce interfaces.  But the interface should basically have 3 methods sub init(), sub do_child_init(), and sub work().  These methods are required as defined by me.  Basically init() is called from base class contructor it sets up your process binning logic at the highest level.  It checks all input parameters and bins items in partition_list into partition_hash.  After initial parent setup in init() do_child_init() is called this method allows you to do child setup initialization.  Finally the work() function is called this method at a minimum must call sub do_child().  This method is the main action method.  In it you define what you want to do at the process level.  In the most basic case you just call do_child() but if youd like to use do_child() as an iterator you might loop over a result set and execute do_child in a loop.

=head1 METHODS

=head2 sub init() class initialization

Bins partition elements into self->{partition_hash}.

=head2 sub do_child_init()

This method does any basic child process level initialization.  In this implentation it does nothing. 

=head2 sub work()

This method at the bare minimum must call do_child().  In the case of this class thats exactly what it does.  Sub classes of this class can expand on this method to iterate do_child over a result set. do_child is a required subroutine reference passed in to parent factory method.

=head1 PARAMETERS AND DEFAULTS

=over 4

=item * partition_list - partition_list => [$url1, $url2, $url3]

* In this generic class this defines the elements to be forked.  Each key relates to one process. 

=back

=head1 AUTHOR

Aaron Dancygier, E<lt>adancygier@bigfootinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Aaron Dancygier

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), MultiProcFactory

=cut

