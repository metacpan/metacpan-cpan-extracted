package Tapper::MCP::Control;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::MCP::Control::VERSION = '5.0.6';
use strict;
use warnings;

use Moose;
use Tapper::Config;
use Tapper::Model qw/model/;

extends 'Tapper::MCP';

has testrun  => (is => 'ro',
                 isa => 'Tapper::Schema::TestrunDB::Result::Testrun',
                );



around BUILDARGS => sub {
        my $orig  = shift;
        my $class = shift;


        my $args;
        if ( @_ == 1) {
                if (not ref $_[0] eq 'HASH' )  {
                        $args->{testrun} = $_[0];
                } else {
                        $args = shift;
                }
                if (not ref $args->{testrun}) {
                        $args->{testrun} = model->resultset('Testrun')->find($args->{testrun});
                }
                return $args;
        }
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::MCP::Control

=head1 SYNOPSIS

 use Tapper::MCP::Control;

=head1 NAME

Tapper::MCP::Control - Shared code for all modules that only handle one
                        specifid testrun

=head1 FUNCTIONS

=head1 AUTHOR

AMD OSRC Tapper Team, C<< <tapper at amd64.org> >>

=head1 BUGS

None.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

 perldoc Tapper

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2008-2011 AMD OSRC Tapper Team, all rights reserved.

This program is released under the following license: freebsd

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
