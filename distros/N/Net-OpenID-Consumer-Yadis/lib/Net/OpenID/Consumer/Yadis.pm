package Net::OpenID::Consumer::Yadis;

use strict;
use Carp ();
use base qw(Net::OpenID::Consumer);
use Net::Yadis::Discovery;
use vars qw($VERSION);
$VERSION = "0.01";

use fields qw(yadis choose_logic __yadis_localcache);

sub new {
    my $self = shift;
    $self = fields::new( $self ) unless ref $self;
    my %opts = @_;
    
    $self->{yadis} =         delete $opts{yadis};
    $self->{choose_logic} =  delete $opts{choose_logic};
    $self->{__yadis_localcache} = {};
    $self->SUPER::new(%opts);

    return $self;
}

sub choose_logic { &Net::OpenID::Consumer::_getset; }
sub __yadis_localcache { &Net::OpenID::Consumer::_getset; }

sub ua {
    my $self = shift;
    $self->{ua} = shift if @_;
    Carp::croak("Too many parameters") if @_;

    unless ($self->{ua}) {
        $self->{ua} = $self->yadis->ua;
    }

    $self->{ua};
}

sub yadis {
    my $self = shift;
    $self->{yadis} = shift if @_;
    Carp::croak("Too many parameters") if @_;

    unless ($self->{yadis}) {
        $self->{yadis} = Net::Yadis::Discovery->new(
            ua => $self->{ua},
            cache => $self->cache,
        );
    }
    $self->{yadis}->ua($self->{ua}) unless ($self->{yadis}->{_ua});

    $self->{yadis};
}

sub _find_semantic_info {
    my $self = shift;
    my $url = shift;
    my $final_url_ref = shift;
    my $yadis = $self->yadis;

    if ($self->cache) {
        $yadis->cache($self->cache) unless ($yadis->cache);
    } else {
        $self->cache($yadis->cache ? $yadis->cache : $yadis->cache($self));
    }

    unless ($yadis->xrd_objects && $yadis->identity_url eq $url) {
        $yadis->discover($url,YR_GET); # or return $self->_fail($yadis->errcode,$yadis->errtext);
    }

    my $sem_info = {};
    if ($url ne $yadis->xrd_url) {
        $sem_info = $self->SUPER::_find_semantic_info($url,$final_url_ref) or return;
    } else {
        $$final_url_ref = $yadis->xrd_url;
    }

    my $logic;
    if (my $a_ident = $self->args("openid.identity")) {
         $logic = sub {
            foreach my $srv (@_) {
                return ($srv) if ($srv->Delegate eq $a_ident);
            }
            return;
         };
    } elsif (ref($self->choose_logic) eq 'CODE') {
        $logic = $self->choose_logic;
    } else {
        $logic = sub {
#            ($_[int(rand(@_))])
            ($_[0])
        };
    }

    if (my @services = $yadis->openid_servers($logic)) {
        $sem_info->{'openid.server'} = $services[0]->URI;
        $sem_info->{'openid.delegate'} = $services[0]->Delegate;
    }
    
    $self->cache($yadis->cache(undef)) if ($yadis->cache->can("__yadis_localcache"));
    $self->__yadis_localcache({});

    return $sem_info;
}

sub set {
    my ($self,$key,$value) = @_;
    $self->__yadis_localcache->{$key} = $value if (defined($key));
}

sub get {
    my ($self,$key) = @_;
    $self->__yadis_localcache->{$key} if (defined($key));
}

1;

__END__

=head1 NAME

Net::OpenID::Consumer::Yadis - library for consumers of OpenID identities, which uses Yadis protocol to search identity

=head1 SYNOPSIS

  use Net::OpenID::Consumer::Yadis;

  my $csr = Net::OpenID::Consumer::Yadis->new(
    yadis => Net::Yadis::Discovery->new(
        ua    => LWPx::ParanoidAgent->new, # You should set ua and cache on yadis object, if use.
        cache => Some::Cache->new,
    ),
    args  => $cgi,
    consumer_secret => ...,
    required_root => "http://site.example.com/",
    choose_logic => sub { ($_[int(rand(@_))]) }, # If you want to set original logic to choose one OpenID server from servers, set the code.
  );

  my $claimed_identity = $csr->claimed_identity("bradfitz.com");

  ....
  
  # After from here, same as Net::OpenID::Consumer. See Net::OpenID::Consumer's pod.


=head1 DESCRIPTION

Parent module, Net::OpenID::Consumer, is the Perl API for (the consumer half of) 
OpenID, a distributed identity system based on proving you own a URL, which is 
then your identity.  More information is available at:

  http://www.openid.net/

And this module is subclass of it, which use Yadis protocol to fetch OpenID protocol's 
setting (identity server, delegation, etc.) from OpenID URL. More information about 
Yadis is available at:

  http://yadis.org/

=head1 CONSTRUCTOR

=over 4

=item C<new>

my $csr = Net::OpenID::Consumer::Yadis->new([ %opts ]);

You can set the C<yadis>, C<choose_logic> options add to Net::OpenID::Consumer's 
original options.
See the corresponding method descriptions below.

=back

=head1 METHODS

=over 4

=item $csr->B<yadis>($yadis_detector)

=item $csr->B<yadis>

Getter/setter for the Net::Yadis::Discovery (or subclass) instance which will
be used when find OpenID settings from OpenID URL by Yadis protocol.

It's highly recommended that, C<ua> and C<cache> options and methods are also
included at Net::Yadis::Discovery module, and you should set it not on 
Net::OpenID::Consumer::Yadis's options or methods but on Net::Yadis::Discovery's.
If do so, it is reuse in Net::OpenID::Consumer::Yadis.

=item $csr->B<choose_logic>($code_ref)

=item $csr->B<choose_logic>

Getter/setter for the choose only one OpenID server from some servers.
By default, servers are sorted by priority, and first server is selected.
Default logic is:

  sub { ($_[0]) }

If you want to use random server, set this logic to this method:

  sub { ($_[int(rand(@_))]) }

Logic's arguments are array of Net::Yadis::Object::OpenID objects.

=back

=head1 COPYRIGHT

This module is Copyright (c) 2006 OHTSUKA Ko-hei.
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.
If you need more liberal licensing terms, please contact the
maintainer.

=head1 WARRANTY

This is free software. IT COMES WITHOUT WARRANTY OF ANY KIND.

=head1 SEE ALSO

OpenID website:  http://www.openid.net/

Yadis website:  http://yadis.org/

L<Net::OpenID::Consumer> -- Superclass of this module

L<Net::Yadis::Discovery> -- Detecting setting of OpenID from OpenID URL

=head1 AUTHORS

OHTSUKA Ko-hei <nene@kokogiko.net>