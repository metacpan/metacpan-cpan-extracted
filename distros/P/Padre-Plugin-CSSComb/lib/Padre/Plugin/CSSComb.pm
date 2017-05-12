package Padre::Plugin::CSSComb;
{
  $Padre::Plugin::CSSComb::VERSION = '0.001';
}

# ABSTRACT: CSSComb plugin for Padre
use strict;
use warnings;
use base 'Padre::Plugin';
use HTTP::Request::Common;

sub plugin_name {
    'CSSComb';
}

sub padre_interfaces {
    'Padre::Plugin' => 0.96,
        ;
}

sub menu_plugins {
    my $self      = shift;
    my $main      = $self->main;
    my $menu_item = Wx::MenuItem->new(
        undef,
        -1,
        Wx::gettext('CSSComb current document/selection')
            . "...\tAlt+Shift+C",
    );

    Wx::Event::EVT_MENU(
        $main,
        $menu_item,
        sub {
            $self->_comb_css;
        },
    );

    return $menu_item;
}

sub _comb_css {
    my ($self) = @_;
    my $main = $self->main;

    my $src = $main->current->text;
    my $doc = $main->current->document;
    return unless $doc;
    my $code = $src ? $src : $doc->text_get;
    return unless ( defined $code and length($code) );

    # NOTE: this is synchronous for a reason, the active document/selection
    #       might change if made asynchronously
    require LWP::UserAgent;
    my $useragent = LWP::UserAgent->new(
        agent   => "Padre::Plugin::CSSComb",
        timeout => 10,
    );
    unless (Padre::Constant::WIN32) {
        $useragent->env_proxy;
    }

    my $response = $useragent->request(
        POST(
            'http://csscomb.com/gate/gate.php',
            Referer => 'http://csscomb.com/online/',
            Content => [ code => $code ],
        )
    );
    if ( !$response->is_success ) {
        my $error_text = Wx::gettext(
            "CSSComb encountered an error: " . $response->status_line );
        $self->_output($error_text);
        return;
    }

    my $css = $response->decoded_content;

    # make sure the line endings match the document
    # the service always returns Windows CR/LF
    # TODO: try to use Wx::Scintilla's ConvertEOLs
    if ( $doc->newline_type eq 'UNIX' ) {
        $css =~ s/\015\012/\012/g;
    }
    elsif ( $doc->newline_type eq 'MAC' ) {
        $css =~ s/\015\012/\015/g;
    }

    if ($src) {
        my $editor = $main->current->editor;
        $editor->ReplaceSelection($css);
    }
    else {
        $doc->text_set($css);
    }
}

sub _output {
    my ( $self, $text ) = @_;
    my $main = $self->main;

    $main->show_output(1);
    $main->output->clear;
    $main->output->AppendText($text);
}


1;

__END__

=pod

=head1 NAME

Padre::Plugin::CSSComb - CSSComb plugin for Padre

=head1 VERSION

version 0.001

=head1 DESCRIPTION

This plugin adds L<CSSComb|http://csscomb.com> support to Padre.

CSSComb is written in PHP so running it locally requires PHP installed.
To circumvent this requirement the plugin uses the API used by the
L<Online Demo|http://csscomb.com/online/>.

WARNING: if you don't want to send your CSS unencrypted to this online service
you should do one of the following:

=over

=item *

submit a patch that allows configuration of the plugin to use a private CSSComb,
either executed locally or against a different URL.

=item *

don't install the plugin to make sure you don't accidently use it

=back

=head1 AUTHOR

Alexander Hartmaier <abraxxa@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Alexander Hartmaier.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
