package Religion::Bible::Regex::Config;

use warnings;
use strict;
use Carp;

use version; our $VERSION = '0.61';

use YAML::Loader;

# Input files are assumed to be in the UTF-8 strict character encoding.
#use utf8;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

sub new {
    my $class = shift;
    my $self = {};
    my $config = shift;

    bless ($self, $class);

    croak "Religion::Bible::Regex::Config must be initialize with a string which containing either a the location of a YAML file or actual YAML" unless (defined($config));

    # If $config is a file that exists
    # Crud method for testing that this is not YAML --> m/\n/ == 0
    if ($config =~ m/\n/ == 0 && -e $config) {
        $self->{config} = $self->_read_yaml_file($config);
    } else {
       my $yaml_loader = YAML::Loader->new();
       $self->{config} = $yaml_loader->load($config); 
    }

    return $self;
}

sub get {
    my $self = shift;
    my @keys = @_;

    my $ret = $self->{config};
    foreach my $key (@keys) {
#        carp "Configuration not found: {$key}" unless defined($ret->{$key});
        $ret = $ret->{$key};
    }
    return $ret;
}

sub get_or_undef {
    my $self = shift;
    my @keys = @_;

    my $ret = $self->{config};
    foreach my $key (@keys) {
        return unless defined($ret->{$key});
        $ret = $ret->{$key};
    }
    return $ret;
}


# These getter functions are very important to have right.
sub get_bookname_configurations {
	return shift->{'config'}{'books'}; 
}

sub get_search_configurations {
	return shift->{'config'}{'regex'}; 
}

sub get_formatting_configurations {
	return shift->{'config'}{'reference'};
}

sub get_versification_configurations {
	return shift->{'config'}{'versification'}; 
}

sub _read_yaml_file {
    my $self = shift;
    my $path_to_config_file = shift;
    my $config;

    my $yaml_loader = YAML::Loader->new();
    my $yaml_text;

    # Vous ouvrez le fichier de configuration 
    if(open(*CONFIG, "<:encoding(UTF-8)", $path_to_config_file)) { 
        {
            local( $/, *FH );
            $yaml_text = <CONFIG>;  # slurp it
        }
        $config = $yaml_loader->load($yaml_text);
    	close (CONFIG);
    }

    return $config;
}
1; # Magic true value required at end of module
__END__

=head1 NAME

Religion::Bible::Regex::Config - Creates a configuration object for the Religion::Bible::Regex objects from a YAML file.


=head1 VERSION

This document describes Religion::Bible::Regex::Config version 0.2


=head1 SYNOPSIS

    use Religion::Bible::Regex::Config;

    # Initialize with a YAML file or a string containing YAML
    my $c = new Religion::Bible::Regex::Config("config.yml");

    # Retrieve configurations in YAML format    
    my $regex_configurations = $c->get_regex_configs;
    my $reference_configurations = $c->get_reference_configs;
    
    # Initialize other Religion::Bible::Regex objects
    my $r   = new Religion::Bible::Regex::Regex($c);
    my $v   = new Religion::Bible::Regex::Versification($r, $c);
    my $ref = new Religion::Bible::Regex::Reference($r, $c);
      

=head1 INTERFACE 

=head2 new

Creates a configuration object from a YAML file or string

=head2 get

Returns a configuration string

=head2 gethash

Returns a hash of all configurations

=head2 get_formatting_configurations

Returns a hash of the reference configurations

=head2 get_search_configurations

Returns a hash of the regex configurations

=head2 get_versification_configurations

Returns a hash of the versification configurations

=head2 get_bookname_configurations

Returns a hash of the bookname configurations

=head2 get_or_undef

=head1 DIAGNOSTICS

=over

=item If you do not pass a YAML file or string when creating a new instance then your program will croak.

=item If you pass in invalid YAML then expect your program to stop and dump the errors
to the STDOUT.

See the YAML module for more details.

=back


=head1 CONFIGURATION AND ENVIRONMENT
  
Religion::Bible::Regex::Config requires no configuration files or environment variables.


=head1 DEPENDENCIES

B<YAML>

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-religion-bible-regex-config@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Daniel Holmlund  C<< <holmlund.dev@gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Daniel Holmlund C<< <holmlund.dev@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

