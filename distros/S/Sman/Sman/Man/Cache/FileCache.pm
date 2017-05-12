package Sman::Man::Cache::FileCache;

#$Id$

use Cache::FileCache;

use base 'Sman::Man::Cache';
use fields qw( filecache );

# pass a dir to store the cache data in
sub new {
   my $class = shift;
    my $dir = shift;
   my $self = fields::new($class);

   $self->SUPER::new();                # init base fields 

    if (defined($dir)) {
        my %hash = ( 'namespace' => 'sman', 'default_expires_in' => "1 month" );
        $^W=0;  # avoid pseudo-hash warnings on perl 5.8.0
        $self->{filecache} = new Cache::FileCache( \%hash );
    }
    return $self;
}

sub get {
    my $self = shift;
    my $key = shift;
    my $val;
    #local $^W = 0; # hide 'pseudo-hashes are deprecated' warnings in perl 5.8.0
    no warnings;    # hide 'pseudo-hashes are deprecated' warnings in perl 5.8.0
    if (defined($self->{filecache}) && ($val = $self->{filecache}->get($key) ) ) {
        return $val;
    }
    return undef;
}
sub set {
    my $self = shift;
    my $key = shift;    
    # we handle rawdata right from $_[0]. Why not?
    #local $^W = 0; # hide 'pseudo-hashes are deprecated' warnings in perl 5.8.0
    no warnings;    # hide 'pseudo-hashes are deprecated' warnings in perl 5.8.0
    $self->{filecache}->set($key, $_[0]) if ($self->{filecache});
} 
sub Clear {
    my $self = shift;
    my $cache = $self->{filecache};
    defined($cache) && ($cache->Clear());
}

1;

=head1 NAME

Sman::Man::Cache::FileCache - Cache converted manpages in a Cache::FileCache

=head1 SYNOPSIS

  # this module is intended for internal use by sman-update
  my $cache = new Sman::Man::Cache::FileCache();
  $cache->set("/usr/man/man3/ls.3", "some stuff");
  
  # ..later...
  
  my $ret = $cache->get("/usr/man/man3/ps.3");
  # $ret will be undef if data not found.
    
=head1 DESCRIPTION

Uses a Cache::FileCache to store raw data for use by Sman::Man::Convert.

=head1 AUTHOR
    
Josh Rabinowitz <joshr>
    
=head1 SEE ALSO
            
L<sman-update>, L<Sman::Man::Convert>, L<sman.conf>, L<Sman::Man::Cache>
        
=cut    
