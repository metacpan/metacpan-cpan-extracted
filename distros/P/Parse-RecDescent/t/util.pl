sub make_itempos_text
{
    my ($item, $itempos) = @_;

    join("\n",
         '',
         (
             map {
                 my $i = $_;
                 join(' ', sprintf("%-10s",ref $item->[$i] ? '_REF_' : $item->[$i]),
                      map {
                          my $type = $_;
                          map {
                              sprintf("%s.%s=%3d", $type, $_, $itempos->[$i]{$type}{$_})
                          } qw(from to)
                      } qw(offset line column));
             } (1..$#$item),
         ),
         '');
}

1;
