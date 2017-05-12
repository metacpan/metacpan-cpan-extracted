package Text::LangTag;

our %script_var = (     # use lowercase
    'fonipa' => 'latn',
    'fonupa' => 'latn',
    '1901' => 'latn',
    '1996' => 'latn',
    'monoton' => 'grek',
    'polyton' => 'grek',
    );

sub parse
{
    my ($class, $str) = @_;
    my (@list) = split('-', lc($str));
    my ($i, $res);

    if (length($list[0]) != 4 && !defined $script_var{$list[0]})
    {
        $res->{'lang'} = shift(@list);
        while (length($list[0]) == 3)
        { $res->{'extlang'}{shift(@list)} = 1; }
    }
    if (length($list[0]) == 4)
    { $res->{'script'} = shift(@list); }
    if (length($list[0]) == 2)
    { $res->{'region'} = shift(@list); }
    while (length($list[0]) > 4 && length($list[0]) < 9 || ($list[0] =~ m/^[0-9].{3}$/o))
    { $res->{'variant'}{shift(@list)} = 1; }
    while (length($list[0]) == 1)   # too loose, but hey
    { $res->{'extension'}{shift(@list) . '-' . shift(@list)} = 1; }
    return bless $res, $class;
}

sub to_string
{
    my ($tag) = @_;
    my (@res);

    push (@res, $tag->{'lang'}) if ($tag->{'lang'});
    push (@res, sort keys %{$tag->{'extlang'}}) if ($tag->{'extlang'});
    if ($tag->{'script'})
    {
        my ($str) = $tag->{'script'};
        $str =~ s/^(.)/uc($1)/oe;
        push (@res, $str);
    }
    push (@res, uc($tag->{'region'})) if ($tag->{'region'});
    push (@res, sort keys %{$tag->{'variant'}}) if ($tag->{'variant'});
    push (@res, sort keys %{$tag->{'extension'}}) if ($tag->{'extension'});
    return join('-', @res);
}

sub suppress
{
    my ($base, $script, $suppress) = @_;

    if ($script)
    {
        $base->{'script'} = $script->{'script'} if ($script->{'script'});
        $base->{'region'} = $script->{'region'} unless (defined $base->{'region'} || !defined $script->{'region'});
        foreach (grep {defined $script_var{$_}} keys %{$base->{'variant'}})
        { delete $base->{'variant'}{$_}; }
        foreach (keys %{$script->{'variant'}})
        {
            $base->{'variant'}{$_} = 1;
            $suppress->{'script'} = $script_var{$_};        # imply script suppression
        }
    }
    if ($suppress)
    {
        foreach (grep {defined $script_var{$_}} keys %{$suppress->{'variant'}})
        { $suppress->{'script'} = $script_var{$_}; }
        return if ($base->{'script'} && $base->{'script'} ne $suppress->{'script'});
        delete $base->{'script'};
        foreach (keys %{$suppress->{'variant'}})
        { delete $base->{'variant'}{$_}; }
        delete $base->{'region'} if (defined $base->{'region'} && $base->{'region'} eq $suppress->{'region'});
    }
}

sub just_script
{
    my ($base) = @_;
    my ($res);

    $res->{'script'} = $base->{'script'};
    foreach (grep {defined $script_var{$_}} keys %{$base->{'variant'}})
    { $res->{'variant'}{$_} = 1; }
    $res->{'region'} = $base->{'region'};
    return bless $res, ref $base;
}

sub no_script
{
    my ($base) = @_;
    my ($res) = bless {%$base}, ref $base;

    delete $res->{'script'};
    delete $res->{'region'};
    foreach (grep {defined $script_var{$_}} keys %{$base->{'variant'}})
    { delete $res->{'variant'}{$_}; }
    return $res;
}

1;
