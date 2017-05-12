# $Id: Dot.pm 6 2007-09-13 10:22:19Z asksol $
# $Source: /opt/CVS/Getopt-LL/inc/Module/Build/Getopt/LL.pm,v $
# $Author: asksol $
# $HeadURL: https://class-dot.googlecode.com/svn/class-dot/inc/Module/Build/Class/Dot.pm $
# $Revision: 6 $
# $Date: 2007-09-13 12:22:19 +0200 (Thu, 13 Sep 2007) $
package Module::Build::Debian;

use strict;
use warnings;
use version; our $VERSION = qv('1.0.0');

use Carp        qw(croak);
use FindBin     qw($Bin);
use English     qw( -no_match_vars );

my $DEFAULT_DH_MAKE_PERL = '/usr/bin/dh-make-perl';

my @CLEAN_FILES = qw(
    build-stamp
    install-stamp
    debian
);

my %EXPORT   = (
    ACTION_debian       => \&ACTION_debian,
    ACTION_debianclean  => \&ACTION_debianclean,
);

sub import {
    my $this_class = shift;
    my $call_class = caller;
   
    while (my ($method_name, $coderef) = each %EXPORT) {
        no strict 'refs'; ## no critic
        my $fqdn   = join q{::}, $call_class, $method_name;
        *{ $fqdn } = $coderef;
    }

    return;
}

sub _set_debauthor {
    my ($self) = @_;

    # Set author name and email for the debian package.
    my $author_name;
    my $author_mail;
    my $dist_author = $self->dist_author->[0];
    if ($dist_author =~ m/ \s*(.+?)\s*    < (.+?) >/xms) {
        $author_name = defined $1   ? $1 : $dist_author;
        $author_mail = defined $2   ? $2 : q{};
    }
    $ENV{DEBFULLNAME} ||= $author_name;
    $ENV{DEBEMAIL}    ||= $author_mail;

    return;
}

sub ACTION_debian  {
    my $self = shift;

    CLEANFILE:
    for my $file (@CLEAN_FILES) {
        if (-f $file || -d _) {
            $self->ACTION_debianclean();
            last CLEANFILE;
        }
    }

    my $dh_make_perl = $self->notes('dh_make_perl') || $DEFAULT_DH_MAKE_PERL;

    if (! -f $dh_make_perl && -x _) {
        croak "Can't find dh-make-perl ($dh_make_perl): $OS_ERROR. " .
              "Please configure the 'dh_make_perl' option\n";
    }

    # Create the shell command for dh-make-perl.
    my @cmd = ($dh_make_perl, '--build', $Bin);
    my $cmd_string = join q{ }, @cmd;

    _set_debauthor($self);

    $self->log_info(">>> Creating debian package with dh-make-perl [$cmd_string]\n");

    system @cmd;

    return;
}

sub ACTION_debianclean {
    my $self = shift;
    
    for my $file (@CLEAN_FILES) {
        $self->delete_filetree($file);
    }

    return;
}


1;

__END__

=pod


=for stopwords dh debian Solem

=head1 NAME

Module::Build::Debian - Module::Build extension to build .deb packages using C<dh-make-perl>.

=head1 VERSION

This document describes Module::Build::Debian version 1.0.0.

=head1 SYNOPSIS

    # In your Module::Build subclass:

        # We use eval because we only want the feature if
        # Module::Build::Debian is actually installed.
        BEGIN {
            eval 'use Module::Build::Debian';
        }


    # Then, you can use Build.PL to create a debian package of the module: 
    
        $ perl Build.PL
    
        $ ./Build debian
    
        $ ./Build debianclean

=head1 DESCRIPTION

This is a C<Module::Build> extension that simplifies building Debian .deb
packages using C<dh-make-perl>. To use it, all you have to do is use the
module in your Module::Build subclass.

=head1 Module::Build COMMANDS

=head2 C<./Build debian>

Builds the a debian package of the module using C<dh-make-perl>. An
error-message is printed If <dh-make-perl> is not installed.


=head2 C<./Build debianclean>

Removes temporary-files and history files created by C<dh-make-perl> after a
C<./Build debian>.

=head1 SUBROUTINES/METHODS

=head2 INSTANCE METHODS

=head3 C<ACTION_debian()>

This is the method that is executed when you run C<./Build debian>.

=head3 C<ACTION_debianclean()>

This is the method that is executed when you run C<./Build debianclean>.

=head1 DIAGNOSTICS

=head2 C<Can't find dh-make-perl (%s): $s.">

Apparently, C<dh-make-perl> is missing from your system.

You can install C<dh-make-perl> with apt-get:

    sudo apt-get install dh-make-perl

=head1 CONFIGURATION AND ENVIRONMENT

=head2 ENVIRONMENT VARIABLES

By default it fetches the author's name and e-mail address from the POD of the
module, but you can also set name and email with the following environment
variables:

=head3 C<DEBFULLNAME>

The debian package author's full name.

=head3 C<DEBEMAIL>

The debian package author's e-mail address.

=head1 DEPENDENCIES


=over 4

=item * L<Module::Build>

=item * L<version>

=back



=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-module-build-debian@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 SEE ALSO

=over 4

=item * L<dh-make-perl>

Program to create debian packages out of perl module-distributions
using C<Module::Build> or C<ExtUtils::MakeMaker>.

=item * L<Module::Build>

The Module::Build perldoc documentation.

=item * L<Module::Build::Cookbook>

The Module::Build cookbook.

=back

=head1 AUTHOR

Ask Solem, C<< ask@0x61736b.net >>.


=head1 LICENSE AND COPYRIGHT

Copyright (c), 2007 Ask Solem C<< ask@0x61736b.net >>.

All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE
SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE
STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE
SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND
PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE,
YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY
COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE
SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO
LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR
THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER
SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGES.

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
# End:
# vim: expandtab tabstop=4 shiftwidth=4 shiftround
