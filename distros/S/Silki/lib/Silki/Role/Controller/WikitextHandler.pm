package Silki::Role::Controller::WikitextHandler;
{
  $Silki::Role::Controller::WikitextHandler::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;

use Net::Akismet::Protocol;
use Silki::Config;
use Silki::I18N qw( loc );

use Moose::Role;

sub _wikitext_from_form {
    my $self = shift;
    my $c    = shift;
    my $wiki = shift;

    my $wikitext = $self->_get_wikitext( $c, $wiki );

    unless (
        $c->user()->has_permission_in_wiki(
            wiki => $wiki, permission => Silki::Schema::Permission->Manage()
        )
        && $c->request()->params()->{skip_spam_check}
        ) {

        $self->_check_for_link_spam( $c, $wiki, $wikitext );
    }

    return $wikitext;
}

sub _get_wikitext {
    my $self = shift;
    my $c    = shift;
    my $wiki = shift;

    if (   $c->request()->params()->{format}
        && $c->request()->params()->{format} eq 'html' ) {
        my $formatter = Silki::Formatter::HTMLToWiki->new( wiki => $wiki );

        return $formatter->html_to_wikitext(
            $c->request()->params()->{content} );

    }
    else {
        return $c->request()->params()->{content};
    }
}

sub _check_for_link_spam {
    my $self     = shift;
    my $c        = shift;
    my $wiki     = shift;
    my $wikitext = shift;

    my $config = Silki::Config->instance();

    my $key    = $config->antispam_key();
    my $server = $config->antispam_server();

    return unless length $key && length $server;

    my $ua = Net::Akismet::Protocol->new(
        key  => $key,
        host => $server,
        url  => $wiki->uri( with_host => 1 ),
    );

    my %user_info;
    unless ( $c->user()->is_system_user() ) {
        $user_info{comment_author}       = $c->user()->best_name();
        $user_info{comment_author_email} = $c->user()->email_address();
    }

    return
        unless $ua->check(
        user_ip         => $c->request()->address(),
        user_agent      => $c->request()->user_agent(),
        comment_content => $wikitext,
        referer         => $c->request()->referer(),
        comment_type    => 'wiki page',
        %user_info,
        );

    die loc(
        'Your submission was flagged as spam by our antispam system. Please check any external links in your text.'
    ) . "\n";
}

1;

# ABSTRACT: Handles wikitext provided by the user, including spam checking

__END__
=pod

=head1 NAME

Silki::Role::Controller::WikitextHandler - Handles wikitext provided by the user, including spam checking

=head1 VERSION

version 0.29

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut

