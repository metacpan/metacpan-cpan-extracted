use strict;
use warnings;

use Test::More tests => 27;
use DateTime;

use_ok('Net::Lighthouse::Project::Ticket::Attachment');
can_ok( 'Net::Lighthouse::Project::Ticket::Attachment', 'new' );

my $attachment = Net::Lighthouse::Project::Ticket::Attachment->new;
isa_ok( $attachment, 'Net::Lighthouse::Project::Ticket::Attachment' );

my @attrs = (
    'width',        'created_at',  'height',   'size',
    'content_type', 'uploader_id', 'filename', 'url',
    'id',           'code',        'content',  'ua',
);

for my $attr (@attrs) {
    can_ok( $attachment, $attr );
}

can_ok( $attachment, 'load_from_xml' );

my $xml = do {
    local $/;
    open my $fh, '<', 't/data/ticket_1_attachment_1.xml' or die $!;
    <$fh>;
};
my $v1 = $attachment->load_from_xml($xml);
is( $v1, $attachment, 'load returns $self' );
my %hash = (
    'width'        => undef,
    'uploader_id'  => 67166,
    'height'       => undef,
    'size'         => 24,
    'content_type' => 'application/octet-stream',
    'created_at'   => DateTime->new( 
        year   => 2009,
        month  => 8,
        day    => 21,
        hour   => 11,
        minute => 15,
        second => 51,
    ),
    'filename'     => 'first',
    'url'  => 'http://sunnavy.lighthouseapp.com/attachments/249828/first',
    'id'   => 249828,
    'code' => '5ace4f26de37855e951eb13f5b07a1b1a0919466'

);

for my $k ( keys %hash ) {
    is_deeply( $v1->$k, $hash{$k}, "$k is loaded" );
}
