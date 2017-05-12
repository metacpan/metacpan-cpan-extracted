# This package provides functions from RT::Interface::REST, because we don't
# want to depend on rt being installed.  Derived from rt 3.4.5.

package RT::Client::REST::Forms;

use strict;
use warnings;
use Exporter;

use vars qw(@EXPORT @ISA $VERSION);

@ISA = qw(Exporter);
@EXPORT = qw(expand_list form_parse form_compose vpush vsplit);
$VERSION = .02;

my $CF_name = q%[#\s\w:()?/-]+%;
my $field   = qr/[a-z][\w-]*|C(?:ustom)?F(?:ield)?-$CF_name|CF\.\{$CF_name}/i;

sub expand_list {
    my ($list) = @_;
    my ($elt, @elts, %elts);

    foreach $elt (split /,/, $list) {
        if ($elt =~ /^(\d+)-(\d+)$/) { push @elts, ($1..$2) }
        else                         { push @elts, $elt }
    }

    @elts{@elts}=();
    return sort {$a<=>$b} keys %elts;
}

# Returns a reference to an array of parsed forms.
sub form_parse {
    my $state = 0;
    my @forms = ();
    my @lines = split /\n/, $_[0];
    my ($c, $o, $k, $e) = ("", [], {}, "");

    LINE:
    while (@lines) {
        my $line = shift @lines;

        next LINE if $line eq '';

        if ($line eq '--') {
            # We reached the end of one form. We'll ignore it if it was
            # empty, and store it otherwise, errors and all.
            if ($e || $c || @$o) {
                push @forms, [ $c, $o, $k, $e ];
                $c = ""; $o = []; $k = {}; $e = "";
            }
            $state = 0;
        }
        elsif ($state != -1) {
            if ($state == 0 && $line =~ /^#/) {
                # Read an optional block of comments (only) at the start
                # of the form.
                $state = 1;
                $c = $line;
                while (@lines && $lines[0] =~ /^#/) {
                    $c .= "\n".shift @lines;
                }
                $c .= "\n";
            }
            elsif ($state <= 1 && $line =~ /^($field):(?:\s+(.*))?$/) {
                # Read a field: value specification.
                my $f  = $1;
                my @v  = ($2 || ());

                # Read continuation lines, if any.
                while (@lines && ($lines[0] eq '' || $lines[0] =~ /^\s+/)) {
                    push @v, shift @lines;
                }
                pop @v while (@v && $v[-1] eq '');

                # Strip longest common leading indent from text.
                my ($ws, $ls) = ("");
                foreach $ls (map {/^(\s+)/} @v[1..$#v]) {
                    $ws = $ls if (!$ws || length($ls) < length($ws));
                }
                s/^$ws// foreach @v;

                push(@$o, $f) unless exists $k->{$f};
                vpush($k, $f, join("\n", @v));

                $state = 1;
            }
            elsif ($line !~ /^#/) {
                # We've found a syntax error, so we'll reconstruct the
                # form parsed thus far, and add an error marker. (>>)
                $state = -1;
                $e = form_compose([[ "", $o, $k, "" ]]);
                $e.= $line =~ /^>>/ ? "$line\n" : ">> $line\n";
            }
        }
        else {
            # We saw a syntax error earlier, so we'll accumulate the
            # contents of this form until the end.
            $e .= "$line\n";
        }
    }
    push(@forms, [ $c, $o, $k, $e ]) if ($e || $c || @$o);

    my $l;
    foreach $l (keys %$k) {
        $k->{$l} = vsplit($k->{$l}) if (ref $k->{$l} eq 'ARRAY');
    }

    return \@forms;
}

# Returns text representing a set of forms.
sub form_compose {
    my ($forms) = @_;
    my (@text, $form);

    foreach $form (@$forms) {
        my ($c, $o, $k, $e) = @$form;
        my $text = "";

        if ($c) {
            $c =~ s/\n*$/\n/;
            $text = "$c\n";
        }
        if ($e) {
            $text .= $e;
        }
        elsif ($o) {
            my (@lines, $key);

            foreach $key (@$o) {
                my ($line, $sp, $v);
                my @values = (ref $k->{$key} eq 'ARRAY') ?
                               @{ $k->{$key} } :
                                  $k->{$key};

                $sp = " "x(length("$key: "));
                $sp = " "x4 if length($sp) > 16;

                foreach $v (@values) {
                    if ($v =~ /\n/) {
                        $v =~ s/^/$sp/gm;
                        $v =~ s/^$sp//;

                        if ($line) {
                            push @lines, "$line\n\n";
                            $line = "";
                        }
                        elsif (@lines && $lines[-1] !~ /\n\n$/) {
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
                    if ($line =~ /\n/) {
                        if (@lines && $lines[-1] !~ /\n\n$/) {
                            $lines[-1] .= "\n";
                        }
                        $line .= "\n";
                    }
                    push @lines, "$line\n";
                }
            }

            $text .= join "", @lines;
        }
        else {
            chomp $text;
        }
        push @text, $text;
    }

    return join "\n--\n\n", @text;
}

# Add a value to a (possibly multi-valued) hash key.
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

# "Normalise" a hash key that's known to be multi-valued.
sub vsplit {
    my ($val) = @_;
    my ($line, $word, @words);

    foreach $line (map {split /\n/} (ref $val eq 'ARRAY') ? @$val : $val)
    {
        # XXX: This should become a real parser, à la Text::ParseWords.
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;
        push @words, split /\s*,\s*/, $line;
    }

    return \@words;
}

1;
