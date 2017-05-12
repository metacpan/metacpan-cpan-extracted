package TemplateM; # $Id: TemplateM.pm 10 2013-07-08 14:37:29Z abalama $
use strict;

=head1 NAME

TemplateM - *ML templates processing module 

=head1 VERSION

Version 3.03

=head1 SYNOPSIS

    use TemplateM;
    use TemplateM 'simple';

    my $template = new TemplateM(
            -url => 'http://localhost/foo.shtml',
            -utf8 => 1,
        );
    
    my $template = new TemplateM( -file => 'ftp://login:password@192.168.1.1/foo.shtml' );
    my $template = new TemplateM( -file => 'foo.shtml' );
    my $template = new TemplateM( -file => \*DATA );

    # GALORE (DEFAULT):

    my $block = $template->start( 'block_label' );
    $block->loop( foo => 'value1', bar => 'value2', ... );

    $template->stash( foo => 'value1', bar => 'value2', ... );
    $block->stash( baz => 'value1', ... );

    $template->ifelse( "ifblock_label", $predicate )
    $block->ifelse( "ifblock_label", $predicate )

    print $block->output;

    $block->finish;

    print $template->output;
    print $template->html( "Content-type: text/html\n\n" );
    
    # OBSOLETE:

    $template->cast( {foo => 'value1', bar => 'value2', ... } );
    my %h = ( ... );
    $template->cast( \%h );

    $template->cast_loop ( "block_label", {foo => 'value1', bar => 'value2', ... } );
    $template->finalize ( "block_label" );

    $template->cast_if( "block_label", $predicate );

=head1 ABSTRACT

The TemplateM module means for text templates processing in XML, HTML, TEXT and so on formats. 
TemplateM is the alternative to most of standard modules, and it can accomplish remote access 
to template files, has simple syntax, small size and flexibility. Then you use TemplateM, 
functionality and data are completely separated, this is quality of up-to-date web-projects.

=head1 TERMS

=head2 Scheme

Set of methods prodiving process template's structures.

=head2 Template

File or array of data which represents the set of instructions, directives and tags of markup 
languages and statistics.

=head2 Directive

Name of structure in a template for substitution. There are a number of directives:

    cgi, val, do, loop, if, endif, else, endelse

=head2 Structure

Structure is the tag or the group of tags in a template which defining a scope of substitution.
The structure consist of tag <!-- --> and formatted content:

    DIRECTIVE: LABEL

The structure can be simple or complex. Simple one is like this:

    <!-- cgi: foo -->
    or
    <!-- val: bar -->

Complex structure is the group of simple structures which constitutive a "section"

    <!-- do: foo -->
    ...
        <!-- val: bar -->
    ...
    <!-- loop: foo -->

    even so:

    <!-- if: foo -->
    ...
    <!-- endif: foo -->
    <!-- else: foo -->
    ...
    <!-- endelse: foo -->

=head2 Label

This is identifier of structure. E.g. foo, bar, baz

    <!-- cgi: foo -->

=head1 DESCRIPTION

=head2 SCHEMES

While defining use it can specify 2 accessible schemes - galore (default) or simple.
It is not obligatory to point at default scheme.

Simple scheme is basic and defines using of basic methods:

C<cast, cast_if, cast_loop, finalize and html>

Simple scheme methods is expedient for small-datasize projects.

Galore (default) scheme is the alternative for base scheme and it defines own set of methods:

C<stash, start, loop, finish, ifelse, output and html>

In order to get knowing which of schemes is activated you need to invoke methods either module() 
or scheme()

    my $module = $template->module;
    my $module = $template->scheme;

In order to get know real module name of the used scheme it's enough to read property 'module' 
of $template object

    my $module = $template->{module};

=head2 CONSTRUCTOR

Constructor new() is the principal method independent of selected scheme. Almost simple way to use 
the constructor is:

    my $template = new TemplateM( -template => "blah-blah-blah" );

This invoking takes directive to use simple text as template.

Below is the attribute list of constructor:

=over 8

=item B<asfile>

B<Asfile flag> designates either path or filehandle to file is passed for reading from disk, bypassing 
the method of remote obtaining of a template.

=item B<cache>

B<Cache> is the absolute or relative path to directory for cache files storage. This directory needs
to have a permission to read and write files.
When B<cache> is missed caching is disabled. Caching on is recommended for faster module operations.

=item B<file, url, uri>

B<Template filename> is the filename, opened filehandler (GLOB) or locations of a template. 
Supports relative or absolute pathes,
and also template file locator. Relative path can forestall with ./ prefix or without it.
Absolute path must be forestall with / prefix. Template file locator is the URI formatted string.
If the file is missed, it use "index.shtml" from current directory as default value.

Value represent "Uniform Resource Identifier references" as specified in RFC 2396 (and updated 
by RFC 2732). See L<URI> for details.

=item B<header>

B<HTTP header> uses as value by default before main content template print (method html).

    my $template = new TemplateM( -header => "Content-type: text/html; charset=UTF-8\n\n");
    print $template->html;

=item B<login & password>

B<User Login> and B<user password> are data for standard HTTP-authorization.
Login and password will be used when the template defined via locator and when remote access is
protected by HTTP-authorization of remote server. When user_login is missed the access to remote
template file realizes simplified scheme, without basic HTTP-authorization.

=item B<method>

B<Request method> points to method of remote HTTP/HTTPS access to template page. Can take values: "GET", 
"HEAD", "PUT" or "POST". HEAD methods can be used only for headers getting.

=item B<onutf8 or utf8>

B<onutf8 flag> turn UTF8 mode for access to a file. The flag allow to get rid of a forced setting utf-8 
flag for properties template and work by method Encode::_utf8_on() 

=item B<template>

B<HTTP content> (template). This attribute has to be defined when template content is not
able to get from a file or get it from remote locations. E.g. it has to be defined when
a template selects from a database. Defining of this attribute means disabling of
precompile result caching! 

=item B<timeout>

B<Timeout> is the period of cache file keeping in integer seconds.
When the value is missed cache file "compiles" once and will be used as template.
Positive value has an effect only then template file is dynamic and it changes in time.
Previous versions of the module sets value 20 instead 0 by default.
It had to set the value -1 for "compilation" disabling.
For current version of the module value can be 0 or every positive number. 0 is
equivalent -1 of previous versions of the module.

=item B<reqcode>

B<Request code> is the pointer to the subroutine must be invoked for HTTP::Request object 
after creation via method new.

Sample:

    -reqcode => sub { 
        my $req = shift;
        ...
        $req-> ...
        ...
        return 1;
    }

=item B<rescode>

B<Response code> is the pointer to the subroutine must be invoked for HTTP::Response after 
creation via calling $ua->request($req).

Sample:

    -rescode => sub { 
        my $res = shift;
        ...
        $res-> ...
        ...
        return 1;
    }      

=item B<uacode>

B<UserAgent code> is the pointer to the subroutine must be invoked for LWP::UserAgent after 
creation via method new().

Sample:

    -uacode => sub { 
        my $ua = shift;
        ...
        $ua-> ...
        ...
        return 1;
    }

=item B<uaopts>

B<UserAgent options> is the pointer to the hash containing options for defining parameters of 
UserAgent object's constructor. (See LWP::UserAgent)

Example:

    -uaopts => {
        agent                 => "Mozilla/4.0",
        max_redirect          => 10,
        requests_redirectable => ['GET','HEAD','POST'],
        protocols_allowed     => ['http', 'https'], # Required Crypt::SSLeay
        cookie_jar            => new HTTP::Cookies(
                file     => File::Spec->catfile("/foo/bar/_cookies.dat"),
                autosave => 1 
            ),
        conn_cache            => new LWP::ConnCache(),
    }

=back

=head2 SIMPLE SCHEME METHODS (BASIC METHODS) 

It is enough to define the module with 'simple' parameter for using of basic methods.

    use TemplateM 'simple';

After that only basic metods will be automatically enabled.

=head3 cast

Modification of labels (cgi labels)

    $template->cast({label1=>value1, label2=>value2, ... });

=over 8

=item B<label>

B<Label> - name will be replaced with appropriate L<value> in tag <!-- cgi: label -->

=item B<value>

B<Value> - Value, which CGI-script sets. Member of the L<label> manpage

=back

=head3 cast_loop

Block labels modification (val labels)

    $template->cast_loop (block_label, {label1=>value1, label2=>value2, ... }]);

=over 8

=item block_label

B<Block label> - Block identification name.
The name will be inserted in tags <!-- do: block_label --> and <!-- loop: block_label --> - all content
between this tags processes like labels, but the tag will be formed as <!-- val: label -->

=back

=head3 finalize

Block finalizing

    $template->finalize(block_label);

Block finalizing uses for not-processed blocks deleting. You need use finalizing every time you use blockes.

=head3 cast_if

    $template->cast_if(ifblock_label, predicate);

Method analyses boolean value of predicate. If value is true, the method prints if-structure content only.

    <!-- if: label -->
        ... blah blah blah ...
    <!-- end_if: label -->

otherwise the method prints else-structure content only.

    <!-- else: label -->
        ... blah blah blah ...
    <!-- end_else: label -->

=head3 html

Template finalizing

    print $template->html(-header=>HTTP_header);
    print $template->html(HTTP_header);
    print $template->html;

The procedure will return formed document after template processing.
if header is present as argument it will be added at the beginning of template's return.

=head2 GALORE SCHEME METHODS (DEFAULT)

It is enough to define the module with parameter 'galore' for using of galore scheme methods.

    use TemplateM;
    use TemplateM 'galore';

=head3 stash

stash (or cast) method is the function of import variables value into template.

    $template->stash(title => 'PI' , pi => 3.1415926);

This example demonstrate how all of <!-- cgi: title --> and <!-- cgi: pi --> structures
will be replaced by parameters of stash method invoking.

In contrast to default scheme, in galore scheme stash method process directives <!-- cgi: label --> only
with defined labels when invoking, whereas cast method of default scheme precess all of
directives <!-- cgi: label --> in template!

=head3 start and finish

Start method defines the beginning of loop, and finish method defines the end.
Start method returns reference to the subtemplate object, that is all between do and loop directives.

    <!-- do: block_label -->
        ... blah blah blah ...
            <!-- val: label1 -->
            <!-- val: label2 -->
            <!-- cgi: label -->
        ... blah blah blah ...
    <!-- loop: block_label -->

    my $block = $template->start(block_label);
    ...
    $block->finish;

For acces to val directives it is necessary to use loop method, and for access to cgi directives use stash method.

=head3 loop

The method takes as parameters a hash of arguments or a reference to this hash.

    $block->loop(label1 => 'A', label2 => 'B');
    $block->loop({label1 => 'A', label2 => 'B'});

Stash method also can be invoked in $block object context.

    $block->stash(label => 3.1415926);

=head3 ifelse

    $template->ifelse("ifblock_label", $predicate)
    $block->ifelse("ifblock_label", $predicate)

Method is equal to cast_if method of default scheme. The difference, ifelse method
can be processed with $template or $block, whereas cast_if method has deal with $template object.

=head3 output

The method returns result of template processing. Output method has deal with $template and $block object:

    $block->output;
    $template->output;

=head3 html

The method is completely equal to html method of default scheme.

=head2 EXAMPLE

In test.pl file:

    use TemplateM;

    my $tpl = new TemplateM(
        -file   => 'test.tpl',
        -asfile => 1,
    );

    $tpl->stash(
        module  => (split(/\=/,"$tpl"))[0],
        version => $tpl->VERSION,
        scheme  => $tpl->scheme()." / ".$tpl->{module},
        date    => scalar(localtime(time())),
    );

    my $row_box = $tpl->start('row');
    foreach my $row ('A'..'F') {
        $row_box->loop({});
        my $col_box = $row_box->start('col');
        foreach my $col (1...6) {
            $col_box->loop( foo  => $row.$col );
            $col_box->cast_if(div=>(
                    ('A'..'F')[$col-1] ne $row
                    &&
                    ('A'..'F')[6-$col] ne $row
                ));
        }
        $col_box->finish;
    }
    $row_box->finish;

    binmode STDOUT, ':raw';
    print $tpl->output();

In test.tpl file:

    **********************
    *                    *
    *  Simple text file  *
    *                    *
    **********************

    Table
    =====
    <!-- do: row -->
    +-----------------+
    |<!-- do: col --><!-- if: div --><!-- val: foo --><!-- endif: div -->
    <!-- else: div -->  <!-- endelse: div -->|<!-- loop: col --><!-- loop: row -->
    +-----------------+

    Data
    ====

    Module       : <!-- cgi: module -->
    Version      : <!-- cgi: version -->
    Scheme       : <!-- cgi: scheme -->
    Current date : <!-- cgi: date -->

Result:

    **********************
    *                    *
    *  Simple text file  *
    *                    *
    **********************

    Table
    =====

    +-----------------+
    |  |A2|A3|A4|A5|  |
    +-----------------+
    |B1|  |B3|B4|  |B6|
    +-----------------+
    |C1|C2|  |  |C5|C6|
    +-----------------+
    |D1|D2|  |  |D5|D6|
    +-----------------+
    |E1|  |E3|E4|  |E6|
    +-----------------+
    |  |F2|F3|F4|F5|  |
    +-----------------+

    Data
    ====

    Module       : TemplateM
    Version      : 3.02
    Scheme       : galore / GaloreWin32
    Current date : Sat Dec 18 12:37:10 2010

=head2 TEMPLATEM'S AND SSI DIRECTIVES

The module can be used with SSI directives together, like in this shtml-sample:

    <html>
        <!--#include virtual="head.htm"-->
    <body>
        <center><!-- cgi: head --><center>
        <!-- do: BLOCK_P -->
            <p><!-- val: content --></p>
        <!-- loop: BLOCK_P -->
    </body>
    </html>

=head1 ENVIRONMENT

No environment variables are used.

=head1 BUGS

Please report them.

=head1 SEE ALSO

L<LWP>, L<URI>

=head1 DIAGNOSTICS

The usual warnings if it cannot read or write the files involved.

=head1 HISTORY

=over 8

=item B<1.00 / 01.05.2006>

Init version

=back

See C<CHANGES> file for details

=head1 TO DO

See C<TODO> file    

=head1 THANKS

Thanks to Dmitry Klimov for technical translating L<http://fla-master.com>.

=head1 AUTHOR

Serz Minus (Lepenkov Sergey) L<http://www.serzik.ru> E<lt>minus@mail333.comE<gt>

=head1 COPYRIGHTS

Copyright (C) 1998-2013 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms and 
conditions as Perl itself.

=cut

use vars qw($VERSION);
our $VERSION = 3.03;
our @ISA;

use Encode;
use Carp qw/croak confess carp cluck/;
use File::Spec;

use TemplateM::Util;

use URI;
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Response;
use HTTP::Headers;

my $mpflag = 0;
if (exists $ENV{MOD_PERL}) {
    if (exists $ENV{MOD_PERL_API_VERSION} && $ENV{MOD_PERL_API_VERSION} == 2) {
        $mpflag = 2;
        require Apache2::Response;
        require Apache2::RequestRec;
        require Apache2::RequestUtil;
        require Apache2::RequestIO;
        require Apache2::ServerRec;
        require APR::Pool;
    } else {
        $mpflag = 1;
        require Apache;
    }
}

my $os = $^O || 'Unix';
my %modules = (
        galore  => ($os eq 'MSWin32' or $os eq 'NetWare') ? "GaloreWin32" : "Galore",
        simple  => "Simple",
    );
my $module;

sub import {
    my ($class, @args) = @_;
    my $mdl = shift(@args) || 'default';
    $module = $modules{lc($mdl)} || $modules{galore};
    require "TemplateM/$module.pm";
    @ISA = ("TemplateM::$module");
}

BEGIN {
    sub errstamp { "[".(caller(1))[3]."]" }
}

sub new {
    my $class = shift;
    my @arg = @_;
    
    # GET Args
    my ($file, $login, $password, $cachedir, $timeout, $header, $template, 
        $asfile, $onutf8, $method, $uaopt, $uacode, $reqcode, $rescode);
    ($file, $login, $password, $cachedir, $timeout, $header, $template,
        $asfile, $onutf8, $method, $uaopt, $uacode, $reqcode, $rescode) = read_attributes(
        [
            [qw/FILE FILENAME URL URI/],
            [qw/LOGIN USER/],
            [qw/PASSWORD PASSWD PASS/],
            [qw/CACHE CACHEFILE CACHEDIR/],
            [qw/TIMEOUT TIME INTERVAL/],
            [qw/HEAD HEADER/],
            [qw/TEMPLATE TPL TMPL TPLT TMPLT CONTENT DATA/],
            
            [qw/ASFILE ONFILE/],
            [qw/UTF8 UTF-8 ONUTF8 ASUTF8 UTF8ON UTF8_ON ON_UTF8 USEUTF8/],
            [qw/METH METHOD/], #  "GET", "HEAD", "PUT" or "POST".
            [qw/UAOPT UAOPTS UAOPTION UAOPTIONS UAPARAMS/],
            
            [qw/UACODE/],
            [qw/REQCODE/],
            [qw/RESCODE/],
            
        ], @arg ) if defined $arg[0];

    # DEFAULTS & BLESS
    $file ||= 'index.shtml';
    my $url = ''; # URL resource
    my $cache = '';
    if (ref $file eq 'GLOB') {
        $asfile = 1;
    } else {
        $cache = _get_cachefile($cachedir, $file);
    }

    unless (defined $template) {
        if ($asfile) {
            $template = _load_file($file, $onutf8);
        } else {
            if ( _timeout_ok($cache, $timeout) ) {
                if ($file =~/^\//) { # abs path (/foo/bar/baz)
                    $url = _get_uri($file, 0);
                } elsif ($file =~/^\w+\:\/\//) { # Full URL (http://foo/bar/baz)
                    $url = $file;
                } else { # relation or other (foo/bar/baz)
                    $url = _get_uri($file, 1);
                }   
            
                $template = _load_url(
                        $url, $login, $password, $onutf8, $method,
                        $uaopt, $uacode, $reqcode, $rescode
                    );
                if ($cache) {
                    if ($template eq '') {
                        $template = _load_cache($cache, $onutf8);
                    } else {
                        _save_cache($cache, $onutf8, $template);
                    }
                }
            } else {
                $template = _load_cache($cache, $onutf8) if $cache;
            }
        }
    }

    $template = '' unless defined($template);
    Encode::_utf8_on($template) if $onutf8;

    my $stk = $modules{galore} eq "GaloreWin32" ? [] : '';

    my $self = bless {
            timeout  => $timeout  || 0,
            file     => $file     || '',
            url      => $url,
            login    => $login    || '',
            password => $password || '',
            cachedir => $cachedir || '',
            cache    => $cache    || '',
            template => $template,
            header   => $header   || '',
            module   => $module   || '',
            # Galore
            work     => $template,
            stackout => $stk,
            looparr  => {}
        }, $class;

    return $self;
}
sub module {
    my $self = shift;
    my %hm = reverse %modules;
    lc($hm{$self->{module}})
}
sub scheme { goto &module }
sub schema { goto &module }
sub AUTOLOAD {
    my $self = shift;
    $self->html(@_)
}
sub DESTROY {
    my $self = shift;
    undef($self);
}

sub _load_url {
    my $url      = shift || '';
    my $login    = shift || '';
    my $password = shift || '';
    my $onutf8   = shift || 0;
    my $method   = shift || 'GET';
    my $uaopt    = shift || {};
    my $uscode   = shift || undef;
    my $reqcode  = shift || undef;
    my $rescode  = shift || undef;

    my $html = '';
    my $uri_url = new URI($url);

    my $ua  = new LWP::UserAgent(%$uaopt); 
    $uscode->($ua) if ($uscode && ref($uscode) eq 'CODE');
    my $req = new HTTP::Request(uc($method), $uri_url);
        $req->authorization_basic($login, $password) if $login;
        $reqcode->($req) if ($reqcode && ref($reqcode) eq 'CODE');
    my $res = $ua->request($req);
        $rescode->($res) if ($rescode && ref($rescode) eq 'CODE');
    if ($res->is_success) {
        if ($onutf8) {
            $html = $res->decoded_content;
            $html = '' unless defined($html);
            Encode::_utf8_on($html);
        } else {
            $html = $res->content;
            $html = '' unless defined($html);
        }
    } else {
        carp(errstamp," An error occurred while trying to obtain the resource \"$url\" (",$res->status_line,")");
    }

    return $html;
}
sub _save_cache {
    my $cf      = shift || '';
    my $onutf8  = shift;
    my $content = shift || '';
    my $OUT;

    my $flc = 0;
    if (ref $cf eq 'GLOB') {
       $OUT = $cf;
    } else {
        open $OUT, '>', $cf or croak(errstamp," An error occurred while trying to write in file \"$cf\" ($!)");
        flock $OUT, 2 or croak(errstamp," An error occurred while blocking in file \"$cf\" ($!)");
        $flc = 1;
    }

    binmode $OUT, ':raw:utf8' if $onutf8;
    binmode $OUT unless $onutf8;
    print $OUT $content;
    close $OUT if $flc;
    return 1;
}
sub _load_cache {
    my $cf = shift || '';
    my $onutf8 = shift;
    my $IN;

    if ($cf && -e $cf) {
        if (ref $cf eq 'GLOB') {
            $IN = $cf;
        } else {
            open $IN, '<', $cf or croak(errstamp," An error occurred while trying to read from file \"$cf\" ($!)");
        }
        binmode $IN, ':raw:utf8' if $onutf8;
        binmode $IN unless $onutf8;
        my $outdata = scalar(do { local $/; <$IN> });
        Encode::_utf8_on($outdata) if $onutf8;
        close $IN;
        return $outdata;
    } else {
        carp(errstamp," An error occurred while opening file \"$cf\" ($!)");
    }
    return '';
}
sub _load_file {
    my $fn     = shift || '';
    my $onutf8 = shift;
    my $IN;

    if (ref $fn eq 'GLOB') {
        $IN = $fn;
    } else {
        open $IN, '<', $fn or croak(errstamp," An error occurred while trying to read from file \"$fn\" ($!)");
    }
    binmode $IN, ':raw:utf8' if $onutf8;
    binmode $IN unless $onutf8;
    my $outdata = scalar(do { local $/; <$IN> });
    Encode::_utf8_on($outdata) if $onutf8;
    close $IN;
    return $outdata;
}
sub _timeout_ok {
    my $cachefile = shift || '';
    my $timeout   = shift || 0;

    return 1 unless $cachefile && -e $cachefile;

    my @statfile = stat($cachefile);

    return 0 unless $timeout;

    if ((time()-$statfile[9]) > $timeout) {
        return 1;
    } else {
        return 0;
    }
}
sub _get_cachefile {
    my ($dir, $file) = @_;
    return '' unless $dir;

    $file=~s/[.\/\\:?&%]/_/g;

    return File::Spec->catfile($dir,$file)
}
sub _get_uri {
    my $file = shift || '';
    my $tp   = shift || 0;
    return '' unless $file;

    my $request_uri = $ENV{REQUEST_URI} || '';
    my $hostname    = $ENV{HTTP_HOST}   || '';
    my $server_port = $ENV{SERVER_PORT} || '';

    my $r;
    if ($mpflag) {
        if ($mpflag == 2) {
            # mod_perl 2
            eval('$r = Apache2::RequestUtil->request()');
        } elsif ($mpflag == 1) {
            # mod_perl 1
            eval('$r = Apache->request()');
        }
        $request_uri = $r->uri();
        $hostname    = $r->hostname();
        $server_port = $r->server->port();
        
        # Artifact #137: correct hostname value
        if ($server_port && $server_port !~ /^(80|443)$/) {
            if ($hostname && $hostname !~ /\:\d+$/) {
                $hostname = $hostname . ':'. $server_port;
            }
        }
    }

    $request_uri =~ s/\?.+$//;
    $request_uri = ($request_uri =~ /^\/(.+\/).*/ ? $1 : '');

    my $url = "http://";
    $url = "https://" if $server_port eq '443';

    if ($tp == 1) {
        # 1 - relation path or other (foo/bar/baz)
        $file =~ s/^\.?\/+//;
        if ($hostname) {
            $url .= $hostname.'/'.$request_uri.$file;
        } else {
            $url = "file://$file";
        }
    } else {
        # 0 - absolute path (/foo/bar/baz)
        if ($hostname) {
            $url .= $hostname.$file;
        } else {
            $url = "file:/$file";
        }
    }

    return $url;
}

1;

__END__
