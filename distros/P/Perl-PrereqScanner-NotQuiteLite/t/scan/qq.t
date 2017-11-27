use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../";
use t::scan::Util;

test(<<'TEST'); # HTML-Perlinfo-1.68/lib/HTML/Perlinfo/Base.pm
eval qq{

END {
    delete \$INC{'HTML/Perlinfo.pm'};
    \$html .= print_thesemodules('loaded',[values %INC]);
    \$html .= print_variables();
    \$html .= '</div></body></html>' if \$self->{'full_page'};
    print \$html; 
 }

}; die $@ if $@;
TEST

test(<<'TEST'); # KARASIK/Prima-1.46/Prima/Sliders.pm
sub init
{
        my $self = shift;
        my %profile = @_;
        my $visible = $profile{visible};
        $profile{visible} = 0;
        for (qw( min max step circulate pageStep)) {$self-> {$_} = 1;};
        $self-> {edit} = bless [], q\Prima::SpinEdit::DummyEdit\;
        %profile = $self-> SUPER::init(%profile);
        my ( $w, $h) = ( $self-> size);
        $self-> {spin} = $self-> insert( $profile{spinClass} =>
                ownerBackColor => 1,
                name           => 'Spin',
                bottom         => 1,
                right          => $w - 1,
                height         => $h - 1 * 2,
                growMode       => gm::Right,
                delegations    => $profile{spinDelegations},
                (map { $_ => $profile{$_}} grep { exists $profile{$_} ? 1 : 0} keys %spinDynas),
                %{$profile{spinProfile}},
        );
        $self-> {edit} = $self-> insert( $profile{editClass} =>
                name         => 'InputLine',
                origin      => [ 1, 1],
                size        => [ $w - $self-> {spin}-> width - 1 * 2, $h - 1 * 2],
                growMode    => gm::GrowHiX|gm::GrowHiY,
                selectable  => 1,
                tabStop     => 1,
                borderWidth => 0,
                current     => 1,
                delegations => $profile{editDelegations},
                (map { $_ => $profile{$_}} keys %editProps),
                %{$profile{editProfile}},
                text        => $profile{value},
        );
        for (qw( min max step value circulate pageStep)) {$self-> $_($profile{$_});};
        $self-> visible( $visible);
        return %profile;
}

sub on_paint
{
        my ( $self, $canvas) = @_;
        my @s = $canvas-> size;
        $canvas-> rect3d( 0, 0, $s[0]-1, $s[1]-1, 1, $self-> dark3DColor, $self-> light3DColor);
}

sub InputLine_MouseWheel
{
        my ( $self, $edit, $mod, $x, $y, $z) = @_;
        $z = int($z/120);
        $z *= $self-> {pageStep} if $mod & km::Ctrl;
        my $value = $self-> value;
        $self-> value( $value + $z * $self-> {step});
        $self-> value( $z > 0 ? $self-> min : $self-> max)
                if $self-> {circulate} && ( $self-> value == $value);
        $edit-> clear_event;
}

sub Spin_Increment
{
        my ( $self, $spin, $increment) = @_;
        my $value = $self-> value;
        $self-> value( $value + $increment * $self-> {step});
        $self-> value( $increment > 0 ? $self-> min : $self-> max)
                if $self-> {circulate} && ( $self-> value == $value);
}

sub InputLine_KeyDown
{
        my ( $self, $edit, $code, $key, $mod) = @_;
        $edit-> clear_event, return if
                $key == kb::NoKey && !($mod & (km::Alt | km::Ctrl)) &&
                chr($code) !~ /^[.\d+-]$/;
        if ( $key == kb::Up || $key == kb::Down || $key == kb::PgDn || $key == kb::PgUp) {
                my ($s,$pgs) = ( $self-> step, $self-> pageStep);
                my $z = ( $key == kb::Up) ? $s : (( $key == kb::Down) ? -$s :
                        (( $key == kb::PgUp) ? $pgs : -$pgs));
                if (( $mod & km::Ctrl) && ( $key == kb::PgDn || $key == kb::PgUp)) {
                        $self-> value( $key == kb::PgDn ? $self-> min : $self-> max);
                } else {
                        my $value = $self-> value;
                        $self-> value( $value + $z);
                        $self-> value( $z > 0 ? $self-> min : $self-> max)
                                if $self-> {circulate} && ( $self-> value == $value);
                }
                $edit-> clear_event;
                return;
        }
        if ($key == kb::Enter) {
                my $value = $edit-> text;
                $self-> value( $value);
                $edit-> clear_event if $value ne $self-> value;
                return;
        }
}

sub InputLine_Change
{
        my ( $self, $edit) = @_;
        $self-> notify(q(Change));
}

sub InputLine_Enter
{
        my ( $self, $edit) = @_;
        $self-> notify(q(Enter));
}

sub InputLine_Leave
{
        my ( $self, $edit) = @_;
        $self-> notify(q(Leave));
}

sub set_bounds
{
        my ( $self, $min, $max) = @_;
        $max = $min if $max < $min;
        ( $self-> { min}, $self-> { max}) = ( $min, $max);
        my $oldValue = $self-> value;
        $self-> value( $max) if $max < $self-> value;
        $self-> value( $min) if $min > $self-> value;
}

sub set_step
{
        my ( $self, $step) = @_;
        $step  = 0 if $step < 0;
        $self-> {step} = $step;
}

sub circulate
{
        return $_[0]-> {circulate} unless $#_;
        $_[0]-> {circulate} = $_[1];
}

sub pageStep
{
        return $_[0]-> {pageStep} unless $#_;
        $_[0]-> {pageStep} = $_[1];
}


sub min          {($#_)?$_[0]-> set_bounds($_[1], $_[0]-> {'max'})      : return $_[0]-> {min};}
sub max          {($#_)?$_[0]-> set_bounds($_[0]-> {'min'}, $_[1])      : return $_[0]-> {max};}
sub step         {($#_)?$_[0]-> set_step         ($_[1]):return $_[0]-> {step}}
sub value
{
        if ($#_) {
                my ( $self, $value) = @_;
                if ( $value =~ m/^\s*([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?\s*$/) {
                        $value = $self-> {min} if $value < $self-> {min};
                        $value = $self-> {max} if $value > $self-> {max};
                } else {
                        $value = $self-> {min};
                }
                return if $value eq $self-> {edit}-> text;
                $self-> {edit}-> text( $value);
        } else {
                my $self = $_[0];
                my $value = $self-> {edit}-> text;
                if ( $value =~ m/^\s*([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?\s*$/) {
                        $value = $self-> {min} if $value < $self-> {min};
                        $value = $self-> {max} if $value > $self-> {max};
                } else {
                        $value = $self-> {min};
                }
                return $value;
        }
}


# gauge reliefs
package
    gr;
use constant Sink         =>  -1;
use constant Border       =>  0;
use constant Raise        =>  1;


package Prima::Gauge;
use vars qw(@ISA);
@ISA = qw(Prima::Widget);

{
my %RNT = (
        %{Prima::Widget-> notification_types()},
        Stringify => nt::Action,
);

sub notification_types { return \%RNT; }
}

sub profile_default
{
        return {
                %{$_[ 0]-> SUPER::profile_default},
                indent         => 1,
                relief         => gr::Sink,
                ownerBackColor => 1,
                hiliteBackColor=> cl::Blue,
                hiliteColor    => cl::White,
                min            => 0,
                max            => 100,
                value          => 0,
                threshold      => 0,
                vertical       => 0,
        }
}

sub init
{
        my $self = shift;
        my %profile = $self-> SUPER::init(@_);
        for (qw( relief value indent min max threshold vertical))
        {$self-> {$_} = 0}
        $self-> {string} = '';
        for (qw( vertical threshold min max relief indent value))
        {$self-> $_($profile{$_}); }
        return %profile;
}

sub setup
{
        $_[0]-> SUPER::setup;
        $_[0]-> value($_[0]-> {value});
}

sub on_paint
{
        my ($self,$canvas) = @_;
        my ($x, $y) = $canvas-> size;
        my $i = $self-> indent;
        my ($clComplete,$clBack,$clFore,$clHilite) = ($self-> hiliteBackColor, $self-> backColor, $self-> color, $self-> hiliteColor);
        my $v = $self-> {vertical};
        my $complete = $v ? $y : $x;
        my $range = ($self-> {max} - $self-> {min}) || 1;
        $complete = int(($complete - $i*2) * $self-> {value} / $range + 0.5);
        my ( $l3, $d3) = ( $self-> light3DColor, $self-> dark3DColor);
        $canvas-> color( $clComplete);
        $canvas-> bar ( $v ? ($i, $i, $x-$i-1, $i+$complete) : ( $i, $i, $i + $complete, $y-$i-1));
        $canvas-> color( $clBack);
        $canvas-> bar ( $v ? ($i, $i+$complete+1, $x-$i-1, $y-$i-1) : ( $i+$complete+1, $i, $x-$i-1, $y-$i-1));
        # draw the border
        my $relief = $self-> relief;
        $canvas-> color(( $relief == gr::Sink) ? $d3 : (( $relief == gr::Border) ? cl::Black : $l3));
        for ( my $j = 0; $j < $i; $j++)
        {
                $canvas-> line( $j, $j, $j, $y - $j - 1);
                $canvas-> line( $j, $y - $j - 1, $x - $j - 1, $y - $j - 1);
        }
        $canvas-> color(( $relief == gr::Sink) ? $l3 : (( $relief == gr::Border) ? cl::Black : $d3));
        for ( my $j = 0; $j < $i; $j++)
        {
                $canvas-> line( $j + 1, $j, $x - $j - 1, $j);
                $canvas-> line( $x - $j - 1, $j, $x - $j - 1, $y - $j - 1);
        }

        # draw the text, if neccessary
        my $s = $self-> {string};
        if ( $s ne '')
        {
                my ($fw, $fh) = ( $canvas-> get_text_width( $s), $canvas-> font-> height);
                my $xBeg = int(( $x - $fw) / 2 + 0.5);
                my $xEnd = $xBeg + $fw;
                my $yBeg = int(( $y - $fh) / 2 + 0.5);
                my $yEnd = $yBeg + $fh;
                my ( $zBeg, $zEnd) = $v ? ( $yBeg, $yEnd) : ( $xBeg, $xEnd);
                if ( $zBeg > $i + $complete) {
                        $canvas-> color( $clFore);
                        $canvas-> text_out_bidi( $s, $xBeg, $yBeg);
                } elsif ( $zEnd < $i + $complete + 1) {
                        $canvas-> color( $clHilite);
                        $canvas-> text_out_bidi( $s, $xBeg, $yBeg);
                } else {
                        $canvas-> clipRect( $v ?
                                ( 0, 0, $x, $i + $complete) :
                                ( 0, 0, $i + $complete, $y)
                        );
                        $canvas-> color( $clHilite);
                        $canvas-> text_out_bidi( $s, $xBeg, $yBeg);
                        $canvas-> clipRect( $v ?
                                ( 0, $i + $complete + 1, $x, $y) :
                                ( $i + $complete + 1, 0, $x, $y)
                        );
                        $canvas-> color( $clFore);
                        $canvas-> text_out_bidi( $s, $xBeg, $yBeg);
                }
        }
}

sub set_bounds
{
        my ( $self, $min, $max) = @_;
        $max = $min if $max < $min;
        ( $self-> { min}, $self-> { max}) = ( $min, $max);
        my $oldValue = $self-> {value};
        $self-> value( $max) if $self-> {value} > $max;
        $self-> value( $min) if $self-> {value} < $min;
}

sub value
{
        return $_[0]-> {value} unless $#_;
        my $v = $_[1] < $_[0]-> {min} ? $_[0]-> {min} : ($_[1] > $_[0]-> {max} ? $_[0]-> {max} : $_[1]);
        $v -= $_[0]-> {min};
        my $old = $_[0]-> {value};
        if (abs($old - $v) >= $_[0]-> {threshold}) {
                my ($x, $y) = $_[0]-> size;
                my $i = $_[0]-> {indent};
                my $range = ( $_[0]-> {max} - $_[0]-> {min}) || 1;
                my $x1 = $i + ($x - $i*2) * $old / $range;
                my $x2 = $i + ($x - $i*2) * $v   / $range;
                ($x1, $x2) = ( $x2, $x1) if $x1 > $x2;
                my $s = $_[0]-> {string};
                $_[0]-> {value} = $v;
                $_[0]-> notify(q(Stringify), $v, \$_[0]-> {string});
                ( $_[0]-> {string} eq $s) ?
                        $_[0]-> invalidate_rect( $x1, 0, $x2+1, $y) :
                        $_[0]-> repaint;
        }
}

1;

TEST

test(<<'TEST'); # AGENT/Makefile-DOM-0.008/t/Shell.pm
sub run_test ($) {
    my $block = shift;
    #warn Dumper($block->cmd);

    my $tempdir = tempdir( 'backend_XXXXXX', TMPDIR => 1, CLEANUP => 1 );
    my $saved_cwd = Cwd::cwd;
    chdir $tempdir;

    process_pre($block);

    my $cmd = [ split_arg($SHELL), '-c', $block->cmd() ];
    if ($^O eq 'MSWin32' and $block->stdout and $block->stdout eq qq{\\"\n}) {
        workaround($block, $cmd);
    } else {
        test_shell_command($block, $cmd);
    }

    process_found($block);
    process_not_found($block);
    process_post($block);

    chdir $saved_cwd;
}

sub workaround (@) {
    my ($block, $cmd) = @_;
    my ($error_code, $stdout, $stderr) =
        run_shell( $cmd );
    #warn Dumper($stdout);
    my $stdout2     = $block->stdout;
    my $stderr2     = $block->stderr;
    my $error_code2 = $block->error_code;

    my $name = $block->name;
    SKIP: {
        skip 'Skip the test uncovers quoting issue on Win32', 3
            if 1;
        is ($stdout, $stdout2, "stdout - $name");
        is ($stderr, $stderr2, "stderr - $name");
        is ($error_code, $error_code2, "error_code - $name");
    }
}
TEST

test(<<'TEST'); # BPMEDLEY/Mojolicious-Plugin-SaveRequest-0.04/lib/Mojolicious/Plugin/SaveRequest.pm
    print($handle qq(my \@exec = (
        \@runme,
        "get",
        "-v",
        "-M",
        \$method,
        "-c",
        \$body,
        map({ ("-H", \"\$_:\$headers{\$_}\") } keys \%headers),
        \$url
    );\n));
TEST

test(<<'TEST'); # HIO/Pod-MultiLang-0.14/lib/Pod/MultiLang/Dict/ja.pm
sub make_linktext
{
  my ($pkg,$lang,$name,$section) = @_;
  $name
    ? $section ? qq($name “à "$section") : $name
    : $section ? qq("$section") : undef;
}
TEST

test(<<'TEST'); # KEICHNER/XML-Parsepp-Testgen-0.03/lib/XML/Parsepp/Testgen.pm
                        if ($check_positions) {
                            say {$ofh} q!!;
                            say {$ofh} q!    my $e_line  = -1;!;
                            say {$ofh} q!    my $e_col   = -1;!;
                            say {$ofh} q!    my $e_bytes = -1;!;
                            say {$ofh} q!!;
                            say {$ofh} q!    if ($err =~ m{at \s+ line \s+ (\d+), \s+ column \s+ (\d+), \s+ byte \s+ (\d+) \s+ at \s+}xms)
 {!;
                            say {$ofh} q!        $e_line  = $1;!;
                            say {$ofh} q!        $e_col   = $2;!;
                            say {$ofh} q!        $e_bytes = $3;!;
                            say {$ofh} q!    }!;
                            say {$ofh} q!!;
                            say {$ofh} q!    is($e_line,  !.sprintf('%4d', $rl->{e_line}) .q!, 'Test-!, sprintf('%03d', $tno), q!v1: error
 - lineno');!;
                            say {$ofh} q!    is($e_col,   !.sprintf('%4d', $rl->{e_col})  .q!, 'Test-!, sprintf('%03d', $tno), q!v2: error
 - column');!;
                            say {$ofh} q!    is($e_bytes, !.sprintf('%4d', $rl->{e_bytes}).q!, 'Test-!, sprintf('%03d', $tno), q!v3: error
 - bytes');!;
                            say {$ofh} q!!;
                        }
TEST

test(<<'TEST'); # MBARBON/Devel-Debug-DBGp-0.06/DB/Text/Balanced.pm
    {
        $rdelspec = eval "qq{$rdel}" || do {
            my $del;
            for (qw,~ ! ^ & * ) _ + - = } ] : " ; ' > . ? / | ',)
                { next if $rdel =~ /\Q$_/; $del = $_; last }
            unless ($del) {
                use Carp;
                croak "Can't interpolate right delimiter $rdel"
            }
            eval "qq$del$rdel$del";
        };
    }
TEST

test(<<'TEST'); # ABH/Authen-Bitcard-0.90/lib/Authen/Bitcard.pm
sub _verify {
    my $bc = shift;
    my($msg, $key, $sig) = @_;
    my $u1 = Math::BigInt->new("0b" . unpack("B*", sha1($msg)));
    $sig->{s}->bmodinv($key->{q});
    $u1 = ($u1 * $sig->{s}) % $key->{q};
    $sig->{s} = ($sig->{r} * $sig->{s}) % $key->{q};
    $key->{g}->bmodpow($u1, $key->{p});
    $key->{pub_key}->bmodpow($sig->{s}, $key->{p});
    $u1 = ($key->{g} * $key->{pub_key}) % $key->{p};
    $u1 %= $key->{q};
    $u1 == $sig->{r};
}
TEST

done_testing;
