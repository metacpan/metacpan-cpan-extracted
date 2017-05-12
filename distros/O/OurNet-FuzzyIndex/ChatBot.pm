# $File: //depot/libOurNet/FuzzyIndex/ChatBot.pm $ $Author: autrijus $
# $Revision: #3 $ $Change: 3772 $ $DateTime: 2003/01/24 00:08:39 $

package OurNet::ChatBot;
require 5.005;

$OurNet::ChatBot::VERSION = '1.24';

use strict;
use OurNet::FuzzyIndex;

use fields qw/botfile botname writable db nextone
              avoid synonyms rndouts lastone/;

=head1 NAME

OurNet::ChatBot - Context-free interactive Q&A engine

=head1 SYNOPSIS

    use OurNet::ChatBot;

    my $bot = eval { OurNet::ChatBot->new('fianjmo', 'fianjmo.db') };

    if ($@ or !$bot->{db}{idxcount}) {
	die "No database found. you must build it with 'make test'.\n";
    }

    while (1) {
	print '['.($ENV{USER} || 'user').'] ';
	print '<fianjmo> '.($bot->input(scalar <STDIN>) || '...')."\n";
    }

=head1 DESCRIPTION

The B<OurNet::ChatBot> module simulates a general-purpose,
context-free, interactive chatter-bot using the B<OurNet::FuzzyIndex>
engine.  It reads the file stored in a F<ChatBot/> directory, parses
synonyms and random output settings, then return answers via the
C<input()> method.

This module require no reformatting of existing contents at all;
it can automatically parse paragraphs and sentences, then convert
the weighted data into a B<OurNet::FuzzyIndex> database. You can
also specify additional parameters like keywords, weights and grammar
at any time.

The B<lastone> property is used to return/set the id of the bot's
last sentence. In conjunction of directly manipulating the B<CHUNKS>
array (which contains all possible return values for C<input()>),
the front-end program could prevent duplicate responses.

=head1 CAVEATS

The B<nextone> flag-property is implemented badly. It's supposed to
tweak the behaviour so it allows a more sequencial follow-up to a
training material based on real dialogs. See the C<__DATA__> section
in F<Makefile.PL> for an example.

=head1 METHODS

=head2 OurNet::ChatBot->new($botname, $bot, [$writable])

Constructor method; reads bot name, bot database file, and
writable flag as arguments. Returns a B<OurNet::ChatBot>
object.

=cut

sub new {
    my $class = shift;
    my $self  = ($] > 5.00562) ? fields::new($class)
                               : do { no strict 'refs';
                                      bless [\%{"$class\::FIELDS"}], $class };

    $self->{botname}  = shift;
    $self->{botfile}  = shift
        or (warn("OurNet::ChatBot needs a bot"), return);
    $self->{writable} = shift;

    my $botfile = '';
    my $botdir = __FILE__;
    $botdir =~ s|\.pm$||;

    eval { mkdir($botdir, 0666) unless -d $botdir };

    $botfile = (-e $self->{botfile})
	? $self->{botfile}
	: (-e "$botdir/$self->{botfile}") ? "$botdir/$self->{botfile}"
	: $self->{botfile};

    die("OurNet::ChatBot cannot find the database: $self->{botfile}")
	unless (-e $botfile or $self->{writable});

    $self->{db}       = OurNet::FuzzyIndex->new($botfile);
    $self->{synonyms} = [split(/\n/, $self->{db}->getvar('synonyms') || '')];
    $self->{rndouts}  = [split(/\n/, $self->{db}->getvar('rndouts')  || '')]
                          || ['...'];

    return $self;
}

=head2 $self->addsyn($skey, @syns)

Inserts new synonyms of the word C<$skey> into the bot database.

=cut

sub addsyn {
    my $self = shift;
    my $skey = shift;

    push(@{$self->{synonyms}}, $skey || ' ', join('|', @_));
}

=head2 $self->addentry($content, [$trigger])

Inserts a response sentence to the ChatBot's corpus. The optional
C<$trigger> variable indicates a B<cue> sentence to be used as
index instead of C<$content>; this is useful in a Q & A context.

=cut

sub addentry {
    my ($self, $content, $trigger) = @_;
    return unless $self->{writable};

    $self->{db}->insert($content, defined($trigger) ? $trigger : $content);
}

=head2 $self->sync()

Writes back to the database file.

=cut

sub sync {
    my $self = shift;

    return unless $self->{writable};

    $self->{db}->setvar('synonyms', join("\n", @{$self->{synonyms}}));
    $self->{db}->setvar('rndouts', join("\n", @{$self->{rndouts}}));
    $self->{db}->sync;
}

=head2 $self->input($say, [@avoid])

Process the query sentence in C<$say>, and returns the chat-bot's
response. The chunk IDs specified in C<@avoid> will not be used.

=cut

sub input {
    my $self    = shift;
    my $say     = shift;
    my $avoid   = join(',', ($self->{avoid} || '', @_ || '', ''));

    # Substitute synonyms
    foreach my $synline (0 .. (($#{$self->{synonyms}} - 1) / 2)) {
        $say =~ s{$self->{synonyms}[$synline * 2 + 1]}
                 {$self->{synonyms}[$synline * 2]}g;
    }

    my %matched = $self->{db}->query("$say\xa4\x3f", $MATCH_PART);

    foreach my $match (sort {$matched{$b} <=> $matched{$a}} keys(%matched)) {
        my $num = unpack('N', $match);
        next if index($avoid, ",$num,") > -1;

        $self->{lastone} = $num;
        $self->{avoid}  .= ",$num";

        return $self->{db}->getkey($self->{nextone}
            ? pack('N', ($num % $self->{db}{idxcount}) + 1)
            : $match);
    }

    return $self->{rndouts}[ int(rand() * ($#{$self->{rndouts}} + 1)) ];
}

=head2 $self->convert($data)

Converts the legacy database in B<Chatbot::Amber> format to
a database file.  This function is obsoleted, unsupported,
and will probably go away at some point in favor of some
XML or YAML-based format.

=cut

sub convert {
    my $self = shift;
    my ($init, @chunks) = split(/\015?\012\s*--+\s*\015?\012/, shift);
    my ($def_val);

    foreach my $line ($init =~ m/^SYN \[(.*)\]/gm) {
        if ($line =~ m/^(.*)\s?::\s?(.+)/) {
            push(@{$self->{synonyms}}, $1 || ' ',
                 join('|', split(/\\\s/, '('.quotemeta($2).')')));
        }
    }

    if ($init =~ m/^RND \[(.*)\]/m) {
        @{$self->{rndouts}} = split(/\s+/, $1);
    }

    if ($init =~ m/^DEV \[(\d+)\]/m) {
        $def_val = $1;
    }

    $self->sync;

    foreach my $chunk (@chunks) {
        my @keywords;

        while ($chunk =~ s/^#(\d*)(.*)//gm) {
            push @keywords, $1 || $def_val;
            push @keywords, $2;
        }

        while ($chunk =~ s/^(.{52,})\n+/$1/g) {};

        $self->addentry($chunk, @keywords);
    }
}

1;

__END__

=head1 SEE ALSO

L<OurNet::FuzzyIndex>

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

=head1 COPYRIGHT

Copyright 2001, 2003 by Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>.

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
