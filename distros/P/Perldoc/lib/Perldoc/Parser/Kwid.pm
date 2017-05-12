package Perldoc::Parser::Kwid;
use Perldoc::Base -Base;
use Perldoc::Reader;

field 'receiver';
field 'reader';

sub init {
    my $reader = Perldoc::Reader->new(@_);
    $self->reader($reader);
    return $self;
}

my ($kwid, $head, $para, $bold, $italic, $tt, $brace_bold, $brace_italic, $brace_tt, $brace_any, $comment, $verbatim, $link, $url, $li, $directive_any);

my @has_inline = (
    \$bold, \$italic, \$tt,
    \$brace_bold, \$brace_italic, \$brace_tt, \$brace_any,
    \$link, \$url, \$comment, \$li,
);

$kwid = {
    begins => qr/^/,
    id     => 'body',
    has    => [ \$head, \$verbatim, \$comment, \$para ],
    ends   => qr/\Z/,
};

$verbatim = {
    begins => qr/^(?=[ \t])/m,
    id     => 'pre',
    ends   => qr/(?=\n[^ \t])/,
};

$comment = {
    begins => qr/^#/m,
    id     => 'comment',
    ends   => qr/\n/,
};

$li = {
    begins => qr/^[-+*]+ /m,
    id     => 'li',
    has    => [ grep {$_ != \$li} @has_inline ],
    ends   => qr/\n/, # (?=[-+*\n])/,
};

$head = {
    begins => qr/^=+ /m,
    id     => 'head',
    event  => sub { "h" . (length($_[0]) - 1) },
    has    => \@has_inline,
    ends   => qr/\n/,
};

$para = {
    begins => qr//,
    id     => 'p',
    has    => \@has_inline,
    ends   => qr/\n\n/,
};

$url = {
    begins => qr{\b\w+://(?:[^,.)\s]|[,.](?!\s))+},
    id     => 'a',
    event  => sub { "a $_[0]" },
    ends   => qr{},
};

$link = {
    begins => qr/\[ (?: [^\]\|\n]+ \| )?/x,
    id     => 'a',
    event  => sub { $_[0] =~ /.([^\]\|\n]*)/; "a $1" },
    has    => [ grep {$_ != \$link} @has_inline ],
    ends   => qr/\]/,
};

$brace_any = {
    begins => qr{\{+\w+: },
    id     => 'brace',
    event  => sub { $_[0] =~ /(\w+)/; $1 },
    has    => \@has_inline,
    ends   => sub { $_[0] =~ /^(\{+)/; my $len = length($1); qr/\}{$len}/ },
    nest   => 1,
};

$directive_any = {
    begins => qr{^\.\w+\n}m,
    id     => 'directive',
    event  => sub { substr($_[0], 1, -1) },
    has    => \@has_inline,
    ends   => sub { $_[0] =~ /(\w+)/; qr/^!$1/ },
    nest   => 1,
};

inline(\$brace_italic, \$italic => 'i', '/');
inline(\$brace_bold, \$bold => 'b', '*');
inline(\$brace_tt, \$tt => 'tt', '`');

sub inline() {
    my ($b, $p, $name, $sym) = @_;
    my $punct = '()$@%&,.!;?';

    $sym = quotemeta($sym);
    $$p = {
        begins => qr{(?<=(?:\a|\s))$sym(?=[$punct]*\b)},
        id     => $name,
        has    => [ grep {$_ != $p} @has_inline ],
        ends   => sub { qr{(?<=[\w$punct])$sym(?=[$punct]*(?=\Z|\s))} },
    };
    $$b = {
        begins => qr{\{+$sym},
        id     => $name,
        has    => [ grep {$_ != $b} @has_inline ],
        ends   => sub { my $len = length($_[0]) - 1; qr/$sym\}{$len}/ },
    };
}

use constant ID    => 0;
use constant HAS   => 1;
use constant ENDS  => 2;
use constant EVENT => 3;

sub parse {
    my @stack;    # ([$id, $has, $ends, $event], ...)
    my @has = (\$kwid);
    my $str = $self->reader->all;

    $str = '' unless defined($str);
    pos($str) = 0;

    PARSE: {
        my $candidates = join('|',
            map { "($_)" } (
                (map { $_->[ENDS] } @stack),
                (map { ($$_)->{begins} } @has)
            )
        );

        my $pos = pos($str);
        my $cur = $pos;

      MATCH:
        pos($str) = $cur;
        $str =~ /\G(?:$candidates)/g or do {
            if ($str =~ /\G(?:\\.)+/gs) {
                $cur = pos($str);
            }
            else {
                ++$cur;
            }
            goto MATCH;
        };

        # Now let's find out which ones matched...
        foreach my $idx (1 .. $#+) {
            no strict 'refs';
            defined $$idx or next;

            $self->receiver->text(substr($str, $pos, $cur - $pos))
              if $cur > $pos;

            if ($idx <= @stack) {
                # For each stack item from the end on, emit "id" events
                $self->receiver->ends($_->[EVENT])
                  for reverse splice(@stack, $idx - 1);

                @stack or last PARSE;

                # Pop onto the last frame
                @has = @{ $stack[-1][HAS] };
                redo PARSE;
            }

            # Now we are at "begins".
            my $parser = ${ $has[ $idx - @stack - 1 ] };
            my $id     = $parser->{id};
            my $ends   = $parser->{ends};
            my $event  = $parser->{event} || $id;

            $ends = $ends->($$idx) if ref $ends eq 'CODE';
            $event = $event->($$idx) if ref $event eq 'CODE';

            # Grep for nestedness
            my @this_has = ();

          HAS:
            foreach my $has (@{ $parser->{has} }) {
                if (($$has)->{nest}) {
                    push @this_has, $has;
                }
                else {
                    foreach my $frame (@stack) {
                        next HAS if $frame->[ID] eq ($$has)->{id};
                    }
                }
                push @this_has, $has;
            }

            push @stack, [ $id, \@this_has, $ends, $event ];
            @has = @this_has;

            $self->receiver->begins($event);
            redo PARSE;
        }
    }
}

=head1 NAME

Perldoc::Parser::Kwid;

=head1 SYNOPSIS

    # Convert kwid to html:
    use Perldoc::Parser::Kwid;
    use Perldoc::Emitter::HTML;

    my $html = '';
    my $receiver = Perldoc::Emitter::HTML->new->init(stringref => $html);
    my $kwid_text = 'This is Kwid markup';
    my $parser = Perldoc::Parser::Kwid->new(receiver => $receiver)
        ->init(string => $kwid_text);
    $parser->parse;
    print $html;

=head1 DESCRIPTION

Parse Kwid markup and fire events.

=head1 AUTHOR

Audrey Tang <autrijus@cpan.org>
Ingy döt Net <ingy@cpan.org>

Audrey wrote the original code for this parser.

=head1 COPYRIGHT

Copyright (c) 2006. Ingy döt Net. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
