package SIL::Shoe::Lang;

=head1 NAME

SIL::Shoe::Lang - Shoebox language file interface

=head1 SYNOPSIS

  $s = SIL::Shoe::Lang->new("filename.lng");
  $s->read;
  $s->{'srt'}{"order"}{'primary'};

=head1 DESCRIPTION

This class provides an interface to the Shoebox language file. It restructures
the file for easier access and provides various support functions for sorting,
etc.

In addition to those in SIL::Shoe::Control, the following methods are
available:

=cut

use SIL::Shoe::Control;

@ISA = qw(SIL::Shoe::Control);

use strict;

my (%groups) = (
            "LanguageEncoding"  => ["0", ""],
            "srtset"            => ["0", ""],
            "srt"               => ["h", "srt"],
            "varset"            => ["0", ""],
            "var"               => ["h", "var"],
            "fnt"               => ["0", ""],
               );

sub group
{
    my ($self, $name) = @_;
    return $groups{$name};
}

sub multiline
{
    my ($self, $name, $ingroup) = @_;
    return 0 if ($name eq "desc");
    return 1;
}

sub make_srt_order
{
    my ($self, $ref) = @_;
    my (@res, %multi);
    my ($i, $sec, $base_sec, $max_sec, $c, $l, $co, $temp);

    $i = 1;
    foreach $c (split(' ', $ref->{'SecPreceding'}))
    {
        if (length($c) > 1)
        {
            $res[ord(substr($c, 0, 1))] = "\xff\xff";
            $multi{$c} = pack("cc", 0, $i++);
        } else
        { $res[ord($c)] = pack("cc", 0, $i++); }
    }
    $base_sec = $i + 1;
    $max_sec = $base_sec;
    $i = 0;
    foreach $l (split('\n', $ref->{'primary'}))
    {
        $sec = $base_sec;
        $i++;
        foreach $c (split(' ', $l))
        {
            if (length($c) > 1)
            {
                $co = ord(substr($c, 0, 1));
                if ($res[$co] ne "" && $res[$co] ne "\xff\xff")
                { $temp = $res[$co]; $res[$co] = "\xff\xff"; $multi{chr($co)} = $temp; }
                elsif ($res[$co] eq "")
                { $res[$co] = "\xff\xff"; }
                $multi{$c} = pack("cc", $i, $sec++);
            } else
            { $res[ord($c)] = pack("cc", $i, $sec++); }
        }
        $max_sec = $sec if $sec > $max_sec;
    }
    
    $i = $max_sec + 1;
    foreach $c (split(' ', $ref->{'SecFollowing'}))
    {
        if (length($c) > 1)
        {
            $co = ord(substr($c, 0, 1));
            if ($res[$co] ne "" && $res[$co] ne "\xff\xff")
            { $temp = $res[$co]; $res[$co] = "\xff\xff"; $multi{chr($co)} = $temp; }
            elsif ($res[$co] eq "")
            { $res[$co] = "\xff\xff"; }
            $multi{$c} = pack("cc", 0, $i++);
        } else
        { $res[ord($c)] = pack("cc", 0, $i++); }
    }
    (\@res, \%multi);
}

=head2 $s->build_sorts

Builds tables to help with sort ordering, for each sort order in the language file.

=cut

sub build_sorts
{
    my ($self) = @_;
    my ($k, $ref);

    foreach $k (keys %{$self->{'srt'}})
    {
        $ref = $self->{'srt'}{$k};
        ($ref->{' single'}, $ref->{' multi'}) = $self->make_srt_order($ref);
    }
    $self;
}

=head2 $s->ducet($name)

Returns the given sort order as a set of unicode style ducet keys

=cut
sub ducet
{
    my ($self, $name) = @_;
    my ($single, $multi, $c, $res);

    $self->build_sorts unless (defined $self->{'srt'}{$name}{' single'});
    $single = $self->{'srt'}{$name}{' single'};
    $multi = $self->{'srt'}{$name}{' multi'};
    foreach $c (sort {$single->{$a} cmp $single->{$b}} keys %{$single})
    {
        $res .= sprintf("%04X", unpack('U', $c));
        $res .= " [." . join(".", map {sprintf("%04X", $_)} unpack("c*", $single->{$c})) . " .0000.0000]\n";
    }
    foreach $c (sort {$multi->{$a} cmp $multi->{$b}} keys %{$multi})
    {
        $res .= join(" ", map {sprintf("%04X", $_)} unpack('U*', $c));
        $res .= " [." . join(".", map {sprintf("%04X", $_)} unpack("c*", $multi->{$c})) . ".0000.0000]\n";
    }
    $res;
}

=head2 $s->sort_key($name, $str)

Calculates a sort key which can be string compared for a given string and sort
order name

=cut

sub sort_key
{
    my ($self, $name, $str) = @_;
    my ($resp, $ress, $i, $j, $c, $prim, $sec, $single, $multi, $val);

    $single = $self->{'srt'}{$name}{' single'};
    if (!defined $single)
    {
        $self->build_sorts;
        $single = $self->{'srt'}{$name}{' single'};
    }
    $multi = $self->{'srt'}{$name}{' multi'};
    for ($i = 0; $i < length($str); $i++)
    {
        $c = ord(substr($str, $i, 1));
        if ($single->[$c] eq "\xff\xff")
        {
            undef $val;
            for ($j = 1; $j < length($str) - $i; $j++)
            {
                last unless defined $multi->{substr($str, $i, $j)};
                $val = $multi->{substr($str, $i, $j)};
            }
            $i += ($j == 1) ? 0 : $j - 2;
        } else
        { $val = $single->[$c]; }
        ($prim, $sec) = unpack("cc", $val);
        $resp .= chr($prim) if ($prim != 0);
        $ress .= chr($sec) if ($sec != 0);
    }
    return $resp . "\000" . $ress;
}

=head2 $s->cmp($name, $level, $a, $b)

Compares the two strings according to the given sort order at the given level.
Returns +1, 0, -1 accordingly as per the perl cmp operator.

=cut

sub cmp
{
    my ($self, $name, $level, $a, $b) = @_;
    my ($single, $multi, $pa, $sa, $ta, $pb, $sb, $tb, $i, $j, $k, $val, $c, $cs);

    $self->build_sorts unless (defined $self->{'srt'}{$name}{' single'});
    $single = $self->{'srt'}{$name}{' single'};
    $multi = $self->{'srt'}{$name}{' multi'};
    while ($i < length($a) || $k < length($b))
    {
        if ($i < length($a))
        {
            $c = ord(substr($a, $i, 1));
            if ($single->[$c] eq "\xff\xff")
            {
                undef $val;
                for ($j = 1; $j < length($a) - $i; $j++)
                {
                    my ($s) = substr($a, $i, $j);
                    last unless defined $multi->{$s};
                    $val = $multi->{$s};
                }
                $i += ($j == 1) ? 0 : $j - 2;
            } else
            { $val = $single->[$c]; }
        }
        else
        { $val = "\000\000"; }
        ($pa, $sa) = unpack("cc", $val);
        
        if ($k < length($b))
        {
            $c = ord(substr($b, $k, 1));
            if ($single->[$c] eq "\xff\xff")
            {
                undef $val;
                for ($j = 1; $j < length($b) - $k; $j++)
                {
                    my ($s) = substr($b, $k, $j);
                    last unless (defined $multi->{$s});
                    $val = $multi->{$s};
                }
                $k += $j - 1;
            }
            else
            { $val = $single->[$c]; }
        }
        else
        { $val = "\000\000"; }

        ($pb, $sb) = unpack("cc", $val);
        if ($level == 0)
        { $c = $pa <=> $pb; }
        
        if (!$cs)
        { $cs = ($sa <=> $sb); }
        return $c if ($c != 0);
    }
    if ($level == 1)
    { return $cs; }
    else
    { return 0; }
}

=head2 @tokens = $s->tokenize($name, $level, $ignore, $str)

Returns an array of tokens that are sorting units. C<$ignore> says whether to
remove characters ignored at C<$level> or lower from the output. For example,
if 'a' were a primary character and "'" were a secondary character then

  $s->tokenize('test', 0, 0, "a'") = ("a", "'")
  $s->tokenize('test', 1, 0, "a'") = ("a'")
  $s->tokenize('test', 0, 1, "a'") = ("a")
  $s->tokenize('test', 1, 1, "a'") = ("a", "'")   # no tertiary chars to remove

=cut

sub tokenize
{
    my ($self, $name, $level, $ignore, $str) = @_;
    my ($i, $j, $c, $single, $multi, $val, @key, @res, $oldi);

    $single = $self->{'srt'}{$name}{' single'};
    if (!defined $single)
    {
        $self->build_sorts;
        $single = $self->{'srt'}{$name}{' single'};
    }
    $multi = $self->{'srt'}{$name}{' multi'};
    for ($i = 0; $i < length($str); $i++)
    {
        $oldi = $i;
        $c = ord(substr($str, $i, 1));
        if ($single->[$c] eq "\xff\xff\xff\xff")
        {
            undef $val;
            for ($j = 1; $j < length($str) - $i; $j++)
            {
                last unless defined $multi->{substr($str, $i, $j)};
                $val = $multi->{substr($str, $i, $j)};
            }
            $i += ($j == 1) ? 0 : $j - 2;
        } else
        { $val = $single->[$c]; }
        @key = unpack("ss", $val);
        next if ($key[0] == 0 && $key[1] == 0);     # ignore ignored characters
        if ($level == 1 && $key[0] == 0)
        {
            if ($ignore)
            { next; }
            else
            { $res[-1] .= substr($str, $oldi, $i - $oldi + 1); }
        }
        else
        { push (@res, substr($str, $oldi, $i - $oldi + 1)); }
    }
    return @res;
}

sub lang_tag
{
    my ($self) = @_;
    return $self->{'langtag'};
}

sub script_tag
{
    my ($self) = @_;
    my (@t) = split('-', lc($self->{'langtag'}));
    my (@res);

    foreach (@t)
    {
        push(@res, $_) if (length($_) == 4 || m/^fon/o);
    }
    return join("-", @res);
}

sub add_specials
{
    my ($self) = @_;
    
    
    while ($self->{'desc'} =~ m/\\([^=\s]+)\s*(?:\=\s*)?
        (?:\"((?:\\.|[^"])*)\"
            |
           \'((?:\\.|[^'])*)\'
            |
           (\S+))/ogx)  #"
        {
            $self->{$1} = $2 || $3 || $4;
        }
    $self;
}

1;

