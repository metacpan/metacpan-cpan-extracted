use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use RPM::CPAN::Repository;

my $tmpdir = tempdir( CLEANUP => 1 );
my $tmpfile = File::Spec->catfile( $tmpdir, 'mediaalpha-public.repo' );

my $CORRECT_CONTENT = <<'END';
[mediaalpha-public-perl]
name     = mediaalpha-public-perl-5.42.2
baseurl  = https://mediaalpha-public-rpm-repo.s3.amazonaws.com/perl/5.42.2/$basearch
gpgcheck = 1
gpgkey   = https://mediaalpha-public-rpm-repo.s3.amazonaws.com/RPM-GPG-KEY-mediaalpha
END

# --- check_if_repo_dir_exists ---

{
    my $missing = File::Spec->catdir( $tmpdir, 'nonexistent' );
    local $RPM::CPAN::Repository::REPO_FILE =
        File::Spec->catfile( $missing, 'test.repo' );
    ok( !eval { RPM::CPAN::Repository::check_if_repo_dir_exists(); 1 },
        'check_if_repo_dir_exists dies when dir is missing' );
    like( $@, qr/does not exist/, 'error mentions missing directory' );
}

{
    local $RPM::CPAN::Repository::REPO_FILE = $tmpfile;
    ok( eval { RPM::CPAN::Repository::check_if_repo_dir_exists(); 1 },
        'check_if_repo_dir_exists passes when dir exists' );
}

# --- add_the_public_ma_repo ---

{
    local $RPM::CPAN::Repository::REPO_FILE = $tmpfile;

    RPM::CPAN::Repository::add_the_public_ma_repo();

    ok( -f $tmpfile, 'add creates the repo file' );

    open( my $fh, '<', $tmpfile ) or die "Can't read temp file: $!";
    my $written = do { local $/; <$fh> };
    close($fh);
    is( $written, $CORRECT_CONTENT, 'add writes correct content' );
}

# --- check_the_public_ma_repo ---

{
    local $RPM::CPAN::Repository::REPO_FILE = $tmpfile;
    ok( eval { RPM::CPAN::Repository::check_the_public_ma_repo(); 1 },
        'check passes when content is correct' );
}

{
    open( my $fh, '>', $tmpfile ) or die "Can't write temp file: $!";
    print $fh "wrong content\n";
    close($fh);

    local $RPM::CPAN::Repository::REPO_FILE = $tmpfile;
    ok( !eval { RPM::CPAN::Repository::check_the_public_ma_repo(); 1 },
        'check dies when content differs' );
    like( $@, qr/differs/, 'error mentions content difference' );
}

{
    unlink $tmpfile;

    local $RPM::CPAN::Repository::REPO_FILE = $tmpfile;
    ok( !eval { RPM::CPAN::Repository::check_the_public_ma_repo(); 1 },
        'check dies when file is missing' );
    like( $@, qr/does not exist/, 'error mentions missing file' );
}

# --- remove_the_public_ma_repo ---

{
    open( my $fh, '>', $tmpfile ) or die "Can't write temp file: $!";
    print $fh $CORRECT_CONTENT;
    close($fh);

    local $RPM::CPAN::Repository::REPO_FILE = $tmpfile;
    ok( -f $tmpfile, 'repo file exists before remove' );
    RPM::CPAN::Repository::remove_the_public_ma_repo();
    ok( !-f $tmpfile, 'remove deletes the repo file' );
}

{
    local $RPM::CPAN::Repository::REPO_FILE = $tmpfile;
    ok( eval { RPM::CPAN::Repository::remove_the_public_ma_repo(); 1 },
        'remove is a no-op when file is already missing' );
}

done_testing();
