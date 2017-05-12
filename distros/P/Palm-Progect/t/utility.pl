
use strict;

# Utility routines for test scripts

# Convert text file to native textfile

sub convert_textfile {
   my ($sourcefile, $targetfile) = @_;
   local (*SOURCE, *TARGET, $_);
   local $/ = $/;

   binmode SOURCE;

   open SOURCE, $sourcefile or die "Can't read $sourcefile: $!\n";
   open TARGET, ">$targetfile" or die "Can't clobber $targetfile: $!\n";

   my @mismatches;
   my ($source, $target);
   while (<SOURCE>) {
       $/ = "\r";    chomp;  # Mac
       $/ = "\r\n";  chomp;  # PC
       $/ = "\n";    chomp;  # Unix

       print TARGET;
       print TARGET "\n";
   }

   close SOURCE;
   close TARGET;

}



# Compare two files, ignoring line endings

sub compare_text_files {
    my ($sourcefile, $targetfile, $sensitive_to_comments) = @_;

    local (*FH, $_);
    local $/ = $/;

    my (@sourcelines, @targetlines, @mismatches);

    open FH, $sourcefile or die "Can't read $sourcefile: $!\n";
    while (<FH>) {
        $/ = "\r";    chomp; # Mac
        $/ = "\r\n";  chomp; # PC
        $/ = "\n";    chomp; # Unix
        next unless /\S/;
        next if /^\s*#/ and !$sensitive_to_comments;
        push @sourcelines, $_;
    }
    close FH;

    open FH, $targetfile or die "Can't read $targetfile: $!\n";
    while (<FH>) {
        $/ = "\r";    chomp; # Mac
        $/ = "\r\n";  chomp; # PC
        $/ = "\n";    chomp; # Unix
        next unless /\S/;
        next if /^\s*#/ and !$sensitive_to_comments;
        push @targetlines, $_;
    }
    close FH;

    for (my $i = 0; $i < @sourcelines; $i++) {
        my $source = $sourcelines[$i] || '';
        my $target = $targetlines[$i] || '';
        push @mismatches, "\n\tSource: ($source)\n\tTarget: ($target)" if $source ne $target;
    }
    if (@mismatches) {
        warn "line mismatch: $_\n" foreach @mismatches;
        print "line mismatch: $_\n" foreach @mismatches;
        return;
    }
    if (@sourcelines != @targetlines) {
        warn "different number of lines in $sourcefile and $targetfile\n";
        return;
    }
    return 1;

}

sub compare_csv_files {
    my ($sourcefile, $targetfile, $eol) = @_;

    require Text::CSV_XS;
    require IO::File;

    local ($_);

    my $csv = Text::CSV_XS->new({
        eol        => $eol,
        binary     => 1,
    });

    my (@sourcelines, @targetlines, @mismatches);

    my $fh = new IO::File;
    $fh->open("< $sourcefile") or die "Can't open $sourcefile for reading: $!\n";
    while (my $fields = $csv->getline($fh)) {
        last if !@$fields;
        push @sourcelines, join( '|', @$fields);
    }
    $fh->close;

    $fh = new IO::File;
    $fh->open("< $targetfile") or die "Can't open $targetfile for reading: $!\n";
    while (my $fields = $csv->getline($fh)) {
        last if !@$fields;
        push @targetlines, join('|', @$fields);
    }
    $fh->close;

    for (my $i = 0; $i < @sourcelines; $i++) {
        my $source = $sourcelines[$i];
        my $target = $targetlines[$i];
        push @mismatches, "\n\tSource: ($source)\n\tTarget: ($target)" if $source ne $target;
    }
    if (@mismatches) {
        warn "line mismatch: $_\n" foreach @mismatches;
        return;
    }
    if (@sourcelines != @targetlines) {
        warn "different number of lines in $sourcefile and $targetfile\n";
        return;
    }
    return 1;

}

# To avoid line ending problems, we will write out our sample platform line
# by line, using the line terminator appropriate for this platform.
my @Text_Lines = (
    '# Sample progect tree, covers most of the bases :)',
    '',
    '[80%] [5] {One} alpha-Priority 5, progress 80%, cat one <<',
    '    Note for alpha',
    '    >>',
    '',
    '[5/20] [1] {Two} Beta-priority 1,num 5/20,cat two',
    '    [x] (15/07/2001) Bc1-no pri, action, date 15jun2001,no cat',
    '    . [2] {One} Bc2-pri2,info,nodate,cat one,note <<',
    '        Bc2 note',
    '        Bc2 note-line2',
    '        >>',
    '',
    '<x> [1] (22/07/2001) {Three} Gamma, pri1,action,todo link,date 22jul2001,cat three,note,complete,closed <<',
    '    Gamma note',
    '    Gamma note -line 2',
    '    >>',
    '    <x> (01/08/2001) Gc1-action,todo link,1aug2001, complete',
    '',
    '[ ] (15/07/2001) Delta,action,not complete',
    '. (15/01/2002) item with January date',
);

my @Text_Lines_With_Comments_In_Notes = (
    '[80%] [5] {One} alpha-Priority 5, progress 80%, cat one <<',
    '    # Note for alpha',
    '    >>',
    '',
    '[5/20] [1] {Two} Beta-priority 1,num 5/20,cat two',
    '    [x] [1] (15/07/2001) Bc1-no pri, action, date 15jun2001,no cat',
    '    . [2] {One} Bc2-pri2,info,nodate,cat one,note <<',
    '        Bc2 note',
    '        Bc2 note-line2',
    '        >>',
    '',
    '<x> [1] (22/07/2001) {Three} Gamma, pri1,action,todo link,date 22jul2001,cat three,note,complete,closed <<',
    '    Gamma note',
    '    Gamma note -line 2',
    '    # Gamma note -line 3 - starting with comment char',
    '    >>',
    '    <x> (01/08/2001) Gc1-action,todo link,1aug2001, complete',
    '',
    '[ ] (15/07/2001) Delta,action,not complete',
    '. (15/01/2002) item with January date',
);

sub write_sample_txt {
    my $filename               = shift;
    my $with_comments_in_notes = shift;

    my @lines = $with_comments_in_notes?
                @Text_Lines_With_Comments_In_Notes :
                @Text_Lines;

    local *FH;
    open FH, ">$filename" or die "Can't clobber $filename: $!\n";
    print FH "$_\n" foreach @lines;
    close FH;
}

sub write_sample_txt_with_tabs {
    my $filename = shift;
    my @lines = @Text_Lines;

    foreach my $line (@lines) {
        $line =~ s/    /\t/g;
    }

    local *FH;
    open FH, ">$filename" or die "Can't clobber $filename: $!\n";
    print FH "$_\n" foreach @lines;
    close FH;
}


sub write_sample_csv {
    my $filename = shift;
    my @lines = (
        qq{level,priority,completed,isAction,isProgress,isNumeric,isInfo,hasToDo,numericActual,numericLimit,dateDue,category,opened,description,note,todo_link_data},
        qq{1,5,80,,1,,,,,,,One,,"alpha-Priority 5, progress 80%, cat one","Note for alpha",},
        qq{1,1,0,,,1,,,5,20,,Two,,"Beta-priority 1,num 5/20,cat two",,},
        qq{2,,1,1,,,,,,,15/07/2001,,,"Bc1-no pri, action, date 15jun2001,no cat",,},
        qq{2,2,,,,,1,,,,,One,,"Bc2-pri2,info,nodate,cat one,note","Bc2 note\nBc2 note-line2",},
        qq{1,1,1,1,,,,1,,,22/07/2001,Three,,"Gamma, pri1,action,todo link,date 22jul2001,cat three,note,complete,closed","Gamma note\nGamma note -line 2",},
        qq{2,,1,1,,,,1,,,01/08/2001,,,"Gc1-action,todo link,1aug2001, complete",,},
        qq{1,,0,1,,,,,,,15/07/2001,,,"Delta,action,not complete",,},
        qq{1,,,,,,1,,,,15/01/2002,,,"item with January date",,},
    );

    local *FH;
    open FH, ">$filename" or die "Can't clobber $filename: $!\n";
    print FH "$_\r\n" foreach @lines;
    close FH;
}

1;

__END__


# This is the original sample.txt
# Sample progect tree, covers most of the bases :)

[80%] {One} alpha-Priority 5, progress 80%, cat one <<
    Note for alpha
    >>

[5/20] {Two} Beta-priority 1,num 5/20,cat two
    [x] (15/07/2001) Bc1-no pri, action, date 15jun2001,no cat
    . {One} Bc2-pri2,info,nodate,cat one,note <<
        Bc2 note
        Bc2 note-line2
        >>

<x> (22/07/2001) {Three} Gamma, pri1,action,todo link,date 22jul2001,cat three,note,complete,closed <<
    Gamma note
    Gamma note -line 2
    # Gamma note -line 3 - starting with comment char
    >>
    <x> (01/08/2001) Gc1-action,todo link,1aug2001, complete

[ ] (15/07/2001) Delta,action,not complete


