use ExtUtils::MakeMaker;

my $verbose = 0;
my $interactive = 0;  # -t STDIN and -t STDOUT;

my $services_file = 'services.yml';
my $services;

eval 'use Getopt::Long';
if ($@) {
    if (@ARGV) {
        print STDERR <<'EOS';
Getopt::Long isn't available, which means I can't interpret the command-line
arguments you've specified.  Please install Getopt::Long or try again without
any arguments.
EOS
        exit 2;
    }
} else {
    my $result = GetOptions(
        'verbose'   => \$verbose,
        'interact!' => \$interactive,
        'help'      => sub {
            print STDERR <<'EOS';
Valid arguments are --verbose, --no-interact, and anything allowed by
ExtUtils::MakeMaker.
EOS
            exit 0;
        }
    );
}

if ($interactive and not -t STDIN && -t STDOUT) {
    print STDERR <<'EOS';
WARNING: Running Makefile.PL interactively outside of a tty!

EOS
}

unless (eval "require YAML") {
    if ($verbose) {
        print STDERR <<'EOS';
While attempting to create a Makefile for this distribution, I noticed that
the Perl module 'YAML' is not installed.  In order to create a meaningful
`make test' capability, YAML must be installed.  ***YAML is NOT required for
actual use of Search::Z3950, only for testing.***

Because testing is important, however, you must specify whether or not it's
OK to generate a Makefile with no meaningful `make test' capability.

EOS
    } else {
        print STDERR <<'EOS';
Can't generate a Makefile with testing capability unless YAML is installed.
EOS
    }
    exit 2 unless $interactive;
    get_permission("generate a Makefile with no testing capability");
}

unless (-f $services_file) {
    print STDERR "The file '$services_file' is required for testing, but is missing.\n\n";
    exit 2;
}
my $services = eval { YAML::LoadFile($services_file) };

if ($@) {
    print STDERR <<"EOS";
The file '$services_file' does not contain valid YAML.  This may mean that
your copy of this distribution has been corrupted.
EOS
    exit 2;
}

my $service = $services->[0];  # Default

if ($interactive) {
    print <<'EOS';
In order to test the functionality of Search::Z3950, I'll need a live Z39.50
service to test against.  If none of the services listed is suitable, edit the
file `services.yml' in this distribution to include the service you prefer.  The
file is in YAML format; see http://www.yaml.org/ if you don't grok YAML.

If you'd rather skip testing altogether, enter 'n' instead of a number.  In any
case, your choice here will only affect the Makefile that's generated, nothing
else.  You can always run tests individually.

WARNING: If you don't use the Library of Congress, your tests will probably fail
-- I got lazy when writing the file `services.yml' and used the same canned
searches for every Z39.50 service.

EOS
    print "Press RETURN to choose from the list of Z39.50 services, or ^D to cancel...";
    system "stty -echo";
    {
        my $foo = <STDIN>;
        unless (defined $foo) {
            system "stty echo";
            print "\nCancelled -- no Makefile generated.\n";
            exit 0;
        }
        chomp $foo;
        print "\n";
        system "stty echo";
        print "\n";
    }
    system('clear');
    print "These are the Z29.50 services available for testing:\n\n";
    my $i = 1;
    foreach (@$services) {
        print " [$i] $_->{'name'} ($_->{'databaseName'}) - $_->{'location'}\n";
        $i++;
    }
    while (1) {
        # Running interactively
        print "\nPlease choose a service on which tests will be run, type ^D to cancel,\n",
            "or enter 'n' to omit live testing from the generated Makefile: [1] ";
        my $k = <STDIN>;
        unless (defined $k) {
            print "\nCancelled -- no Makefile generated.\n";
            exit 1;
        }
        chomp $k;
        if ($k eq '') {
            last;
        } elsif ($k eq 'n') {
            undef $service;
            last;
        } elsif ($k >= 1 and $k <= scalar @$services) {
            $service = $services->[$k-1];
            last;
        } else {
            print "Huh???  Try again...\n";
        }
    }
}

my @test_files_to_run = qw(t/pod.t);

push @test_files_to_run, "t/$service->{abbrev}.t"
    if defined $service;

WriteMakefile(
    'NAME'         => 'Search::Z3950',
    'VERSION_FROM' => 'lib/Search/Z3950.pm',
    'PREREQ_PM'    => {
                          # Some of these versions may be too low
                          'YAML' => 0,
                          'Net::Z3950' => 0,
                          'Net::Z3950::Manager' => 0,
                          'MARC::Record' => 0,
                      },
    'test' => {
        'TESTS' => join(' ', @test_files_to_run),
    }
);

unless ($interactive) {
    print STDERR <<'EOS';
A Makefile has been generated that uses the defaults for testing.  This means
that running `make test' will result in a connection with the Z39.50 server at
the Library of Congress in the U.S.A.  To specify another server interactively,
run `perl Makefile.PL --interact' instead.
EOS
}


sub get_permission {
    print "Is it OK to $clause? [n] ";
    my $answer = <STDIN>;
    exit 2 unless defined $answer and $answer =~ /^y/i;
}

sub cant_interact {
    my ($msg) = @_;
    if ($verbose) {
        my $apology = <<'EOS';
You appear to be using an automated tool such as cpan or cpanp to build this
distribution, so it's not possible for me to ask you to specify your preference
interactively.  Instead, I'll assume you want to use the default settings.
EOS
        $apology .= "\n$msg\n" if defined $msg && $msg ne '';
        print STDERR $apology;
    } else {
        print STDERR <<'EOS';
Generating Makefile requires user interaction; run `make verbose' for details.
EOS
    }
    exit 2;
}

