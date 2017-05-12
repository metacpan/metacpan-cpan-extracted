use utf8;
use warnings;
no warnings 'redefine';
use vars qw(@t @menuNavi @m_aT1 $treeview);
@menuNavi = $m_oDatabase->fetch_AoH(
    "select title,action,`submenu`,target from $m_hrSettings->{database}{name}.navigation where `right` <= $m_nRight order by position"
);
@t = fetchMenu(@menuNavi);

sub fetchMenu {
    my @actions = @_;
    my @ret;
    for (my $i = 0 ; $i <= $#actions ; $i++) {
        my $fm;
        if ($actions[$i]->{submenu}) {
            my @sumenu = fetchMenu(
                $m_oDatabase->fetch_AoH(
                    "select * from  $m_hrSettings->{database}{name}.$actions[$i]->{submenu} where `right` <= $m_nRight order by id"
                )
            );
            my $headline = translate($actions[$i]->{title});
            maxlength(15, \$headline);
            push @ret,
              {
                text => $headline,
                href => 'javascript:void(0);',
                onclick =>
                  "requestURI('$ENV{SCRIPT_NAME}?action=$actions[$i]->{action}','$actions[$i]->{action}','$actions[$i]->{title}');",
                subtree => [@sumenu],
              };
        } else {
            my $headline = translate($actions[$i]->{title});
            maxlength(15, \$headline);
            if ($actions[$i]->{action} =~ /^javascript:(.+)$/) {
                push @ret,
                  {
                    text    => $headline,
                    href    => 'javascript:void(0);',
                    onclick => $1,
                  };
            } else {
                push @ret,
                  {
                    text => $headline,
                    href => 'javascript:void(0);',
                    onclick =>
                      "requestURI('$ENV{SCRIPT_NAME}?action=$actions[$i]->{action}','$actions[$i]->{action}','$actions[$i]->{title}');",
                  };
            }
        }
    }
    return @ret;
}
$treeview = new HTML::Menu::TreeView();
undef @m_aT1;
$treeview->loadTree($m_hrSettings->{tree}{navigation});

*m_aT1 = \@{$HTML::Menu::TreeView::TreeView[0]};
delId(\@m_aT1);
push @t, @m_aT1;
applyRights(\@t);
$treeview->sortTree(0);
$treeview->folderFirst(0);
$treeview->desc(0);
print $treeview->Tree(\@t, 'Crystal');
undef @m_aT1;

sub delId {
    my $t = shift;
    for (my $i = 0 ; $i < @$t ; $i++) {
        next unless ref @$t[$i] eq 'HASH';
        undef @$t[$i]->{id};
        delId(\@{@$t[$i]->{subtree}}) if (@{@$t[$i]->{subtree}});
    }
}

