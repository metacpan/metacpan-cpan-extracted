#!/usr/local/bin/perl

use warnings;
use strict;
use sigtrap die => 'normal-signals';
use CGI;
use OpenGuides::Config;
use OpenGuides::Template;
use OpenGuides::Utils;
use URI::Escape;

my @badchars = qw( & ? _ );
push @badchars, '#'; # Avoid warning about possible comments in qw()

my $q = CGI->new;
my $config_file = $ENV{OPENGUIDES_CONFIG_FILE} || "wiki.conf";
my $config = OpenGuides::Config->new( file => $config_file );
my $wiki = OpenGuides::Utils->make_wiki_object( config => $config );

my $pagename = $q->param("pagename") || "";
$pagename =~ s/^\s*//;
$pagename =~ s/\s*$//;

my $action = $q->param("action") || "";

if ( $action eq "makepage" ) {
    make_page();
} else {
    show_form();
}

sub show_form {
    print OpenGuides::Template->output( wiki     => $wiki,
					config   => $config,
					template => "newpage.tt",
					vars     => {
                                            not_editable     => 1,
                                            not_deletable    => 1,
                                            deter_robots     => 1,
                                            disallowed_chars => \@badchars,
                                            pagename         => $pagename,
                                            read_only        => $config->read_only,
                                }
    );
}

sub make_page {
    # Ensure pagename not blank.
    unless ( $pagename ) {
        print OpenGuides::Template->output(
            wiki     => $wiki,
	    config   => $config,
	    template => "error.tt",
	    vars     => { not_editable  => 1,
                          not_deletable => 1,
                          deter_robots  => 1,
			  message       => "Please enter a page name!",
			  return_url    => "newpage.cgi" } );
        return 0;
    }

    # Ensure pagename valid.
    my %badhash = map { $_ => 1 } @badchars;
    my @naughty;
    foreach my $i ( 0 .. (length $pagename) - 1 ) {
        my $char = substr( $pagename, $i, 1 );
        push @naughty, $char if $badhash{$char};
    }
    if ( scalar @naughty ) {
        my $message = "Page name $pagename contains disallowed characters";
        print OpenGuides::Template->output(
            wiki     => $wiki,
	    config   => $config,
	    template => "error.tt",
	    vars     => {
                pagename     => $pagename,
                not_editable => 1,
                not_deletable => 1,
                deter_robots => 1,
		message      => $message,
		return_url   => "newpage.cgi?pagename=" . uri_escape($pagename)
            }
        );
        return 0;
    }

    # Hurrah, we're OK.
    my $node_param = $wiki->formatter->node_name_to_node_param($pagename);
    print "Location: ".$config->script_url.$config->script_name."?action=edit;id=$node_param\n\n";
    return 0;
}


