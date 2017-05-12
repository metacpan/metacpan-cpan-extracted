package Nagios::NSCA::Client::Config;
use strict;
use warnings;
use base 'Nagios::NSCA::Client::Base';
use constant DEFAULT_NSCA_PASSWORD => "";
use constant DEFAULT_NSCA_ENCRYPTION => "NONE";
use constant MAXIMUM_ENCRYPTION_VALUE => 26;

our $VERSION = sprintf("%d", q$Id: Config.pm,v 1.2 2006/04/10 22:39:39 matthew Exp $ =~ /\s(\d+)\s/);

sub new {
    my ($class, %args) = @_;
    my $fields = {
        password => DEFAULT_NSCA_PASSWORD,
        encryption => DEFAULT_NSCA_ENCRYPTION,
    };
    my $self = $class->SUPER::new(%args);
    $self->_initFields($fields);

    $self->_initFromConfig($args{config});

    return $self;
}

sub _initFromConfig {
    my ($self, $file) = @_;
    return if not $file;

    open(CONFIG, $file) || die "Could not open file $file: $!\n";
    while (<CONFIG>) {
        next if /^\s*(#|$)/;  # Skip blank lines and commented lines.

        if (/^(.*?)=(.*)$/) {
            my ($variable, $value) = ($1, $2);

            # Make sure we have both a variable and a value
            die "No variable name found: $_\n" if not defined $variable;
            die "No variable value found: $_\n" if not defined $value;

            if ($variable eq 'password') {
                $self->password($value);
            } elsif ($variable eq 'encryption_method') {
                $value = Nagios::NSCA::Encrypt->numberToName($value);
                $self->encryption($value);
            } else {
                die "Unknown option in config file: $_\n";
            }
        } else {
            die "Bad line in configuration file: $_\n";
        }
    }
    close(CONFIG);
}

1;
