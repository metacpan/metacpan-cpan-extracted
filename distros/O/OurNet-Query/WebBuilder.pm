# $File: //depot/OurNet-Query/WebBuilder.pm $ $Author: autrijus $
# $Revision: #1 $ $Change: 1139 $ $DateTime: 2001/06/14 18:46:33 $

package OurNet::WebBuilder;
require 5.005;

$OurNet::WebBuilder::VERSION = '1.21';

use strict;
use CGI;
use CGI::Cookie;

=head1 NAME

OurNet::WebBuilder - Web rendering for BBS-based services

=head1 SYNOPSIS

    use OurNet::WebBuilder;

    my $tmpl = {
        dir     => \%dir,
        article => \%article,
        cgi_url => CGI->url
    };

    my $opref = {
	'' => sub {
	    return '!view';
	},

	'view' => sub {
	    $tmpl->{'menu'} ||= param('curdir') || $dir{'oin'}[0]{id};
 	    $tmpl->{'curdir'} ||= param('curdir') || $dir{'oin'}[0]{id};
	    loadboard($tmpl->{'curdir'});

	    loadarticle(
		$_->{'id'},
		($tmpl->{'curdir'} eq 'bbs' ? $bbs 
					    : ($oin, $tmpl->{'curdir'})))
		foreach @{$dir{$tmpl->{'curdir'}}};

	    return 'view';
	}
    };

    OurNet::WebBuilder::Display($tmpl, $opref);

=head1 DESCRIPTION

the method C<Display> takes $tmpl, which is a variable pool, and $opref,
which is hash of mapping from 'op' to the subroutine for that 'op'.

The op routine fill in the $tmpl with the varialbes it would like the
variable pool to have, and returns the name of the template file that
would be used. or if the return value begins with '!', the variable pool
will be transit to the specified op again.

You may set I<$OurNet::WebBuilder::Backend> to specify a specific
rendering package. Currently, I<OurNet::Template>, I<Template> and
I<HTML::Template> are supported.

=cut

use vars qw/$Backend/;
use fields qw/header template errormsg cache params extension filename/;
use constant LANGS    => [{'zh-tw', 1, 'en-us', 2}, 'big5', 'iso-8859-1'];

# ----------------------
# Subroutine new(%param)
# ----------------------
sub new {
    my $class = shift;
    my $self  = ($] > 5.00562) ? fields::new($class)
                               : do { no strict 'refs';
                                      bless [\%{"$class\::FIELDS"}], $class };

    $self->{'cache'} = (defined $ENV{'GATEWAY_INTERFACE'} and
                        $ENV{'GATEWAY_INTERFACE'} =~ m/PerlEx|CGI-Perl/);

    %{$self->{'params'}} = @_;

    return $self;
}

# -----------------------
# Subroutine show($self)
# -----------------------
# Outputs the whole page.
# -----------------------
sub show {
    my $self = shift;

    if (my $lang = $self->dotemplate and $Backend eq 'HTML::Template') {
        foreach my $key (%{$self->{'params'}}) {
            if (UNIVERSAL::isa($key, "HASH") and exists($key->{$lang})) {
                $key = $key->{$lang};
            }
        }
        $self->{'template'}->param(%{$self->{'params'}});
    }

    if (UNIVERSAL::isa($self, __PACKAGE__) and $self->{'template'}) {
        print CGI->header($self->{'header'});
        if ($Backend eq 'HTML::Template') {
            print $self->{'template'}->output;
        }
        else {
            $self->{'template'}->process(
		$self->{'filename'}, $self->{'params'}
	    ) or die $self->{'template'}->error();
        }
    }
}

# ---------------------------------------------------------
# Subroutine dotemplate($self)
# ---------------------------------------------------------
# Determines and populates the template file/string/object.
# ---------------------------------------------------------
sub dotemplate {
    my $self = shift;
    my $CGIOBJ = CGI->new();
    my ($path, $info, $dir, $filename, $extension);

    $extension = $self->{'extension'};

    if (defined $self->{'template'}) {
        if (UNIVERSAL::isa($self->{'template'}, 'Template')) {
            # Template object already specified: populate CGI if must
            push(@{$self->{'template'}->{'options'}{'associate'}}, $CGIOBJ);
        }
        elsif (UNIVERSAL::isa($self->{'template'}, 'HTML::Template')) {
            # Template object already specified: populate CGI if must
            push(@{$self->{'template'}->{'options'}{'associate'}}, $CGIOBJ);
        }
        elsif (!ref($self->{'template'})) {
            # It's a file name, so put into $info
            $info = $self->{'template'};
            $self->{'template'} = undef;
            $path = $CGIOBJ->path_translated() || $0;
        }
        else {
            # Something else...
            die "Unknown type of 'template' field (".
                 ref($self->{'template'}).
                ")";
        }
    }
    else {
        $path = $CGIOBJ->path_translated() || $0;
    }

    if (($dir, $filename) = $path =~ m|(.*[\\/])?(.*)\.|) {
        $dir     ||= '';
        $dir      =~ tr|\\|/|;
        $filename = $info if $info;
        $filename =~ tr|\\|/|;

        foreach my $lang (map( { ".$_" } $CGIOBJ->param('lang')), '') {
            if (-e ($dir.$filename.$extension.$lang)) {
                $self->{'header'} = "text/html";
                $self->{'header'}.= "; charset=" . LANGS->{substr($lang, 1)}
                    if exists LANGS->{substr($lang, 1)};
                    
                if ($Backend eq 'HTML::Template') {
                    require HTML::Template;
                    $self->{'template'} = HTML::Template->new(
                        filename  => $dir.$filename.$extension.$lang,
                        associate => $CGIOBJ,
                        cache     => $self->{'cache'}
                    );
                }
                else {
                    require Template;
                    $self->{'template'} = Template->new(
                        INCLUDE_PATH => $dir,
                        INTERPOLATE  => 1,
                        POST_CHOMP   => 1,
                    );
                    $self->{'filename'} = $filename.$extension.$lang;
                }

                return $lang ? substr($lang, 1) : 1;
            }
        }
    }

    $info = $CGIOBJ->path_info() || $filename.'.pl';

    if (my @list = <$dir$filename$extension.??-??> and (-e $dir.'error_lang')) {
        $self->{'header'} = "Content-Type: text/html; charset=iso-8859-1";

        if ($Backend eq 'HTML::Template') {
            require HTML::Template;
            $self->{'template'} = HTML::Template->new(
                filename  => $dir.'error_lang',
                associate => $CGIOBJ,
                cache     => $self->{'cache'}
            );
        }
        else {
            require Template;
            $self->{'template'} = Template->new(
                INCLUDE_PATH => $dir,
                INTERPOLATE  => 1,
                POST_CHOMP   => 1,
            );
    
            $self->{'filename'} = 'error_lang';
        }
        

        @{$self->{'params'}}{qw/title url langs/} = (
            'Available Languages for: '.$CGIOBJ->param('lang'),
            $info,
            [map {s|^.*\.||; {code => $_, url => $info}} @list],
        );

        return 0;
    }
    elsif (-e $dir.'error_url') {
        if ($Backend eq 'HTML::Template') {
            require HTML::Template;
            $self->{'template'} = HTML::Template->new(
                filename  => $dir.'error_url',
                associate => $CGIOBJ,
                cache     => $self->{'cache'}
            );
        }
        else {
            require Template;
            $self->{'template'} = Template->new(
                INCLUDE_PATH => $dir,
                INTERPOLATE  => 1,
                POST_CHOMP   => 1,
            );
    
            $self->{'filename'} = 'error_url';
        }

        @{$self->{'params'}}{qw/title url/} = (
            'Address error', $path,
        );

        return 0;
    }
    else {
        $self->{'header'}   = "text/plain";
        print qq{
A Terrible error happened when parsing $info.

Worse yet, nobody is there to help you.

Please mail your complaints to the system administrator.

With sincere apologies,

The Webmaster
                              };
        exit;
    }
}

# Display($tmpl_param, $ophashref, [$fail_url], [$session_db, $flavor])
sub Display {
    my $tmpl_param = shift;
    my $ophashref  = shift;
    my $fail_url   = shift;
    my $session_db = shift;
    my $flavor     = shift || 'WEBBUILDERID';
    my $op         = CGI::param('op');
    my $user;

    if ($op and $session_db) {
        my $cookie;

        if (CGI->path_translated()) {
            my %cookies = CGI::Cookie->fetch;
            $cookie = $cookies{$flavor} if exists $cookies{$flavor};
        }
        else {
            $cookie = CGI::Cookie->new(-value => 'localhost');
        }

    	if (exists $session_db->{$cookie->value}) {
    	    my $sescook = CGI::Cookie->new(
		-name    => $flavor,
		-value   =>  $cookie->value,
                -expires =>  '+1h',
                -domain  =>  $cookie->domain
	    );

    	    print "Set-Cookie: $sescook\n";

    	    $user = $session_db->{$cookie->value};
    	}
        else {
            print CGI->header(-location => ($fail_url || '/'));
    	    return;
    	}
    }

    unless (exists $ophashref->{$op}) {
        # No such page; panic!
        print CGI->header(-location => ($fail_url || '/'));
        return;
    }

    # Found a page
    my $ext = do{&{$ophashref->{$op}}($tmpl_param, $user)};

    while (substr($ext, 0, 1) eq '!') {
        $op = substr($ext, 1);
        $ext = eval{&{$ophashref->{$op}}($tmpl_param, $user)};
    }

    if ($@) {
        print CGI->header;
        print "Error occured! Op=$op Ext=$ext Errors=$@ $! $^E $? ";
        return;
    }

    my $page = OurNet::WebBuilder->new(%{$tmpl_param});

    $page->{'extension'} = $ext ? ".$ext.w" : '.w';
    $page->show;
}

sub SetCookie {
    my $flavor  = shift || 'WEBBUILDERID';
    my $sescook = CGI::Cookie->new(
	-name    => $flavor,
        -value   =>  crypt(time, substr(CGI::remote_host(), -2)),
        -expires =>  '+1h'
    );

    print "Set-Cookie: $sescook\n";
    return (CGI::path_translated()) ? $sescook->value : 'localhost';
}

1;

=head1 SEE ALSO

L<OurNet::Template>, L<Template>, L<HTML::Template>

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.org>

=head1 COPYRIGHT

Copyright 2001 by Autrijus Tang E<lt>autrijus@autrijus.org>.

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
