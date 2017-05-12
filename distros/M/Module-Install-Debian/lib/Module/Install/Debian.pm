package Module::Install::Debian;

use strict;
use Module::Install::Base;
use English;

use vars qw{$VERSION @ISA};

BEGIN {
    $VERSION = '0.030';
    @ISA     = qw{Module::Install::Base};
}

sub dpkg_requires {
    my $self = shift;

    if ( !$self->can_run('dpkg') ) {
        warn 'No dpkg installed.';
        return;
    }

    while (@_) {
        my $package = shift or last;
        my $version = shift || 0;
        push @{ $self->{values}{dpkg_requires} }, [ $package, $version ];

        # Check for package
        print "Checking dpkg $package status...\n";
        my $dpkg_status  = `dpkg -s $package`;
        my $installed = ( $dpkg_status =~ /^Status\:.*installed/m );
        my ($installed_version) = ( $dpkg_status =~ /^Version\: (.*)$/m );

        if ($installed) {
            print "$package $version ... $installed_version\n";

            # Check version
            return;
        }
        else {
            print "$package $version ... missing\n";
        }

        # Check for apt-get
        if ( !$self->can_run('apt-get') ) {
            warn "No apt-get installed. Needs to but cannot install $package";
            return;
        }

        # Check for root?

        # Install package
        `apt-get install $package`;

    }

    $self->{values}{dpkg_requires};
}

1;

=head1 NAME

Module::Install::Debian - Require debian packages to be installed on the system

=head1 SYNOPSIS

Have your Makefile.PL read as follows:

  use inc::Module::Install;
  
  name      'Foo-Bar';
  all_from  'lib/Foo/Bar.pm';

  dpkg_requires '' => 'bar'; # require .deb file
  
  WriteAll;
  

=head1 DESCRIPTION

Module::Install::Debian allows you to require .deb packages to be installed
on the system.

=head1 METHODS

=over 1

=item * dpkg_requires()

Takes a list of key/value pairs specifying a debian package name and version
number. This will install the package in the system if it is not there allready.

=back

=head1 BUGS

This module will not honour the version requirement yet.

Please report any bugs to (patches welcome):

    http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Module-Install-Debian


=head1 SEE ALSO

L<Module::Install>

=head1 AUTHOR

Bjørn-Olav Strand E<lt>bo@startsiden.noE<gt>

=head1 LICENSE

Copyright 2009 by ABC Startsiden AS, Bjørn-Olav Strand <bo@startsiden.no>.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
