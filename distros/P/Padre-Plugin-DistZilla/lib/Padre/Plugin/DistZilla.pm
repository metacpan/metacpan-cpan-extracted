package Padre::Plugin::DistZilla;

use 5.008;

use strict;
use warnings;

use Padre::Constant ();
use Padre::Plugin   ();
use Padre::Wx       ();
use Wx qw(:everything);
use Wx::Event qw(:everything);
use Dist::Zilla;
use Dist::Zilla::App;
use Wx::Perl::DirTree qw(:const);
use File::Which qw(which);

our @ISA = qw(Padre::Plugin);

our $VERSION = '0.02';

sub plugin_name { return 'DistZilla' }

sub padre_interfaces { 'Padre::Plugin' => 0.43 }

sub menu_plugins_simple {
    my $self = shift;

    return $self->plugin_name => [
        'start'   => sub { $self->start },
        'release' => sub { $self->release },
    ]
}

sub release {}

sub start {
    my $self = shift;
    
    my $main = $self->main;

    # create dialog
    my $dialog = Wx::Dialog->new(
        $main,
        -1,
        'Dist::Zilla',
        [ -1, -1 ],
        [ 560, 330 ],
        Wx::wxDEFAULT_FRAME_STYLE,
    );
    
    # directory tree
    my $tree = Wx::Perl::DirTree->new(
        $dialog, 
        [400,250],
        {
            dir     => '.',
            allowed => wxPDT_DIR,
        },
    );
    
    # input field for module name
    my $name_input = Wx::TextCtrl->new(
        $dialog,
        -1,
        '',
        Wx::wxDefaultPosition,
        Wx::wxDefaultSize,
        Wx::wxTE_PROCESS_ENTER | Wx::wxSIMPLE_BORDER,
    );
        
    my $main_sizer = Wx::GridBagSizer->new( 3, 0 );
        
    my $size   = Wx::Button::GetDefaultSize;
    my $ok_btn = Wx::Button->new( $dialog, Wx::wxID_OK, '', Wx::wxDefaultPosition, $size );
    
    my $sizerv = Wx::BoxSizer->new(Wx::wxVERTICAL);
    my $sizerh = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
    $sizerv->Add( $name_input,    0, Wx::wxALL | Wx::wxEXPAND );
    $sizerv->Add( $tree->GetTree, 1, Wx::wxALL | Wx::wxEXPAND );
    $sizerv->Add( $ok_btn,        0, Wx::wxALL | Wx::wxEXPAND );
    $sizerh->Add( $sizerv,        1, Wx::wxALL | Wx::wxEXPAND );

    # Fits panel layout
    $dialog->SetSizerAndFit($sizerh);
	
    $name_input->SetFocus;

    $dialog->SetSizer( $main_sizer );

    my $return = $dialog->ShowModal;
    
    if ( $return == Wx::wxID_OK ) {
        require File::pushd;
        
        my $dir = $tree->GetSelectedPath();
        return if !-d $dir;
        
        my $module = $name_input->GetValue();
        return if $module !~ m{ \A [A-Za-z]\w+(?:::\w+)* \z }xms;
        
        my $return = File::pushd::pushd( $dir );
                
        my $prog = which( 'dzil' );
        return if !$prog;
        
        $main->run_command( "$prog new $module" );
        
        my $run_is_started = $main->{command};
        
        $main->error( $run_is_started );
        
        if ( $run_is_started ) {
            (my $dir_name = $module) =~ s{::}{/}g;
            my @parts = split /::/, $module;
            $parts[-1] .= '.pm';
            
            my $file = File::Spec->catfile( $dir, $dir_name, 'lib', @parts );
            
            my $counter = 0;
            while ( $run_is_started->IsAlive ) {
                $counter++;
            }
            
            if ( -e $file ) {
                Padre::DB::History->create(
                    type => 'files',
                    name => $file,
                );
                
                $main->setup_editor($file);
                $main->refresh;
            }
        }
    }
}

1;

# ABSTRACT: A plugin for Padre to create modules with Dist::Zilla


__END__
=pod

=head1 NAME

Padre::Plugin::DistZilla - A plugin for Padre to create modules with Dist::Zilla

=head1 VERSION

version 0.02

=head1 SYNOPSIS

=head1 AUTHOR

Renee Baecker <module@renee-baecker.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0

=cut

