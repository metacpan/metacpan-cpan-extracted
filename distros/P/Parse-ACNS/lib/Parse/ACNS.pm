use 5.008;
use strict;
use warnings;


package Parse::ACNS;
our $VERSION = '1.00';

=head1 NAME

Parse::ACNS - parser for Automated Copyright Notice System (ACNS) XML

=head1 SYNOPSIS

    use Parse::ACNS;
    my $data = Parse::ACNS->new->parse( XML::LibXML->load_xml( string => $xml ) );

=head1 DESCRIPTION

ACNS stands for Automated Copyright Notice System. It's an open source,
royalty free system that universities, ISP's, or anyone that handles large
volumes of copyright notices can implement on their network to increase
the efficiency and reduce the costs of responding to the notices...

See L<http://acns.net> for more details.

This module parses ACNS XML into a perl data structure. Supports 1.2, 1.1, 1.0,
0.7 and 0.6 revisions of the spec. Parser strictly follows XML Schemas, so throws
errors on malformed data.

However, it B<doesn't> extract ACNS XML from email messages.

=head1 SOME ACNS BACKGROUND

L<NBC Universal and UMG|http://mpto.unistudios.com/xml/> released two revisions
of the spec (0.6 and 0.7).

L<Motion Picture Laboratories, Inc.|http://www.movielabs.com/ACNS> took over
and named it ACNS 2.0 and released revisions 1.0, 1.1 and several sub-revisions with
letters (1.1f, 1.1j, 1.1p).

Then it was moved once again to L<http://www.acns.net/spec.html> and revision 1.2
was released.

=cut

use File::ShareDir ();
use File::Spec ();
use Scalar::Util qw(blessed);
use XML::Compile::Schema;

our %CACHE = (
);

=head1 METHODS

=head2 new

Constructor, takes list of named arguments.

=over 4

=item version - version of the specification

=over 4

=item compat

default value, can parse 1.2 to 0.6 XML. Revision 1.2 is backwards
compatible with 0.7. Compat schema makes TimeStamp in Infringement/Content/Item
optional to make it compatible with 0.6 revision. Everything else new in 1.2 is
optional.

=item 1.2, 1.1, 1.0, 0.7 or 0.6

strict parsing of the specified version.

=back

=back

=cut

sub new {
    my $proto = shift;
    return (bless { @_ }, ref($proto) || $proto)->init;
}

sub init {
    my $self = shift;

    $self->{'version'} ||= 'compat';
    unless ( $self->{'version'} =~ /^(compat|0\.[67]|1\.[0-2])$/ ) {
        require Carp;
        Carp::croak(
            "Only compat, 1.2, 1.1, 1.0, 0.7 and 0.6 versions are supported"
            .", not '". $self->{'version'} ."'"
        );
    }

    return $self;
}

=head2 parse

    my $data = Parse::ACNS->new->parse( XML::LibXML->load_xml(...) );

Takes L<XML::LibXML::Document> containing an ACNS XML and returns it as a perl
struture. Read L<XML::LibXML::Parser> on parsing from different sources.

Newer versions of the spec describe more messages besides
C<< <Infringement> >>, for example C<< <StatusUpdate> >>. Top level element
is not returned as part of the result, but you always can get it from XML
document:

    $xml_doc->documentElement->nodeName;

To simplify implementation of compat version parsing document can be
changed. At this moment XML namespace is adjusted on all elements.

Returned data structure follows XML and its Schema, for example:

    {
        'Case' => {
            'ID' => 'A1234567',
            'Status' => ...,
            ...
        },
        'Complainant' => {
            'Email' => 'antipiracy@contentowner.com',
            'Phone' => ...,
            ...
        },
        'Source' => {
            'TimeStamp' => '2003-08-30T12:34:53Z',
            'UserName' => 'guest',
            'Login' => { ... },
            'IP_Address' => ...,
            ...
        }
        'Service_Provider' => { ... }
        'Content' => {
            'Item' => [
                {
                    'TimeStamp' => '2003-08-30T12:34:53Z',
                    'FileName' => '8Mile.mpg',
                    'Hash' => {
                            'Type' => 'SHA1',
                            '_' => 'EKR94KF985873KD930ER4KD94'
                          },
                    ...
                },
                { ... },
                ...
            ]
        },
        'History' => {
            'Notice' => [
                {
                    'ID' => '12321',
                    'TimeStamp' => '2003-08-30T10:23:13Z',
                    '_' => 'freeform text area'
                },
                { ... },
                ...
            ]
        },
        'Notes' => '
            Open area for freeform text notes, filelists, etc...
        '
    }

=cut

sub parse {
    my $self = shift;
    my $xml = shift;
    my $element = $xml->documentElement->nodeName;
    if ( $self->{'version'} eq 'any' ) {
        foreach my $v (qw(1.2 1.1 1.0 0.7 0.6)) {
            local $@;
            my $res;
            return $res if eval { $res = $self->reader($v, $element)->($xml); 1 };
        }
    }
    elsif ( $self->{'version'} eq 'compat' ) {
        my $root = $xml->documentElement;
        my $uri = $root->namespaceURI || '';
        if ( !$uri || ($uri eq 'http://www.movielabs.com/ACNS' && !$root->can('setNamespaceDeclURI')) ) {
            my $list = $root->getElementsByTagNameNS($uri, '*');
            $list->unshift($root);
            $list->foreach(sub {
                $_->setNamespace('http://www.acns.net/ACNS', $root->prefix, 1);
            });
        }
        elsif ( $uri eq 'http://www.movielabs.com/ACNS' ) {
            $root->setNamespaceDeclURI($root->prefix, 'http://www.acns.net/ACNS');
        }
        elsif ( $uri eq 'http://www.acns.net/ACNS' ) {
            # do nothing
        }
        elsif ( $uri =~ m{^http://www\.acns\.net\b}i ) {
            $root->setNamespaceDeclURI($root->prefix, 'http://www.acns.net/ACNS');
        }
        else {
            die "Top level element has '$uri' namespace and it's not something we can parse as ACNS";
        }
        return $self->reader($self->{'version'}, $element)->($xml);
    }
    else {
        return $self->reader($self->{'version'}, $element)->($xml);
    }
    return undef;
}

my %NS = (
    '1.0' => 'http://www.movielabs.com/ACNS',
    '1.1' => 'http://www.movielabs.com/ACNS',
    '1.2' => 'http://www.acns.net/ACNS',
    'compat' => 'http://www.acns.net/ACNS',
);
my %SUPLIMENTARY = (
    '1.0' => ['xmlmime'],
    '1.1' => ['xmlmime'],
    '1.2' => ['xmlmime', 'xmldsig'],
);

sub reader {
    my $self = shift;
    my $version = shift;
    my $element = shift || 'Infringement';

    return $CACHE{$version}{'element'}{$element}
        if $CACHE{$version}{'element'}{$element};

    my $schema = $CACHE{$version}{'schema'} ||= do {
        my @paths;
        push @paths, File::ShareDir::dist_file(
            'Parse-ACNS',
            File::Spec->catfile( 'schema', $version, 'acns.xsd' )
        );
        if ( $SUPLIMENTARY{$version} ) {
            push @paths, map File::ShareDir::dist_file(
                'Parse-ACNS',
                File::Spec->catfile( 'schema', "$_.xsd" )
            ), @{$SUPLIMENTARY{$version}};
        }
        XML::Compile::Schema->new( \@paths );
    };

    use XML::Compile::Util qw/pack_type/;
    return $CACHE{$version}{'element'}{$element}
            = $schema->compile( READER => pack_type( $NS{$version}, $element ) );

}

=head1 AUTHOR

Ruslan Zakirov E<lt>ruz@bestpractical.comE<gt>

=head1 LICENSE

Under the same terms as perl itself.

=cut

1;
