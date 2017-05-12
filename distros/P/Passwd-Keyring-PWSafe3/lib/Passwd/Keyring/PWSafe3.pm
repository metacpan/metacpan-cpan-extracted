package Passwd::Keyring::PWSafe3;

use warnings;
use strict;
#use parent 'Keyring';
use Crypt::PWSafe3;
use File::Spec;
use File::Basename;
use Term::ReadKey;              # For secure password prompt
use Carp;

=head1 NAME

Passwd::Keyring::PWSafe3 - Password storage based on Password Safe encrypted files

=head1 VERSION

Version 0.61

=cut

our $VERSION = '0.61';

our $APP_NAME = "Passwd::Keyring";
our $FOLDER_NAME = "Perl-Passwd-Keyring";

=head1 SYNOPSIS

Password Safe implementation of L<Passwd::Keyring>. Passwords are
stored in the L<Password Safe|http://passwordsafe.sourceforge.net>
encrypted file.

    use Passwd::Keyring::PWSafe3;

    my $keyring = Passwd::Keyring::PWSafe3->new(
         app=>"blahblah scraper",
         group=>"Johnny web scrapers",
         file=>"/home/joe/secrets.pwsafe3",        # ~/passwd-keyring.pwsafe3 by default
         master_password=>"very secret password",  # Or callback. See below
    );

    my $username = "John";  # or get from .ini, or from .argv...

    my $password = $keyring->get_password($username, "blahblah.com");
    unless( $password ) {
        $password = <somehow interactively prompt for password>;

        # securely save password for future use
        $keyring->set_password($username, $password, "blahblah.com");
    }

    login_somewhere_using($username, $password);
    if( password_was_wrong ) {
        $keyring->clear_password($username, "blahblah.com");
    }

=head1 DESCRIPTION

This module does not require Password Safe to be installed, and can be
used as generic "store many passwords in file encrypted with single
master password" storage. Password Safe GUI, if installed, may help
the user to review, modify, or delete saved passwords.

=over 4

Official GUIs can be freely downloaded from L<the official
site|http://passwordsafe.sourceforge.net> - both Windows and (beta)
Linux versions are available. Apart from them there exist
various L<compatible tools|http://passwordsafe.sourceforge.net/relatedprojects.shtml>,
for example <Pasaffe for Gnome|https://launchpad.net/pasaffe>  or
<PwSafe for Mac|http://passwordsafe.sourceforge.net/relatedprojects.shtml>.

=back

Actual handling of Password Safe format is based on L<Crypt::PWSafe3>
module. Passwd::Keyring::PWSafe3 just wraps it into the interface
compatible with other Passwd::Keyring backends.

See L<Passwd::Keyring::Auto::KeyringAPI> for detailed comments
on keyring methods (this document is installed with
C<Passwd::Keyring::Auto> package).

=head1 CAVEATS

Underlying module (L<Crypt::PWSafe3>) in fact rewrites the whole file
on every save and keeps all passwords cached in memory while active.
This means, that any attempts to use the file paralelly from a few
programs, or from a few objects within one program, are doomed to
cause lost updates. Also, all passwords from the file are kept in
(unprotected) memory while keyring object is active. Therefore, it is
recommended to use separate .psafe3 file for Passwd::Keyring::PWSafe3,
not mixing it with normal Password Safe database, and to keep keyring
object for a short time only, especially if modifications happen.

There are some limitations in L<Crypt::PWSafe3> handling of Password
Safe format. Passwords are read and saved properly and it is possible
to alternate using them from perl, and via Password Safe GUI, but some
less important aspects of the format, like password expiraton policy,
may be ignored. Refer to L<Crypt::PWSafe3> docs for more details.

=head1 DATA MAPPING

Group name is mapped to Password Safe folder.

Realm is mapped as password title.

Username and password are ... well, used as username and password.

=head1 SUBROUTINES/METHODS

=head2 new(app=>'app name', group=>'passwords folder', file=>'pwsafe3 file', master_password=>'secret or callback', lazy_save=>1)

Initializes the processing. Croaks if Crypt::PWSafe3 is not installed or
master password is invalid. May create password file if it is missing.

Handled parameters:

=over 4

=item app

Symbolic application name (used in password notes)

=item group

Name for the password group (used as folder name)

=item file

Location of .pwsafe3 file. If not given, C<passwd-keyring.pwsafe3> in
user home directory is used. Will be created if does not exist. Note:
absolute path is required, relative paths are very error prone.

=item master_password 

Password required to unlock the file. Can be given as string, or
as callback returning a string (usually some way of interactively
asking user for the password).  The callback gets two parameters: app
and file.

If this param is missing, module will prompt interactively for this
password using console prompt.

=item lazy_save

if given, asks not to save the file after every change (saving is
fairly time consuming), but only when $keyring->save is called or when
keyring is destroyed.

=back

Note: it of course does not make much sense to keep app passwords in
encrypted storage if master password is saved in plain text. The
module most natural usage is to interactively ask for master password
(and use it to protect noticeable number of application-specific
passwords).

Ideas of how to workaround this obstacle are welcome. I loosely
consider either caching master password per desktop session
(implementing sht. similar to ssh-agent/gpg-agent or using one of
those somehow), or integrating the tool with PAM to use actual system
password, or both - but while it seems doable on Linux, cross platform
solution is not so easy.

=cut

sub new {
    my ($cls, %args) = @_;

    my $self = {};
    $self->{app} = $args{app} || 'Passwd::Keyring::PWSafe3';
    $self->{group} = $args{group} || 'Passwd::Keyring';
    $self->{lazy_save} = $args{lazy_save};
    my $file = $args{file} || File::Spec->catfile(File::HomeDir->users_data, "passwd-keyring.pwsafe3");

    unless(File::Spec->file_name_is_absolute($file)) {
        croak("Absolute path to .pwsafe3 file is required, but relative path '$file' given");
    }
    my $parent_dir = dirname($file);
    unless(-d $parent_dir) {
        croak("Directory $parent_dir (parent directory of file $file) does not exist");
    }

    # TODO: escape group (note that . are used for hierarchy!)
    # TODO: some locking or maybe detect gui

    bless $self;

    my $master = $args{master_password} || \&_prompt_for_password;
    if(ref($master) eq 'CODE') {
        $master = $master->($self->{app}, $file);
    }

    $self->{vault} = Crypt::PWSafe3->new(file=>$file, password=>$master);

    return $self;
}

sub DESTROY {
    my $self = shift;
    $self->save();
}

sub _prompt_for_password {
    my ($app, $file) = @_;
    print "* The applicaton $app is requesting to access\n";
    print "* the Password Safe file $file\n";
    if (-f $file) {
        print "* Enter master password necessary to unlock this file.\n";
    } else {
        print "* (the file does not exist and will be created on first password save)\n";
        print "* Enter master password which will protect this file.\n";
    }
    while(1) {
        print "  Master password: ";
        ReadMode 'noecho';
        my $password = ReadLine 0; chomp($password);
        ReadMode 'normal';
        print "\n";
        return $password if $password;
    }
}

# Find data record for given params, or undef if not found
sub _find_record {
    my ($self, $username, $realm) = @_;
    my $group = $self->{group};
    foreach my $record($self->{vault}->getrecords()) {
        if( ($record->group || '') eq $group
            && ($record->user || '') eq $username
            && ($record->title || '')  eq $realm) {
            return $record;
        }
    }
    return undef;
}

=head2 set_password(username, password, realm)

Sets (stores) password identified by given realm for given user 

=cut

sub set_password {
    my ($self, $user_name, $user_password, $realm) = @_;

    my $rec = $self->_find_record($user_name, $realm);
    if($rec) {
        $self->{vault}->modifyrecord(
            $rec->uuid,
            passwd => $user_password,
            notes => "Saved by $self->{app}",
           );
    } else {
        $self->{vault}->newrecord(
            group => $self->{group},
            title => $realm,
            user => $user_name,
            passwd => $user_password,
            notes => "Saved by $self->{app}",
            );
    }
    $self->save() unless $self->{lazy_save};
}

=head2 get_password($user_name, $realm)

Reads previously stored password for given user in given app.
If such password can not be found, returns undef.

=cut

sub get_password {
    my ($self, $user_name, $realm) = @_;

    my $rec = $self->_find_record($user_name, $realm);
    if($rec) {
        return $rec->passwd;
    }
    return undef;
}

=head2 clear_password($user_name, $realm)

Removes given password (if present)

=cut

sub clear_password {
    my ($self, $user_name, $realm) = @_;

    my $rec = $self->_find_record($user_name, $realm);
    if($rec) {
        $self->{vault}->deleterecord($rec->uuid);
        $self->save() unless $self->{lazy_save};
        return 1;
    } else {
        return 0;
    }
}

=head2 save

Saves unsaved changes, if any are present.

Important only when lazy_save was given in constructor.

=cut

sub save {
    my ($self) = @_;
    # Crypt::PWSafe3 internally keeps track of changes presence,
    # and makes this noop if there are no changes. So just call it.
    $self->{vault}->save();
}

=head2 is_persistent

Returns info, whether this keyring actually saves passwords persistently.

(true in this case)

=cut

sub is_persistent {
    my ($self) = @_;
    return 1;
}

=head1 AUTHOR

Marcin Kasperski

=head1 BUGS

Please report any bugs or feature requests to 
issue tracker at L<https://bitbucket.org/Mekk/perl-keyring-pwsafe3>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Passwd::Keyring::PWSafe3

You can also look for information at:

L<http://search.cpan.org/~mekk/Passwd-Keyring-PWSafe3/>

Source code is tracked at:

L<https://bitbucket.org/Mekk/perl-keyring-pwsafe3>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Marcin Kasperski.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut


1; # End of Passwd::Keyring::PWSafe3


