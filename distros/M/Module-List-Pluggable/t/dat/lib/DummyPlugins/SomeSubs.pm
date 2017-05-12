package DummyPlugins::SomeSubs;
#                                doom@kzsu.stanford.edu
#                                12 May 2007

=head1 NAME

DummyPlugins::SomeSubs - a set of dummy plugins

=head1 SYNOPSIS

   use DummyPlugins::SomeSubs;

=head1 DESCRIPTION

To be used for testing Module::List::Pluggable

In this style of "plugin", the subs are written as methods,
but exported to another namespace via Exporter.

=head2 EXPORT

"nothing_much" and "back_atcha".

=cut

use 5.006;
use strict;
use warnings;
my $DEBUG = 1;
use Carp;
use Data::Dumper;

require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(
) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw(
                  nothing_much
                  back_atcha
               );

our $VERSION = '0.01';


sub nothing_much {
  my $self = shift;  # right?
  return "Nothing much. What's with you?";
}

sub back_atcha {
  my $self = shift;  # right?
  my $string = shift;
  return "Do you say: $string";
}

1;


=head1 SEE ALSO

L<Module::List::Pluggable>
L<List::Filter>

=head1 AUTHOR

Joseph Brenner, E<lt>doom@kzsu.stanford.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Joseph Brenner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
