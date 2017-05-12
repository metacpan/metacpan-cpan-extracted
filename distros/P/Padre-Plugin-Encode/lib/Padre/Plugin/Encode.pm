package Padre::Plugin::Encode;

use strict;
use warnings;

use version; our $VERSION = qv('0.1.3');

use base 'Padre::Plugin';

use Wx         ':everything';
use Wx::Event  ':everything';
use Wx::Locale qw(:default);

use Padre::Wx         ();
use Padre::Wx::Dialog ();
use Padre::Locale     ();

my @ENCODINGS = qw(
    cp932
    cp949
    euc-jp
    euc-kr
    shift-jis
    utf-8
);

sub padre_interfaces {
    'Padre::Plugin' => '0.24',
}

sub menu_plugins_simple {
    'Convert Encoding' => [
        Wx::gettext('Encode document to System Default') => \&encode_document_to_system_default,
        Wx::gettext('Encode document to utf-8')          => \&encode_document_to_utf8,
        Wx::gettext('Encode document to ...')            => \&encode_document_to,
    ];
}

sub encode_document_to_system_default {
    my ( $window, $event ) = @_;

    my $doc = $window->current->document;
    $doc->{encoding} = Padre::Locale::encoding_system_default || 'utf-8';
    $doc->save_file if $doc->filename;
    $window->refresh;

    my $string = 'Encode document to System Default('.$doc->{encoding}.')';
    my $output_panel = $window->{gui}->{output_panel};
    $output_panel->clear;
    $output_panel->AppendText( $string . $/ );
}

sub encode_document_to_utf8 {
    my ( $window, $event ) = @_;

    my $doc = $window->current->document;
    $doc->{encoding} = 'utf-8';
    $doc->save_file if $doc->filename;
    $window->refresh;

    my $string = 'Encode document to '.$doc->{encoding};
    my $output_panel = $window->{gui}->{output_panel};
    $output_panel->clear;
    $output_panel->AppendText( $string . $/ );
}

sub encode_document_to {
    my ( $window, $event ) = @_;

    my @layout = (
        [
            [ 'Wx::StaticText', undef, Wx::gettext('Encode to:') ],
            [ 'Wx::ComboBox', '_encoding_', 'utf-8', \@ENCODINGS, wxCB_READONLY ],
        ],
        [
            [ 'Wx::Button', '_ok_',     Wx::wxID_OK ],
            [ 'Wx::Button', '_cancel_', Wx::wxID_CANCEL ],
        ],
    );

    my $dialog = Padre::Wx::Dialog->new(
        parent => $window,
        title  => gettext(
            "Encode document to..."
        ),
        layout => \@layout,
        width  => [ 100, 200 ],
        bottom => 20,
    );
    $dialog->{_widgets_}{_ok_}->SetDefault;
    Wx::Event::EVT_BUTTON( $dialog, $dialog->{_widgets_}{_ok_}, \&ok_clicked );
    Wx::Event::EVT_BUTTON( $dialog, $dialog->{_widgets_}{_cancel_}, \&cancel_clicked );

    $dialog->{_widgets_}{_encoding_}->SetFocus;
    $dialog->Show(1);

    return 1;
}

sub cancel_clicked {
    my ( $dialog, $event ) = @_;

    $dialog->Destroy;
}

sub ok_clicked {
    my ( $dialog, $event ) = @_;

    my $window = $dialog->GetParent;
    my $data = $dialog->get_data;
    $dialog->Destroy;

    my $doc = $window->current->document;
    $doc->{encoding} = $data->{_encoding_};
    $doc->save_file if $doc->filename;
    $window->refresh;

    my $string = 'Encode document to '.$doc->{encoding};
    my $output_panel = $window->{gui}->{output_panel};
    $output_panel->clear;
    $output_panel->AppendText( $string . $/ );
}

1; # Magic true value required at end of module
__END__

=encoding utf-8

=head1 NAME

Padre::Plugin::Encode - convert file to different encoding in Padre


=head1 VERSION

This document describes Padre::Plugin::Encode version 0.1.3


=head1 SYNOPSIS

    $>padre
    Plugins -> Convert Encode -> 
                                 Encode document to System Default
                                 Encode document to utf-8
                                 Encode document to ...


=head1 DESCRIPTION

Encode by L<Encode>


=head1 INSTALLATION

To install this module, run the following commands:

    perl Makefile.PL
    make
    make test
    make install


=head1 AUTHOR

Keedi Kim - 김도형  C<< <keedi@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Keedi Kim - 김도형 C<< <keedi@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
