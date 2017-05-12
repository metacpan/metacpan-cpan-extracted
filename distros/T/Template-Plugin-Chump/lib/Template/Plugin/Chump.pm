package Template::Plugin::Chump;

use strict;
use Text::Chump;
use Template::Plugin::Filter;
use base qw(Template::Plugin::Filter);
use vars qw($VERSION $FILTER_NAME);

$VERSION = '1.3';
$FILTER_NAME = 'chump';


=pod

=head1 NAME

Template::Plugin::Chump - provides a Template Toolkit filter for Chump like syntax

=head1 SYNOPSIS

	[% USE Chump %]

	<html>
	<body>

	[% FILTER chump %]

	This will get turned into a clickable link
	http://something.com 

	This will turn the word 'foo' into a link to bar.com
	[foo|http://bar.com]

	This will get turned into an image link 
    +[http://foo.com/quux.jpg]

	This will get turned into an inline image with the label 'bar'
	+[bar|http://foo.com/quux.jpg]

    This will get turned into an image with the label 'bar' which 
    is a link to http://foobar.com
    +[bar|http://foobar.com|http://url.of.image.com/image.jpg]


	[% END %]

	And this will do what you expect
	[% somevar FILTER chump %]

	[% Chump.new_type('equal','=', subref,'rege+xp') %]
	[% FILTER chump %]
	=[foo|regeeeeexp]
	[% END %]
	the subroutine subref will now be called for all links 
    of the format =[<stuff>]

	[% FILTER chump( {links=>0}) %]
	links won't be parsed so this ...
	[foo|http://bar.com]
	will remain as is
	[% END %]	
	
	</body>
	</html>

Alternatively you can pass in a Text::Chump object and use that.


	[% USE Chump({ chump => my_chump_object }) %]


=head1 DESCRIPTION

Chump is a simplified markup language that allows for simple markup of 
text to include urls, links and inline images.

Chump is based on an original idea by Bijan Parsia who wrote a bot named DiaWebLogBot in Squeak
for the Monkeyfist Daily Churn. Subsequently Useful Inc. "stole all his good ideas" for their own 
IRC bot.

The bot is available from http://usefulinc.com/chump/ and the original page that uses this form of 
markup is http://pants.heddley.com 

From there the syntax was adopted by various other projects where more 
complex solutions such as Text::WikiFormat or HTML::FromText aren't
needed or don't have the right features and an extensible parser was
written because that's what good little programmers do.

B<Text::Chump> is a surprisingly (too the author if not anyone else), 
flexible and powerful Chump parser. From humble beginnings it has evolved 
to allow installable handlers and new types. All with a nice simple interface.

B<Template::Plugin::Chump> brings that interface to B<Template::Toolkit>. 

It's probably useful for allowing users to enter text which is HTML safe
(i.e no nasty cross site scripting bugs) but still allows them to provide 
links and inline images.

=head1 OPTIONS

B<Template::Plugin::Chump> can handle the same options as B<Text::Chump>.

Just pass them in either when loading the plugin or filtering with  it.

	[% USE Chump({ urls=>0 }) %]

	[% FILTER chump({ urls=>1 }) %]

	some text
	
	[% END %]

Like that.


You can also call the new_type and install methods from Text::Chump
using

	[% Chump.install(...) %]

or

	[% Chump.new_type(...) %]

the code ref you pass in must be a variable in the vars hash ref you 
pass into Template::Toolkit. Remember, because sub refs get called 
automatically you need something which returns a sub ref.

So, in your CGI script you need something like

	$vars->{uc} = sub { return sub { return uc $_[1] } };

	# stuff

	$tt->process($template, $vars);

And then in your template you do

	[% Chump.install('equal', '=', uc) %]
	[% FILTER chump %]
		=[foo]
		This will give FOO
	[% END %]


Que convenient :)

Alternatively you can pass in a fully formed B<Text::Chump>
object as a template var and use that instead inorder to more 
cleanly seperate code from presentation.

	sub uc { return uc $_[1] };

	my $tc = Text::Chump->new();
	$tc->install('link',\&uc);
	$tc->new_type('equal','=',\&uc);
	
	$tt->process($template, { my_chump => $tc });


And then in the template

	[% USE Chump ( { chump => my_chump } ) %]

	[% FILTER chump %]
		=[foo]
		This will give FOO
	[% END %]



=head1 AUTHOR

Simon Wistow <simon@thegestalt.org>

=head1 COPYING

(C)opyright 2003, Simon Wistow

Distributed under the same terms as Perl itself.

This software is under no warranty whatsoever and will probably ruin your life, 
kill your friends, burn down your house and bring about the apocalypse.

=head1 BUGS

None known.

=head1 SEE ALSO

L<Text::Chump>, L<Template::Plugin::Filter>

=cut



sub init {
	my ($self,@args)  = @_;
	my $config = (ref $args[-1] eq 'HASH')? pop @args : {};

	my $tc;

	if (defined $config->{chump}) {
		$tc = $config->{chump};
	} else {
	    $tc = Text::Chump->new($config);
    }    

	

	$self->{_DYNAMIC} = 1;
	$self->{_TC}      = $tc;


	$self->install_filter($FILTER_NAME);
	
	return $self;

}

# possibly extraneous cargo culting but it works so ...
sub filter {
    my ($self, $text, @args) = @_;
    my $config = (ref $args[-1] eq 'HASH')? pop @args : {};
    return $self->{_TC}->chump($text, $config);

}

# pass through methods to the same methods in Text::Chump
sub new_type {
	my $self = shift;
	$self->{_TC}->new_type(@_);

	return;
}

sub install {
	my $self = shift;
	$self->{_TC}->install(@_);
	return;
}


1;

