#!/usr/bin/perl

use strict;
use warnings;

use RT::Extension::ACNS::Test tests => 32;

my $cf_single;
{
    my $cf = RT::CustomField->new( $RT::SystemUser );
    my ($ret, $msg) = $cf->Create(
        Name  => 'TextSingle',
        Queue => 'General',
        Type  => 'TextSingle',
    );
    ok($ret, "created Custom Field");
    $cf_single = $cf;
}

my $cf_multiple;
{
    my $cf = RT::CustomField->new( $RT::SystemUser );
    my ($ret, $msg) = $cf->Create(
        Name  => 'FreeformMultiple',
        Queue => 'General',
        Type  => 'FreeformMultiple',
    );
    ok($ret, "created Custom Field");
    $cf_multiple = $cf;
}


my $full_sample = <<END;
<?xml version="1.0" encoding="iso-8859-1"?>
<Infringement xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="Infringement_schema-0.7.xsd">	
	<Case>
		<ID>A1234567</ID>
		<Ref_URL>http://www.contentowner.com/trackingid.asp?A1234567</Ref_URL>
		<Status>First Notice, Open</Status>
		<Severity>Normal</Severity>
	</Case>
	<Complainant>
		<Entity>Content Owner Inc.</Entity>
		<Contact>John Doe</Contact>
		<Address>100 Anywhere Street, Anywhere, CA 90000</Address>
		<Phone>555-555-1212</Phone>
		<Email>antipiracy\@contentowner.com</Email>
	</Complainant>
	<Service_Provider>
		<Entity>ISP Broadband Inc.</Entity>
		<Contact>John Doe</Contact>
		<Address>100 Anywhere Street, Anywhere, CA 90000</Address>
		<Phone>555-555-1212</Phone>
		<Email>dmca_agent\@ispbroadband.net</Email>
	</Service_Provider>
	<Source>
		<TimeStamp>2003-08-30T12:34:53Z</TimeStamp>
		<IP_Address>168.1.1.145</IP_Address>
		<Port>21</Port>
		<DNS_Name>pcp574.nshville.tn.ispbroadband.net</DNS_Name>
		<MAC_Address>00-00-39-B6-00-A4</MAC_Address>
		<IP_Block>?????</IP_Block>
		<Type>FTP</Type>
		<URL_Base>ftp://guest:freepwd\@168.1.1.145/media/8Mile/</URL_Base>
		<UserName>guest</UserName>
		<Login Username="guest" Password="freepwd"/>
		<Number_Files>324</Number_Files>
		<Deja_Vu>Yes</Deja_Vu>
	</Source>
	<Content>
		<Item>
			<TimeStamp>2003-08-30T12:34:53Z</TimeStamp>
			<Title>8 Mile</Title>
			<FileName>8Mile.mpg</FileName>
			<FileSize>702453789</FileSize>
			<URL>ftp://guest:freepwd\@168.1.1.145/media/8Mile/8mile.mpg</URL>
			<Type>Movie</Type>
			<Hash Type="SHA1">EKR94KF985873KD930ER4KD94</Hash>
		</Item>
		<Item>
			<TimeStamp>2003-08-30T12:34:53Z</TimeStamp>
			<Title>Lose Yourself</Title>
			<Artist>Eminem</Artist>
			<FileName>eminem_loseyourself.mp3</FileName>
			<FileSize>4235654</FileSize>
			<URL>ftp://guest:freepwd\@168.1.1.145/media/8Mile/eminem_loseyourself.mp3</URL>
			<Type>SoundRecording</Type>
			<Hash Type="SHA1">B5A94KF93673KD930D21DFD94</Hash>
		</Item>
	</Content>
	<History>
		<Notice ID="12321" TimeStamp="2003-08-30T10:23:13Z">freeform text area</Notice>
		<Notice ID="19832" TimeStamp="2003-08-30T11:03:00Z">freeform text area</Notice>
	</History>
	<Notes>
		Open area for freeform text notes, filelists, etc...
		
		drwxr-xr-x   2 staff    ftp           4096 May 15 13:21 morestuff
		-rw-r--r--   1 staff    ftp      702453789 Mar 24 15:34 8Mile.mpg
		-rw-r--r--   1 staff    ftp        4235654 Mar 24 07:44 eminem_loseyourself.mp3
		-rw-r--r--   1 staff    ftp        3914249 Apr  4 07:53 xzibit_spitshine.mp3
		-rw-r--r--   1 staff    ftp        1525267 Feb 24 16:39 50cent_wanksta.mp3
		-rw-r--r--   1 staff    ftp          25188 Feb 24 16:42 coverart.jpg
	</Notes>
</Infringement>
END

$full_sample = <<END;
Free form text

Start ACNS XML
$full_sample
- ----End ACNS XML

Free form ending
END

{
    my $content = <<END;
No ACNS
END
    my $ticket = RT::Ticket->new( $RT::SystemUser );
    my ($id, undef, $msg) = $ticket->Create(
        Queue => 'General',
        MIMEObj => MIME::Entity->build(
            Data => [ $content ],
        ),
    );
    ok($id, 'created a ticket');
    is($ticket->FirstCustomFieldValue($cf_single->id), undef, "no CF value");
    is($ticket->FirstCustomFieldValue($cf_multiple->id), undef, "no CF value");
}

{
    my $ticket = RT::Ticket->new( $RT::SystemUser );
    my ($id, undef, $msg) = $ticket->Create(
        Queue => 'General',
        MIMEObj => MIME::Entity->build(
            Data => [ $full_sample ],
        ),
    );
    ok($id, 'created a ticket');
    is($ticket->FirstCustomFieldValue($cf_single->id), undef, "no CF value");
    is($ticket->FirstCustomFieldValue($cf_multiple->id), undef, "no CF value");
}

{
    my $ticket = RT::Ticket->new( $RT::SystemUser );
    my ($id, undef, $msg) = $ticket->Create(
        Queue => 'General',
        MIMEObj => MIME::Entity->build(
            Data => [ $full_sample ],
        ),
    );
    ok($id, 'created a ticket');
    is($ticket->FirstCustomFieldValue($cf_single->id), undef, "no CF value");
    is($ticket->FirstCustomFieldValue($cf_multiple->id), undef, "no CF value");
}

RT->Config->Set(ACNS => Defaults => { $cf_single->id => 'test' } );
{
    my $ticket = RT::Ticket->new( $RT::SystemUser );
    my ($id, undef, $msg) = $ticket->Create(
        Queue => 'General',
        MIMEObj => MIME::Entity->build(
            Data => [ 'No ACNS message' ],
        ),
    );
    ok($id, 'created a ticket');
    is($ticket->FirstCustomFieldValue($cf_single->id), undef, "no CF value");
    is($ticket->FirstCustomFieldValue($cf_multiple->id), undef, "no CF value");
}
{
    my $ticket = RT::Ticket->new( $RT::SystemUser );
    my ($id, undef, $msg) = $ticket->Create(
        Queue => 'General',
        MIMEObj => MIME::Entity->build(
            Data => [ $full_sample ],
        ),
    );
    ok($id, 'created a ticket');
    is($ticket->FirstCustomFieldValue($cf_single->id), 'test', "CF value");
    is($ticket->FirstCustomFieldValue($cf_multiple->id), undef, "no CF value");
}

RT->Config->Set(ACNS =>
    Defaults => { $cf_single->id => 'test' },
    Map      => { $cf_single->id => [qw(NotExist)] },
);
{
    my $ticket = RT::Ticket->new( $RT::SystemUser );
    my ($id, undef, $msg) = $ticket->Create(
        Queue => 'General',
        MIMEObj => MIME::Entity->build(
            Data => [ $full_sample ],
        ),
    );
    ok($id, 'created a ticket');
    is($ticket->FirstCustomFieldValue($cf_single->id), undef, "no CF value");
    is($ticket->FirstCustomFieldValue($cf_multiple->id), undef, "no CF value");
}

RT->Config->Set(ACNS =>
    Map      => { $cf_single->id => [qw(Case ID)] },
);
{
    my $ticket = RT::Ticket->new( $RT::SystemUser );
    my ($id, undef, $msg) = $ticket->Create(
        Queue => 'General',
        MIMEObj => MIME::Entity->build(
            Data => [ $full_sample ],
        ),
    );
    ok($id, 'created a ticket');
    is($ticket->FirstCustomFieldValue($cf_single->id), 'A1234567', "CF value");
    is($ticket->FirstCustomFieldValue($cf_multiple->id), undef, "no CF value");
}

RT->Config->Set(ACNS =>
    Map      => { $cf_multiple->id => [qw(Content Item * URL)] },
);
{
    my $ticket = RT::Ticket->new( $RT::SystemUser );
    my ($id, undef, $msg) = $ticket->Create(
        Queue => 'General',
        MIMEObj => MIME::Entity->build(
            Data => [ $full_sample ],
        ),
    );
    ok($id, 'created a ticket');
    is($ticket->FirstCustomFieldValue($cf_single->id), undef, "CF value");
    is_deeply(
        [ sort map $_->Content, @{ $ticket->CustomFieldValues($cf_multiple->id)->ItemsArrayRef } ],
        [ 
            'ftp://guest:freepwd@168.1.1.145/media/8Mile/8mile.mpg',
            'ftp://guest:freepwd@168.1.1.145/media/8Mile/eminem_loseyourself.mp3',
        ],
        "CF value"
    );
}

RT->Config->Set(ACNS =>
    Map      => { $cf_single->id => [qw(Content Item * URL)] },
);
{
    my $ticket = RT::Ticket->new( $RT::SystemUser );
    my ($id, undef, $msg) = $ticket->Create(
        Queue => 'General',
        MIMEObj => MIME::Entity->build(
            Data => [ $full_sample ],
        ),
    );
    ok($id, 'created a ticket');
    is(
        $ticket->FirstCustomFieldValue($cf_single->id),
        join( "\n",
            'ftp://guest:freepwd@168.1.1.145/media/8Mile/8mile.mpg',
            'ftp://guest:freepwd@168.1.1.145/media/8Mile/eminem_loseyourself.mp3',
        ),
        "CF value"
    );
    is($ticket->FirstCustomFieldValue($cf_multiple->id), undef, "no CF value");
}
