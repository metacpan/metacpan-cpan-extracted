package Samba::LDAP::User;

# Returned by Perl::MinimumVersion 0.11
require 5.006;

use warnings;
use strict;
use Carp qw(carp croak);
use Regexp::DefaultFlags;
use Readonly;
use Crypt::SmbHash;
use Digest::MD5 qw(md5);
use Digest::SHA1 qw(sha1);
use MIME::Base64 qw(encode_base64);
use List::MoreUtils qw( any );
use Unicode::MapUTF8 qw(to_utf8 from_utf8);
use UNIVERSAL::require;
use base qw(Samba::LDAP::Base);
use Samba::LDAP;
use Samba::LDAP::Group;

our $VERSION = '0.05';

#
# Add Log::Log4perl to all our classes!!!!
#

# Our USAGE messages
Readonly my $DELETE_USER_USAGE => 'Usage: delete_user( 
                                 { 
                                    user => \'ghenry\', 
                                    homedir => \'1\', 
                                 }
                               );';

Readonly my $CHANGE_PASSWORD_USAGE => 'Usage: change_password( 
                                     { 
                                       user    => \'ghenry\',
                                       oldpass => "$oldpass",
                                       newpass => "$newpass",
                                       samba   => \'1\',
                                     }
                                   );';

Readonly my $ADD_USER_USAGE => 'Usage: add_user( 
                                     { 
                                       user    => \'ghenry\',
                                       newpass => "$newpass",
                                       windows_user   => \'1\',
                                       ox => \'1\',
                                     }
                                   );';

Readonly my $GET_NEXT_ID_USAGE =>
  'Usage: _get_next_id( $self->{usersdn}, "$attribute" );';

#========================================================================
#                         -- PUBLIC METHODS --
#========================================================================

#------------------------------------------------------------------------
# change_password( {
#                   user    => 'ghenry',
#                   oldpass => "$oldpass",
#                   newpass => "$newpass",
#                   samba   => '1', # Update only Samba pass, can be
#                  }                # unix => '1' for unix pass only
#                );
#           Note the {} round the args, to report errors at compile time.
#
# Change user password in LDAP Directory
#
# Checks the users exists first, then changes the password
# If user doesn't exist, returns the error etc.
#
# If no oldpass arg is passed, binds as rootdn and sets a password
#
# Default is to add a Samba "and" unix password
#------------------------------------------------------------------------

sub change_password {
    my $self = shift;
    my %args = (
        samba => 1,
        unix  => 1,
        @_,    # argument pair list goes here
    );

    # Required arguments
    my @required_args = ( $args{user}, $args{newpass}, );
    croak $CHANGE_PASSWORD_USAGE
      if any { !defined $_ } @required_args;

    # Die straight away if passwords are the same. Should really be checked
    # by the script/web app using this method, but hey ;-)
    croak "Passwords are the same!\n"
      if ( defined( $args{oldpass} ) eq $args{newpass} );

    # Set the $dn
    my $dn;
    if ( defined $args{dn} ) {
        $dn = $args{dn};
    }
    else {
        $dn = "uid=$args{user},$self->{usersdn}";
    }

    if ( $args{user} && $args{oldpass} && $args{newpass} ) {
        $self->{masterDN} = "uid=$args{user},$self->{usersdn}";
        $self->{masterPw} = "$args{oldpass}";

        # Check the users password if they exist
        if ( !$self->is_valid_user( $dn, $args{oldpass} ) ) {
            $self->error("Authentication failure for $args{user}");
            croak $self->error();
        }
    }

    # test existence of user in LDAP
    if ( !defined( $self->_get_user_dn( $args{user} ) ) ) {
        $self->error("user $args{user} doesn't exist");
        croak $self->error();
    }

    # Generate the password to be used for Unix and Samba pass
    my $hash_password = $self->make_hash(
        clear_pass          => $args{newpass},
        hash_encrypt_format => $self->{hash_encrypt},
        crypt_salt_format   => $self->{crypt_salt_format},
    );

    # Check if a hash was generated, otherwise die
    chomp($hash_password)
      if ( defined($hash_password) )
      or croak "I cannot generate the proper hash!\n";

    # Get ready to bind
    my $ldap = Samba::LDAP->new();

    # If no oldpass argument, bind and set a password as the rootdn
    # Bind details are set in the oldpass check above.
    if ( $args{user} && $args{newpass} ) {
        $ldap = $ldap->connect_ldap_master();
    }

    # Change Samba password if they are actually a Samba user
    if ( $self->is_samba_user( $args{user} ) && $args{samba} ) {

        # generate LanManager and NT clear text passwords
        my ( $sambaLMPassword, $sambaNTPassword ) = ntlmgen $args{newpass};

        # the sambaPwdLastSet attribute must be updated
        my $date = time;
        my @mods;

        # Start setting the modifications
        push( @mods, 'sambaLMPassword' => $sambaLMPassword );
        push( @mods, 'sambaNTPassword' => $sambaNTPassword );
        push( @mods, 'sambaPwdLastSet' => $date );

        if ( defined( $self->{defaultMaxPasswordAge} ) ) {
            my $new_sambaPwdMustChange =
              $date + $self->{defaultMaxPasswordAge} * 24 * 60 * 60;

            push( @mods, 'sambaPwdMustChange' => $new_sambaPwdMustChange );

            # This should only be done by the rootdn, need to put a better
            # check in here
            push( @mods, 'sambaAcctFlags' => '[U]' ) if ( !$args{user} );
        }

        # Let's change nt/lm passwords
        my $modify = $ldap->modify( "$dn", 'replace' => {@mods}, );
        $modify->code && warn "Failed to modify entry: ", $modify->error;

    }

    # Update 'userPassword' field
    if ( defined( $args{unix} ) ) {
        my $modify =
          $ldap->modify( "$dn",
            changes => [ replace => [ userPassword => "$hash_password" ] ], );
        $modify->code && warn "Unable to change password: ", $modify->error;
    }

    # take the session down
    $ldap->unbind;

    return "Password changed.";
}

#------------------------------------------------------------------------
# add_user()
#
# Adds a new LDAP user. Various options
#------------------------------------------------------------------------

sub add_user {
    my $self = shift;
    my %args = (
        @_,    # argument pair list goes here
    );
    my $username = $args{user};

    #my $oldpass  = $args{oldpass};
    my $newpass = $args{newpass};

    # Required arguments
    my @required_args = ( $username, $newpass, );
    croak $ADD_USER_USAGE
      if any { !defined $_ } @required_args;

    # Die straight away if passwords are the same. Should really be checked
    # by the script/web app using this method, but hey ;-)
    #die "Passwords are the same!\n" if ( $args{oldpass} eq $args{newpass} );

    # For computers account, add a trailing dollar if missing
    if ( defined( $args{workstation} ) ) {
        if ( $username =~ /[^\$]$/s ) {
            $username .= "\$";
        }
    }

    # untaint $username (can finish with one or two $)
    if ( $username =~ /^([\w -.]+\$?)$/ ) {
        $username = $1;
    }
    else {
        $self->error("illegal username\n");
        die $self->error();
    }

    # User must not exist in LDAP (should it be nss-wide ?)
    # $rc is return code. We are looking for '1'
    my ( $rc, $dn ) = $self->_get_user_dn2($username);

    if ( $rc and defined($dn) ) {
        $self->error("User $username already exists, can not add.\n");
        croak $self->error();
    }
    elsif ( !$rc ) {
        $self->error("error retrieving details\n");
        croak $self->error();
    }

    # Read options
    # we create the user in the specified ou (relative to the users suffix)
    my $user_ou = $args{ou};
    my $node;

    # Connect
    my $ldap_start = Samba::LDAP->new();
    my $ldap       = $ldap_start->connect_ldap_master();

    if ( defined $user_ou ) {
        if ( !( $user_ou =~ m{^ou=(.*)} ) ) {
            $node    = $user_ou;
            $user_ou = "ou=$user_ou";
        }
        else {
            ($node) = ( $user_ou =~ m{ou=(.*)} );
        }

        # if the ou does not exist, we create it
        my $mesg = $ldap->search(
            base   => $self->{usersdn},
            scope  => 'one',
            filter => "(&(objectClass=organizationalUnit)(ou=$node))"
        );

        $mesg->code && die $mesg->error;

        if ( $mesg->count eq 0 ) {

            # add organizational unit
            my $add = $ldap->add(
                "ou=$node,$self->{usersdn}",
                attr => [
                    'objectclass' => [ 'top', 'organizationalUnit' ],
                    'ou'          => "$node"
                ]
            );
            $add->code && die "failed to add entry: ", $add->error;
        }

        $self->{usersdn} = "$user_ou,$self->{usersdn}";
    }

    my $userUidNumber = $args{user_uid};

    if ( !defined($userUidNumber) ) {
        $userUidNumber = $self->_get_next_id( $self->{usersdn}, 'uidNumber' );
    }
    elsif ( getpwuid($userUidNumber) ) {
        carp "Uid already $userUidNumber exists.\n";
    }

    my $createGroup   = 0;
    my $userGidNumber = $args{group};
    my $group         = Samba::LDAP::Group->new();

    # gid not specified ?
    if ( !defined($userGidNumber) ) {

        # windows machine => $self->{defaultComputerGid}
        if ( defined( $args{workstation} ) ) {
            $userGidNumber = $self->{defaultComputerGid};
        }
        else {

            # user will have gid = $self->{defaultUserGid}
            $userGidNumber = $self->{defaultUserGid};
        }
    }
    else {
        my $gid;

        if ( ( $gid = $group->parse_group($userGidNumber) ) < 0 ) {
            $self->error("unknown group $userGidNumber\n");
            croak $self->error();
        }
        $userGidNumber = $gid;
    }

    my $group_entry;
    my $userGroupSID;
    my $userRid;
    my $user_sid;

    if ( defined $args{windows_user} or defined $args{trust_account} ) {

        # as grouprid we use the value of the sambaSID attribute for
        # group of gidNumber=$userGidNumber

        $group_entry  = $group->read_group_entry_gid($userGidNumber);
        $userGroupSID = $group_entry->get_value('sambaSID');
        unless ($userGroupSID) {
            $self->error( "Error: SID not set for unix group $userGidNumber\n"
                  . "check if your unix group is mapped to an NT group\n" );
            die $self->error();
        }

        # as rid we use 2 * uid + 1000
        $userRid = 2 * $userUidNumber + 1000;

        # let's test if this SID already exist
        $user_sid = "$self->{SID}-$userRid";

        my $test_exist_sid =
          $ldap_start->does_sid_exist( $user_sid, $self->{usersdn} );
        if ( $test_exist_sid->count == 1 ) {
            $self->{sid_message} = "User SID already owned by\n";

            # there should not exist more than one entry, but ...
            foreach my $entry ( $test_exist_sid->all_entries ) {
                my $dn = $entry->dn;
                chomp($dn);
                $self->{sid_message} .= "$dn\n";
            }
            croak $self->{sid_message};
        }
    }

    my $userHomeDirectory;
    my ( $givenName, $userCN, $userSN );
    my @userMailLocal;
    my @userMailTo;
    my $tmp;

    if ( !defined( $userHomeDirectory = $args{homedir} ) ) {
        $userHomeDirectory = $self->_subst_user( $self->{userHome}, $username );
    }

    # RFC 2256
    # sn: : nom (option S)
    # givenName: prenom (option N)
    # cn: person's full name
    $userHomeDirectory =~ s{\/\/}{\/};

    $self->{userLoginShell} = $tmp if ( defined( $tmp = $args{shell} ) );
    $self->{userGecos}      = $tmp if ( defined( $tmp = $args{gecos} ) );
    $self->{skeletonDir}    = $tmp if ( defined( $tmp = $args{skeleton_dir} ) );

    $givenName = ( $self->_utf8Encode( $args{surname} )     || $username );
    $userSN    = ( $self->_utf8Encode( $args{family_name} ) || $username );

    if ( $args{surname} and $args{family_name} ) {
        $userCN = "$givenName" . " $userSN";
    }
    else {
        $userCN = $username;
    }

    # $args{local_mail_address} and $args{mail_to_address} arguments are HoA
    #
    # Passed by:
    #       local_mail_address => [ "ghenry@suretecsystems.com", "me@me.com" ];
    #       mail_to_address => [ "ghenry@ghenry.co.uk", "ghenry@perl.me.uk" ];

    if (   defined( $args{local_mail_address} )
        or defined( $args{mail_to_address} ) )
    {
        @userMailLocal = @{ $args{local_mail_address} };
        @userMailTo    = @{ $args{mail_to_address} };
    }

    # Machine Account
    if ( defined( $args{workstation} ) or defined( $args{trust_account} ) ) {

       # if args{workstation} and username doesn't end with '$'char => we add it
        if ( $args{workstation} and !( $username =~ m{\$$} ) ) {
            $username .= '$';
        }

        my $machine = Samba::LDAP::Machine->new();
        if (
            !$machine->add_posix_machine(
                {
                    user         => $username,
                    uid          => $userUidNumber,
                    gid          => $userGidNumber,
                    time_to_wait => $args{time_to_wait},
                }
            )
          )
        {
            $self->error("error while adding posix account\n");
            die $self->error();
        }

        if ( defined( $args{trust_account} ) ) {

            # For machine trust account
            # Objectclass sambaSAMAccount must be added now !
            my ( $lmpassword, $ntpassword ) = ntlmgen $newpass;
            my $date = time;

            my $modify = $ldap->modify(
                "uid=$username,$self->{computersdn}",
                changes => [
                    replace => [
                        objectClass => [
                            'top',                  'person',
                            'organizationalPerson', 'inetOrgPerson',
                            'posixAccount',         'sambaSAMAccount'
                        ]
                    ],
                    add => [ sambaLogonTime       => '0' ],
                    add => [ sambaLogoffTime      => '2147483647' ],
                    add => [ sambaKickoffTime     => '2147483647' ],
                    add => [ sambaPwdCanChange    => '0' ],
                    add => [ sambaPwdMustChange   => '2147483647' ],
                    add => [ sambaPwdLastSet      => "$date" ],
                    add => [ sambaAcctFlags       => '[I          ]' ],
                    add => [ sambaLMPassword      => "$lmpassword" ],
                    add => [ sambaNTPassword      => "$ntpassword" ],
                    add => [ sambaSID             => "$user_sid" ],
                    add => [ sambaPrimaryGroupSID => "$self->{SID}-515" ]
                ]
            );

            $modify->code && die "failed to add entry: ", $modify->error;
        }

        $ldap->unbind;
        return;
    }

    # USER ACCOUNT
    # add posix account first

    # if AIX account, inetOrgPerson obectclass can't be used
    my $add;
    if ( defined( $args{aix} ) ) {
        $add = $ldap->add(
            "uid=$username,$self->{usersdn}",
            attr => [
                'objectclass' => [
                    'top',                  'person',
                    'organizationalPerson', 'posixAccount',
                    'shadowAccount'
                ],
                'cn'            => "$userCN",
                'sn'            => "$userSN",
                'uid'           => "$username",
                'uidNumber'     => "$userUidNumber",
                'gidNumber'     => "$userGidNumber",
                'homeDirectory' => "$userHomeDirectory",
                'loginShell'    => "$self->{userLoginShell}",
                'gecos'         => "$self->{userGecos}",
                'userPassword'  => "{crypt}x",
            ]
        );
    }
    else {
        $add = $ldap->add(
            "uid=$username,$self->{usersdn}",
            attr => [
                'objectclass' => [
                    'top',                  'person',
                    'organizationalPerson', 'inetOrgPerson',
                    'posixAccount',         'shadowAccount'
                ],
                'cn'            => "$userCN",
                'sn'            => "$userSN",
                'givenName'     => "$givenName",
                'uid'           => "$username",
                'uidNumber'     => "$userUidNumber",
                'gidNumber'     => "$userGidNumber",
                'homeDirectory' => "$userHomeDirectory",
                'loginShell'    => "$self->{userLoginShell}",
                'gecos'         => "$self->{userGecos}",
                'userPassword'  => "{crypt}x",
            ]
        );
    }
    $add->code && carp "failed to add entry: ", $add->error;

    # Add to an LDAP group
    if ( $userGidNumber != $self->{defaultUserGid} ) {
        $group->add_to_group( $userGidNumber, $username );
    }

    my $grouplist;

    # Adds to supplementary groups
    if ( defined( $args{groups} ) ) {
        $group->add_to_groups( $args{groups}, $username );
    }

    # If user was created successfully then we should create his/her home dir
    if ( defined( $tmp = $args{homedir} ) ) {
        unless ( $username =~ /\$$/ ) {
            if ( !( -e $userHomeDirectory ) ) {
                system "mkdir $userHomeDirectory 2>/dev/null";
                system
"cp -a $self->{skeletonDir}/.[a-z,A-Z]* $self->{skeletonDir}/* $userHomeDirectory 2>/dev/null";
                system
"chown -R $userUidNumber:$userGidNumber $userHomeDirectory 2>/dev/null";

                if ( defined $self->{userHomeDirectoryMode} ) {
                    system
"chmod $self->{userHomeDirectoryMode} $userHomeDirectory 2>/dev/null";
                }
                else {
                    system "chmod 700 $userHomeDirectory 2>/dev/null";
                }
            }
        }
    }

# we start to define mail adresses if option $args{homedir} or $args{mail_to_address} is given in option
    my @adds;
    if (@userMailLocal) {
        my @mail;
        foreach my $m (@userMailLocal) {
            my $domain = $self->{mailDomain};
            if ( $m =~ /^(.+)@/ ) {
                push( @mail, $m );

                # mailLocalAddress contains only the first part
                $m = $1;
            }
            else {
                push( @mail, $m . ( $domain ? '@' . $domain : '' ) );
            }
        }
        push( @adds, 'mailLocalAddress' => [@userMailLocal] );
        push( @adds, 'mail'             => [@mail] );
    }
    if (@userMailTo) {
        push( @adds, 'mailRoutingAddress' => [@userMailTo] );
    }
    if ( @userMailLocal || @userMailTo ) {
        push( @adds, 'objectClass' => 'inetLocalMailRecipient' );
    }

    # Add OX User Infos
    if ( defined( $args{ox} ) ) {
        my $modify = $ldap->modify(
            "uid=$username,$self->{usersdn}",
            changes => [
                add => [ objectclass    => ['OXUserObject'] ],
                add => [ shadowMin      => "-1" ],
                add => [ shadowMax      => "99999" ],
                add => [ shadowWarning  => "-1" ],
                add => [ shadowExpire   => "-1" ],
                add => [ shadowInactive => "-1" ],
                add => [ mail           => "$username\@$self->{mailDomain}" ],
                add => [ mailDomain     => "$self->{mailDomain}" ],
                add => [ preferredLanguage => "EN" ],
                add => [ OXAppointmentDays => "5" ],
                add => [ OXGroupID         => "500" ],
                add => [ OXTaskDays        => "5" ],
                add => [ OXTimeZone        => "Europe/London" ],
                add => [ o                 => "Suretec Systems Ltd." ],
                add => [ userCountry       => "Scotland" ],
                add => [ mailEnabled       => "OK" ],
                add => [ lnetMailAccess    => "TRUE" ],
            ]
        );
        $modify->code && die "failed to add entry: ", $modify->error;

        my $add = $ldap->add(
            "ou=addr,uid=$username,$self->{usersdn}",
            attr => [
                'objectclass' => [ 'top', 'organizationalUnit' ],
                'ou'          => "addr"
            ]
        );
        $add->code && warn "failed to add entry: ", $add->error;

        my $modify2 = $ldap->modify(
            "cn=AddressAdmins,o=AddressBook,ou=OxObjects,$self->{suffix}",
            changes => [ add => [ member => "uid=$username,$self->{usersdn}" ] ]
        );
        $modify2->code && die "failed to modify entry: ", $modify2->error;

#system "/usr/local/openxchange/sbin/addusersql_ox --username=$username --lang=EN";
    }

    # Add Samba user infos
    if ( defined( $args{windows_user} ) ) {
        if ( !$self->{with_smbpasswd} ) {

            my $winmagic         = 2147483647;
            my $valpwdcanchange  = 0;
            my $valpwdmustchange = $winmagic;
            my $valpwdlastset    = 0;
            my $valacctflags     = "[UX]";

            if ( defined( $tmp = $args{can_change_pass} ) ) {
                if ( $tmp != 0 ) {
                    $valpwdcanchange = "0";
                }
                else {
                    $valpwdcanchange = "$winmagic";
                }
            }

            if ( defined( $tmp = $args{must_change_pass} ) ) {
                if ( $tmp != 0 ) {
                    $valpwdmustchange = "0";

                    # To force a user to change his password:
                    # . the attribute sambaPwdLastSet must be != 0
                    # . the attribute sambaAcctFlags must not match the 'X' flag
                    $valpwdlastset = $winmagic;
                    $valacctflags  = "[U]";
                }
                else {
                    $valpwdmustchange = "$winmagic";
                }
            }

            if ( defined( $tmp = $args{account_flags} ) ) {
                $valacctflags = "$tmp";
            }

            my $modify = $ldap->modify(
                "uid=$username,$self->{usersdn}",
                changes => [
                    add => [ objectClass        => 'sambaSAMAccount' ],
                    add => [ sambaPwdLastSet    => "$valpwdlastset" ],
                    add => [ sambaLogonTime     => '0' ],
                    add => [ sambaLogoffTime    => '2147483647' ],
                    add => [ sambaKickoffTime   => '2147483647' ],
                    add => [ sambaPwdCanChange  => "$valpwdcanchange" ],
                    add => [ sambaPwdMustChange => "$valpwdmustchange" ],
                    add => [ displayName        => "$self->{userGecos}" ],
                    add => [ sambaAcctFlags     => "$valacctflags" ],
                    add => [ sambaSID           => "$self->{SID}-$userRid" ]
                ]
            );

            $modify->code && die "failed to add entry: ", $modify->error;

        }
        else {
            my $FILE = "|smbpasswd -s -a $username >/dev/null";
            open( FILE, $FILE ) || die "$!\n";
            print FILE <<EOF;
x
x
EOF
            close FILE;
            if ($?) {
                $self->error("Error adding samba account\n");
                die $self->error();
            }
        }

        $tmp =
          defined( $args{logon_script} )
          ? $args{logon_script}
          : $self->{userScript};
        my $valscriptpath = $self->_subst_user( $tmp, $username );

        $tmp =
          defined( $args{home_path} ) ? $args{home_path} : $self->{userSmbHome};
        my $valsmbhome = $self->_subst_user( $tmp, $username );

        my $valhomedrive =
          defined( $args{home_drive} )
          ? $args{home_drive}
          : $self->{userHomeDrive};

        # If the letter is given without the ":" symbol, we add it
        $valhomedrive .= ':' if ( $valhomedrive && $valhomedrive !~ /:$/ );

        $tmp =
          defined( $args{user_profile} )
          ? $args{user_profile}
          : $self->{userProfile};
        my $valprofilepath = $self->_subst_user( $tmp, $username );

        if ($valhomedrive) {
            push( @adds, 'sambaHomeDrive' => $valhomedrive );
        }
        if ($valsmbhome) {
            push( @adds, 'sambaHomePath' => $valsmbhome );
        }

        if ($valprofilepath) {
            push( @adds, 'sambaProfilePath' => $valprofilepath );
        }
        if ($valscriptpath) {
            push( @adds, 'sambaLogonScript' => $valscriptpath );
        }
        if ( !$self->{with_smbpasswd} ) {
            push( @adds, 'sambaPrimaryGroupSID' => $userGroupSID );
            push( @adds, 'sambaLMPassword'      => "XXX" );
            push( @adds, 'sambaNTPassword'      => "XXX" );
        }
        my $modify =
          $ldap->modify( "uid=$username,$self->{usersdn}", add => {@adds} );

        $modify->code && die "failed to add entry: ", $modify->error;
    }

    # add AIX user
    if ( defined( $args{aix_user} ) ) {
        my $modify = $ldap->modify(
            "uid=$username,$self->{usersdn}",
            changes => [
                add => [ objectClass     => 'aixAuxAccount' ],
                add => [ passwordChar    => "!" ],
                add => [ isAdministrator => "false" ]
            ]
        );

        $modify->code && die "failed to add entry: ", $modify->error;
    }

    # Finally, set their password
    if ( defined( $args{newpass} ) ) {
        $self->change_password(
            user    => "$args{user}",
            newpass => "$newpass",
        );
    }

    $ldap->unbind;    # take down session

    return;
}

#------------------------------------------------------------------------
# delete_user( user => 'ghenry', )
#
# Delete the LDAP user and remove their home drive (if homedir => '1',)
#
# In addition to the original userdel script, this searches for
#  subordinate objects, and deletes them first
#------------------------------------------------------------------------

sub delete_user {
    my $self = shift;
    my %args = (
        @_,    # argument pair list goes here
    );

    # Required arguments
    my @required_args = ( $args{user}, );
    croak $DELETE_USER_USAGE
      if any { !defined $_ } @required_args;

    my $user = $args{user};

    my $dn_line;
    if ( !defined( $dn_line = $self->_get_user_dn($user) ) ) {
        $self->error("User $user doesn't exist\n");
        croak $self->error();
    }

    # Get ready to remove them from the Directory
    my $ldap = Samba::LDAP->new();

    # Remove user from groups
    my $group  = Samba::LDAP::Group->new();
    my @groups = $group->find_groups($user);

    if (@groups) {
        for my $gname (@groups) {
            if ( $gname ne "" ) {
                $group->remove_from_group( $gname, $user );
            }
        }
    }

    my $dn = $ldap->get_dn_from_line($dn_line);

    $ldap = $ldap->connect_ldap_master();

    # Here we do a Sub-Tree search, with the users DN as the base to
    # find anything below.
    my $mesg = $ldap->search(
        base   => "uid=$user,$self->{usersdn}",
        scope  => 'sub',
        filter => "(objectclass=*)",
    );
    $mesg->code && croak $mesg->error;

    my @entries = $mesg->all_entries;
    foreach my $entr (@entries) {

        # Remove sub-entries, but move on if we hit the actual user
        next if ( $entr->dn =~ m{^uid} );

        my $modify = $ldap->delete( $entr->dn );
        $modify->code
          && croak "Failed to delete sub-trees of user $user, ", $modify->error;
    }

    # Now delete the top level user
    my $modify = $ldap->delete($dn);
    $modify->code
      && croak "Failed to delete user '$user', ", $modify->error;

    # Remove their Home Drive
    my $homedir;
    if ( defined( $args{homedir} ) ) {
        $homedir = $self->get_homedir($user);

        if ( $homedir !~ /^\/.+\/(.*)$user/ ) {
            $self->error("Refusing to delete this home directory: $homedir\n");
            croak $self->error();
        }
    }

    if ($homedir) {
        my $module = 'File::Path';
        $module->require or die $@;

        # Delete it!
        rmtree($homedir);
    }

    my $nscd_status = system "/etc/init.d/nscd status >/dev/null 2>&1";

    if ( $nscd_status == 0 ) {
        system "/etc/init.d/nscd restart > /dev/null 2>&1";
    }

    $ldap->unbind;    # take down session

    return;
}

#
# Replace the next 3 methods with (don't like code repetition):
#
# foreach (qw/valid samba unix/) {
#   *{"is_${_}_user"} = sub { shift->_generic_is_user($_) };
# }
#
#
# Or use something like __PACKAGE__->mk_accessors(...)
# or make __PACKAGE__->mk_is_user_methods(qw/valid samba unix/);
#
# Even Sub::Install would do.
#

#------------------------------------------------------------------------
# disable_user( $username )
#
# Disable a user by clearing their password and disabling in Samba
#------------------------------------------------------------------------

sub disable_user {
    my $self = shift;
    my $user = shift;

    $self->error("Need username!\n");
    croak $self->error() if !defined($user);

    my $dn_line;
    if ( !defined( $dn_line = $self->_get_user_dn($user) ) ) {
        $self->error("User $user doesn't exist\n");
        croak $self->error();
    }

    my $ldap = Samba::LDAP->new();
    my $dn   = $ldap->get_dn_from_line($dn_line);

    $ldap = $ldap->connect_ldap_slave();

    # Put test in here to see is user has already been disabled.
    #
    # Does it matter if they have? Changes will just be made again, so
    # mayeb test not needed.
    #
    #my $mesg = $ldap->search (
    #                               base   => $self->{suffix},
    #                               scope => $self->{scope},
    #                               filter =>"($dn)",
    #                               attrs => 'UserPassword',
    #                              );
    #$mesg->code && croak $mesg->error;

    my $modify =
      $ldap->modify( "$dn",
        changes => [ replace => [ userPassword => '{crypt}!x' ] ] );
    $modify->code && croak "failed to modify entry: ", $modify->error;

    if ( $self->is_samba_user($user) ) {
        my $modify =
          $ldap->modify( "$dn",
            changes => [ replace => [ sambaAcctFlags => '[D       ]' ] ] );
        $modify->code && croak "failed to modify entry: ", $modify->error;
    }

    return;
}

#------------------------------------------------------------------------
# is_valid_user( $dn,$password )
#
# bind to a directory with the user dn and password. Returns 1 on success
# and 0 on failure
#------------------------------------------------------------------------

sub is_valid_user {
    my $self    = shift;
    my $dn      = shift;
    my $oldpass = shift;

    my $ldap_slave = Net::LDAP->new(
        $self->{slaveLDAP},
        port    => $self->{slavePort},
        version => 3,
        timeout => 60,
      )
      or carp "LDAP error: Can't contact slave ldap server ($@)\n
               =>trying to contact the master server\n";

    if ( !$ldap_slave ) {

        # connection to the slave failed: trying to contact the master ...
        $ldap_slave = Net::LDAP->new(
            $self->{masterLDAP},
            port    => $self->{masterPort},
            version => 3,
            timeout => 60,
        ) or carp "LDAP error: Can't contact master ldap server ($@)\n";
    }

    if ($ldap_slave) {
        if ( $self->{ldapTLS} == 1 ) {
            $ldap_slave->start_tls(
                verify     => $self->{verify},
                clientcert => $self->{clientcert},
                clientkey  => $self->{clientkey},
                cafile     => $self->{cafile},
            );
        }

        my $mesg = $ldap_slave->bind( dn => $dn, password => $oldpass );

        if ( $mesg->code == 0 ) {
            $ldap_slave->unbind;
            return 1;
        }
        else {
            if ( $ldap_slave->bind() ) {
                $ldap_slave->unbind;
                return 0;
            }
            else {
                $self->error("The LDAP directory is not available.");
                $ldap_slave->unbind;
                return 0;
            }
            die "Problem: contact your administrator";
        }
    }

    return $self->error();
}

#------------------------------------------------------------------------
# is_samba_user( $username )
#
# Check user is a Samba user in the LDAP directory
#
# returns 1
#------------------------------------------------------------------------

sub is_samba_user {
    my $self = shift;
    my $user = shift;

    my $ldap = Samba::LDAP->new();
    $ldap = $ldap->connect_ldap_master();

    my $mesg = $ldap->search(
        base   => $self->{suffix},
        scope  => $self->{scope},
        filter => "(&(objectClass=sambaSamAccount)(uid=$user))"
    );

    $mesg->code && die $mesg->error;
    return ( $mesg->count != 0 );
}

#------------------------------------------------------------------------
# is_unix_user( $username )
#
# Check user is a Unix user in the LDAP directory
#
# returns 1 if user found
#------------------------------------------------------------------------

sub is_unix_user {
    my $self = shift;
    my $user = shift;

    my $ldap = Samba::LDAP->new();
    $ldap = $ldap->connect_ldap_master();

    my $mesg = $ldap->search(
        base   => $self->{suffix},
        scope  => $self->{scope},
        filter => "(&(objectClass=posixAccount)(uid=$user))"
    );
    $mesg->code && croak $mesg->error;
    return ( $mesg->count != 0 );
}

#------------------------------------------------------------------------
# is_nonldap_unix_user()
#
# Description here
#------------------------------------------------------------------------

sub is_nonldap_unix_user {
    my $self = shift;
}

#------------------------------------------------------------------------
# get_homedir()
#
# Discovery the home directory from the user entry in the Directory
# Server
#
# Returns undef, if not found.
#------------------------------------------------------------------------

sub get_homedir {
    my $self    = shift;
    my $user    = shift;
    my $homeDir = '';
    my $entry;

    my $ldap = Samba::LDAP->new();
    $ldap = $ldap->connect_ldap_master();

    my $mesg = $ldap->search(
        base   => $self->{usersdn},
        scope  => $self->{scope},
        filter => "(&(objectclass=posixAccount)(uid=$user))"
    );
    $mesg->code && croak $mesg->error;

    my $nb = $mesg->count;
    if ( $nb > 1 ) {
        carp "Aborting: there are $nb existing users named $user\n";
        foreach $entry ( $mesg->all_entries ) {
            my $dn = $entry->dn;
            print "  $dn\n";
        }
        return;
    }
    else {
        $entry = $mesg->shift_entry();
        if ( defined $entry ) {
            $homeDir = $entry->get_value('homeDirectory');
        }
    }

    chomp $homeDir;
    if ( $homeDir eq '' ) {
        return undef;
    }
    return $homeDir;
}

#------------------------------------------------------------------------
# make_hash( {
#                clear_pass => 'original_pass',
#                hash_encrypt_format => 'SSHA',
#                crypt_salt_format   => '%s',
#            }
#          )
#
# A substitute for slappasswd tool
#
# Generates a hash which is one of the following RFC 2307 schemes:
# CRYPT, MD5, SMD5, SHA, SSHA, and CLEARTEXT
#
# SSHA is default
# '%s' is a default crypt_salt_format
#------------------------------------------------------------------------

sub make_hash {
    my $self = shift;
    my %args = (
        hash_encrypt_format => 'SSHA',
        crypt_salt_format   => '%s',
        @_,    # argument pair list goes here
    );

    # Save args for laziness ;-)
    my $clear_pass = $args{clear_pass};

    # Complain if no password passed.
    $self->error("Need password to hash!\n");
    croak $self->error() if !defined($clear_pass);

    my $hash_encrypt      = '{' . $args{hash_encrypt_format} . '}';
    my $crypt_salt_format = $args{crypt_salt_format};

    if ( $hash_encrypt eq '{CRYPT}' && defined($crypt_salt_format) ) {

        # Generate CRYPT hash
        # for unix md5crypt $crypt_salt_format = '$1$%.8s'
        my $salt = sprintf( $crypt_salt_format, $self->_make_salt() );
        $self->{hash_pass} = '{CRYPT}' . crypt( $clear_pass, $salt );
    }
    elsif ( $hash_encrypt eq '{MD5}' ) {

        # Generate MD5 hash
        $self->{hash_pass} = '{MD5}' . encode_base64( md5($clear_pass), '' );
    }
    elsif ( $hash_encrypt eq '{SMD5}' ) {

        # Generate SMD5 hash (MD5 with salt)
        my $salt = $self->_make_salt(4);
        $self->{hash_pass} =
          '{SMD5}' . encode_base64( md5( $clear_pass . $salt ) . $salt, '' );
    }
    elsif ( $hash_encrypt eq '{SHA}' ) {

        # Generate SHA1 hash
        $self->{hash_pass} = '{SHA}' . encode_base64( sha1($clear_pass), '' );
    }
    elsif ( $hash_encrypt eq '{SSHA}' ) {

        # Generate SSHA hash (SHA1 with salt)
        my $salt = $self->_make_salt(4);
        $self->{hash_pass} =
          '{SSHA}' . encode_base64( sha1( $clear_pass . $salt ) . $salt, '' );
    }
    elsif ( $hash_encrypt eq '{CLEARTEXT}' ) {
        $self->{hash_pass} = $clear_pass;
    }
    else {
        $self->error("Bad format $self->{hash_encrypt_format}\n");
        return $self->error();
    }

    return $self->{hash_pass};
}

#========================================================================
#                         -- PRIVATE METHODS --
#========================================================================

#------------------------------------------------------------------------
# _get_next_id( $self->{usersdn}, $attribute )
#
# Get the next id for the new user in add_user() and make the change in
# the directory, i.e. increase uidNumber by 1.
# $attribute is something like uidNumber
#------------------------------------------------------------------------

sub _get_next_id {
    my $self         = shift;
    my $ldap_base_dn = shift;
    my $attribute    = shift;

    # Required arguments
    my @required_args = ( $ldap_base_dn, $attribute, );
    croak $GET_NEXT_ID_USAGE
      if any { !defined $_ } @required_args;

    my $tries = 0;
    my $found = 0;
    my $next_uid_mesg;
    my $nextuid;

    my $ldap = Samba::LDAP->new();
    $ldap = $ldap->connect_ldap_slave();

    if ( $ldap_base_dn =~ m/$self->{usersdn}/i ) {

        # when adding a new user, we'll check if the uidNumber available is not
        # already used for a computer's account
        $ldap_base_dn = $self->{suffix};
    }
    do {
        $next_uid_mesg = $ldap->search(
            base   => $self->{sambaUnixIdPooldn},
            filter => '(objectClass=sambaUnixIdPool)',
            scope  => 'base',
        );
        $next_uid_mesg->code && die "Error looking for next uid";

        if ( $next_uid_mesg->count != 1 ) {
            die "Could not find base dn, to get next $attribute";
        }
        my $entry = $next_uid_mesg->entry(0);

        $nextuid = $entry->get_value($attribute);
        my $modify =
          $ldap->modify( "$self->{sambaUnixIdPooldn}",
            changes => [ replace => [ $attribute => $nextuid + 1 ], ], );
        $modify->code && die "Error: ", $modify->error;

      # let's check if the id found is really free (in ou=Groups or ou=Users)...
        my $check_uid_mesg = $ldap->search(
            base   => $ldap_base_dn,
            filter => "($attribute=$nextuid)",
        );
        $check_uid_mesg->code
          && die "Cannot confirm $attribute $nextuid is free";

        if ( $check_uid_mesg->count == 0 ) {
            $found = 1;
            return $nextuid;
        }
        $tries++;
        print "Cannot confirm $attribute $nextuid is free: checking for the next
one\n"
    } while ( $found != 1 );

    die "Could not allocate $attribute!";
}

#------------------------------------------------------------------------
# _utf8Encode( $user )
#
# Wrapper for to_utf8
#-----------------------------------------------------------------------

sub _utf8Encode {
    my $self      = shift;
    my $to_encode = shift;

    return to_utf8(
        -string  => $to_encode,
        -charset => 'ISO-8859-1',
    );
}

#------------------------------------------------------------------------
# _utf8Decode( $user )
#
# Wrapper for from_utf8
#-----------------------------------------------------------------------

sub _utf8Decode {
    my $self      = shift;
    my $to_decode = shift;

    return from_utf8(
        -string  => $to_decode,
        -charset => 'ISO-8859-1',
    );
}

#------------------------------------------------------------------------
# _get_user_dn( $user )
#
# Searches for a users distinguised name
#------------------------------------------------------------------------

sub _get_user_dn {
    my $self = shift;
    my $user = shift;

    my $ldap = Samba::LDAP->new();
    $ldap = $ldap->connect_ldap_slave();

    my $mesg = $ldap->search(
        base   => $self->{suffix},
        scope  => $self->{scope},
        filter => "(&(objectclass=posixAccount)(uid=$user))"
    );
    $mesg->code && die $mesg->error;

    for my $entry ( $mesg->all_entries ) {
        $self->{dn} = $entry->dn;
    }

    # Shut down session
    $ldap->unbind;

    if ( !$self->{dn} ) {
        croak "Can not find $user user";
    }

    my $dn = $self->{dn};
    chomp($dn);

    $dn = "dn: " . $dn;

    return $dn;
}

#------------------------------------------------------------------------
# _get_user_dn2( $user )
#
# Same as above, but returns 1 this time as well.
#------------------------------------------------------------------------

sub _get_user_dn2 {
    my $self = shift;
    my $user = shift;

    my $ldap = Samba::LDAP->new();
    $ldap = $ldap->connect_ldap_slave();

    my $mesg = $ldap->search(
        base   => $self->{suffix},
        scope  => $self->{scope},
        filter => "(&(objectclass=posixAccount)(uid=$user))"
    );
    $mesg->code && die $mesg->error;

    for my $entry ( $mesg->all_entries ) {
        $self->{dn} = $entry->dn;
    }

    # Shut down session
    $ldap->unbind;

    my $dn = $self->{dn};

    if ( defined($dn) ) {
        chomp($dn);

        $dn = "dn: " . $dn;
        return ( 1, $dn );
    }
    else {
        return ( 1, undef );
    }
    return;
}

#------------------------------------------------------------------------
# _subst_user( $string, $username )
#
# Replaces the %U in the main settings with their username (don't like
# and will replace on new version)
#
#------------------------------------------------------------------------

sub _subst_user {
    my $self     = shift;
    my $str      = shift;
    my $username = shift;

    $str =~ s/%U/$username/ if ($str);
    return ($str);
}

#------------------------------------------------------------------------
# _make_salt( $length )
#
# Generates salt
#
# Pretty much the same as the Crypt::Salt module from CPAN, except our
# $length is 32 by default
#------------------------------------------------------------------------

sub _make_salt {
    my $self = shift;
    my $length = shift || '32';

    my @tab = ( '.', '/', 0 .. 9, 'A' .. 'Z', 'a' .. 'z' );

    return join "", @tab[ map { rand 64 } ( 1 .. $length ) ];
}

1;    # Magic true value required at end of module

__END__

=head1 NAME

Samba::LDAP::User - Manipulate a Samba LDAP User

=head1 VERSION

This document describes Samba::LDAP::User version 0.05


=head1 SYNOPSIS

    use Carp;
    use Samba::LDAP::User;
    
    # create Template object
    my $user = Samba::LDAP::User->new()
        or croak "Can't create object\n";

=head1 DESCRIPTION

Various methods to manipulate a Samba LDAP user. Add, delete,
modify, show and change a users password.

B<DEVELOPER RELEASE!>

B<BE WARNED> - Not yet complete and neither are the docs!


=head1 INTERFACE 

=head2 new

Create a new L<Samba::LDAP::User> object

=head2 add_user

Takes many options. For example:
    
    user =>
    oldpass =>
    newpass =>
    workstation =>
    ou =>
    user_uid =>
    group =>
    windows_user =>
    trust_account =>
    homedir =>
    shell =>
    gecos =>
    skeleton_dir =>
    surname =>
    family_name =>
    local_mail_address =>
    mail_to_address =>
    time_to_wait =>
    aix =>
    groups =>
    ox =>
    can_change_pass =>
    must_change_pass =>
    account_flags =>
    logon_script =>
    home_path =>
    home_drive =>
    user_profile =>
    aix_user =>

The above options are only needed if you don't want to use the defaults
that are set in F</etc/smbldap/smbldap.conf>

=head2 delete_user

=head2 disable_user

=head2 is_valid_user

=head2 is_samba_user

=head2 is_unix_user

=head2 is_nonldap_unix_user

=head2 get_homedir

=head2 make_hash

=head2 change_password
    
    change_password( 
                   user    => 'ghenry',
                   oldpass => "$oldpass",
                   newpass => "$newpass",
                   samba   => '1', # Update only Samba pass, can be
                                  # unix => '1' for unix pass only
                );

Change user password in LDAP Directory

Checks the users exists first, then changes the password
If user doesn't exist, returns the error etc.

If no oldpass arg is passed, binds as rootdn and sets a password

Default is set to change/add a Samba "and" Unix password. If you don't 
want this, pass in unix => '0', or samba => '0', etc.
    
=head1 DIAGNOSTICS

None yet.


=head1 CONFIGURATION AND ENVIRONMENT

Samba::LDAP::User requires no environment variables, only
F</etc/smbldap/smbldap.conf> and F</etc/smbldap/smbldap_bind.conf>

=head1 DEPENDENCIES

L<Carp>
L<Regexp::DefaultFlags>
L<Readonly>
L<Crypt::SmbHash>
L<Digest::MD5>
L<Digest::SHA1>
L<MIME::Base64>
L<List::MoreUtils>
L<Unicode::MapUTF8>


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
