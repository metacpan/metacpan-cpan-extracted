#!perl
# PODNAME: RT::Client::REST::Forms
# ABSTRACT: This package provides functions from RT::Interface::REST, because we don't want to depend on rt being installed.  Derived from rt 3.4.5.

use strict;
use warnings;

package RT::Client::REST::Forms;
$RT::Client::REST::Forms::VERSION = '0.71';
use Exporter;

use vars qw(@EXPORT @ISA);

@ISA = qw(Exporter);
@EXPORT = qw(expand_list form_parse form_compose vpush vsplit);

my $CF_name = q%[#\s\w:()?/-]+%;
my $field   = qr/[a-z][\w-]*|C(?:ustom)?F(?:ield)?-$CF_name|CF\.\{$CF_name}/i;
# always 9 https://rt-wiki.bestpractical.com/wiki/REST#Ticket_Attachments
my $spaces = ' ' x 9;


sub expand_list {
    my ($list) = @_;
    my (@elts, %elts);

    for my $elt (split /,/, $list) {
        if ($elt =~ m/^(\d+)-(\d+)$/) { push @elts, ($1..$2) }
        else                          { push @elts, $elt }
    }

    @elts{@elts}=();
    my @return = sort {$a<=>$b} keys %elts;
    return @return
}


sub form_parse {
    my @lines = split /(?<=\n)/, shift;
    my $state = 0;
    my @forms = ();
    my ($c, $o, $k, $e) = ('', [], {}, '');

    LINE:
    while (@lines) {
        my $line = shift @lines;

        next LINE if $line eq "\n";

        if ($line eq "--\n") {
            # We reached the end of one form. We'll ignore it if it was
            # empty, and store it otherwise, errors and all.
            if ($e || $c || @$o) {
                push @forms, [ $c, $o, $k, $e ];
                $c = ''; $o = []; $k = {}; $e = '';
            }
            $state = 0;
            next LINE
        }

        if ($state != -1) {

            if ($state == 0 && $line =~ m/^#/) {
                # Read an optional block of comments (only) at the start
                # of the form.
                $state = 1;
                $c = $line;
                while (@lines && $lines[0] =~ m/^#/) {
                    $c .= shift @lines;
                }
                next LINE
            }

            if ($state <= 1 && $line =~ m/^($field:) ?$/s) {
                # Empty field
                my $f = $1;
                $f =~ s/:?$//;

                push(@$o, $f) unless exists $k->{$f};
                vpush($k, $f, undef);

                $state = 1;

                next LINE
            }

            if ($state <= 1 && $line =~ m/^($field:) (.*)?$/s) {
                # Read a field: value specification.
                my $f     = $1;
                my $value = $2;
                $f =~ s/:?$//;

                # Read continuation lines, if any.
                while (@lines && ($lines[0] eq "\n" || $lines[0] =~ m/^ +/)) {
                    my $l = shift @lines;
                    $l =~ s/^$spaces//;
                    $value .= $l
                }

                # `Content` is always supposed to be followed by three new lines
                # ... but this doesnt behave as documented
                # https://rt-wiki.bestpractical.com/wiki/REST#Ticket_Attachments
                if ($f eq 'Content') {
                    $value =~ s/\n\n\n?$//g
                }
                # Chomp everything else
                else {
                    chomp $value
                }

                push(@$o, $f) unless exists $k->{$f};
                vpush($k, $f, $value);

                $state = 1;

                next LINE
            }

            if ($line !~ m/^#/) {
                # We've found a syntax error, so we'll reconstruct the
                # form parsed thus far, and add an error marker. (>>)
                $state = -1;
                $e = form_compose([[ '', $o, $k, '' ]]);
                $e.= $line =~ m/^>>/ ? "$line\n" : ">> $line\n";
                next LINE
            }

            # line will be ignored
        }
        else {
            # We saw a syntax error earlier, so we'll accumulate the
            # contents of this form until the end.
            $e .= "$line\n";
        }
    }
    push(@forms, [ $c, $o, $k, $e ]) if ($e || $c || @$o);

    for my $l (keys %$k) {
        $k->{$l} = vsplit($k->{$l}) if (ref $k->{$l} eq 'ARRAY');
    }

    return \@forms;
}


sub form_compose {
    my ($forms) = @_;
    my @text;

    for my $form (@$forms) {
        my ($c, $o, $k, $e) = @$form;
        my $text = '';

        if ($c) {
            $c =~ s/\n*$/\n/;
            $text = "$c\n";
        }
        if ($e) {
            $text .= $e;
        }
        elsif ($o) {
            my @lines;

            for my $key (@$o) {
                my ($line, $sp);
                my @values = (ref $k->{$key} eq 'ARRAY') ?
                               @{ $k->{$key} } :
                                  $k->{$key};

                $sp = " "x(length("$key: "));
                $sp = " "x4 if length($sp) > 16;

                for my $v (@values) {
                    if ($v =~ /\n/) {
                        $v =~ s/^/$sp/gm;
                        $v =~ s/^$sp//;

                        if ($line) {
                            push @lines, "$line\n\n";
                            $line = '';
                        }
                        elsif (@lines && $lines[-1] !~ m/\n\n$/) {
                            $lines[-1] .= "\n";
                        }
                        push @lines, "$key: $v\n\n";
                    }
                    elsif ($line &&
                           length($line)+length($v)-rindex($line, "\n") >= 70)
                    {
                        $line .= ",\n$sp$v";
                    }
                    else {
                        $line = $line ? "$line, $v" : "$key: $v";
                    }
                }

                $line = "$key:" unless @values;
                if ($line) {
                    if ($line =~ m/\n/) {
                        if (@lines && $lines[-1] !~ m/\n\n$/) {
                            $lines[-1] .= "\n";
                        }
                        $line .= "\n";
                    }
                    push @lines, "$line\n";
                }
            }

            $text .= join '', @lines;
        }
        else {
            chomp $text;
        }
        push @text, $text;
    }

    return join "\n--\n\n", @text;
}


sub vpush {
    my ($hash, $key, $val) = @_;
    my @val = ref $val eq 'ARRAY' ? @$val : $val;

    if (exists $hash->{$key}) {
        unless (ref $hash->{$key} eq 'ARRAY') {
            my @v = $hash->{$key} ne '' ? $hash->{$key} : ();
            $hash->{$key} = \@v;
        }
        push @{ $hash->{$key} }, @val;
    }
    else {
        $hash->{$key} = $val;
    }
}


sub vsplit {
    my ($val) = @_;
    my (@words);

    for my $line (map {split /\n/} (ref $val eq 'ARRAY') ? @$val : $val)
    {
        # XXX: This should become a real parser, à la Text::ParseWords.
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;
        push @words, split /\s*,\s*/, $line;
    }

    return \@words;
}

__END__

=pod

=encoding UTF-8

=head1 NAME

RT::Client::REST::Forms - This package provides functions from RT::Interface::REST, because we don't want to depend on rt being installed.  Derived from rt 3.4.5.

=head1 VERSION

version 0.71

=head2 METHODS

=over 4

=item expand_list

Expands a list, splitting on commas and stuff.

=item form_parse

Returns a reference to an array of parsed forms.

=item form_compose

Returns text representing a set of forms.

=for stopwords vpush vsplit

=item vpush

Add a value to a (possibly multi-valued) hash key.

=item vsplit

"Normalize" a hash key that's known to be multi-valued.

=back

1;

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2020 by Dmitri Tikhonov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
