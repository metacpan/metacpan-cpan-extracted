package Sietima::Policy;
use 5.024;
use strict;
use warnings;
use feature ':5.24';
use experimental 'signatures';

our $VERSION = '1.0.1'; # VERSION
# ABSTRACT: pragma for Sietima modules


sub import {
    # These affect the currently compiling scope,
    # so no need for import::into
    strict->import;
    warnings->import;
    experimental->import('signatures');
    feature->import(':5.24');
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sietima::Policy - pragma for Sietima modules

=head1 VERSION

version 1.0.1

=head1 SYNOPSIS

  use 5.024;
  use strict;
  use warnings;
  use feature ':5.24';
  use experimental 'signatures';

or just:

  use Sietima::Policy;

=head1 DESCRIPTION

This module imports the pragmas shown in the L</synopsis>. All Sietima
modules use it.

=head1 AUTHOR

Gianni Ceccarelli <dakkar@thenautilus.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gianni Ceccarelli <dakkar@thenautilus.net>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
