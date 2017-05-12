package Quiz::Flashcards;
use warnings;
use strict;

use 5.010;

use base 'Exporter';

our @EXPORT = (qw( run_flashcard_app ));

use Carp qw( confess );
use utf8;
use English qw(-no_match_vars);

use Wx;

run_flashcard_app() unless caller();

=head1 NAME

Quiz::Flashcards - Cross-platform modular flashcard GUI application

=cut

our $VERSION = '0.04';    # define version

=head1 DESCRIPTION

Created out of the need to aid in language studies while being able to quickly adapt the program for a higher learning efficiency than most showy flashcard applications allow. This application focuses not on teaching new material, but on training and reinforcing already learned material.

It uses wxPerl for the GUI, which should make it work on most major desktop platforms. Additionally it stores data about the user's certainty and speed in answers in a SQLite database located in the user's data directory.

Flashcard sets as well as additional data like sound files to go along with the sets will be available as seperate modules in the Quiz::Flashcards::Sets:: and Quiz::Flashcards::Audiobanks:: namespaces.

=head1 SYNOPSIS

    use Edu::Flashcards;
    run_flashcard_app();

=head1 FUNCTIONS

=head2 run_flashcard_app

Starts the application itself.

=cut

sub run_flashcard_app {
    my $app = Quiz::Flashcards::App->new;
    $app->MainLoop;
}

=head1 AUTHOR

Christian Walde, C<< <mithaldu at yahoo.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-Quiz-flashcards at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Quiz-Flashcards>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find the source code repository with public read access on Google Code.

=over 4

=item

L<http://edu-flashcards.googlecode.com>

=back


You can find documentation for this module with the perldoc command.

    perldoc Quiz::Flashcards


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Quiz-Flashcards>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Quiz-Flashcards>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Quiz-Flashcards>

=item * Search CPAN

L<http://search.cpan.org/dist/Quiz-Flashcards/>

=back


=head1 RELATED

L<Wx>, L<DBD::SQLite>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Christian Walde, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

################################################################################

package Quiz::Flashcards::App;

use base 'Wx::App';

use strict;
use warnings;
use utf8;
use Time::HiRes qw( time );
use Wx::XRC;
use File::HomeDir;
use File::Spec::Functions;
use Module::Find;
use Wx qw(:everything);
use Wx::Event qw(:everything);
use File::ShareDir ':ALL';
use DBI;
use List::Util 'shuffle';

my %el;

sub OnInit {
    my $self = shift;

    $self->load_gui;
    $self->load_config;
    $self->adjust_fonts;
    $self->load_sets_into_selector;
    $self->load_timers;
    $self->load_waiting_animator;
    $self->register_events;
    
    return 1;
}

# Event Sub-Routines
################################################################################

sub load_set {
    my ( $self, $event ) = @_;

    my $module = $event->GetString;
    my $title  = "Quiz::Flashcards - $module";

    $module =~ s/ -> /::/;

    eval " require Quiz::Flashcards::Sets::$module; import Quiz::Flashcards::Sets::$module; ";
    confess $@ if $@;

    @{ $self->{set} } = get_set();
    $self->{set_name} = $module;

    $self->setup_set_table;
    $self->load_set_table;
    $self->load_set_sounds;

    $el{frame}->SetTitle($title);
    $el{start_next_button}->SetLabel("Start");

    $el{start_next_button}->Enable;
    $el{set_status_toggle}->Enable;
    
    $self->hide_sizer_contents( $self->{multi_answer_sizer} );
    $el{answer}->Hide;
    $el{correct_answer}->Hide;
    $el{answer_time}->SetLabel( '' );

    $el{question}->SetBackgroundColour(wxNullColour);
    $el{question}->SetLabel( '' );
    $el{question}->Show;
    $el{start_next_button}->Show;
    $el{answer_time}->Show;

    $el{start_next_button}->SetFocus;

    $self->{set_complexity} = 1;
    $self->{set_part_certainty} = 0;
    $self->update_set_status;

    $self->re_layout;
}

sub toggle_set_status {
    my ( $self, $event ) = @_;

    if ( $el{set_status}->IsShown ) {
        $el{set_status}->Hide;
        $el{set_status_summary}->Hide;
    }

    elsif ( $el{set_status_summary}->IsShown ) {
        $el{set_status}->Show;
    }

    else {
        $self->update_set_status;
        $el{set_status_summary}->Show;
    }

    $self->re_layout;
}

sub start_next_clicked {
    my ( $self, $event ) = @_;

    $self->select_current_question;
    $self->update_ui_for_question;
}

sub check_answer {
    my ( $self, $event ) = @_;

    $el{question_timer}->Stop;

    my $certainty_modifier;

    if ( $el{answer}->GetValue eq $self->{curr_question}->{answer} ) {
        my $answer_time = time - $self->{curr_question}->{time_start};
        $el{answer_time}->SetLabel( sprintf( "%.1f s", $answer_time ) );
        $certainty_modifier = 100;
        $self->{curr_question}->{time_to_answer} += .2 * ( $answer_time - $self->{curr_question}->{time_to_answer} );
        $self->{curr_question}->{time_to_answer} = $self->{curr_question}->{time_to_answer};
        $el{correct_answer}->Show;
        #$el{question_description}->Show;
        $self->enable_start_next_button;
        $el{question}->SetBackgroundColour(wxGREEN);
    }
    else {
        $el{question}->SetBackgroundColour(wxRED);
        $certainty_modifier = 0;
        $el{correct_answer}->Show;
        #$el{question_description}->Show;
        $el{wrong_timer}->Start(1_000);

        for my $item ( @{ $self->{set} } ) {
            next if $item->{answer} ne $el{answer}->GetValue;

            $item->{certainty} += .1 * ( $certainty_modifier - $item->{certainty} );
            $item->{certainty} = $item->{certainty};

            $self->update_user_data_db($item);

            last;
        }
    }

    my $certainty_change = .2 * ( $certainty_modifier - $self->{curr_question}->{certainty} );
    $self->{curr_question}->{certainty} += $certainty_change;
    $self->{curr_question}->{last_seen} = int time;

    $self->update_user_data_db( $self->{curr_question} );

    $self->update_set_status;

    Wx::Sound->new( $self->{curr_question}->{audio_file_path} )->Play() if $self->{curr_question}->{audio_file_path};

    $el{animator}->Hide;
    $el{set_selector}->Enable;
    $el{answer}->Disable;

    $self->re_layout;
}

sub evt_multi_answer_button {
    my ( $self, $event ) = @_;
    
    my $answer = $event->GetEventObject->GetLabel;
    
    $el{answer}->SetValue( $answer );
    
    $self->disable_sizer_contents( $self->{multi_answer_sizer} );
    
    $self->check_answer;
}

sub evt_process_keyboard {
    my ( $self, $event ) = @_;
    
    my $choice = $event->GetKeyCode();
    
    given ( $choice ) {
        when ( $_ == WXK_NUMPAD7 ) { $choice = 0  }
        when ( $_ == WXK_NUMPAD8 ) { $choice = 1  }
        when ( $_ == WXK_NUMPAD9 ) { $choice = 2  }
        when ( $_ == WXK_NUMPAD4 ) { $choice = 3  }
        when ( $_ == WXK_NUMPAD5 ) { $choice = 4  }
        when ( $_ == WXK_NUMPAD6 ) { $choice = 5  }
        when ( $_ == WXK_NUMPAD1 ) { $choice = 6  }
        when ( $_ == WXK_NUMPAD2 ) { $choice = 7  }
        when ( $_ == WXK_NUMPAD3 ) { $choice = 8  }
        when ( $_ == WXK_NUMPAD0 ) { $choice = 10 }
    }
    
    if ( defined $choice ) {
        EVT_KEY_DOWN( $self,  undef );
        
        my @children = $self->{multi_answer_sizer}->GetChildren;
        $choice = $children[$choice]->GetWindow->GetLabel;
    
        $el{answer}->SetValue( $choice );
        
        $self->disable_sizer_contents( $self->{multi_answer_sizer} );
        
        $self->check_answer;
    }
}

# Event Helper Sub-Routines
################################################################################

sub enable_start_next_button {
    my ($self) = @_;

    $el{wrong_timer}->Stop;
    $el{start_next_button}->Enable;
    $el{start_next_button}->SetFocus;
}

sub setup_set_table {
    my ($self) = @_;

    $self->{set_table} = "set_$self->{set_name}";
    $self->{set_table} =~ s/::/_/;

    $self->{dbh}->do( "
        CREATE TABLE IF NOT EXISTS $self->{set_table} (
            id INTEGER NOT NULL PRIMARY KEY,
            certainty INTEGER DEFAULT 0 NOT NULL,
            time_to_answer REAL DEFAULT 10 NOT NULL,
            last_seen INTEGER DEFAULT 0 NOT NULL
        )
    " );
}

sub load_set_table {
    my ($self) = @_;

    my $hash_ref = $self->{dbh}->selectall_hashref( "SELECT * FROM $self->{set_table};", 'id' );

    for my $id ( 0 .. $#{ $self->{set} } ) {
        next if !defined $self->{set}->[$id];
        my $set_entry = $self->{set}->[$id];
        $set_entry->{id}             = $id;
        $set_entry->{certainty}      = $hash_ref->{$id}->{certainty} || 0;
        $set_entry->{time_to_answer} = $hash_ref->{$id}->{time_to_answer} || 10;
        $set_entry->{last_seen}      = $hash_ref->{$id}->{last_seen} || 0;
    }
}

sub load_set_sounds {
    my ($self) = @_;

    for my $item ( @{ $self->{set} } ) {
        next unless $item->{audiobank};
        next unless $item->{audio_file};

        my $ab = $item->{audiobank};
        $self->load_audiobank($ab) unless $self->{audiobanks}->{$ab};
        $item->{audio_file_path} = $self->{audiobanks}->{$ab}->{ $item->{audio_file} };
    }
}

sub update_set_status {
    my ( $self, $event ) = @_;
    $el{set_status}->ClearAll;

    my %sum;
    my $i        = 0;
    my $set_size = @{ $self->{set} };

    for my $item ( @{ $self->{set} } ) {
        $el{set_status}->InsertStringItem(
            $i++,
            "$item->{question}: $item->{certainty} %, " . sprintf( "%.1f", $item->{time_to_answer} ) . " s"
        );
        $sum{certainty}      += $item->{certainty};
        $sum{time_to_answer} += $item->{time_to_answer};
    }
    my $title = $self->{set_name};
    $title =~ s/::/ -> /;
    
    $self->calc_set_complexity;
    
    my $set_status_summary = 
            "$title\nCertainty = "
          . sprintf( "%.2f", $sum{certainty} / $set_size )
          . " Answer Time = "
          . sprintf( "%.1f", $sum{time_to_answer} / $set_size )
          . " Complexity = "
          . sprintf( "%d/%d", $self->{set_complexity}, $self->{max_complexity} )
          . " Part Certainty = "
          . sprintf( "%.2f", $self->{set_part_certainty} );
    
    $el{set_status_summary}->SetLabel( $set_status_summary );
}

sub calc_set_complexity {
    my ( $self ) = @_;
    
    if( !$self->{max_complexity} ) {
        $self->{max_complexity} = 1;
        
        for my $item ( @{ $self->{set} } ) {
            $self->{max_complexity} = $item->{complexity} if $self->{max_complexity} < $item->{complexity};
        }
    }
    
    # calculate the certainty for each complexity group, starting with the largest
    for my $c ( 1 .. $self->{max_complexity} ) {
        my ($sum, $count, $done) = (0,0,0);
        for my $item ( @{ $self->{set} } ) {
            next if $item->{complexity} != $c;
            $sum += $item->{certainty};
            $count++;
        }
        
        my $this_certainty = $sum/$count;
        $done = 1 if (
            ( $self->{set_part_certainty} > 50 and $this_certainty <= 50 )
            or ( $this_certainty <= 50 and $c == 1 )
        );
        
        $self->{set_complexity} = $c;
        $self->{set_part_certainty} = $sum/$count;
        
        last if $done;
    }
    
}

sub select_current_question {
    my ($self) = @_;
    my ( @choices, $margin );
    
    # remove items that have a too high complexity and make sure the last one isn't repeated immediately
    for my $item ( @{ $self->{set} } ) {
        next if $item->{complexity} > $self->{set_complexity};
        next if $self->{curr_question} and $self->{curr_question}{question} eq $item->{question};
        
        push @choices, $item;
    }
    
    # find items with low certainty that we haven't seen recently
    @choices = trim_hash_array_by ( "certainty", \@choices );
    
    # find items with low certainty that we haven't seen recently
    @choices = trim_hash_array_by ( "last_seen", \@choices );

    # find items with a high response time
    @choices = trim_hash_array_by ( "time_to_answer", \@choices, 'reverse' );

    # pick random item from choices
    my $pick = int( rand($#choices) );

    $self->{curr_question} = $choices[$pick];
}

sub trim_hash_array_by {
    my ($parameter, $array, $reverse) = @_;
    
    my @sort_array;
    @sort_array = sort { $a->{$parameter} <=> $b->{$parameter} } @{$array};
    @sort_array = reverse @sort_array if $reverse;
    
    my $margin = 0.33 * scalar @sort_array;
    $margin = 4 if $margin < 4;
    splice @sort_array, $margin;
    
    return @sort_array;
}

sub update_ui_for_question {
    my ($self) = @_;
    
    $el{question}->SetBackgroundColour(wxNullColour);
    $el{set_selector}->Disable;
    $el{start_next_button}->Disable;
    $el{start_next_button}->SetLabel("Next");
    $el{answer_time}->SetLabel('');
    $el{correct_answer}->Hide;
    $el{correct_answer}->SetLabel( $self->{curr_question}{answer} );
    $el{animator}->Show;
    $self->enable_sizer_contents( $self->{multi_answer_sizer} ) if ( $self->{curr_question}{answer_type} eq 'multi' );
    
    given ($self->{curr_question}{answer_type}) {
        when ( "text"  ) { $self->load_text_answer; }
        when ( "multi" ) { $self->load_multi_answer; }
        default          { confess( "unknown answer type: $self->{curr_question}{answer_type}" );  }
    }

    $el{question}->SetLabel( $self->{curr_question}{question} );
    $self->re_layout;

    $self->{curr_question}->{time_start} = time;
    $el{question_timer}->Start(10_000);
}

sub load_text_answer {
    my ($self) = @_;
    
    $self->hide_sizer_contents( $self->{multi_answer_sizer} );
    $el{answer}->Show;
    $el{answer}->SetValue('');
    $el{answer}->Enable;
    $el{answer}->SetFocus;
}

sub load_multi_answer {
    my ($self) = @_;
    
    my (@possible_answers, @answers);
    
    for my $answer ( @{ $self->{set} } ) {
        next if $answer->{answer} eq $self->{curr_question}{answer};
        next if $answer->{complexity} > $self->{set_complexity};
        
        push @possible_answers, $answer->{answer};
    }
    
    push @answers, $self->{curr_question}{answer};
    while ( @answers < 9 and @possible_answers > 0 ) {
        my $pick = int( rand( $#possible_answers ) );
        push @answers, $possible_answers[$pick];
        splice @possible_answers, $pick, 1;
    }
    
    @answers = shuffle(@answers);
    
    my @children = $self->{multi_answer_sizer}->GetChildren;
    
    for my $i ( 0..8 ) {
        my $a = $children[$i]->GetWindow;
        $a->SetLabel( $answers[$i] || '' );
    }
    
    $self->show_sizer_contents( $self->{multi_answer_sizer} );
    $el{answer}->Hide;
    
    EVT_KEY_DOWN( $self,  \&evt_process_keyboard );
}

sub update_user_data_db {
    my ( $self, $item ) = @_;

    $self->{dbh}->do( "
        REPLACE INTO $self->{set_table}
        VALUES (?,?,?,?);
    ", undef,
        $item->{id}, $item->{certainty}, $item->{time_to_answer}, $item->{last_seen} );
}

sub load_audiobank {
    my ( $self, $audiobank ) = @_;

    eval "require $audiobank; $audiobank->import();";

    if ($@) {
        $self->{audiobanks}->{$audiobank} = 'not_available';
        return;
    }

    my @content_list;

    eval "\@content_list = $audiobank->get_content_list;";
    confess $@ if $@;

    my $dist = $audiobank;
    $dist =~ s/::/-/g;
    $self->{audiobank_paths}->{$audiobank} ||= dist_dir($dist);

    for my $file (@content_list) {
        $self->{audiobanks}->{$audiobank}->{$file} = catfile( $self->{audiobank_paths}->{$audiobank}, $file );
    }
}



# GUI Setup Sub-Routines
################################################################################

sub load_gui {
    my ($self) = @_;

    my $xr = Wx::XmlResource->new();
    $xr->InitAllHandlers();
    $xr->Load(catfile( dist_dir('Quiz-Flashcards'), 'gui.xrc' ));

    $el{frame} = Wx::Frame->new;
    $xr->LoadFrame( $el{frame}, undef, 'frame' );

    $self->{main_sizer} = $el{frame}->GetSizer;

    my @children = $el{frame}->GetChildren;

    for my $child (@children) {
        $el{ $child->GetName } = $child;
    }
    
    $self->{bottom_sizer} = $el{start_next_button}->GetContainingSizer;
    $self->{multi_answer_sizer} = $el{answer_0}->GetContainingSizer;
    
    $self->re_layout;
    $el{frame}->Show(1);
}

sub re_layout {
    my ($self) = @_;

    $self->{main_sizer}->Layout;
    $self->{main_sizer}->SetSizeHints( $el{frame} );
    $el{frame}->Center;
}

sub load_config {
    my ($self) = @_;

    $self->{dbh} = setup_database();
    $self->{c} = $self->{dbh}->selectall_hashref( "SELECT * FROM settings;", 'name' );

    for my $key ( keys %{ $self->{c} } ) {
        $self->{c}->{$key} = $self->{c}->{$key}->{value};
    }
}

sub setup_database {
    my $path = catfile( File::HomeDir->my_data, '.Quiz-Flashcards' );

    my $dbh = DBI->connect( "dbi:SQLite:dbname=$path", "", "" );

    $dbh->{HandleError} = sub { confess(shift) };

    $dbh->do( "
        CREATE TABLE IF NOT EXISTS settings (
            name TEXT PRIMARY KEY,
            value TEXT
        );
    " );

    #$dbh->do("
    #    INSERT OR IGNORE INTO settings
    #    VALUES ( 'font_size_question', 'original' );
    #");

    return $dbh;
}

sub load_sets_into_selector {
    my ($self) = @_;

    my @found = findallmod Quiz::Flashcards::Sets;
    for my $module (@found) {
        $module =~ s/Quiz::Flashcards::Sets:://;
        $module =~ s/::/ -> /;
        $el{set_selector}->Append($module);
    }

    $self->re_layout;
}

sub load_timers {
    my ($self) = @_;

    $el{question_timer_id} = Wx::NewId;
    $el{question_timer}    = Wx::Timer->new( $self, $el{question_timer_id} );
    $el{wrong_timer_id}    = Wx::NewId;
    $el{wrong_timer}       = Wx::Timer->new( $self, $el{wrong_timer_id} );
}

sub register_events {
    my ($self) = @_;

    EVT_CHOICE( $self, $el{set_selector}, \&load_set );
    EVT_BUTTON( $self, $el{set_status_toggle}, \&toggle_set_status );
    EVT_BUTTON( $self, $el{start_next_button}, \&start_next_clicked );
    EVT_TIMER( $self, $el{question_timer_id}, \&check_answer );
    EVT_TIMER( $self, $el{wrong_timer_id},    \&enable_start_next_button );
    EVT_TEXT_ENTER( $self, $el{answer}, \&check_answer );
    
    my @multi_answer_buttons = $self->{multi_answer_sizer}->GetChildren;
    for my $button ( @multi_answer_buttons ) {
        EVT_BUTTON( $self, $button->GetWindow, \&evt_multi_answer_button );
    }
}

sub load_waiting_animator {
    my ($self) = @_;

    my $activity_anim_path = catfile( dist_dir('Quiz-Flashcards'), 'ajax-loader.gif' );
    my $animation = Wx::Animation->new();
    $animation->LoadFile( $activity_anim_path, wxANIMATION_TYPE_GIF );
    $el{animator}->SetAnimation($animation);
    $el{animator}->Play;
    $el{animator}->Hide;

    $self->re_layout;
}

sub adjust_fonts {
    my ($self) = @_;

    my $question_font = $el{question}->GetFont;
    $question_font->SetPointSize( $question_font->GetPointSize * 4 );
    $el{question}->SetFont($question_font);
    $el{answer}->Disable;
    $el{correct_answer}->Hide;
    
    my $answer_font = $el{correct_answer}->GetFont;
    $answer_font->SetPointSize( $answer_font->GetPointSize * 2 );
    $el{correct_answer}->SetFont($answer_font);
}

sub show_sizer_contents {
    my ($self, $sizer) = @_;
    
    for my $child ( $sizer->GetChildren ) {
        $child->GetWindow->Show;
    }
}

sub hide_sizer_contents {
    my ($self, $sizer) = @_;
    
    for my $child ( $sizer->GetChildren ) {
        $child->GetWindow->Hide;
    }
}

sub disable_sizer_contents {
    my ($self, $sizer) = @_;
    
    for my $child ( $sizer->GetChildren ) {
        $child->GetWindow->Disable;
    }
}

sub enable_sizer_contents {
    my ($self, $sizer) = @_;
    
    for my $child ( $sizer->GetChildren ) {
        $child->GetWindow->Enable;
    }
}

1;    # End of Quiz::Flashcards