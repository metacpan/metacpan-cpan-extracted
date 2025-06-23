# -----------------------------------------------------------------------------

=head1 NAME

Quiq::Dumper - Ausgabe Datenstruktur

=head1 BASE CLASS

L<Quiq::Object>

=cut

# -----------------------------------------------------------------------------

package Quiq::Dumper;
use base qw/Quiq::Object/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::AnsiColor;
use Scalar::Util ();

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Klassenmethoden

=head3 dump() - Liefere Datenstruktur in lesbarer Form

=head4 Synopsis

  $str = $this->dump($scalar);

=head4 Arguments

=over 4

=item $scalar

Referenz auf eine Datenstruktur.

=back

=head4 Description

Liefere eine Perl-Datenstruktur beliebiger Tiefe in lesbarer Form
als Zeichenkette, so dass sie zu Debugzwecken ausgegeben werden kann.

Wenn die Klassenvariable $NoClassNames gesetzt ist, unterbleibt die
Ausgabe eines evtl. gegebenen Klassennamens vor einer geblessten
Struktur:

  $Quiq::Dumper::NoClassNames = 1;

=head4 Example

  Quiq::Dumper->dump($obj);

=cut

# -----------------------------------------------------------------------------

my $maxDepth = undef;
my $a = Quiq::AnsiColor->new(1);
our $NoClassNames = 0;

sub dump {
    my ($this,$arg) = splice @_,0,2;
    my $depth = shift // 0;
    my $seenH = shift // {};

    $depth++;

    # Skalar

    if (!ref $arg) {
        if (!defined $arg) {
            return 'undef';
        }
        $arg =~ s/\n/\\n/g;
        $arg =~ s/\r/\\r/g;
        return qq|"$arg"|;
    }

    # Referenz

    if ($seenH->{$arg}) {
        return "SEEN $arg";
    }
    $seenH->{$arg}++;

    my $ref = ref $arg;
    my $refType = Scalar::Util::reftype($arg);

    if ($refType eq 'SCALAR') {
        return '\\'.$this->dump($$arg,$depth,$seenH);
    }
    elsif ($refType eq 'ARRAY') {
        my $str = '';
        if (!defined($maxDepth) || $depth <= $maxDepth) {
            for (my $i = 0; $i < @$arg; $i++) {
                if ($str) {
                    $str .= ",\n";
                }
                $str .= $this->dump($arg->[$i],$depth,$seenH);
            }
            if ($str) {
                $str =~ s/^/  /mg;
                $str = "\n$str\n";
            }
        }
        else {
            $str = @$arg;
        }
        $str = "[$str]";
        if (!$NoClassNames && $refType ne $ref) {
            $str = $a->str('bold dark blue',$ref).' '.$str;
        }
        return $str;
    }
    elsif ($refType eq 'HASH') {
        my $str = '';
        if (!defined($maxDepth) || $depth <= $maxDepth) {
            for my $key (sort keys %$arg) {
                if ($str) {
                    $str .= ",\n";
                }
                $str .= "'$key' => ".$this->dump($arg->{$key},$depth,$seenH);
            }
            if ($str) {
                $str =~ s/^/  /mg;
                $str = "\n$str\n";
            }
        }
        else {
            $str = keys %$arg;
        }
        $str = "{$str}";
        if (!$NoClassNames && $refType ne $ref) {
            $str = $a->str('bold dark blue',$ref).' '.$str;
        }
        return $str;
    }
    elsif ($refType eq 'REGEXP') {
        return "/$arg/";
    }
    elsif ($refType eq 'CODE') {
        # FIXME: nicht richtig ausgearbeitet
        return "CODE: $arg";
    }
    elsif ($refType eq 'GLOB') {
        # FIXME: nicht richtig ausgearbeitet
        return "GLOB: $arg";
    }

    $this->throw(
        'DUMPER-00002: Unknown reference type',
        ReferenceType => "$refType - $arg",
    );
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.228

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2025 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
