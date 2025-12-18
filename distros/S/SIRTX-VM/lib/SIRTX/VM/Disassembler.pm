# Copyright (c) 2025 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: module for assembling SIRTX VM code


package SIRTX::VM::Disassembler;

use v5.16;
use strict;
use warnings;

use Carp;
use Fcntl qw(SEEK_SET SEEK_END SEEK_CUR);
use SIRTX::VM::RegisterFile;
use SIRTX::VM::Opcode;

use parent 'Data::Identifier::Interface::Userdata';

our $VERSION = v0.11;


sub new {
    my ($pkg, %opts) = @_;
    my $self = bless({
            max_data => delete($opts{max_data}),
        }, $pkg);

    {
        my $fh = delete $opts{in};
        croak 'No input given' unless defined $fh;

        unless (ref $fh) {
            open(my $x, '<', $fh) or die $!;
            $fh = $x;
        }

        $fh->binmode;
        $self->{in} = $fh;
    }

    {
        my $fh = delete $opts{out};
        croak 'No output given' unless defined $fh;

        unless (ref $fh) {
            open(my $x, '>', $fh) or die $!;
            $fh = $x;
        }

        $fh->binmode;
        $fh->binmode(':utf8');
        $self->{out} = $fh;
    }

    croak 'Stray options passed' if scalar keys %opts;

    return $self;
}


sub run {
    my ($self, @opts) = @_;
    my $in = $self->{in};
    my $out = $self->{out};
    my $in_length = $self->_in_length;

    $self->{starts} = {0 => undef};

    croak 'Stray options passed' if scalar @opts;

    while (1) {
        my $pos = $in->tell // croak 'Cannot tell on input';

        last if $pos >= $in_length;

        if (exists $self->{starts}{$pos}) {
            $self->_run_text;
        } else {
            $self->_run_data;
        }
    }
}

# ---- Private helpers ----

sub _in_length {
    my ($self) = @_;

    return $self->{in_length} //= do {
        my $fh = $self->{in};
        my $l;

        $fh->seek(0, SEEK_END);

        $l = $fh->tell;

        $fh->seek(0, SEEK_SET);

        $l;
    };
}

sub _run_text {
    my ($self) = @_;
    my $in = $self->{in};
    my $out = $self->{out};
    my $in_length = $self->_in_length;

    while ($in->tell < $in_length && defined(my $opcode = SIRTX::VM::Opcode->read($in))) {
        my %extra = $opcode->_extra;

        $self->{starts}{$_} //= undef for @{$extra{start_offsets}//[]};


        if ($extra{type} eq 'chunk') {
            my $length = $extra{length};

            if ($length >= 4) {
                my $command = '.chunk';
                my $data_length = $length - 4;
                my ($flags, $type);
                my $chunk_identifier;
                my $raw;

                $in->read($raw, 4) == 4 or croak 'Cannot read input';

                ($flags, $type) = unpack('nn', $raw);

                {
                    my $identifier_type = $flags & ((1<<15)|(1<<14));
                    if ($identifier_type == ((1<<15)|(1<<14))) {
                        croak 'Unsupported identifier type: user defined';
                    } elsif ($identifier_type == ((1<<15)|(0<<14))) {
                        $command .= ' of ~'.$type;
                    } elsif ($identifier_type == ((0<<15)|(1<<14))) {
                        $command .= ' of sid:'.$type;
                    } elsif ($identifier_type == ((0<<15)|(0<<14))) {
                        $command .= ' of sni:'.$type;
                    }
                }

                if ($flags & (1<<7)) {
                    $command .= ' standalone';
                }

                if ($flags & (1<<1)) {
                    $in->read($raw, 2) == 2 or croak 'Cannot read input';
                    $chunk_identifier = unpack('n', $raw);
                    $data_length -= 2;
                    $command .= ' as ~'.$chunk_identifier;
                }

                if ($flags & (1<<0)) {
                    $data_length -= 1;
                }

                #warn sprintf('; ### flags: %04x type: %04x, chunk identifier: %s, data_length: %u', $flags, $type, $chunk_identifier // '<undef>', $data_length);
                $out->say($command);
                $self->_run_data($data_length);

                if ($flags & (1<<0)) {
                    my $pos = $in->tell;
                    $in->read($raw, 1) == 1 or croak 'Cannot read input';
                    $out->say(sprintf('                                                 ; at 0x%04x: Padding: 0x%02x', $pos, ord $raw));
                }
                $out->say('.endchunk');
            }
        } else {
            $out->say($opcode->as_text);
            if ($opcode->is_end_of_text) {
                $out->say('; End of text');
                last;
            }
        }
    }
}

sub _run_data {
    my ($self, $todo) = @_;
    my $in = $self->{in};
    my $out = $self->{out};
    my $pos = $in->tell // croak 'Cannot tell on input';
    my ($next_code) = sort { $a <=> $b } grep { $_ >= $pos } keys(%{$self->{starts}}), $self->_in_length;

    $todo //= $next_code - $pos;

    if (defined($self->{max_data}) && $todo > $self->{max_data}) {
        $out->say(sprintf('; %u bytes of data skipped', $todo));
        $in->seek($todo, SEEK_CUR);
        return;
    }

    $out->say(sprintf('; %u bytes of data follow', $todo));

    while ($todo > 0) {
        my $step = $todo > 8 ? 8 : $todo;
        my $line = '.byte';
        my $rendered;

        $in->read(my $raw, $step) == $step or croak 'Error reading data';

        $line .= sprintf(' 0x%02x', ord) foreach split //, $raw;

        $rendered = $raw =~ tr/\x21-\x7E/./rc;

        $line = sprintf('%-48s ; at 0x%04x: | %-8s |',
            $line, $pos,
            $rendered,
        );

        $out->say($line);

        $todo -= $step;
        $pos  += $step;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SIRTX::VM::Disassembler - module for assembling SIRTX VM code

=head1 VERSION

version v0.11

=head1 SYNOPSIS

    use SIRTX::VM::Disassembler;

    my SIRTX::VM::Disssembler $asm = SIRTX::VM::Disassembler->new(in => $infile, out => $outfile);

    $asm->run;

(experimental since v0.09)

This is a disassembler for vmv0 code.
It tries to reverse the assembling step by e.g. L<SIRTX::VM::Assembler>.
It's main use is to debug programs as well as translators (L<SIRTX::VM::Assembler> and compilers).

This package inherits from L<Data::Identifier::Interface::Userdata>.

=head1 METHODS

=head2 new

    my SIRTX::VM::Disassembler $disasm = SIRTX::VM::Disassembler->new(in => $infile, out => $outfile);

(experimental since v0.09)

Creates a new disassembler object. This object can be used to convert byte code back into code.

The following options are supported:

=over

=item C<in>

(required)

The input data as a filename or handle.
If a handle the handle must allow seeking.
Also attributes on the handle might be changed.
It is best to avoid reusing the handle with other code.

=item C<out>

(required)

The output to write the result to. The same aspects as for C<in> apply.

=item C<max_data>

(since v0.10, optional)

Maximum amount of data (in bytes) that is reported before it is skipped.

=back

=head2 run

    $disasm->run;

(experimental since v0.09)

Performs the translation back from binary form to text form.

=head1 AUTHOR

Philipp Schafft <lion@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024-2025 by Philipp Schafft <lion@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
