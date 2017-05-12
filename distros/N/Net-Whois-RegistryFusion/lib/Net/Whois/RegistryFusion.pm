package Net::Whois::RegistryFusion;

=head1 NAME 

Net::Whois::RegistryFusion - perform cacheable whois lookups using RegistryFusion XML API

=head1 SYNOPSIS 

    $rf = Net::Whois::RegistryFusion->new();
    # OR:
    $rf = Net::Whois::RegistryFusion->new({ refreshCache=>1, 
                                            AUTH=>'http://hexillion.com/rf/xml/1.0/auth/',
                                            WHOIS=>'http://hexillion.com/rf/xml/1.0/whois/'
                                          });
    $rf->isCached('domain.com') 
    && 
    $xml = $rf->whois('domain.com');

=head1 DESCRIPTION

This class does not do any XML parsing. You must create a subclass inheriting and extending the whois method 
where you can code the XML parsing using eg. XML::Simple. 
You must also implement the _getUsername, _getPassword, _getXmlpath methods.

The class does some basic on-disk caching of the raw xml retrieved from RegistryFusion.
The path to the cache is specified using _getXmlpath method.

=head1 REQUIRED MODULES

 Date::Format (any)
 Error (any)
 File::Slurp (any)
 File::stat (any)
 IO::LockedFile (any)
 LWP::Simple (any)
 Module::Signature (any)
 Set::Array (any)
 Test::More (any)
 Test::Signature (any)

=head1 ABSTRACT METHODS

=head2 _getUsername

Must be implemented to return a RegistryFusion username

=head2 _getPassword

Must be implemented to return a RegistryFusion password

=head2 _getXmlpath 

Must be implemented to return a path where XML cache files will be stored

=head1 PUBLIC METHODS

=head2 new

This is the constructor. It takes as argument a hashref of options.

One option is 'refreshCache'. Setting 'refreshCache' to a value of 1 will alter the behaviour of the whois method for the lifetime of the object; foregoing and deleting the cached domain (if any) and retrieving directly from RegistryFusion.

You can also pass the auth url in the 'AUTH' key and the whois url in 'WHOIS' key, overriding the default values of:
AUTH    => 'http://whois.RegistryFusion.com/rf/xml/1.0/auth/';
WHOIS   => 'http://whois.RegistryFusion.com/rf/xml/1.0/whois/';

=head2 whois ($domain)

Returns (scalar) whois info in xml format for given $domain. Checks the cache first. If not found in the cache, retrieves from RegistryFusion. The whois xml info is cached in a file under the path as returned by _getXmlpath method. So, if the XMLPATH is '/registryfusion' and the $domain is 'example.com', the file will be stored as '/registryfusion/e/example.com.xml'

=head2 getFetchedDomains

Fetched domains are those domains that had the whois info fetched from RegistryFusion and not the cache.
Accessor returns array in list context or a Set::Array object in scalar context.

=head2 isCached ($domain)

Returns TRUE if given domain is cached. FALSE otherwise.

=head2 deleteFromCache ($domain)

Deletes the given $domain from the cache.

=head2 logout

Logs out of RegistryFusion, expiring the session. This method is called by the destructor, so you don't need to explicitly call it.

=head2 getSessionKey

returns session key.

=head1 PRIVATE METHODS

=head2 _login

Login to RegistryFusion and return a session key. this method is called by the constructor.

=head1 TODO

Need generic test suite. eg. use Class::Generate to generate a subclass. Get the username, password, xmlpath values from user during make test.

I've started doing this but encountered a problem with the fact that the username, password and xmlpath variables are static class variables and Class::Generate doesn't take care of this. Maybe we can improve Class::Generate.

My current progress can be seen embedded in the pod (Test::Inline style).


=begin testing

use Class::Generate;

subclass Net::Whois::RegistryFusion::Test => [
    '&_getUsername' => q{ return $username },
    '&_getPassword' => q{ return $password },
    '&_getXmlpath'  => q{ return $xmlpath  },

], -parent => 'Net::Whois::RegistryFusion';

my $rf = new Net::Whois::RegistryFusion::Test;
can_ok('Net::Whois::RegistryFusion::Test', ('isCached', 'whois'));
ok(defined $rf->isCached('lobsanov.com'), "verify isCached");
ok(my @info = $rf->whois('lobsanov.com'), "get whois");
is($info[0], 'LOBSANOV.COM', 'verify whois content');


=end testing

=cut

use strict;

use LWP::Simple;
use File::Slurp (); # don't import File::Slurp symbols to avoid collisions and reduce overhead
use File::stat;
use IO::LockedFile;
use Date::Format;
use Set::Array;
use Error;

use constant AUTH       => 'http://whois.RegistryFusion.com/rf/xml/1.0/auth/';
use constant WHOIS      => 'http://whois.RegistryFusion.com/rf/xml/1.0/whois/';

use constant TRUE       => 1;
use constant FALSE      => 0;

use vars qw($VERSION);
$VERSION = '0.05';


use fields qw(sessionKey fetchedDomains refreshCache AUTH WHOIS);

sub new {
    my ($self, $opts) = @_;

    $self = fields::new($self) unless ref $self;

    $self->{'fetchedDomains'}   = new Set::Array;
    $self->{'refreshCache'}     = $opts->{'refreshCache'} || FALSE;
    $self->{'AUTH'}             = $opts->{'AUTH'} || AUTH;
    $self->{'WHOIS'}            = $opts->{'WHOIS'} || WHOIS;
    $self->{'sessionKey'}       = $self->_login();
    return $self;
}

sub _login {
    my ($self) = @_;

    if ( defined $self->{'sessionKey'} ) {
        # already logged in
        return;
    }
    my $url = $self->{AUTH} . "?username=" . $self->_getUsername() . "&password=" . $self->_getPassword();
    my $xml = get($url)
        or throw Error::Simple("failed to get $url");
    $xml =~ m#<SessionKey>(.*)</SessionKey>#
        or throw Error::Simple("Couldn't open session");
    return $1;
}

sub logout {
    my ($self) = @_;

    my $url = $self->{AUTH} . "?sessionkey=" . $self->getSessionKey();
    get($url);
}

sub _getUsername {
    throw Error::Simple("this is an abstract method and must be implemented by subclass");
}

sub _getPassword {
    throw Error::Simple("this is an abstract method and must be implemented by subclass");
}

sub _getXmlpath {
    throw Error::Simple("this is an abstract method and must be implemented by subclass");
}

sub getSessionKey {
    my ($self) = @_;
    return $self->{'sessionKey'};
}

sub whois {
    my ($self, $domain) = @_;

    my $xml;
    if ( $self->isCached($domain) ) {
        if ( $self->{refreshCache} ) {
            $self->deleteFromCache($domain);
            $xml = $self->_whois($domain);
        }
        else {
            $xml = $self->_getCached($domain);
        }
    }
    else {
        $xml = $self->_whois($domain);
    }
    return $xml;
}

sub _whois {
# here we do the actual whois lookup
    my ($self, $domain) = @_;

    my $url = $self->{WHOIS} . "?sessionkey=". $self->getSessionKey() . "&query=$domain";
    my $xml = get($url)
        or throw Error::Simple("get $url failed");

# record the domain as fetched for reporting purposes
    $self->{fetchedDomains}->push($domain);
# cache the xml
    $self->_cache($xml, $domain);

    return $xml;
}

sub getFetchedDomains {
    my ($self) = @_;

    return wantarray ? @{ $self->{fetchedDomains} } : $self->{fetchedDomains};
}

sub _getFilename {
    my ($self, $domain) = @_;

    unless ( $domain ) {
        throw Error::Simple("_getFilename called without domain argument");
    }

    my $subdir = lc(substr($domain, 0, 1));
    my $filename = $self->_getXmlpath() . "/$subdir/$domain.xml";

    return wantarray ? ($filename, $subdir) : $filename;
}

sub getCacheDate {
    my ($self, $domain) = @_;

    my $stat = stat($self->_getFilename($domain));
    return time2str("%x", $stat->mtime());
}

sub isCached {
    my ($self, $domain) = @_;
 
    if ( -e $self->_getFilename($domain) ) {
        return TRUE;
    }
    else {
        return FALSE;
    }
}

sub _getCached {
    my ($self, $domain) = @_;

    my $filename = $self->_getFilename($domain);
    my $file = new IO::LockedFile $filename;
    if ( my $xml = File::Slurp::read_file($file) ) { #YYY: Perl6::Slurp is nicer but requires perl5.8+
        return $xml;
    }
}

sub _cache {
    my ($self, $xml, $domain) = @_;
    
    my ($filename, $subdir) = $self->_getFilename($domain);
    $subdir = $self->_getXmlpath() . "/$subdir";
    mkdir $subdir if ! -d $subdir;
    my $file = new IO::LockedFile ">$filename";
    File::Slurp::write_file($file, $xml);
}

sub deleteFromCache {
    my ($self, $domain) = @_;

    my $filename = $self->_getFilename($domain);
    if ( -e $filename ) {
        unlink $filename 
            or throw Error::Simple("Failed to unlink $filename. $!");
    }
}

sub DESTROY {
    my ($self) = @_;
    $self->logout();
}

1;

__END__

=head1 AUTHOR

Ilia Lobsanov

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Ilia Lobsanov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
