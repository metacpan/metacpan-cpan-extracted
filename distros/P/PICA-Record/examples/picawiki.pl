#!/usr/bin/perl

=head1 NAME 

PICA+Wiki - Wiki interface to a L<PICA::Store> of PICA+ records

=head1 DESCRIPTION

This is just a proof of concept and needs a major rewrite. To try
out, create a file picawiki.conf point with SQLite=sqlitefile.db 
to a file that is writeable to your webserver.

=cut


#use lib "../lib";

use CGI qw/:standard :form/;
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use URI::Escape;
use PICA::Record;
use PICA::SQLiteStore;
use Data::Dumper;
use File::Basename;
use Cwd qw(abs_path);

# TODO: error handling if this fails (installation)
# TODO: add wsdl and soap files

my $store = eval { PICA::SQLiteStore->new( config => "picawiki.conf" ); };
my $error = $@;

my $PICAWIKI_VERSION = "0.1.0";

my $baseurl = url(-full => 0);
my $title = "PICA+Wiki"; 
my $ppn = param('ppn');
my $cmd = param('cmd');
my $record = param('record');
my $version = param('version');
my $submit = param('submit');
my $cancel = param('cancel');

my $offset = param('offset') || 0;
my $limit = param('limit') || 30;

my $user = $ENV{REMOTE_ADDR} or "0";
$store->access( userkey => $user ) if defined $user;

my $c_user = param('user');
$cmd = 'contributions' if defined $c_user and not $cmd;

$cmd = '' if ($error);

print header({type => 'text/html', charset => 'utf-8'});
print start_html(
    -encoding => 'utf-8',
    -style=> 'picawiki.css',
    title=>$title,
);

#print pre( { class => 'debug' }, "hallo" );
#print $baseurl;

print "<div id='page-base' class='noprint'></div>\n";
print "<div id='head-base' class='noprint'></div>\n";
print "<div id='content'>\n";
print "<a id='top' name='top'></a>\n";
print "<div id='bodyContent'>\n";

# cancel action
if ($cancel) {
    if ($cmd eq 'editrecord') {
        $cmd = 'viewrecord'; $version = 0;
    }
    # TODO: redirect to get HTTP GET (?)
}
$cmd = 'viewrecord' if ( ($ppn or $version) and not $cmd);
$cmd = '' if $cmd eq 'viewrecord' and not ($ppn or $version); 

if ($cmd eq 'editrecord' && $submit) {
    # TODO: nicht wenn version fehlt
    $record =~ s/\t/ /g;
    $record =~ s/ +/ /g;
    my $pprecord = eval { PICA::Record->new( $record ); };
    $pprecord = 0 if $pprecord && $pprecord->is_empty;
    if ($pprecord) {
        my %result = ();
        if ($ppn) {
            %result = $store->update( $ppn, $pprecord, $version );
        } else {
#print "CREATE: " . $pprecord->to_string();
            %result = $store->create( $pprecord );
        }
        if (%result) {
            if ($result{id}) {
                $ppn = $result{id};
                $cmd = 'viewrecord';
            } else {
                $error = "ERROR: " . $result{errormessage};
            }
            $version = $result{version};
        } else {
            $error = "Fehler beim Speichern des Datensatz";
        }
    } else {
        $error = $@ ? $@ : "Der Datensatz ist kein PICA+";
    }
}

if ($cmd eq 'newrecord') {
    $record = "";
    $version = "";
    $cmd = "editrecord";
} 

#if ($version && !$cmd) {
#    $cmd = 'viewrecord';
#}

if ($cmd eq 'viewrecord') {
    my %recorddata;
    if ($version) {
        %recorddata = $store->get( $ppn, $version );
    } elsif ($ppn) {
        %recorddata = $store->get( $ppn );
    }
    if ($recorddata{id}) {
        $ppn = $recorddata{id};
        $record = $recorddata{record}->to_string;
        $version = $recorddata{version};
        $timestamp = $recorddata{timestamp};
        $latest = $recorddata{latest};
    } else {
        $error = "Failed to get record $ppn version $version";
        $cmd = "";
    }
}

print div({class=>'error'},$error) if $error;


sub version_line {
    my ($line, $item) = @_;

    my %del = $item->{deleted} ? (class=>'deleted') : ();
    
    if ($line =~ /{TIMESTAMP_LINK}/) {
        my $timestamp = a( { href=>"$baseurl?version=" . $item->{version}, %del }, $item->{timestamp} );
        $line =~ s/{TIMESTAMP_LINK}/$timestamp/g;
    }
    if ($line =~ /{PPN_LINK}/) {
        my $link = a( { href=>"$baseurl?ppn=" . $item->{ppn}, , %del }, "Datensatz " . $item->{ppn} );
        $line =~ s/{PPN_LINK}/$link/g;
    }
    if ($line =~ /{IS_NEW}/) {
        my $new = $item->{is_new} ? ' <b>neu</b> ' : '';
        $line =~ s/{IS_NEW}/$is_new/g;
    }
    if ($line =~ /{IS_DELETED}/) {
        my $text = $item->{deleted} ? ' <b>gelöscht</b> ' : '';
        $line =~ s/{IS_DELETED}/$text/g;
    }
    if ($line =~ /{BY_USER}/) {
        my $by_user = " von " . a({ href=>"$baseurl?user=".$item->{user} }, $item->{user});
        $by_user = '' if not $item->{user};
        $line =~ s/{BY_USER}/$by_user/g;
    }
    $line = "<li>$line</li>";
    return $line;
}


if ($cmd eq 'editrecord') {
    my %rec;
    if ($ppn and not $version) {
        my %rec = $store->get( $ppn ); # TODO: vorher machen, und wenn nicht vorhanden: fehler
        $record = $rec{record}->to_string;
        $version = $rec{version};
    }
    print h2( $ppn ? "Datensatz $ppn bearbeiten" : "Datensatz anlegen" );
    print "Version $version" if $version;
    print start_form( { action=>$baseurl, method=>'post' } );
    print input( {type=>'hidden', name=>'cmd', value=>'editrecord'} );
    print input( {type=>'hidden', name=>'ppn', value=>$ppn} );
    print input( {type=>'hidden', name=>'version', value=>$version} );
    print textarea( { name=>'record', style=>'width:100%', rows=>25, cols=>80, value=>$record } );
    print br,
        input( { type=>'submit', name=>'submit', value=>($ppn?'Speichern':'Anlegen') } ),
        input( { type=>'submit', name=>'cancel', value=>'Abbrechen' } );
    print end_form;

} elsif($cmd eq 'viewrecord') {
    print h2("Datensatz $ppn");
    if ($version) {
        my $prevnext = $store->prevnext($ppn, $version, 1);
        my @pn = sort keys %$prevnext;
        my $n = shift @pn;
        if ($n && $n < $version) {
            print a({href=>"$baseurl?version=".$n}, " \x{2190} " );
            $n = shift @pn;
        }
        print "Version id $version ";
        print " ($timestamp)" if $timestamp;
        if ($n && $n > $version) {
            print a({href=>"$baseurl?version=".$n}, " \x{2192} ");
        }
        # TODO: add user
        if ($latest && $version < $latest) {
            print " Von diesem Datensatz existiert eine " 
                  . a({href=>"$baseurl?ppn=$ppn"}, "aktuelle Version") . "!";
        }
    }

    print pre($record);
    print div(a({href=>"$baseurl?cmd=editrecord&ppn=$ppn"}, "Bearbeiten"));
    #print div(a({href=>"$baseurl?cmd=deleterecord&ppn=$ppn"}, "Löschen"));

} elsif ($cmd eq 'history' and $ppn) {
    print h2("Versionen von Datensatz $ppn");
    $history = $store->history($ppn, $offset, $limit);
    print "<ul>";
    foreach my $item (@$history) {
        print version_line('{TIMESTAMP_LINK} {IS_NEW}{IS_DELETED} {BY_USER}', $item);
    }
    print "</ul>";
    # print Dumper($history);
} elsif ($cmd eq 'contributions') {
    print h2("Bearbeitungen von $c_user");
    $revisions = $store->contributions($c_user, $offset, $limit);
    print div("Es liegen keine Bearbeitungen dieses Accounts vor.") unless @$revisions;
    print "<ul>";
    foreach my $item (@$revisions) {
        print "<li>";
        print a( { href=>"$baseurl?version=" . $item->{version} }, $item->{timestamp} );
        print " ";
        print a( { href=>"$baseurl?ppn=" . $item->{ppn} }, "Datensatz " . $item->{ppn} );
        print " <b>neu</b>" if ($item->{is_new});
        print " <b>gelöscht</b>" if ($item->{deleted});
        print "</li>";
    }
    print "</ul>";    
} elsif ($cmd eq 'recentchanges') {
    print h2("Letzte Änderungen");
    $rc = $store->recentchanges($offset, $limit);
    if (!@$rc) {
        print div("Es liegen keine Änderungen vor.");
    }
    print "<ul>"; # TODO: Gelöschte Datensätze markieren!
    foreach my $item (@$rc) {
        print version_line('{TIMESTAMP_LINK} {PPN_LINK} {IS_NEW}{IS_DELETED} {BY_USER}', $item);
    }
    print "</ul>";
    # print Dumper($rc);    
} elsif ($cmd eq 'stats') {
    print h2("Statistik");
    my %stats = getStats();
    print '<div>';
    print '<dl>';
    print map { dt($_) . dd($stats{$_}); } (keys %stats);
    print '</dl>';
    print '</div>';
} elsif ($cmd eq 'deleted') {
    print h2("Gelöschte Datensätze");
    my $del = $store->deletions($offset, $limit);
    if (@$del) {
        print "<ul>";
        foreach my $item (@$del) {
            print version_line('{TIMESTAMP_LINK} {PPN_LINK} {IS_NEW}{IS_DELETED} {BY_USER}', $item);
        }
        print "</ul>";
    } else {
        print "Es liegen keine gelöschten Datensätze vor.";
    }
} else { # startseite
    print h2("$title");
    print "<div>";
    print "Herzlich Willkommen zur ersten Demo des PICAWiki. Hier können Datensätze im ";
    print a({href=>"http://www.gbv.de/wikis/cls/PicaPlus"},"PICA+ Format") . " angelegt und bearbeitet werden.";
    print "</div>";
    #if (!$store) {
    #print div("Bitte lesen Sie sich die Installationsanweisung durch!");
    #}
}

print "</div>";
print "</div><!-- content -->\n";
print "<div id='head' class='noprint'>\n";

print div({id=>'title'}, h1($title) ) . "\n";
print div({id=>'personal'}, span($user));

print "<div id='left-navigation'>";
if ($ppn) {
    print "<ul>";
    print "<li><a href='$baseurl?ppn=$ppn'><span>Datensatz</span></a></li>";
    print "<li><a href='$baseurl?cmd=history&ppn=$ppn'><span>Versionen</span></a></li>";
    print "</ul>";
}
print "</div>\n";
print "</div> <!-- head -->";
print "<div id='panel' class='noprint'>\n";

my @panel = (
  'Navigation', [
      $baseurl, 'Startseite',
      "$baseurl?cmd=recentchanges", 'Letzte Änderungen',
     # "$baseurl?cmd=listrecords", 'Alle Datensätze'
  ],
  'Werkzeuge', [
      "$baseurl?cmd=newrecord", 'Neuer Datensatz',
      "$baseurl?cmd=stats", 'Statistik',
      "$baseurl?cmd=deleted", 'Löschlog'
  ]
);
for(my $i=0; $i<@panel; $i+=2) {
    my @list = @{$panel[$i+1]};
    print '<div class="portal">' . h5($panel[$i]) . '<div><ul>';
    for(my $j=0; $j<@list; $j+=2) {
        print li(a({href=>$list[$j]},$list[$j+1]));
    }
    print '</ul></div></div>';
}
print "</div> <!-- panel -->\n";

print "<div class='break'/>\n";
print "<div id='foot'><!-- footer --></div>\n";
print end_html;


sub getStats {
    my %stat;

    #my @s = stat($dbfile);
    #$stat{dbfilename} = $dbfile;
    #$stat{dbfilesize} = $s[7];
    #$stat{dbfilemtime} = $s[9];
    #$stat{wikiversion} = $PICAWIKI_VERSION;

    return %stat;    
}

=head1 SEEALSO

HTML and CSS design is adopted from the MediaWiki Vector theme.

=cut

__END__

TODO: 
- allow to query raw PICA via same URL-parameters as PSI and via unAPI
- add SOAP server to emulate CBS Webcat

