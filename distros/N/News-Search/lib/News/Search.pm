package News::Search;

use warnings;
use strict;

# @Author: Tong SUN, (c)2001-2008, all right reserved
# @Version: $Date: 2008/11/04 17:19:30 $ $Revision: 1.15 $
# @HomeURL: http://xpt.sourceforge.net/

# {{{ LICENSE: 

# 
# Permission to use, copy, modify, and distribute this software and its
# documentation for any purpose and without fee is hereby granted, provided
# that the above copyright notices appear in all copies and that both those
# copyright notices and this permission notice appear in supporting
# documentation, and that the names of author not be used in advertising or
# publicity pertaining to distribution of the software without specific,
# written prior permission.  Tong Sun makes no representations about the
# suitability of this software for any purpose.  It is provided "as is"
# without express or implied warranty.
#
# TONG SUN DISCLAIM ALL WARRANTIES WITH REGARD TO THIS SOFTWARE, INCLUDING ALL
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS, IN NO EVENT SHALL ADOBE
# SYSTEMS INCORPORATED AND DIGITAL EQUIPMENT CORPORATION BE LIABLE FOR ANY
# SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER
# RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF
# CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
# CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# 

# }}} 

# {{{ POD, Intro:

=head1 NAME

News::Search - Usenet news searching toolkit

=head1 SYNOPSIS

  use News::Search;

  my $ns = News::Search->new();
  $ns->search_for(\@ARGV);

  my %newsarticles = $ns->SearchNewsgroups;

=head1 DESCRIPTION

News::Search searches Usenet news postings.

It can be used to search local news groups that google doesn't cover.
Or, even for news groups that are covered by google, it can give you
all the hits in one file, in the format that you prescribed.

You can also use the provided L<news-search> in cron to watch specific
news groups for specific criteria and mail you reports according to the
interval you set.

=cut

# }}}

# {{{ Global Declaration:

# ============================================================== &us ===
# ............................................................. Uses ...

# -- global modules
use Carp;
use Net::NNTP;

use base qw(Class::Accessor::Fast);

# ============================================================== &cs ===
# ................................................. Constant setting ...
#

our @EXPORT = (  ); # may even omit this line
our $VERSION = sprintf("%d.%02d", q$Revision: 1.15 $ =~ /(\d+)\.(\d+)/);

# }}} 

# ############################################################## &ss ###
# ................................................ Subroutions start ...

=head1 METHODS

=head2 News::Search->new(\%config_param)

Initialize the object.

  my $searcher = News::Search->new();

or,

  my $searcher = News::Search->new( {} );

which are the same as:

  my $searcher = News::Search->new( {
     nntp_server => 'news',
     msg_headers => 'Date|From',	# + Subject, which is always printed
     msg_limit	 => 200,
     verbose 	 => 0,
     on_group    => \&default_group_handler,
     on_message  => \&default_message_handler,
  } );

What shown above are default settings. Any of the C<%config_param> attribute can be omitted when calling the new method.

The C<new> is the only class method. All the rest methods are object methods.

=cut

News::Search->mk_accessors(qw(nntp_server msg_headers msg_limit verbose
	on_group on_message nntp_handle newsgroups nntp_query));

my %config =
    (
     nntp_server => 'news',
     msg_headers => 'Date|From',	# + Subject, which is always printed
     msg_limit	 => 200,
     verbose 	 => 0,
     on_group    => \&default_group_handler,
     on_message  => \&default_message_handler,
 );

my $verbose;

sub new {
    my ($class, $arg_ref) = @_;
    my $self = $class->SUPER::new({%config, %$arg_ref});

    $verbose = $self->verbose;

    return $self;
}

=head2 Object attributes

The following object attributes are accessible.

=over 4

=item * nntp_server([set_val])

The nntp server to search.

=item * msg_headers([set_val])

Message headers to print.

=item * msg_limit([set_val])

Maximum number of posts to search (not return).

=item * verbose([set_val])

Be verbose.

=item * on_group([set_val])

Handler for group starts. Refer to L<news-search> for the example.

=item * on_message([set_val])

Handler for news message. Refer to L<news-search> for the example.

=back

Provide the C<set_val> to change the attribute, omitting it to retrieve the attribute value. E.g.,

  $searcher->nntp_server("news.easysw.com");

=head2 Object method: search_for($array_ref)

  $searcher->search_for(\@ARGV);

Command line parameter handling. Refer to L<news-search>
section "command line arguments" for details.

=cut

sub search_for {
    my ($self, $array_ref) = @_;

    my $nntp_server;
    $nntp_server = $self->nntp_server;
    $nntp_server = $ENV{"NNTPSERVER"} if $ENV{"NNTPSERVER"};

    my $nntp;
    if (defined($ENV{DEBUG}) && $ENV{DEBUG} eq "1") {
	$nntp = Net::NNTP->new($nntp_server, Debug=>'On', Timeout=>10) ||
	   croak  "Cant connect to News Server: $@";
    } else {
	$nntp = Net::NNTP->new($nntp_server) ||
	    croak "Cant connect to News Server: $@";
    }

    my @newsgroups;
    my %args;

    foreach (@$array_ref) {
	if (/=/) {
	    # key/value pair
	    my ($name, $value) = split(/=/);
	    $name = lc $name;
	    $args{$name} = $value;
	} else {
	    # group name
	    my $ngname = $_;
	    if (index($ngname, "\*") > -1) {
		# have wildcard (*) in group name.
		my $nntplist = $nntp->list() || die "Cannot list newsgroups";
		$ngname =~ s/\*/.*/g;
		foreach (sort(keys(%$nntplist))) {
		    if (/$ngname/) {
			push(@newsgroups, $_);
		    }
		}
	    } else {
		push(@newsgroups, $ngname);
	    }
	}
    }

    print STDERR "Searching the top ". $self->msg_limit. " messages "
	. " in newsgroups: @newsgroups...\n\n"
	    if $verbose;

    $self->nntp_handle($nntp);
    $self->newsgroups(\@newsgroups);
    $self->nntp_query(\%args);

}

# default handler for group starts ...
sub default_group_handler {
    my $newsgroup = shift;
    #print STDERR "\n\nSearching group '$newsgroup'\n\n";
}

# default handler for news message ...
sub default_message_handler {
    print STDERR "." if $verbose;
}

sub dbg_msg {
    my $show_msg = shift;
    my $show_level = shift;

    $show_level = 1 unless $show_level;
    return unless $verbose >= $show_level;
    warn "[News::Search] $show_msg\n";
}

=head2 Object method: SearchNewsgroups()

Search the given newsgroups with the given criteria:

  my %newsarticles = $ns->SearchNewsgroups;

  foreach my $article (values %newsarticles) {
    # deal with  $article->{"SUBJECT"}, @{$article->{"HEADER"}})
    #  and $article->{"BODY"}
  }

Refer to L<news-search> for usage example.

=cut

sub SearchNewsgroups {
    my $self = shift;
    my ($newsgroups) = @_;
    $newsgroups = $self->{newsgroups} unless $newsgroups;

    my $nntp = $self->{nntp_handle};
    my $args = $self->{nntp_query};
    
    my %newsarticles;
    foreach my $newsgroup (@$newsgroups) {
	my ($first, $last) = ($nntp->group($newsgroup))[1,2];
	#warn "] $first => $last\n";
	if (($first == 0) && ($first == $last)) {
	    next;
	}

	$first = $last - $self->msg_limit if $last - $self->msg_limit > $first;
	#warn "] $first => $last\n" if $verbose;
	
	# == news article loop
	$self->{on_group}->($newsgroup);
	my $msg_headers = $self->msg_headers;
	for ($nntp->nntpstat($first);$nntp->next() || last;) {
	    my $msghead = $nntp->head();

	    unless(defined($msghead)){
		dbg_msg "No message head found";
		next;
	    }

	    # Ignore html postings
	    if(arrary_search("Content-Type: text/html",$msghead)){
		dbg_msg "html posting ignored (found in head)";
		next;
	    }
	    
	    my ($msgfound, $msgsubj, $msgfrom, $newsarticle) =
		SearchMessage($nntp, $msghead, $args);
	    next unless $msgfound;
	    
	    $self->{on_message}->($newsgroup, $msghead, $newsarticle);

	    # Ignore html postings
	    if($newsarticle =~ "Content-Type: text/html"){
		dbg_msg "html posting ignored (found in body)";
		next;
	    }
	    
	    # zap excessive spaces
	    $newsarticle =~ s/\n(\s*\n){2,}/\n\n/;
	    # eliminate duplicated posts
	    #$newsarticles{"$msgfrom $msgsubj"} =
	    $newsarticles{"$msgfrom"} =
	    {
		"SUBJECT" => $msgsubj,
		"HEADER" => [ grep(/^($msg_headers): /, @$msghead) ],
		#"BODY" =>  $newsarticle,
		"BODY" =>  $newsarticle
		};
	}
    }
    $nntp->quit();
    return %newsarticles;
}


# message search
sub SearchMessage($$$){
    my ($nntp, $msghead, $args, ) = @_;
    my $headmatched = my $bodymatched = 0;
    my $msgfrom = "nofrom";
    my $msgsubj = "nosubj";
    my $i = 0;

    # -- message head loop
    #warn "] @$msghead\n";
    foreach my $headline (@$msghead) {
	chomp($headline);
	$headline =~ /^([^:]+): /;
	my $argname = lc $1;
	my $argval = "$'";
	$msgfrom = $argval if ($argname eq 'from');
	$msgsubj = $argval if ($argname eq 'subject');
	# look for search patterns
	if (defined($args->{$argname})) {
	    $i++;
	    if ($argval =~ m/$args->{$argname}/i) {
		#warn "] <$args->{$argname}> $argname => $argval\n";
		$headmatched = 1;
	    }
	}
	# look for ignore patterns
	if (defined($args->{"no$argname"})) {
	    if ($argval =~ m/$args->{"no$argname"}/i) {
		return (0, undef, undef, undef);
	    }
	}
    }
    $msgsubj =~ s/^\w+: //; # remove re: fw:, etc
    #warn "] headmatched = $i\n";

    if ($i == 0 && defined($args->{"body"})){
	#warn "] search in the body only\n";
	$headmatched = 1;
    }

    my $msgbodyfh = $nntp->bodyfh() || Carp::shortmess
	"Can't get body filehandle of article\n";

    # get the whole body
    my $newsarticle = '';
    while (my $bodyline=<$msgbodyfh>) {
	$newsarticle .= $bodyline;
    }
    # Ignore html postings
    #next if $newsarticle =~ m{^Content-Type: text/html|Mississauga|Scarborough|Etobicoke}mi;

    if (defined($args->{"body"})) {
	if ($newsarticle =~ m/$args->{"body"}/i) {
	    $bodymatched = 1;
	}
    } else {
	# not searching the body
	$bodymatched = 1;
    }

    return ($headmatched == 1 && $bodymatched == 1,
	    $msgsubj, $msgfrom, $newsarticle);
}

sub arrary_search($$){
    my ($look_for, $arrary_ref) = @_;
    my $is_there = 0;
    foreach my $elt (@$arrary_ref) {
        if ($elt =~ /$look_for/) {
            $is_there = 1;
            last;
        }
    }
    return $is_there;
}

# {{{ POD, Appendixes:

=head1 SEE ALSO

L<Net::NNTP>.

=head1 BUGS

Please report any bugs or feature requests to C<bug-news-search at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=News-Search>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc News::Search


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=News-Search>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/News-Search>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/News-Search>

=item * Search CPAN

L<http://search.cpan.org/dist/News-Search/>

=back


=head1 AUTHOR

SUN, Tong C<< <suntong at cpan.org> >>
http://xpt.sourceforge.net/

=head1 COPYRIGHT

Copyright 2003-2008 Tong Sun, all rights reserved.

This program is released under the BSD license.

=cut

# }}}

1; # End of News::Search
