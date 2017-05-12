package Printer::Label::Template::Processor;
use strict;
use warnings;

use Carp;
use File::Slurp;
use Net::FTP;
use Net::Printer;
use Template;
use Params::Validate qw/validate SCALAR UNDEF OBJECT HASHREF ARRAYREF CODEREF/;

our $VERSION = '1.01';

#-------------------------------------------------------------------------------
# Constants
#-------------------------------------------------------------------------------

# lookup table used to link file extensions and _build_output_from_* methods
my $H_TEMPLATES = {
    pl   => 'perl',
    perl => 'perl',
    tt   => 'tkit',
    tt2  => 'tkit',
};

#-------------------------------------------------------------------------------
# Public methods
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# new
# Creates a label object
#-------------------------------------------------------------------------------

sub new {
    my $class = shift;
    my %params = @_;
    my $print_mode = defined($params{print_mode}) ? uc($params{print_mode}) : 'CON';

    # params validation
    %params = validate(@_, {
        script_file => { 
            type => SCALAR,
        },
        print_mode  => { 
            type    => SCALAR,
            default => 'CON',
        },
        check_syntax => {
            type => CODEREF,
            default => sub { return (1==1) },
        },
        server => { 
            type     => SCALAR,
            optional => (grep(/$print_mode/, qw/FTP LPR/) ? 0 : 1),
        },
        port => { 
            type     => SCALAR,
            optional => 1,      # Net::FTP and Net::Printer define their own default values
            depends  => [ 'server' ],
        },
        user => { 
            type     => SCALAR,
            optional => 1,      # Net::FTP defines its own default value
            depends  => [ 'server', 'password' ],
        },
        password => { 
            type     => SCALAR,
            optional => 1,      # Net::FTP defines its own default value
            depends  => [ 'server', 'user' ],
        },
        output_file => { 
            type     => SCALAR,
            optional => ($print_mode ne 'FILE'),
        },
    });

    my $self = bless {}, $class;
    $self->{$_} = $params{$_} foreach (keys %params);

    return $self;
}

#-------------------------------------------------------------------------------
# printout
# Builds the output data and sends it to a printing system
#-------------------------------------------------------------------------------

sub printout {
    my $self = shift;

    # params validation
    my %params = validate(@_, {
        vars => { type => HASHREF },
    });

    $self->{$_} = $params{$_} foreach (keys %params);

    # builds the output data
    $self->_set_output_data;

    # checks the syntax
    $self->{check_syntax}->($self->{output_data}) or croak "Invalid output syntax while processing $self->{script_file}";

    # builds the print method name and calls it
    my $method = '_print_to_' . lc($self->{print_mode});
    $self->can("$method") or croak "Unknown print method: $method";
    $self->$method;
}

#-------------------------------------------------------------------------------
# Private methods
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# _set_output_data
# Builds the output data of the label
#-------------------------------------------------------------------------------

sub _set_output_data {
    my $self = shift;

    # detects the script's language
    my $script_language = $self->{script_file};
    $script_language =~ s/^.*\.([^\.]*$)/lc($1)/e;
    $H_TEMPLATES->{$script_language} or croak "Unknown script language: $script_language";

    # invokes the corresponding method
    my $method = '_build_output_from_' . $H_TEMPLATES->{$script_language};
    $self->can("$method") or croak "Unknown print method: $method";
    $self->$method;
}

#-------------------------------------------------------------------------------
# _build_output_from_perl
# Builds output data by processing a Perl script
#-------------------------------------------------------------------------------

sub _build_output_from_perl {
    my $self = shift;

    # loads the script
    my $script = read_file($self->{script_file}) ;
    $script or croak "Error while loading the file: $self->{script_file}";

    # evaluates the script
    my $output_data = eval("$script");

    # links the output data to the label
    $self->{output_data} = $output_data;
}

#-------------------------------------------------------------------------------
# _build_output_from_tkit
# Builds output data by processing a Template Toolkit script
#-------------------------------------------------------------------------------

sub _build_output_from_tkit {
    my $self = shift;

    # extracts the script's filename
    my $script_file = (split(/[\\\/]/, $self->{script_file}))[-1];

    # extracts the path to the script file
    my $script_path = $self->{script_file};
    $script_path =~ s/\/$script_file//g;

    # creates a TT2 object
    my $tt = Template->new({
        INCLUDE_PATH => $script_path,
        INTERPOLATE  => 1,
    }) || croak "$Template::ERROR";

    # evaluates the script
    my $output_data;
    $tt->process($script_file, $self->{vars}, \$output_data) || croak $tt->error();

    # links the output data to the label
    $self->{output_data} = $output_data;
}

#-------------------------------------------------------------------------------
# _print_to_con
# Sends the content to the standard output
#-------------------------------------------------------------------------------

sub _print_to_con {
    my $self = shift;

    # prints the output data to standard output
    print "$self->{output_data}\n";
}

#-------------------------------------------------------------------------------
# _print_to_ftp
# Sends the content to a FTP server
#-------------------------------------------------------------------------------

sub _print_to_ftp {
    my $self = shift;

    # connects to the FTP server
    my $session = Net::FTP->new(
        $self->{server}, 
        Passive => 0, 
        Debug => 0,
    ) or croak "Error while connecting to $self->{server}\n";
    $session->login(
        $self->{user}, 
        $self->{password},
    ) or croak "Invalid user/password\n";
    $session->ascii;

    # sends the in-memory file to the FTP server
    open my $output_file, "<", \$self->{output_data} or croak $!;
    $session->put($output_file, "OUTPUT.TXT") or croak "Error while sending the file\n";
    $session->quit;
    close $output_file;
}

#-------------------------------------------------------------------------------
# _print_to_lpr
# Sends the content to a print queue
#-------------------------------------------------------------------------------

sub _print_to_lpr {
    my $self = shift;

    # creates a print queue
    my $printer = new Net::Printer(
        server => $self->{server},
    );
    $printer->{port} = $self->{port} if defined($self->{port});

    # sends the output data to the print queue
    my $res = $printer->printstring($self->{output_data});
    $res or croak "Error while printing on $self->{server} port $self->{port} using LPR: " . $printer->printerror() . "\n";
}

#-------------------------------------------------------------------------------
# _print_to_file
# Writes the content to a file
#-------------------------------------------------------------------------------

sub _print_to_file {
    my $self = shift;

    # dumps the output data to a file
    write_file($self->{output_file}, \$self->{output_data}) or croak "Error while sending the file\n";
}


1;

__END__

=head1 NAME

Printer::Label::Template::Processor
Template-based label management

=head1 SYNOPSIS

    # prints to standard output
    my $print_con = Printer::Label::Template::Processor->new(
        script_file   => "MyPath/MyFile.tt2",
        check_syntax  => \&my_check_sub,
        print_mode    => "CON",
    );
    $print_con or croak "Error while creating the printer object";
    $print_con->printout(
        vars => {
            my_var_1 => 'My var 1',
            my_var_2 => $my_var_2,
            my_var_3 => ['My', 'var', '3'],
        }
    );

    # prints to FTP server
    my $print_ftp = Printer::Label::Template::Processor->new(
        script_file   => "MyPath/MyFile.tt2",
        check_syntax  => \&my_check_sub,
        print_mode    => "FTP",
        server        => "MyPrintServer",
    );
    $print_ftp or croak "Error while creating the printer object";
    $print_ftp->printout(
        vars => {
            my_var_1 => 'My var 1',
            my_var_2 => $my_var_2,
            my_var_3 => ['My', 'var', '3'],
        }
    );

    # prints to LPR queue
    my $print_lpr = Printer::Label::Template::Processor->new(
        script_file   => "MyPath/MyFile.tt2",
        check_syntax  => \&my_check_sub,
        print_mode    => "LPR",
        server        => "MyPrintServer",
    );
    $print_lpr or croak "Error while creating the printer object";
    $print_lpr->printout(
        vars => {
            my_var_1 => 'My var 1',
            my_var_2 => $my_var_2,
            my_var_3 => ['My', 'var', '3'],
        }
    );

    # prints to file
    my $print_file = Printer::Label::Template::Processor->new(
        script_file   => "MyPath/MyFile.tt2",
        check_syntax  => \&my_check_sub,
        print_mode    => "FILE",
        output_file   => "MyPath/MyFile.txt",
    );
    $print_file or croak "Error while creating the printer object";
    $print_file->printout(
        vars => {
            my_var_1 => 'My var 1',
            my_var_2 => $my_var_2,
            my_var_3 => ['My', 'var', '3'],
        }
    );

(...)

    sub my_check_sub {
        my $output_data = shift;

        # checks for the presence of some commands
        return ($output_data =~ /^MyStartCommand(.*\s)*MyStopCommand$/);
    }

=head1 DESCRIPTION

This module provides a way to build any type of labels using templates and 
output them on a printing device.

A template file consists of a script written in a scripting language.
Support is provided for the following scripting languages:
* Perl
* Template Toolkit

The template is run and passed variables through a hash. This variables are
used by the script to populate fields and perform operations throughout the 
content of the label. The scripts returns the ready-to-print content of the 
label. The syntax of the output data is checked in accordance with the 
language used by the printing device. Once validated, the output data is sent
to the printing device.

Support is provided for the following printing protocols:
* CON: prints to the standard output
* FTP: prints to an FTP server
* LPR: prints to an LPR queue
* FILE: prints to a file

=head1 CONSTANTS

=head3 $H_TEMPLATES

Lookup table used to link file extensions and _build_output_from_* methods.

=head1 METHODS

=head2 Public Methods

=head3 new

    my $print_lpr = Printer::Label::Template::Processor->new(
        script_file  => "MyPath/MyScriptFile.tt2",      # full path to the script file
        check_syntax => \&my_check_sub,                 # reference to the sub that will check the syntax of the data output by the script
        print_mode   => "LPR",                          # identifier of the printing prtotocol
        server       => "MyPrintServer",                # Identifier of the printing device (Network name, IP address...)
        port         => 555,                            # TCP port number if required
        user         => 'MyUser',                       # username if authentification is required
        password     => 'MyPassword',                   # password if authentification is required
        output_file  => "MyPath/MyOutputFile.txt"       # full path to the output file required by the FILE printing protocol
    );

Creates a label processor object.
Each parameter passed to the method is set to an object's property of the 
same name.

=head3 printout

    $print_lpr->printout(
        vars => {
            my_var_1 => 'My var 1',
            my_var_2 => $my_var_2,
            my_var_3 => ['My', 'var', '3'],
        }
    );

Builds the output data and sends it to a printing system.
The vars structure is transmitted to the template script which will use them
in order to produce the content of the label. The variables can be used to
fill placeholders values or any algorithmic needs.

=head2 Private Methods

=head3 _set_output_data

Builds the output data of the label.
This method uses the lookup table defined in $H_TEMPLATES to identify the 
language of the template script. It then builds dynamically the name of the
corresponding method and calls it.

=head3 _build_output_from_perl

Builds output data by processing a Perl script.
Loads the Perl script, eval-s it and stores its output in the output_data 
property of the label object.

=head3 _build_output_from_tkit

Builds output data by processing a Template Toolkit script.
Loads the Template Toolkit script, processes it and stores its output in the 
output_data property of the label object.

=head3 _print_to_con

Sends the content to the standard output.

=head3 _print_to_ftp

Sends the content to a FTP server.

=head3 _print_to_lpr

Sends the content to a print queue.

=head3 _print_to_file

Writes the content to a file.

=head1 AUTHOR

Christian Morel, C<< <christian.morel at etat.ge.ch> >>, Jan. 2013
