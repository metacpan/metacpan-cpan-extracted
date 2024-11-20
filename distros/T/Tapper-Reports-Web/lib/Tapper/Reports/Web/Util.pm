package Tapper::Reports::Web::Util;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Reports::Web::Util::VERSION = '5.0.17';
use Moose;
use strict;
use warnings;
use 5.010;

use Perl6::Junction qw /any/;


sub prepare_top_menu
{
        my ($self, $active) = @_;
        my $top_menu = [
                { key => 'start',                text => 'Start',                uri => "/tapper/start/",            },
                { key => 'reports',              text => 'Reports',              uri => "/tapper/reports",           },
                { key => 'testruns',             text => 'Testruns',             uri => "/tapper/testruns",          },
                { key => 'testplans',            text => 'Testplans',            uri => "/tapper/testplan",          },
                { key => 'continuoustestruns',   text => 'Continuous Testruns',  uri => "/tapper/continuoustestruns",},
                { key => 'metareports',          text => 'Metareports',          uri => "/tapper/metareports/",      },
                { key => 'manual',               text => 'Manual',               uri => "/tapper/manual/",           },
       ];

        # Some keys may be singular with their actions being named in plural or vice versa. Unify this.
        if ($active) {
                $active = lc($active);
                (my $active_singular) = ($active =~ m/^(.+)s$/) // '';
                (my $active_plural)   = $active."s" // '';
                foreach (@$top_menu) { $_->{active} = 1 if $_->{key} eq any($active, $active_singular, $active_plural) }
        }
        return $top_menu;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Reports::Web::Util

=head1 SYNOPSIS

 use Tapper::Reports::Web::Util;
 my $util = Tapper::Reports::Web::Util->new();
 $util->prepare_top_menu($active_system);

=head1 NAME

Tapper::Reports::Web::Util - Basic utilities for all Tapper::Reports::Web controller

=head1 METHODS

=head2 prepare_top_menu

Creates the required datastructure to show the top menu in all pages.

@param string - active element

@return hash ref containing top menu

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

This software is Copyright (c) 2024 by Advanced Micro Devices, Inc.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
