package Palm::Keyring;
# $RedRiver: Keyring.pm,v 1.45 2007/02/26 00:02:13 andrew Exp $
########################################################################
# Keyring.pm *** Perl class for Keyring for Palm OS databases.
#
#   This started as Memo.pm, I just made it work for Keyring.
#
# 2006.01.26 #*#*# andrew fresh <andrew@cpan.org>
########################################################################
# Copyright (C) 2006, 2007 by Andrew Fresh
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
########################################################################
use strict;
use warnings;

use Carp;

use base qw/ Palm::StdAppInfo /;

my $ENCRYPT    = 1;
my $DECRYPT    = 0;
my $MD5_CBLOCK = 64;
my $kSalt_Size = 4;
my $EMPTY      = q{};
my $SPACE      = q{ };
my $NULL       = chr 0;

my @CRYPTS = (
    { 
        alias     => 'None',
        name      => 'None',
        keylen    => 8,
        blocksize => 1,
        default_iter => 500,
    },
    { 
        alias     => 'DES-EDE3',
        name      => 'DES_EDE3',
        keylen    => 24,
        blocksize =>  8,
        DES_odd_parity => 1,
        default_iter => 1000,
    },
    {   
        alias     => 'AES128',
        name      => 'Rijndael',
        keylen    => 16,
        blocksize => 16,
        default_iter => 100,
    },
    { 
        alias     => 'AES256',
        name      => 'Rijndael',
        keylen    => 32,
        blocksize => 16,
        default_iter => 250,
    },
);


our $VERSION = 0.95;

sub new 
{
    my $classname = shift;
    my $options = {};

    # hashref arguments
    if (ref $_[0] eq 'HASH') {
      $options = shift;
    }

    # CGI style arguments
    elsif ($_[0] =~ /^-[a-zA-Z0-9_]{1,20}$/) {
      my %tmp = @_;
      while ( my($key,$value) = each %tmp) {
        $key =~ s/^-//;
        $options->{lc $key} = $value;
      }
    }

    else {
        $options->{password} = shift;
        $options->{version}  = shift;
    }

    # Create a generic PDB. No need to rebless it, though.
    my $self = $classname->SUPER::new();

    $self->{name}    = 'Keys-Gtkr';    # Default
    $self->{creator} = 'Gtkr';
    $self->{type}    = 'Gkyr';

    # The PDB is not a resource database by
    # default, but it's worth emphasizing,
    # since MemoDB is explicitly not a PRC.
    $self->{attributes}{resource} = 0;

    # Set the version
    $self->{version} = $options->{version} || 4;

    # Set options
    $self->{options} = $options;

    # Set defaults
    if ($self->{version} == 5) {
        $self->{options}->{cipher} ||= 0; # 'None'
        my $c = crypts($self->{options}->{cipher}) 
            or croak('Unknown cipher ' . $self->{options}->{cipher});
        $self->{options}->{iterations} ||= $c->{default_iter};
        $self->{appinfo}->{cipher} ||= $self->{options}->{cipher};
        $self->{appinfo}->{iter}   ||= $self->{options}->{iterations};
    };

    if ( defined $options->{password} ) {
        $self->Password($options->{password});
    }

    return $self;
}

sub import 
{
    Palm::PDB::RegisterPDBHandlers( __PACKAGE__, [ 'Gtkr', 'Gkyr' ], );
    return 1;
}

# Accessors

sub crypts
{
    my $crypt = shift;
    if (! defined $crypt || ! length $crypt) {
        return;
    } elsif ($crypt =~ /\D/) {
        foreach my $c (@CRYPTS) {
            if ($c->{alias} eq $crypt) {
                return $c;
            }
        }
        # didn't find it.
        return;
    } else {
        return $CRYPTS[$crypt];
    }
}

# ParseRecord

sub ParseRecord 
{
    my $self     = shift;

    my $rec = $self->SUPER::ParseRecord(@_);
    return $rec if ! exists $rec->{data};

    if ($self->{version} == 4) {
        # skip the first record because it contains the password.
        return $rec if ! exists $self->{records}; 

        my ( $name, $encrypted ) = split /$NULL/xm, $rec->{data}, 2;

        return $rec if ! $encrypted;
        $rec->{name}      = $name;
        $rec->{encrypted} = $encrypted;
        delete $rec->{data};

    } elsif ($self->{version} == 5) {
        my $c = crypts( $self->{appinfo}->{cipher} ) 
            or croak('Unknown cipher ' . $self->{appinfo}->{cipher});
        my $blocksize = $c->{blocksize};
        my ($field, $extra) = _parse_field($rec->{data});
        delete $rec->{data};

        $rec->{name}      = $field->{data};
        $rec->{ivec}      = substr $extra, 0, $blocksize;
        $rec->{encrypted} = substr $extra, $blocksize;

    } else {
        die 'Unsupported Version';
        return;
    }

    return $rec;
}

# PackRecord

sub PackRecord 
{
    my $self = shift;
    my $rec  = shift;

    if ($self->{version} == 4) {
        if ($rec->{encrypted}) {
            if (! defined $rec->{name}) {
                $rec->{name} = $EMPTY;
            }
            $rec->{data} = join $NULL, $rec->{name}, $rec->{encrypted};
            delete $rec->{name};
            delete $rec->{encrypted};
        }

    } elsif ($self->{version} == 5) {
        my $field;
        if ($rec->{name}) {
            $field = {
                'label_id' => 1,
                'data'     => $rec->{name},
                'font'     => 0,
            };
        } else {
            $field = {
                'label_id' => $EMPTY,
                'data'     => $EMPTY,
                'font'     => 0,
            };
        }
        my $packed = _pack_field($field);

        $rec->{data} = join '', $packed, $rec->{ivec}, $rec->{encrypted};

    } else {
        die 'Unsupported Version';
    }

    return $self->SUPER::PackRecord($rec, @_);
}

# ParseAppInfoBlock

sub ParseAppInfoBlock 
{
    my $self = shift;
    my $data = shift;
    my $appinfo = {};

    &Palm::StdAppInfo::parse_StdAppInfo($appinfo, $data);

    # int8/uint8 
    # - Signed or Unsigned Byte (8 bits). C types: char, unsigned char
    # int16/uint16 
    # - Signed or Unsigned Word (16 bits). C types: short, unsigned short
    # int32/uint32 
    # - Signed or Unsigned Doubleword (32 bits). C types: int, unsigned int
    # sz 
    # - Zero-terminated C-style string 

    if ($self->{version} == 4) {
        # Nothing extra for version 4

    } elsif ($self->{version} == 5) {
        _parse_appinfo_v5($appinfo) || return;

    } else {
        die "Unsupported Version";
        return;
    }

    return $appinfo;
}

sub _parse_appinfo_v5
{
    my $appinfo = shift;

    if (! exists $appinfo->{other}) {
        # XXX Corrupt appinfo?
        return;
    }

    my $unpackstr
        = ("C1" x 8)  # 8 uint8s in an array for the salt
        . ("n1" x 2)  # the iter (uint16) and the cipher (uint16)
        . ("C1" x 8); # and finally 8 more uint8s for the hash

    my (@salt, $iter, $cipher, @hash);
    (@salt[0..7], $iter, $cipher, @hash[0..7]) 
        = unpack $unpackstr, $appinfo->{other};

    $appinfo->{salt}           = sprintf "%02x" x 8, @salt;
    $appinfo->{iter}           = $iter;
    $appinfo->{cipher}         = $cipher;
    $appinfo->{masterhash}     = sprintf "%02x" x 8, @hash;
    delete $appinfo->{other};

    return $appinfo
}

# PackAppInfoBlock

sub PackAppInfoBlock 
{
    my $self = shift;
    my $retval;

    if ($self->{version} == 4) {
        # Nothing to do for v4

    } elsif ($self->{version} == 5) {
        _pack_appinfo_v5($self->{appinfo});
    } else {
        die "Unsupported Version";
        return;
    }
    return &Palm::StdAppInfo::pack_StdAppInfo($self->{appinfo});
}

sub _pack_appinfo_v5
{
    my $appinfo = shift;

    my $packstr
        = ("C1" x 8)  # 8 uint8s in an array for the salt
        . ("n1" x 2)  # the iter (uint16) and the cipher (uint16)
        . ("C1" x 8); # and finally 8 more uint8s for the hash

    my @salt = map { hex $_ } $appinfo->{salt} =~ /../gxm;
    my @hash = map { hex $_ } $appinfo->{masterhash} =~ /../gxm;

    my $packed = pack($packstr, 
        @salt,
        $appinfo->{iter},
        $appinfo->{cipher},
        @hash
    );

    $appinfo->{other}  = $packed;

    return $appinfo
}

# Encrypt

sub Encrypt 
{
    my $self = shift;
    my $rec  = shift;
    my $data = shift;
    my $pass = shift || $self->{password};
    my $ivec = shift;

    if ( ! $pass && ! $self->{appinfo}->{key}) {
        croak("password not set!\n");
    }

    if ( ! $rec) {
        croak("Needed parameter 'record' not passed!\n");
    }

    if ( ! $data) {
        croak("Needed parameter 'data' not passed!\n");
    }

    if ( $pass && ! $self->Password($pass)) {
        croak("Incorrect Password!\n");
    }

    my $acct;
    if ($rec->{encrypted}) {
        $acct = $self->Decrypt($rec, $pass);
    }

    my $encrypted;
    if ($self->{version} == 4) {
        $self->{digest} ||= _calc_keys( $pass );
        $encrypted = _encrypt_v4($data, $acct, $self->{digest});
        $rec->{name}    ||= $data->{name};

    } elsif ($self->{version} == 5) {
        my @accts = ($data, $acct);
        if ($self->{options}->{v4compatible}) {
            $rec->{name} ||= $data->{name};
            foreach my $a (@accts) {
                my @fields;
                foreach my $k (sort keys %{ $a }) {
                    my $field = {
                        label    => $k,
                        font     => 0,
                        data     => $a->{$k},
                    };
                    push @fields, $field;
                }
                $a = \@fields;
            }
        }

        ($encrypted, $ivec) = _encrypt_v5(
            @accts,
            $self->{appinfo}->{key}, 
            $self->{appinfo}->{cipher},
            $ivec,
        );
        if (defined $ivec) {
            $rec->{ivec} = $ivec;
        }

    } else {
        die "Unsupported Version";
    }

    if ($encrypted) { 
        if ($encrypted eq '1') {
            return 1;
        }

        $rec->{attributes}{Dirty} = 1;
        $rec->{attributes}{dirty} = 1;
        $rec->{encrypted} = $encrypted;

        return 1;
    } else {
        return;
    }
}

sub _encrypt_v4 
{
    my $new    = shift;
    my $old    = shift;
    my $digest = shift;

    $new->{account}  ||= $EMPTY;
    $new->{password} ||= $EMPTY;
    $new->{notes}    ||= $EMPTY;

    my $changed      = 0;
    my $need_newdate = 0;
    if ($old && %{ $old }) {
        foreach my $key (keys %{ $new }) {
            next if $key eq 'lastchange';
            if ($new->{$key} ne $old->{$key}) {
                $changed = 1;
                last;
            }
        }
        if ( exists $new->{lastchange} && exists $old->{lastchange} && (
            $new->{lastchange}->{day}   != $old->{lastchange}->{day}   ||
            $new->{lastchange}->{month} != $old->{lastchange}->{month} ||
            $new->{lastchange}->{year}  != $old->{lastchange}->{year}
        )) {
            $changed = 1;
            $need_newdate = 0;
        } else {
            $need_newdate = 1;
        }

    } else {
        $changed = 1;
    }

    # no need to re-encrypt if it has not changed.
    return 1 if ! $changed;

    my ($day, $month, $year);

    if ($new->{lastchange} && ! $need_newdate ) {
        $day   = $new->{lastchange}->{day}   || 1;
        $month = $new->{lastchange}->{month} || 0;
        $year  = $new->{lastchange}->{year}  || 0;

        # XXX Need to actually validate the above information somehow
        if ($year >= 1900) {
            $year -= 1900;
        }
    } else {
        $need_newdate = 1;
    }

    if ($need_newdate) {
        ($day, $month, $year) = (localtime)[3,4,5];
    }

    my $packed_date = _pack_keyring_date( {
            year  => $year,
            month => $month,
            day   => $day,
    });

    my $plaintext = join $NULL, 
        $new->{account}, $new->{password}, $new->{notes}, $packed_date;

    return _crypt3des( $plaintext, $digest, $ENCRYPT );
}

sub _encrypt_v5
{
    my $new    = shift;
    my $old    = shift;
    my $key    = shift;
    my $cipher = shift;
    my $ivec   = shift;
    my $c = crypts($cipher) or croak('Unknown cipher ' . $cipher);

    if (! defined $ivec) { 
        $ivec = pack("C*",map {rand(256)} 1..$c->{blocksize});
    }

    my $changed = 0;
    my $need_newdate = 1;
    my $date_index;
    for (my $i = 0; $i < @{ $new }; $i++) {
        if (
            ($new->[$i]->{label_id} && $new->[$i]->{label_id} == 3) ||
            ($new->[$i]->{label} && $new->[$i]->{label} eq 'lastchange')
        ) {
            $date_index   = $i;
            if ( $old && $#{ $new } == $#{ $old } && (
                    $new->[$i]{data}{day}   != $old->[$i]{data}{day}   ||
                    $new->[$i]{data}{month} != $old->[$i]{data}{month} ||
                    $new->[$i]{data}{year}  != $old->[$i]{data}{year}
                )) {
                $changed      = 1;
                $need_newdate = 0;
            }

        } elsif ($old && $#{ $new } == $#{ $old }) {
            my $n = join ':', %{ $new->[$i] };
            my $o = join ':', %{ $old->[$i] };
            if ($n ne $o) {
                $changed = 1;
            }
        } elsif ($#{ $new } != $#{ $old }) {
            $changed = 1;
        }
    }
    if ($old && (! @{ $old }) && $date_index) {
        $need_newdate = 0;
    }

    return 1, 0 if $changed == 0;

    if ($need_newdate || ! defined $date_index) {
        my ($day, $month, $year) = (localtime)[3,4,5];
        my $date = {
            year  => $year,
            month => $month,
            day   => $day,
        };
        if (defined $date_index) {
            $new->[$date_index]->{data} = $date;
        } else {
            push @{ $new }, {
                label => 'lastchange',
                font  => 0,
                data  => $date,
            };
        }
    } else {
        # XXX Need to actually validate the above information somehow
        if ($new->[$date_index]->{data}->{year} >= 1900) {
            $new->[$date_index]->{data}->{year} -= 1900;
        }
    }

    my $decrypted;
    foreach my $field (@{ $new }) {
        $decrypted .= _pack_field($field);
    }
    my $encrypted;
    if ($c->{name} eq 'None') {
        # do nothing
        $encrypted = $decrypted;

    } elsif ($c->{name} eq 'DES_EDE3' or $c->{name} eq 'Rijndael') {
        require Crypt::CBC;
        my $cbc = Crypt::CBC->new( 
            -key         => $key,
            -literal_key => 1,
            -iv          => $ivec,
            -cipher      => $c->{name},
            -keysize     => $c->{keylen},
            -blocksize   => $c->{blocksize},
            -header      => 'none',
            -padding     => 'oneandzeroes',
        );

        if (! $c) {
            croak("Unable to set up encryption!");
        }

        $encrypted = $cbc->encrypt($decrypted);

    } else {
        die "Unsupported Version";
    } 

    return $encrypted, $ivec;
}

# Decrypt

sub Decrypt
{
    my $self = shift;
    my $rec  = shift;
    my $pass = shift || $self->{password};

    if ( ! $pass && ! $self->{appinfo}->{key}) {
        croak("password not set!\n");
    }

    if ( ! $rec) {
        croak("Needed parameter 'record' not passed!\n");
    }

    if ( $pass && ! $self->Password($pass)) {
        croak("Invalid Password!\n");
    }

    if ( ! $rec->{encrypted} ) {
        croak("No encrypted content!");
    }

    if ($self->{version} == 4) {
        $self->{digest} ||= _calc_keys( $pass );
        my $acct = _decrypt_v4($rec->{encrypted}, $self->{digest});
        $acct->{name} ||= $rec->{name};
        return $acct;

    } elsif ($self->{version} == 5) {
        my $fields = _decrypt_v5(
            $rec->{encrypted}, $self->{appinfo}->{key}, 
            $self->{appinfo}->{cipher}, $rec->{ivec}, 
        );
        if ($self->{options}->{v4compatible}) {
            my %acct;
            foreach my $f (@{ $fields }) {
                $acct{ $f->{label} } = $f->{data};
            }
            $acct{name} ||= $rec->{name};
            return \%acct;
        } else {
            return $fields;
        }

    } else {
        die "Unsupported Version";
    }
    return;
}

sub _decrypt_v4
{
    my $encrypted = shift;
    my $digest    = shift;

    my $decrypted = _crypt3des( $encrypted, $digest, $DECRYPT );
    my ( $account, $password, $notes, $packed_date ) 
        = split /$NULL/xm, $decrypted, 4;

    my $modified;
    if ($packed_date) {
        $modified = _parse_keyring_date($packed_date);
    }

    return {
        account    => $account,
        password   => $password,
        notes      => $notes,
        lastchange => $modified,
    };
}

sub _decrypt_v5
{

    my $encrypted = shift;
    my $key       = shift;
    my $cipher    = shift;
    my $ivec      = shift;

    my $c = crypts($cipher) or croak('Unknown cipher ' . $cipher);

    my $decrypted;

    if ($c->{name} eq 'None') {
        # do nothing
        $decrypted = $encrypted;

    } elsif ($c->{name} eq 'DES_EDE3' or $c->{name} eq 'Rijndael') {
        require Crypt::CBC;
        my $cbc = Crypt::CBC->new( 
            -key         => $key,
            -literal_key => 1,
            -iv          => $ivec,
            -cipher      => $c->{name},
            -keysize     => $c->{keylen},
            -blocksize   => $c->{blocksize},
            -header      => 'none',
            -padding     => 'oneandzeroes',
        );

        if (! $c) {
            croak("Unable to set up encryption!");
        }
        my $len = $c->{blocksize} - length($encrypted) % $c->{blocksize};
        $encrypted .= $NULL x $len;
        $decrypted  = $cbc->decrypt($encrypted);

    } else {
        die "Unsupported Version";
        return;
    } 

    my @fields;
    while ($decrypted) {
        my $field;
        ($field, $decrypted) = _parse_field($decrypted);
        if (! $field) {
            last;
        }
        push @fields, $field;
    }

    return \@fields;
}

# Password

sub Password 
{
    my $self = shift;
    my $pass = shift;
    my $new_pass = shift;

    if (! $pass) {
        delete $self->{password};
        delete $self->{appinfo}->{key};
        return 1;
    }

    if (
        ($self->{version} == 4 && ! exists $self->{records}) ||
        ($self->{version} == 5 && ! exists $self->{appinfo}->{masterhash})
    ) {
        if ($self->{version} == 4) {
            # Give the PDB the first record that will hold the encrypted password
            $self->{records} = [ $self->new_Record ];
        }

        return $self->_password_update($pass);
    }

    if ($new_pass) {
        my $v4compat = $self->{options}->{v4compatible};
        $self->{options}->{v4compatible} = 0;

        my @accts = ();
        foreach my $i (0..$#{ $self->{records} }) {
            if ($self->{version} == 4 && $i == 0) {
                push @accts, undef;
                next;
            }
            my $acct = $self->Decrypt($self->{records}->[$i], $pass);
            if ( ! $acct ) {
                croak("Couldn't decrypt $self->{records}->[$i]->{name}");
            }
            push @accts, $acct;
        }

        if ( ! $self->_password_update($new_pass)) {
            croak("Couldn't set new password!");
        }
        $pass = $new_pass;

        foreach my $i (0..$#accts) {
            if ($self->{version} == 4 && $i == 0) {
                next;
            }
            delete $self->{records}->[$i]->{encrypted};
            $self->Encrypt($self->{records}->[$i], $accts[$i], $pass);
        }

        $self->{options}->{v4compatible} = $v4compat;
    }

    if (defined $self->{password} && $pass eq $self->{password}) {
        # already verified this password
        return 1;
    }

    if ($self->{version} == 4) {
        # AFAIK the thing we use to test the password is
        #     always in the first entry
        my $valid = _password_verify_v4($pass, $self->{records}->[0]->{data});

        # May as well generate the keys we need now, since we know the password is right
        if ($valid) {
            $self->{digest} = _calc_keys($pass);
            if ($self->{digest} ) {
                $self->{password} = $pass;
                return 1;
            }
        }
    } elsif ($self->{version} == 5) {
        return _password_verify_v5($self->{appinfo}, $pass);
    } else {
        # XXX unsupported version
    }

    return;
}

sub _password_verify_v4 
{
    require Digest::MD5;
    import Digest::MD5 qw(md5);

    my $pass = shift;
    my $data = shift;

    if (! $pass) { croak('No password specified!'); };

    # XXX die "No encrypted password in file!" unless defined $data;
    if ( ! defined $data) { return; };

    $data =~ s/$NULL$//xm;

    my $salt = substr $data, 0, $kSalt_Size;

    my $msg = $salt . $pass; 
    $msg .= "\0" x ( $MD5_CBLOCK - length $msg );

    my $digest = md5($msg);

    if ($data ne $salt . $digest ) {
        return;
    }

    return 1;
}

sub _password_verify_v5 
{
    my $appinfo = shift;
    my $pass    = shift;

    my $salt = pack("H*", $appinfo->{salt});

    my $c = crypts($appinfo->{cipher}) 
        or croak('Unknown cipher ' . $appinfo->{cipher});
    my ($key, $hash) = _calc_key_v5(
        $pass, $salt, $appinfo->{iter}, 
        $c->{keylen}, 
        $c->{DES_odd_parity}, 
    );

    #print "Iter: '" . $appinfo->{iter} . "'\n";
    #print "Key:  '". unpack("H*", $key) . "'\n";
    #print "Salt: '". unpack("H*", $salt) . "'\n";
    #print "Hash: '". $hash . "'\n";
    #print "Hash: '". $appinfo->{masterhash} . "'\n";

    if ($appinfo->{masterhash} eq $hash) {
        $appinfo->{key} = $key;
    } else {
        return;
    }

    return $key;
}


sub _password_update 
{
    # It is very important to Encrypt after calling this
    #     (Although it is generally only called by Encrypt)
    # because otherwise the data will be out of sync with the
    # password, and that would suck!
    my $self   = shift;
    my $pass   = shift;

    if ($self->{version} == 4) {
        my $data = _password_update_v4($pass, @_);

        if (! $data) {
            carp("Failed  to update password!");
            return;
        }

        # AFAIK the thing we use to test the password is
        #     always in the first entry
        $self->{records}->[0]->{data} = $data;
        $self->{password} = $pass;
        $self->{digest}   = _calc_keys( $self->{password} );

        return 1;

    } elsif ($self->{version} == 5) {
        my $cipher  = shift || $self->{appinfo}->{cipher};
        my $iter    = shift || $self->{appinfo}->{iter};
        my $salt    = shift || 0;

        my $hash = _password_update_v5(
            $self->{appinfo}, $pass, $cipher, $iter, $salt
        );

        if (! $hash) {
            carp("Failed  to update password!");
            return;
        }

        return 1;
    } else {
        croak("Unsupported version ($self->{version})");
    }

    return;
}

sub _password_update_v4
{
    require Digest::MD5;
    import Digest::MD5 qw(md5);

    my $pass = shift;
    
    if (! defined $pass) { croak('No password specified!'); };

    my $salt;
    for ( 1 .. $kSalt_Size ) {
        $salt .= chr int rand 255;
    }

    my $msg = $salt . $pass;

    $msg .= "\0" x ( $MD5_CBLOCK - length $msg );

    my $digest = md5($msg);

    my $data = $salt . $digest;    # . "\0";

    return $data;
}

sub _password_update_v5
{
    my $appinfo = shift;
    my $pass    = shift;
    my $cipher  = shift;
    my $iter    = shift;

    # I thought this needed to be 'blocksize', but apparently not.
    #my $length  = $CRYPTS[ $cipher ]{blocksize};
    my $length  = 8;
    my $salt    = shift || pack("C*",map {rand(256)} 1..$length);

    my $c = crypts($cipher) or croak('Unknown cipher ' . $cipher);
    my ($key, $hash) = _calc_key_v5(
        $pass, $salt, $iter, 
        $c->{keylen}, 
        $c->{DES_odd_parity},
    );

    $appinfo->{salt}           = unpack "H*", $salt;
    $appinfo->{iter}           = $iter;
    $appinfo->{cipher}         = $cipher;
    $appinfo->{masterhash}     = $hash;
    $appinfo->{key}            = $key;

    return $key;
}

# Helpers

sub _calc_keys 
{
    my $pass = shift;
    if (! defined $pass) { croak('No password defined!'); };

    my $digest = md5($pass);

    my ( $key1, $key2 ) = unpack 'a8a8', $digest;

    #--------------------------------------------------
    # print "key1: $key1: ", length $key1, "\n";
    # print "key2: $key2: ", length $key2, "\n";
    #--------------------------------------------------

    $digest = unpack 'H*', $key1 . $key2 . $key1;

    #--------------------------------------------------
    # print "Digest: ", $digest, "\n";
    # print length $digest, "\n";
    #--------------------------------------------------

    return $digest;
}

sub _calc_key_v5
{
    my ($pass, $salt, $iter, $keylen, $dop) = @_;

    require Digest::HMAC_SHA1;
    import  Digest::HMAC_SHA1 qw(hmac_sha1);
    require Digest::SHA1;
    import  Digest::SHA1 qw(sha1);

    my $key = _pbkdf2( $pass, $salt, $iter, $keylen, \&hmac_sha1 );
    if ($dop) { $key = _DES_odd_parity($key); }

    my $hash = unpack("H*", substr(sha1($key.$salt),0, 8));

    return $key, $hash;
}

sub _crypt3des 
{
    require Crypt::DES;

    my ( $plaintext, $passphrase, $flag ) = @_;

    $passphrase   .= $SPACE x ( 16 * 3 );
    my $cyphertext = $EMPTY;

    my $size = length $plaintext;

    #print "STRING: '$plaintext' - Length: " . (length $plaintext) . "\n";

    my @C;
    for ( 0 .. 2 ) {
        $C[$_] =
          new Crypt::DES( pack 'H*', ( substr $passphrase, 16 * $_, 16 ));
    }

    for ( 0 .. ( ($size) / 8 ) ) {
        my $pt = substr $plaintext, $_ * 8, 8;

        #print "PT: '$pt' - Length: " . length($pt) . "\n";
        if (! length $pt) { next; };
        if ( (length $pt) < 8 ) {
            if ($flag == $DECRYPT) { croak('record not 8 byte padded'); };
            my $len = 8 - (length $pt);
            $pt .= ($NULL x $len);
        }
        if ( $flag == $ENCRYPT ) {
            $pt = $C[0]->encrypt($pt);
            $pt = $C[1]->decrypt($pt);
            $pt = $C[2]->encrypt($pt);
        }
        else {
            $pt = $C[0]->decrypt($pt);
            $pt = $C[1]->encrypt($pt);
            $pt = $C[2]->decrypt($pt);
        }

        #print "PT: '$pt' - Length: " . length($pt) . "\n";
        $cyphertext .= $pt;
    }

    $cyphertext =~ s/$NULL+$//xm;

    #print "CT: '$cyphertext' - Length: " . length($cyphertext) . "\n";

    return $cyphertext;
}

sub _parse_field 
{
    my $field = shift;

    my @labels;
    $labels[0]   = 'name';
    $labels[1]   = 'account';
    $labels[2]   = 'password';
    $labels[3]   = 'lastchange';
    $labels[255] = 'notes';

    my ($len) = unpack "n1", $field;
    if ($len + 4 > length $field) {
        return undef, $field;
    }
    my $unpackstr = "x2 C1 C1 A$len";
    my $offset    =   2 +1 +1 +$len;
    if ($len % 2) { # && $len + 4 < length $field) {
        # trim the 0/1 byte padding for next even address.
        $offset++;
        $unpackstr .= ' x' 
    }

    my ($label, $font, $data) = unpack $unpackstr, $field;
    my $leftover = substr $field, $offset;

    if ($label && $label == 3) {
        $data = _parse_keyring_date($data);
    }
    return {
        #len      => $len,
        label    => $labels[ $label ] || $label,
        label_id => $label,
        font     => $font,
        data     => $data,
    }, $leftover;
}

sub _pack_field 
{
    my $field = shift;

    my %labels = (
        name       =>   0,
        account    =>   1,
        password   =>   2,
        lastchange =>   3,
        notes      => 255,
    );

    my $packed;
    if (defined $field) {
        my $label = $field->{label_id} || 0;
        if (defined $field->{label} && ! $label) {
            $label = $labels{ $field->{label} };
        }
        my $font  = $field->{font} || 0;
        my $data  = defined $field->{data} ? $field->{data} : $EMPTY;

        if ($label && $label == 3) {
            $data = _pack_keyring_date($data);
        }
        my $len = length $data;
        my $packstr = "n1 C1 C1 A*";

        $packed = pack $packstr, ($len, $label, $font, $data);

        if ($len % 2) {
            # add byte padding for next even address.
            $packed .= $NULL;
        }
    } else {
        my $packstr = "n1 C1 C1 x1";
        $packed = pack $packstr, 0, 0, 0;
    }

    return $packed;
}

sub _parse_keyring_date
{
    my $data = shift;

    my $u = unpack 'n', $data;
    my $year  = (($u & 0xFE00) >> 9) + 4; # since 1900
    my $month = (($u & 0x01E0) >> 5) - 1; # 0-11
    my $day   = (($u & 0x001F) >> 0);     # 1-31

    return {
        year   => $year,
        month  => $month || 0,
        day    => $day   || 1,
    };
}

sub _pack_keyring_date
{
    my $d = shift;
    my $year  = $d->{year};
    my $month = $d->{month};
    my $day   = $d->{day};

    $year -= 4;
    $month++;

    return pack 'n', $day | ($month << 5) | ($year << 9);
}


sub _hexdump
{
    my $prefix = shift;   # What to print in front of each line
    my $data = shift;     # The data to dump
    my $maxlines = shift; # Max # of lines to dump
    my $offset;           # Offset of current chunk

    for ($offset = 0; $offset < length($data); $offset += 16)
    {
        my $hex;   # Hex values of the data
        my $ascii; # ASCII values of the data
        my $chunk; # Current chunk of data

        last if defined($maxlines) && ($offset >= ($maxlines * 16));

        $chunk = substr($data, $offset, 16);

        ($hex = $chunk) =~ s/./sprintf "%02x ", ord($&)/ges;

        ($ascii = $chunk) =~ y/\040-\176/./c;

        printf "%s %-48s|%-16s|\n", $prefix, $hex, $ascii;
    }
}

sub _bindump
{
    my $prefix = shift;   # What to print in front of each line
    my $data = shift;     # The data to dump
    my $maxlines = shift; # Max # of lines to dump
    my $offset;           # Offset of current chunk

    for ($offset = 0; $offset < length($data); $offset += 8)
    {
        my $bin;   # binary values of the data
        my $ascii; # ASCII values of the data
        my $chunk; # Current chunk of data

        last if defined($maxlines) && ($offset >= ($maxlines * 8));

        $chunk = substr($data, $offset, 8);

        ($bin = $chunk) =~ s/./sprintf "%08b ", ord($&)/ges;

        ($ascii = $chunk) =~ y/\040-\176/./c;

        printf "%s %-72s|%-8s|\n", $prefix, $bin, $ascii;
    }
}

# Thanks to Jochen Hoenicke <hoenicke@gmail.com> 
# (one of the authors of Palm Keyring)
# for these next two subs.

# Usage pbkdf2(password, salt, iter, keylen, prf)
# iter is number of iterations
# keylen is length of generated key in bytes
# prf is the pseudo random function (e.g. hmac_sha1)
# returns the key.
sub _pbkdf2($$$$$)
{
    my ($password, $salt, $iter, $keylen, $prf) = @_;
    my ($k, $t, $u, $ui, $i);
    $t = "";
    for ($k = 1; length($t) <  $keylen; $k++) {
    $u = $ui = &$prf($salt.pack('N', $k), $password);
    for ($i = 1; $i < $iter; $i++) {
        $ui = &$prf($ui, $password);
        $u ^= $ui;
    }
    $t .= $u;
    }
    return substr($t, 0, $keylen);
}

sub _DES_odd_parity($) {
    my $key = $_[0];
    my ($r, $i);
    my @odd_parity = (
  1,  1,  2,  2,  4,  4,  7,  7,  8,  8, 11, 11, 13, 13, 14, 14,
 16, 16, 19, 19, 21, 21, 22, 22, 25, 25, 26, 26, 28, 28, 31, 31,
 32, 32, 35, 35, 37, 37, 38, 38, 41, 41, 42, 42, 44, 44, 47, 47,
 49, 49, 50, 50, 52, 52, 55, 55, 56, 56, 59, 59, 61, 61, 62, 62,
 64, 64, 67, 67, 69, 69, 70, 70, 73, 73, 74, 74, 76, 76, 79, 79,
 81, 81, 82, 82, 84, 84, 87, 87, 88, 88, 91, 91, 93, 93, 94, 94,
 97, 97, 98, 98,100,100,103,103,104,104,107,107,109,109,110,110,
112,112,115,115,117,117,118,118,121,121,122,122,124,124,127,127,
128,128,131,131,133,133,134,134,137,137,138,138,140,140,143,143,
145,145,146,146,148,148,151,151,152,152,155,155,157,157,158,158,
161,161,162,162,164,164,167,167,168,168,171,171,173,173,174,174,
176,176,179,179,181,181,182,182,185,185,186,186,188,188,191,191,
193,193,194,194,196,196,199,199,200,200,203,203,205,205,206,206,
208,208,211,211,213,213,214,214,217,217,218,218,220,220,223,223,
224,224,227,227,229,229,230,230,233,233,234,234,236,236,239,239,
241,241,242,242,244,244,247,247,248,248,251,251,253,253,254,254);
    for ($i = 0; $i< length($key); $i++) {
    $r .= chr($odd_parity[ord(substr($key, $i, 1))]);
    }
    return $r;
}

1;
__END__
=head1 NAME

Palm::Keyring - Handler for Palm Keyring databases.

=head1 DESCRIPTION

The Keyring PDB handler is a helper class for the Palm::PDB package. It
parses Keyring for Palm OS databases.  See
L<http://gnukeyring.sourceforge.net/>.

It has the standard Palm::PDB methods with 2 additional public methods.  
Decrypt and Encrypt.

It currently supports the v4 Keyring databases as well as
the pre-release v5 databases.  I am not completely happy with the interface
for accessing v5 databases, so any suggestions on improvements on 
the interface are appreciated.

This module doesn't store the decrypted content.  It only keeps it until it 
returns it to you or encrypts it.

=head1 SYNOPSIS

    use Palm::PDB;
    use Palm::Keyring;
    
    my $pass = 'password';
    my $file = 'Keys-Gtkr.pdb';
    my $pdb  = new Palm::PDB;
    $pdb->Load($file);
    
    foreach (0..$#{ $pdb->{records} }) {
        # skip the password record for version 4 databases
        next if $_ == 0 && $pdb->{version} == 4;
        my $rec  = $pdb->{records}->[$_];
        my $acct = $pdb->Decrypt($rec, $pass);
        print $rec->{name}, ' - ';
        if ($pdb->{version} == 4 || $pdb->{options}->{v4compatible}) {
            print ' - ', $acct->{account};
        } else {
            foreach my $a (@{ $acct }) {
                if ($a->{label} eq 'account') {
                    print ' - ',  $a->{data};
                    last;
                }
            }
        }
        print "\n";
    }

=head1 SUBROUTINES/METHODS

=head2 new

    $pdb = new Palm::Keyring([$password[, $version]]);

Create a new PDB, initialized with the various Palm::Keyring fields
and an empty record list.

Use this method if you're creating a Keyring PDB from scratch otherwise you 
can just use Palm::PDB::new() before calling Load().

If you pass in a password, it will initalize the first record with the encrypted 
password.

new() now also takes options in other formats

    $pdb = new Palm::Keyring({ key1 => value1,  key2 => value2 });
    $pdb = new Palm::Keyring( -key1 => value1, -key2 => value2);

=over

=item Supported options

=over

=item password

The password used to initialize the database

=item version

The version of database to create.  Accepts either 4 or 5.  Currently defaults to 4.

=item v4compatible

The format of the fields passed to Encrypt and returned from Decrypt have changed.
This allows programs to use the newer databases with few changes but with less features.

=item cipher

The cipher to use.  Either the number or the name.

    0 => None
    1 => DES_EDE3
    2 => AES128
    3 => AES256

=item iterations

The number of iterations to encrypt with.

=item options

A hashref of the options that are set

=back

=back

For v5 databases there are some additional appinfo fields set.
These are set either on new() or Load().

    $pdb->{appinfo} = {
        # normal appinfo stuff described in L<Palm::StdAppInfo>
        cipher     => The index number of the cipher being used
        iter       => Number of iterations for the cipher
    };

=head2 crypts

Pass in the alias of the crypt to use, or the index.

These only make sense for v5 databases.

This is a function, not a method.  

$cipher can be 0, 1, 2, 3, None, DES_EDE3, AES128 or AES256.

    my $c = Palm::Keyring::crypt($cipher);

$c is now:

    $c = {
        alias     => (None|DES_EDE3|AES128|AES256),
        name      => (None|DES_EDE3|Rijndael),
        keylen    => <key length of the cipher>,
        blocksize => <block size of the cipher>,
        default_iter => <default iterations for the cipher>,
    };

=head2 Encrypt

    $pdb->Encrypt($rec, $acct[, $password[, $ivec]]);

Encrypts an account into a record, either with the password previously 
used, or with a password that is passed.

$ivec is the initialization vector to use to encrypt the record.  This is
not used by v4 databases.  Normally this is not passed and is generated 
randomly.

$rec is a record from $pdb->{records} or a new_Record().
The v4 $acct is a hashref in the format below.

    my $v4acct = {
        name       => $rec->{name},
        account    => $account,
        password   => $password,
        notes      => $notes,
        lastchange => {
            year  => 107, # years since 1900
            month =>   0, # 0-11, 0 = January, 11 = December
            day   =>  30, # 1-31, same as localtime
        },
    };

The v5 $acct is an arrayref full of hashrefs that contain each encrypted field.

    my $v5acct = [
        {
            'label_id' => 2,
            'data' => 'abcd1234',
            'label' => 'password',
            'font' => 0
        },
        {
            'label_id' => 3,
            'data' => {
                'month' => 1,
                'day' => 11,
                'year' => 107
            },
            'label' => 'lastchange',
            'font' => 0
        },
        {
            'label_id' => 255,
            'data' => 'This is a short note.',
            'label' => 'notes',
            'font' => 0
        }
    ];


The account name is stored in $rec->{name} for both v4 and v5 databases.  
It is not returned in the decrypted information for v5.  

    $rec->{name} = 'account name';

If you have changed anything other than the lastchange, or don't pass in a 
lastchange key, Encrypt() will generate a new lastchange date for you.

If you pass in a lastchange field that is different than the one in the
record, it will honor what you passed in.

Encrypt() only uses the $acct->{name} if there is not already a $rec->{name}.

=head2 Decrypt

    my $acct = $pdb->Decrypt($rec[, $password]);

Decrypts the record and returns a reference for the account as described 
under Encrypt().  

    foreach (0..$#{ $pdb->{records} }) {
        next if $_ == 0 && $pdb->{version} == 4;
        my $rec = $pdb->{records}->[$_];
        my $acct = $pdb->Decrypt($rec);
        # do something with $acct
    }


=head2 Password

    $pdb->Password([$password[, $new_password]]);

Either sets the password to be used to crypt, or if you pass $new_password, 
changes the password on the database.

If you have created a new $pdb, and you didn't set a password when you 
called new(), you only need to pass one password and it will set that as 
the password. 

If nothing is passed, it forgets the password that it was remembering.

After a successful password verification the following fields are set

For v4

    $pdb->{digest}   = the calculated digest used from the key;
    $pdb->{password} = the password that was passed in;

For v5

    $pdb->{appinfo} = {
        # As described under new() with these additional fields
        cipher     => The index number of the cipher being used
        iter       => Number of iterations for the cipher
        key        => The key that is calculated from the password 
                      and salt and is used to decrypt the records.
        masterhash => the hash of the key that is stored in the 
                      database.  Either set when Loading the database
                      or when setting a new password.
        salt       => the salt that is either read out of the database 
                      or calculated when setting a new password.
    };

=head2 Other overridden subroutines/methods

=over

=item ParseAppInfoBlock

Converts the extra returned by Palm::StdAppInfo::ParseAppInfoBlock() into 
the following additions to $pdb->{appinfo}

    $pdb->{appinfo} = {
        cipher     => The index number of the cipher being used (Not v4)
        iter       => Number of iterations for the cipher (Not v4)
    };

=item PackAppInfoBlock

Reverses ParseAppInfoBlock before
sending it on to Palm::StdAppInfo::PackAppInfoBlock()

=item ParseRecord

Adds some fields to a record from Palm::StdAppInfo::ParseRecord()

    $rec = {
        name       => Account name
        ivec       => The IV for the encrypted record.  (Not v4)
        encrypted  => the encrypted information
    };

=item PackRecord

Reverses ParseRecord and then sends it through Palm::StdAppInfo::PackRecord()

=back

=head1 DEPENDENCIES

Palm::StdAppInfo

B<For v4 databases>

Digest::MD5

Crypt::DES

B<For v5 databases>

Digest::HMAC_SHA1

Digest::SHA1

Depending on how the database is encrypted

Crypt::CBC - For any encryption but None

Crypt::DES_EDE3 - DES_EDE3 encryption

Crytp::Rijndael - AES encryption schemes

=head1 THANKS

I would like to thank the helpful Perlmonk shigetsu who gave me some great advice
and helped me get my first module posted.  L<http://perlmonks.org/?node_id=596998>

I would also like to thank 
Johan Vromans
E<lt>jvromans@squirrel.nlE<gt> -- 
L<http://www.squirrel.nl/people/jvromans>.
He had his own Palm::KeyRing module that he posted a couple of days before 
mine was ready and he was kind enough to let me have the namespace as well 
as giving me some very helpful hints about doing a few things that I was 
unsure of.  He is really great.

And finally, 
thanks to Jochen Hoenicke E<lt>hoenicke@gmail.comE<gt> 
(one of the authors of Palm Keyring)
for getting me started on the v5 support as well as providing help
and some subroutines.

=head1 BUGS AND LIMITATIONS

I am sure there are problems with this module.  For example, I have 
not done very extensive testing of the v5 databases.  

I am not sure I am 'require module' the best way, but I don't want to 
depend on modules that you don't need to use.  

I am not very happy with the data structures used by Encrypt() and 
Decrypt() for v5 databases, but I am not sure of a better way.  

The v4 compatibility mode does not insert a fake record 0 where 
normally the encrypted password is stored.

The date validation for packing new dates is very poor.

I have not gone through and standardized on how the module fails.  Some 
things fail with croak, some return undef, some may even fail silently.  
Nothing initializes a lasterr method or anything like that.  I need 
to fix all that before it is a 1.0 candidate. 

Please report any bugs or feature requests to
C<bug-palm-keyring at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 AUTHOR

Andrew Fresh E<lt>andrew@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2004, 2005, 2006, 2007 Andrew Fresh, All Rights Reserved.

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

=head1 SEE ALSO

Palm::PDB(3)

Palm::StdAppInfo(3)

The Keyring for Palm OS website: 
L<http://gnukeyring.sourceforge.net/>

The HACKING guide for palm keyring databases:
L<http://gnukeyring.cvs.sourceforge.net/*checkout*/gnukeyring/keyring/HACKING>

Johan Vromans also has a wxkeyring app that now uses this module, available 
from his website at L<http://www.vromans.org/johan/software/sw_palmkeyring.html>
