# please insert nothing before this line: -*- mode: cperl; cperl-indent-level: 4; cperl-continued-statement-offset: 4; indent-tabs-mode: nil -*-

package ModPerl2::Tools;

use 5.008008;
use strict;
use warnings;
no warnings 'uninitialized';

use Apache2::RequestUtil ();
use POSIX ();

our $VERSION = '0.10';

sub close_fd {
    my %save=(2=>1);       # keep STDERR
    undef @save{@{$_[0]}} if( @_ and ref $_[0] eq 'ARRAY' );

    if( $^O eq 'linux' and opendir my $d, "/proc/self/fd" ) {
        # Don't try to C<while( my $fd=readdir $d )> here. For really large
        # directories it may require several read operations on the directory.
        # So, with the loop above there is a chance that $d is closed before
        # it could be read completely. Unfortunately, C<fileno DIRHANDLE>
        # is not supported by perl. Hence, the fd cannot be inserted into
        # %save. So, we need to read the complete directory *before* closing
        # any fds.
        for my $fd (readdir $d) {
            next unless $fd=~/^\d+$/;
            POSIX::close $fd unless exists $save{$fd};
        }
    } else {
        my $max_fd=POSIX::sysconf(&POSIX::_SC_OPEN_MAX);
        $max_fd=1000 unless $max_fd>0;
        for( my $fd=0; $fd<$max_fd; $fd++ ) {
            POSIX::close $fd unless exists $save{$fd};
        }
    }

    # now reopen std{in,out} on /dev/null
    open(STDIN,  '<', '/dev/null') unless exists $save{0};
    open(STDIN,  '>', '/dev/null') unless exists $save{1};
}

sub spawn {
    my ($daemon_should_survive_apache_restart, @args)=@_;

    local $SIG{CHLD}='IGNORE';
    my $pid;
    pipe my ($rd, $wr) or return;
    # yes, even fork can fail
    select undef, undef, undef, .1 while( !defined($pid=fork) );
    unless( $pid ) {            # child
        close $rd;
        # 2nd fork to cut parent relationship with a mod_perl apache
        select undef, undef, undef, .1 while( !defined($pid=fork) );
        if( $pid ) {
            print $wr $pid;
            close $wr;
            POSIX::_exit 0;
        } else {
            close $wr;
            if( ref($daemon_should_survive_apache_restart) ) {
                close_fd($daemon_should_survive_apache_restart->{keep_fd});
                POSIX::setsid if( $daemon_should_survive_apache_restart->{survive} );
            } else {
                close_fd;
                POSIX::setsid if( $daemon_should_survive_apache_restart );
            }

            if( 'CODE' eq ref $args[0] ) {
                my $f=shift @args;
                # TODO: restore %ENV and exit() behavior
                eval {$f->(@args)};
                CORE::exit 0;
            } else {
                {exec @args;}         # extra block to suppress a warning
                POSIX::_exit -1;
            }
        }
    }
    close $wr;
    $pid=readline $rd;
    waitpid $pid, 0;            # avoid a zombie on some OS

    return $pid;
}

sub safe_die {
    my ($status)=@_;

    Apache2::RequestUtil->request->safe_die($status);
}

sub fetch_url {
    my ($url)=@_;

    Apache2::RequestUtil->request->fetch_url($url);
}

{
    package
        Apache2::Filter;

    use Apache2::Filter ();
    use Apache2::FilterRec ();
    use Apache2::HookRun ();
    use ModPerl::Util ();
    use Apache2::Const -compile=>qw/OK/;

    sub safe_die {
        my ($I, $status)=@_;

        # avoid further invocation
        $I->remove;

        unless( $I->r->headers_sent ) {
            $I->r->status_line(undef);
            $I->r->die($status);
        }

        ModPerl::Util::exit 0;
    }
}

{
    package
        ModPerl2::Tools::Filter;

    use Apache2::Filter ();
    use APR::Brigade ();
    use APR::Bucket ();
    use base 'Apache2::Filter';
    use Apache2::Const -compile=>qw/OK DECLINED HTTP_OK/;

    sub read_bb {
        my ($bb, $buffer)=@_;

        my $eos=0;

        while( my $b=$bb->first ) {
            $eos++ if $b->is_eos;
            $b->read(my $bdata);
            push @{$buffer}, $bdata if $buffer and length $bdata;
            $b->delete;
        }

        return $eos;
    }

    sub fetch_content_filter : FilterRequestHandler {
        my ($f, $bb)=@_;

        unless( $f->ctx ) {
            unless( $f->r->status==Apache2::Const::HTTP_OK or
                    $f->r->pnotes->{force_fetch_content} ) {
                $f->remove;
                return Apache2::Const::DECLINED;
            }
            $f->ctx(1);
        }

        my $out=$f->r->pnotes->{out};
        if( 'ARRAY' eq ref $out ) {
            read_bb $bb, $out;
        } elsif( 'CODE' eq ref $out ) {
            read_bb $bb, my $buf=[];
            $out->($f->r, @$buf);
        } else {
            $f->remove;
            return Apache2::Const::DECLINED;
        }

        return Apache2::Const::OK;
    }
}

{
    package
        Apache2::RequestRec;

    use Apache2::RequestRec ();
    use Apache2::SubRequest ();
    use APR::Table ();
    use APR::Finfo ();
    use APR::Const -compile=>qw/FILETYPE_REG/;
    use Apache2::Const -compile=>qw/HTTP_OK OK HTTP_NOT_FOUND/;
    use Apache2::Filter ();
    use Apache2::FilterRec ();
    use Apache2::Module ();
    use ModPerl::Util ();

    sub headers_sent {
        my ($I)=@_;

        # Check if any output has already been sent. If so the HTTP_HEADER
        # filter is missing in the output chain. If it is still present we
        # can send a normal error message or modify headers, see ap_die()
        # in httpd-2.2.x/modules/http/http_request.c.

        for( my $n=$I->output_filters; $n; $n=$n->next ) {
            return if $n->frec->name eq 'http_header';
        }

        # http_header filter missing -- that means headers are sent
        return 1;
    }

    sub safe_die {
        my ($I, $status)=@_;

        unless( $I->headers_sent ) {
            $I->status($status);
            $I->status_line(undef);
        }

        ModPerl::Util::exit 0;
    }

    sub fetch_url {
        my ($I, $url, $headers, $outfn)=@_;
        if( @_==3 and ref $headers eq 'CODE' ) {
            $outfn=$headers;
            undef $headers;
        }

        my $output=[];
        my $proxy=$url=~m!^\w+?://!;
        my $subr;
        if( $proxy ) {
            return unless Apache2::Module::loaded('mod_proxy.c');
            $subr=$I->lookup_uri('/');
        } else {
            $subr=$I->lookup_uri($url);
        }
        if( $subr->status==Apache2::Const::HTTP_OK and
            (length($subr->handler) ||
             $subr->finfo->filetype==APR::Const::FILETYPE_REG) ) {
            @{$subr->pnotes}{qw/out force_fetch_content/}=($outfn||$output,1);
            $subr->add_output_filter
                (\&ModPerl2::Tools::Filter::fetch_content_filter);
            if( $proxy ) {
                $subr->proxyreq(2);
                $subr->filename("proxy:".$url);
                $subr->handler('proxy_server');
            }
            $subr->headers_in->clear;
            if( $headers ) {
                for( my $i=0; $i<@$headers; $i+=2 ) {
                    $subr->headers_in->add(@{$headers}[$i, $i+1]);
                }
            }
            $subr->headers_in->add('User-Agent', "ModPerl2::Tools/$VERSION")
                unless exists $subr->headers_in->{'User-Agent'};
            $_=$I->headers_in->{Host} and $subr->headers_in->add('Host', $_)
                unless exists $subr->headers_in->{'Host'};
            $subr->run;
            if( wantarray ) {
                my (%hout);
                $hout{STATUS}=$subr->status;
                $hout{STATUSLINE}=$subr->status_line;
                $subr->headers_out->do(sub {$hout{lc $_[0]}=$_[1]; 1});
                return (join('', @$output), \%hout);
            } else {
                return join('', @$output);
            }
        }
        if( wantarray ) {
            my (%hout);
            $hout{STATUS}=$subr->status;
            $hout{STATUS}=Apache2::Const::HTTP_NOT_FOUND
                if $hout{STATUS}==Apache2::Const::HTTP_OK;
            $subr->headers_out->do(sub {$hout{lc $_[0]}=$_[1]; 1});
            return (undef, \%hout);
        } else {
            return;
        }
        return;
    }
}

1;

__END__

=encoding utf8

=head1 NAME

ModPerl2::Tools - a few hopefully useful tools

=head1 SYNOPSIS

 use ModPerl2::Tools;

 ModPerl2::Tools::spawn +{keep_fd=>[3,4,7], survive=>1}, sub {...};
 ModPerl2::Tools::spawn +{keep_fd=>[3,4,7], survive=>1}, qw/bash -c .../;

 ModPerl2::Tools::safe_die $status;
 $r->safe_die($status);
 $f->safe_die($status);

 $content=ModPerl2::Tools::fetch_url $url;
 $content=$r->fetch_url($url);

=head1 DESCRIPTION

This module is a collection of functions and methods that I found useful
when working with C<mod_perl>. I work mostly under Linux. So, I don't expect
all of these functions to work on other operating systems.

=head2 Forking off long running processes

Sometimes one needs to spawn off a long running process as the result of
a request. Under modperl this is not as simple as calling C<fork>
because that way all open file descriptors would be inherited by the
child and, more subtle, the long running process would be killed when the
administrator shuts down the web server. The former is usually considered
a security issue, the latter a design decision.

There is already
L<< $r->spawn_proc_prog|Apache2::SubProcess/"spawn_proc_prog" >>
that serves a similar purpose as the C<spawn> function.
However, C<spawn_proc_prog> is not usable for long running processes
because it kills the children after a certain timeout.

=head3 Solution

 $pid=ModPerl2::Tools::spawn \%options, $subroutine, @parameters;

or

 $pid=ModPerl2::Tools::spawn \%options, @command_line;

C<spawn> expects as the first parameter an options hash reference.
The second parameter may be a code reference or a string.

In case of a code ref no other program is executed but the subroutine
is called instead. The remaining parameters are passed to this function.

Note, the perl environment under modperl differs in certain ways from
a normal perl environment. For example C<%ENV> is not bound to the C-level
C<environ>. These modifications are not undone by this module. So, it's
generally better to execute another perl interpreter instead of using
the C<$subroutine> feature.

The options parameter accepts these options:

=over 4

=item keep_fd =E<gt> \@fds

here an array of file descriptor numbers (not file handles) is expected.
All other file descriptors except for the listed and file descriptor 2
(STDERR) are closed before calling C<$subroutine> or executing
C<@command_line>.

=item survive =E<gt> $boolean

if passed C<false> the created process will be killed when Apache shuts down.
if true it will survive an Apache restart.

=back

The return code on success is the PID of the process. On failure C<undef>
or an empty string is returned.

The created process is not related as a child process to the current
apache child.

=head2 Serving C<ErrorDocument>s

Triggering C<ErrorDocument>s from a registry script or even more from an
output filter is not simple. The normal way as a handler is

  return Apache2::Const::STATUS;

This does not work for registry scripts. An output filter even if it
returns a status can trigger only a C<SERVER_ERROR>.

The main interface to enter standard error processing in Apache is
C<ap_die()> at C-level. Its Perl interface is hidden in L<Apache2::HookRun>.

There is one case when an error message cannot be sent to the user. This
happens if the HTTP headers are already on the wire. Then it is too late.

The various flavors of C<safe_die()> take this into account.

C<safe_die> won't return. Instead it calls
L<ModPerl::Util::exit(0)|ModPerl::Util/"exit">
which raises an exception.

=over 4

=item ModPerl2::Tools::safe_die $status

This function is designed to be called from registry scripts. It
uses L<< Apache2::RequestUtil->request|Apache2::RequestUtil/"request" >>
to fetch the current request object. So,

 PerlOption +GlobalRequest

must be enabled.

Usage example:

 ModPerl2::Tools::safe_die 401;

=item $r-E<gt>safe_die($status)

=item $f-E<gt>safe_die($status)

These 2 methods are to be used if a request object or a filter object
are available.

Usage from within a filter:

 package My::Filter;
 use strict;
 use warnings;

 use ModPerl2::Tools;
 use base 'Apache2::Filter';

 sub handler : FilterRequestHandler {
   my ($f, $bb)=@_;
   $f->safe_die(410);
 }

The filter flavor removes the current filter from the request's output
filter chain.

=item $r-E<gt>headers_sent

This function checks if the HTTP_HEADER output filter is still present.
If so, it returns an empty list, true otherwise.

The presence of this filter means no output has yet been written to the
client. The HTTP status code and header fields can still be modified.

=back

=head2 Fetching the content of another document

Sometimes a handler or a filter needs the content of another document
in the web server's realm. Apache provides subrequests for this purpose.

The 2 C<fetch_url> variants use a subrequest to fetch the content of another
document. The document can even be fetched via C<mod_proxy> from another
server.

C<ModPerl2::Tools::fetch_url> needs

 PerlOption +GlobalRequest

Usage:

 $content=ModPerl2::Tools::fetch_url '/some/where?else=42';

 $content=$r->fetch_url('/some/where?else=42');

 ($content, $headers)=
     $r->fetch_url('http://what.is/the/meaning/of?life=42');

If C<mod_proxy> is available C<fetch_url> can use it to fetch a document
from another web server. If C<mod_ssl> is configured to allow proxying SSL
(see C<SSLProxyEngine>) even the C<https> scheme works. Another subtle point,
C<ProxyErrorOverride> may affect the output in case of an error.

Further, if C<fetch_url> is passed a subroutine as the last argument the
content is not accumulated in a single variable but passed brigade-wise to
the function:

 ($content, $headers)=
     $r->fetch_url('http://what.is/the/meaning/of?life=42', sub {
         my ($subr, @brigade)=$_;
         ...
     });

The subroutine is called with the subrequest as the first parameter and
a list of non-empty strings. The list itself may be empty if all buckets
of the brigade do not contain data.

On success the resulting C<$content> will be the empty string in this case.

C<fetch_url()> normally strips almost all input HTTP header fields from the
subrequest before running it. However, if the C<$r> request object has
a C<Host> header field it is passed on. Also, a C<User-Agent> header is
set for the subrequest containing C<ModPerl2::Tools/$VERSION> where
C<$VERSION> is the module's version.

If you need to pass more fields pass an array reference as the
2nd parameter to C<fetch_url()>:

 ($content, $headers)=
     $r->fetch_url('http://what.is/the/meaning/of?life=42', [qw/
         X-MyHeader my-value
         X-MyNextHeader my-next-value
     /]);

or even:

 ($content, $headers)=
     $r->fetch_url('http://what.is/the/meaning/of?life=42', [qw/
         X-MyHeader my-value
         X-MyNextHeader my-next-value
     /], sub {
         my ($subr, @brigade)=$_;
         ...
     });

If C<Host> or C<User-Agent> headers are passed this way they overwrite
the default ones.

Note, though, the header fields are assigned to the subrequest just before
the response handler is run. Earlier phases will see a copy of the main
request's headers.

=head3 How does it work?

If the passed URL starts with C<https://> or C<http://> a subrequest for
the URI C</> is initiated via C<< $r->lookup_uri('/') >>. Before the
subrequest is run it is changed into a proxy request for the passed URL.
One precondition for this to work is that there are no access restrictions
for the URL C</>.

Otherwise it is simply a subrequest for the passed URL.

Then C<ModPerl2::Tools::Filter::fetch_content_filter> is installed
as output filter for the subrequest. After that the subrequest is run.

The output filter collects all output.

When the request is done its C<< $r->headers_out >> is copied into a
normal hash and in list context the output string and this hash are returned.
In scalar context only the string is returned.

HTTP header names are case insensitive. Their names are all converted to
lower case in the C<$headers> hash. There are 2 hash members in upper case.
C<STATUS> contains the HTTP status code of the subrequest and C<STATUSLINE>
the status line.

=head3 Useful functions for similar cases

Note, it is always better to process data one chunk at a time. Try hard
to do that! Collecting data in memory should only be a last resort.

=over 4

=item ModPerl2::Tools::Filter::read_bb $bucket_brigade, \@buffer

C<read_bb> collects the data of a bucket brigade in the C<@buffer>
array. If an C<EOS> bucket has been seen it returns true otherwise false.

A simple output filter that collects all data could look like:

 sub filter {
     my ($f, $bb)=@_;

     my @buffer;
     do_something(join '', @buffer)
         if ModPerl2::Tools::Filter::read_bb $bb, \@buffer;

     return Apache2::Const::OK;
 }

=item ModPerl2::Tools::Filter::fetch_content_filter

This function is a C<FilterRequestHandler>. Is is controlled by 2 elements
of C<< $r->pnotes >>, C<out> and C<force_fetch_content>. C<out> must be
an array reference. It is passed to C<read_bb> to collect the output.
C<force_fetch_content> is a flag. If false the filter does nothing and
removes itself if the C<< $r->status >> on the first invocation of the
filter is not C<HTTP_OK>.

Usage:

 my $subr=$r->lookup_uri(...);

 my $output=[];
 @{$subr->pnotes}{qw/out force_fetch_content/}=($output,1);
 $subr->add_output_filter
     (\&ModPerl2::Tools::Filter::fetch_content_filter);
 $subr->run;

 do_something(join '', @$output)

=back

=head1 EXPORTS

None.

=head1 TODO

=over 4

=item Look at APR to see what it provides to make things easier. For example
C<apr_proc_create()>

=back

=head1 SEE ALSO

L<http://perl.apache.org>

=head1 AUTHOR

Torsten Förtsch, E<lt>torsten.foertsch@gmx.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Torsten Förtsch

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut

