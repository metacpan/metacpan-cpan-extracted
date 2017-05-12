package MyTest::Mock::ConnectParams;
use Moose;
use Config;
extends 'Net::SSH::Mechanize::ConnectParams';

# From perlvar
my $secure_perl_path = $Config{perlpath};
if ($^O ne 'VMS') {
    $secure_perl_path .= $Config{_exe}
        unless $secure_perl_path =~ m/$Config{_exe}$/i;
}


# Construct an instance of this class, unless env var TEST_PASSWD is defined,
# in whcih case construct a Net::SSH::Mechanize::ConnectParams instance.
sub detect {
    my $class = shift;

    return $class->new(host => 'nowhere',
                       password => 'sekrit')
        unless $ENV{TEST_PASSWD} || $ENV{TEST_HOST};

    return Net::SSH::Mechanize::ConnectParams->new(
        host => $ENV{TEST_HOST} || 'localhost',
        $ENV{TEST_PASSWD}? 
            (password => $ENV{TEST_PASSWD}) : (),
    );
}

sub ssh_cmd {
    # Use $secure_perl_path so that tests on non-system perl builds
    # continue to use the same executable.  A belt-and-braces
    # approach, since in any case mock-ssh aims to be portable back to
    # fairly old versions of Perl.
    return ($secure_perl_path, "$FindBin::Bin/bin/mock-ssh");
};

__PACKAGE__->meta->make_immutable;
1;
