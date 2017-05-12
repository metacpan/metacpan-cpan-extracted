package Net::Discident;

use Modern::Perl;
use Digest::MD5     qw( md5_hex );
use File::Find;
use File::stat;
use HTTP::Lite;
use JSON;

use version;
our $VERSION = qv( 1.0.1 );

use constant BASE_URI => 'http://discident.com/v1';



sub new {
    my $class = shift;
    my $path  = shift;
    
    my $self = {};
    bless $self, $class;
    
    $self->fingerprint( $path );
    
    return $self;
}

sub fingerprint {
    my $self        = shift;
    my $path        = shift;
    my $fingerprint = shift;
    
    return $self->ident()
        if !defined $fingerprint && !defined $path;
    
    $fingerprint = $self->fingerprint_files( $path )
        if !defined $fingerprint;
    
    # discident fingerprints are uppercase and hyphenated hex md5s
    my $md5 = uc md5_hex( $fingerprint );
    $md5 =~ s{(.{8})(.{4})(.{4})(.{4})(.*)}{$1-$2-$3-$4-$5};
    
    $self->{'ident'} = $md5;
    
    return $md5;
}
sub ident {
    my $self  = shift;
    my $ident = shift;
    
    $self->{'ident'} = $ident
        if defined $ident;
    
    return $self->{'ident'};
}
sub query {
    my $self  = shift;
    my $ident = shift // $self->ident();
    my $raw   = shift // 0;
    
    my $uri  = $self->query_url( $ident );
    my $http = HTTP::Lite->new();
    my $code = $http->request( $uri )
        or die "Unable to fetch ident: $!";
    
    die "Unable to fetch ident: HTTP $code"
        unless 200 == $code;
    
    return $http->body()
        if $raw;
    
    return from_json $http->body()
}
sub query_url {
    my $self  = shift;
    my $ident = shift // $self->ident();
    
    return sprintf "%s/%s/", BASE_URI, $ident;
}

sub fingerprint_files {
    my $self = shift;
    my $path = shift;
    
    my $long_fingerprint;
    
    my $stat_file = sub {
        return if -d $_;

        my $stat = stat $_;
        substr $_, 0, length( $path ), '';
        
        $long_fingerprint .= sprintf(
            ":%s:%lld",
                $_,
                $stat->size,
        );
    };
    
    find(
        {
            wanted   => $stat_file,
            no_chdir => 1,
        },
        $path,
    );
    
    return $long_fingerprint;
}

1;

__END__

=head1 NAME 

Net::Discident - query discident.com for DVD details

=head1 SYNOPSIS

    my $ident       = Net::Discident->new( $path );
    my $fingerprint = $ident->ident();
    my $data        = $ident->query();

=head1 METHODS

=over

=item fingerprint( I<path> )

Stores and returns the fingerprint of the DVD at I<path>. 

=item ident()

Returns the fingerprint of the DVD already added with C<new()> or
C<fingerprint()>.

=item query()
=item query( I<$fingerprint> )
=item query( I<$gtin> )

The first two forms will return the data that discident.com knows about the
given DVD fingerprint, either passed as an argument or already calculated
from a path. This data looks like:

    discs => {
        '3DF28C7A-3EB4-41F2-7CD8-27B691EF984D' => {
            confirmed => 'true',
            tag       => '1A'
        },
    },
    gtin  => '00794043444623',
    title => 'Long Kiss Goodnight'

The third form, using a GTIN ("Global Trade Item Number"), may contain more
information if it is registered with discident.com. Such as:

    discs          => {
        '3DF28C7A-3EB4-41F2-7CD8-27B691EF984D' => {
            confirmed => 'true',
            tag       => "1A"
        },
    },
    genre          => 'Action/Adventure',
    gtin           => '00794043444623',
    productionYear => 1996,
    studio         => 'New Line',
    title          => 'Long Kiss Goodnight'

=item query_url()
=item query_url( I<$identifier> )

Will return the URL used to query discident.com for the given identifier
or already calculated identifier.

=back

=head1 AUTHORS

Mark Norman Francis <norm@cackhanded.net> and 
Steve Marshall <steve@nascentguruism.com>.

Based upon Objective C code provided by discident.com --
L<https://github.com/discident/objectivec>.

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Mark Norman Francis and Steve Marshall.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.
