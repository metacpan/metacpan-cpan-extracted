#!/usr/bin/env perl
#
# This file is part of TBX-XCS
#
# This software is copyright (c) 2013 by Alan K. Melby.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;
# TODO: test this
# PODNAME: xcs2json.pl
our $VERSION = '0.05'; # VERSION
# ABSTRACT: Print a JSON representation of the input XCS file
use TBX::XCS;
use TBX::XCS::JSON qw(json_from_xcs);
print json_from_xcs(TBX::XCS->new(file => $ARGV[0]));

__END__

=pod

=head1 NAME

xcs2json.pl - Print a JSON representation of the input XCS file

=head1 VERSION

version 0.05

=head1 AUTHOR

Nathan Glenn <garfieldnate@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Alan K. Melby.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
