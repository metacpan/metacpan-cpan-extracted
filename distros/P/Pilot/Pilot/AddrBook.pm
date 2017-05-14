# AddrBook
#
# This module is useful for processing the contents of Pilot Address
# Book databases.

require 5.001;

package Pilot::AddrBook;

use Pilot::DB;
@ISA = qw(Pilot::DB);

@ContactTypes =
    ("Work",
     "Home",
     "FAX",
     "Other",
     "E-Mail",
     "Main",
     "Pager",
     "Mobile");

sub new {
    my $self = new Pilot::DB @_;
    bless $self;
    return $self;
}

sub before_records {
    # jww: skip some unknown data; length is given

    $self->{"MiscLength"} = Pilot::DB::read_dword;
    $self->{"MiscData"}   = Pilot::DB::read_db $self->{"MiscLength"};

    # jww: what do these mean?

    $self->{"MiscDWORD1"} = Pilot::DB::read_dword;
    $self->{"MiscDWORD2"} = Pilot::DB::read_dword;
}

sub read_record {
    my ($self, $descriptors) = @_;

    my $ref = $self->start_record();

    # basic appelative details

    my $field;
    foreach $field ("Last", "First", "Title", "Company") {
        $ref->{$field} = Pilot::DB::read_field;
    }

    # phone data

    for ($i = 0; $i < 5; $i++) {
        my $index = Pilot::DB::read_field;
        my $data  = Pilot::DB::read_field;

        if ($data) {
            if (! $ref->{"Contact"}) {
                $ref->{"Contact"} = [ ];
            }
            push @{$ref->{"Contact"}}, [ $ContactTypes[$index], $data ];
        }
    }

    # address lines

    my $data = Pilot::DB::read_note;

    $addr = { "Street" => $data } if $data;

    # other address info

    foreach $field ("City", "State", "Zip", "Country") {
        $data = Pilot::DB::read_field;
        if ($data) {
            $addr = { } if ! $addr;
            $addr->{$field} = $data;
        }
    }

    # store the address in the record

    $ref->{"Address"} = [ [ "Home", $addr ] ] if $addr;
    
    # note about the person
    
    $ref->{"Note"}    = Pilot::DB::read_note;
    
    # private and category
    
    $ref->{"Private"} = Pilot::DB::read_field;
    
    my $descriptor    = $self->read_category($descriptors, $ref);
    
    # read the custom fields
    
    $ref->{"Custom"}  = { };

    my $i;
    for ($i = 0; $i < 4; $i++) {
        if ($descriptor->{"CustomFields"} &&
            ref $descriptor->{"CustomFields"} eq "ARRAY") {
            if ($descriptor->{"CustomFields"}[$i] &&
                ref $descriptor->{"CustomFields"}[$i] eq "ARRAY") {
                $field = $descriptor->{"CustomFields"}[$i][0];
            } else {
                $field = $descriptor->{"CustomFields"}[$i];
            }
        } else {
            $field = $self->{"Header"}[$i];
        }

        if ($field eq "Middle") {
            $ref->{$field} = Pilot::DB::read_field;
        } else {
            $ref->{"Custom"}{$field} = Pilot::DB::read_field;
        }
    }

    # which number is displayed

    $index = Pilot::DB::read_field;

    if ($index > @ContactTypes) {
      Pilot::DB::db_warn("contact type index too high at $index");
    }

    $ref->{"Display"} = $ContactTypes[$index - 1];

    # finish up the record

    return $self->finish_record($descriptor, $ref);
}


########################################################################
# support code for BBDB databases                                      #
########################################################################

sub grab_field {
    my $field;
    if ($_[0] =~ /^\(/) {
        my $text = substr $_[0], 1;
        my $pos  = 0;
        my $depth = 1;
        for ($pos = 0; $depth && $pos < length $text; $pos++) {
            my $char = substr $text, $pos, 1;
            $depth++ if $char eq "(";
            $depth-- if $char eq ")";
        }
        $field = substr $text, 0, $pos - 1;
        $text = substr $text, $pos;
        $_[0] = $text;
        $_[0] =~ s/^\s*//;
    }
    elsif ($_[0] =~ /^\[/) {
        $_[0] =~ s/^\[([^\]]+)\]\s*(.*)/$2/;
        $field = $1;
    }
    elsif ($_[0] =~ /^\"/) {
        my $text = substr $_[0], 1;
        my $pos  = 0;
        for ($pos = 0; $pos < length $text; $pos++) {
            my $char = substr $text, $pos, 1;
            if ($char eq "\\") {
                $pos++;
                next;
            }
            last if $char eq "\"";
        }
        $field = substr $text, 0, $pos;
        $text = substr $text, $pos + 1;
        $_[0] = $text;
        $_[0] =~ s/^\s*//;
        $_[0] =~ s/^,//;
    } else {
        $_[0] =~ s/^(\S+)\s*(.*)/$2/;
        $field = $1;
    }
    $field = "" if $field eq "0";
    return $field;
}

sub bbdb_to_record {
    my ($line) = @_;
    my $ref = { };

    $line =~ s/^\[//;
    $line =~ s/\]$//;

    my ($field, $subfield, $mfield);

    if (($field = grab_field $line) ne "nil") {
        $ref->{"First"} = $field;
    }

    if (($field = grab_field $line) ne "nil") {
        $ref->{"Last"} = $field;
    }

    if (($field = grab_field $line) ne "nil") {
        $subfield = grab_field $field;
        $ref->{"Middle"} = $subfield;
    }

    if (($field = grab_field $line) ne "nil") {
        $ref->{"Company"} = $field;
    }

    if (($field = grab_field $line) ne "nil") {
        $ref->{"Contact"} = [ ];
        while ($subfield = grab_field $field) {
            $mfield = grab_field $subfield;

            my ($data, $prefix, $suffix, $ext);
            $area   = grab_field $subfield;
            $prefix = grab_field $subfield;
            $suffix = grab_field $subfield;
            $ext    = grab_field $subfield;

            my $num = sprintf("%03d %03d %04d x%d", $area, $prefix,
                              $suffix, $ext);

            push @{$ref->{"Contact"}}, [ $mfield, $num ];
        }
    }

    if (($field = grab_field $line) ne "nil") {
        $ref->{"Address"} = [ ];
        while ($subfield = grab_field $field) {
            $mfield = grab_field $subfield;

            my @street;
            my $ssf;

            $ssf = grab_field $subfield;
            push @street, $ssf if $ssf;

            $ssf = grab_field $subfield;
            push @street, $ssf if $ssf;
            
            $ssf = grab_field $subfield;
            if ($ssf) {
                push @street, split / \/ /, $ssf;
            }

            my %data;

            if (@street) {
                $data{"Street"}  = [ @street ];
            }

            $data{"City"}  = grab_field $subfield;
            $data{"State"} = grab_field $subfield;
            $data{"Zip"}   = grab_field $subfield;
            $data{"Zip"} =~ s/ /-/;

            push @{$ref->{"Address"}}, [ $mfield, \%data ];
        }
    }

    if (($field = grab_field $line) ne "nil") {
        if (! $ref->{"Contact"}) {
            $ref->{"Contact"} = [ ];
        }
        while ($subfield = grab_field $field) {
            $mfield = grab_field $subfield;
            push @{$ref->{"Contact"}}, [ "E-Mail", $mfield ];
        }
    }

    $ref->{"Custom"} = { };
    if (($field = grab_field $line) ne "nil") {
        if ($field !~ /^\(/) {
            # jww (09/07/97): How does BBDB handle multi-line comments?
            $ref->{"Note"} = [ split(/ \/ /, $field) ];
        } else {
            while ($subfield = grab_field $field) {
                my $label = grab_field $subfield;
                my $dot = grab_field $subfield;
                my $content = grab_field $subfield;

                my $found = 0;
                foreach $non_custom ("Category", "Private", "Display") {
                    if ($label =~ /^$non_custom$/i) {
                        if ($non_custom eq "Category") {
                            $ref->{$non_custom} = [ split / \/ /, $content ];
                        } else {
                            $ref->{$non_custom} = $content;
                        }
                        $found = 1;
                        last;
                    }
                }

                if (! $found) {
                    $ref->{"Custom"}{$label} = $content;
                }
            }
        }
    }

    if (! $ref->{"Category"}) {
        $ref->{"Category"} = [ "Unfiled" ];
    }

    if (grab_field($line) ne "nil") {
        warn "unexpected field in BBDB line\n";
    }

    return $ref;
}

sub split_phone_number {
    my ($self, $phone) = @_;
    my ($area, $prefix, $suffix, $ext);

    if ($phone =~ /\(?([0-9]+)\)?\s+([0-9]+)(\s+|-)([0-9]+)\s+(.+)/) {
        ($area, $prefix, $suffix, $ext) = ($1, $2, $4, $5);
    }
    elsif ($phone =~ /\(?([0-9]+)\)?\s+([0-9]+)(\s+|-)([0-9]+)/) {
        ($area, $prefix, $suffix, $ext) = ($1, $2, $4, 0);
    }
    elsif ($phone =~ /([0-9]+)(\s+|-)([0-9]+)\s+(.+)/) {
        ($area, $prefix, $suffix, $ext) = ($self->{"AreaCode"}, $1, $3, $4);
    }
    elsif ($phone =~ /([0-9]+)(\s+|-)([0-9]+)/) {
        ($area, $prefix, $suffix, $ext) = ($self->{"AreaCode"}, $1, $3, 0);
    }
    elsif ($phone =~ /([0-9]+)/) {
        # jww (09/05/97): Hack for Borland extensions
        ($area, $prefix, $suffix, $ext) = ($self->{"AreaCode"}, "431", $1, 0);
    }

    return ($area, $prefix, $suffix, $ext);
}

sub record_to_bbdb {
    my ($ref) = @_;
    my $line = "";

    $line .= '[';

    if ($ref->{"First"}) {
        $line .= sprintf '"%s" ', $ref->{"First"};
    } else {
        $line .= '"" ';
    }

    if ($ref->{"Last"}) {
        $line .= sprintf '"%s" ', $ref->{"Last"};
    } else {
        $line .= 'nil ';
    }

    if ($ref->{"Middle"}) {
        $line .= sprintf '("%s") ', $ref->{"Middle"};
    } else {
        $line .= 'nil ';
    }

    if ($ref->{"Company"}) {
        $line .= sprintf '"%s" ', $ref->{"Company"};
    } else {
        $line .= 'nil ';
    }

    my $have_phone = 0;
    my $have_email = 0;

    foreach $contact (@{$ref->{"Contact"}}) {
        if ($contact->[0] eq "E-Mail") {
            $have_email = 1;
        } else {
            $have_phone = 1;
        }
    }

    if ($have_phone) {
        $line .= '(';
        my $first = 1;
        foreach $contact (@{$ref->{"Contact"}}) {
            next if $contact->[0] eq "E-Mail";
            $line .= ' ' if ! $first;
            my @phone_data = $self->split_phone_number($contact->[1]);
            $line .= sprintf('["%s" %ld %ld %ld %ld]', $contact->[0], @phone_data);
            $first = 0;
        }
        $line .= ') ';
    } else {
        $line .= 'nil ';
    }

    if ($ref->{"Address"}) {
        $line .= '(';
        my $location;
        my $first = 1;
        foreach $location (@{$ref->{"Address"}}) {
            $line .= ' ' if ! $first;
            $line .= sprintf '["%s" ', $location->[0];

            my $addr = $location->[1];
            my $zip = $addr->{"Zip"};
            if (! $zip) {
                $zip = "0";
            }
            elsif ($zip =~ /-/) {
                $zip =~ s/([0-9]+)-([0-9]+)/($1 $2)/;
            }


            my $i;
            for ($i = 0; $i < 3; $i++) {
                if ($i == 2) {
                    my $len = scalar @{$addr->{"Street"}};
                    if ($len > $i + 1) {
                        $line .= sprintf('"%s" ', join(" / ", $addr->{"Street"}[$i, $len - 1]));
                        next;
                    }
                }
                $line .= sprintf('"%s" ', $addr->{"Street"}[$i]);
            }
            $line .= sprintf('"%s" "%s" %s]', $addr->{"City"}, $addr->{"State"}, $zip);

            $first = 0;
        }
        $line .= ') ';
    } else {
        $line .= 'nil ';
    }

    if ($have_email) {
        $line .= '(';
        my $first = 1;
        foreach $contact (@{$ref->{"Contact"}}) {
            next unless $contact->[0] eq "E-Mail";
            $line .= ' ' if ! $first;
            $line .= sprintf('"%s"', $contact->[1]);
            $first = 0;
        }
        $line .= ') ';
    } else {
        $line .= 'nil ';
    }

    $line .= '(';
    my $added = 0;

    foreach $field ("Category", "Private", "Display") {
        if ($ref->{$field}) {
            my $lc = $field;
            $lc =~ tr/A-Z/a-z/;
            $added && ($line .= ' ', $added = 0);

            my $data;
            if ($field eq "Category") {
                $data = join " / ", $ref->{$field};
            } else {
                $data = $ref->{$field};
            }
            $line .= sprintf('(%s . "%s")', $lc, $data);
            $added = 1;
        }
    }

    foreach $field (sort keys %{$ref->{"Custom"}}) {
        if ($ref->{"Custom"}{$field}) {
            my $lc = $field;
            $lc =~ tr/A-Z/a-z/;
            $added && ($line .= ' ', $added = 0);
            $line .= sprintf('(%s . ', $lc);
            if (ref $ref->{"Custom"}{$field} eq "ARRAY") {
                $line .= '"';
                my $member;
                my $first = 1;
                foreach $member (@{$ref->{"Custom"}{$field}}) {
                    if (! $first) {
                        $line .= ' / ';
                    } else {
                        $first = 0;
                    }
                    $line .= $member;
                }
                $line .= '"';
            } else {
                $line .= sprintf('"%s"', $ref->{"Custom"}{$field});
            }
            $line .= ')';
            $added = 1;
        }
    }

    if ($ref->{"Note"}) {
        my $note = join " / ", @{$ref->{"Note"}};
        $note =~ s/\"/\\\"/g;
        $added && ($line .= ' ', $added = 0);
        $line .= sprintf('(notes . "%s")', $note);
        $added = 1;
    }

    $line .= ') nil]';

    return $line;
}

1;
