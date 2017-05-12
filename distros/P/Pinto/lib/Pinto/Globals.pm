# ABSTRACT: Global variables used across the Pinto utilities

package Pinto::Globals;

use strict;
use warnings;

use LWP::UserAgent;

#------------------------------------------------------------------------------

our $VERSION = '0.12'; # VERSION

#------------------------------------------------------------------------------

## no critic qw(PackageVars);
our $current_utc_time    = undef;
our $current_time_offset = undef;
our $current_username    = undef;
our $current_author_id   = undef;
our $is_interactive      = undef;

#------------------------------------------------------------------------------
# TODO: Decide how to expose this

our $UA = LWP::UserAgent->new(
	agent      => 'Pinto/' . (__PACKAGE__->VERSION || '???'),
   	env_proxy  => 1,
   	keep_alive => 5,
);

#------------------------------------------------------------------------------
1;

__END__

=pod

=encoding UTF-8

=for :stopwords Jeffrey Ryan Thalhammer

=head1 NAME

Pinto::Globals - Global variables used across the Pinto utilities

=head1 VERSION

version 0.12

=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@stratopan.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Jeffrey Ryan Thalhammer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
