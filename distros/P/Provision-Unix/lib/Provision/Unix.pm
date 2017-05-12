package Provision::Unix;
# ABSTRACT: provision hosting accounts on unix systems

use strict;
use warnings;

our $VERSION = '1.07';

use Config::Tiny;
use Cwd;
use Data::Dumper;
use English qw( -no_match_vars );
use Params::Validate qw(:all);
use Scalar::Util qw( openhandle );

sub new {
    my $class = shift;
    my %p     = validate(
        @_,
        {   file  => { type => SCALAR, optional => 1, },
            fatal => { type => SCALAR, optional => 1, default => 1 },
            debug => { type => SCALAR, optional => 1, default => 1 },
        }
    );

    my $file = $p{file} || 'provision.conf';
    my $debug = $p{debug};
    my $ts = get_datetime_from_epoch();
    my $self = {
        debug  => $debug,
        fatal  => $p{fatal},
        config => undef,
        errors => [],  # errors get appended here
        audit  => [    # status messages accumulate here
                "launched at $ts",
                $class . sprintf( " loaded by %s, %s, %s", caller ),
            ], 
        last_audit => 0,
        last_error => 0,
        util   => undef,
    };

    bless( $self, $class );
    my $config = $self->find_config( file => $file, debug => $debug, fatal => 0 );
    if ( $config ) {
        $self->{config} = Config::Tiny->read( $config );
    }
    else {
        warn "could not find $file. Installing it in your local etc directory.\n";
    };

    return $self;
}

sub audit {
    my $self = shift;
    my $mess = shift;

    if ($mess) {
        push @{ $self->{audit} }, $mess;
        print STDERR "$mess\n" if $self->{debug};
    }

    return $self->{audit};
}

sub dump_audit {
    my $self = shift;
    my $last_line = $self->{last_audit};

    # we already dumped everything
    return if $last_line == scalar @{ $self->{audit} };

    print STDERR "\n\t\t\tAudit History Report \n\n";
    my $i = 0;
    foreach ( @{ $self->{audit} } ) {
        $i++;
        next if $i < $last_line;
        print STDERR "\t$_\n";
    };
    $self->{last_audit} = $i;
    return;
};

sub dump_errors {
    my $self = shift;
    my $last_line = $self->{last_error};

    return if $last_line == scalar @{ $self->{errors} }; # everything dumped

    print STDERR "\n\t\t\t Error History Report \n\n";
    my $i = 0;
    foreach ( @{ $self->{errors} } ) {
        $i++;
        next if $i < $last_line;
        print STDERR "ERROR: '$_->{errmsg}' \t\t at $_->{errloc}\n";
    };
    print "\n";
    $self->{last_error} = $i;
    return;
};

sub error {
    my $self = shift;
    my $message = shift;
    my %p = validate(
        @_,
        {   'location' => { type => SCALAR,  optional => 1, },
            'fatal'    => { type => BOOLEAN, optional => 1, default => 1 },
            'debug'    => { type => BOOLEAN, optional => 1, default => 1 },
        },
    );

    my $debug = $p{debug};
    my $fatal = $p{fatal};
    my $location = $p{location};

    if ( $message ) {
        my @caller = caller;
        push @{ $self->{audit} }, $message;

        # append message to $self->error stack
        push @{ $self->{errors} },
            {
            errmsg => $message,
            errloc => $location || join( ", ", $caller[0], $caller[2] ),
            };
    }
    else {
        $message = $self->get_last_error();
    }

    # print audit and error results to stderr
    if ( $debug ) {
        $self->dump_audit();
        $self->dump_errors();
    }

    if ( $fatal ) {
        if ( ! $debug ) {
            $self->dump_audit();  # dump if err is fatal and debug is not set
            $self->dump_errors();
        };
        die "FATAL ERROR";
    };
    return;
}

sub find_config {
    my $self = shift;
    my %p = validate(
        @_,
        {   'file'   => { type => SCALAR, },
            'etcdir' => { type => SCALAR | UNDEF, optional => 1, },
            'fatal'  => { type => SCALAR, optional => 1, default => 1 },
            'debug'  => { type => SCALAR, optional => 1, default => 1 },
        }
    );

    my $file = $p{file};
    my $etcdir = $p{etcdir};
    my $fatal = $self->{fatal} = $p{fatal};
    my $debug = $self->{debug} = $p{debug};

    $self->audit("searching for config $file");

    return $self->_find_readable( $file, $etcdir ) if $etcdir;

    my @etc_dirs = qw{ /opt/local/etc /usr/local/etc /etc etc };

    my $working_directory = cwd;
    push @etc_dirs, $working_directory;

    my $r = $self->_find_readable( $file, @etc_dirs );
    return $r if $r;

    # try $file-dist in the working dir
    if ( -r "./$file-dist" ) {
        $self->audit("\tfound $file-dist in ./");
        return "$working_directory/$file-dist";
    }

    return $self->error( "could not find $file",
        fatal   => $fatal,
        debug   => $debug,
    );
}

sub get_datetime_from_epoch {
    my ( $self, $time ) = @_;
    my @lt = localtime( $time || time() );
    return sprintf '%04d-%02d-%02d %02d:%02d:%02d', $lt[5] + 1900, $lt[4] + 1,
           $lt[3], $lt[2], $lt[1], $lt[0];
}

sub get_dns {
    my $self = shift;
    return $self->{dns} if ref $self->{dns};
    require Provision::Unix::DNS;
    $self->{dns} = Provision::Unix::DNS->new( 
            prov  => $self, 
            debug => $self->{debug},
            );
    return $self->{dns};
};

sub get_debug {
    my ($self, $debug) = @_;
    return $debug if defined $debug;
    return $self->{debug};
};  

sub get_errors {
    my $self = shift;
    return $self->{errors};
}

sub get_fatal {
    my ($self, $fatal) = @_;
    return $fatal if defined $fatal;
    return $self->{fatal};
};

sub get_last_error {
    my $self = shift;
    return $self->{errors}[-1]->{errmsg} if scalar @{ $self->{errors} };
    return;
}

sub get_util {
    my $self = shift;
    return $self->{util} if ref $self->{util};
    require Provision::Unix::Utility;
    $self->{util} = Provision::Unix::Utility->new( 
            'log' => $self, 
            debug => $self->{debug},
            );
    return $self->{util};
};

sub get_version {
    print "Provision::Unix version $VERSION\n";
    return $VERSION;
};

sub progress {
    my $self = shift;
    my %p = validate(
        @_,
        {   'num'  => { type => SCALAR },
            'desc' => { type => SCALAR, optional => 1 },
            'err'  => { type => SCALAR, optional => 1 },
        },
    );

    my $num  = $p{num};
    my $desc = $p{desc};
    my $err  = $p{err};

    my $msg_length = length $desc || 0;
    my $to_print   = 10;
    my $max_print  = 70 - $msg_length;

    # if err, print and return
    if ( $err ) {
        if ( length( $err ) == 1 ) {
            foreach my $error ( @{ $self->{errors} } ) {
                print {*STDERR} "\n$error->{errloc}\t$error->{errmsg}\n";
            }
        }
        else {
            print {*STDERR} "\n\t$err\n";
        }
        return $self->error( $err, fatal => 0, debug => 0 );
    }

    if ( $msg_length > 54 ) {
        die "max message length is 55 chars\n";
    }

    print {*STDERR} "\r[";
    foreach ( 1 .. $num ) {
        print {*STDERR} "=";
        $to_print--;
        $max_print--;
    }

    while ($to_print) {
        print {*STDERR} ".";
        $to_print--;
        $max_print--;
    }

    print {*STDERR} "] $desc";
    while ($max_print) {
        print {*STDERR} " ";
        $max_print--;
    }

    if ( $num == 10 ) { print {*STDERR} "\n" }

    return 1;
}

sub _find_readable {
    my $self = shift;
    my $file = shift;
    my $dir  = shift or return;    # breaks recursion at end of @_

    #$self->audit("looking for $file in $dir") if $self->{debug};

    if ( -r "$dir/$file" ) {
        no warnings;
        $self->audit("\tfound in $dir");
        return "$dir/$file";       # we have succeeded
    }

    if ( -d $dir ) {

        # warn about directories we don't have read access to
        if ( !-r $dir ) {
            $self->error( "$dir is not readable", fatal => 0 );
        }
        else {

            # warn about files that exist but aren't readable
            if ( -e "$dir/$file" ) {
                $self->error( "$dir/$file is not readable",
                    fatal   => 0
                );
            }
        }
    }

    return $self->_find_readable( $file, @_ );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Provision::Unix - provision hosting accounts on unix systems

=head1 VERSION

version 1.08

=head1 SYNOPSIS

    use Provision::Unix;

    my $foo = Provision::Unix->new();
    ...

    prov_dns     --action=create --zone=example.com
    prov_user    --action=create --username=matt --pass='neat0app!'
    prov_virtual --action=create --name=testVPS
    prov_web     --action=create --vhost=www.example.com

=head1 DESCRIPTION

Provision::Unix is a suite of applications to create, modify, and destroy 
accounts on Unix systems in a reliable and consistent manner.

Command line scripts are provided for humans to perform provisioning actions 
by hand. See the documentation included in each of the prov_* scripts. 
Programmers and automated systems should be loading the Provision::Unix 
modules and calling the methods directly. The API provided by each method is
stable and only changes when additional parameters are added.

The types of accounts that can be provisioned are organized by class with each
class including a standard set of methods. All classes support at least
create and destroy. Additional common methods are: modify, enable, and disable.

Each class (DNS, User, VirtualOS, Web) has a general module that 
contains the logic for selecting and dispatching requests to sub-classes which
are implementation specific. Selecting and dispatching is done based on the
environment and configuration file settings at run time. 

For example, Provision::Unix::DNS contains all the general logic for dns
operations (create a zone, record, alias, etc). Subclasses contain 
specific information such as how to provision a DNS record for nictool,
BIND, or tinydns.

Not all specific modules are fully implemented yet. 
Ex: Provision::Unix::VirtualOS::Linux::Xen is fully implemented, 
where Provision::Unix::VirtualOS::FreeBSD::Jail is not.

Browse the perl modules to see which modules are available.

=head1 NAME

Provision::Unix - provision accounts on unix systems

=head1 Programming Conventions

All functions/methods adhere to the following:

=head2 Exception Handling

Errors throw exceptions. This can be overridden by calling the method with fatal=0. If you do so, you must write code to handle the errors. 

This call will throw an exception since it cannot find the file. 

  $util->file_read('/etc/oopsie_a_typo');

Setting fatal will cause it to return undef instead:

  $util->file_read('/etc/oopsie_a_typo', fatal=>0);

=head2 Warnings and Messages

Methods have an optional debug parameter that defaults to enabled. Often, that means methods spit out more messages than you want. Supress them by setting debug=0.

Supressed messages are not lost! All error messages are stored in $prov->errors and all status messages are in $prov->audit. You can dump those arrays any time to to inspect the status or error messages. A handy way to do so is:

  $prov->error('test breakpoint');

That will dump the contents of $prov->audit and $prov->errors and then terminate your program. If you want your program to continue after calling $prov->error, just set fatal=0. 

  $prov->error('test breakpoint', fatal => 0);

=head1 FUNCTIONS

=head2 new

Creates and returns a new Provision::Unix object. 

As part of initialization, new() finds and reads in provision.conf from /[opt/usr]/local/etc, /etc, and the current working directory. 

=head2 audit

audit is a method that appends messages to an internal audit log. Rather than spewing messages to stdout or stderr, they are stored as a list. The list can can be inspected by calling $prov->audit or it can be printed by calling $prov->dump_audit.

  $prov->audit("knob fitzerbaum twiddled to setting 5");

If the debug option is set ($prov->{debug}), audit messages are also printed to stderr. 

returns an arrayref of audit messages.

=head2 dump_audit

dump_audit prints out any audit/status messages that have accumulated since the last time dump_audit was called. It is particularly useful for RPC agents that poll for status updates during long running processes.

=head2 dump_error

Same as dump_audit, except dumps the error history report.

=head2 error

Whenever a method runs into an unexpected condition, it should call $prov->error with a human intelligible error message. It should also specify whether the error is merely a warning or a fatal condition. Errors are considered fatal unless otherwise specified.

Examples:

 $prov->error( 'could not write to file /etc/passwd' );

This error is fatal and will throw an exception, after printing the contents of the audit log and the last error message to stderr. 

A very helpful thing to do is call error with a location as well:

 $prov->error( 'could not write to file /etc/passwd',
    location => join( ", ", caller ),
 );

Doing so will tell reveal in the error log exactly where the error was encountered as well as who called the method. The latter is more likely where the error exists, making location a very beneficial parameter.

=head2 find_config

This sub is used to determine which configuration file to use. The general logic is as follows:

  If the etc dir and file name are provided and the file exists, use it.

If that fails, then go prowling around the drive and look in all the usual places, in order of preference:

  /opt/local/etc/
  /usr/local/etc/
  /etc

Finally, if none of those work, then check the working directory for the named .conf file, or a .conf-dist. 

Example:
  my $conf = $util->find_config (
      file   => 'example.conf', 
      etcdir => '/usr/local/etc',
    )

 arguments required:
   file - the .conf file to read in

 arguments optional:
   etcdir - the etc directory to prefer
   debug
   fatal

 result:
   0 - failure
   the path to $file  

=head2 get_last_error

prints and returns the last error encountered.

=head1 BUGS

Please report any bugs or feature requests to C<bug-unix-provision at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Provision-Unix>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Provision::Unix

=head1 AUTHOR

Matt Simerson <msimerson@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by The Network People, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
