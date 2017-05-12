package Nagios::Clientstatus;
use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use Log::Log4perl;
use Exporter;

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION = '0.06';
    @ISA     = qw(Exporter);

    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
}

=head1 NAME

Nagios::Clientstatus - Framework for Nagios check-service programs

=head1 SYNOPSIS

    use Nagios::Clientstatus;
    # This is needed for logging
    use Log::Log4perl qw/:easy/;
    Log::Log4perl->easy_init($ERROR);
    my $logger = Log::Log4perl->get_logger;
    
    # Arguments to the program are:
    # --critical=40 --warning=35 --hostname=server1.zdf --sensor_nr=4
    my $version = "0.01";
    my $ncli    = Nagios::Clientstatus->new(
        help_subref    => \&help,
        version        => $version,
        # default is that the module checks commandline
        dont_check_commandline_args => 0,  # default
        mandatory_args => [ "hostname", "sensor_nr", "critical", "warning" ],
    );

    # ask only one time, because it's expensive
    my $temperature = &get_temperature_of_sensor(
        hostname  => $ncli->get_given_arg('hostname'),
        sensor_nr => $ncli->get_given_arg('sensor_nr'),
    );

    # Message for the user to read
    my $msg;
    my $status;

    # strange case
    if (   ( !defined $temperature )
        || ( defined $temperature && $temperature eq "" ) )
    {
        $status = "unknown";
        $msg    = "Could not get temperature from sensor";
    }
    else {

        # We got a temperature
        # worst case first
        if ( $temperature > $ncli->get_given_arg('critical') ) {
            $status = "critical";
        }
        elsif ( $temperature > $ncli->get_given_arg('warning') ) {
            $status = "warning";
        }
        else {
            $status = "ok";
        }
        $msg = sprintf "Temperature is %s degrees Celsius", $temperature;
    }
    printf "%s - %s", uc($status), $msg;
    exit $ncli->exitvalue($status);

    sub help {
        print "Usage:\n";
        print "$0 --critical=40 --warning=35"
          . " --hostname=server1.zdf --sensor_nr=4";

        # When supplying help you should exit, use class-method
        # because we don't have an object
        exit Nagios::Clientstatus::exitvalue( 'unknown' );
    }

    sub get_temperature_of_sensor {
        my(%args) = @_;
        print "You should supply something useful here.\n";
        printf "Hostname: %s, sensor: %s\n", 
            $args{hostname}, $args{sensor_nr};
        print "Please enter a temperature: ";
        my $temperature = <STDIN>;
        chomp $temperature;
        return $temperature;

    };


=head1 DESCRIPTION

Create a program to check the function of some service or device
for Nagios. This module helps you to check the mandatory and 
optional arguments. It helps you to send the right output so that 
Nagios can check wether the service works ok or not.

=head1 METHODS

=cut

=head2 new

Create the object. Immediately check commandline arguments which
are mandatory for every Nagios command.

Usage:

    my $ncli = Nagios::Clientstatus->new(
        help_subref => \&help,
        version => $version,
        dont_check_commandline_args => 0, # default
        # mandatory_args is optional, maybe you don't need any
        mandatory_args => [ 'url' ],
        # optional_args is optional, maybe you don't need any
        optional_args => [ 'carsize' ],
    );

=cut

sub new {
    my ( $class, %args ) = @_;
    my $new_object = bless(
        {
            help_subref                 => \&help_example,
            version                     => $args{version},
            mandatory_args              => [],
            # help, version, debug: but no arguments here
            # like --help=specialvalue, only --help
            optional_default_args       => [],
            # more optional values, all must have a value
            # like --carsize=medium
            optional_additional_args    => [],
            given_args                  => {},
            dont_check_commandline_args => 0,
        },
        ref($class) || $class
    );

    if ( exists $args{dont_check_commandline_args} ) {
        $new_object->{dont_check_commandline_args} =
          $args{dont_check_commandline_args};
    }

    # help_subref
    unless ( ( exists $args{help_subref} )
        && ( ref $args{help_subref} eq "CODE" ) )
    {
        print STDERR
          "Missing ref to help-subroutine. This sub could output this:\n";
        $new_object->help_example;
        my $msg =
          sprintf "Mandatory argument help_subref must point"
          . " to a help-subroutine, but it is a '%s'",
          ref( $args{help_subref} );
        die $msg;
    }
    $new_object->{help_subref} = $args{help_subref};

    # which optional args could be at the commandline?
    # The usual ones
    $new_object->{optional_default_args} = [ $new_object->_get_optional_default_args ];

    # The other one the user wants
    # These arguments must be supplied like this:
    # --carsize=medium, not valid: --carsize
    if (   ( exists $args{optional_args} )
        && ( ref $args{optional_args} eq "ARRAY" ) )
    {
        foreach my $optarg ( @{$args{optional_args}} ) {
            push @{$new_object->{optional_additional_args}}, $optarg;
        } 
    }

    # are there mandatory arguments?
    if (   ( exists $args{mandatory_args} )
        && ( ref $args{mandatory_args} eq "ARRAY" ) )
    {
        $new_object->_set_mandatory_args( @{ $args{mandatory_args} } );
    }

    # don't set mandatory args, sometimes it's critical when
    # the service does not run -> very simple
    # $new_object->_set_mandatory_args( "critical", "warning" );

    $new_object->_check_commandline_args;
    return $new_object;
}

sub _logger {
    return Log::Log4perl->get_logger('Nagios.Clientstatus');
}

sub _dont_check_commandline_args {

    # shall any commandline-arg be checked by Getopt::Long?
    shift->{dont_check_commandline_args};
}

#=head2_set_mandatory_args
#
#Remind arguments which user must supply when calling the program.
#Can be called several times.
#
#=cut

sub _set_mandatory_args {
    my ( $self, @args ) = @_;
    push @{ $self->{mandatory_args} }, @args;
}

#=head2 _get_mandatory_args
#
#Which args MUST be given to the programm? Each argument must have a value, too.
#
#=cut

sub _get_mandatory_args {
    my $self = shift;
    @{ $self->{mandatory_args} };
}

#=head2 _set_given_args
#
#Which arguments where given to the program?
#
#=cut

sub _set_given_args {
    my ( $self, $name, $value ) = @_;
    $self->{given_args}->{name} = $value;
}

=head2 get_given_arg

Object-creator can ask for the value of an argument
given to the program. This can be a mandatory or
an optional argument. Not given optional arguments
return undef.

When you create the object like this:

    my $ncli = Nagios::Clientstatus->new(
        help_subref => \&help,
        version => $version,
        mandatory_args => [ 'url' ],
        optional_args => [ 'carsize' ],
    );

If program is called: checkme --url=xx --carsize=medium

    # $value -> 'medium'
    $value = $nc->get_given_arg('carsize');
    
    # $value -> 'xx'
    $value = $nc->get_given_arg('url');

    # $value -> undef
    $value = $nc->get_given_arg('carpoolnotgiven');

=cut

sub get_given_arg {
    my ( $self, $name ) = @_;
    return exists $self->{given_args}->{$name}
      ? $self->{given_args}->{$name}
      : undef;
}

#=head2 _check_commandline_args
#
#There are arguments which must exist when calling a Nagios-checker.
#warning|critcal are mandatory, other mandatory were given by new.
#
#=cut

sub _check_commandline_args {
    my $self   = shift;
    my $logger = $self->_logger;

    my %getopt_long_arg;
    my %got_this_option;

    # shall any commandline-arg be checked by Getopt::Long?
    if ( $self->_dont_check_commandline_args ) {
        $logger->info("Do not check any commandline arguments");
        return;
    }

    # Build up the argument hash for Getopt::Long

    # Build the hash for Getopt::Long
    foreach ( $self->_get_optional_default_args ) {

        # Getopt::Long wants a ref to a scalar where value is stored in
        $getopt_long_arg{$_} = $got_this_option{$_};
    }

    # Maybe there are optional args supplied by new
    # Must be all like: --carsize=medium (with value)
    foreach ($self->_get_optional_additional_args) {
        $getopt_long_arg{"$_=s"} = $got_this_option{$_};
    }

    foreach ( $self->_get_mandatory_args ) {

        # Tell Getopt::Long that there must be an argument
        # Getopt::Long wants a ref to a scalar where value is stored in
        $getopt_long_arg{"$_=s"} = $got_this_option{$_};
    }

    # Unusual syntax for daily life in GetOptions
    # Look in manpage of Getopt::Long for this:
    #     Storing option values in a hash
    # All given options are stored in hash given as first argument
    GetOptions(
        \%got_this_option,

        # all possible options are here:
        keys %getopt_long_arg,
    );

    # Now all arguments given to the program are in %got_this_option

    # Do mandatory args exist?
    my @mand_forgotten;
    foreach ( $self->_get_mandatory_args ) {
        unless ( exists $got_this_option{$_} ) {
            push @mand_forgotten, $_;
        }
    }
    if ( scalar @mand_forgotten > 0 ) {
        $logger->debug('%getopt_long_arg was: ');
        $logger->debug( Dumper( \%getopt_long_arg ) );
        $logger->debug('%got_this_option was: ');
        $logger->debug( Dumper( \%got_this_option ) );

        printf STDERR "Mandatory arguments not given: %s\n",
          join( ", ", @mand_forgotten );
        $self->{help_subref}->();
        $self->_exit;
    }

    # all arguments where checked, now put them into given_args
    $self->{given_args} = \%got_this_option;
}

=head2 exitvalue

Return the value the Nagios-command must return to Nagios.
This is the only value which is important for the Nagios state.

Use it like this:

    exit $ncli->exitvalue( $status );

or without object as class-method:

    exit Nagios::Clientstatus::exitvalue( $status );


Returnvalue can be a string of these:

    OK|WARNING|CRITICAL|UNKNOWN

=cut

sub exitvalue {
    my $first_arg = shift;

    # Class-method or object-method?
    my $status = ref($first_arg) ? shift: $first_arg;

    $status = uc $status;
    my %nagios_returnvalue = (
        'OK'       => 0,
        'WARNING'  => 1,
        'CRITICAL' => 2,
        'UNKNOWN'  => 3,
    );
    unless ( exists $nagios_returnvalue{$status} ) {
        die "Wrong status '$status' to return, status can only be: " . join ",",
          sort keys %nagios_returnvalue;
    }
    return $nagios_returnvalue{$status};
}

=head2 help_example

Give the user a hint how to use this programm. 

=cut

sub help_example {
    shift;
    print <<"EOUSAGE";
This is $0

Usage: 

$0 --warning 60 \\
   --critical 130 \\
   --your_argument_here_1 xx \\
   --your_argument_here_2 xx \\
   [--version]

Tell the user what this programm does
EOUSAGE
}

sub _get_optional_default_args {
    shift;
    qw{version help debug};
}

#=head2 _get_optional_additional_args
#
#Get a list of args which could be given to the program.
#These are the optional args given in new, but not the 
#default optional args 'help','debug','version'
#
#=cut

sub _get_optional_additional_args {
    my $self = shift;
    @{$self->{optional_additional_args}};
}

# for testing only, I can overwrite exit
# to let the program run after "exiting"

sub _exit {
    exit;
}

=head1 AUTHOR

    Richard Lippmann
    CPAN ID: HORSHACK
    horshack@lisa.franken.de
    http://lena.franken.de

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;

