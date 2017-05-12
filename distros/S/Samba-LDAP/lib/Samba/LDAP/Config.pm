package Samba::LDAP::Config;

require 5.006;

use warnings;
use strict;
use Readonly;
use Regexp::DefaultFlags;
use base qw( Config::Tiny );

our $VERSION = '0.05';

#
# Add Log::Log4perl to all our classes!!!!
#

# Regexp to save param and value in param="value", excluding ""
Readonly my $SPLIT_ON_EQUALS_SIGN => qr{
                                         \A       # Start of string 
                                         \s*      # Whitespace 0 or more
                                         ([^=]+?) # = is terminator of
                                                  # optionally match 1 
                                                  # or more
                                         \s* 
                                         =        # Actual =
                                         \s* 
                                         "        # Actual "
                                         ([^"]*)  # " is terminator of
                                                  # match 0 or more
                                         " 
                                         \s* 
                                         \z       # End of string
                                       };

# Regexp for ${suffix}
Readonly my $SUFFIX_CHARS => qr{ \$ [{] suffix [}] \z};

# Move this up here from read_string. Will benchmark later.
Readonly my $COMMENTS_AND_EMPTY_LINES => qr{
                                             \A   # Start of string
                                             \s*  # Whitespace 0 or more

                                             # Match one or the other
                                             ( ?: [#] | [;] | \z )
                                           };

#========================================================================
#                         -- PUBLIC METHODS --
#========================================================================

#------------------------------------------------------------------------
# find_smbldap()
#
# Looks for smbldap.conf
#------------------------------------------------------------------------

sub find_smbldap {
    my $self = shift;

    if ( -e '/etc/smbldap-tools/smbldap.conf' ) {
        $self->{smbldap_conf} = '/etc/smbldap-tools/smbldap.conf';
    }
    elsif ( -e '/etc/opt/IDEALX/smbldap-tools/smbldap.conf' ) {
        $self->{smbldap_conf} = '/etc/opt/IDEALX/smbldap-tools/smbldap.conf';
    }
    else {
        if ( -d 't' ) {
            chdir 't';
        }
        $self->{smbldap_conf} = 'smbldap.conf';
    }

    # Add more locations here (don't really like this technique) or use
    # Config::Find - Same applies for below two methods

    return $self->{smbldap_conf};
}

#------------------------------------------------------------------------
# find_smbldap_bind()
#
# Looks for smbldap_bind.conf
#------------------------------------------------------------------------

sub find_smbldap_bind {
    my $self = shift;

    if ( -e '/etc/smbldap-tools/smbldap_bind.conf' ) {
        $self->{smbldap_bind_conf} = '/etc/smbldap-tools/smbldap_bind.conf';
    }
    elsif ( -e '/etc/opt/IDEALX/smbldap-tools/smbldap_bind.conf' ) {
        $self->{smbldap_bind_conf} =
          '/etc/opt/IDEALX/smbldap-tools/smbldap_bind.conf';
    }
    else {
        if ( -d 't' ) {
            chdir 't';
        }
        $self->{smbldap_bind_conf} = 'smbldap_bind.conf';
    }

    return $self->{smbldap_bind_conf};
}

#------------------------------------------------------------------------
# find_samba()
#
# Looks for smb.conf
#------------------------------------------------------------------------

sub find_samba {
    my $self = shift;

    if ( -e '/etc/samba/smb.conf' ) {
        $self->{samba_conf} = '/etc/samba/smb.conf';
    }
    elsif ( -e 'usr/local/samba/lib/smb.conf' ) {
        $self->{samba_conf} = '/usr/local/samba/lib/smb.conf';
    }
    else {
        if ( -d 't' ) {
            chdir 't';
        }
        $self->{samba_conf} = 'smb.conf';
    }

    return $self->{samba_conf};
}

#------------------------------------------------------------------------
# read_conf( $filename )
#
# Wrapper to provide an instant error message as returned by the native
# Config::Tiny read method
#------------------------------------------------------------------------

sub read_conf {
    my $self = shift;
    my $file = shift;

    my $conf = $self->read($file);

    # Nice instant user error message
    die $self->errstr() . "\nPlease fix this to continue!\n"
      if $self->errstr();

    return $conf;
}

#------------------------------------------------------------------------
# read_string()
#
# Overrides Config::Tiny's read_string to exclude the " " marks found in
# smbldap.conf and smbldap_bind.conf and remove section handling, as we
# don't have any [sections] in either of these files.
#
# Also substitutes the suffix hash ( ${suffix} ) with its value
#------------------------------------------------------------------------

sub read_string {
    my $class = ref $_[0] ? ref shift: shift;
    my $self = bless {}, $class;
    return undef if !defined $_[0];

    # Parse the file
    my $counter = 0;
    foreach ( split /(?:\015{1,2}\012|\015|\012)/, shift ) {
        $counter++;

        # Skip comments and empty lines
        next if /$COMMENTS_AND_EMPTY_LINES/;

        # Handle properties, but don't save " " and S&R ${suffix}
        if (/$SPLIT_ON_EQUALS_SIGN/) {
            my ( $before_equals, $after_equals ) = ( $1, $2 );

            # Save what's after suffix=, temporarily. (don't like this
            # technique, will come back to it later though)
            if ( $before_equals eq 'suffix' ) {
                $self->{sf_val} = $after_equals;
            }

            # Replace ${suffix} with what was saved above
            $after_equals =~ s{ $SUFFIX_CHARS }{$self->{sf_val}};

            # as normal
            $self->{$before_equals} = $after_equals;
            next;
        }

        return $self->_error("Syntax error at line $counter: '$_'");
    }

    # Not needed for returning
    delete $self->{sf_val};

    return $self;
}

#========================================================================
#                         -- PRIVATE METHODS --
#========================================================================

1;    # Magic true value required at end of module

__END__

=head1 NAME

Samba::LDAP::Config - Config file related tasks for Samba::LDAP


=head1 VERSION

This document describes Samba::LDAP::Config version 0.05


=head1 SYNOPSIS

    use Samba::LDAP::Config;

    my $config = Samba::LDAP::Config->new()
        or die "Can't create object\n";
    
    # Returns where smbldap.conf, smbldap_bind.conf and
    # smb.conf are located
    my $smbldap_conf = $config->find_smbldap();    
    my $smbldap_bind_conf = $config->find_smbldap_bind();
    my $samba_conf = $config->find_samba();
    

=head1 DESCRIPTION

Various methods to find where the related Samba configuration 
files are saved, read them in and write them out etc. 
Subclasses L<Config::Tiny>

B<DEVELOPER RELEASE!>

B<BE WARNED> - Not yet complete and neither are the docs!

=head1 INTERFACE 

=head2 new

Create a new L<Samba::LDAP::Config> object

=head2 find_smbldap

Searches in usual places for F<smbldap.conf> and returns location
found. 

    my $smbldap_conf = $config->find_smbldap();

Returns the F<smbldap.conf> in the F<scripts>, if nothing 
found.

=head2 find_smbldap_bind

Searches in usual places for F<smbldap_bind.conf> and returns location
found.

    my $smbldap_bind_conf = $config->find_smbldap_bind();

Returns the F<smbldap_bind.conf> in the F<scripts>, if nothing 
found.

=head2 find_samba

Searches in usual places for F<smb.conf> and returns location
found.

    my $smb_conf = $config->find_samba();

Returns the F<smb.conf> in the F<scripts>, if nothing 
found.

=head2 read_conf

Wrapper to provide an instant error message as returned by the native
L<Config::Tiny> read method

    my $conf = $config->read_conf( $filename );

=head2 read_string

Overrides L<Config::Tiny>'s L<read_string> to exclude the " " marks found in
F<smbldap.conf> and F<smbldap_bind.conf> and remove section handling, as we
don't have any [sections] in either of these files.

Also substitutes the suffix hash ( ${suffix} ) with its value.

Need to fix the F<smb.conf> reading. Will use L<File::Samba> or 
L<Config::Auto> for it instead.

=head1 DIAGNOSTICS

None yet.


=head1 CONFIGURATION AND ENVIRONMENT

Samba::LDAP::Config requires no configuration files or environment variables.


=head1 DEPENDENCIES

L<Config::Tiny>,
L<Regexp::DefaultFlags> and
L<Readonly>

=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-samba-ldap@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Gavin Henry  C<< <ghenry@suretecsystems.com> >>


=head1 ACKNOWLEDGEMENTS

IDEALX for original scripts.


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2001-2002 IDEALX - Original smbldap-tools

Copyright (c) 2006, Suretec Systems Ltd. - Gavin Henry
C<< <ghenry@suretecsystems.com> >>

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version. See L<perlgpl>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
