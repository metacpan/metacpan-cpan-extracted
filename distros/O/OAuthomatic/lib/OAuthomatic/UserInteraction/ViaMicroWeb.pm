package OAuthomatic::UserInteraction::ViaMicroWeb;
# ABSTRACT: User is led using forms in the browser


use Moose;
use namespace::sweep;
use Proc::Background;
use Carp;


has 'micro_web' => (is=>'ro', isa=>'OAuthomatic::Internal::MicroWeb', required=>1,
                    handles => ['server', 'config']);

sub prepare_to_work {
    my $self = shift;
    $self->micro_web->start_using;
    return;
}

sub cleanup_after_work {
    my $self = shift;
    $self->micro_web->finish_using;
    return;
}


sub prompt_client_credentials {
    my ($self) = @_;

    my $mweb = $self->micro_web;

    my $enter_url = $mweb->client_key_url;
    $self->_open_in_browser($enter_url, <<"END");
Fill application tokens in the browser form. 
This script will continue once they are submitted.
END
    my $client_cred = $mweb->wait_for_client_cred();

    return $client_cred;
}

sub visit_oauth_authorize_page {
    my ($self, $url) = @_;

    my $site_name = $self->server->site_name;

    $self->_open_in_browser($url, <<"END");
Accept application authorization in the browser form (page from $site_name),
or just notification about succesfull authorization if you already authorized
in the past.
This script will continue once you authorize application.
END

    return;
}

sub _open_in_browser {
    my ($self, $url, $comment) = @_;

    my $browser = $self->config->browser;
    unless($browser) {
        print <<"END";
Open your browser on 
    $url
$comment
END
    } else {
        print <<"END";
Spawning browser ($browser) on
    $url
(open this page manually if for some reason it is not displayed automatically).

$comment
END
        my $bgr = Proc::Background->new($browser, $url);
        # The process sometimes will end immediately (page in existing browser), sometimes will 
        # continue. Let's just ignore it (and, therefore, ignore returned object)
        undef $bgr;
    }
    return;
}

with 'OAuthomatic::UserInteraction';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OAuthomatic::UserInteraction::ViaMicroWeb - User is led using forms in the browser

=head1 VERSION

version 0.0201

=head1 DESCRIPTION

Simple (local) web forms will be used to ask user for client
credentials and provide him with instructions.

=head1 PARAMETERS

=head2 micro_web

Embedded web server object. Here it will be used to show forms.

=head1 METHODS

=head2 prompt_client_credentials() => ClientCred(...)

Asks the user to visit appropriate remote page and provide application
(or developer) keys. Here use web form as an aid.

=head1 AUTHOR

Marcin Kasperski <Marcin.Kasperski@mekk.waw.pl>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Marcin Kasperski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
