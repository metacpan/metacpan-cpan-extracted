package Sweat;

our $VERSION = 201909171;

use v5.10;

use warnings;
use strict;
use Types::Standard qw(Int ArrayRef Maybe Str Bool HashRef);

use List::Util qw(shuffle);
use YAML;
use File::Temp qw(tmpnam);
use Web::NewsAPI;
use MediaWiki::API;
use LWP;
use Try::Tiny;
use utf8::all;
use Term::ReadKey;
use POSIX qw(uname);
use File::Which;

use Sweat::Group;
use Sweat::Article;

use Moo;
use namespace::clean;

BEGIN {
    binmode STDOUT, ":utf8";
}

sub DEMOLISH {
    \&clean_up;
}

has 'groups' => (
    is => 'lazy',
    isa => ArrayRef,
);

has 'group_config' => (
    is => 'rw',
    isa => ArrayRef,
    default => sub { _default_group_config( @_ ) },
);

has 'drills' => (
    is => 'lazy',
    isa => ArrayRef,
);

has 'drill_count' => (
    is => 'rw',
    isa => Int,
    required => 1,
    default => 12,
);

has 'drill_counter' => (
    is => 'rw',
    isa => Int,
    default => 0,
);

has 'config' => (
    is => 'ro',
    isa => Maybe[Str],
);

has 'shuffle' => (
    is => 'rw',
    default => 0,
    isa => Bool,
);

has 'entertainment' => (
    is => 'rw',
    default => 1,
    isa => Bool,
);

has 'chair' => (
    is => 'rw',
    default => 1,
    isa => Bool,
);

has 'jumping' => (
    is => 'rw',
    default => 1,
    isa => Bool,
);

has 'drill_length' => (
    is => 'rw',
    isa => Int,
    default => 30,
);

has 'rest_length' => (
    is => 'rw',
    isa => Int,
    default => 10,
);

has 'drill_prep_length' => (
    is => 'rw',
    isa => Int,
    default => 1,
);

has 'side_switch_length' => (
    is => 'rw',
    isa => Int,
    default => 4,
);

has 'speech_program' => (
    is => 'rw',
    isa => Str,
    default => sub { (uname())[0] eq 'Darwin'? 'say' : 'espeak' },
);

has 'url_program' => (
    is => 'rw',
    isa => Maybe[Str],
    default => sub { (uname())[0] eq 'Darwin'? 'open' : undef },
);

has 'fortune_program' => (
    is => 'rw',
    isa => Maybe[Str],
    default => 'fortune',
);

has 'newsapi_key' => (
    is => 'rw',
    isa => Maybe[Str],
);

has 'country' => (
    is => 'rw',
    isa => Str,
    default => 'us',
);

has 'articles' => (
    is => 'lazy',
    isa => ArrayRef,
);

has 'weather' => (
    is => 'lazy',
    isa => Str,
);

has 'speaker_pid' => (
    is => 'rw',
    isa => Int,
);

around BUILDARGS => sub {
    my ( $orig, $class, %args ) = @_;

    _mangle_args( \%args );

    return $class->$orig(%args);

};

sub BUILD {
    my ($self, $args) = @_;

    my $config;

    try {
        $config = Load( $self->config );
    }
    catch {
        die "Can't load the config file! Here's the error from the YAML parser: "
            . $_
            . "\n";
    };

    foreach ( $args, $config ) {
        _mangle_args( $_ );
    }

    for my $method( qw(shuffle entertainment chair jumping)) {
        next if defined $args->{$method};
        if ( defined $config->{$method} ) {
            my $value = $config->{$method} // 0;
            $self->$method($value);
        }
    }

    for my $method (
        qw(
            newsapi_key country fortune_program speech_program url_program
            rest_length drill_length drill_count
        )
    ) {
        next if defined $args->{$method};
        if ( defined $config->{$method} ) {
            $self->$method($config->{$method});
        }
    }

    if ( my $group_data = $config->{groups} ) {
        $self->group_config( $group_data );
    }

    if ( $args->{no_news} ) {
        $self->newsapi_key( undef );
    }

    $self->_check_resources;
    $self->_load_entertainment;

}

sub _check_resources {
    my $self = shift;

    my $speech_program = $self->speech_program;
    my $bare_speech_program = (split /\s+/, $speech_program)[0];

    unless ( which( $bare_speech_program) ) {
        die "ERROR: Sweat's 'speech-program' configuration is set to "
            . "'$speech_program', but there doesn't seem to be a program "
            . "there. I can't run without a speech program... sorry!\n";
    }

    if ( $self->entertainment ) {
        foreach (qw (url fortune) ) {
            my $method = "${_}_program";
            my $program = $self->$method;
            my $bare_program = (split /\s+/, $program)[0];
            unless ( which( $bare_program ) ) {
                $self->$method( undef );
                warn "WARNING: Sweat's '$_-program' configuration is set to "
                     . "'$program', but there doesn't seem to be a program there. "
                     . "Going ahead without $_-opening.\n";
            }
        }
    }
}


sub _load_entertainment {
    my $self = shift;
    if ( $self->entertainment ) {
        local $| = 1;
        say "Loading entertainment...";
        $self->articles;
        $self->weather;
        say "...done.";
    }

}

sub _build_articles {
    my $self = shift;

    if ( $self->newsapi_key ) {
        try {
            my $newsapi = Web::NewsAPI->new(
                api_key => $self->newsapi_key,
            );
            my $result = $newsapi->top_headlines(
                country => $self->country,
                pageSize => $self->drill_count,
            );
            return [
                map { Sweat::Article->new_from_newsapi_article($_) }
                    $result->articles
            ];
        }
        catch {
            die "Sweat ran into a problem fetching news articles: $_\n";
        };
    }
    else {
        try {
            my @articles;
            $articles[0] = Sweat::Article->new_from_random_wikipedia_article;
            print '.';
            for (1..$self->drill_count) {
                push @articles,
                    Sweat::Article->new_from_linked_wikipedia_article(
                        $articles[-1]
                    );
                    print '.';
            }
            return \@articles;
        }
        catch {
            die "Sweat ran into a problem fetching Wikipedia articles: $_\n";
        };
    }

}

my $temp_file = tmpnam();

sub sweat {
    my $self = shift;

    ReadMode 3;

    for my $drill (@{ $self->drills }) {
        $self->order($drill);
    }

    $self->cool_down;
    $self->clean_up;
}

sub order {
    my ( $self, $drill ) = @_;

    $self->drill_counter( $self->drill_counter + 1 );

    $self->rudely_speak(
        'Prepare for '
        . $drill->name
        . '. Drill '
        . $self->drill_counter
        . '.'
    );
    $self->countdown($self->rest_length);

    my ($extra_text, $url, $article) = $self->entertainment_for_drill( $drill );
    $extra_text //= q{};

    $self->rudely_speak( "Start now. $extra_text");
    my $url_tempfile;
    if ( defined $url ) {
        if ( $url =~ m{\Wyoutube.com/} ) {
            $url_tempfile = $self->mangle_youtube_url( $article );
            $url = "file://$url_tempfile";
        }
        if ( defined $self->url_program ) {
            system( split (/\s+/, $self->url_program), $url );
        }
    }

    if ( $drill->requires_side_switching ) {
        $self->countdown( $self->drill_length / 2 );
        $self->speak( 'Switch sides.');
        $self->countdown( $self->side_switch_length );
        $self->speak( 'Resume.' );
        $self->countdown( $self->drill_length / 2 );
    }
    else {
        $self->countdown( $self->drill_length );
    }

    $self->rudely_speak( 'Rest.' );
    sleep $self->drill_prep_length;
}

sub countdown {
    my ($self, $seconds) = @_;
    return unless $seconds;

    my $seconds_label_cutoff = 10;
    my @spoken_seconds = (20, 15, 10, 5, 4, 3, 2, 1);
    my $label = 'seconds left';

    for my $current_second (reverse(0..$seconds)) {
        my $keystroke = ReadKey (1);
        if ( $keystroke ) {
            $self->pause;
        }
        if (
            ( grep {$_ == $current_second} @spoken_seconds )
            || ( $current_second && not ( $current_second % 10 ) )
        ) {
            if ( $current_second >= $seconds_label_cutoff ) {
                $self->speak( "$current_second $label." );
                $label = 'seconds';
            }
            else {
                $self->shut_up; # Final countdown, so interrupt any chattiness
                $self->speak( $current_second );
            }
        }
    }
}

sub shut_up {
    my $self = shift;

    # We check for drill-length here for the sake of testing, which usually
    # sets this to 0, and also runs under the `prove` program... which will
    # get killed by the code below, oops. Something to improve later.
    if ( -e $temp_file && $self->drill_length ) {
        my $group = getpgrp;
        unlink $temp_file;
        $SIG{TERM} = 'IGNORE';
        kill ('TERM', -$group);
        $SIG{TERM} = 'DEFAULT';
    }
}

sub pause {
    my $self = shift;

    $self->shut_up;
    say "***PAUSED*** Press any key to resume.";
    $self->leisurely_speak( 'Paused.' );
    ReadKey (0);
    say "Resuming...";
    $self->leisurely_speak( 'Resuming.' );
}

sub entertainment_for_drill {
    my ( $self, $drill ) = @_;

    unless ($self->entertainment) {
        return (undef, undef);
    }

    my $text;
    my $url;
    my $article;

    if ( $drill->requires_side_switching ) {
        $text = $self->weather;
    }
    else {
        $article = $self->next_article;
        $text = $article->text;
        $url = $article->url;
    }

    return ( $text, $url, $article );
}


sub fortune {
    my $self = shift;

    return q{} unless $self->entertainment;

    my $exec = $self->fortune_program;

    no warnings;
    my $text = `$exec` // '';
    use warnings;

    unless (length $text) {
        warn "Sweat tried to fetch a fortune by running `$exec`, but didn't "
             . "get any output. Sorry!\n";
    }

    return $text;
}

sub next_article {
    my $self = shift;

    return shift @{ $self->articles };
}

sub _build_weather {
    my $self = shift;

    my $weather;
    my $ua = LWP::UserAgent->new;
    my $response = $ua->get('http://wttr.in?format=3');
    if ( $response->is_success ) {
        $weather = 'The current weather in ' . $response->content;
    }
    else {
        $weather = 'Could not fetch the current weather. Sorry about that.';
    }
    return $weather;
}

sub cool_down {
    my $self = shift;

    $self->speak(
        'Workout complete. ' . $self->fortune
    );
}

sub speak {
    my ( $self, $message ) = @_;

    say $message;

    return if -e $temp_file;

    my $pid = fork;
    if ( $pid ) {
        $self->speaker_pid( $pid );
    }
    else {
        open my $fh, '>', $temp_file;
        print $fh $pid;
        system ( split (/\s+/, $self->speech_program), $message );
        unlink $temp_file;
        exit;
    }
}

sub leisurely_speak {
    my ( $self, $message ) = @_;

    system ( split (/\s+/, $self->speech_program), $message );
}

sub rudely_speak {
    my ( $self, $message ) = @_;

    $self->shut_up;
    $self->speak( $message );
}

# mangle_youtube_url: create a local file that just embeds the youtube
#                     video, preventing autoplay.
sub mangle_youtube_url {
    my ( $self, $article ) = @_;
    my $tempfile = File::Temp->new( SUFFIX => '.html' );
    binmode $tempfile, ":utf8";
    my $title = $article->title;
    my $description = $article->text;
    my $url = $article->url;

    my ($video_id) = $url =~ m{v=(\w+)};

    print $tempfile qq{<html><head><title>$title</title></head>}
              . qq{<body><h1>$title</h1>}
              . qq{<p>$description</p>}
              . qq{<div><iframe src="https://www.youtube.com/embed/$video_id" }
              . q{frameborder="0" allow="accelerometer; autoplay; }
              . q{encrypted-media; gyroscope; picture-in-picture" }
              . q{allowfullscreen></iframe></div>}
              . q{<p><em>This article was mangled by Sweat so that its video }
              . q{didn&#8217;t autoplay. You&#8217;re welcome.</em></p>}
              . qq{</body></html>\n};

    return $tempfile;
}

sub _build_drills {
    my $self = shift;

    my @final_drills;

    while (@final_drills < $self->drill_count) {
        for my $group ( @{ $self->groups } ) {
            my @drills = $group->unused_drills;

            unless ( @drills ) {
                $group->reset_drills;
                @drills = $group->unused_drills;
            }

            if ( $self->shuffle ) {
                @drills = shuffle(@drills);
            }

            $drills[0]->is_used( 1 );
            push @final_drills, $drills[0];

            last if @final_drills == $self->drill_count;
        }
    }

    return \@final_drills;
}

sub clean_up {
    ReadMode 0;
}

sub _build_groups {
    my $self = shift;

    return [ Sweat::Group->new_from_config_data( $self, $self->group_config ) ];

}

sub _default_group_config {
    my $self = shift;
    return Load(<<END);
- name: aerobic
  drills:
    - name: jumping jacks
      requires_jumping: 1
    - name: high knees
      requires_jumping: 1
    - name: step-ups
      requires_a_chair: 1
- name: lower-body
  drills:
    - name: wall sit
    - name: squats
    - name: knee lunges
- name: upper-body
  drills:
    - name: push-ups
    - name: tricep dips
      requires_a_chair: 1
    - name: rotational push-ups
- name: core
  drills:
    - name: abdominal crunches
    - name: plank
    - name: side plank
      requires_side_switching: 1
END
}

sub _mangle_args {
    my ( $args ) = @_;

    for my $key (keys %$args) {
        if ( $key =~ /-/ ) {
            my $new_key = $key;
            my $value = $$args{$key};
            $new_key =~ s/-/_/g;
            $$args{$new_key} = $value;
            delete $$args{$key};
        }
    }
}

1;

=head1 NAME

Sweat - Library for the `sweat` command-line program

=head1 DESCRIPTION

This library is intended for internal use by the L<sweat> command-line program,
and as such offers no publicly documented methods.

=head1 SEE ALSO

L<sweat>

=head1 AUTHOR

Jason McIntosh <jmac@jmac.org>
