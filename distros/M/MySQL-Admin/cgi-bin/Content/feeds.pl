use utf8;
use warnings;
no warnings 'redefine';
use vars qw(@menu @ret $blogs @t);
@menu =
  $m_oDatabase->fetch_AoH('select id,name from blogs  where `right` <= ? order by id', $m_nRight);

for (my $i = 0 ; $i <= $#menu ; $i++) {
    use HTML::Entities;
    my $url = "requestURI('$ENV{SCRIPT_NAME}?action=viewrss&url=$menu[$i]->{id}','feeds','feeds')";
    push @ret,
      {
        text    => $menu[$i]->{name},
        onclick => $url,
      };
}
$blogs = "requestURI('$ENV{SCRIPT_NAME}?action=viewrss','feeds','feeds')";
@t = (
         {
          text    => 'Rss feeds',
          onclick => $blogs,
          subtree => [@ret]
         }
        );
print '<tr id="trwwblogs"><td valign="top" class="sidebar">';
print Tree(\@t, $m_sStyle);
print '<br/></td></tr>';
@menu     = undef;
@t        = undef;
$treeview = undef;
1;
