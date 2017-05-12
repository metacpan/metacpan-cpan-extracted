#!/usr/bin/perl

use Test::More tests => 133;
use Carp;

use strict;
use warnings;

use Net::DAV::Server ();
use Net::DAV::LockManager::Simple ();
use XML::LibXML;
use XML::LibXML::XPathContext;
use URI::Escape;

my $parser = XML::LibXML->new();

{
    package Mock::Filesys;
    sub new {
        return bless {
            '/' =>               [ 0, 0, 040777, 2, 1, 1, 0,    0, (time)x3, 1024, 1 ],
            '/foo' =>            [ 0, 0, 040777, 2, 1, 1, 0,    0, (time)x3, 1024, 1 ],
            '/foo/bar' =>        [ 0, 0, 040777, 2, 1, 1, 0,    0, (time)x3, 1024, 1 ],
            '/test.html' =>      [ 0, 0, 0666,   1, 1, 1, 0, 1024, (time)x3, 1024, 1 ],
            '/foo/index.html' => [ 0, 0, 0666,   1, 1, 1, 0, 2048, (time)x3, 1024, 2 ],
            '/bar' =>            [ 0, 0, 040777, 2, 1, 1, 0,    0, (time)x3, 1024, 1 ],
            '/テスト' =>         [ 0, 0, 0666,   1, 1, 1, 0,  128, (time)x3, 1024, 1 ],
        };
    }
    sub test {
        my ($self, $op, $path) = @_;
        if ( $op eq 'e' ) {
            return exists $self->{$path};
        }
        elsif ( $op eq 'd' ) {
            return unless exists $self->{$path};
            return (($self->{$path}->[2]&040000) ? 1 : 0);
        }
        else {
            die "Operation $op not implemented.";
        }
    }
    sub stat {
        my ($self, $path) = @_;

        return unless exists $self->{$path};
        return @{$self->{$path}};
    }
    sub list {
        my ($self, $dir) = @_;
        my @ls;
        my $match = $dir eq '/' ? $dir : "$dir/";
        return map { substr( $_, length $match ) }
            grep { $_ ne $dir && m{^$match[^/]+$} }
            sort keys %{$self};
    }
}

# Missing resource
{
    my $label = 'Missing item, default';
    my $path = '/fred';
    my $dav = Net::DAV::Server->new( -filesys => Mock::Filesys->new(), -dbobj => Net::DAV::LockManager::Simple->new() );
    my $fs = $dav->filesys;

    ok( !$fs->test( 'e', $path ), "$label: target does not initially exist" );
    my $req = propfind_request( $path );

    my $resp = $dav->propfind( $req, HTTP::Response->new( 200, 'OK' ) );
    is( $resp->code, 404, "$label: Response is 'Not Found'" );
}

{
    my $label = 'Missing resource, allprop';
    my $path = '/fred';
    my $dav = Net::DAV::Server->new( -filesys => Mock::Filesys->new(), -dbobj => Net::DAV::LockManager::Simple->new() );
    my $fs = $dav->filesys;

    ok( !$fs->test( 'e', $path ), "$label: target does not initially exist" );
    my $req = propfind_request(
        $path,
        '<D:propfind xmlns:D="DAV:"><D:allprop/></D:propfind>'
    );

    my $resp = $dav->propfind( $req, HTTP::Response->new( 200, 'OK' ) );
    is( $resp->code, 404, "$label: Response is 'Not Found'" );
}

{
    my $label = 'Missing resource, propname';
    my $path = '/fred';
    my $dav = Net::DAV::Server->new( -filesys => Mock::Filesys->new(), -dbobj => Net::DAV::LockManager::Simple->new() );
    my $fs = $dav->filesys;

    ok( !$fs->test( 'e', $path ), "$label: target does not initially exist" );
    my $req = propfind_request(
        $path,
        '<D:propfind xmlns:D="DAV:"><D:propname/></D:propfind>'
    );

    my $resp = $dav->propfind( $req, HTTP::Response->new( 200, 'OK' ) );
    is( $resp->code, 404, "$label: Response is 'Not Found'" );
}

# Directory
{
    my $label = 'Depth 1 dir, default';
    my $path = '/foo';
    my $dav = Net::DAV::Server->new( -filesys => Mock::Filesys->new(), -dbobj => Net::DAV::LockManager::Simple->new() );
    my $fs = $dav->filesys;

    ok( $fs->test( 'e', $path ), "$label: root directory exists" );
    my $req = propfind_request( $path );

    my $resp = $dav->propfind( $req, HTTP::Response->new( 200, 'OK' ) );
    is( $resp->code, 207, "$label: Response is 'Multi-Status'" );
    my $xpc = get_xml_context( $resp->content );
    has_text( $xpc, '/D:multistatus/D:response/D:href', "$path/", "$label: Path is correct" );
    has_text( $xpc, '/D:multistatus/D:response/D:propstat/D:status', 'HTTP/1.1 200 OK', "$label: Status is correct" );
    has_nodes( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop[1]',
        [ qw/creationdate getcontentlength getcontenttype getlastmodified supportedlock resourcetype/ ],
        "$label: Property nodes"
    );
    like_text( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop[1]/D:creationdate',
        qr/^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d$/,
        "$label: Date/time format is correct"
    );
    has_node( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:supportedlock/D:lockentry/D:lockscope/D:exclusive',
        "$label: supports exclusive lock scope"
    );
    hasnt_node( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:supportedlock/D:lockentry/D:lockscope/D:shared',
        "$label: shared lock scope not supported"
    );
    has_text( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:getcontenttype',
        'httpd/unix-directory',
        "$label: content type is correct"
    );
    like_text( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop[1]/D:getlastmodified',
        qr/^\w\w\w, \d\d? \w\w\w \d\d\d\d \d\d:\d\d:\d\d \w+$/,
        "$label: Date/time format is correct"
    );
    has_node( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:resourcetype/D:collection',
        "$label: resource type is correct"
    );
}

{
    my $label = 'Depth 1 dir, allprop';
    my $path = '/foo';
    my $dav = Net::DAV::Server->new( -filesys => Mock::Filesys->new(), -dbobj => Net::DAV::LockManager::Simple->new() );
    my $fs = $dav->filesys;

    ok( $fs->test( 'e', $path ), "$label: root directory exists" );
    my $req = propfind_request(
        $path,
        '<D:propfind xmlns:D="DAV:"><D:allprop/></D:propfind>'
    );

    my $resp = $dav->propfind( $req, HTTP::Response->new( 200, 'OK' ) );
    is( $resp->code, 207, "$label: Response is 'Multi-Status'" );
    my $xpc = get_xml_context( $resp->content );
    has_text( $xpc, '/D:multistatus/D:response/D:href', "$path/", "$label: Path is correct" );
    has_text( $xpc, '/D:multistatus/D:response/D:propstat/D:status', 'HTTP/1.1 200 OK', "$label: Status is correct" );
    has_nodes( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop[1]',
        [ qw/creationdate getcontentlength getcontenttype getlastmodified supportedlock resourcetype/ ],
        "$label: Property nodes"
    );
    like_text( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop[1]/D:creationdate',
        qr/^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d$/,
        "$label: Date/time format is correct"
    );
    has_node( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:supportedlock/D:lockentry/D:lockscope/D:exclusive',
        "$label: supports exclusive lock scope"
    );
    hasnt_node( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:supportedlock/D:lockentry/D:lockscope/D:shared',
        "$label: shared lock scope not supported"
    );
    has_text( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:getcontenttype',
        'httpd/unix-directory',
        "$label: content type is correct"
    );
    like_text( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop[1]/D:getlastmodified',
        qr/^\w\w\w, \d\d? \w\w\w \d\d\d\d \d\d:\d\d:\d\d \w+$/,
        "$label: Date/time format is correct"
    );
    has_node( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:resourcetype/D:collection',
        "$label: resource type is correct"
    );
}

{
    my $label = 'Directory, propname';
    my $path = '/foo';
    my $dav = Net::DAV::Server->new( -filesys => Mock::Filesys->new(), -dbobj => Net::DAV::LockManager::Simple->new() );
    my $fs = $dav->filesys;

    ok( $fs->test( 'e', $path ), "$label: file exists" );
    my $req = propfind_request(
        $path,
        '<D:propfind xmlns:D="DAV:"><D:propname/></D:propfind>'
    );

    my $resp = $dav->propfind( $req, HTTP::Response->new( 200, 'OK' ) );
    is( $resp->code, 207, "$label: Response is 'Multi-Status'" );
    my $xpc = get_xml_context( $resp->content );
    has_text( $xpc, '/D:multistatus/D:response/D:href', "$path/", "$label: Path is correct" );
    has_text( $xpc, '/D:multistatus/D:response/D:propstat/D:status', 'HTTP/1.1 200 OK', "$label: Status is correct" );
    has_nodes( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop[1]',
        [ qw/creationdate getcontentlength getcontenttype getlastmodified supportedlock resourcetype/ ],
        "$label: Property nodes"
    );
}

{
    my $label = 'Directory, creationdate';
    my $path = '/';
    my $dav = Net::DAV::Server->new( -filesys => Mock::Filesys->new(), -dbobj => Net::DAV::LockManager::Simple->new() );

    my $req = propfind_request(
        $path,
        '<D:propfind xmlns:D="DAV:"><D:prop><D:creationdate/></D:prop></D:propfind>'
    );
    my $resp = $dav->propfind( $req, HTTP::Response->new( 200, 'OK' ) );
    is( $resp->code, 207, "$label: Response is 'Multi-Status'" );
    my $xpc = get_xml_context( $resp->content );
    has_text( $xpc, '/D:multistatus/D:response/D:href', $path, "$label: Path is correct" );
    has_text( $xpc, '/D:multistatus/D:response/D:propstat/D:status', 'HTTP/1.1 200 OK', "$label: Status is correct" );
    has_node( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop[1]/D:creationdate',
        "$label: Property exists"
    );
    like_text( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop[1]/D:creationdate',
        qr/^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d$/,
        "$label: Date/time format is correct"
    );
}

{
    my $label = 'Directory, getcontentlength';
    my $path = '/';
    my $dav = Net::DAV::Server->new( -filesys => Mock::Filesys->new(), -dbobj => Net::DAV::LockManager::Simple->new() );

    my $req = propfind_request(
        $path,
        '<D:propfind xmlns:D="DAV:"><D:prop><D:getcontentlength/></D:prop></D:propfind>'
    );
    my $resp = $dav->propfind( $req, HTTP::Response->new( 200, 'OK' ) );
    is( $resp->code, 207, "$label: Response is 'Multi-Status'" );
    my $xpc = get_xml_context( $resp->content );
    has_text( $xpc, '/D:multistatus/D:response/D:propstat/D:status', 'HTTP/1.1 200 OK', "$label: Status is correct" );
    has_node( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop[1]/D:getcontentlength',
        "$label: Property exists"
    );
}

{
    my $label = 'Directory, getcontenttype';
    my $path = '/';
    my $dav = Net::DAV::Server->new( -filesys => Mock::Filesys->new(), -dbobj => Net::DAV::LockManager::Simple->new() );

    my $req = propfind_request(
        $path,
        '<D:propfind xmlns:D="DAV:"><D:prop><D:getcontenttype/></D:prop></D:propfind>'
    );
    my $resp = $dav->propfind( $req, HTTP::Response->new( 200, 'OK' ) );
    is( $resp->code, 207, "$label: Response is 'Multi-Status'" );
    my $xpc = get_xml_context( $resp->content );
    has_text( $xpc, '/D:multistatus/D:response/D:propstat/D:status', 'HTTP/1.1 200 OK', "$label: Status is correct" );
    has_node( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop[1]/D:getcontenttype',
        "$label: Property exists"
    );
    has_text( $xpc, '/D:multistatus/D:response/D:propstat/D:prop/D:getcontenttype', 'httpd/unix-directory', "$label: contenttype is correct" );
}

{
    my $label = 'Directory, getlastmodified';
    my $path = '/';
    my $dav = Net::DAV::Server->new( -filesys => Mock::Filesys->new(), -dbobj => Net::DAV::LockManager::Simple->new() );

    my $req = propfind_request(
        $path,
        '<D:propfind xmlns:D="DAV:"><D:prop><D:getlastmodified/></D:prop></D:propfind>'
    );
    my $resp = $dav->propfind( $req, HTTP::Response->new( 200, 'OK' ) );
    is( $resp->code, 207, "$label: Response is 'Multi-Status'" );
    my $xpc = get_xml_context( $resp->content );
    has_text( $xpc, '/D:multistatus/D:response/D:propstat/D:status', 'HTTP/1.1 200 OK', "$label: Status is correct" );
    has_node( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop[1]/D:getlastmodified',
        "$label: Property exists"
    );
    like_text( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop[1]/D:getlastmodified',
        qr/^\w\w\w, \d\d? \w\w\w \d\d\d\d \d\d:\d\d:\d\d \w+$/,
        "$label: Date/time format is correct"
    );
}

{
    my $label = 'Directory, resourcetype';
    my $path = '/';
    my $dav = Net::DAV::Server->new( -filesys => Mock::Filesys->new(), -dbobj => Net::DAV::LockManager::Simple->new() );

    my $req = propfind_request(
        $path,
        '<D:propfind xmlns:D="DAV:"><D:prop><D:resourcetype/></D:prop></D:propfind>'
    );
    my $resp = $dav->propfind( $req, HTTP::Response->new( 200, 'OK' ) );
    is( $resp->code, 207, "$label: Response is 'Multi-Status'" );
    my $xpc = get_xml_context( $resp->content );
    has_text( $xpc, '/D:multistatus/D:response/D:propstat/D:status', 'HTTP/1.1 200 OK', "$label: Status is correct" );
    has_node( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop[1]/D:resourcetype/D:collection',
        "$label: Property exists"
    );
}

{
    my $label = 'Directory, lockdiscovery';
    my $path = '/';
    my $dav = Net::DAV::Server->new( -filesys => Mock::Filesys->new(), -dbobj => Net::DAV::LockManager::Simple->new() );

    my $req = propfind_request(
        $path,
        '<D:propfind xmlns:D="DAV:"><D:prop><D:lockdiscovery/></D:prop></D:propfind>'
    );
    my $resp = $dav->propfind( $req, HTTP::Response->new( 200, 'OK' ) );
    is( $resp->code, 207, "$label: Response is 'Multi-Status'" );
    my $xpc = get_xml_context( $resp->content );
    has_text( $xpc, '/D:multistatus/D:response/D:propstat/D:status', 'HTTP/1.1 200 OK', "$label: Status is correct" );
    has_node( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop[1]/D:lockdiscovery',
        "$label: Property exists"
    );
}

{
    my $label = 'Directory, supportedlock';
    my $path = '/';
    my $dav = Net::DAV::Server->new( -filesys => Mock::Filesys->new(), -dbobj => Net::DAV::LockManager::Simple->new() );

    my $req = propfind_request(
        $path,
        '<D:propfind xmlns:D="DAV:"><D:prop><D:supportedlock/></D:prop></D:propfind>'
    );
    my $resp = $dav->propfind( $req, HTTP::Response->new( 200, 'OK' ) );
    is( $resp->code, 207, "$label: Response is 'Multi-Status'" );
    my $xpc = get_xml_context( $resp->content );
    has_text( $xpc, '/D:multistatus/D:response/D:propstat/D:status', 'HTTP/1.1 200 OK', "$label: Status is correct" );
    has_node( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop[1]/D:supportedlock',
        "$label: Property exists"
    );
    has_node( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop[1]/D:supportedlock/D:lockentry/D:lockscope/D:exclusive',
        "$label: supports exclusive lock scope"
    );
    hasnt_node( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:supportedlock/D:lockentry/D:lockscope/D:shared',
        "$label: shared lock scope not supported"
    );
}

{
    my $label = 'Directory, different namespace';
    my $path = '/';
    my $dav = Net::DAV::Server->new( -filesys => Mock::Filesys->new(), -dbobj => Net::DAV::LockManager::Simple->new() );

    my $req = propfind_request(
        $path,
        '<D:propfind xmlns:D="DAV:" xmlns:G="GWJ:"><D:prop><G:weirdprop/></D:prop></D:propfind>'
    );
    my $resp = $dav->propfind( $req, HTTP::Response->new( 200, 'OK' ) );
    is( $resp->code, 207, "$label: Response is 'Multi-Status'" );
    my $xpc = get_xml_context( $resp->content );
    $xpc->registerNs( 'i0', 'GWJ:' ); 
    has_text( $xpc, '/D:multistatus/D:response/D:propstat/D:status', 'HTTP/1.1 404 Not Found', "$label: Status is correct" );
    has_node( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/i0:weirdprop',
        "$label: Property exists"
    );
}

{
    my $label = 'Directory, bad property';
    my $path = '/';
    my $dav = Net::DAV::Server->new( -filesys => Mock::Filesys->new(), -dbobj => Net::DAV::LockManager::Simple->new() );

    my $req = propfind_request(
        $path,
        '<D:propfind xmlns:D="DAV:"><D:prop><D:xyzzy/></D:prop></D:propfind>'
    );
    my $resp = $dav->propfind( $req, HTTP::Response->new( 200, 'OK' ) );
    is( $resp->code, 207, "$label: Response is 'Multi-Status'" );
    my $xpc = get_xml_context( $resp->content );
    has_text( $xpc, '/D:multistatus/D:response/D:propstat/D:status', 'HTTP/1.1 404 Not Found', "$label: Status is correct" );

}

# File
{
    my $label = 'File, default';
    my $path = '/test.html';
    my $dav = Net::DAV::Server->new( -filesys => Mock::Filesys->new(), -dbobj => Net::DAV::LockManager::Simple->new() );
    my $fs = $dav->filesys;

    ok( $fs->test( 'e', $path ), "$label: file exists" );
    my $req = propfind_request( $path );

    my $resp = $dav->propfind( $req, HTTP::Response->new( 200, 'OK' ) );
    is( $resp->code, 207, "$label: Response is 'Multi-Status'" );
    my $xpc = get_xml_context( $resp->content );
    has_text( $xpc, '/D:multistatus/D:response/D:href', $path, "$label: Path is correct" );
    has_text( $xpc, '/D:multistatus/D:response/D:propstat/D:status', 'HTTP/1.1 200 OK', "$label: Status is correct" );
    has_nodes( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop[1]',
        [ qw/creationdate getcontentlength getcontenttype getlastmodified supportedlock resourcetype/ ],
        "$label: Property nodes"
    );
    like_text( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop[1]/D:creationdate',
        qr/^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d$/,
        "$label: Date/time format is correct"
    );
    has_node( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:supportedlock/D:lockentry/D:lockscope/D:exclusive',
        "$label: supports exclusive lock scope"
    );
    hasnt_node( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:supportedlock/D:lockentry/D:lockscope/D:shared',
        "$label: shared lock scope not supported"
    );
    has_text( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:getcontenttype',
        'httpd/unix-file',
        "$label: content type is correct"
    );
    like_text( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop[1]/D:getlastmodified',
        qr/^\w\w\w, \d\d? \w\w\w \d\d\d\d \d\d:\d\d:\d\d \w+$/,
        "$label: Date/time format is correct"
    );
    has_text( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop[1]/D:getcontentlength',
        '1024',
        "$label: content length is correct"
    );
}

{
    my $label = 'File, allprop';
    my $path = '/test.html';
    my $dav = Net::DAV::Server->new( -filesys => Mock::Filesys->new(), -dbobj => Net::DAV::LockManager::Simple->new() );
    my $fs = $dav->filesys;

    ok( $fs->test( 'e', $path ), "$label: file exists" );
    my $req = propfind_request(
        $path,
        '<D:propfind xmlns:D="DAV:"><D:allprop/></D:propfind>'
    );

    my $resp = $dav->propfind( $req, HTTP::Response->new( 200, 'OK' ) );
    is( $resp->code, 207, "$label: Response is 'Multi-Status'" );
    my $xpc = get_xml_context( $resp->content );
    has_text( $xpc, '/D:multistatus/D:response/D:href', $path, "$label: Path is correct" );
    has_text( $xpc, '/D:multistatus/D:response/D:propstat/D:status', 'HTTP/1.1 200 OK', "$label: Status is correct" );
    has_nodes( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop[1]',
        [ qw/creationdate getcontentlength getcontenttype getlastmodified supportedlock resourcetype/ ],
        "$label: Property nodes"
    );
    like_text( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop[1]/D:creationdate',
        qr/^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d$/,
        "$label: Date/time format is correct"
    );
    has_node( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:supportedlock/D:lockentry/D:lockscope/D:exclusive',
        "$label: missing exclusive lock scope"
    );
    hasnt_node( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:supportedlock/D:lockentry/D:lockscope/D:shared',
        "$label: shared lock scope not supported"
    );
    has_text( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:getcontenttype',
        'httpd/unix-file',
        "$label: content type is correct"
    );
    like_text( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop[1]/D:getlastmodified',
        qr/^\w\w\w, \d\d? \w\w\w \d\d\d\d \d\d:\d\d:\d\d \w+$/,
        "$label: Date/time format is correct"
    );
    has_text( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop[1]/D:getcontentlength',
        '1024',
        "$label: content length is correct"
    );
}

{
    my $label = 'File, propname';
    my $path = '/test.html';
    my $dav = Net::DAV::Server->new( -filesys => Mock::Filesys->new(), -dbobj => Net::DAV::LockManager::Simple->new() );
    my $fs = $dav->filesys;

    ok( $fs->test( 'e', $path ), "$label: file exists" );
    my $req = propfind_request(
        $path,
        '<D:propfind xmlns:D="DAV:"><D:propname/></D:propfind>'
    );

    my $resp = $dav->propfind( $req, HTTP::Response->new( 200, 'OK' ) );
    is( $resp->code, 207, "$label: Response is 'Multi-Status'" );
    my $xpc = get_xml_context( $resp->content );
    has_text( $xpc, '/D:multistatus/D:response/D:href', $path, "$label: Path is correct" );
    has_text( $xpc, '/D:multistatus/D:response/D:propstat/D:status', 'HTTP/1.1 200 OK', "$label: Status is correct" );
    has_nodes( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop[1]',
        [ qw/creationdate getcontentlength getcontenttype getlastmodified supportedlock resourcetype/ ],
        "$label: Property nodes"
    );
}

{
    my $label = 'File, creationdate';
    my $path = '/test.html';
    my $dav = Net::DAV::Server->new( -filesys => Mock::Filesys->new(), -dbobj => Net::DAV::LockManager::Simple->new() );

    my $req = propfind_request(
        $path,
        '<D:propfind xmlns:D="DAV:"><D:prop><D:creationdate/></D:prop></D:propfind>'
    );
    my $resp = $dav->propfind( $req, HTTP::Response->new( 200, 'OK' ) );
    is( $resp->code, 207, "$label: Response is 'Multi-Status'" );
    my $xpc = get_xml_context( $resp->content );
    has_text( $xpc, '/D:multistatus/D:response/D:propstat/D:status', 'HTTP/1.1 200 OK', "$label: Status is correct" );
    has_node( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop[1]/D:creationdate',
        "$label: Property exists"
    );
    like_text( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop[1]/D:creationdate',
        qr/^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d$/,
        "$label: Date/time format is correct"
    );
}

{
    my $label = 'File, getcontentlength';
    my $path = '/test.html';
    my $dav = Net::DAV::Server->new( -filesys => Mock::Filesys->new(), -dbobj => Net::DAV::LockManager::Simple->new() );

    my $req = propfind_request(
        $path,
        '<D:propfind xmlns:D="DAV:"><D:prop><D:getcontentlength/></D:prop></D:propfind>'
    );
    my $resp = $dav->propfind( $req, HTTP::Response->new( 200, 'OK' ) );
    is( $resp->code, 207, "$label: Response is 'Multi-Status'" );
    my $xpc = get_xml_context( $resp->content );
    has_text( $xpc, '/D:multistatus/D:response/D:propstat/D:status', 'HTTP/1.1 200 OK', "$label: Status is correct" );
    has_node( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop[1]/D:getcontentlength',
        "$label: Property exists"
    );
    has_text( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop[1]/D:getcontentlength',
        '1024',
        "$label: content length is correct"
    );
}

{
    my $label = 'File, getcontenttype';
    my $path = '/test.html';
    my $dav = Net::DAV::Server->new( -filesys => Mock::Filesys->new(), -dbobj => Net::DAV::LockManager::Simple->new() );

    my $req = propfind_request(
        $path,
        '<D:propfind xmlns:D="DAV:"><D:prop><D:getcontenttype/></D:prop></D:propfind>'
    );
    my $resp = $dav->propfind( $req, HTTP::Response->new( 200, 'OK' ) );
    is( $resp->code, 207, "$label: Response is 'Multi-Status'" );
    my $xpc = get_xml_context( $resp->content );
    has_text( $xpc, '/D:multistatus/D:response/D:propstat/D:status', 'HTTP/1.1 200 OK', "$label: Status is correct" );
    has_node( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop[1]/D:getcontenttype',
        "$label: Property exists"
    );
    has_text( $xpc, '/D:multistatus/D:response/D:propstat/D:prop/D:getcontenttype', 'httpd/unix-file', "$label: contenttype is correct" );
}

{
    my $label = 'File, getlastmodified';
    my $path = '/test.html';
    my $dav = Net::DAV::Server->new( -filesys => Mock::Filesys->new(), -dbobj => Net::DAV::LockManager::Simple->new() );

    my $req = propfind_request(
        $path,
        '<D:propfind xmlns:D="DAV:"><D:prop><D:getlastmodified/></D:prop></D:propfind>'
    );
    my $resp = $dav->propfind( $req, HTTP::Response->new( 200, 'OK' ) );
    is( $resp->code, 207, "$label: Response is 'Multi-Status'" );
    my $xpc = get_xml_context( $resp->content );
    has_text( $xpc, '/D:multistatus/D:response/D:propstat/D:status', 'HTTP/1.1 200 OK', "$label: Status is correct" );
    has_node( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop[1]/D:getlastmodified',
        "$label: Property exists"
    );
    like_text( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop[1]/D:getlastmodified',
        qr/^\w\w\w, \d\d? \w\w\w \d\d\d\d \d\d:\d\d:\d\d \w+$/,
        "$label: Date/time format is correct"
    );
}

{
    my $label = 'File, resourcetype';
    my $path = '/test.html';
    my $dav = Net::DAV::Server->new( -filesys => Mock::Filesys->new(), -dbobj => Net::DAV::LockManager::Simple->new() );

    my $req = propfind_request(
        $path,
        '<D:propfind xmlns:D="DAV:"><D:prop><D:resourcetype/></D:prop></D:propfind>'
    );
    my $resp = $dav->propfind( $req, HTTP::Response->new( 200, 'OK' ) );
    is( $resp->code, 207, "$label: Response is 'Multi-Status'" );
    my $xpc = get_xml_context( $resp->content );
    has_text( $xpc, '/D:multistatus/D:response/D:propstat/D:status', 'HTTP/1.1 200 OK', "$label: Status is correct" );
    has_node( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop[1]/D:resourcetype',
        "$label: Property exists"
    );
}

{
    my $label = 'File, lockdiscovery';
    my $path = '/test.html';
    my $dav = Net::DAV::Server->new( -filesys => Mock::Filesys->new(), -dbobj => Net::DAV::LockManager::Simple->new() );

    my $req = propfind_request(
        $path,
        '<D:propfind xmlns:D="DAV:"><D:prop><D:lockdiscovery/></D:prop></D:propfind>'
    );
    my $resp = $dav->propfind( $req, HTTP::Response->new( 200, 'OK' ) );
    is( $resp->code, 207, "$label: Response is 'Multi-Status'" );
    my $xpc = get_xml_context( $resp->content );
    has_text( $xpc, '/D:multistatus/D:response/D:propstat/D:status', 'HTTP/1.1 200 OK', "$label: Status is correct" );
    has_node( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop[1]/D:lockdiscovery',
        "$label: Property exists"
    );
}

{
    my $label = 'File, supportedlock';
    my $path = '/test.html';
    my $dav = Net::DAV::Server->new( -filesys => Mock::Filesys->new(), -dbobj => Net::DAV::LockManager::Simple->new() );

    my $req = propfind_request(
        $path,
        '<D:propfind xmlns:D="DAV:"><D:prop><D:supportedlock/></D:prop></D:propfind>'
    );
    my $resp = $dav->propfind( $req, HTTP::Response->new( 200, 'OK' ) );
    is( $resp->code, 207, "$label: Response is 'Multi-Status'" );
    my $xpc = get_xml_context( $resp->content );
    has_text( $xpc, '/D:multistatus/D:response/D:propstat/D:status', 'HTTP/1.1 200 OK', "$label: Status is correct" );
    has_node( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:supportedlock/D:lockentry/D:lockscope/D:exclusive',
        "$label: supports exclusive lock scope"
    );
    hasnt_node( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:supportedlock/D:lockentry/D:lockscope/D:shared',
        "$label: shared lock scope not supported"
    );
}

{
    my $label = 'File, bad property';
    my $path = '/test.html';
    my $dav = Net::DAV::Server->new( -filesys => Mock::Filesys->new(), -dbobj => Net::DAV::LockManager::Simple->new() );

    my $req = propfind_request(
        $path,
        '<D:propfind xmlns:D="DAV:"><D:prop><D:xyzzy/></D:prop></D:propfind>'
    );
    my $resp = $dav->propfind( $req, HTTP::Response->new( 200, 'OK' ) );
    is( $resp->code, 207, "$label: Response is 'Multi-Status'" );
    my $xpc = get_xml_context( $resp->content );
    has_text( $xpc, '/D:multistatus/D:response/D:propstat/D:status', 'HTTP/1.1 404 Not Found', "$label: Status is correct" );
}

{
    my $label = 'Unicode File, default';
    my $path = '/テスト';
    my $uripath = '/' . uri_escape('テスト');
    my $dav = Net::DAV::Server->new( -filesys => Mock::Filesys->new(), -dbobj => Net::DAV::LockManager::Simple->new() );
    my $fs = $dav->filesys;

    ok( $fs->test( 'e', $path ), "$label: file exists" );
    my $req = propfind_request( $path );

    my $resp = $dav->propfind( $req, HTTP::Response->new( 200, 'OK' ) );
    is( $resp->code, 207, "$label: Response is 'Multi-Status'" );
    my $xpc = get_xml_context( $resp->content );
    has_text( $xpc, '/D:multistatus/D:response/D:href', $uripath, "$label: Path is correct" );
    has_text( $xpc, '/D:multistatus/D:response/D:propstat/D:status', 'HTTP/1.1 200 OK', "$label: Status is correct" );
    has_nodes( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop[1]',
        [ qw/creationdate getcontentlength getcontenttype getlastmodified supportedlock resourcetype/ ],
        "$label: Property nodes"
    );
    like_text( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop[1]/D:creationdate',
        qr/^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d$/,
        "$label: Date/time format is correct"
    );
    has_node( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:supportedlock/D:lockentry/D:lockscope/D:exclusive',
        "$label: supports exclusive lock scope"
    );
    hasnt_node( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:supportedlock/D:lockentry/D:lockscope/D:shared',
        "$label: shared lock scope not supported"
    );
    has_text( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:getcontenttype',
        'httpd/unix-file',
        "$label: content type is correct"
    );
    like_text( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop[1]/D:getlastmodified',
        qr/^\w\w\w, \d\d? \w\w\w \d\d\d\d \d\d:\d\d:\d\d \w+$/,
        "$label: Date/time format is correct"
    );
    has_text( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop[1]/D:getcontentlength',
        '128',
        "$label: content length is correct"
    );
}

{
    my $label = 'Directory, listing';
    my $path = '/';
    my $dav = Net::DAV::Server->new( -filesys => Mock::Filesys->new(), -dbobj => Net::DAV::LockManager::Simple->new() );

    my $req = propfind_request(
        $path,
        '<D:propfind xmlns:D="DAV:"><D:allprop/></D:propfind>'
    );
    $req->header( 'Depth' => 1 );
    my $resp = $dav->propfind( $req, HTTP::Response->new( 200, 'OK' ) );
    is( $resp->code, 207, "$label: Response is 'Multi-Status'" );
    my $xpc = get_xml_context( $resp->content );

    # Build a list of child files/directories.
    my @expected = (
        map { /^\/(?:foo|bar)$/ ? "$_/" : $_ }
        map { my $s = $_; $s =~ s{([^/]+)}{uri_escape $1}eg; $s }
        grep { $_ ne '/' && m{^/[^/]+$} } sort keys %{$dav->filesys}
    );

    # Add a final entry of the directory itself
    push @expected, '/';
    has_texts( $xpc, '/D:multistatus/D:response/D:href', \@expected, "$label: Status is correct" );
}

# -------- Utility subs ----------

sub propfind_request {
    my ($path, $content) = @_;

    my $req = HTTP::Request->new( PROPFIND => $path );
    if ( defined $content ) {
        $req->content( $content );
        $req->header( 'Content-Length', length $content );
    }
    $req->authorization_basic( 'fred', 'fredmobile' );
    return $req;
}

sub get_xml_context {
    my ($content) = @_;
    my $doc = eval { $parser->parse_string( $content ) };
    die "Unable to parse content.\n" unless defined $doc;
    my $xpc = XML::LibXML::XPathContext->new( $doc );
    $xpc->registerNs( 'D', 'DAV:' );
    return $xpc;
}

sub has_text {
    my ($xpc, $xpath, $expect, $label) = @_;
    $expect = Encode::decode_utf8 $expect;
    my @nodes = $xpc->findnodes( "$xpath/text()" );
    unless ( defined $nodes[0] ) {
        fail( "$label : Node not found." );
        return;
    }
    is( $nodes[0]->data, $expect, $label );
}

sub like_text {
    my ($xpc, $xpath, $expect, $label) = @_;
    my @nodes = $xpc->findnodes( "$xpath/text()" );
    unless ( defined $nodes[0] ) {
        fail( "$label : Node not found." );
        return;
    }
    like( $nodes[0]->data, $expect, $label );
}

sub has_texts {
    my ($xpc, $xpath, $expect, $label) = @_;
    my @nodes = map { $_->data } $xpc->findnodes( "$xpath/text()" );
    unless ( defined $nodes[0] ) {
        fail( "$label : Node not found." );
        return;
    }
    is_deeply( \@nodes, $expect, $label );
}

sub has_nodes {
    my ($xpc, $xpath, $tags, $label) = @_;
    my @nodes = map { $_->localname } $xpc->findnodes( "$xpath/D:*" );
    unless ( defined $nodes[0] ) {
        fail( "$label : Node not found." );
        return;
    }
    is_deeply( \@nodes, $tags, $label );
}

sub has_node {
    my ($xpc, $xpath, $label) = @_;
    my @nodes = $xpc->findnodes( $xpath );
    ok ( defined $nodes[0], $label );
}

sub hasnt_node {
    my ($xpc, $xpath, $label) = @_;
    my @nodes = $xpc->findnodes( $xpath );
    ok ( !defined $nodes[0], $label );
}
