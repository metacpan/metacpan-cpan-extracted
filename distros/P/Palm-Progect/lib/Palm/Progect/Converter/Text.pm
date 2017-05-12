
use strict;
package Palm::Progect::Converter::Text;

=head1 NAME

Palm::Progect::Converter::Text - Convert between Progect databases and Text files

=head1 SYNOPSIS

    my $converter = Palm::Progect::Converter->new(
        format => 'Text',
        # ... other args ...
    );

    $converter->load_records();

    # ... do stuff with records

    $converter->save_records();

=head1 DESCRIPTION

This converts between Text files and C<Palm::Progect> records and preferences.

The Text format used for import/export looks something like this:

    [x] Level 1 Todo item
        [10%] Child (progress)
            . Child of Child (informational)

    [80%] (31/12/2001) Progress item
        [ ] Unticked action item


Here is a summary of the various types of records:

    [ ] action type
    [x] completed action type
    < > action type with todo link
    <x> completed action type with todo link

    [80%] progress type
    [4/5] numeric type

    . info type

    [ ] [5] action type with priority
    [ ] (15/7/2001) action type with date

    [80%] [5] (15/7/2001) {category} progress type with priority and date and category

    [80%] [5] (15/7/2001) {category} progress type with priority and date and category <<
        Multi-Line note
        for this item
        >>

=head1 OPTIONS

These options can be passed to the C<Palm::Progect::Converter> constructor,
for instance:

    my $converter = Palm::Progect::Converter->new(
        format    => 'Text',
        tabstop   => 4,
    );


=over 4

=item tabstop

Treat tabs as n spaces wide (default is 8)

=item fill_with_spaces

Use spaces to indent instead of tabs

=item date_format

The format for dates:  Any combination of dd, mm, yy, yyyy (default is dd/mm/yy).

Any dates that are printed will use this format. Dates that are parsed will
be expected to be in this format.

=item columns

Wrap text to fit on n columns

=back

=cut

use Text::Wrap;
use Text::Tabs qw();

# A hack to disable tab insertion by Text::Wrap
sub dummy { return @_ if wantarray; return $_[0]; }
*Text::Tabs::expand   = *dummy;
*Text::Tabs::unexpand = *dummy;
*Text::Wrap::expand   = *dummy;
*Text::Wrap::unexpand = *dummy;

use Palm::Progect::Constants;
use Palm::Progect::Date;

use CLASS;
use base qw(Class::Accessor Class::Constructor);

use base 'Palm::Progect::Converter';

################################################################################
# Class methods for providing info on options

sub provides_import     { 1 }
sub provides_export     { 1 }
sub accepted_extensions { 'txt' }

sub options_spec {
    return {
        tabstop          => [ 'tabstop=i',     8,            '  --tabstop=n        Treat tabs as n spaces wide (default is 8)'                 ],
        fill_with_spaces => [ 'use-spaces',    '',           '  --use-spaces       Use spaces to indent instead of tabs'                       ],
        date_format      => [ 'date-format=s', 'yyyy/mm/dd', '  --date-format=s    Any combination of dd, mm, yy, yyyy (default is dd/mm/yy)'  ],
        columns          => [ 'columns',       80,           '  --columns=n        Wrap text to fit on n columns (defaults to 80)'             ],
    };
}

my @Accessors = qw(
    tabstop
    date_format
    columns
    fill_with_spaces
);

CLASS->mk_accessors(@Accessors);
CLASS->mk_constructor(
    Auto_Init => \@Accessors,
);

=head1 METHODS

=over 4

=item load_records($file, $append)

Load Text records from C<$file>, translating them into the
internal C<Palm::Progect::Record> format.

If C<$append> is true then C<load_records> will B<append> the records
imported from C<$file> to the internal records list.  If false,
C<load_records> will B<replace> the internal records list with the
records imported from C<$file>.

=cut

sub load_records {
    my ($self, $filename, $append) = @_;
    local (*FH, $_);

    print STDERR "Loading Text format from $filename\n" unless $self->quiet;

    open FH, $filename or die "Can't open $filename for reading: $!\n";

    my $multiline_desc_mode = 0;
    my $multiline_note_mode = 0;
    my $record = new Palm::Progect::Record;

    my @records;

    my (@description_lines, @note_lines);
    while (<FH>) {
        chomp;
        next unless /\S/;
        # next if /^\s*#/;

        if ($multiline_desc_mode) {
            if (/^(\s*)(.*)>>/) {

                # End of description.  Trim the whitespace
                # from the start of each line, and pack
                # them all up.

                my $whitespace = $1;
                my $desc_line  = $2;

                if ($desc_line) {
                    push @description_lines, $desc_line;
                }

                if ($whitespace) {
                    @description_lines = _trim_lines($whitespace, $self->tabstop, @description_lines);
                }

                # Append here, because we might have already stashed the
                # first line of the description

                $record->description($record->description . join "\n", @description_lines);
                @description_lines = ();

                $multiline_desc_mode = 0;

                if (/>>\s*<<(.*)/) {
                    push @note_lines, $1;
                    $multiline_note_mode = 1;
                }
                else {
                    # End of Record - pack it up!
                    push @records, $record;
                    $record = new Palm::Progect::Record;
                }
            }
            else {
                push @description_lines, $_;
            }

        }
        elsif ($multiline_note_mode) {
            if (/^(\s*)(.*)>>/) {

                # End of note.  Trim the whitespace
                # from the start of each line, and pack
                # them all up.

                my $whitespace = $1;
                my $note_line  = $2;

                if ($note_line) {
                    push @note_lines, $note_line;
                }

                if ($whitespace) {
                    @note_lines = _trim_lines($whitespace, $self->tabstop, @note_lines);
                }

                $record->note(join "\n", @note_lines);
                @note_lines      = ();

                $multiline_note_mode = 0;

                # End of Record - pack it up!
                push @records, $record;
                $record = new Palm::Progect::Record;
            }
            else {
                push @note_lines, $_;
            }
        }
        elsif (m~^
              (\s*)                # Optional Whitespace - save it to calc level
              (
              (?:\[.*?\])|         # bracketed sequence  - e.g. [], [x], [80%] or [4/5]
              (?:\<.*?\>)|         # or todo brackets    - e.g. < >, <x>
              (?:\.)               # or dot for info     - e.g. . some info
              )
              \s*
              (?:\[\s*(\d)\s*\])?  # optional priority in square brackets
              \s*
              (?:\s*\((.*?)\s*\))? # paren sequence      - e.g. (1/2/2001)
              \s*
              (?:\s*\{(.*?)\}\s*)? # braced sequence     - e.g. {My Category}
              \s*
              (<<)?                # optional start of multiline description
              \s*
              (.*?)                # description text
              \s*
              (<<\s*(.*))?         # optional start of multiline note
              \s*
            $~x           ) {

            my ($whitespace, $type_info, $priority, $date, $category,
                $multi_desc_start, $description, $multi_note_start, $note)
                = ($1, $2, $3, $4, $5, $6, $7, $8);

            if ($category) {
                $record->category_name($category);
            }

            if ($type_info) {

                if ($type_info =~ /^\.$/) {
                    $record->type(RECORD_TYPE_INFO);
                }
                else {
                    $record->type(RECORD_TYPE_ACTION);
                    $record->completed(0);

                    # Strip brackets
                    if ($type_info =~ /^
                                       \s*
                                       (\[|\<)   # Open bracket: [ or <
                                       \s*
                                       (.*?)
                                       \s*
                                       (?:\]|\>) # close bracket: ] or >
                                       \s*
                                       $/x) {

                        my $bracket_type = $1;
                        my $contents     = $2;

                        if (!$contents) {
                            $record->type(RECORD_TYPE_ACTION);
                            $record->completed(0);
                        }
                        elsif ($contents =~ /^x$/i) {
                            $record->type(RECORD_TYPE_ACTION);
                            $record->completed(1);
                        }
                        elsif ($contents =~ /^(\d+)%$/) {
                            $record->type(RECORD_TYPE_PROGRESS);
                            $record->completed($1);
                        }
                        elsif ($contents =~ m{^(\d+)/(\d+)$}) {
                            $record->type(RECORD_TYPE_NUMERIC);
                            $record->completed_actual($1);
                            $record->completed_limit($2);
                        }
                        if ($record->type == RECORD_TYPE_ACTION and $bracket_type eq '<') {
                            $record->has_todo(1);
                        }
                    }
                }
            }
            if ($priority) {
                $record->priority($priority);
            }
            if ($date) {
                $record->date_due(parse_date($date, $self->date_format));
            }

            my $indent_columns = ($whitespace =~ tr/\t/\t/) * $self->tabstop
                               + ($whitespace =~ tr/ / /);

            if ($self->tabstop) {
                $record->level(int($indent_columns/$self->tabstop) + 1);
            }

            $record->description($description);

            if ($multi_desc_start) {
                @description_lines = ($description);
                $multiline_desc_mode = 1;
            }
            elsif ($multi_note_start) {
                @note_lines = ();
                $multiline_note_mode = 1;
            }
            else {
                push @records, $record;
                $record = new Palm::Progect::Record;
            }
        }
        else {
            next if /^\s*#/;
            warn "line not matched: $_\n";
        }

    }

    close FH;

    if ($append) {
        $self->records(@{ $self->records } , @records);
    }
    else {
        $self->records(@records);
    }

}

=item save_records($file, $append)

Export records in Text format to C<$file>.

If C<$append> is true then C<load_records> will B<append> the Text to
C<file>.  If false, C<export_records> If false, C<export_records> will
overwrite C<$file> (if it exists) before writing the Text.

=back

=cut

sub save_records {
    my ($self, $filename, $append) = @_;

    local (*FH);

    if ($filename) {
        if ($append) {
            print STDERR "Appending Records in Text format to $filename\n" unless $self->quiet;
            open FH, ">>$filename" or die "Can't append to $filename: $!\n";
        }
        else {
            print STDERR "Saving Text format to $filename\n" unless $self->quiet;
            open FH, ">$filename" or die "Can't clobber $filename: $!\n";
        }
    }
    else {
        print STDERR "Dumping Text format to STDOUT\n" unless $self->quiet;
        open FH, ">&STDOUT" or die "Can't dup STDOUT: $!\n";
    }

    my ($indent);
    if ($self->fill_with_spaces) {
        $indent = ' ' x $self->tabstop;
    }
    else {
        $indent = "\t";
    }

    my $i = 0;
    foreach my $record (@{$self->records}) {
        $i++;
        # Skip the invisible root record
        next if $i == 1 and not $record->level;

        my $level = $record->level || 0;
        if ($level == 1) {
            print FH "\n";
        }

        my $columns    = $self->columns || 0;
        my $tabstop    = $self->tabstop || 0;
        my $zero_based_level = $level - 1;
        $zero_based_level    = 0 if $zero_based_level < 0;

        my $record_indent = $indent x $zero_based_level;
        $Text::Wrap::Columns = 80;  # avoid the 'used only once warning'
        $Text::Wrap::Columns = $columns - $tabstop * $zero_based_level;
        $Text::Tabs::tabstop = $tabstop;

        my @line;

        if ($record->type == RECORD_TYPE_ACTION) {
            if ($record->has_todo()) {
                if ($record->completed) {
                    push @line, '<x>';
                }
                else {
                    push @line, '< >';
                }
            }
            else {
                if ($record->completed) {
                    push @line, '[x]';
                }
                else {
                    push @line, '[ ]';
                }
            }
        }
        elsif ($record->type == RECORD_TYPE_PROGRESS) {
            push @line, '[' . ($record->completed() || 0). '%]';
        }
        elsif ($record->type == RECORD_TYPE_NUMERIC) {
            push @line, "[" . ($record->completed_actual || 0) . '/' . ($record->completed_limit || 0). "]";
        }
        elsif ($record->type == RECORD_TYPE_INFO) {
            push @line, ".";
        }

        if ($record->priority) {
            push @line, '[' . $record->priority . ']';
        }

        if ($record->date_due) {
            push @line, "(" . format_date($record->date_due, $self->date_format) . ")";
        }

        if ($record->category_name) {
            push @line, "{" . $record->category_name . "}";
        }

        my $desc = $record->description;
        my $para_indent = $record_indent.$indent;

        $desc =~ s/\n/ /g;

        push @line, $desc;

        if ($record->note) {
            my $note = $record->note;
            if ($self->columns) {
                $note = wrap('', $para_indent, $note);
            }
            $note = "<<\n$para_indent$note\n$para_indent>>";
            $note = _expand_tabs($note, $self->tabstop) if $self->fill_with_spaces;
            push @line, $note;
        }

        print FH "${record_indent}", join ' ', @line;

        print FH "\n";
    }
    print FH "\n";

    close FH;
}

sub load_prefs {
}

sub save_prefs {
}

sub _expand_tabs {
    my ($string, $tabstop) = @_;
    $string =~ s/\t/' ' x $tabstop/ge;
    return $string;
}

sub _trim_lines {
    my ($whitespace, $tabstop, @lines) = @_;

    $whitespace = _expand_tabs($whitespace, $tabstop);

    foreach my $line (@lines) {
        $line = _expand_tabs($line, $tabstop);
        $line =~ s/^$whitespace//;
    }
    return @lines;
}


# sub db_name_from_filename {
#     my $filename = shift;
#     $filename =~ tr{\\}{/};
#     $filename =~ tr{:}{/};
#     $filename = (split m{/}, $filename)[-1];
#     $filename =~ s/^lbPG-//;
#     $filename =~ s/\..*?$//;
#     return $filename;
# }
#
# sub expand_tabs {
#     my ($string, $tabstop) = @_;
#     $string =~ s/\t/' ' x $tabstop/ge;
#     return $string;
# }
#
# sub trim_lines {
#     my ($whitespace, $tabstop, @lines) = @_;
#
#     $whitespace = expand_tabs($whitespace, $tabstop);
#
#     foreach my $line (@lines) {
#         $line = expand_tabs($line, $tabstop);
#         $line =~ s/^$whitespace//;
#     }
#     return @lines;
# }
#
#
#
1;

__END__


Example:

@ setting_foo : 1
@ setting_bar : 2


    [ ] action type
    [x] completed action type
    < > action type with todo link
    <x> completed action type with todo link

    [80%] progress type
    [4/5] numeric type

    . info type

    [ ] [5] action type with priority
    [ ] (15/7/2001) action type with date

    [80%] [5] (15/7/2001) {category} progress type with priority and date and category

    [80%] [5] (15/7/2001) {category} progress type with priority and date and category <<
        Multi-Line note
        for this item
        >>


=head1 AUTHOR

Michael Graham E<lt>mag-perl@occamstoothbrush.comE<gt>

Copyright (C) 2002-2005 Michael Graham.  All rights reserved.
This program is free software.  You can use, modify,
and distribute it under the same terms as Perl itself.

The latest version of this module can be found on http://www.occamstoothbrush.com/perl/

=head1 SEE ALSO

C<progconv>

L<Palm::PDB(3)>

http://progect.sourceforge.net/

=cut



