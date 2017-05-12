use warnings;
use strict;

package Net::Whois::SIDN;
use base 'XML::Compile::Cache';

our $VERSION = '0.98';

use XML::Compile::Util qw/type_of_node unpack_type pack_type/;
use Log::Report    'net-whois-sidn', syntax => 'SHORT';

use Net::Whois::SIDN::Util;
use HTTP::Status   qw/RC_OK/;
use LWP::UserAgent ();

my $service_public     = 'http://whois.domain-registry.nl';
my $service_registered = 'http://rwhois.domain-registry.nl';

=head1 NAME

Net::Whois::SIDN - whois for .nl TLD via XML interface

=head1 INHERITANCE

  Net::Whois::SIDN
  is a XML::Compile::Cache
  is a XML::Compile::Schema
  is a XML::Compile

=head1 SYNOPSIS

  my $whois  = Net::Whois::SIDN->new(drs_version => '5.0');
  my $answer = $whois->is('sidn.nl');
  my $answer = $whois->whois('sidn.nl');

  use Data::Dumper;
  warn Dumper $answer;

=head1 DESCRIPTION

Implementation (both usable for client and server side), of the XML
version of the whois interface, as provided by the Dutch ccTLD
registry SIDN (the C<.nl> top-level domain).

Documentation is included in this distribution (in the F<doc/>
directory), and in nicely printed form via the ISP participants
wiki. Don't forget to look at the F<examples/> directory.

=cut

# map namespace always to the newest implementation of the protocol
my %ns2version =
 ( &NS_WHOIS_DRS50 => '5.0'
 );

my %version2ns = reverse %ns2version;

#---------------

=head1 METHODS

=head2 Constructor

First, create an object which contains the information for the
connection.

=over 4

=item my $whois = Net::Whois::SIDN->new(@opts);

The C<drs_version> parameter is required. When new versions of the SIDN
core implementation (DRS) are introduced, you may have to convert your
application.  In that case, SIDN will provide a test environment with
a server using a newer scheme before the change goes public.

With options C<role> set to C<SERVER>, you will accept queries and produce
responses.  For all other values, the module behaves as client. The
default role is C<REGISTERED>. The other valid value is C<PUBLIC>. however
SIDN does not (yet) support XML output on the public interface.

Option C<service> changes the url of the default server which will answer
the queries. You may pass your own C<user_agent> (an L<LWP::UserAgent>
instance).

Use option C<trace>, set to a trueth value, to see the message sent and
received. Client-side only.

This object extents L<XML::Compile::Cache>, so there are a lot of additional
parameters.  However, you will probably not need them.


=cut

my %roles = map { $_ => 1 } qw/SERVER PUBLIC REGISTERED/;

sub new($)
{   my $class = shift;
    $class->SUPER::new(direction => 'RW', @_);
}

sub init($)
{   my ($self, $args) = @_;
#   $args->{allow_undeclared} = 1
#       unless exists $args->{allow_undeclared};

    $args->{opts_readers} = { @{$args->{opts_readers}} }
        if ref $args->{opts_readers} eq 'ARRAY';

    $args->{opts_rw}      = { @{$args->{opts_rw}} }
        if ref $args->{opts_rw} eq 'ARRAY';
    $args->{opts_rw}{sloppy_floats}   = 1;  # only small floats
    $args->{opts_rw}{sloppy_integers} = 1;  # only small ints

    my $version = $self->{version} = $args->{drs_version}
        or error __x"object requires an explicit drs version";

    my $ns = $version2ns{$version}
        or error __x"unsupported DRS version {v}", v => $version;
    $args->{prefixes} = [ '' => $ns, whois => $ns ];

    $self->SUPER::init($args);

    $self->prefixes(whois => $ns);
    $self->addKeyRewrite('UNDERSCORES');

    $version =~ s/\.//;
    (my $xsd = __FILE__) =~ s!\.pm!/xsd/whois-drs$version.xsd!;
    $self->importDefinitions($xsd);

    my $role = $self->{role} = $args->{role} || 'REGISTERED';
    $roles{$role}
        or error __x"no such role: `{role}'", role => $role;

    my ($cs, $ss);
    if($role eq 'SERVER')
    {   # configure as server
        ($cs, $ss)  = ('READER', 'WRITER');
    }
    else
    {   # configure as client
        ($cs, $ss)    = ('WRITER', 'READER');
        $self->{ua}   = $args->{user_agent} || LWP::UserAgent->new;
        $self->{service} = $args->{service} ||
          ( $role eq 'PUBLIC'     ? $service_public
          : $role eq 'REGISTERED' ? $service_registered
          :                         undef
          );
        $self->{trace} = $args->{trace};
    }

    $self->declare($cs, [ qw/whois:whois-query    whois:is-query/    ]);
    $self->declare($ss, [ qw/whois:whois-response whois:is-response/ ]);
    $self;
}

#----------

=back

=head2 Accessors

=over 4

=item $whois->version

=item $whois->namespace

=item $whois->role

=item $whois->userAgent

=item $whois->service('is'|'whois')

=cut

sub version()   {shift->{version}}
sub namespace() {shift->{namespace}}
sub role()      {shift->{role}}
sub userAgent() {shift->{ua}}
sub service($)  {$_[0]->{service}.'/'.$_[1]}

#--------

=back

=head2 Client actions

=over 4

=item my ($rc, $data) = $obj->whois('sidn.nl', %opts)

When C<$rc> equals 0, then there are no errors and C<$data> will refer
to the HASH containing the result. Otherwise, C<$rc> is an error code,
defined as HTTP error codes and C<$data> an error text.

The C<%opts> are parameter pairs. Defined keys are: C<lang> (language
EN or NL, default EN), C<output_format> (PLAIN, HTML, and the default XML)
and C<usertext_format> (PLAIN or HTML).

Example:

   my ($rc, $data) = $whois->whois('sidn.nl');
   $rc==0 or die "Error: $data";

   print $data->{domain}{status}{code}, "\n";
  
The distribution package contains an extended realistic example of
the data structure as made available in Perl.

=item my ($rc, $data) = $obj->is('sidn.nl', %opts)

The C<is()> works exactly the same as the C<whois()>, but produces a
shorter answer.

=cut

sub _call($$)
{   my ($self, $action, $data_out) = @_;

    my $xmlout   = $self->create("whois:$action-query" => $data_out);

    my $request  = HTTP::Request->new
      ( POST => $self->service($action)
      , [ X_Net_Whois_SIDN => $VERSION
        , Content_Type     => 'text/xml; charset="utf-8"'
        , Connection       => 'open'
        ]
      , $xmlout->toString(1)
      );

    print "\n==> Request\n", $request->as_string
        if $self->{trace};

    my $response = $self->userAgent->request($request);
    print "\n--> Response\n", $response->as_string
        if $self->{trace};

    my $content  = $response->decoded_content || $response->content;

    my $rc = $response->code;
    $rc == RC_OK
        or return ($rc, "Error: $rc = "
           . ($response->header('Client-Warnings') || $content));

    my $ct = $response->content_type;
    $ct eq 'text/xml'
        or return (-1, "Error: expect xml, but got $ct");

    my ($type, $data_in) = $self->from($content);
    (0, $data_in);
}

sub is($@)
{   my ($self, $domain, @args) = @_;
    $self->_call(is => {domain => $domain, @args});
}

sub whois($@)
{   my ($self, $domain, @args) = @_;
    $self->_call(whois => {domain => $domain, @args});
}

=back

=head2 Helpers

=over 4

=item my $xml = $obj->create($type, $data);

Pass a correctly constructed Perl C<$data> nested HASH, which suites
to the C<$type>, which is C<whois:{whois,is}-{query,response}>. See
the examples provided by the distribution.

  my $xml = $whois->create($type, $data);
  print $xml->toString(1);

=cut

sub create($$)
{   my ($self, $type, $data) = @_;
    my $doc  = XML::LibXML::Document->new('1.0', 'UTF-8');
    my $wr   = $self->writer($type) or return;
    my $root = $wr->($doc, $data);
    $doc->setDocumentElement($root);
    $doc;
}

=item $class->from($data, [@opts]);

=item $obj->from($data, [@opts]);

Read an XML message from C<$data>, in any format supported by
L<XML::Compile> method C<dataToXML()>: string, file, filehandle, and more.
Returned is a list of two: the type of the top-level element plus the
data-structure.

When called as instance method, the data will automatically get converted
to the version of required by the object.  When called as class method,
the version of the top-level element will determine the returned version
automatically (which may give unpredictable versions as result).

When the method is called as class method, then a temporary instance is
created.  Creating an instance is (very) slow.

Examples:

  my $whois = Net::Whois::SIDN->new(drs_version => '3.14');
  my ($type, $data) = $whois->from('data.xml');

or

  my ($type, $data) = Net::Whois::SIDN->from('data.xml');

=cut

sub from($@)
{   my ($thing, $source, %args) = @_;

    my $xml  = XML::Compile->dataToXML($source);
    my $top  = type_of_node $xml;

    my ($ns, $topname) = unpack_type $top;
    my $version = $ns2version{$ns}
       or error __x"unknown version with namespace {ns}", ns => $ns;

    my ($self, $convert);
    if(ref $thing)
    {   # instance method
        $self    = $thing;
        $convert = 1;
    }
    else
    {   # class method: can determine version myself
        $self    = $thing->new(drs_version => $version, %args);
        $convert = 0;
    }

    my $r  = $self->reader($top, %args)
        or error __x"root node `{top}' not recognized", top => $top;

    my $data = $r->($xml);
    ($top, $data);
}

=back

=head1 COPYRIGHT

Copyright 2010 Mark Overmeer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


1;
