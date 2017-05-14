require 5.001;

package Pilot;

$pilot_key  = "Software\\U.S. Robotics\\Pilot Desktop\\";
$EMPTY_DATE = 0x749ea1ef;

sub new {
    my $self = { };
    $self->{"Path"} = $_[1];
    bless $self;
    return $self;
}

sub add_value {
    my ($area, $key, $name, $value) = @_;
    my ($hkey, %values);

    $area->Open($pilot_key . $key, $hkey) || die $!;
    $hkey->SetValueEx($name, 0, REG_DWORD, $value);
}

sub copy_file {
    my ($src, $dest) = @_;
    open(SRC, $src) || die;
    open(DEST, "> $dest") || die;
    print DEST <SRC>;
    close DEST;
    close SRC;
}

sub DateText {
    my ($long, $sec, $min, $hour, $mday, $mon, $year) = @_;

    if ($long) {
        return sprintf("%02d/%02d/%02d %02d:%02d:%02d", $mon + 1, $mday,
                       $year, $hour, $min, $sec);
    } else {
        return sprintf("%02d/%02d", $mon + 1, $mday);
    }
    return "";
}

sub DateString {
    my ($date, $long) = @_;

    if ($date && $date != $EMPTY_DATE) {
        return DateText($long, localtime $date);
    }
    return "";
}

sub LastSync {
    my ($self) = @_;

    open(FILE, $self->{"Path"} . "\\HotSync.Log") || return 0;

    my $d = "[0-9]{2}";
    while (<FILE>) {
        if (/^HotSync started ($d)\/($d)\/($d) ($d):($d):($d)/o) {
            return ($6, $5, $4, $2, $1 - 1, $3);
        }
    }
    close FILE;
    return 0;
}

sub Install {
    my ($self, $file) = @_;

    add_value($HKEY_CURRENT_USER, "HotSync Manager", "Install5550", "1");

    my $base = $file;
    $base =~ s,/,\\,g;
    $base =~ s,.*\\,,;

    copy_file($file, $self->{"Path"} . "\\Install\\" . $base);
}

1;
