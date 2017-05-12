#line 1
package Text::Greeking;
use strict;
use warnings;

use vars qw( $VERSION );
$VERSION = 0.12;

# make controllable eventually.
my @punc   = split('', '..........??!');
my @inpunc = split('', ',,,,,,,,,,;;:');
push @inpunc, ' --';

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    srand;
    $self->init;
}

sub init {
    $_[0]->sources([]);
    $_[0]->paragraphs(2, 8);
    $_[0]->sentences(2, 8);
    $_[0]->words(5, 15);
    $_[0];
}

sub sources {
    $_[0]->{sources} = $_[1] if defined $_[1];
    $_[0]->{sources};
}

sub add_source {
    my ($self, $text) = @_;
    return unless $text;
    $text =~ s/[\n\r]/ /g;
    $text =~ s/[[:punct:]]//g;
    my @words = map { lc $_ } split /\s+/, $text;
    push @{$self->{sources}}, \@words;
}

sub generate {
    my $self = shift;
    my $out;
    $self->_load_default_source unless defined $self->{sources}->[0];
    my @words = @{$self->{sources}->[int(rand(@{$self->{sources}}))]};
    my ($paramin, $paramax) = @{$self->{paragraphs}};
    my ($sentmin, $sentmax) = @{$self->{sentences}};
    my ($phramin, $phramax) = @{$self->{words}};
    my $pcount = int(rand($paramax - $paramin + 1) + $paramin);

    for (my $x = 0; $x < $pcount; $x++) {
        my $p;
        my $scount = int(rand($sentmax - $sentmin + 1) + $sentmin);
        for (my $y = 0; $y < $scount; $y++) {
            my $s;
            my $wcount = int(rand($phramax - $phramin + 1) + $phramin);
            for (my $w = 0; $w < $wcount; $w++) {
                my $word = $words[int(rand(@words))];
                $s .= $s ? " $word" : ucfirst($word);
                $s .=
                  (($w + 1 < $wcount) && !int(rand(10)))
                  ? $inpunc[int(rand(@inpunc))]
                  : '';
            }
            $s .= $punc[int(rand(@punc))];
            $p .= ' ' if $p;
            $p .= $s;
        }
        $out .= $p . "\n\n";    # assumes text.
    }
    $out;
}

sub paragraphs { $_[0]->{paragraphs} = [$_[1], $_[2]] }
sub sentences  { $_[0]->{sentences}  = [$_[1], $_[2]] }
sub words      { $_[0]->{words}      = [$_[1], $_[2]] }

sub _load_default_source {
    my $text = <<TEXT;
Lorem ipsum dolor sit amet, consectetuer adipiscing elit,
sed diam nonummy nibh euismod tincidunt ut laoreet dolore
magna aliquam erat volutpat. Ut wisi enim ad minim veniam,
quis nostrud exerci tation ullamcorper suscipit lobortis
nisl ut aliquip ex ea commodo consequat. Duis autem vel eum
iriure dolor in hendrerit in vulputate velit esse molestie
consequat, vel illum dolore eu feugiat nulla facilisis at
vero eros et accumsan et iusto odio dignissim qui blandit
praesent luptatum zzril delenit augue duis dolore te feugait
nulla facilisi.
Ut wisi enim ad minim veniam, quis nostrud exerci tation
ullamcorper suscipit lobortis nisl ut aliquip ex ea commodo
consequat. Duis autem vel eum iriure dolor in hendrerit in
vulputate velit esse molestie consequat, vel illum dolore eu
feugiat nulla facilisis at vero eros et accumsan et iusto
odio dignissim qui blandit praesent luptatum zzril delenit
augue duis dolore te feugait nulla facilisi. Lorem ipsum
dolor sit amet, consectetuer adipiscing elit, sed diam
nonummy nibh euismod tincidunt ut laoreet dolore magna
aliquam erat volutpat. 
Duis autem vel eum iriure dolor in hendrerit in vulputate
velit esse molestie consequat, vel illum dolore eu feugiat
nulla facilisis at vero eros et accumsan et iusto odio
dignissim qui blandit praesent luptatum zzril delenit augue
duis dolore te feugait nulla facilisi. Lorem ipsum dolor sit
amet, consectetuer adipiscing elit, sed diam nonummy nibh
euismod tincidunt ut laoreet dolore magna aliquam erat
volutpat. Ut wisi enim ad minim veniam, quis nostrud exerci
tation ullamcorper suscipit lobortis nisl ut aliquip ex ea
commodo consequat.
TEXT
    $_[0]->add_source($text);
}

1;

__END__

#line 243

