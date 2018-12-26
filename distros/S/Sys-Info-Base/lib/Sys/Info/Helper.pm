package Sys::Info::Helper;
$Sys::Info::Helper::VERSION = '0.7807';
use strict;
use warnings;
use base qw(Exporter);
use File::Spec::Functions qw( catdir catfile );
use File::Path;
use File::Basename;
use Cwd;
use Carp qw( croak );
use Data::Dumper;
use Text::Template::Simple;

our @EXPORT  = qw( new_driver );

sub new {
    my($class, @args) = @_;
    my $self  = {
        @args % 2 ? () : @args,
    };
    bless $self, $class;
    return $self;
}

sub new_driver {
    my $os   = shift || croak 'OS name?';
    my $you  = shift || 'Your Name';
    my $self = __PACKAGE__->new( os => $os, you => $you );
    my $mb   = catdir qw( lib Sys Info Driver );
    my %file = (
        catfile( $mb, "$os.pm"               ) => $self->_template( 'base'    ),
        catfile( $mb, $os, 'OS.pm'           ) => $self->_template( 'os'      ),
        catfile( $mb, $os, 'Device.pm'       ) => $self->_template( 'device'  ),
        catfile( $mb, $os, 'Device', 'CPU.pm') => $self->_template( 'cpu'     ),
        catfile( qw( t 01-basic.t )          ) => $self->_template( 't'       ),
        'Changes'                              => $self->_template( 'changes' ),
        'README'                               => $self->_template( 'readme'  ),
    );
    $file{MANIFEST} = $self->_manifest( \%file );
    return print Dumper( \%file );
}

sub _write_files {}

sub _manifest {
    my($self, $file) = @_;
    my @list = keys %{ $file };
    return join "\n", map { s{\\}{/}xmsg; $_ } sort @list;
}

sub _template {
    my($self, $target) = @_;
    my $meth = '_template_' . $target;
    croak "$target is not a valid target" if ! $self->can( $meth );
    my $id = $self->{os};
    my $you = $self->{you};
    my $date = localtime time;
    my $year = (localtime time)[5] + 1900;
    my $perlv = $];
    my $tmp = $self->$meth();
    $tmp =~ s{<%ID%>}{$id}xmsg;
    $tmp =~ s{<%DATE%>}{$date}xmsg;
    $tmp =~ s{<%YEAR%>}{$year}xmsg;
    $tmp =~ s{<%PERLV%>}{$perlv}xmsg;
    $tmp =~ s{<%YOU%>}{$you}xmsg;
    return $tmp;
}

sub _template_readme {
    my $self = shift;
    return <<'TEMPLATE';
Sys::Info::Driver::<%ID%>
========================

<%ID%> driver for Sys::Info.

Read the module's POD for documentation.
See the tests for examples.

INSTALLATION

To install this module type the following:

   perl Makefile.PL
   make
   make test
   make install

or under Windows:

   perl Makefile.PL
   nmake
   nmake test
   nmake install

COPYRIGHT

Copyright (c) <%YEAR%> <%YOU%>. All rights reserved.

LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version <%PERLV%> or, 
at your option, any later version of Perl 5 you may have available.
TEMPLATE
}

sub _template_changes {
    my $self = shift;
    return <<'TEMPLATE';
Revision history for Perl extension Sys::Info::Driver::<%ID%>.

0.10 <%DATE%>
    => Initial release.

TEMPLATE
}

sub _template_device {
    my $self = shift;
    return <<'TEMPLATE';
package Sys::Info::Driver::<%ID%>::Device;
use strict;
use warnings;
use vars qw( $VERSION );

$VERSION = '0.10';

1;

__END__

=head1 NAME

Sys::Info::Driver::<%ID%>::Device - Base class for <%ID%> device drivers

=head1 SYNOPSIS

    use base qw( Sys::Info::Driver::<%ID%>::Device );

=head1 DESCRIPTION

Base class for <%ID%> device drivers.

=cut

TEMPLATE
}

sub _template_base {
    my $self = shift;
    return <<'TEMPLATE';
package Sys::Info::Driver::<%ID%>;
use strict;
use warnings;
use vars qw( $VERSION );

$VERSION = '0.10';

1;

__END__

=head1 NAME

Sys::Info::Driver::<%ID%> - <%ID%> driver for Sys::Info

=head1 SYNOPSIS

    use Sys::Info::Driver::<%ID%>;

=head1 DESCRIPTION

This is the main module in the C<<%ID%>> driver collection.

=cut
TEMPLATE
}

sub _template_cpu {
    my $self = shift;
    return <<'TEMPLATE';
package Sys::Info::Driver::<%ID%>::Device::CPU;
use strict;
use warnings;
use vars qw($VERSION);
use base qw(Sys::Info::Base);

$VERSION = '0.10';

sub identify { }

sub bitness { }

sub load { }

1;

__END__

=head1 NAME

Sys::Info::Driver::<%ID%>::Device::CPU - <%ID%> CPU Device Driver

=head1 SYNOPSIS

-

=head1 DESCRIPTION

Identifies the CPU.

=head1 METHODS

=head2 identify

See identify in L<Sys::Info::Device::CPU>.

=head2 load

See load in L<Sys::Info::Device::CPU>.

=head2 bitness

See bitness in L<Sys::Info::Device::CPU>.

=head1 SEE ALSO

L<Sys::Info>, L<Sys::Info::Device::CPU>.

=cut
TEMPLATE
}

sub _template_t {
    my $self = shift;
    return <<'TEMPLATE';
#!/usr/bin/env perl
use strict;
use warnings;
use Test::Sys::Info;

driver_ok('<%ID%>');
TEMPLATE
}

sub _template_os {
    my $self = shift;
    return <<'TEMPLATE';
package Sys::Info::Driver::<%ID%>::OS;
use strict;
use warnings;
use vars qw( $VERSION );
use base qw( Sys::Info::Base );

$VERSION = '0.10';

sub init {
    my $self = shift;
    # initialize here, if necessary
    return;
}

sub logon_server {}

sub edition { }

sub tz { }

sub meta { }

sub tick_count { }

sub name { }

sub version { }

sub build { }

sub uptime { }

sub is_root { }

sub login_name { }

sub node_name { }

sub domain_name { }

sub fs { }

sub bitness { }

1;

__END__

=pod

=head1 NAME

Sys::Info::Driver::<%ID%>::OS - <%ID%> backend

=head1 SYNOPSIS

-

=head1 DESCRIPTION

-

=head1 METHODS

Please see L<Sys::Info::OS> for definitions of these methods and more.

=head2 build

=head2 domain_name

=head2 edition

=head2 fs

=head2 is_root

=head2 login_name

=head2 logon_server

=head2 meta

=head2 name

=head2 node_name

=head2 tick_count

=head2 tz

=head2 uptime

=head2 version

=head2 bitness

=head1 SEE ALSO

L<Sys::Info>, L<Sys::Info::OS>.
=cut

TEMPLATE
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sys::Info::Helper

=head1 VERSION

version 0.7807

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 NAME 

Sys::Info::Helper - Helps to create new Sys::Info drivers.

=head1 METHODS

=head2 new

=head1 FUNCTIONS

=head2 new_driver

=head1 SEE ALSO

L<Sys::Info>.

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by Burak Gursoy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
