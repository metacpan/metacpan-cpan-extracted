package SOAP::Transport::HTTP::MockReplay;

=head1 NAME

SOAP::Transport::HTTP::MockReplay - Mock HTTP client layer for SOAP::Lite

=head1 SYNOPSIS

    # Thsi module has to be loaded *BEFORE* SAOAP::Lite
    use SOAP::Transport::HTTP::MockReplay;
    
    use SOAP::Lite;
    my $client = SOAP::Lite->new(proxy => $endpoint);
    $client->call($method => @arguments);

=head1 DESCRIPTION

This module records all SOAP rquests and responses to a locale cache on disk.
The requests can then be mocked (played back) from the cache.

This can be of great help when using complex web services that return
unexpected messages and can be hard to troubleshoot. Or when using services that
are paying (ex: Google AdWords) and where invoking a service is costly.

=head1 CACHE

The cache consists simply of a folder where the requestes and responses are
both saved in the same subfolder. The subfolder is named after the MD5 of the
request's contents. This allows the module to quicky find a response when
performing a I<playback>.

=head1 API

=head2 import

This module can be configured through the import mechanism.

To change the name of the logger (I<soap.mock>) used simply provide a name
through the parameter I<logger>:

    use SOAP::Transport::HTTP::MockReplay logger => 'app.soap';

To use a different cache folder (F<soap-cache>) provide a new value through the parameter
I<cache>:

    use SOAP::Transport::HTTP::MockReplay cache => '.soap/mock/';

To write the files with a IO layer mode other than ':utf8' use I<binmode>:

    use SOAP::Transport::HTTP::MockReplay binmode => ':raw';

Of course all these options can be combined together.

=head1 AUTHOR

Emmanuel Rodriguez E<lt>potyl@cpan.orgE<gt>

=head1 COPYRIGHT

(C) 2010 Emmanuel Rodriguez

=cut

use strict;
use warnings;

use base 'LWP::UserAgent';

use LWP;
use SOAP::Lite;
use SOAP::Transport::HTTP;
BEGIN {
    $SOAP::Transport::HTTP::Client::USERAGENT_CLASS = __PACKAGE__;
}

use HTTP::Response;
use Data::Dumper;
use Digest::MD5 'md5_hex';
use File::Slurp;
use File::Spec;
use File::Path 'mkpath';

use Log::Log4perl ':nowarn';

our $VERSION = '0.01';

my $LOG = Log::Log4perl->get_logger('soap.mock');
my $DIR = 'soap-cache';
my $BINMODE = ':utf8'; # Shoudn't we use :raw instead?
my $EOL = "\015\012";  # "\r\n" is not portable (stolen from lib/HTTP/Message.pm)


sub import {
    my ($package, %options) = @_;

    my $value;
    if ($value = $options{logger}) {
        $LOG = Log::Log4perl->get_logger($value);
    }

    if ($value = $options{cache}) {
        $DIR = $value;
    }

    if ($value = $options{binmode}) {
        $BINMODE = $value;
    }
}


sub request {
    my $self = shift;
    my ($request) = @_;

    my $digest = md5_hex($request->content);
    my $dir = File::Spec->catdir($DIR, $digest);
    mkpath($dir) unless -d $dir;

    my $file = File::Spec->catfile($dir, "request.soap");
    if (! -e $file) {
        $LOG->debug("Saving request to $file");
        write_message($file, $request);
    }

    $file = File::Spec->catfile($dir, "response.soap");
    my $response;
    if (-e $file) {
        $LOG->warn("Using a cached response $file");
        $response = read_message($file);
    }
    else {
        $LOG->info("Performing a SOAP call for $digest");
        $response = $self->SUPER::request($request);
        write_message($file, $response);
    }

    return $response;
}


sub read_message {
    my ($file) = @_;

    my $str = read_file($file, binmode => $BINMODE);


    if ($LWP::VERSION gt '5.803') {
        return HTTP::Response->parse($str);
    }


    # NOTE: Ideally we would use HTTP::Response->parse($str); but that method is
    #       broken in 5.803 and earlier as it fails to parse the headers
    #       properly and ends up eating part of the content.

    my $status_line;
    if ($str =~ s/^(.*)\n//) {
        $status_line = $1;
    }
    else {
        $status_line = $str;
        $str = "";
    }

    my @hdr;
    while (1) {
        if ($str =~ s/^([^\s:]+)[ \t]*: ?(.*)\n?//) {
            push(@hdr, $1, $2);
            $hdr[-1] =~ s/\r\z//;
        }
        elsif (@hdr && $str =~ s/^([ \t].*)\n?//) {
            $hdr[-1] .= "\n$1";
            $hdr[-1] =~ s/\r\z//;
        }
        else {
            $str =~ s/^\r?\n//;
            last;
        }
    }

    my $response;
    do {
        local $HTTP::Headers::TRANSLATE_UNDERSCORE;
        $response = HTTP::Message::new('HTTP::Response', \@hdr, $str);
    };

    my($protocol, $code, $message);
    if ($status_line =~ /^\d{3} /) {
       # Looks like a response created by HTTP::Response->new
       ($code, $message) = split(' ', $status_line, 2);
    } else {
       ($protocol, $code, $message) = split(' ', $status_line, 3);
    }
    $response->protocol($protocol) if $protocol;
    $response->code($code) if defined($code);
    $response->message($message) if defined($message);

    return $response;
}


sub write_message {
    my ($file, $message) = @_;
    write_file($file, {binmode => $BINMODE}, $message->as_string($EOL));
}


1;
