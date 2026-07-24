package OpenSearch::Client::Hash;
$OpenSearch::Client::Hash::VERSION = '3.007010';
use Moo;
use MIME::Base64 ();
use Crypt::URandom;
use Crypt::Bcrypt 0.011;
use Crypt::Argon2 0.013;
use Crypt::PBKDF2 0.161520;
use namespace::clean;

sub create_bcrypt_password_hash {
    my($self, %options) = @_;
    $options{type} ||= '2y';
    $options{rounds} ||= 12;
    $options{password} ||= '';
    
    my $salt = Crypt::URandom::urandom(16);
    
    unless($options{password}) {
        die 'you must provide a password';
    }
    {
        my $pwdlen = length($options{password});
        if ($pwdlen > 72 ) {
            die 'your password is longer than 72 characters';
        }   
    }
    
    $options{type} = lc($options{type});
    unless($options{type} =~ /^2(a|b|y)$/ ) {
        die qq(invalid type '$options{type}' : valid options are 2y, 2a or 2b);
    }
    
    unless($options{rounds}
       && $options{rounds} =~ /^[1-9][0-9]*$/
       && $options{rounds} >= 4
       && $options{rounds} <= 31
       ) {
        die qq(Invalid rounds "$options{rounds}". Must be an integer between 4 and 31 inclusive.);
    }
        
    my $hash = Crypt::Bcrypt::bcrypt($options{password}, $options{type}, $options{rounds}, $salt);
    unless(Crypt::Bcrypt::bcrypt_check($options{password}, $hash)) {
        die 'failed to verify created hash';
    }
    return $hash;
}

sub create_argon2_password_hash {
    my($self, %options) = @_;
    $options{password} ||= '';
    $options{type}   ||= 'argon2id';
    $options{length} ||= 32;
    $options{iterations} ||= 3;
    $options{memory} ||= 65536;
    
    my $salt = Crypt::URandom::urandom(32);
    
    unless($options{password}) {
        die 'you must provide a password';
    }
    
    $options{type} = lc($options{type});
        
    unless($options{type} =~ /\Aargon2i\Z|\Aargon2d\Z|\Aargon2id\Z/ ) {
        die qq(invalid type '$options{type}' : valid options are argon2i, argon2d or argon2id);
    }
    
    unless($options{iterations}
       && $options{iterations} =~ /^[1-9][0-9]*$/
       ) {
        die qq(Invalid iterations "$options{iterations}". Must be an integer);
    }
    
    unless($options{length}
       && $options{length} =~ /^[1-9][0-9]*$/
       ) {
        die qq(Invalid length "$options{length}". Must be an integer);
    }
    
    unless($options{memory}
       && $options{memory} =~ /^[1-9][0-9]*$/
       ) {
        die qq(Invalid memory "$options{memory}". Must be an integer);
    }
    
    my $parallelism = 1;
    my $m_factor    = $options{memory} . 'k';
    
    my @cmdparams = ( $options{password}, $salt, $options{iterations}, $m_factor, $parallelism, $options{length} );
    
    my $hash = '';
    
    if ($options{type} eq 'argon2id') {
        $hash = Crypt::Argon2::argon2id_pass(@cmdparams);
        unless(Crypt::Argon2::argon2id_verify($hash, $options{password})) {
            die 'failed to verify created hash';
        }
    } elsif($options{type} eq 'argon2i') {
        $hash = Crypt::Argon2::argon2i_pass(@cmdparams);
        unless(Crypt::Argon2::argon2i_verify($hash, $options{password})) {
            die 'failed to verify created hash';
        }
    } elsif($options{type} eq 'argon2d') {
        $hash = Crypt::Argon2::argon2d_pass(@cmdparams);
        unless(Crypt::Argon2::argon2d_verify($hash, $options{password})) {
            die 'failed to verify created hash';
        }
    }
    
    return $hash;
}

sub create_pbkdf2_password_hash {
    my($self, %options) = @_;
    $options{password} ||= '';
    $options{length} ||= 256;
    $options{iterations} ||= 600000;
    $options{function} ||= 'SHA256';
    
    my $funcmap = {
        'SHA1'   => { number => 1, class => 'HMACSHA1', size => 0 },
        'SHA224' => { number => 2, class => 'HMACSHA2', size => 224 },
        'SHA256' => { number => 3, class => 'HMACSHA2', size => 256 },
        'SHA384' => { number => 4, class => 'HMACSHA2', size => 384 },
        'SHA512' => { number => 5, class => 'HMACSHA2', size => 512 },
    };
    
    unless($options{password}) {
        die 'you must provide a password';
    }
    
    unless(exists($funcmap->{$options{function}})) {
        my @allowedoptions = ( sort keys %$funcmap );
        my $msg = qq('$options{function}' is not a valid function. Valid functions are ) . join(', ', @allowedoptions);
        die $msg;
    }
    
    unless($options{length}
       && $options{length} =~ /^[1-9][0-9]*$/
       ) {
        die qq(Invalid length "$options{length}". Must be an integer);
    }
    
    if ( $options{length} % 8 ) {
        die qq(A length of '$options{length}' bits cannot be encoded as bytes. Use a multiple of 8 ( 128, 256, 384, 512 etc) );
    }
    
    unless($options{iterations}
       && $options{iterations} =~ /^[1-9][0-9]*$/
       ) {
        die qq(Invalid iterations "$options{iterations}". Must be an integer);
    }
        
    my $salt = Crypt::URandom::urandom(128);
    
    my $base64salt = MIME::Base64::encode_base64($salt, '');
    
    my $mappedfunc = $funcmap->{$options{function}};
    
    my $bytelen = int($options{length} / 8);
    
    my %hasherparams = (
        'hash_class' =>  $mappedfunc->{class},
        'iterations' =>  $options{iterations},
        'output_len' =>  $bytelen,
        'salt_len'   =>  128,
        'encoding'   =>  'crypt',
    );
    
    if ($mappedfunc->{size}) {
        $hasherparams{hash_args} = { 'sha_size' => $mappedfunc->{size} };
    }
    
    my $hasher = Crypt::PBKDF2->new(%hasherparams);
    
    my $basehash = $hasher->PBKDF2_base64($salt, $options{password});
    
    my $keynum = $options{iterations} << 32;
    $keynum |= $options{length}; 
    
    my $hash = sprintf('$%s$%s$%s$%s',
        $mappedfunc->{number}, $keynum, $base64salt, $basehash
    );
    
    ## and validate
        
    my $generated;
    if ($mappedfunc->{class} eq 'HMACSHA1' ) {
        $generated = sprintf('$PBKDF2$HMACSHA1:%s:%s$%s', $options{iterations}, $base64salt, $basehash );
    } else {
        $generated = sprintf('$PBKDF2$HMACSHA2{%s}:%s:%s$%s', $mappedfunc->{size}, $options{iterations}, $base64salt, $basehash );
    }
    
    unless($hasher->validate($generated, $options{password})) {
        die 'failed to verify created hash';
    }
        
    return $hash;
    
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenSearch::Client::Hash - A utility to create password hashes

=head1 VERSION

version 3.007010

=head1 SYNOPSYS

    use OpenSearch::Client::Hash;
    my $pwdhasher = OpenSearch::Client::Hash->new;
    my $hash1 = $pwdhasher->create_bcrypt_password_hash( password => 'my plaintext password');
    my $hash2 = $pwdhasher->create_argon2_password_hash( password => 'my plaintext password');
    my $hash3 = $pwdhasher->create_pbkdf2_password_hash( password => 'my plaintext password');
    
    # store $hash1
    # $hash1 == something like $2y$12$KCHnaCykMhrXNkfpPlDmRejRYAd2rhixnWgcpICQyTEc8HI.0G8Ca
    
    # later create users using stored hashed passwords
    
    my $cli = OpenSearch::Client->new( .... );
    my $result = $cli->security->patch_users(
        body => [
            {
                op    => 'add',
                path  => '/myuserone',
                value => {
                    description => 'Read only query user',
                    hash        => '$2y$12$KCHnaCykMhrXNkfpPlDmRejRYAd2rhixnWgcpICQyTEc8HI.0G8Ca'
                }
            },
            {
                op    => 'add',
                path  => '/myusertwo',
                value => {
                    description => 'Indexing user',
                    hash        => '$2y$12$ak6pPjW3aEbVaU7FX03HLuGWO0K5oNa3PRvUE.A6six2vdvq0uTue'
                }
            },
        ]
    );
    
=head1 DESCRIPTION

Allows creation of C<BCrypt>, C<Argon2> and C<PBKDF2> password hashes that can be stored for later use in user creation.

These are the same types of hash produced by C<plugins/opensearch-security/tools/hash.sh -p E<lt>new-passwordE<gt>>.


=head1 METHODS

=head2 create_bcrypt_password_hash

Create a C<BCrypt> password hash from a plain text password.

B<You cannot use hashes produced by this method> if your C<plugins.security.password.hashing.algorithm> is not the default C<BCrypt>

    use OpenSearch::Client::Hash;
    my $ph = OpenSearch::Client::Hash->new;
    
    my $hash1 = $ph->create_bcrypt_password_hash( password => 'my plaintext password' );
    
    my $hash2 = $ph->create_bcrypt_password_hash(
        password => 'my other plaintext password',
        type     => '2y',
        rounds   => 12
    );


=over

=item C<password>

Required. The plaintext password to hash.

Note that in C<BCrypt> passwords may only contain 72 characters and may not contain any null-byte.

=item C<type>

Optional. Default is '2y'. Allowed values are '2y', '2a' and '2b'.

Specifies the minor version of the C<BCrypt> algorithm to use for hashing.

B<Do not set this option> unless your C<plugins.security.password.hashing.bcrypt.minor> setting is not the default C<Y> when you must match it with C<2a> for C<A> and C<2b> for C<B>.

=item C<rounds>

Optional. Default is 12.

Specifies the number of rounds to use for password hashing with C<BCrypt>. Valid values are between 4 and 31, inclusive.

B<Do not set this option> unless your C<plugins.security.password.hashing.bcrypt.rounds> setting is something other than 12 when you must match it here.

=back

=head2 create_argon2_password_hash

Create an C<Argon2> password hash from a plain text password.

B<You cannot use hashes produced by this method unless :>

=over

=item *

your C<plugins.security.password.hashing.algorithm> is C<Argon2>

=item *

your C<plugins.security.password.hashing.argon2.version> is the default C<19>

=back

    use OpenSearch::Client::Hash;
    my $ph = OpenSearch::Client::Hash->new;
    
    my $hash1 = $ph->create_argon2_password_hash( password => 'my plaintext password' );
    
    my $hash2 = $ph->create_argon2_password_hash(
        password   => 'my other plaintext password',
        type       => 'argon2id',
        length     => 32,
        iterations => 3,
        memory     => 65536,
    );

=over

=item C<password>

Required. The plaintext password to hash.

=item C<type>

Optional. Default is 'argon2id'. Allowed values are 'argon2id', 'argon2i' and 'argon2d'.

B<Do not set this option> unless your C<plugins.security.password.hashing.argon2.type> setting is not the default C<Argon2id> when you must match it here.

=item C<length>

Optional. Desired length of the final derived key. Default is 32.

B<Do not set this option> unless your C<plugins.security.password.hashing.argon2.length> setting is not the default C<32> when you must match it here.

=item C<iterations>

Optional. Number of times the pseudo-random function is applied to the password. Default is 3.

B<Do not set this option> unless your C<plugins.security.password.hashing.argon2.iterations> setting is not the default  C<3> when you must match it here.

=item C<memory>

Optional. Amount of memory to use for hashing in KiB. Default is 65536.

B<Do not set this option> unless your C<plugins.security.password.hashing.argon2.memory> setting is not the default C<65536> when you must match it here.

=back

=head2 create_pbkdf2_password_hash

Create a C<PBKDF2> password hash from a plain text password.

B<You cannot use hashes produced by this method> unless your C<plugins.security.password.hashing.algorithm> is C<PBKDF2>

    use OpenSearch::Client::Hash;
    my $ph = OpenSearch::Client::Hash->new;
    
    my $hash1 = $ph->create_pbkdf2_password_hash( password => 'my plaintext password' );
    
    my $hash2 = $ph->create_pbkdf2_password_hash(
        password   => 'my other plaintext password',
        function   => 'SHA256',
        length     => 256,
        iterations => 600000,
    );

=over

=item C<password>

Required. The plaintext password to hash.

=item C<function>

Optional. Default is 'SHA256'. Allowed values are 'SHA1', 'SHA224', 'SHA256', 'SHA384' and 'SHA512'.

B<Do not set this option> unless your C<plugins.security.password.hashing.pbkdf2.function> setting is not the default C<SHA256> when you must match it here.

=item C<length>

Optional. Desired length of the final derived key. Default is 256.

B<Do not set this option> unless your C<plugins.security.password.hashing.pbkdf2.length> setting is not the default C<256> when you must match it here.

=item C<iterations>

Optional. Number of times the pseudo-random function is applied to the password. Default is 600000.

B<Do not set this option> unless your C<plugins.security.password.hashing.pbkdf2.iterations> setting is not the default  C<600000> when you must match it here.

=back

=head1 MANUAL

Documentation index L<OpenSearch::Client::Manual>

=head1 AUTHOR

Mark Dootson E<lt>mdootson@cpan.orgE<gt> ( current maintainer )

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 by Mark Dootson

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut

