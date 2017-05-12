package Sman::IndexVersion;
use warnings;
use strict;
use fields qw( config );
#use Data::Dumper; # tmp, for debugging
#$Id$

# call like my $versions = new Sman::IndexVersion( $sman_config_obj )
# appends .version to determine the version file.
sub new {
   my $proto = shift;
   my $class = ref($proto) || $proto;
   my $self  = {};
   bless ($self, $class);
   $self->{config} = shift || 
        die "$0: must pass a config object to Sman::IndexVersion::new()";
    
   return $self;
}        
# uses the $self->{config} object to figure out the .version filename
sub get_version_filename {
    my $self = shift;
    my $config = $self->{config};
    my $index = $config->GetConfigData("SWISHE_IndexFile") || 
        die "$0: no indexfile specified in configuration";
    return "$index.version"; 
}
sub set_versions {
    my ($self, $href) = @_;
    #print "$0: debug: set_versions() called\n";
    my $version_filename = $self->get_version_filename();
    open(VFILE, "> $version_filename") ||
        die "$0: can't open to write: $version_filename\n";
    for my $k (keys( %$href ) ) {
        print VFILE "$k $href->{$k}\n"; 
    }
    close(VFILE) || 
        die "$0: can't close: $version_filename\n";
}

# returns a hashref of NAME=>VALUE info 
sub get_versions {
    my $self = shift;
    my %hash;
    my $version_filename = $self->get_version_filename();
    #print "$0: debug: get_versions() called, opening $version_filename\n";
    return \%hash unless -f $version_filename;
    open(VFILE, "< $version_filename") || 
        die "$0: can't open to read: $version_filename\n";
    while( defined( my $line = <VFILE> ) ) {
        chomp($line);
        my ($k, $v) = split(/ /, $line, 2); 
        if ($k && $v) {
            $hash{$k} = $v;
            #print "$0: Sman::IndexVersion::get_versions(): got $k, $v\n";
        }
    }
    close(VFILE) || 
        die "$0: can't close $version_filename\n";
    return \%hash;
}



1;
__END__ 

=head1 NAME

Sman::IndexVersion - writes and reads sman's sman.index.version file

=head1 SYNOPSIS 

  # this module is intended for internal use by sman and sman-update
    # module appends ".version" and looks for that file
  my $index_versions = new Sman::IndexVersion( $versionfile );
  my $versions_hashref = $index_versions->get_versions();
  # will have values like 'VERSION' and 'SMAN_DATA_VERSION'
  $index_versions->set_versions( $versions_hashref );   # set them back
    
=head1 DESCRIPTION

Get/set the sman version information for a given indexfile

=head1 AUTHOR

Josh Rabinowitz <joshr>

=head1 SEE ALSO

L<sman.conf>, L<sman-update>, L<sman>

=cut

