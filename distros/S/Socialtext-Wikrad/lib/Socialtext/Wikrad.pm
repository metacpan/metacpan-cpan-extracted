package Socialtext::Wikrad;
use strict;
use warnings;
use Curses::UI;
use Carp qw/croak/;
use File::Path qw/mkpath/;
use base 'Exporter';
our @EXPORT_OK = qw/$App/;

our $VERSION = '0.07';

=head1 NAME

Socialtext::Wikrad - efficient wiki browsing and editing

=head1 SYNOPSIS

  my $app = Socialtext::Wikrad->new(rester => $rester);
  $app->set_page( $starting_page );
  $app->run;

=cut

our $App;

sub new {
    my $class = shift;
    $App = { 
        history => [],
        save_dir => "$ENV{HOME}/wikrad",
        @_ ,
    };
    die 'rester is mandatory' unless $App->{rester};
    $App->{rester}->agent_string("wikrad/$VERSION");
    bless $App, $class;
    $App->_setup_ui;
    return $App;
}

sub run {
    my $self = shift;

    my $quitter = sub { exit };
    $self->{cui}->set_binding( $quitter, "\cq");
    $self->{cui}->set_binding( $quitter, "\cc");
    $self->{win}{viewer}->set_binding( $quitter, 'q');

    $self->{cui}->reset_curses;
    $self->{cui}->mainloop;
}

sub save_dir { 
    my $self = shift;
    my $dir = $self->{save_dir};
    unless (-d $dir) {
        mkpath $dir or die "Can't mkpath $dir: $!";
    }
    return $dir;
}

sub set_page {
    my $self = shift;
    my $page = shift;
    my $workspace = shift;
    my $no_history = shift;

    my $pb = $self->{win}{page_box};
    my $wksp = $self->{win}{workspace_box};

    unless ($no_history) {
        push @{ $self->{history} }, {
            page => $pb->text,
            wksp => $wksp->text,
            pos  => $self->{win}{viewer}{-pos},
        };
    }
    $self->set_workspace($workspace) if $workspace;
    unless (defined $page) {
        $self->{rester}->accept('text/plain');
        $page = $self->{rester}->get_homepage;
    }
    $pb->text($page);
    $self->load_page;
}

sub set_last_tagged_page {
    my $self = shift;
    my $tag  = shift;
    my $r = $self->{rester};

    $r->accept('text/plain');
    my @pages = $r->get_taggedpages($tag);
    $self->set_page(shift @pages);
}

sub download {
    my $self = shift;
    my $current_page = $self->{win}{page_box}->text;
    $self->{cui}->leave_curses;

    my $r = $self->{rester};
    
    my $dir = $self->_unique_filename($current_page);
    mkdir $dir or die "Error creating directory $dir: $!";

    my %ct = (
        html => 'text/html',
        wiki => 'text/x.socialtext-wiki',
    );

    while (my ($ext, $ct) = each %ct) {
        $r->accept($ct);
        my $file = "$dir/content.$ext";
        open my $fh, ">$file" or die "Can't open $file: $!";
        print $fh $r->get_page($current_page);
        close $fh or die "Can't open $file: $!";
    }
    
    # Fetch attachments
    $r->accept('perl_hash');
    my $attachments = $r->get_page_attachments($current_page);

    for my $a (@$attachments) {
        my $filename = "$dir/$a->{name}";
        my ( $status, $content ) = $r->_request(
            uri    => $a->{uri},
            method => 'GET',
        );
        if ($status != 200) {
            warn "Error downloading $filename: $status";
            next;
        }
        open my $fh, ">$filename" or die "Can't open $filename: $!\n";
        print $fh $content;
        close $fh or die "Error writing to $filename: $!\n";
        print "Downloaded $filename\n";
    }
}

sub _unique_filename {
    my $self = shift;
    my $original = shift;
    my $filename = $original;
    my $i = 0;
    while (-e $filename) {
        $i++;
        $filename = "$original.$i";
    }
    return $filename;
}

sub set_workspace {
    my $self = shift;
    my $wksp = shift;
    $self->{win}{workspace_box}->text($wksp);
    $self->{rester}->workspace($wksp);
}

sub go_back {
    my $self = shift;
    my $prev = pop @{ $self->{history} };
    if ($prev) {
        $self->set_page($prev->{page}, $prev->{wksp}, 1);
        $self->{win}{viewer}{-pos} = $prev->{pos};
    }
}

sub get_page {
    return $App->{win}{page_box}->text;
}

sub load_page {
    my $self = shift;
    my $current_page = $self->{win}{page_box}->text;

    if (! $current_page) {
        $self->{cui}->status('Fetching list of pages ...');
        $self->{rester}->accept('text/plain');
        my @pages = $self->{rester}->get_pages;
        $self->{cui}->nostatus;
        $App->{win}->listbox(
            -title => 'Choose a page',
            -values => \@pages,
            change_cb => sub {
                my $page = shift;
                $App->set_page($page) if $page;
            },
        );
        return;
    }

    $self->{cui}->status("Loading page $current_page ...");
    $self->{rester}->accept('text/x.socialtext-wiki');
    my $page_text = $self->{rester}->get_page($current_page);
    $page_text = $self->_render_wikitext_wafls($page_text);
    $self->{cui}->nostatus;
    $self->{win}{viewer}->text($page_text);
    $self->{win}{viewer}->cursor_to_home;
}

sub _setup_ui {
    my $self = shift;
    $self->{cui} = Curses::UI->new( -color_support => 1 );
    $self->{win} = $self->{cui}->add('main', 'Socialtext::Wikrad::Window');
    $self->{cui}->leave_curses;
}

sub _render_wikitext_wafls {
    my $self = shift;
    my $text = shift;

    if ($text =~ m/{st_(?:iteration|project)stories: <([^>]+)>}/) {
        my $tag = $1;
        my $replace_text = "Stories for tag: '$tag':\n";
        $self->{rester}->accept('text/plain');
        my @pages = $self->{rester}->get_taggedpages($tag);
    
        $replace_text .= join("\n", map {"* [$_]"} @pages);
        $replace_text .= "\n";
        $text =~ s/{st_(?:iteration|project)stories: <[^>]+>}/$replace_text/;
    }

    return $text;
}


1;
