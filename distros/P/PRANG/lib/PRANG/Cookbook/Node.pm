
package PRANG::Cookbook::Node;
$PRANG::Cookbook::Node::VERSION = '0.20';
use Moose::Role;

#sub xmlns { "" }

1;

=pod

=head1 NAME

PRANG::Cookbook::Node - Baseclass for nodes in the Cookbook series

=head1 SYNOPSIS

 package PRANG::Cookbook::Node;
 
 use Moose::Role;
 
 #sub xmlns { "" }  # no namespaces required (optional)
 
 1;

=head1 DESCRIPTION

This class is just a base class for every node in the Cookbook
series. It contains nothing more than what is shown above and just
inherits from L<Moose::Role> and provides a convenient place for a
global XML namespace to be specified.

It also overrides the xmlns method to define that these nodes do not
have namespaces (as a default). Instead if a node chooses to define
what namespace it should be in, it is welcome to override this method
too.

=head1 USAGE



=cut

