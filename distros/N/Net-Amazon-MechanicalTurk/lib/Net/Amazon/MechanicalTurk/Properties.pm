package Net::Amazon::MechanicalTurk::Properties;
use strict;
use warnings;
use IO::File;
use Carp;

our $VERSION = '1.00';

sub toProperties {
    my ($class, $properties) = @_;
    if (UNIVERSAL::isa($properties, "HASH")) {
        return $properties;
    }
    else {
        return Net::Amazon::MechanicalTurk::Properties->readNestedData($properties);
    }
}

sub write {
    my ($class, $settings, $file, $header) = @_;
    my $out = IO::File->new($file, "w");
    if (!$out) {
        Carp::croak("Could not open file $file - $!.");
    }
    if ($header) {
        foreach my $line (split /\r?\n/, $header) {
            printf $out "# %s\n", $line;
        }
    }
    foreach my $key (sort keys %$settings) {
        my $value = $settings->{$key};
        printf $out "%s: %s\n", $key, $value;
    }
    $out->close;
}

# Reads a properties file into a nested data structure
sub readNestedData {
    my ($class, $in) = @_;
    return Net::Amazon::MechanicalTurk::DataStructure->fromProperties($class->read($in));
}

# Reads a file into key value pairs and returns a hash.
# The file should be similar to that of a Java properties file.
# Backslash escaping is not supported though.
# Both = and : can be used as key/value separators.
sub read {
    my ($class, $in) = @_;
    my $file = "<stream>";
    
    if (!UNIVERSAL::isa($in, "GLOB")) {
        $file = $in;
        $in = IO::File->new($file, "r");
        if (!$in) {
            Carp::croak("Could not read file $file - $!.");
        }
    }
    
    my $props = {};
    my $lineno = 0;
    while (my $line = <$in>) {
        next if ($line =~ /^\s*[#!]/ or $line =~ /^\s*$/);
        if ($line =~ /^([^:=]+)[=:](.*)/) {
            my ($key,$val) = ($1,$2);
            $key =~ s/^\s+//;
            $key =~ s/\s+$//;
            $val =~ s/^\s+//;
            $val =~ s/\s+$//;
            $props->{$key} = $val;
        }
        else {
            warn "Unknown format at $file:$lineno.";
        }
    }
    
    return $props;
}

return 1;
