package OurNet::Site;
require 5.005;

$OurNet::Site::VERSION = '1.52';

use strict;

=head1 NAME

OurNet::Site - Extract web pages via templates

=head1 SYNOPSIS

    use LWP::Simple;
    use OurNet::Site;

    my ($query, $hits) = ('autrijus', 10);
    my $found;

    # Create a bot
    $bot = OurNet::Site->new('google');

    # Parse the result got from LWP::Simple
    $bot->callme($self, 0, get($bot->geturl($query, $hits)), \&callmeback);

    print '*** ' . ($found ? $found : 'No') . ' match(es) found.';

    # Callback routine
    sub callmeback {
        my ($self, $himself) = @_;

        foreach my $entry (@{$himself->{response}}) {
            if ($entry->{url}) {
                print "*** [$entry->{title}]" .
                         " ($entry->{score})" .
                       " - [$entry->{id}]\n"  .
                 "    URL: [$entry->{url}]\n" .
                       "    $entry->{preview}\n";
                $found++;
                delete($entry->{url});
            }
        }
    }

=head1 DESCRIPTION

This module emulates a typical search engine by reading a XML script
defining its aspects, and parses results on-the-fly accordingly.

Note that it also takes Inforia Quest .fmt scripts, available at
http://www.inforian.com/. The author of course cannot support this
usage.

As per v1.52, Site.pm also accepts Template Toolkit format templates
with extention '.tt2' as site descriptors, provided that it contains
at least one C<[% FOREACH entry %]> block, and C<[% SET url.start %]>
accordingly.

Note that tt2 support is *highly* experimental and should not be
relied upon until a more stable release comes.

=head1 BUGS

Probably lots. Most notably the 'More' facilities is lacking. Also
there is no template-generating abilities. This is a must, but I
couldn't find enough motivation to do it. Maybe you could.

Currently, tt2 does not (quite) support incremental parsing in
conjunction with L<OurNet::Query>.

=cut

# ---------------
# Variable Fields
# ---------------
use vars qw/$Myself/;

use fields qw/id charset proc expression template tempdata
              name info url var response category score
              allow_partial allow_tags tmplobj/;

# -----------------
# Package Constants
# -----------------
use constant PATH_SITE         => join('/', ('', split('::', __PACKAGE__), ''));
use constant ERROR_SITE_NEEDED => __PACKAGE__ . ' needs a file';
use constant ERROR_FILE_NEEDED => __PACKAGE__ . ' cannot find definition for ';
use constant ERROR_FORMAT      => __PACKAGE__ . ' cannot determine file format for';
use constant CHARSET_MAP       => {'JIS'  => 'ja-jp.jis', 'EUC'  => 'ja-jp.euc',
                                   'BIG5' => 'zh-tw',     'GB'   => 'zh-cn'};
use constant ENTITY_STRIP      => '<.*?>|^[\015\012\s]+|[\015\012\s]+$|\t';
use constant ENTITY_MAP        => {'nbsp' => ' ', 'quot' => '"', 'amp' => '&',
                                   'gt' => '>', 'lt' => '<', 'copy' => '(c)'};
use constant ENTITY_LIST       => '&('.join('|', keys(%{ENTITY_MAP()})).');';

# ---------------------
# Subroutine new($site)
# ---------------------
sub new {
    my $class = shift;
    my $self  = ($] > 5.00562) ? fields::new($class)
                               : do { no strict 'refs';
                                      bless [\%{"$class\::FIELDS"}], $class };
    my $file = $_[0] or (warn(ERROR_SITE_NEEDED), return);

    (%{$self} = %{$file}, return $self) if UNIVERSAL::isa($file, 'HASH');

    unless (-e $file) {
        if (-e "$_[0].xml") {
            $file = "$_[0].xml";
        }
        elsif (-e "$_[0].fmt") {
            $file = "$_[0].fmt";
        }
        elsif (-e "$_[0].tt2") {
            $file = "$_[0].tt2";
        }
        else {
            foreach my $inc (@INC) {
                last if -e ($file = $inc . PATH_SITE . $_[0]);
                last if -e ($file = $inc . PATH_SITE . "$_[0].xml");
                last if -e ($file = $inc . PATH_SITE . "$_[0].fmt");
                last if -e ($file = $inc . PATH_SITE . "$_[0].tt2");
            }
        };
    }

    die(ERROR_FILE_NEEDED . $file) if !(-e $file);

    $self->parse($file);
    $self->{tempdata} = '';

    return $self;
}

# ---------------------------------------
# Subroutine geturl($self, $query, $hits)
# ---------------------------------------
sub geturl {
    my $self = shift;
    my $url  = $self->{url}{start};

    $url =~ s|_QUERY_|$_[0]|g;
    $url =~ s|_HITS_|$_[1]|g;
    $url =~ s|\${  query  }|$_[0]|g;
    $url =~ s|\${  hits  }|$_[1]|g;

    return $url;
}

# ------------------------------
# Subroutine parse($self, $file)
# ------------------------------
sub parse {
    my $self = shift;
    open(local *SITEFILE, $_[0]);

    if ($_[0] =~ m|\.tt2$|i) {
        local $/;
        my $content = <SITEFILE>;

	require OurNet::Template;
        $self->{tmplobj} = OurNet::Template->new();
        $self->{tmplobj}->extract($content, undef, $self);
    }
    elsif ($_[0] =~ m|\.xml$|i) {
        local $/;
        my $content = <SITEFILE>;

        my $xml_cdata_re = '(<!\[CDATA\[)?\015?\012?(.*?)\015?\012?(]]>)?';

        $self->{id} = $1 if $content =~ m|<site id="(.*?)">|i;

        foreach my $tag ('charset', 'score', 'expression', 'template', 'proc') {
            $self->{$tag} = $2 if $content =~ m|<$tag>$xml_cdata_re</$tag>|is;
        }

        foreach my $tag ('url', 'var', 'name', 'info') {
            $self->{$tag}{lc($1)} = $3 while
                $content =~ s|<$tag \w+="(.*?)">$xml_cdata_re</$tag>||is;
        }

        if ($content =~ m|<category>(.*?)</category>|i) {
            $self->{category} = [ split(',', $1) ];
        }
    }
    elsif ($_[0] =~ m|(?:.*[/\\])?(.*?)(?:\.fmt)?$|i) {
        $self->{id} = $1;

        chomp($self->{name}{'en-us'} = <SITEFILE>);
        if ($self->{name}{'en-us'} =~ s|\((.+)\)||) {
            $self->{info}{'en-us'} = $1;
        }

        chomp($self->{url}{start} = <SITEFILE>);
        if ($self->{url}{start} =~ m|_START_\d+_\d+_|) {
            $self->{url}{more}  = $self->{url}{start};
            $self->{url}{start} =~ s|_START_\d+_(\d+)_|$1|;
        }

        while (chomp($_ = <SITEFILE>)) {
            (m|^---|) ? do {
                last;
            } :
            (m|^\w+://|) ? do {
                $self->{url}{backup} = $_;
            } :
            (m|^MORE\t(.+)|) ? do {
                $self->{url}{more} = $1;
            } :
            (m|^PROC\t(.+)|) ? do {
                $self->{proc} = $1;
            } :
            (m|^VAR\t(.+)|) ? do {
                $self->{var}{$1} = <SITEFILE> . $1 . <SITEFILE>;
                $self->{var}{$1} =~ s|[\t\015\012]||g;
            } :
            (m|^SCORE\t(.+)|) ? do {
                $self->{score} = $1;
                $self->{score} =~ s|\bx\b|_SCORE_|ig;
                $self->{score} =~ s|\by\b|_RANK_|ig;
            } :
            (m|^CHARSET\t(.+)|) ? do {
                $self->{charset} = CHARSET_MAP->{uc($1)};
            } :
            (m|^CHT\t(.+)|) ? do {
                $self->{name}{'zh-tw'} = $1;
                $self->{info}{'zh-tw'} = $self->{info}{'en-us'};
            } :
            (m|^CHS\t(.+)|) ? do {
                $self->{name}{'zh-cn'} = $1;
                $self->{info}{'zh-cn'} = $self->{info}{'en-us'};
            } :
            (m|^EXPR\t(.+)|) ? do {
                $self->{expression} = $1;
            } :
            (m|^TYPE\t(.+)|) ? do {
                $self->{category} = $1;
            } : undef;
        }

        chomp($self->{url}{home} = <SITEFILE>);
        chomp($self->{template} = <SITEFILE>);

        while (chomp($_ = <SITEFILE>)) {
            next unless m|^[A-Z_]*$|;

            $self->{template} .= $_ ? "_${_}_" : '___';
            chomp($self->{template} .= <SITEFILE>);
        }
    }
    else {
        die(ERROR_FORMAT . $_[0]);
    };

    close(SITEFILE);
}

# ---------------------------------------
# Subroutine contemplate($self, $content)
# ---------------------------------------
sub contemplate {
    my ($self, $content) = @_;

    if ($self->{tmplobj}) {
        # tt2 support goes here
        # XXX macros, etc incomplete
        my $result = $self->{tmplobj}->extract(undef, $content);
        push @{$self->{response}}, @{$result->{entry}};
        return $self;
    }

    my $template = _quote($self->{template});
    my @vars     = map {lc($_)} ($template =~ m|_(\w+?)_|g); # slurp!
    my $length   = length($content);
    $template    =~ s|\015?\012?_\w+?_\015?\012?|(.*?)|g;

    while (my @vals = ($content =~ m|$template|is)) {
        $content =~ s|$template||is;
        last if $length == length($content); # infinite loop
        $length  = length($content);

        my $rank = ($#{$self->{response}} + 2); # begins with 1

        push(@{$self->{response}}, {'rank' => $rank});
        my $entry = $self->{response}[$rank - 1];
        $entry->{id} = $self->{id};

        foreach my $idx (0 .. $#vars) {
            my ($var, $val) = ($vars[$idx], $vals[$idx]);

            # Null variable ___
            next if $var eq '_';

            # Expand HTML entities
            if (!$self->{allow_tags}) {
                $val =~ s|@{[ENTITY_STRIP]}||gs;
                $val =~ s|@{[ENTITY_LIST]}|ENTITY_MAP->{$1}|ge;
            }

            if ($var eq 'sizek') {
                $entry->{size} = $val * 1024;
            }
            elsif ($var eq 'score') {
                my $proc = $self->{score};

                $proc =~ s|_RANK_|$rank|ig;
                $proc =~ s|_SCORE_|$val|ig;

                if ($proc =~ m|^\d*|) {
                    $entry->{$var} = $proc;
                }
                else {
                    require Safe;

                    my $compartment = Safe->new();
                    $compartment->permit_only(qw/:base_core :base_mem/);
                    $compartment->share(qw/$rank $val $self/);
                    $entry->{$var} = $compartment->reval($proc);
                }
            }
            elsif ($var eq 'url') {
                $entry->{$var} = $val;

                if ($entry->{$var} !~ m|^\w+://|) {
                    if ($self->{url}{home}) {
                        $entry->{$var} = $self->{url}{home} . $entry->{$var};
                    }
                    elsif (!$self->{allow_partial} and
                           $self->{url}{start} =~ m|^(\w+://.*?)/|) {
                        $entry->{$var} = $1 . $entry->{$var};
                    }
                }
            }
            else {
                $entry->{$var} = $val;
            };
        }

        if (!$entry->{score}) {
            my $proc = $self->{score};
            $proc =~ s|_RANK_|\$rank|ig;
            $entry->{score} = eval($proc);
        }

        if (my $proc = $self->{proc}) {
            require Safe;
            $Myself ||= $self;

            my $compartment = Safe->new();
            $compartment->share(qw/$Myself/);
            $compartment->permit_only(qw/:base_core :base_mem pushre regcmaybe regcreset regcomp/);

            $proc =~ s|_(\w+)_|\$Myself->{response}[$rank - 1]{lc('$1')}|ig;
            $compartment->reval($proc);
        }
    }

    undef $Myself;
    return $self;
}

# ----------------------------------------------------------
# Subroutine callme($self, $herself, $id, $data, \&callback)
# ----------------------------------------------------------
sub callme {
    my ($self, $herself, $id, $data, $callback) = @_;
    my $template = _quote($self->{template});
    my $count    = $#{$self->{response}};

    # Append old ones
    $self->{tempdata} = $data = $self->{tempdata} . $data;

    unless ($self->{tmplobj}) {
        # Deep magic here
        $template =~ s|\015?\012?_\w+?_\015?\012?|(.*?)|g;  # Find variables
    
        $template = '^.*' . $template;
    
        $self->{tempdata} =~ s|$template||is;
    }

    if (defined $callback) {
        return &$callback($herself, $self->contemplate($data));
    }
    else {
        return $self->contemplate($data);
    }
}

sub _quote {
    my $quoted;

    foreach my $chunk (split(/({{.*?}})/, $_[0] || '')) {
        if ($chunk =~ m|{{(.*?)}}|) {
            $quoted .= $1;
        }
        else {
            $quoted .= quotemeta($chunk);
        }
    }

    return $quoted;
}

1;

=head1 SEE ALSO

L<OurNet::Query>

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.org>

=head1 COPYRIGHT

Copyright 2001 by Autrijus Tang E<lt>autrijus@autrijus.org>.

All rights reserved.  You can redistribute and/or modify
this module under the same terms as Perl itself.

=cut
