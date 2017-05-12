package Scaffold::Base;

our $VERSION = '0.01';

use 5.8.8;
use Data::Dumper;

use Scaffold;
use Scaffold::Class
  base     => 'Badger::Base',
  version  => $VERSION,
  messages => {
      invparams  => "invalid paramters passed, reason: %s\n",
      evenparams => "%s requires an even number of paramters\n",
      noalias    => "can not set session alias %s\n",
      badini     => "can not load %s\n",
  }
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub config {
    my ($self, $p) = @_;

    return $self->{config}->{$p};

}

sub custom_error {
    my ($self, $scaffold, $page_title, $text) = @_;

    my $die_msg    = $text;
    my $param_dump = Dumper($scaffold->request->parameters->mixed());

    $param_dump =~ s/(?:^|\n)(\s+)/&_trim( $1 )/ge;
    $param_dump =~ s/</&lt;/g;

    my $request_dump  = Dumper($scaffold->request);
    my $response_dump = Dumper($scaffold->response);

#    local $Data::Dumper::Freezer = '_dumper_hook';
    my $scaffold_dump = Dumper($scaffold);

    $request_dump =~ s/(?:^|\n)(\s+)/&_trim( $1 )/ge;
    $request_dump =~ s/</&lt;/g;

    $response_dump =~ s/(?:^|\n)(\s+)/&_trim( $1 )/ge;
    $response_dump =~ s/</&lt;/g;

    $scaffold_dump =~ s/(?:^|\n)(\s+)/&_trim( $1 )/ge;
    $scaffold_dump =~ s/</&lt;/g;

    my $status = $scaffold->response->status || 'Bad Request';
    my $page = $self->_error_page();

    $page =~ s/##DIE_MESSAGE##/$die_msg/sg;
    $page =~ s/##PARAM_DUMP##/$param_dump/sg;
    $page =~ s/##REQUEST_DUMP##/$request_dump/sg;
    $page =~ s/##RESPONSE_DUMP##/$response_dump/sg;
    $page =~ s/##SCAFFOLD_DUMP##/$scaffold_dump/sg;
    $page =~ s/##STATUS##/$status/sg;
    $page =~ s/##PAGE_TITLE##/$page_title/sge;

    return $page;

}

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub _trim {
    my $spaces = $1;

    my $new_sp = " " x int( length($spaces) / 4 );
    return( "\n$new_sp" );
}

sub _dumper_hook {
    $_[0] = bless {
        %{ $_[0] },
        result_source => undef,
    }, ref($_[0]);
}

sub _error_page {
    my ($self) = @_;

    return( qq!
<html>
    <head>
        <title>##PAGE_TITLE## ##STATUS##</title>
        <style type="text/css">
            body {
                font-family: "Bitstream Vera Sans", "Trebuchet MS", Verdana,
                            Tahoma, Arial, helvetica, sans-serif;
                color: #ddd;
                background-color: #eee;
                margin: 0px;
                padding: 0px;
            }
            div.box {
                background-color: #ccc;
                border: 1px solid #aaa;
                padding: 4px;
                margin: 10px;
                -moz-border-radius: 10px;
            }
            div.error {
                font: 20px Tahoma;
                background-color: #88003A;
                border: 1px solid #755;
                padding: 8px;
                margin: 4px;
                margin-bottom: 10px;
                -moz-border-radius: 10px;
            }
            div.infos {
                font: 9px Tahoma;
                background-color: #779;
                border: 1px solid #575;
                padding: 8px;
                margin: 4px;
                margin-bottom: 10px;
                -moz-border-radius: 10px;
            }
            .head {
                font: 12px Tahoma;
            }
            div.name {
                font: 12px Tahoma;
                background-color: #66B;
                border: 1px solid #557;
                padding: 8px;
                margin: 4px;
                -moz-border-radius: 10px;
            }
        </style>
    </head>
    <body>
        <div class="box">
            <div class="error">##DIE_MESSAGE##</div>
            <div class="infos"><br/>    
                <div class="head"><u>site.params</u></div>
                <br />
                <pre>
##PARAM_DUMP##
                </pre>
                <div class="head"><u>Request Object</u></div><br/>
                <pre>
##REQUEST_DUMP##
                </pre>
                <div class="head"><u>Response Object</u></div><br/>
                <pre>
##RESPONSE_DUMP##
                </pre>
                <div class="head"><u>Scaffold Object</u></div><br/>
                <pre>
##SCAFFOLD_DUMP##
                </pre>    
            </div>    
            <div class="name">Running on Scaffold $Scaffold::VERSION</div>
        </div>
    </body>
</html>! 
);
    
}

1;

__END__

=head1 NAME

Scaffold::Base - The Base environment for Scaffold

=head1 SYNOPSIS

 use Scaffold::Class
   version => '0.01',
   base    => 'Scaffold::Base'
 ;

=head1 DESCRIPTION

This is the base class for Scaffold. It defines some useful exception messages
and a method to access the config cache.

=head1 ACCESSORS

=over 4

=item config

This method is used to return items from the interal config cache.

=back

=head1 SEE ALSO

 Badger::Base

 Scaffold
 Scaffold::Base
 Scaffold::Cache
 Scaffold::Cache::FastMmap
 Scaffold::Cache::Manager
 Scaffold::Cache::Memcached
 Scaffold::Class
 Scaffold::Constants
 Scaffold::Engine
 Scaffold::Handler
 Scaffold::Handler::Default
 Scaffold::Handler::Favicon
 Scaffold::Handler::Robots
 Scaffold::Handler::Static
 Scaffold::Lockmgr
 Scaffold::Lockmgr::KeyedMutex
 Scaffold::Lockmgr::UnixMutex
 Scaffold::Plugins
 Scaffold::Render
 Scaffold::Render::Default
 Scaffold::Render::TT
 Scaffold::Routes
 Scaffold::Server
 Scaffold::Session::Manager
 Scaffold::Stash
 Scaffold::Stash::Controller
 Scaffold::Stash::Cookie
 Scaffold::Stash::View
 Scaffold::Uaf::Authenticate
 Scaffold::Uaf::AuthorizeFactory
 Scaffold::Uaf::Authorize
 Scaffold::Uaf::GrantAllRule
 Scaffold::Uaf::Login
 Scaffold::Uaf::Logout
 Scaffold::Uaf::Manager
 Scaffold::Uaf::Rule
 Scaffold::Uaf::User
 Scaffold::Utils

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
