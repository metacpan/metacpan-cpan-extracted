package Scrapar::DataHandler::_base;

use strict;
use warnings;
use base 'Scrapar::Var';

sub new {
    my $class = shift;
    my $params_ref = shift || {};

    bless {
	%{$params_ref}
    } => ref($class) || $class;

}

sub handle {
    die "This method must be overridden";
}

1;

__END__

=pod

=head1 NAME

Scrapar::DataHandler::_base - The base class for buildling data handlers

=head1 COPYRIGHT

Copyright 2009 by Yung-chung Lin

All right reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
