###########################################
package Proc::Info::Environment;
###########################################
use strict;
use warnings;

our $VERSION = "0.01";

our %OS_MAP = (
    "linux" => "Linux",
);

###########################################
sub new {
###########################################
    my($class, %options) = @_;

    my $self = {
        %options,
    };

    my $os = $OS_MAP{ $^O };

    if(! defined $os ) {
        die "OS $^O not supported";
    }

    my $subclass = "Proc::Info::Environment::$os";
    eval "require $subclass";

    bless $self, $subclass;

    return $self;
}

###########################################
sub os_not_supported_error_message {
###########################################
    return "OS $^O not supported (only " .
           join(', ', sort keys %OS_MAP) .
           " so far)";
}

###########################################
sub os_supported {
###########################################
    if(exists $OS_MAP{ $^O } ) {
        return 1;
    }

    return 0;
}

###########################################
sub error {
###########################################
    my($self, $error) = @_;

    if(defined $error) {
        $self->{error} = $error;
    }

    return $self->{error};
}

1;

__END__

=head1 NAME

Proc::Info::Environment - Read Environment Variables of any Process

=head1 SYNOPSIS

    use Proc::Info::Environment;
    my $proc_info = Proc::Info::Environment->new();

    my $env = $proc_info->env( $pid );

    print "\$PATH of process $pid is $env->{PATH}\n";

=head1 DESCRIPTION

Proc::Info::Environment retrieves the settings of environment variables
in arbitrary running processes of the operating system.

For example,

    use Proc::Info::Environment;
    my $proc_env = Proc::Info::Environment->new();
    my $env = $proc_env->env( 123 );

will retrieve the environment settings of the process with the pid 123 
and (if this process exists and is readable by the user) return them as a 
hash reference in $env. 

As an illustrative (but not very useful) example, retrieving

    my $env = $proc_env->env( $$ );

will return a reference to a hash similar to C<%ENV>, which contains the
environment variables of the current process.

Reading other processes' environment variables is only possible 
if the operating system (a) supports a method to do this and (b)
the user of the currently running process is either root, or has the 
same uid as the process whose variables it wants to read.

Proc::Info::Environment is currently supported only for specific Unix
systems. On Linux, it will use the procfs file system mounted under /proc
to get the information needed. It will read the file /proc/xxx/environ, 
where xxx is the pid of the target process.

To verify if Proc::Info::Environment supports your operating system, 
run Proc::Info::Environment::os_supported(), which returns a true value
if it is supported. If the OS is unsupported, the new() constructor will
die() with an error message listing all currently supported operating 
systems.

The module's architecture allows for easy support of other systems, if
you want support for one and know how the information is provided,
drop me an email.

=head1 LEGALESE

Copyright 2010 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2010, Mike Schilli <cpan@perlmeister.com>
