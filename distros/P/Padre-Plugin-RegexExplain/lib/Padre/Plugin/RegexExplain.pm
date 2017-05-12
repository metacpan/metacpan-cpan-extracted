package Padre::Plugin::RegexExplain;

use 5.008;

use strict;
use warnings;

use YAPE::Regex::Explain;
use Padre::Constant ();
use Padre::Plugin   ();
use Padre::Wx       ();
use Wx qw(:everything);

our @ISA = qw(Padre::Plugin);

our $VERSION = '0.02';

sub plugin_name { return 'RegexExplain' }

sub padre_interfaces { 'Padre::Plugin' => 0.43 }

sub menu_plugins_simple {
    my $self = shift;

    return $self->plugin_name => [
        'Explain' => sub { $self->explain },
    ]
}

sub explain {
    my $self = shift;

    my $editor = $self->current->editor;
    my $regex  = $editor->GetSelectedText || '';

    my $expl   = YAPE::Regex::Explain->new( $regex )->explain;

    my $dialog = Wx::Dialog->new(
        $self->main,
        -1,
        'Regex',
        [ -1, -1 ],
        [ 560, 330 ],
        Wx::wxDEFAULT_FRAME_STYLE,
    );
        
    my $main_sizer   = Wx::GridBagSizer->new( 2, 0 );
    my $text         = Wx::TextCtrl->new(
        $dialog,
        -1,
        $expl,
        [-1,-1],
        [ 540, 250 ],
        Wx::wxTE_MULTILINE | Wx::wxTE_READONLY,
    );
    
    my $cur_font   = $text->GetFont;
    my $fixed_font = Wx::Font->new(
        $cur_font->GetPointSize,
        Wx::wxFONTFAMILY_TELETYPE,
        $cur_font->GetStyle,
        $cur_font->GetWeight,
        $cur_font->GetUnderlined,
    );
    
    $text->SetFont( $fixed_font );
    $text->SetSelection( 0, 0 );
    
    my $size   = Wx::Button::GetDefaultSize;
    my $ok_btn = Wx::Button->new( $dialog, Wx::wxID_OK, '', Wx::wxDefaultPosition, $size );
    
    $main_sizer->Add( $text, Wx::GBPosition->new( 0, 0 ),
                Wx::GBSpan->new(1,1), wxLEFT | wxALIGN_CENTER_VERTICAL , 2);
    $main_sizer->Add( $ok_btn, Wx::GBPosition->new( 1, 0 ),
                Wx::GBSpan->new(1,1), wxLEFT | wxALIGN_CENTER_VERTICAL , 2);

    $dialog->SetSizer( $main_sizer );
    $dialog->SetAutoLayout(1);

    $dialog->ShowModal;
}


1; # End of Padre::Plugin::RegexExplain

# ABSTRACT: A Padre plugin for Regex explainations


__END__
=pod

=head1 NAME

Padre::Plugin::RegexExplain - A Padre plugin for Regex explainations

=head1 VERSION

version 0.02

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Padre::Plugin::RegexExplain;

    my $foo = Padre::Plugin::RegexExplain->new();
    ...

=head1 AUTHOR

Renee Baecker <module@renee-baecker.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0

=cut

