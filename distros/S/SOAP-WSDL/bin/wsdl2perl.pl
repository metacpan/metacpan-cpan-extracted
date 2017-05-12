#!/usr/bin/perl -w
use strict;
use warnings;
use Pod::Usage;
use Getopt::Long;
use LWP::UserAgent;
use SOAP::WSDL::Expat::WSDLParser;
use SOAP::WSDL::Factory::Generator;
use Term::ReadKey;

my %opt = (
  url => '',
  prefix            => 'My',
  attribute_prefix  => undef,
  type_prefix       => undef,
  element_prefix    => undef,
  typemap_prefix    => undef,
  interface_prefix  => undef,
  server_prefix     => undef,
  base_path => 'lib/',
  proxy => undef,
  generator => 'XSD',
  server => 0,
  namespace => 0,
);

{   # a block just to scope "no warnings"
    no warnings qw(redefine);

    *LWP::UserAgent::get_basic_credentials = sub {
        my ($user, $password);
        # remove user from option if called, to force prompting for a user
        # name the next time
        print "URL requires authorization.\n";
        if (not $user = delete $opt{user}) {
            print 'User name:';
            ReadMode 1;
            $user =  ReadLine();
            ReadMode 0;
            chomp $user;
        };
        if (not $password = delete $opt{password}) {
            print 'Password:';
            ReadMode 2;
            $password = ReadLine;
            ReadMode 0;
            chomp $password;
        };
        return ($user, $password);
    };
}

GetOptions(\%opt,
  qw(
    prefix|p=s
    attribute_prefix|a=s
    type_prefix|t=s
    element_prefix|e=s
    typemap_prefix|m=s
    interface_prefix|i=s
    server_prefix|sp=s
    base_path|b=s
    typemap_include|mi=s
    help|h
    proxy|x=s
    keep_alive
    user=s
    password=s
    generator=s
    server|s
    namespaces|n
  )
);

my $url = $ARGV[0];

pod2usage( -exit => 1 , verbose => 2 ) if ($opt{help});
pod2usage( -exit => 1 , verbose => 1 ) if not ($url);

local $ENV{HTTP_PROXY} = $opt{proxy} if $opt{proxy};
local $ENV{HTTPS_PROXY} = $opt{proxy} if $opt{proxy};

my $lwp = LWP::UserAgent->new(
    $opt{keep_alive}
        ? ( keep_alive => 1 )
        : ()
    );
$lwp->env_proxy();  # get proxy from environment. Works for both http & https.
$lwp->agent(qq[SOAP::WSDL $SOAP::WSDL::Expat::WSDLParser::VERSION]);

my $parser = SOAP::WSDL::Expat::WSDLParser->new({
    user_agent => $lwp,
});

# resolve the default prefix options
map {
    my $opt_key = $_;
    if ( $opt_key =~ / (\w+) _prefix $/xms # relevant option
            && !$opt{ $opt_key }           # that hasn't already been explicitly set
        )
    {
        my $prefix_type = $1;
        $opt{ $opt_key } = $opt{prefix} .                           # My
                           ucfirst( $prefix_type ) .                # Typemap
                           ( $prefix_type eq 'server' ? '' : 's' ); # s
    }
} keys %opt;

my $definitions = $parser->parse_uri( $url );

my %typemap = ();

if ($opt{typemap_include}) {
  die "$opt{typemap_include} not found " if not -f $opt{typemap_include};
  %typemap = do $opt{typemap_include};
}

my $generator = SOAP::WSDL::Factory::Generator->get_generator({ type => $opt{'generator'} });

if (%typemap) {
    if ($generator->can('set_typemap')) {
        $generator->set_typemap( \%typemap );
    }
    else {
        warn "Typemap snippet given, but generator does not support it\n";
    }
};

$generator->set_attribute_prefix( $opt{ attribute_prefix })
    if $generator->can('set_attribute_prefix');
$generator->set_type_prefix( $opt{ type_prefix })
    if $generator->can('set_type_prefix');
$generator->set_typemap_prefix( $opt{ typemap_prefix })
    if $generator->can('set_typemap_prefix');
$generator->set_element_prefix($opt{ element_prefix })
    if $generator->can('set_element_prefix');
$generator->set_interface_prefix($opt{ interface_prefix })
    if $generator->can('set_interface_prefix');
$generator->set_server_prefix($opt{ server_prefix })
    if $generator->can('set_server_prefix');
$generator->set_OUTPUT_PATH($opt{ base_path })
    if $generator->can('set_OUTPUT_PATH');
$generator->set_definitions($definitions)
    if $generator->can('set_definitions');
# $generator->set_wsdl($xml) if $generator->can('set_wsdl');

# start with typelib, as errors will most likely occur here...
$generator->generate();
$generator->generate_interface() if ! $opt{server};
$generator->generate_server() if $opt{server};
__END__

=pod

=head1 NAME

wsdl2perl.pl - create perl bindings for SOAP webservices.

=head1 SYNOPSIS

 wsdl2perl.pl -t TYPE_PREFIX -e ELEMENT_PREFIX -m TYPEMAP_PREFIX \
   -i INTERFACE_PREFIX -b BASE_DIR URL

=head1 OPTIONS

 NAME            SHORT  DESCRITPION
 ----------------------------------------------------------------------------
 prefix            p   Prefix for all generated classes. If you set "-p=Foo",
                       you will get "FooAttributes", "FooTypes",
					   "FooElements" and so on.
 attribute_prefix  a   Prefix for XML attribute classes.
                       Default: MyAttributes
 type_prefix       t   Prefix for type classes.
                       Default: MyTypes
 element_prefix    e   Prefix for element classes.
                       Default: MyElements
 typemap_prefix    m   Prefix for typemap classes.
                       Default: MyTypemaps
 interface_prefix  i   Prefix for interface classes.
                       Default: MyInterfaces
 server_prefix     sp  Prefix for server classes.
                       Default: MyServer
 base_path         b   Path to create classes in.
                       Default: .
 typemap_include   mi  File to include in typemap. Must eval() to a valid
                       perl hash (not a hash ref !).
 proxy             x   HTTP(S) proxy to use (if any). wsdl2perl will also
                       use the proxy settings specified via the HTTP_PROXY
                       and HTTPS_PROXY environment variables.
 keep_alive            Use http keep_alive.
 user                  Username for HTTP authentication
 password              Password. wsdl2perl will prompt if not given.
 generator         g   Generator to use.
                       Default: XSD
 server            s   Generate a server interface (currently only CGI
                       supported)
 help              h   Show help content

=head1 DESCRIPTION

Generates a interface class for a SOAP web service described by a WSDL
definition.

The following classes are created:

=over

=item * A interface class for every SOAP port in service

Interface classes are what you will mainly deal with: They provide a method
for accessing every web service method.

If you chose to generate Server interfaces, a class for every SOAP port in
every Web service.

You'll have to implement a method for each of the implemented methods. You
may implement these methods in the CGI script / handler, or in any class
to dispatch calls to.

=item * A typemap for every service

Typemaps are used internally by SOAP::WSDL for parsing the SOAP message into
object trees.

If the WSDL definition is incomplete, you may need to add some lines to
your typemap. Especially definitions for faults are sometimes left out.

Additional typemap content may be included by passing a file name as
typemap_include (mi) option.

=item * A type class for every element, complexType or simpleType definition

You may need to write additional type classes if your WSDL is incomplete.

For writing your own lib classes, see L<SOAP::WSDL::XSD::Typelib::Element>,
L<SOAP::WSDL::XSD::Typelib::ComplexType>
and L<SOAP::WSDL::XSD::Typelib::SimpleType>.

=back

=head1 TROUBLESHOOTING

=head2 Accessing HTTPS URLs

You need Crypt::SSLeay installed for accessing HTTPS URLs.

=head2 Accessing protected documents

Use the -u option for specifying the user name. You will be prompted for a
password.

Alternatively, you may specify a passowrd with --password on the command
line.

=head2 Accessing documents protected by NTLM authentication

Set the --keep_alive option.

Note that accessing documents protected by NTLM authentication is currently
untested, because I have no access to a system using NTLM authentication.
If you try it, I would be glad if you could just drop me a note about
success or failure.

=head1 LICENSE

Copyright 2007 Martin Kutter.

This file is part of SOAP-WSDL. You may distribute/modify it under
the same terms as perl itself

=head1 AUTHOR

Martin Kutter E<lt>martin.kutter fen-net.deE<gt>

=cut
