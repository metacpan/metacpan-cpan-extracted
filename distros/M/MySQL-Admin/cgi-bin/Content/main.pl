use utf8;
use warnings;
no warnings 'redefine';
use vars qw(@menuNavi);
@menuNavi = $m_oDatabase->fetch_AoH(
    "select title,action,`submenu`,target from $m_hrSettings->{database}{name}.mainMenu where `right` <= $m_nRight order by position");
print q(<?xml version="1.0" encoding="UTF-8"?><actions>);
for ( my $i = 0 ; $i < $#menuNavi ; $i++ ) {
    print qq(<action output="$menuNavi->{output}">
    <title>$menuNavi->{title}</title>
    <xml>cgi-bin/mysql.pl?action=$menuNavi->{action}</xml>
    <out>content</out>
    <id>$menuNavi->{action}</id>
    <text>$menuNavi->{title}</text>
</action>);
} ## end for ( my $i = 0 ; $i < ...)
1;
