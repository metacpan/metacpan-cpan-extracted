#!/usr/bin/perl -w
use strict;
use Frontier::RPC2;
use lib qw(lib);
use DBI::Library::Database;
use MySQL::Admin::Settings;
use vars
  qw($m_oRpc $m_sXml $m_oDatabase $m_dbh @m_aUsersBlogs $m_hrSubs @m_aRecentPost @m_aCatlist $m_hrSettings $m_nRight);
$m_oRpc   = new Frontier::RPC2;
$m_sXml   = "";
$m_nRight = 0;
loadSettings("config/settings.pl");
*m_hrSettings = \$MySQL::Admin::Settings::m_hrSettings;
($m_oDatabase, $m_dbh) =
  new DBI::Library::Database(
                             {
                              name     => $m_hrSettings->{database}{name},
                              host     => $m_hrSettings->{database}{host},
                              user     => $m_hrSettings->{database}{user},
                              password => $m_hrSettings->{database}{password},
                             }
                            );
@m_aUsersBlogs = (
                  {
                   url      => $m_hrSettings->{cgi}{serverName},
                   title    => $m_hrSettings->{cgi}{title},
                   blogid   => 123,
                   blogName => $m_hrSettings->{cgi}{serverName}
                  }
                 );
$m_hrSubs = {
             'blogger.getUsersBlogs'          => \&getUsersBlogs,
             'blogger.editPost'               => \&editPost,
             'metaWeblog.editPost'            => \&editPost,
             'metaWeblog.getRecentPostTitles' => \&getRecentPostTitles,
             'metaWeblog.newPost'             => \&newPost,
             'blogger.newPost'                => \&newPost,
             'mt.setPostCategories'           => \&setPostCategories,
             'mt.getCategoryList'             => \&getCategoryList,
             'metaWeblog.getRecentPosts'      => \&getRecentPosts,
             'blogger.getUserInfo'            => \&getUserInfo,
             'mt.publishPost'                 => \&publishPost,
             'mt.getRecentPostTitles'         => \&getRecentPostTitles,
             'mt.supportedTextFilters'        => \&supportedTextFilters,
             'blogger.setTemplate'            => \&setTemplate,
             'blogger.getTemplate'            => \&getTemplate,
             'blogger.getUserInfo'            => \&getUserInfo,
             'blogger.getPost'                => \&getPost,
             'mt.getPostCategories'           => \&getPostCategories,
            };

sub publishPost {
    return 1;
}

sub getPostCategories {
    my $postid   = shift;
    my $username = shift;
    my $password = shift;
    if (checkPassword($username, $password)) {
        my $sql    = ("select cat from news where `right` <= $m_nRight");
        my $c      = $m_oDatabase->fetch_string($sql);
        my @select = split /\|/, $c;
        for (my $i = 0 ; $i <= $#select ; $i++) {
            my $id = $m_oDatabase->fetch_string("select id from cats where name = ?", $select[$i]);
            push @m_aCatlist,
              {
                categoryId   => $id,
                categoryName => $select[$i]
              };
        }
        return \@m_aCatlist;
    } else {
        return 0;
    }
}

sub setPostCategories {
    my $postid   = shift;
    my $username = shift;
    my $password = shift;
    my $aoh      = shift;
    if (checkPassword($username, $password)) {
        my $catstring;
        my @cats;
        foreach my $hash (@{$aoh}) {
            my $name = $m_oDatabase->fetch_string("select name from cats where id = ?",
                                                  $catstring .= $hash->{categoryId});
            push @cats, $name;
        }
        my $cat = join('|', @cats);
        $cat = $cat =~ /^$/ ? 'draft' : $cat;
        $m_oDatabase->void("update news Set cat =? where id = ? && `right` <= $m_nRight",
                           $cat, $postid);
        return \@m_aRecentPost;
    } else {
        return 0;
    }
}

sub getPost {
    my $postid   = shift;
    my $username = shift;
    my $password = shift;
    $postid = $postid =~ /(\d+)/ ? $1 : 1;
    if (checkPassword($username, $password)) {
        my $sql    = ("select *from news where id = $postid && `right` <= $m_nRight");
        my $ref    = $m_oDatabase->fetch_hashref($sql);
        my @select = split /\|/, $ref->{cat};
        my $struct = {
                      postid      => $ref->{id},
                      dateCreated => $ref->{id},
                      title       => $ref->{title},
                      description => $ref->{body},
                      categories  => [@select],
                      publish     => $ref->{cat} =~ /draft/ ? 1 : 0,
                     };
        return \$struct;
    } else {

        return 0;
    }

}

sub getRecentPostTitles {
    my $blogid        = shift;
    my $username      = shift;
    my $password      = shift;
    my $numberOfPosts = shift;
    $numberOfPosts = $numberOfPosts =~ /(\d+)/ ? $1 : 10;
    if (checkPassword($username, $password)) {
        my $sql =
          ("select *from news  where `right` <= $m_nRight order by date desc LIMIT 0,$numberOfPosts"
          );
        my @ref = $m_oDatabase->fetch_AoH($sql);
        for (my $i = 0 ; $i <= $#ref ; $i++) {
            push @m_aRecentPost,
              {
                postid      => $ref[$i]->{id},
                dateCreated => $ref[$i]->{id},
                title       => $ref[$i]->{title},
                userid      => $blogid
              };
        }
    }
    return \@m_aRecentPost;
}

sub getRecentPosts {
    my $blogid        = shift;
    my $username      = shift;
    my $password      = shift;
    my $numberOfPosts = shift;
    $numberOfPosts = $numberOfPosts =~ /(\d+)/ ? $1 : 10;
    if (checkPassword($username, $password)) {
        my $sql =
          ("select *from news  where `right` <= $m_nRight order by date desc LIMIT 0,$numberOfPosts"
          );
        my @ref = $m_oDatabase->fetch_AoH($sql);
        for (my $i = 0 ; $i <= $#ref ; $i++) {
            my @select = split /\|/, $ref[$i]->{cat};
            push @m_aRecentPost,
              {
                postid      => $ref[$i]->{id},
                dateCreated => $ref[$i]->{id},
                title       => $ref[$i]->{title},
                description => $ref[$i]->{body},
                categories  => [@select],
                publish     => $ref[$i]->{cat} =~ /draft/ ? 1 : 0,
              };
        }
    }
    return \@m_aRecentPost;
}

sub getCategoryList {
    my $blogid   = shift;
    my $username = shift;
    my $password = shift;
    if (checkPassword($username, $password)) {
        my $blogid   = shift;
        my $username = shift;
        my $password = shift;
        my $sql      = ("select *from cats where `right` <= $m_nRight");
        my @ref      = $m_oDatabase->fetch_AoH($sql);
        for (my $i = 0 ; $i <= $#ref ; $i++) {
            push @m_aCatlist,
              {
                categoryId   => $ref[$i]->{id},
                categoryName => $ref[$i]->{name}
              };
        }
        return \@m_aCatlist;
    } else {
        return 0;
    }
}

sub checkPassword {
    my $username = shift;
    my $password = shift;
    use MD5;
    my $md5 = new MD5;
    $md5->add($username);
    $md5->add($password);
    my $cyrptpass = $md5->hexdigest();
    $m_nRight = $m_oDatabase->userright($username);

    if ($m_nRight >= $m_hrSettings->{news}{right}) {
        return $m_oDatabase->checkPass($username, $cyrptpass);
    } else {
        return 0;
    }
}

sub newPost {
    my $blogid   = shift;
    my $username = shift;
    my $password = shift;
    my $content  = shift;
    my $bpublish = shift;

    if (checkPassword($username, $password)) {
        my $cats = join('|', @{$content->{categories}});
        $cats = $cats =~ /^$/ ? 'draft' : $cats;
        my %message = (
                       title  => $content->{title},
                       body   => $content->{description},
                       thread => 'news',
                       cat    => $bpublish->value ? $cats : 'draft',
                       attach => '',
                       format => 'html',
                       user   => $username,
                       attach => '',
                       ip     => $ENV{REMOTE_ADDR},
                      );
        return $m_oDatabase->addMessage(\%message);
    } else {
        return 0;
    }
}

sub getUsersBlogs {
    my $appkey   = shift;
    my $username = shift;
    my $password = shift;
    if (checkPassword($username, $password)) {
        return \@m_aUsersBlogs;
    } else {
        return 0;
    }
}

sub editPost {
    my $postid   = shift;
    my $username = shift;
    my $password = shift;
    my $content  = shift;
    my $bpublish = shift;
    if (checkPassword($username, $password)) {
        my $cats = join('|', @{$content->{categories}});
        $cats = $cats =~ /^$/ ? 'draft' : $cats;
        my %message = (

            title => $content->{title},

            body => $content->{description},

            thread => 'news',

            cat => $bpublish->value ? $cats : 'draft',

            attach => '',

            format => 'html',

            user => $username,

            attach => '',

            ip => $ENV{REMOTE_ADDR},

            id => $postid,

        );
        $m_oDatabase->editMessage(\%message);
    }
}

sub getTemplate {
    return 0;
}

sub setTemplate {
    return 0;
}

sub supportedTextFilters {
    return 0;
}

sub getUserInfo {
    my $struct = {
                  userid    => 123,
                  firstname => $m_hrSettings->{admin}{firstname},
                  lastname  => $m_hrSettings->{admin}{name},
                  nickname  => $m_hrSettings->{admin}{name},
                  email     => $m_hrSettings->{admin}{email},
                  url       => $m_hrSettings->{cgi}{serverName}
                 };
    return \$struct;
}
print "Content-type: text/xml$/$/";
$m_sXml .= $_ while (<STDIN>);
print $m_oRpc->serve($m_sXml, $m_hrSubs) . $/;

1;
