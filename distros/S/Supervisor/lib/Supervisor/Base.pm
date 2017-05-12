package Supervisor::Base;

our $VERSION = '0.06';

use Supervisor::Class
  base     => 'Badger::Base',
  version  => $VERSION,
  messages => {
      evenparams => "%s requires an even number of paramters\n",
      noalias    => "can not set session alias %s\n",
      badini     => "can not load %s\n",
  }
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub config {
    my ($self, $p) = @_;

    return $self->{config}->{$p};
    
}

1;

__END__

=head1 NAME

Supervisor::Base - The base environment for the Supervisor

=head1 SYNOPSIS

 use Supervisor::Class
   base => 'Supervisor::Base'
 ;

=head1 DESCRIPTION

This is the base module for the Supervisor environmnet. It provides 
some global error messages and one method to retrieve config values. It also
inherits all the properties of Badger::Base.

=head1 ACCESSORS

=over 4

=item config

This method is used to return items from the interal config cache.

=back

=head1 SEE ALSO

 Badger::Base

 Supervisor
 Supervisor::Base
 Supervisor::Class
 Supervisor::Constants
 Supervisor::Controller
 Supervisor::Log
 Supervisor::Process
 Supervisor::ProcessFactory
 Supervisor::Session
 Supervisor::Utils
 Supervisor::RPC::Server
 Supervisor::RPC::Client

=head1 AUTHOR

Kevin L. Esteb, E<lt>kesteb@wsipc.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
