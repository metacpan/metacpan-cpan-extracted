package Net::SMS::ASPSMS::XML;

use warnings;
use strict;
use Carp;
#use Unicode::String qw(utf8);
use overload q("") => \&as_string;

our $VERSION = '1.0.2';

my @valid_tags = qw(
  Userkey AffiliateId Password Originator UsedCredits
  Recipient_PhoneNumber Recipient_TransRefNumber
  DeferredDeliveryTime LifeTime MessageData URLBinaryFile
  FlashingSMS BlinkingSMS MCC MNC
  URLBufferedMessageNotification URLDeliveryNotification
  URLNonDeliveryNotification TimeZone XSer BinaryFileDataHex
  TransRefNumber ReplaceMessage
  VCard_VName VCard_VPhoneNumber
  WAPPushDescription WAPPushURL OriginatorUnlockCode Action
);

my %valid_tags = ();
@valid_tags{map {lc($_), $_} @valid_tags} = @valid_tags;

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = {};
    bless $self, $class;
    $self->initialize(@_);
    return $self;
}

sub initialize {
    my $self = shift;
    my $arg = defined($_[0]) && ref($_[0]) eq 'HASH' ? $_[0] : {@_};
    foreach (keys %$arg) {
        if (exists $valid_tags{lc($_)}) {
            $self->{data}->{lc($_)} = $arg->{$_} 
        }
    }
}

sub as_string {
    my $self = shift;
    my $encoding = shift;
    $encoding = "ISO-8859-1" if not defined $encoding;
    my $container = '';
    my $result = "<?xml version=\"1.0\" encoding=\"${encoding}\"?>\n";
    $result .= "<aspsms>\n";
    foreach (@valid_tags) {
        if (exists $self->{data}->{lc($_)}) {
            my ($c, $tag) = /^(.*)_(.*)/ ? ($1, $2) : ('', $_);
            my $content =  $self->{data}->{lc($_)};
            if ($c ne $container) {
                $result .= "  </$container>\n" if $container;
                $result .= "  <$c>\n" if $c;
                $container = $c;
            }
            #$content = utf8($content)->latin1;
            $content =~ s/([\x26\x3c\x3e\x80-\xff])/'&#' . ord($1) . ';'/xeg;
            $result .= "  " if $container;
            $result .= "  <$tag>" . $content . "</$tag>\n";
        }
    }
    $result .= "  </$container>\n" if $container;
    $result .= "</aspsms>";
    return $result
}

sub AUTOLOAD {
    my $self = shift or return undef;
    (my $method = our $AUTOLOAD) =~ s{.*::}{};
    return if $method eq 'DESTROY';
    if (exists $valid_tags{lc($method)} and defined $_[0]) {
        $self->{data}->{lc($method)} = $_[0]
    } else {
        croak "unknown method $method\n"
    }
}

1;
__END__

=head1 NAME

Net::SMS::ASPSMS::XML - XML generator for Net::SMS::ASPSMS


=head1 VERSION

This document describes Net::SMS::ASPSMS::XML version 1.0.2


=head1 SYNOPSIS

    use Net::SMS::ASPSMS::XML;

    my $xml = new Net::SMS::ASPSMS::XML(
        userkey=>"User",
        password=>"Secret"
    );

    $xml->Recipient_PhoneNumber("0123456789");

    $xml->MessageData("Hello World, île câblée");

    print $xml->as_string;


=head1 DESCRIPTION

Net::SMS::ASPSMS::XML provides an easy way to generate the XML data needed
by Net::SMS::ASPSMS.


=head1 BUGS AND LIMITATIONS

There are no known bugs in this module. 
Please report problems to Jacques Supcik C<< <supcik@cpan.org> >>.
Patches are welcome.


=head1 AUTHOR

Jacques Supcik  C<< <supcik@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013, Jacques Supcik C<< <supcik@cpan.org> >>.
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

