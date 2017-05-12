#-----------------------------------------------------------------
# Proc::Async::Config
# Author: Martin Senger <martin.senger@gmail.com>
# For copyright and disclaimer se below.
#
# ABSTRACT: Configuration helper
# PODNAME: Proc::Async::Config
#-----------------------------------------------------------------

use warnings;
use strict;
package Proc::Async::Config;

use Carp;

our $VERSION = '0.2.0'; # VERSION

#-----------------------------------------------------------------
# Constructor. It reads a given configuration file (but does not
# complain if the file does not exist yet).
#
# Arguments:
#   config-file-name
#   name/value pairs (at the moment, not used)
# -----------------------------------------------------------------
sub new {
    my ($class, @args) = @_;

    # create an object
    my $self = bless {}, ref ($class) || $class;

    # a config file name is mandatory
    croak ("Missing config file name in the Proc::Async::Config constructor.\n")
        unless @args > 0;
    $self->{cfgfile} = shift @args;

    # ...and the rest are optional name/value pairs
    my (%args) = @args;
    foreach my $key (keys %args) {
        $self->{$key} = $args {$key};
    }

    $self->clean();  # empty storage for the configuration properties

    # load the configuration (if exists)
    $self->load()
        if -e $self->{cfgfile};

    # done
    return $self;
}

#-----------------------------------------------------------------
# Remove all properties from all so far loaded configuration files (it
# does it in memory, the files remain untouched).
# -----------------------------------------------------------------
sub clean {
    my $self = shift;
    $self->{data} = {};
}

#--------------------------------------------------------------------
# Add properties from the given configuration files (or from the file
# given in the constructor).
# -----------------------------------------------------------------
sub load {
    my ($self, $cfgfile) = @_;
    $cfgfile = $self->{cfgfile} unless $cfgfile;
    open (my $cfg, '<', $cfgfile)
        or croak ("Cannot open configuration file '$cfgfile': $!\n");
    my $count = 0;
    while (my $line = <$cfg>) {
        $count++;

        # skipping comments and empty lines:
        $line =~ /^(\n|\#)/  and next;
        $line =~ /\S/        or  next;
        chomp $line;
        $line =~ s/^\s+//g;
        $line =~ s/\s+$//g;

        # parsing key/value pairs
        my ($key, $value) = split (m{\s*=\s*}, $line, 2);
        if (not defined $key or $key eq '') {
            # unusable key
            carp "Missing key in the configuration file '$cfgfile' in line $count: '$line'. Ignored.\n";
            next;
        }
        if (not defined $value or $value eq '') {
            $value = 1;   # an existing property must be an important property
        }
        $self->param ($key, $value);
    }
    close $cfg;
}

#-----------------------------------------------------------------
# Return the value of the given configuration property, or undef if
# the property does not exist. Depending on the context, it returns
# the value as a scalar (and if there are more values for the given
# property then it returns the first value only), or an array.
#
# Set the given property first if there is a second argument with the
# property value.
#
# Return a sorted list of all property names if no argument given (the
# list may be empty).
# -----------------------------------------------------------------
sub param {
    my ($self, $name, $value) = @_;
    unless (defined $name) {
        my @names = sort keys %{ $self->{data} };
        return (@names ? @names : ());
    }
    if (defined $value) {
        $self->{data}->{$name} = []
            unless exists $self->{data}->{$name};
        push (@{ $self->{data}->{$name} }, $value);
    } else {
        return
            unless exists $self->{data}->{$name};
    }
    return unless defined wantarray; # don't bother doing more
    return wantarray ? @{ $self->{data}->{$name} } : $self->{data}->{$name}->[0];
}

sub remove {
    my ($self, $name) = @_;
    return delete $self->{data}->{$name};
}

#-----------------------------------------------------------------
# Create a configuration file (overwrite if exists). The name is
# either given here or the one given in the constructor.
# -----------------------------------------------------------------
sub save {
    my ($self, $cfgfile) = @_;
    $cfgfile = $self->{cfgfile} unless defined $cfgfile;
    open (my $cfg, '>', $cfgfile)
        or croak ("Cannot create configuration file '$cfgfile': $!\n");
    foreach my $key (sort keys %{ $self->{data} }) {
        my $values = $self->{data}->{$key};
        foreach my $value (@$values) {
            print $cfg "$key = $value\n";
        }
    }
    close $cfg;
}

1;

__END__
=pod

=head1 NAME

Proc::Async::Config - Configuration helper

=head1 VERSION

version 0.2.0

=head1 AUTHOR

Martin Senger <martin.senger@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Martin Senger, CBRC-KAUST (Computational Biology Research Center - King Abdullah University of Science and Technology) All Rights Reserved.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

