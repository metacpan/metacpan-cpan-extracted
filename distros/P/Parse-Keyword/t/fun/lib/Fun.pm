package Fun;
use strict;
use warnings;

use Parse::Keyword { fun => \&fun_parser };
use Sub::Name 'subname';

use Exporter 'import';

our @EXPORT = 'fun';

# XXX this isn't quite right, i think, but probably close enough for now?
my $start_rx = qr/^[\p{ID_Start}_]$/;
my $cont_rx  = qr/^\p{ID_Continue}$/;

sub fun { @_ ? $_[0] : () }

sub fun_parser {
    my ($name, $prototype, $body);

    lex_read_space;

    if (lex_peek =~ /$start_rx|^:$/) {
        $name = parse_name(1);
    }

    lex_read_space;

    if (lex_peek eq '(') {
        $prototype = parse_prototype();
    }

    lex_read_space;

    if (lex_peek eq '{') {
        local $Fun::{'DEFAULTS::'};
        if ($prototype) {
            lex_read;

            my $preamble = '{';

            my @names = map { $_->{name} } @$prototype;
            $preamble .= 'my (' . join(', ', @names) . ') = @_;';

            my $index = 1;
            for my $var (grep { defined $_->{default} } @$prototype) {
                {
                    no strict 'refs';
                    *{ 'Fun::DEFAULTS::default_' . $index } = sub () {
                        $var->{default}
                    };
                }
                $preamble .= $var->{name} . ' = Fun::DEFAULTS::default_' . $index . '->()' . ' unless @_ > ' . $var->{index} . ';';
                $index++;
            }

            lex_stuff($preamble);
        }
        $body = parse_block;
    }
    else {
        die "syntax error";
    }

    if (defined $name) {
        my $full_name = join('::', compiling_package, $name);
        {
            no strict 'refs';
            *$full_name = subname $full_name, $body;
        }
        return (sub {}, 1);
    }
    else {
        return (sub { $body }, 0);
    }
}

sub parse_name {
    my ($allow_package) = @_;
    my $name = '';

    my $char_rx = $start_rx;

    while (1) {
        my $char = lex_peek;
        last unless length $char;
        if ($char =~ $char_rx) {
            $name .= $char;
            lex_read;
            $char_rx = $cont_rx;
        }
        elsif ($allow_package && $char eq ':') {
            die "syntax error" unless lex_peek(3) =~ /^::(?:[^:]|$)/;
            $name .= '::';
            lex_read(2);
        }
        else {
            last;
        }
    }

    return length($name) ? $name : undef;
}

sub parse_prototype {
    die "syntax error" unless lex_peek eq '(';
    lex_read;
    lex_read_space;

    if (lex_peek eq ')') {
        lex_read;
        return;
    }

    my $seen_slurpy;
    my @vars;
    while ((my $sigil = lex_peek) ne ')') {
        my $var = {};
        die "syntax error"
            unless $sigil eq '$' || $sigil eq '@' || $sigil eq '%';
        die "Can't declare parameters after a slurpy parameter"
            if $seen_slurpy;

        $seen_slurpy = 1 if $sigil eq '@' || $sigil eq '%';

        lex_read;
        lex_read_space;
        my $name = parse_name(0);
        lex_read_space;

        $var->{name} = "$sigil$name";

        if (lex_peek eq '=') {
            lex_read;
            lex_read_space;
            $var->{default} = parse_arithexpr;
        }

        $var->{index} = @vars;

        push @vars, $var;

        die "syntax error"
            unless lex_peek eq ')' || lex_peek eq ',';

        if (lex_peek eq ',') {
            lex_read;
            lex_read_space;
        }
    }

    lex_read;

    return \@vars;
}

1;
