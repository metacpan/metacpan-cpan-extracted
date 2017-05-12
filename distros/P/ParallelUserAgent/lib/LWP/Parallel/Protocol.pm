#  -*- perl -*-
# $Id: Protocol.pm,v 1.10 2004/02/10 15:19:19 langhein Exp $
# derived from: Protocol.pm,v 1.39 2001/10/26 19:00:21 gisle Exp

package LWP::Parallel::Protocol;

=head1 NAME

LWP::Parallel::Protocol - Base class for parallel LWP protocols

=head1 SYNOPSIS

 package LWP::Parallel::Protocol::foo;
 require LWP::Parallel::Protocol;
 @ISA=qw(LWP::Parallel::Protocol);

=head1 DESCRIPTION

This class is used a the base class for all protocol implementations
supported by the LWP::Parallel library. It mirrors the behavior of the
original LWP::Parallel library by subclassing from it and adding a few
subroutines of its own.

Please see the LWP::Protocol for more information about the usage of
this module. 

In addition to the inherited methods from LWP::Protocol, The following 
methods and functions are provided:

=head1 ADDITIONAL METHODS AND FUNCTIONS

=over 4

=cut

#######################################################

require LWP::Protocol;
@ISA = qw(LWP::Protocol);
$VERSION = sprintf("%d.%02d", q$Revision: 1.10 $ =~ /(\d+)\.(\d+)/);


use HTTP::Status ();
use HTML::HeadParser; # thanks to Kirill
use strict;
use Carp ();

my %ImplementedBy = (); # scheme => classname


=item $prot = LWP::Parallel::Protocol->new();

The LWP::Parallel::Protocol constructor is inherited by subclasses. As this is
a virtual base class this method should B<not> be called directly.

Note: This is inherited from LWP::Protocol

=cut



=item $prot = LWP::Parallel::Protocol::create($schema)

Create an object of the class implementing the protocol to handle the
given scheme. This is a function, not a method. It is more an object
factory than a constructor. This is the function user agents should
use to access protocols.

=cut

sub create
{
    my ($scheme, $ua) = @_;
    my $impclass = LWP::Parallel::Protocol::implementor($scheme) or
	Carp::croak("Protocol scheme '$scheme' is not supported");

    # hand-off to scheme specific implementation sub-class
    my $protocol = $impclass->new($scheme, $ua);

    return $protocol;
}


=item $class = LWP::Parallel::Protocol::implementor($scheme, [$class])

Get and/or set implementor class for a scheme.  Returns '' if the
specified scheme is not supported.

=cut

sub implementor
{
    my($scheme, $impclass) = @_;

    if ($impclass) {
	$ImplementedBy{$scheme} = $impclass;
    }
    my $ic = $ImplementedBy{$scheme};
    return $ic if $ic;

    return '' unless $scheme =~ /^([.+\-\w]+)$/;  # check valid URL schemes
    $scheme = $1; # untaint
    $scheme =~ s/[.+\-]/_/g;  # make it a legal module name

    # scheme not yet known, look for a 'use'd implementation
    $ic = "LWP::Parallel::Protocol::$scheme";  # default location
    no strict 'refs';
    # check we actually have one for the scheme:
    unless (@{"${ic}::ISA"}) { # fixed in LWP 5.48
	# try to autoload it
        #LWP::Debug::debug("Try autoloading $ic");
	eval "require $ic";
	if ($@) {
	    if ($@ =~ /Can't locate/) { #' #emacs get confused by '
		$ic = '';
	    } else { # this msg never gets to the surface - 1002, JB
		die "$@\n";
	    }
	}
    }
    $ImplementedBy{$scheme} = $ic if $ic;
    $ic;
}

=item $prot->receive ($arg, $response, $content)

Called to store a piece of content of a request, and process it
appropriately into a scalar, file, or by calling a callback.  If $arg
is undefined, then the content is stored within the $response.  If
$arg is a simple scalar, then $arg is interpreted as a file name and
the content is written to this file.  If $arg is a reference to a
routine, then content is passed to this routine.

$content must be a reference to a scalar holding the content that
should be processed.

The return value from receive() is undef for errors, positive for
non-zero content processed, 0 for forced EOFs, and potentially a
negative command from a user-defined callback function.

B<Note:> We will only use the file or callback argument if
$response->is_success().  This avoids sendig content data for
redirects and authentization responses to the file or the callback
function.

=cut

sub receive {
    my ($self, $arg, $response, $content, $entry) = @_;

  LWP::Debug::trace("( [self]" .
                    ", ". (defined $arg ? $arg : '[undef]') . 
                    ", ". (defined $response ? 
		            (defined $response->code ? 
			      $response->code : '???') . " " .
                            (defined $response->message ?
			      $response->message : 'undef')
                                                : '[undef]') .
                    ", ". (defined $content ? 
		           (ref($content) eq 'SCALAR'? 
			       length($$content) . " bytes" 
			       : '[ref('. ref($content) .')' )
                            : '[undef]') . 
                    ", ". (defined $entry ? $entry : '[undef]') . 
                    ")");


    my($parse_head, $max_size, $parallel) =
      @{$self}{qw(parse_head max_size parallel)};

    my $parser;
    if ($parse_head && $response->content_type eq 'text/html') {
        require HTML::HeadParser; # LWP 5.60
	$parser = HTML::HeadParser->new($response->{'_headers'});
    }
    
    my $content_size = $entry->content_size;

    # Note: We don't need alarms here since we are not making any tcp
    # connections.  All the data we need is alread in \$content, so we
    # just read out a string value -- nothing should slow us down here
    # (other than processor speed or memory constraints :) ) PS: You
    # can't just add 'alarm' somewhere here unless you fix the calls
    # to ->receive in the subclasses such as 'ftp' or 'http' and wrap
    # them in an 'eval' statement that will catch our alarm-exceptions
    # we would throw here! But since we don't need alarms here, just
    # forget what I just said - it's irrelevant.

    if (!defined($arg) || !$response->is_success ) {
	# scalar
	if ($parser) {
	    $parser->parse($$content) or undef($parser);
	}
        LWP::Debug::debug("read " . length($$content) . " bytes");
	$response->add_content($$content);
	$content_size += length($$content);
	$entry->content_size($content_size); # update persistant size counter
	if (defined($max_size) && $content_size > $max_size) {
  	    LWP::Debug::debug("Aborting because size limit of " .
	                      "$max_size bytes exceeded");
	    $response->push_header("Client-Aborted", "max_size");
	    #my $tot = $response->header("Content-Length") || 0;
	    #$response->header("X-Content-Range", "bytes 0-$content_size/$tot");
	    return 0; # EOF (kind of)
	} 
    }
    elsif (!ref($arg)) {
	# Mmmh. Could this take so long that we want to use alarm here?
	my $file_open;
	if (defined ($entry->content_size) and ($entry->content_size > 0)) {
	  $file_open = open(OUT, ">>$arg"); # we already have data: append
	} else { 
	  $file_open = open(OUT, ">$arg");  # no content received: open new
	}
	unless ( $file_open ) {
	    $response->code(&HTTP::Status::RC_INTERNAL_SERVER_ERROR);
	    $response->message("Cannot write to '$arg': $!");
	    return; # undef means error
	}
        binmode(OUT);
        local($\) = ""; # ensure standard $OUTPUT_RECORD_SEPARATOR
	if ($parser) {
	    $parser->parse($$content) or undef($parser);
	}
        LWP::Debug::debug("[FILE] read " . length($$content) . " bytes");
	print OUT $$content;
	$content_size += length($$content);
	$entry->content_size($content_size); # update persistant size counter
	close(OUT);
	if (defined($max_size) && $content_size > $max_size) {
	    LWP::Debug::debug("Aborting because size limit exceeded");
	    $response->push_header("Client-Aborted", "max_size");
	    #my $tot = $response->header("Content-Length") || 0;
	    #$response->header("X-Content-Range", "bytes 0-$content_size/$tot");
	    return 0;
	} 
    }
    elsif (ref($arg) eq 'CODE') {
	# read into callback
	if ($parser) {
	    $parser->parse($$content) or undef($parser);
	}
        LWP::Debug::debug("[CODE] read " . length($$content) . " bytes");
	my $retval;
	eval {
	    $retval = &$arg($$content, $response, $self, $entry);
	};
	if ($@) {
	    chomp($@);
	    $response->push_header('X-Died' => $@);
	    $response->push_header("Client-Aborted", "die");
	} else {
	    # pass return value from callback through to implementor class
	  LWP::Debug::debug("return-code from Callback was '".
 	                    (defined $retval ? "$retval'" : "[undef]'")); 
	    return $retval; 
	}
    }
    else {
	$response->code(&HTTP::Status::RC_INTERNAL_SERVER_ERROR);
	$response->message("Unexpected collect argument  '$arg'");
    }
    return length($$content); # otherwise return size of content processed
}

=item $prot->receive_once($arg, $response, $content, $entry)

Can be called when the whole response content is available as
$content.  This will invoke receive() with a collector callback that
returns a reference to $content the first time and an empty string the
next.

=cut

sub receive_once {
    my ($self, $arg, $response, $content, $entry) = @_;

    # read once
    my $retval = $self->receive($arg, $response, \$content, $entry);

    # and immediately simulate EOF
    my $no_content = '';  
    $retval = $self->receive($arg, $response, \$no_content, $entry) 
	unless $retval;

    return (defined $retval? $retval : 0);
}

1;

=head1 SEE ALSO

Inspect the F<LWP/Parallel/Protocol/http.pm> file for examples of usage.

=head1 COPYRIGHT

Copyright 1997-2004 Marc Langheinrich E<lt>marclang@cpan.org>
Parts copyright 1995-2004 Gisle Aas

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


