package Net::DAV::Server;
use strict;
use warnings;
use File::Slurp;
use Encode;
use File::Find::Rule::Filesys::Virtual;
use HTTP::Date qw(time2str time2isoz);
use HTTP::Headers;
use HTTP::Response;
use HTTP::Request;
use File::Spec;
use URI;
use URI::Escape;
use XML::LibXML;
use XML::LibXML::XPathContext;
use Net::DAV::LockManager ();
use Net::DAV::LockManager::DB ();

our $VERSION = '1.305';
$VERSION = eval $VERSION;  # convert development version into a simpler version number.

our %implemented = (
    options  => 1,
    put      => 1,
    get      => 1,
    head     => 1,
    post     => 1,
    delete   => 1,
    mkcol    => 1,
    propfind => 1,
    copy     => 1,
    lock     => 1,
    unlock   => 1,
    move     => 1
);

sub new {
    my $class = shift;
    my %args = @_ % 2 ? () : @_;
    my $self = {};
    if ( $args{'-dbobj'} ) {
        $self->{'lock_manager'} = Net::DAV::LockManager->new( $args{'-dbobj'} );
    }
    elsif ( $args{'-dbfile'} ) {
        $self->{'_dsn'} = "dbi:SQLite:dbname=$args{'-dbfile'}";
    }
    elsif ( $args{'-dsn'} ) {
        $self->{'_dsn'} = $args{'-dsn'};
    }
    bless $self, $class;
    if ( $args{'-filesys'} ) {
        $self->filesys( $args{'-filesys'} );
    }
    return $self;
}

sub filesys {
    my ($self, $nfs) = @_;
    $self->{'-filesys'} = $nfs if defined $nfs;
    return $self->{'-filesys'};
}

sub run {
    my ( $self, $request, $response ) = @_;

    my $fs = $self->filesys || die 'Filesys missing';

    my $method = $request->method;
    my $path   = uri_unescape $request->uri->path;

    if ( !defined $response ) {
        $response = HTTP::Response->new;
    }

    $method = lc $method;
    if ( $implemented{$method} ) {
        $response->code(200);
        $response->message('OK');
        eval {
            $response = $self->$method( $request, $response );
            $response->header( 'Content-Length' => length( $response->content ) ) if defined $response->content;
            1;
        } or do {
            return HTTP::Response->new( 400, 'Bad Request' );
        };
    }
    else {

        # Saying it isn't implemented is better than crashing!
        $response->code(501);
        $response->message('Not Implemented');
    }
    return $response;
}

sub options {
    my ( $self, $request, $response ) = @_;
    $response->header( 'DAV'           => '1,2,<http://apache.org/dav/propset/fs/1>' );    # Nautilus freaks out
    $response->header( 'MS-Author-Via' => 'DAV' );                                         # Nautilus freaks out
    $response->header( 'Allow'         => join( ',', map { uc } keys %implemented ) );
    $response->header( 'Content-Type'  => 'httpd/unix-directory' );
    $response->header( 'Keep-Alive'    => 'timeout=15, max=96' );
    return $response;
}

sub head {
    my ( $self, $request, $response ) = @_;
    my $path = uri_unescape $request->uri->path;
    my $fs   = $self->filesys;

    if ( $fs->test( 'f', $path ) && $fs->test( 'r', $path ) ) {
        $response->last_modified( $fs->modtime($path) );
    }
    elsif ( $fs->test( 'd', $path ) ) {
        $response->header( 'Content-Type' => 'text/html; charset="utf-8"' );
    }
    else {
        $response = HTTP::Response->new( 404, 'NOT FOUND', $response->headers );
    }
    return $response;
}

sub get {
    my ( $self, $request, $response ) = @_;
    my $path = uri_unescape $request->uri->path;
    my $fs   = $self->filesys;

    if ( $fs->test( 'f', $path ) && $fs->test( 'r', $path ) ) {
        my $fh = $fs->open_read($path);
        my $file = join '', <$fh>;
        $fs->close_read($fh);
        $response->content($file);
        $response->last_modified( $fs->modtime($path) );
    }
    elsif ( $fs->test( 'd', $path ) ) {

        # a web browser, then
        my @files = $fs->list($path);
        my $body;
        my $fpath = $path =~ m{/$} ? $path : $path . '/';
        foreach my $file (@files) {
            if ( $fs->test( 'd', $fpath . $file ) ) {
                $body .= qq|<a href="$file/">$file/</a><br>\n|;
            }
            else {
                $file =~ s{/$}{};
                $body .= qq|<a href="$file">$file</a><br>\n|;
            }
        }
        $response->header( 'Content-Type' => 'text/html; charset="utf-8"' );
        $response->content($body);
    }
    else {
        return HTTP::Response->new( 404, 'Not Found' );
    }
    return $response;
}

sub _lock_manager {
    my ($self) = @_;
    unless ( $self->{'lock_manager'} ) {
        if ( $self->{'_dsn'} ) {
            my $db = Net::DAV::LockManager::DB->new( $self->{'_dsn'} );
            $self->{'lock_manager'} = Net::DAV::LockManager->new($db);
        }
        else {
            $self->{'lock_manager'} = Net::DAV::LockManager->new();
        }
    }
    return $self->{'lock_manager'};
}

sub lock {
    my ( $self, $request, $response ) = @_;

    my $lockreq = _parse_lock_request($request);

    # Invalid XML requires a 400 response code.
    return HTTP::Response->new( 400, 'Bad Request' ) unless defined $lockreq;

    if ( !$lockreq->{'has_content'} ) {

        # Not already locked.
        return HTTP::Response->new( 403, 'Forbidden' ) if !$lockreq->{'token'};

        # Reset timeout
        if ( my $lock = $self->_lock_manager()->refresh_lock($lockreq) ) {
            $response->header( 'Content-Type' => 'text/xml; charset="utf-8"' );
            $response->content(
                _lock_response_content(
                    {
                        'path'    => $lock->path,
                        'token'   => $lock->token,
                        'timeout' => $lock->timeout,
                        'scope'   => $lock->scope,
                        'depth'   => $lock->depth,
                    }
                )
            );
        }
        else {
            my $curr = $self->_lock_manager()->find_lock( { 'path' => $lockreq->{'path'} } );
            return HTTP::Response->new( 412, 'Precondition Failed' ) unless $curr;

            # Not the correct lock token
            return HTTP::Response->new( 412, 'Precondition Failed' ) if $lockreq->{'token'} ne $curr->token;

            # Not the correct user.
            return HTTP::Response->new( 403, 'Forbidden' );
        }
        return $response;
    }

    # Validate depth request
    return HTTP::Response->new( 400, 'Bad Request' ) unless $lockreq->{'depth'} =~ /^(?:0|infinity)$/;

    my $lock = $self->_lock_manager()->lock($lockreq);

    if ( !$lock ) {
        my $curr = $self->_lock_manager()->find_lock( { 'path' => $lockreq->{'path'} } );
        return HTTP::Response->new( 412, 'Precondition Failed' ) unless $curr;

        # Not the correct lock token
        return HTTP::Response->new( 412, 'Precondition Failed' ) if $lockreq->{'token'}||'' ne $curr->token;

        # Resource is already locked
        return HTTP::Response->new( 403, 'Forbidden' );
    }

    my $token = $lock->token;
    $response->code( 200 );
    $response->message( 'OK' );
    $response->header( 'Lock-Token',   "<$token>" );
    $response->header( 'Content-Type', 'text/xml; charset="utf-8"' );
    $response->content(
        _lock_response_content(
            {
                'path'       => $lock->path,
                'token'      => $token,
                'timeout'    => $lock->timeout,
                'scope'      => 'exclusive',
                'depth'      => $lock->depth,
                'owner_node' => $lockreq->{'owner_node'},
            }
        )
    );

    # Create empty file if none exists, as per RFC 4918, Section 9.10.4
    my $fs = $self->filesys;
    if ( !$fs->test( 'e', $lock->path ) ) {
        my $fh = $fs->open_write( $lock->path, 1 );
        $fs->close_write($fh) if $fh;
    }

    return $response;
}

sub _get_timeout {
    my ($to_header) = @_;
    return undef unless defined $to_header and length $to_header;

    my @timeouts = sort
      map { /Second-(\d+)/ ? $1 : $_ }
      grep { $_ ne 'Infinite' }
      split /\s*,\s*/, $to_header;

    return undef unless @timeouts;
    return $timeouts[0];
}

sub _parse_lock_header {
    my ($req)   = @_;
    my $depth   = $req->header('Depth');
    my %lockreq = (
        'path' => uri_unescape( $req->uri->path ),

        # Assuming basic auth for now.
        'user' => ( $req->authorization_basic() )[0] || '',
        'token' => ( _extract_lock_token($req) || undef ),
        'timeout' => _get_timeout( $req->header('Timeout') ),
        'depth'   => ( defined $depth ? $depth : 'infinity' ),
    );
    return \%lockreq;
}

sub _parse_lock_request {
    my ($req) = @_;
    my $lockreq = _parse_lock_header($req);
    return $lockreq unless $req->content;

    my $parser = XML::LibXML->new;
    my $doc;
    eval { $doc = $parser->parse_string( $req->content ); } or do {

        # Request body must be a valid XML request
        return;
    };
    my $xpc = XML::LibXML::XPathContext->new($doc);
    $xpc->registerNs( 'D', 'DAV:' );

    # Want the following in list context.
    $lockreq->{'owner_node'} = ( $xpc->findnodes('/D:lockinfo/D:owner') )[0];
    if ( $lockreq->{'owner_node'} ) {
        my $owner = $lockreq->{'owner_node'}->toString;
        $owner =~ s/^<(?:[^:]+:)?owner>//sm;
        $owner =~ s!</(?:[^:]+:)?owner>$!!sm;
        $lockreq->{'owner'} = $owner;
    }
    $lockreq->{'scope'} = eval { ( $xpc->findnodes('/D:lockinfo/D:lockscope/D:*') )[0]->localname; };
    $lockreq->{'has_content'} = 1;

    return $lockreq;
}

sub _extract_lock_token {
    my ($req) = @_;
    my $token = $req->header('If');
    unless ($token) {
        $token = $req->header('Lock-Token');
        return $1 if defined $token && $token =~ /<([^>]+)>/;
        return undef;
    }

    # Based on the last paragraph of section 10.4.1 of RFC 4918, it appears
    # that any lock token that appears in the If header is available as a
    # known lock token. Rather than trying to deal with the whole entity,
    # lock, implicit and/or, and Not (with and without resources) thing,
    # This code just returns a list of lock tokens found in the header.
    my @tokens = map { $_ =~ /<([^>]+)>/g } ( $token =~ /\(([^\)]+)\)/g );

    return undef unless @tokens;
    return @tokens == 1 ? $tokens[0] : \@tokens;
}

sub _lock_response_content {
    my ($args) = @_;
    my $resp = XML::LibXML::Document->new( '1.0', 'utf-8' );
    my $prop = _dav_root( $resp, 'prop' );
    my $lock = _dav_child( _dav_child( $prop, 'lockdiscovery' ), 'activelock' );
    _dav_child( _dav_child( $lock, 'locktype' ), 'write' );
    _dav_child( _dav_child( $lock, 'lockscope' ), $args->{'scope'} || 'exclusive' );
    _dav_child( $lock, 'depth', $args->{'depth'} || 'infinity' );
    if ( $args->{'owner_node'} ) {
        my $owner = $args->{'owner_node'}->cloneNode(1);
        $resp->adoptNode($owner);
        $lock->addChild($owner);
    }
    _dav_child( $lock, 'timeout', "Second-$args->{'timeout'}" );
    _dav_child( _dav_child( $lock, 'locktoken' ), 'href', $args->{'token'} );
    _dav_child( _dav_child( $lock, 'lockroot' ),  'href', $args->{'path'} );

    return $resp->toString;
}

sub _active_lock_prop {
    my ( $doc, $lock ) = @_;
    my $active = $doc->createElement('D:activelock');

    # All locks are write
    _dav_child( _dav_child( $active, 'locktype' ),  'write' );
    _dav_child( _dav_child( $active, 'lockscope' ), $lock->scope );
    _dav_child( $active, 'depth', $lock->depth );
    $active->appendWellBalancedChunk( '<D:owner xmlns:D="DAV:">' . $lock->owner . '</D:owner>' );
    _dav_child( $active, 'timeout', 'Second-' . $lock->timeout );
    _dav_child( _dav_child( $active, 'locktoken' ), 'href', $lock->token );
    _dav_child( _dav_child( $active, 'lockroot' ),  'href', $lock->path );

    return $active;
}

sub unlock {
    my ( $self, $request, $response ) = @_;
    my $path    = uri_unescape( $request->uri->path );
    my $lockreq = _parse_lock_header($request);

    # No lock token supplied, we cannot unlock
    return HTTP::Response->new( 400, 'Bad Request' ) unless $lockreq->{'token'};

    if ( !$self->_lock_manager()->unlock($lockreq) ) {
        my $curr = $self->_lock_manager()->find_lock( { 'path' => $lockreq->{'path'} } );

        # No lock exists, conflicting requirements.
        return HTTP::Response->new( 409, 'Conflict' ) unless $curr;

        # Not the owner of the lock or bad token.
        return HTTP::Response->new( 403, 'Forbidden' );
    }

    return HTTP::Response->new( 204, 'No content' );
}

sub _dav_child {
    my ( $parent, $tag, $text ) = @_;
    my $child = $parent->ownerDocument->createElement("D:$tag");
    $parent->addChild($child);
    $child->appendText($text) if defined $text;
    return $child;
}

sub _dav_root {
    my ( $doc, $tag ) = @_;
    my $root = $doc->createElementNS( 'DAV:', $tag );
    $root->setNamespace( 'DAV:', 'D', 1 );
    $doc->setDocumentElement($root);
    return $root;
}

sub _can_modify {
    my ( $self, $request ) = @_;
    my $lockreq = _parse_lock_header($request);
    return $self->_lock_manager()->can_modify($lockreq);
}

sub post {
    my ( $self, $request, $response ) = @_;

    if ( !$self->_can_modify( $request ) ) {
        return HTTP::Response->new( 403, 'Forbidden' );
    }

    return HTTP::Response->new( 501, 'Not Implemented' );
}

sub put {
    my ( $self, $request, $response ) = @_;

    if ( !$self->_can_modify($request) ) {
        return HTTP::Response->new( 403, 'Forbidden' );
    }

    my $path = uri_unescape $request->uri->path;
    my $fs   = $self->filesys;

    return HTTP::Response->new( 405, 'Method Not Allowed' ) if $fs->test( 'd', $path );
    my $parent = $path;
    $parent =~ s{/[^/]+$}{};
    $parent = '/' if $parent eq '';
    # Parent directory does not exist.
    return HTTP::Response->new( 409, 'Conflict' ) unless $fs->test( 'd', $parent );

    my $fh = $fs->open_write( $path );
    if ( $fh ) {
        $response = HTTP::Response->new( 201, 'Created', $response->headers );
        print $fh $request->content;
        $fs->close_write($fh);
    }
    else {
        # Unable to write for some other reason.
        return HTTP::Response->new( 403, 'Forbidden' );
    }

    return $response;
}

sub _delete_xml {
    my ( $dom, $path ) = @_;

    my $response = $dom->createElement('d:response');
    $response->appendTextChild( 'd:href'   => $path );
    $response->appendTextChild( 'd:status' => 'HTTP/1.1 401 Permission Denied' );    # *** FIXME ***
}

sub delete {
    my ( $self, $request, $response ) = @_;

    if ( !$self->_can_modify($request) ) {
        return HTTP::Response->new( 403, 'Forbidden' );
    }

    if ( $request->uri->fragment ) {
        return HTTP::Response->new( 404, 'Not Found', $response->headers );
    }

    my $path = uri_unescape $request->uri->path;
    my $fs   = $self->filesys;
    unless ( $fs->test( 'e', $path ) ) {
        return HTTP::Response->new( 404, 'Not Found', $response->headers );
    }

    my $dom = XML::LibXML::Document->new( '1.0', 'utf-8' );
    my @error;
    # see rt 46865: files first since rmdir() only removed empty directories
    foreach my $part ( _get_files($fs, $path), _get_dirs($fs, $path), $path ) {

        next unless $fs->test( 'e', $part );

        if ( $fs->test( 'f', $part ) ) {
            push @error, _delete_xml( $dom, $part )
              unless $fs->delete($part);
        }
        elsif ( $fs->test( 'd', $part ) ) {
            push @error, _delete_xml( $dom, $part )
              unless $fs->rmdir($part);
        }
    }

    if (@error) {
        my $multistatus = $dom->createElement('D:multistatus');
        $multistatus->setAttribute( 'xmlns:D', 'DAV:' );

        $multistatus->addChild($_) foreach @error;

        $response = HTTP::Response->new( 207 => 'Multi-Status' );
        $response->header( 'Content-Type' => 'text/xml; charset="utf-8"' );
    }
    else {
        $response = HTTP::Response->new( 204 => 'No Content' );
    }
    return $response;
}

sub copy {
    my ( $self, $request, $response ) = @_;
    my $path = uri_unescape $request->uri->path;
    $path =~ s{/+$}{}; # see rt 46865

    # need to modify request to pay attention to destination address.
    my $lockreq = _parse_lock_header( $request );
    $lockreq->{'path'} = uri_unescape( $request->header( 'Destination' ) );
    if ( !$self->_lock_manager()->can_modify( $lockreq ) ) {
        return HTTP::Response->new( 403, 'Forbidden' );
    }
    my $fs   = $self->filesys;

    my $destination = $request->header('Destination');
    $destination = URI->new($destination)->path;
    $destination =~ s{/+$}{}; # see rt 46865

    my $depth     = $request->header('Depth');
    $depth = '' if !defined $depth;

    my $overwrite = $request->header('Overwrite') || 'F';

    if ( $fs->test( "f", $path ) ) {
        return $self->_copy_file( $request, $response );
    }

    my @files = _get_files($fs, $path, $depth);
    my @dirs  = _get_dirs($fs, $path, $depth);

    push @dirs, $path;
    foreach my $dir ( sort @dirs ) {
        my $destdir = $dir;
        $destdir =~ s/^$path/$destination/;
        if ( $overwrite eq 'F' && $fs->test( "e", $destdir ) ) {
            return HTTP::Response->new( 401, "ERROR", $response->headers );
        }
        $fs->mkdir($destdir);
    }

    foreach my $file ( reverse sort @files ) {
        my $destfile = $file;
        $destfile =~ s/^$path/$destination/;
        my $fh = $fs->open_read($file);
        my $file = join '', <$fh>;
        $fs->close_read($fh);
        if ( $fs->test( 'e', $destfile ) ) {
            if ( $overwrite eq 'T' ) {
                $fh = $fs->open_write($destfile);
                print $fh $file;
                $fs->close_write($fh);
            }
            else {
                return HTTP::Response( 412, 'Precondition Failed' );
            }
        }
        else {
            $fh = $fs->open_write($destfile);
            print $fh $file;
            $fs->close_write($fh);
        }
    }

    $response = HTTP::Response->new( 200, 'OK', $response->headers );
    return $response;
}

sub _copy_file {
    my ( $self, $request, $response ) = @_;
    my $path = uri_unescape $request->uri->path;
    my $fs   = $self->filesys;

    my $destination = $request->header('Destination');
    $destination = URI->new($destination)->path;
    my $depth     = $request->header('Depth');
    my $overwrite = $request->header('Overwrite');

    if ( $fs->test( 'd', $destination ) ) {
        return HTTP::Response->new( 204, 'No Content', $response->headers );
    }
    if ( $fs->test( 'f', $path ) && $fs->test( 'r', $path ) ) {
        my $fh = $fs->open_read($path);
        my $file = join '', <$fh>;
        $fs->close_read($fh);
        if ( $fs->test( 'f', $destination ) ) {
            if ( $overwrite eq 'T' ) {
                $fh = $fs->open_write($destination);
                print $fh $file;
                $fs->close_write($fh);
            }
            else {
                return HTTP::Response( 412, 'Precondition Failed' );
            }
        }
        else {
            unless ( $fh = $fs->open_write($destination) ) {
                return HTTP::Response->new( 409, 'Conflict' );
            }
            print $fh $file;
            $fs->close_write($fh);
            $response->code(201);
            $response->message('Created');
        }
    }
    else {
        return HTTP::Response->new( 404, 'Not Found' );
    }

    return $response;
}

sub move {
    my ( $self, $request, $response ) = @_;

    # need to check both paths for locks.
    my $lockreq = _parse_lock_header( $request );
    if ( !$self->_lock_manager()->can_modify( $lockreq ) ) {
        return HTTP::Response->new( 403, 'Forbidden' );
    }
    $lockreq->{'path'} = uri_unescape( $request->header( 'Destination' ) );
    if ( !$self->_lock_manager()->can_modify( $lockreq ) ) {
        return HTTP::Response->new( 403, 'Forbidden' );
    }

    my $destination = $request->header('Destination');
    $destination = URI->new($destination)->path;
    my $destexists = $self->filesys->test( "e", $destination );

    $response = $self->copy( $request, $response );
    $response = $self->delete( $request, $response )
      if $response->is_success;

    $response->code(201) unless $destexists;

    return $response;
}

sub mkcol {
    my ( $self, $request, $response ) = @_;
    my $path = uri_unescape $request->uri->path;

    if ( !$self->_can_modify($request) ) {
        return HTTP::Response->new( 403, 'Forbidden' );
    }

    my $fs   = $self->filesys;

    return HTTP::Response->new( 415, 'Unsupported Media Type' ) if $request->content;
    return HTTP::Response->new( 405, 'Method Not Allowed' ) if $fs->test( 'e', $path );
    $fs->mkdir($path);
    if ( $fs->test( 'd', $path ) ) {
        $response->code(201);
        $response->message('Created');
    }
    else {
        $response->code(409);
        $response->message('Conflict');
    }

    return $response;
}

sub propfind {
    my ( $self, $request, $response ) = @_;
    my $path  = uri_unescape $request->uri->path;
    my $fs    = $self->filesys;
    my $depth = $request->header('Depth');

    my $reqinfo = 'allprop';
    my @reqprops;
    if ( $request->header('Content-Length') ) {
        my $content = $request->content;
        my $parser  = XML::LibXML->new;
        my $doc;
        eval { $doc = $parser->parse_string($content); };
        if ($@) {
            return HTTP::Response->new( 400, 'Bad Request' );
        }

        #$reqinfo = doc->find('/DAV:propfind/*')->localname;
        $reqinfo = $doc->find('/*/*')->shift->localname;
        if ( $reqinfo eq 'prop' ) {

            #for my $node ($doc->find('/DAV:propfind/DAV:prop/*')) {
            for my $node ( $doc->find('/*/*/*')->get_nodelist ) {
                push @reqprops, [ $node->namespaceURI, $node->localname ];
            }
        }
    }

    if ( !$fs->test( 'e', $path ) ) {
        return HTTP::Response->new( 404, 'Not Found' );
    }

    $response->code(207);
    $response->message('Multi-Status');
    $response->header( 'Content-Type' => 'text/xml; charset="utf-8"' );

    my $doc = XML::LibXML::Document->new( '1.0', 'utf-8' );
    my $multistat = $doc->createElement('D:multistatus');
    $multistat->setAttribute( 'xmlns:D', 'DAV:' );
    $doc->setDocumentElement($multistat);

    my @paths;
    if ( defined $depth && $depth eq 1 and $fs->test( 'd', $path ) ) {
        my $p = $path;
        $p .= '/' unless $p =~ m{/$};
        @paths = map { $p . $_ } File::Spec->no_upwards( $fs->list($path) );
        push @paths, $path;
    }
    else {
        @paths = ($path);
    }

    for my $path (@paths) {
        my (
            $dev, $ino, $mode, $nlink, $uid, $gid, $rdev,
            $size, $atime, $mtime, $ctime, $blksize, $blocks
        ) = $fs->stat($path);

        # modified time is stringified human readable HTTP::Date style
        $mtime = time2str($mtime);

        # created time is ISO format
        # tidy up date format - isoz isn't exactly what we want, but
        # it's easy to change.
        $ctime = time2isoz($ctime);
        $ctime =~ s/ /T/;
        $ctime =~ s/Z//;

        $size ||= '';

        my $is_dir = $fs->test( 'd', $path );
        my $resp = _dav_child( $multistat, 'response' );
        my $href = File::Spec->catdir(
                map { uri_escape $_} File::Spec->splitdir($path)
            ) . ( $is_dir && $path !~ m{/$} ? '/' : '');
        $href =~ tr{\\}{/};  # Protection from wrong slashes under Windows.
        _dav_child( $resp, 'href', $href );
        my $okprops = $doc->createElement('D:prop');
        my $nfprops = $doc->createElement('D:prop');
        my $prop;

        if ( $reqinfo eq 'prop' ) {
            my %prefixes = ( 'DAV:' => 'D' );
            my $i = 0;

            for my $reqprop (@reqprops) {
                my ( $ns, $name ) = @$reqprop;
                if ( $ns eq 'DAV:' && $name eq 'creationdate' ) {
                    _dav_child( $okprops, 'creationdate', $ctime );
                }
                elsif ( $ns eq 'DAV:' && $name eq 'getcontentlength' ) {
                    _dav_child( $okprops, 'getcontentlength', $is_dir ? () : ($size) );
                }
                elsif ( $ns eq 'DAV:' && $name eq 'getcontenttype' ) {
                    _dav_child( $okprops, 'getcontenttype', $is_dir ? 'httpd/unix-directory' : 'httpd/unix-file' );
                }
                elsif ( $ns eq 'DAV:' && $name eq 'getlastmodified' ) {
                    _dav_child( $okprops, 'getlastmodified', $mtime );
                }
                elsif ( $ns eq 'DAV:' && $name eq 'resourcetype' ) {
                    $prop = _dav_child( $okprops, 'resourcetype' );
                    if ( $is_dir ) {
                        _dav_child( $prop, 'collection' );
                    }
                }
                elsif ( $ns eq 'DAV:' && $name eq 'lockdiscovery' ) {
                    $prop = _dav_child( $okprops, 'lockdiscovery' );
                    my $user = ($request->authorization_basic())[0]||'';
                    foreach my $lock ( $self->_lock_manager()->list_all_locks({ 'path' => $path, 'user' => $user }) ) {
                        my $active = _active_lock_prop( $doc, $lock );
                        $prop->addChild( $active );
                    }
                }
                elsif ( $ns eq 'DAV:' && $name eq 'supportedlock' ) {
                    $prop = _supportedlock_child( $okprops );
                }
                else {
                    my $prefix = $prefixes{$ns};
                    if ( !defined $prefix ) {
                        $prefix = 'i' . $i++;

                        # mod_dav sets <response> 'xmlns' attribute - whatever
                        #$nfprops->setAttribute("xmlns:$prefix", $ns);
                        $resp->setAttribute( "xmlns:$prefix", $ns );

                        $prefixes{$ns} = $prefix;
                    }

                    $prop = $doc->createElement("$prefix:$name");
                    $nfprops->addChild($prop);
                }
            }
        }
        elsif ( $reqinfo eq 'propname' ) {
            _dav_child( $okprops, 'creationdate' );
            _dav_child( $okprops, 'getcontentlength' );
            _dav_child( $okprops, 'getcontenttype' );
            _dav_child( $okprops, 'getlastmodified' );
            _dav_child( $okprops, 'supportedlock' );
            _dav_child( $okprops, 'resourcetype' );
        }
        else {
            _dav_child( $okprops, 'creationdate', $ctime );
            _dav_child( $okprops, 'getcontentlength', $is_dir ? () : ($size) );
            _dav_child( $okprops, 'getcontenttype', $is_dir ? 'httpd/unix-directory' : 'httpd/unix-file' );
            _dav_child( $okprops, 'getlastmodified', $mtime );
            $prop = _supportedlock_child( $okprops );
            my $user = ($request->authorization_basic())[0]||'';
            my @locks = $self->_lock_manager()->list_all_locks({ 'path' => $path, 'user' => $user });
            if ( @locks ) {
                $prop = _dav_child( $okprops, 'lockdiscovery' );
                foreach my $lock ( @locks ) {
                    my $active = _active_lock_prop( $doc, $lock );
                    $prop->addChild( $active );
                }
            }
            $prop = _dav_child( $okprops, 'resourcetype' );
            if ( $is_dir ) {
                _dav_child( $prop, 'collection' );
            }
        }

        if ( $okprops->hasChildNodes ) {
            my $propstat = _dav_child( $resp, 'propstat' );
            $propstat->addChild($okprops);
            _dav_child( $propstat, 'status', 'HTTP/1.1 200 OK' );
        }

        if ( $nfprops->hasChildNodes ) {
            my $propstat = _dav_child( $resp, 'propstat' );
            $propstat->addChild($nfprops);
            _dav_child( $propstat, 'status', 'HTTP/1.1 404 Not Found' );
        }
    }

    #this must be 0 as certin ms webdav clients choke on 1
    $response->content( $doc->toString(0) );

    return $response;
}

sub _supportedlock_child {
    my ($okprops) = @_;
    my $prop = _dav_child( $okprops, 'supportedlock' );
    #for my $n (qw(exclusive shared)) {  # shared is currently not supported.
    for my $n (qw(exclusive)) {
        my $lock = _dav_child( $prop, 'lockentry' );

        _dav_child( _dav_child( $lock, 'lockscope' ), $n );
        _dav_child( _dav_child( $lock, 'locktype' ), 'write' );
    }

    return $prop;
}

sub _get_files {
    my ($fs, $path, $depth) = @_;
    reverse map { s{/+}{/}g;s{/$}{}; $_ }
    (defined $depth && $depth =~ m{\A\d+\z}) ?
      File::Find::Rule::Filesys::Virtual->virtual($fs)->file->maxdepth($depth)->in($path)
      : File::Find::Rule::Filesys::Virtual->virtual($fs)->file->in($path)
      ;
}

sub _get_dirs {
    my ($fs, $path, $depth) = @_;
    return reverse sort
    grep { $_ !~ m{/\.\.?$} }
    map { s{/+}{/}g;s{/$}{}; $_ }
    (defined $depth && $depth =~ m{\A\d+\z}) ?
       File::Find::Rule::Filesys::Virtual->virtual($fs)->directory->maxdepth($depth)->in($path)
       : File::Find::Rule::Filesys::Virtual->virtual($fs)->directory->in($path)
       ;
}

1;

__END__

=head1 NAME

Net::DAV::Server - Provide a DAV Server

=head1 SYNOPSIS

  my $filesys = Filesys::Virtual::Plain->new({root_path => $cwd});
  my $webdav = Net::DAV::Server->new();
  $webdav->filesys($filesys);

  my $d = HTTP::Daemon->new(
    LocalAddr => 'localhost',
    LocalPort => 4242,
    ReuseAddr => 1) || die;
  print "Please contact me at: ", $d->url, "\n";
  while (my $c = $d->accept) {
    while (my $request = $c->get_request) {
      my $response = $webdav->run($request);
      $c->send_response ($response);
    }
    $c->close;
    undef($c);
  }

=head1 DESCRIPTION

This module provides a WebDAV server. WebDAV stands for "Web-based
Distributed Authoring and Versioning". It is a set of extensions to
the HTTP protocol which allows users to collaboratively edit and
manage files on remote web servers.

Net::DAV::Server provides a WebDAV server and exports a filesystem for
you using the Filesys::Virtual suite of modules. If you simply want to
export a local filesystem, use Filesys::Virtual::Plain as above.

This module doesn't currently provide a full WebDAV
implementation. However, I am working through the WebDAV server
protocol compliance test suite (litmus, see
http://www.webdav.org/neon/litmus/) and will provide more compliance
in future. The important thing is that it supports cadaver and the Mac
OS X Finder as clients.

=head1 AUTHOR

Leon Brocard <acme@astray.com>

=head1 MAINTAINERS

  G. Wade Johnson <wade@cpanel.net>  ( co-maintainer )
  Erin Schoenhals <erin@cpanel.net>  ( co-maintainer )
  Bron Gondwana <perlcode@brong.net> ( co-maintainer )
  Leon Brocard <acme@astray.com>     ( original author )

The latest copy of this package can be checked out using Subversion
from http://svn.brong.net/netdavserver/release

Development code at http://svn.brong.net/netdavserver/trunk


=head1 COPYRIGHT

Copyright (C) 2004, Leon Brocard
Changes copyright (c) 2010, cPanel, Inc.

This module is free software; you can redistribute it or modify it under
the same terms as Perl itself.

=cut

1
