# NAME

RPM::Query - Perl object overlay of the RPM query command

# SYNOPSIS

    use RPM::Query;
    my $rpm      = RPM::Query->new;
    my $pkg      = $rpm->query('perl');
    my $requires = $pkg->requires;
    foreach my $capability (@$requires) {
      printf "Capability: %s\n", $capability->name;
      my $whatprovides = $capability->whatprovides;
      foreach my $package (@$whatprovides) { #could be zero or more but normally one
        printf "  Package: %s\n", $package->package_name;
      }
    }

# DESCRIPTION

# METHODS

## query

Returns an the last object of the passed in package name or undef if not installed.

    my $package_obj = $rpm->query("my_package") or die("my_package is not installed");
    my $long_name   = $package_obj->package_name;

Wrapper around

    $ rpm --query | tail -n 1
    perl-5.16.3-299.el7_9.x86_64

## query\_list

    my $packages_aref = $rpm->query("kernel");

Wrapper around

    $ rpm -q kernel
    kernel-3.10.0-1160.76.1.el7.x86_64
    kernel-3.10.0-1160.80.1.el7.x86_64
    kernel-3.10.0-1160.81.1.el7.x86_64
    kernel-3.10.0-1160.83.1.el7.x86_64
    kernel-3.10.0-1160.88.1.el7.x86_64

## details

Returns a HASH data structure of the details of the passed in package name.

    my $hash    = $rpm->details("my_package");
    my $version = $hash->{'version'};

Wrapper around

    $ rpm --query perl --queryformat '%{name} %{version} ...'
    perl 5.16.3 ...

## verify

Returns true if verify is clean

Wrapper around

    $ rpm --verify perl && echo 1 || echo 0
    1

## whatprovides

Returns a list of packages that provides the capability

    my $package = $rpm->whatprovides('perl(strict)'); #isa ARRAY of RPM::Query::Package

Wrapper around

    $ rpm --query --whatprovides 'perl(strict)'
    perl-5.16.3-299.el7_9.x86_64

## provides

Returns a list of capabilities that the installed package provides

    my $capabilities = $rpm->provides('perl'); #isa ARRAY of RPM::Query::Capability objects

Wrapper around

    $ rpm --query --provides 'perl'
    perl = 4:5.16.3-299.el7_9
    perl(AutoLoader) = 5.72
    perl(B) = 1.35
    perl(B::Section)
    ...

## requires

Returns a list of capabilities that the package requires

    my $capabilities = $rpm->requires('perl'); #isa ARRAY of RPM::Query::Capability objects

Wrapper around

    $ rpm --query --requires perl
    /usr/bin/perl
    libpthread.so.0()(64bit)
    perl >= 0:5.000
    ...

## whatrequires

Returns a list of packages that this capability requires

    my $capabilities = $rpm->whatrequires('perl'); #isa ARRAY of RPM::Query::Package objects

Wrapper around

    $ rpm --query --whatrequires perl
    perl-podlators-2.5.1-3.el7.noarch
    perl-Pod-Perldoc-3.20-4.el7.noarch
    perl-Text-ParseWords-3.29-4.el7.noarch
    perl-Pod-Usage-1.63-3.el7.noarch
    perl-threads-shared-1.43-6.el7.x86_64
    perl-Filter-1.49-3.el7.x86_64
    perl-Exporter-5.68-3.el7.noarch
    ...

# SEE ALSO

# AUTHOR

Michael R. Davis

# COPYRIGHT AND LICENSE

MIT License

Copyright (c) 2023 Michael R. Davis
