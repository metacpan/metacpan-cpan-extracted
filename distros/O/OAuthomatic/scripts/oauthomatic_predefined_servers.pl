#!perl

use strict;
use warnings;

# PODNAME: oauthomatic_predefined_servers
# ABSTRACT: list all predefined server definitions
our $VERSION = '0.0202'; # VERSION


{
    package RunMe;
    use Moose;
    with 'MooseX::Getopt';

    use OAuthomatic::ServerDef qw/oauthomatic_predefined_list/;

    has 'compact' => (is=>'ro', isa=>'Bool');

    sub run {
        my ($self) = @_;

        my @predefined = oauthomatic_predefined_list();

        print "Known OAuthomatic servers:\n\n" unless $self->compact;
        foreach my $srv (@predefined) {
            if($self->compact) {
                print $srv->site_name, "\n";
            } else {
                print "    ", $srv->site_name, "\n";
                print "        oauth_temporary_url:    ", $srv->oauth_temporary_url, "\n";
                print "        oauth_authorize_page:   ", $srv->oauth_authorize_page, "\n";
                print "        oauth_token_url:        ", $srv->oauth_token_url, "\n";
                print "        site_client_creation_page: ", $srv->site_client_creation_page || "[undefined]", "\n";
                print "        site_client_creation_desc: ", $srv->site_client_creation_desc || "[undefined]", "\n";
                print "        site_client_creation_help: \n";
                my $help = $srv->site_client_creation_help || "[undefined]";
                $help =~ s{^}{            }gm;
                print $help, "\n";
            }
        }
        return;
    }

};

my $app = RunMe->new_with_options;
$app->run;

__END__

=pod

=encoding UTF-8

=head1 NAME

oauthomatic_predefined_servers - list all predefined server definitions

=head1 VERSION

version 0.0202

=head1 DESCRIPTION

Lists all OAuthomatic predefined servers known in current environment.
By default, shows various details, with C<--compact> option, only names.

=head1 AUTHOR

Marcin Kasperski <Marcin.Kasperski@mekk.waw.pl>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Marcin Kasperski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
