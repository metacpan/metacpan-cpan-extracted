##- the Free Software Foundation; either version 2, or (at your option)
##- any later version.
##-
##- This program is distributed in the hope that it will be useful,
##- but WITHOUT ANY WARRANTY; without even the implied warranty of
##- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##- GNU General Public License for more details.
##-
##- You should have received a copy of the GNU General Public License
##- along with this program; if not, write to the Free Software
##- Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
# $Id$

package RPM4::Sign;

use strict;
use warnings;

use RPM4;

sub new {
    my ($class, %options) = @_;

    my $Sign;
    $Sign = {
        _signature => undef,
        name => undef,
        path => undef,
        checkrpms => 1,
        passphrase => undef,

        password_file => undef,

        log => sub {
            my ($m, @v) = @_;
            printf STDERR "$m\n", @v;
        },

    };

    foreach (keys %$Sign) {
        defined($options{$_}) and $Sign->{$_} = $options{$_};
    }
    
    bless($Sign, $class);
    $Sign->getpubkey();
    $Sign->getpasswdfile();
    $Sign;
}

sub getpasswdfile {
    my ($self) = @_;
    $self->{password_file} or return 1;
    open(my $hpass, "<", $self->{password_file}) or return 0;
    $self->{passphrase} = <$hpass>;
    chomp($self->{passphrase});
    close($hpass);
    1;
}

sub adjustmacro {
    my ($self) = @_;

    defined($self->{_signature}) and RPM4::add_macro("_signature $self->{_signature}");

    foreach my $macro (qw(_gpg_name _pgp_name)) {
        RPM4::add_macro("$macro $self->{name}") if (defined($self->{name}));
    }
    
    foreach my $macro (qw(_gpg_path _pgp_path)) {
        RPM4::add_macro("$macro $self->{path}") if (defined($self->{path}));
    }
}

sub restoremacro {
    my ($self) = @_;

    if (defined($self->{_signature})) { RPM4::del_macro('_signature'); }
    
    if (defined($self->{name})) {
        RPM4::del_macro('_gpg_name');
        RPM4::del_macro('_pgp_name');
    }

    if (defined($self->{path})) {
        RPM4::del_macro('_gpg_path');
        RPM4::del_macro('_pgp_path');
    }
}

sub getpubkey {
    my ($self) = @_;
    $self->adjustmacro();
    my $gpgcmd;
    if (RPM4::expand("%_signature") eq "gpg") {
        $gpgcmd = '%__gpg --homedir %_gpg_path --list-public-keys --with-colons \'%_gpg_name\'';
    }
    open(my $hgpg, RPM4::expand($gpgcmd) .'|') or return undef;
    while (my $l = <$hgpg>) {
        chomp($l);
        my @v = split(':', $l);
        if ($v[0] eq 'pub') {
           $self->{keyid} = $v[4];
           last;
        }
    }
    close($hgpg);
    $self->restoremacro();
}

sub rpmsign {
    my ($self, $rpm, $header) = @_;
    my $need = 1;

    $header or return -1;
    
    if (RPM4::expand("_signature") || "" eq "gpg") {
        my $sigid = $header->queryformat("%{SIGGPG:pgpsig}");
        ($sigid) = $sigid =~ m/Key ID (\S+)/;
        if ($sigid && lc($sigid) eq lc($self->{keyid} || "")) { $need = 0 }
    }
    
    if ($need > 0) {
        $self->adjustmacro();
        rpmresign($self->{passphrase}, $rpm) and $need = -1;
        $self->restoremacro();
    }

    $need;
}

sub rpmssign {
    my ($self, @rpms) = @_;

    RPM4::parserpms(
        rpms => [ @rpms ],
        checkrpms => $self->{checkrpms},
        callback => sub {
            my (%arg) = @_;
            defined($arg{header}) or do {
                $self->{log}->("bad rpm %s", $arg{rpm});
                return;
            };
            my $res = $self->rpmsign($arg{rpm}, $arg{header});
            if ($res > 0) { $self->{log}->("%s has been resigned", $arg{rpm}); 
            } elsif ($res < 0) { $self->{log}->("Can't resign %s", $arg{rpm}); }
        },
    );
}

1;

__END__

=head1 NAME

RPM4::Sign

=head1 SYNOPSIS

A container to massively resign packages

=head1 DESCRIPTION

This object retains gpg options and provides functions to easilly sign or
resign packages. It does not resign packages having already the proper
signature.

=head1 METHODS

=head2 new(%options)

Create a new RPM4::Sign object.

Options are:

=over 4

=item name

The gpg key identity to use

=item path

the gpg homedir where keys are located

=item password_file

Use passphrase contains in this files

=item passphrase

Use this passphrase to unlock the key

=item checkrpms

Set to 0 remove the signature checking on packages

=back

=head2 rpmssign(@filelist)

Sign or resign the packages passed are arguments

=head1 SEE ALSO

L<RPM4>
L<RPM4::Header>

=cut
