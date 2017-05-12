
use utf8;
use v5.10.0;
use strict;

package inc::MY::Build::Changes;

require DateTime;


sub build
{
    my $self = shift;
    my %args = @_;
    my $input = 'Changes';
    my $Changes_dt = DateTime->from_epoch(epoch => (stat $input)[9], time_zone => 'local');
    my $Changes = $self->parse($input);

    #use Data::Dumper;
    #print Dumper(\%Changes), "\n";

    $self->write_YAML("$input.yml", $Changes, %args, last_update => $Changes_dt);
    utime $Changes_dt->epoch, $Changes_dt->epoch, "$input.yml";
    $self->write_RSS("$input.rss", $Changes, %args, last_update => $Changes_dt);
    utime $Changes_dt->epoch, $Changes_dt->epoch, "$input.rss";
}


sub parse
{
    my $self = shift;
    my $input_file = shift;

    my $Changes = do {
	# See http://rt.cpan.org/Ticket/Display.html?id=54819#txn-736810
	#open my $fd, "<:utf8", $input_file;
	open my $fd, "<:raw", $input_file;
	local $/ = undef;
	<$fd>;
    };


    #print $Changes;

    my $parser = do {
	use Regexp::Grammars;
	qr{

  \A
  \R*
  <Header>
  <[Releases=Release]>+

  (?:
           # Should be at end of input...
            \Z
          |
           # If not, report the fact but don't fail...
            <warning: Expected end-of-input>
            <warning: (?{ "Extra junk at index $INDEX: $CONTEXT" })>
  )
  <MATCH=(?{ delete $MATCH{'!'}; {%MATCH} })>


<token: Header>
  \S \V+ (?: \R \V+ )*

<token: Release>
  \R+
  <Version> \h+ <DateTime> \h+ <Author_Id> \h+ \( <Author_Name> \) \R
  <[Changes]>+
  <MATCH=(?{ delete $MATCH{'!'}; {%MATCH} })>

<token: Version>
  \d+ \. \d+ (?: _ \d+ )?

<token: DateTime>
  ( <.Date> (?: T <.Time> <.TimeZone>? )? )

<token: Date>
  \d{4}-\d{2}-\d{2}

<token: Time>
  (\d{2}:\d{2})
  <MATCH=(?{ $CAPTURE.":00" })>

<token: TimeZone>
  Z | [+-]\d{2}:\d{2}

<token: Author_Id>
  \w+

<token: Author_Name>
  [^)]+

<token: Changes>
  (?:\t|[ ]{8}) (\S\V*) \R           (?{ $MATCH = $CAPTURE })
  (?:
    (?:\t[ ]{2}|\h{10}) \h* (\V+) \R (?{ $MATCH .= " ".$CAPTURE })
  )*

<token: ChangesIdent1>

    }xms;
};

    $Changes =~ $parser or die "format invalide !\n";
    my %Changes = %{$/{'='}};


    use Data::Recursive::Encode;
    # Workaround for the Perl crash: we decode UTF-8 after matching with R::G
    # http://rt.perl.org/rt3//Public/Bug/Display.html?id=72996
    %Changes = %{ Data::Recursive::Encode->decode_utf8(\%Changes, Encode::FB_WARN) };


    return \%Changes;
}


use YAML 0.71 ();

sub write_YAML
{
    my $self = shift;
    my $output_file = shift;
    my $Changes = shift;
    my %args = @_;

    #print YAML::Dump(\%Changes), "\n";
    YAML::DumpFile($output_file, $Changes);
}


use XML::RSS;
use DateTime::Format::W3CDTF;

sub write_RSS
{
    my $self = shift;
    my $output_file = shift;
    my %Changes = %{ (shift) };
    my %args = @_;
    my $dist = $args{dist_name};
    my $lastUpdate = $args{last_update};

    my $rss = XML::RSS->new(version => '1.0');

    $rss->channel(
	title => "$dist releases",
	description => $Changes{'Header'},
	(map { $_ => "http://search.cpan.org/dist/$dist/" } qw/about link/),
	dc => {
	    date => DateTime::Format::W3CDTF->new->format_datetime($lastUpdate),
	    creator => "$Changes{Releases}[0]{Author_Name} <".lc($Changes{Releases}[0]{Author_Id}).'@cpan.org>',
	    language => 'en-us',
	},
	syn => {
	    updatePeriod => 'weekly',
	},
	taxo => [
	    'http://dmoz.org/Computers/Programming/Languages/Perl/'
	],
    );




    sub changes_html
    {
	my $h = "<ul>\n".join('', map {"<li>$_</li>\n"} @_).'</ul>';
	$h =~ s{(RT#(\d+))}{<a href="https://rt.cpan.org/Public/Bug/Display.html?id=$2" title="Bug $1">$1</a>}g;
	$h
    }



    for my $r (@{$Changes{'Releases'}}) {
	my $link = 'http://search.cpan.org/~'.lc($r->{Author_Id})."/$dist-$r->{Version}/";
	$rss->add_item(
	    title => "$dist $r->{Version}",
	    about => $link,
	    link => $link,
	    description => changes_html(@{$r->{Changes}}),
	    dc => {
		creator => "$r->{Author_Name} <".lc($r->{Author_Id}).'@cpan.org>',
		date => "$r->{DateTime}",
	    }
	);
    }

    open my $Changes_rss, '>:utf8', $output_file;
    print $Changes_rss $rss->as_string;
    close $Changes_rss;
}
