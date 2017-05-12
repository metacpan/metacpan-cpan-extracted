#!/usr/bin/perl -w

package Sakai::Nakamura::JsonQueryServlet;

use 5.008008;
use strict;
use warnings;
use Carp;
use base qw(Apache::Sling::JsonQueryServlet);
use Sakai::Nakamura;
use Sakai::Nakamura::Authn;

require Exporter;

use base qw(Exporter);

our @EXPORT_OK = ();

our $VERSION = '0.13';

#{{{ sub command_line
sub command_line {
    my ( $class, @ARGV ) = @_;
    my $nakamura = Sakai::Nakamura->new;
    my $config   = $class->config( $nakamura, @ARGV );
    my $authn    = new Sakai::Nakamura::Authn( \$nakamura );
    return $class->run( $nakamura, $config );
}

#}}}

1;

__END__

=head1 NAME

Sakai::Nakamura::JsonQueryServlet - Manipulate the JSON query servlet in a Sakai Nakamura instance.

=head1 ABSTRACT

json query servlet related functionality for nakamura implemented over rest APIs.

=head1 USAGE

use Sakai::Nakamura::JsonQueryServlet;

=head1 DESCRIPTION

Perl library providing a layer of abstraction to the REST json query servlet methods

=head1 REQUIRED ARGUMENTS

None required.

=head1 OPTIONS

n/a

=head1 DIAGNOSTICS

n/a

=head1 EXIT STATUS

0 on success.

=head1 CONFIGURATION

None required.

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

None known.

=head1 AUTHOR

Daniel David Parry <perl@ddp.me.uk>

=head1 LICENSE AND COPYRIGHT

LICENSE: http://dev.perl.org/licenses/artistic.html

COPYRIGHT: (c) 2012 Daniel David Parry <perl@ddp.me.uk>
