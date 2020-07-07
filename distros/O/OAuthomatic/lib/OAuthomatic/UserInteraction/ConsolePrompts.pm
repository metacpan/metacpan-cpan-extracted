package OAuthomatic::UserInteraction::ConsolePrompts;
# ABSTRACT: Simple textual prompts on the console

# FIXME: use templates
# FIXME: test it


use Moose;
use namespace::sweep;
use Proc::Background;
use IO::Interactive qw/is_interactive/;
use Carp;


has 'config' => (
    is => 'ro', isa => 'OAuthomatic::Config', required => 1,
    handles=>[
        'browser',
       ]);


has 'server' => (
    is => 'ro', isa => 'OAuthomatic::Server', required => 1,
    handles => [
        'site_name',
        'site_client_creation_page',
        'site_client_creation_desc',
        'site_client_creation_help',
       ]);

sub prompt_client_credentials {
    my ($self) = @_;

    unless(is_interactive()) {
        OAuthomatic::Error::Generic->throw(
            ident => "Bad usage",
            extra => "Can not use ConsolePrompts without interactive terminal");
    }

    print << 'END';
Client (application) credentials are necessary to continue.
Those must be created manually using $site_name web interface.
END
    my $page_url = $self->site_client_creation_page;
    my $page_desc = $self->site_client_creation_desc;
    my $page_help = $self->site_client_creation_help || '';
    if($page_url) {
        print << "END";

Please, visit

   $page_url

($page_desc)
click through new application setup and enter obtained values below.

$page_help
END
    } else {
        print << "END";

Please, visit $page_desc,
click through new application setup and enter developer keys below.

$page_help
END
    }

    my ($key, $secret);
    while(1) {
        print "Key:    ";
        $key = <>; chomp($key); $key =~ s/^\s+//x; $key =~ s/\s+$//x;
        last if $key;
    }
    while(1) {
        print "Secret: ";
        $secret = <>; chomp($secret); $secret =~ s/^\s+//x; $secret =~ s/\s+$//x;
        last if $secret;
    }
    return OAuthomatic::Types::ClientCred->new(
        key => $key,
        secret => $secret,
    );
}

sub visit_oauth_authorize_page {
    my ($self, $app_auth_url) = @_;

    print <<"END";
Open your browser (local one!) on $app_auth_url
and authorize application when prompted. This script will continue once you finish.
END
    return;
}

sub prepare_to_work {
}

sub cleanup_after_work {
}

with 'OAuthomatic::UserInteraction';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OAuthomatic::UserInteraction::ConsolePrompts - Simple textual prompts on the console

=head1 VERSION

version 0.0202

=head1 DESCRIPTION

Absolutely nothing fancy, bare console prints.

=head1 METHODS

=head2 prompt_client_credentials() => ClientCred(...)

Asks the user to visit appropriate remote page and provide application
(or developer) keys.

Here just plain console prompt.

=head1 ATTRIBUTES

=head2 config

L<OAuthomatic::Config> object used to bundle various configuration params.

=head2 server

L<OAuthomatic::Server> object used to bundle server-related configuration params.

=head1 AUTHOR

Marcin Kasperski <Marcin.Kasperski@mekk.waw.pl>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Marcin Kasperski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
