use utf8;
use warnings;
no warnings 'redefine';
use XML::RSS;
use CGI qw(:all);
use vars qw(@content $content $url);
$url = param('url');
if ( defined $url ) {
    $url = $url =~ /(\d+)/ ? $1 : 1;
    my @o = $m_oDatabase->fetch_array( "select url from blogs where id = ? && `right` <= ?", $url, $m_nRight );
    $url = $o[0] ? $o[0] : $url;
    my $rss = new XML::RSS;
    use LWP::UserAgent;
    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    $ua->agent('cms_rssget');
    my $time     = localtime;
    my $response = $ua->get($url);

    if ( $response->is_success ) {
        $content = $response->content;
        $rss->parse($content);
    } else {
        warn "Konnte $url nicht downloaden $!";
    } ## end else [ if ( $response->is_success)]
    use HTML::Entities;
    utf8::encode( $rss->{'channel'}->{'title'} );
    push @content,
      '<table border="0" width="100%"><tr><td><table cellspacing="0" cellspacing="0"><tr><td><b><a href="',
      encode_entities( $rss->{'channel'}->{'link'}, '<>&' ), '" target="_blank">',
      encode_entities( $rss->{'channel'}->{'title'}, '<>&' ),
      '</a></b></td></tr><tr><td>';
    if ( $rss->{'image'}->{'link'} ) {
        push @content, '<div align="center"><p><a href="',
          encode_entities( $rss->{'image'}->{'link'}, '<>&' ), '" target="_blank"><img src="',
          $rss->{'image'}->{'url'}, '" alt="', encode_entities( $rss->{'image'}->{'title'}, '<>&' ),
          '" border="0" ';
        push @content, " width=\"$rss->{'image'}->{'width'}\" "   if ( $rss->{'image'}->{'width'} );
        push @content, " height=\"$rss->{'image'}->{'height'}\" " if ( $rss->{'image'}->{'height'} );
        push @content, '/></a></div><p>';
    } ## end if ( $rss->{'image'}->...)
    foreach my $item ( @{ $rss->{'items'} } ) {
        next unless defined( $item->{'title'} ) && defined( $item->{'link'} );
        utf8::encode( $item->{'title'} );
        utf8::encode( $item->{'description'} );
        if ( defined $item->{'link'} ) {
            push @content, '<img src="/style/' . $m_sStyle . '/buttons/rss.png" alt=""/><a href="',
              encode_entities( $item->{'link'}, '<>&' ), '" target="_blank" style="color:black;">',
              $item->{'title'}, '</a><br/>' . $item->{'description'} . '<br/>';
        } elsif ( $item->{'guid'} ) {
            push @content, '<img src="/style/' . $m_sStyle . '/buttons/rss.png" alt=""/><a href="',
              encode_entities( $item->{'guid'}, '<>&' ), '" target="_blank" style="color:black;">',
              $item->{'title'}, '</a><br/>' . $item->{'description'} . '<br/>';
        } ## end elsif ( $item->{'guid'} )
    } ## end foreach my $item ( @{ $rss->...})
    if ( $rss->{'textinput'}->{'title'} ) {
        push @content, '<form method="get" action="',
          $rss->{'textinput'}->{'link'}, '">',
          $rss->{'textinput'}->{'description'},
          '<br/><input type="text" name="', $rss->{'textinput'}->{'name'},
          '><br/><input type="submit" value="',
          $rss->{'textinput'}->{'title'}, '"></form>';
    } ## end if ( $rss->{'textinput'...})
    if ( $rss->{'channel'}->{'copyright'} ) {
        push @content, '<p>', encode_entities( $rss->{'channel'}->{'copyright'} ), '</p>';
    } ## end if ( $rss->{'channel'}...)
    push @content, qq(</td></tr></table></td></tr></table><A href="$url"><img border="0" align="right" src="../images/rss.png" alt=""/></a>);
    print '<div align="ShowTables">';
    print br();
    print "@content";
    print br() . '</div>';
    undef @content;
    undef $content;
    undef $url;
} else {    #alle feeds anzeigen
    my @menu = $m_oDatabase->fetch_AoH( 'select id,name from blogs  where `right` <= ? order by id', $m_nRight );
    my @ret;
    for ( my $i = 0 ; $i <= $#menu ; $i++ ) {
        use HTML::Entities;
        my $url = "requestURI('$ENV{SCRIPT_NAME}?action=viewrss&url=$menu[$i]->{id}','feeds','feeds')";
        push @ret,
          {
            text    => $menu[$i]->{name},
            onclick => $url,
          };
    } ## end for ( my $i = 0 ; $i <=...)
    my $blogs = "requestURI('$ENV{SCRIPT_NAME}?action=viewrss','feeds','feeds')";
    my @t     = (
        {
            text    => 'Rss feeds',
            onclick => $blogs,
            subtree => [@ret]
        }
    );
    print '<tr id="trwwblogs"><td valign="top" class="sidebar">';
    print Tree( \@t, $m_sStyle );
    print '<br/></td></tr>';
    @menu     = undef;
    @t        = undef;
    $treeview = undef;
} ## end else [ if ( defined $url ) ]
1;
