#!/usr/bin/perl
use strict;
use warnings;
use Data::Dump;
use Term::ReadKey;
use Time::HiRes qw[time];
my $display;
if (eval 'require RPi::UnicornHatHD') {
    $display = RPi::UnicornHatHD->new();
    $display->off;

    #$display->rotation(90);
    $display->brightness(.1);
}
use strict;
use warnings;
$|++;
my $MAX_COLS            = 16;                     # 10 cells wide
my $MAX_ROWS            = 15;                     # 15 cells high
my $level               = 1;
my $score               = 0;
my $playing             = 0;
my $basicUpdateInterval = 1;
my $updateInterval      = $basicUpdateInterval;
my @patterns = ([" * ", "***", "   "],
                ["    ", "****", "    ", "    "],
                ["  *",  "***",  "   "],
                ["*  ",  "***",  "   "],
                [" **",  "** ",  "   "],
                ["** ",  " **",  "   "],
                ["**",   "**"]
);
my @colors = ('#BA55D3', '#8EE5EE', '#FFA500', '#0000FF',
              '#00FF00', '#FF0000', '#FFFF00');
my $nextIndex;
my @currentBlock;
my @currentPattern;
my $currentColor;
my @currentBlockCoors
    ;   # x0, y0, x1, y1; 0 : left up; 1 : right bottom (in terms of the grid)
my @fixedBlock;      # store ref to all blocks which hit ground
my @board;
my @colorInBoard;    # -1:no color, 0:color0, ...

sub update {
    if ($playing) {
        printBoard();
        if (isHitGround()) {
            rmbColor();

            # reset some data
            foreach my $block (@currentBlock) {
                push(@fixedBlock, $block);
            }
            @currentBlock = ();
            clearRows();
            if (isHitSky()) {
                gameover();
            }    # gameover when hitting both ground and sky
            else {
                createTile();
                createNextTile();
            }
        }
        moveDown();

        #update();
        #$updateTimer = $wBase->after($updateInterval, \&update);
    }
}

sub start {
    if (!$playing) {
        $level          = 1;
        $score          = 0;
        $updateInterval = $basicUpdateInterval;
        createNextTile();
        createTile();

        #$wBase->after($updateInterval, \&update);
        warn $updateInterval;

        #sleep $updateInterval;
        update();
        $playing = 1;
    }
}

sub rmbColor {
    my $colorIndex;
    for my $i (0 .. scalar(@colors) - 1) {
        if ($colors[$i] eq $currentColor) { $colorIndex = $i; }
    }
    my $xOffset = $currentBlockCoors[0];
    my $yOffset = $currentBlockCoors[1];
    for my $i (0 .. scalar(@currentPattern) - 1) {
        my @line = split(//, $currentPattern[$i]);
        for my $j (0 .. scalar(@line) - 1) {
            if ($line[$j] eq "*") {
                ${$colorInBoard[$yOffset + $i]}[$xOffset + $j] = $colorIndex;
            }
        }
    }
}

sub clearRow {

    #$wBase->after(200);
    my $delRow = $_[0];

    # delete the row first
    for my $i (0 .. $MAX_COLS - 1) {
        ${$board[$delRow]}[$i]        = 0;
        ${$colorInBoard[$delRow]}[$i] = -1;
    }

    # move the tiles one unit below
    for my $col (0 .. $MAX_COLS - 1) {
        for my $row (1 .. $delRow) {
            my $adjustedRow = $row = $delRow - $row;
            ${$board[$adjustedRow + 1]}[$col]
                = ${$board[$adjustedRow]}[$col];    # move the data
            ${$colorInBoard[$adjustedRow + 1]}[$col]
                = ${$colorInBoard[$adjustedRow]}[$col];    # move the data
        }
    }
    @fixedBlock = ();
    for my $row (0 .. $MAX_ROWS - 1) {
        for my $col (0 .. $MAX_COLS - 1) {
            if (${$board[$row]}[$col]) {
                my $color = $colors[${$colorInBoard[$row]}[$col]];
            }
        }
    }
}

sub isFullRow {
    my $count = 0;
    for my $col (0 .. $MAX_COLS - 1) {
        if (${$board[$_[0]]}[$col]) { $count++; }
    }
    if   ($count == $MAX_COLS) { return 1; }
    else                       { return 0; }
}

sub clearRows {
    my $count = 0;
    for my $row (0 .. $MAX_ROWS - 1) {
        if (isFullRow($row)) { clearRow($row); $count++; }
    }
    if ($count != 0) { calculateScore($count); }
}

sub calculateScore {
    my $count = $_[0];
    if ($count == 1) { $score += (100 * $level); }
    else {
        if ($count == 2) { $score += (300 * $level); }
        else {
            if ($count == 3) { $score += (600 * $level); }
            else {
                if ($count == 4) { $score += (1000 * $level); }
            }
        }
    }
    warn 'Score: ' . $score;
    adjustDifficulty();
}

sub adjustDifficulty {
    my $minus = 50;
    my @interval = (1000, 2500, 5000, 9000, 15000, 30000);
    if ($updateInterval > 200) {
        for my $i (1 .. scalar(@interval)) {
            my $k = scalar(@interval) - $i;    # $k = len-1, len-2, ..., 1, 0
            if ($score >= $interval[$k]) {
                $updateInterval = $basicUpdateInterval - $minus * ($k + 1);
                $level = $k + 2;
                warn 'Level: ' . $level;
                last;
            }
        }
    }
}

sub isHitSky {
    if   ($currentBlockCoors[1] == 0) { return 1; }
    else                              { return 0; }
}

sub isHitGround {
    my $botMostY = $currentBlockCoors[3];
    for my $i (1 .. scalar(@currentPattern)) {
        my $k        = scalar(@currentPattern) - $i;
        my @line     = split(//, $currentPattern[$k]);
        my $emptyCol = 1;
        for my $j (0 .. scalar(@line) - 1) {
            if ($line[$j] eq "*") { $emptyCol = 0; last; }
        }
        if (!$emptyCol) { last; }
        $botMostY--;
    }
    if ($botMostY == $MAX_ROWS - 1) { return 1; }
    else {
        for my $i (0 .. length($currentPattern[0]) - 1) {
            for my $j (1 .. scalar(@currentPattern)) {
                my $k       = scalar(@currentPattern) - $j;
                my $line    = $currentPattern[$k];
                my @line    = split(//, $line);
                my $xOffset = $currentBlockCoors[0];
                my $yOffset = $currentBlockCoors[1];
                if ($line[$i] eq "*") {
                    if (${$board[$k + $yOffset + 1]}[$i + $xOffset]) {
                        return 1;
                    }
                    last;
                }
            }
        }
        return 0;
    }
}

sub gameover {

    #Win32::Sound::Stop();
    #$wBase->afterCancel($updateTimer);
    $playing = 0;
    print "gameover! Score: $score\n";
    exit;
}

sub moveRight {
    my $rightMostX = $currentBlockCoors[2];
    for my $i (1 .. length($currentPattern[0])) {
        my $k        = length($currentPattern[0]) - $i;
        my $emptyCol = 1;
        for my $j (0 .. scalar(@currentPattern) - 1) {
            my @line = split(//, $currentPattern[$j]);
            if ($line[$k] eq "*") { $emptyCol = 0; last; }
        }
        if (!$emptyCol) { last; }
        $rightMostX--;
    }
    if ($rightMostX < $MAX_COLS - 1) {
        for my $i (0 .. scalar(@currentPattern) - 1) {
            my $line    = $currentPattern[$i];
            my @line    = split(//, $line);
            my $xOffset = $currentBlockCoors[0];
            my $yOffset = $currentBlockCoors[1];
            for my $j (0 .. length($line) - 1) {
                my $k = length($line) - 1 - $j;
                if ($line[$k] eq "*") {
                    if (${$board[$i + $yOffset]}[$xOffset + $k + 1]) {
                        return;
                    }    # if a cell's right is filled, return with doing nth
                    last;
                }
            }
        }

        # change @board data to 0
        for my $i (0 .. scalar(@currentPattern) - 1) {
            my $line    = $currentPattern[$i];
            my @line    = split(//, $line);
            my $xOffset = $currentBlockCoors[0];
            my $yOffset = $currentBlockCoors[1];
            for my $j (0 .. length($line) - 1) {
                if ($line[$j] eq "*") {
                    ${$board[$i + $yOffset]}[$xOffset + $j] = 0;
                }
            }
        }

        # move the tile
        #        foreach my $unit (@currentBlock) {
        #            $wGame->move($unit, $TILE_SIZE, 0);
        #        }
        $currentBlockCoors[0] += 1;
        $currentBlockCoors[2] += 1;

        # change @board data to 1
        for my $i (0 .. scalar(@currentPattern) - 1) {
            my $line    = $currentPattern[$i];
            my @line    = split(//, $line);
            my $xOffset = $currentBlockCoors[0];
            my $yOffset = $currentBlockCoors[1];
            for my $j (0 .. length($line) - 1) {
                if ($line[$j] eq "*") {
                    ${$board[$i + $yOffset]}[$xOffset + $j] = $currentColor;
                }
            }
        }
    }
}

sub moveLeft {
    my $leftMostX = $currentBlockCoors[0];
    for my $i (0 .. length($currentPattern[0]) - 1) {
        my $emptyCol = 1;
        for my $j (0 .. scalar(@currentPattern) - 1) {
            my @line = split(//, $currentPattern[$j]);
            if ($line[$i] eq "*") { $emptyCol = 0; last; }
        }
        if (!$emptyCol) { last; }
        $leftMostX++;
    }
    if ($leftMostX > 0) {
        for my $i (0 .. scalar(@currentPattern) - 1) {
            my $line    = $currentPattern[$i];
            my @line    = split(//, $line);
            my $xOffset = $currentBlockCoors[0];
            my $yOffset = $currentBlockCoors[1];
            for my $j (0 .. length($line) - 1) {
                if ($line[$j] eq "*") {
                    if (${$board[$i + $yOffset]}[$xOffset + $j - 1]) {
                        return;
                    }    # if a cell's left is filled, return with doing nth
                    last;
                }
            }
        }

        # change @board data to 0
        for my $i (0 .. scalar(@currentPattern) - 1) {
            my $line    = $currentPattern[$i];
            my @line    = split(//, $line);
            my $xOffset = $currentBlockCoors[0];
            my $yOffset = $currentBlockCoors[1];
            for my $j (0 .. length($line) - 1) {
                if ($line[$j] eq "*") {
                    ${$board[$i + $yOffset]}[$xOffset + $j] = 0;
                }
            }
        }

        #        foreach my $unit (@currentBlock) {
        #            $wGame->move($unit, -$TILE_SIZE, 0);
        #        }
        $currentBlockCoors[0] -= 1;
        $currentBlockCoors[2] -= 1;

        # change @board data to 1
        for my $i (0 .. scalar(@currentPattern) - 1) {
            my $line    = $currentPattern[$i];
            my @line    = split(//, $line);
            my $xOffset = $currentBlockCoors[0];
            my $yOffset = $currentBlockCoors[1];
            for my $j (0 .. length($line) - 1) {
                if ($line[$j] eq "*") {
                    ${$board[$i + $yOffset]}[$xOffset + $j] = $currentColor;
                }
            }
        }
    }
}

sub moveDown {
    my $botMostY = $currentBlockCoors[3];
    for my $i (1 .. scalar(@currentPattern)) {
        my $k        = scalar(@currentPattern) - $i;
        my @line     = split(//, $currentPattern[$k]);
        my $emptyCol = 1;
        for my $j (0 .. scalar(@line) - 1) {
            if ($line[$j] eq "*") { $emptyCol = 0; last; }
        }
        if (!$emptyCol) { last; }
        $botMostY--;
    }
    if ($botMostY < $MAX_ROWS - 1) {
        for my $i (0 .. length($currentPattern[0]) - 1) {
            for my $j (1 .. scalar(@currentPattern)) {
                my $k       = scalar(@currentPattern) - $j;
                my $line    = $currentPattern[$k];
                my @line    = split(//, $line);
                my $xOffset = $currentBlockCoors[0];
                my $yOffset = $currentBlockCoors[1];
                if ($line[$i] eq "*") {
                    if (${$board[$k + $yOffset + 1]}[$i + $xOffset]) {
                        return;
                    }
                    last;
                }
            }
        }

        # change @board data to 0
        for my $i (0 .. scalar(@currentPattern) - 1) {
            my $line    = $currentPattern[$i];
            my @line    = split(//, $line);
            my $xOffset = $currentBlockCoors[0];
            my $yOffset = $currentBlockCoors[1];
            for my $j (0 .. length($line) - 1) {
                if ($line[$j] eq "*") {
                    ${$board[$i + $yOffset]}[$xOffset + $j] = 0;
                }
            }
        }

        #        foreach my $unit (@currentBlock) {
        #            $wGame->move($unit, 0, $TILE_SIZE);
        #        }
        $currentBlockCoors[1] += 1;
        $currentBlockCoors[3] += 1;

        # change @board data to 1
        for my $i (0 .. scalar(@currentPattern) - 1) {
            my $line    = $currentPattern[$i];
            my @line    = split(//, $line);
            my $xOffset = $currentBlockCoors[0];
            my $yOffset = $currentBlockCoors[1];
            for my $j (0 .. length($line) - 1) {
                if ($line[$j] eq "*") {
                    ${$board[$i + $yOffset]}[$xOffset + $j] = $currentColor;
                }
            }
        }
    }
}

sub fallDown {
    for my $i (1 .. $MAX_ROWS) {
        moveDown();
    }
}

sub rotate {

    #print "pressed up arrow \n";
    my @currentPatternArray;
    my @newPatternArray;
    my @newPattern;
    for my $i (0 .. scalar(@currentPattern) - 1)
    {    # translate pattern into array
        my $line = $currentPattern[$i];
        my @line = split(//, $line);
        for my $j (0 .. length($line) - 1) {
            if ($line[$j] eq "*") {
                $currentPatternArray[$i][$j] = $currentColor;
            }
            else {
                $currentPatternArray[$i][$j] = 0;
            }
        }
    }
    for my $i (0 .. scalar(@currentPattern) - 1) {    # rotate the array
        for my $j (0 .. scalar(@currentPattern) - 1) {
            $newPatternArray[$i][$j]
                = $currentPatternArray[scalar(@currentPattern) - 1 - $j][$i];
        }
    }
    for my $i (0 .. scalar(@currentPattern) - 1)
    {    # translate new array into pattern
        my $patternString;
        for my $j (0 .. scalar(@currentPattern) - 1) {
            if ($newPatternArray[$i][$j]) {
                $patternString = $patternString . "*";
            }
            else {
                $patternString = $patternString . " ";
            }
            @newPattern[$i] = $patternString;
        }
    }
    my @tempCoorsArray;

    # change @board data to 0
    for my $i (0 .. scalar(@currentPattern) - 1) {
        my $line    = $currentPattern[$i];
        my @line    = split(//, $line);
        my $xOffset = $currentBlockCoors[0];
        my $yOffset = $currentBlockCoors[1];
        for my $j (0 .. length($line) - 1) {
            if ($line[$j] eq "*") {
                my $coor = ($i + $yOffset) * 100 + $xOffset + $j;
                push(@tempCoorsArray, $coor);
                ${$board[$i + $yOffset]}[$xOffset + $j] = 0;
            }
        }
    }
    my $displacement = 0;    # -1:left, 0:stay, 1:right

    # check if there is collision
    for my $i (0 .. scalar(@newPattern) - 1) {
        my $line    = $newPattern[$i];
        my @line    = split(//, $line);
        my $xOffset = $currentBlockCoors[0];
        my $yOffset = $currentBlockCoors[1];
        for my $j (0 .. length($line) - 1) {
            if ($line[$j] eq "*") {
                if ((${$board[$i + $yOffset]}[$xOffset + $j])    # collision
                    || ($i + $yOffset < 0 || $i + $yOffset > $MAX_ROWS - 1))
                {    # out of range (in terms of y coor)
                        # restore original state
                    foreach my $coor (@tempCoorsArray) {
                        use integer;
                        my $row = $coor / 100;
                        my $col = $coor - $row * 100;
                        ${$board[$row]}[$col] = $currentColor;
                    }
                    return;
                }
                else {
                    if ($xOffset + $j < 0 || $xOffset + $j > $MAX_COLS - 1)
                    {    # out of range (in terms of x-coor)
                        if ($xOffset + $j < 0) {
                            $displacement += 1;
                        }    # crash left boundary -> move right one cell
                        else {
                            $displacement -= 1;
                        }    # crash right boundary -> move left one cell
                    }
                }
            }
        }
    }
    if ($displacement != 0) {    # not 0 -> need to displace
        if ($currentColor eq $colors[2])
        {    # lazy, only this is exception to the above counting method
            if   ($displacement > 0) { $displacement = 1; }
            else                     { $displacement = -1; }
        }
        $currentBlockCoors[0] += $displacement;
        $currentBlockCoors[2] += $displacement;
    }
    @currentPattern = @newPattern;

    # create the tile
    for my $i (0 .. scalar(@currentPattern) - 1) {
        my $line    = $currentPattern[$i];
        my @line    = split(//, $line);
        my $xOffset = $currentBlockCoors[0];
        my $yOffset = $currentBlockCoors[1];
        for my $j (0 .. scalar(@line) - 1) {
            my $char = $line[$j];
            if ($char eq "*") {
            }
        }
    }

    # change @board data to 1
    for my $i (0 .. scalar(@currentPattern) - 1) {
        my $line    = $currentPattern[$i];
        my @line    = split(//, $line);
        my $xOffset = $currentBlockCoors[0];
        my $yOffset = $currentBlockCoors[1];
        for my $j (0 .. length($line) - 1) {
            if ($line[$j] eq "*") {
                ${$board[$i + $yOffset]}[$xOffset + $j] = $currentColor;
            }
        }
    }
}

sub printBoard {
    use Data::Dump;

    #ddx \@board;
    return if !$display;

    #    $display->clear;
    $display->set_all('#0F0f0f');
    for my $row (0 .. $#board) {
        for my $col (0 .. $#{$board[$row]}) {
            my $value = $board[$row][$col];

            # warn sprintf '%d x %d = %s', $col, $row, $value // '';
            $display->set_pixel($row, $col, $value ? $value : '#0f0f0f')
                if defined $value;
        }
    }
    $display->show;
    return;
    foreach my $row (@board) {
        foreach my $cell (@$row) {
            if   ($cell) { print "* "; }
            else         { print "  "; }
        }
        print "\n";
    }
}

sub createNextTile {
    $nextIndex = int(rand(scalar(@patterns)));
}

sub createTile {
    my $randomIndex = $nextIndex;
    my $color       = $colors[$randomIndex];
    $currentColor = $color;
    my $pattern = $patterns[$randomIndex];
    my $xOffset, my $height = scalar(@$pattern), my $width;
    @currentBlock = ();
    for my $i (0 .. scalar(@$pattern) - 1) {
        my $line = @$pattern[$i];
        my @line = split(//, $line);
        $xOffset = int(($MAX_COLS - length($line)) / 2);
        $width   = scalar(@line);
        for my $j (0 .. scalar(@line) - 1) {
            my $char = $line[$j];
            if ($char eq "*") {
                ${$board[$i]}[$j + $xOffset] = $color;
            }
        }
    }
    @currentPattern = @$pattern;
    @currentBlockCoors = ($xOffset, 0, $width + $xOffset - 1, $height - 1);
}

sub clearBoard {
    for my $i (0 .. $MAX_ROWS - 1) {
        for my $j (0 .. $MAX_COLS - 1) {
            $board[$i][$j]        = 0;
            $colorInBoard[$i][$j] = -1;
        }
    }
}

#sub init {
#    createScreen();
#    drawLines();
#    clearBoard();
#}
#init();
start();

#sleep $updateInterval &&
ReadMode('cbreak');
END { ReadMode('restore'); $display->off }
while (1) {
    while (1) {
        my $time = time;
        my $key  = ReadKey($updateInterval);
        if (defined $key) {
            warn ord $key;
            if (ord $key == 27) {
                ReadKey(); # Clear it!
                my $direction = ReadKey(0);
                warn ord $direction;
                if (ord $direction == 65) {
                    rotate();
                }
                elsif (ord $direction == 66) {
                    fallDown();
                }
                elsif (ord $direction == 67) {
                    moveRight();
                }
                elsif (ord $direction == 68) {
                    moveLeft();
                }
                else {
                    warn 'Unknown key: '
                        . $direction . ' | '
                        . ord $direction;
                }
                printBoard();
            }
        }
        warn(time - $time);
        sleep(time - $time);
        update();
    }
}
