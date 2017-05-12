package OpenInteract::Template::Plugin;

# $Id: Plugin.pm,v 1.32 2003/08/13 12:28:43 lachoy Exp $

use strict;
use base qw( Template::Plugin );
use Class::Date     qw( -DateParse );
use Data::Dumper    qw( Dumper );
use HTML::Entities  qw();
use SPOPS::Secure   qw( :level :scope );
use SPOPS::Utility;
use Text::Sentence;

$OpenInteract::Template::Plugin::VERSION  = sprintf("%d.%02d", q$Revision: 1.32 $ =~ /(\d+)\.(\d+)/);

my %SECURITY_CONSTANTS  = (
  level => {
     none => SEC_LEVEL_NONE, read => SEC_LEVEL_READ, write => SEC_LEVEL_WRITE
  },
  scope => {
     user => SEC_SCOPE_USER, group => SEC_SCOPE_GROUP, world => SEC_SCOPE_WORLD
  },
);

use constant QUERY_ARG_SEPARATOR => '&amp;';

########################################
# PLUGIN IMPLEMENTATION
########################################

# Simple stub to load/create the plugin object. Since it's really just
# a way to call subroutines and doesn't maintain any state within the
# request, we can just return the same one again and again

sub load {
    my ( $class, $context ) = @_;
    return bless( { _CONTEXT => $context }, $class );
}


sub new {
    my ( $self, $context, @params ) = @_;
    return $self;
}

########################################
# METADATA
########################################

sub show_all_actions {
    my ( $self ) = @_;
    my $class = ref $self || $self;
    no strict 'refs';
    my %skip_actions = map { $_ => 1 } qw( load new Dumper );
    my @skip_initial = qw( SEC _ );
    my $src = \%{ $class . '::' };
    my @methods = ();
SYMBOL:
    foreach my $symbol_name ( keys %{ $src } ) {
        next SYMBOL if ( $skip_actions{ $symbol_name } );
        for ( @skip_initial ) { next SYMBOL if ( $symbol_name =~ /^$_/ ) }
        push @methods, $symbol_name if ( defined *{ $src->{ $symbol_name } }{CODE} );
    }
    return [ sort @methods ];
}


########################################
# PLUGIN ACTIONS
########################################

# Stub to call the component processor

sub comp {
    my ( $self, $name, @params ) = @_;

    # Put the parameters in a consistent format: all unnamed
    # parameters go into the key '_unnamed_' in the hashref, which
    # is what is passed to the actual component. Note that Template Toolkit
    # always passes the hashref of named parameters as the LAST parameter

    my $p = pop @params;
    $p->{_unnamed_} = \@params;

    # Put the name of the component into the parameters (note: you cannot
    # use 'name' as a parameter)

    $p->{name} = $name;

    # Pass the information to the component processor

    my $R = OpenInteract::Request->instance;
    $R->DEBUG && $R->scrib( 1, "Calling template component ($name)" );
    return $R->component->handler( $p );
}


# Add the box named $box with $params

sub box_add {
    my ( $self, $box, $params ) = @_;
    $params ||= {};
    my $R = OpenInteract::Request->instance;
    $R->DEBUG && $R->scrib( 1, "Trying to add $box with ", Dumper( $params ) );
    my %box_info = ( name => $box );
    if ( $params->{remove} ) {
        $box_info{remove} = 'yes';
        delete $params->{remove};
    }
    for ( qw( weight title template ) ) {
        next unless ( $params->{ $_ } );
        $box_info{ $_ } = $params->{ $_ };
        delete $params->{ $_ };
    }
    $box_info{params} = $params;
    push @{ $R->{boxes} }, \%box_info;
    return undef;
}


########################################
# SPOPS/OBJECT INFORMATION
########################################


# Return a hashref of information about $obj

sub object_description {
    my ( $self, $obj ) = @_;
    return {} unless ( ref $obj and $obj->isa( 'SPOPS' ) );
    return $obj->object_description;
}


# Backward compatibility

sub object_info { return object_description( @_ ); }


# Wrap the call in an eval{} just in case people pass us bad data.

sub class_isa {
    my ( $self, $item, $class ) = @_;
    return eval { $item->isa( $class ) };
}



########################################
# DATES
########################################

sub _create_date_object {
    my ( $date_string ) = @_;
    return ( $date_string =~ /^(today|now)$/ )
             ? Class::Date->now()
             : Class::Date->new( $date_string );
}


# Format a date with a strftime format

sub date_format {
    my ( $self, $date_string, $format, $params ) = @_;
    return undef unless ( $date_string );
    $params ||= {};
    my $date = _create_date_object( $date_string );
    unless ( $date ) {
        OpenInteract::Request->instance->scrib( 0, "Cannot parse ($date_string) into valid date" );
        return undef;
    }
    $format ||= '%Y-%m-%d %l:%M %p';
    my $formatted = $date->strftime( $format );
    if ( $params->{fill_nbsp} ) {
        $formatted =~ s/\s/\&nbsp;/g;
    }
    return $formatted;
}


# Put a date into a hash with year, month, day, hour and second as
# keys. If the date is 'today' or 'now' you get back the current time.

sub date_into_object {
    my ( $self, $date_string ) = @_;
    return {} unless ( $date_string );
    return _create_date_object( $date_string );
}


########################################
# STRING FORMATTING
########################################

# Limit $str to $len characters

sub limit_string {
    my ( $self, $str, $len ) = @_;
    my $R = OpenInteract::Request->instance;
    $R->DEBUG && $R->scrib( 2, "limiting $str to $len characters" );
    return $str if ( length $str <= $len );
    return substr( $str, 0, $len ) . '...';
}


# Quote something for use in generated Javascript code

sub javascript_quote {
    my ( $self, $string ) = @_;
    $string =~ s/\'/\\\'/g;
    return $string;
}

# Match $match from $str, which should have parentheses in it
# somewhere so that the match will be passed out (works?)

sub regex_chunk {
    my ( $self, $str, $match ) = @_;
    my $R = OpenInteract::Request->instance;
    $R->DEBUG && $R->scrib( 2, "Grabbing the match ($match) from string (($str))" );
    my ( $item ) = $str =~ /$match/;
    $R->DEBUG && $R->scrib( 2, "Matched (($item)) from string." );
    return $item;
}


# Limit $text to $num_sentences sentences (works?)

sub limit_sentences {
    my ( $self, $text, $num_sentences ) = @_;
    return undef if ( ! $text );
    $num_sentences ||= 3;
    my @sentences = Text::Sentence::split_sentences( $text );
    my $orig_num_sentences = scalar @sentences;
    $sentences[ $num_sentences - 1 ] .= ' ...'  if ( $orig_num_sentences > $num_sentences );
    return join ' ', @sentences[ 0 .. ( $num_sentences - 1 ) ];
}


# Format $num as a percent to $places decimal places

sub percent_format {
    my ( $self, $num, $places ) = @_;
    $places = 2 unless ( defined $places );
    return sprintf( "%5.${places}f%%", $num * 100 );
}


# Format $num as US currency

sub money_format {
    my ( $self, $num, $places ) = @_;
    $places = 2 unless ( defined $places );
    return sprintf( "\$%5.${places}f", $num );
}


sub byte_format {
    my ( $self, $num ) = @_;
    my @formats = ( '%s bytes', '%5.1f KB', '%5.1f MB', '%5.1f GB' );
    my $idx = 0;
    my $max = scalar @formats - 1;
    while ( $num > 1024 and $idx < $max ) {
        $num /= 1024;
        $idx++;
    }
    my $fmt = sprintf( $formats[ $idx ], $num );
    $fmt =~ s/^\s+//;
    return $fmt;
}


# Return the arg sent to ucfirst

sub uc_first { return ucfirst $_[1] }


# Return an HTML-encoded first argument

sub html_encode {
    return HTML::Entities::encode( $_[1] )
}


# Return an HTML-decoded first argument

sub html_decode {
    return HTML::Entities::decode( $_[1] );
}


# Create a URL, smartly. (The smart part was taken from
# Template::Plugin::URL)

sub make_url {
    my ( $self, $p ) = @_;
    my $url_base = $p->{base} || '/';
    delete $p->{base};
    my $R = OpenInteract::Request->instance;
    if ( $R->{path}{location} ) {
        $url_base = "$R->{path}{location}$url_base";
    }
	my $query = join( QUERY_ARG_SEPARATOR,
                      map  { "$_=" . _url_escape( $p->{ $_ } ) }
                      grep { defined $p->{ $_ } }
                      keys %{ $p } );

    return "$url_base?$query";
}

sub _url_escape {
    my ( $to_encode ) = shift;
    return undef unless defined( $to_encode );
    $to_encode =~ s/([^a-zA-Z0-9_.-])/uc sprintf("%%%02x",ord($1))/eg;
    return $to_encode;
}


########################################
# DATA RETRIEVAL
########################################

# TODO: Figure out how configure this to use a nice API to select only
# certain users (e.g., pass in a group name, group API, beginning of a
# last name, etc..

sub get_users {
    my ( $self ) = @_;
    my $R = OpenInteract::Request->instance;
    return eval { $R->user->fetch_iterator({ order => 'login_name' }) };
}


########################################
# OI DISPLAY
########################################

# Tell OI (from a page) about the page title

sub page_title {
    my ( $self, $title ) = @_;
    my $R = OpenInteract::Request->instance;
    $R->{page}{title} = $title;
    $R->DEBUG && $R->scrib( 2, "Set page title to [$title]" );
    return undef;
}

# Tell OI (from a page) you want to use a different 'main' template

sub use_main_template {
    my ( $self, $template_name ) = @_;
    my $R = OpenInteract::Request->instance;
    $R->{page}{_template_name_} = $template_name;
    $R->DEBUG && $R->scrib( 2, "Set main template to [$template_name]" );
    return undef;
}


# This should return the main content template used. This isn't
# documented yet because while it probably works 90% of the time, I'm
# not sure about the other 10%.

sub content_template {
    my ( $self ) = @_;
    my $R = OpenInteract::Request->instance;
    return $R->{templates_used}->[0];
}


########################################
# PLUGIN PROPERTIES
########################################

sub security_level {
    return $SECURITY_CONSTANTS{level};
}


sub security_scope {
    return $SECURITY_CONSTANTS{scope};
}


sub login {
    return OpenInteract::Request->instance->{auth}{user};
}


sub logged_in {
    return OpenInteract::Request->instance->{auth}{logged_in}
}


sub login_group {
    return OpenInteract::Request->instance->{auth}{group};
}


sub is_admin {
    return OpenInteract::Request->instance->{auth}{is_admin};
}


sub return_url {
    my $R = OpenInteract::Request->instance;
    return $R->{page}{return_url}
           || $R->{path}{login_fail}
           || $R->{path}{original};
}


sub theme_properties {
    my $R = OpenInteract::Request->instance;
    my $prop = $R->{theme_values} || $R->{theme}->all_values;
    $R->{theme_values} ||= $prop;
    return $prop;
}

sub theme {
    return theme_properties( @_ );
}

sub theme_fetch {
    my ( $self, $theme_spec, $params ) = @_;
    my ( $theme_id );
    my $R = OpenInteract::Request->instance;
    if ( $theme_spec =~ /^[\d\s]+$/ ) {
        $theme_id = $theme_spec;
    }
    else {
        $theme_id = $R->CONFIG->{default_objects}{ $theme_spec };
    }
    unless ( $theme_id ) {
        $R->scrib( 0, "Could not fetch theme given spec of '$theme_spec': ",
                      "it doesn't look like an object ID and no matching ",
                      "no matching name found in 'default_objects' server ",
                      "configuration" );

        # Don't return undef or the caller will get a nasty surprise
        # when he tries to use it

        return $self->theme_properties;
    }
    my $new_theme = eval { $R->theme->fetch( $theme_id ) };
    if ( $@ ) {
        $R->scrib( 0, "Error fetching theme with ID '$theme_id': $@" );
        return $self->theme_properties;
    }
    unless ( $new_theme ) {
        $R->scrib( 0, "No theme with ID '$theme_id' exists" );
        return $self->theme_properties;
    }

    # New theme looks good, fill it up...
    my $new_props = $new_theme->all_values;

    # ... and set for rest of request if specified
    if ( $params->{set_for_request} eq 'yes' ) {
        $R->{theme} = $new_theme;
        $R->{theme_values} = $new_props;
    }

    return $new_props;
}

sub error_hold {
    return OpenInteract::Request->instance->{error_hold};
}


sub session {
    return \%{ OpenInteract::Request->instance->{session} };
}

sub server_config {
    return OpenInteract::Request->instance->CONFIG;
}


1;

__END__

=head1 NAME

OpenInteract::Template::Plugin - Custom OpenInteract functionality in templates

=head1 SYNOPSIS

 # Create the TT object with the OI plugin
 
 my $template = Template->new(
                       PLUGINS => { OI => 'OpenInteract::Template::Plugin' }, ... );
 my ( $output );
 $template->process( 'package::template', \%params, \$output );
 
 
 # In the template (brief examples, see below for more)
 
 [% OI.show_all_actions.join( "\n" ) -%]
 
 [% OI.comp( 'error_display', error_msg = error_msg ) -%]
 
 [% OI.box_add( 'contact_tools_box', title  = 'Contact Tools',
                                     weight = 2 ) -%]
 
 [% object_info = OI.object_description( object ) %]
 This is a [% object_info.name %] object.
 
 Is the object in the class? 
    [% OI.class_isa( object, 'SPOPS::DBI' ) ? 'yes' : 'no' %]
 
 Today is [% OI.date_format( 'now', '%Y-%m-%e %l:%M %p' ) %] the
 [% OI.date_format( 'now', '%j' ) %] day of the year
 
 [% d = OI.date_into_object( object.updated_on ) -%]
 [% OI.comp( 'date_select', month_value  = d.month,
                            day_value    = d.day,
                            year_value   = d.year, blank = 1,
                            field_prefix = 'updated_on' ) -%]
 
 [% OI.limit_string( object.description, 30 ) %]
 
 var person_last_name = '[% OI.javascript_quote( person.last_name ) %]';
 
 [% matched = OI.regex_chunk( 'It was the best of times, it was the blurst of times.',
                              '(blurst.*)' ) %]
 
 [% OI.limit_sentences( news.news_item, 3 ) %]
 
 [% score = grade.score / test.total %]
 Your grade is: [% OI.percent_format( score ) %]
 
 You have [% OI.money_format( account.balance ) %] left to spend.
 
 Hello [% OI.uc_first( person.first_name ) %]
 
 <textarea name="news_item">[% OI.html_encode( news.news_item ) %]</textarea>
 
 Item: [% OI.html_decode( news.news_item ) %]
 
 [% edit_url = OI.make_url( base = '/User/show/', user_id = OI.login.user_id,
                            edit = 1, show_all = 'yes' ) %]
 <a href="[% edit_url %]">Edit your information</a>
 
 [% theme = OI.theme_properties %]
 Background color of page: [% theme.bgcolor %]
 
 [% new_theme = OI.theme_fetch( 5 ) %]
 Background color of page from other theme: [% new_theme.bgcolor %]
 
 [% IF OI.logged_in -%]
 Hello [% OI.login.full_name %]. 
   Your groups are: [% OI.login_group.join( ', ' ) -%]
 [% ELSE -%]
 You are not logged in.
 [% END -%]
 
 Your last search: [% OI.session.latest_search %]
 
 <a href="[% OI.return_url %]">Refresh</a>
 
 [% IF OI.error_hold.myapp.field_out_of_bounds %]
   The entry you made is out of bounds:
        [% OI.error_hold.myapp.field_out_of_bounds %]
 [% END %]
 
 [% IF object.tmp_security_level >= OI.security_level.write -%]
   you can edit this object!
 [% END %]

=head1 DESCRIPTION

This implements a Template Toolkit Plugin. For more information about
plugins, see L<Template::Manual::Plugins>.

Normally a plugin is instantiated like this:

 [% USE OI %]
 [% object_info = OI.object_description( object ) %]

But since this plugin will probably be used quite a bit by
OpenInteract template authors, it is always already created for you if
you use the L<OpenInteract::Template::Process> module.

It can be used outside of the normal OpenInteract processing by doing
something like:

    my $template = Template->new(
                      PLUGINS => { OI => 'OpenInteract::Template::Plugin' }
                   );
    $template->process( $text, { OI => $template->context->plugin( 'OI' ) } )
         || die "Cannot process template! ", $template->error();

This is done for you in L<OpenInteract::Template::Process> so you can
simply do:

    my $R = OpenInteract::Startup->setup_static_environment_options();
    OpenInteract::Template::Process->initialize( $R->CONFIG );
    print OpenInteract::Template::Process->handler( {},
                                                    { foo => 'bar' },
                                                    { name => 'mypkg::mytemplate' });

And everything works. (See L<OpenInteract::Template::Process> for more
information.)

Most of the interesting information is in L<METHODS AND PROPERTIES>.

=head1 METHODS AND PROPERTIES

The following OpenInteract properties and methods are available
through this plugin, so this describes how you can interface with
OpenInteract from a template.

=head2 REFLECTION

B<show_all_actions()>

You can get a listing of all actions available via the plugin by
doing:

 [% actions = OI.show_all_actions -%]
 [% actions.join( "\n" ) %]

=head2 METHODS

B<comp( $name, \%params )>

Calls the component processor and returns the output. Components can
be very simple means for generating reusing HTML, or they can be
complex data display/manipulation schemes.

Example:

 [% OI.comp( 'error_display', error_msg = error_msg ) %]

See L<OpenInteract::Component|OpenInteract::Component> module for
more information about components.

B<box_add( $box, \%params )>

Adds a box to the list of boxes that will be processed by the 'boxes'
component. (This is usually found in the 'base_main' template for your
site.) You can add just a simple box name or parameters for the box as
well. See the 'base_box' package for more information about boxes.

Examples:

 [% OI.box_add( 'object_modify_box', object = news ) %]

 [% OI.box_add( 'object_modify_box', object = news, title = 'Change it!',
                                     weight = 1 ) %]

B<object_description( $spops_object )>

Returns a hashref with metadata about any SPOPS object. Keys of the
hashref are C<class>, C<object_id> (and C<oid>), C<id_field>, C<name>,
C<title>, C<url>, C<url_edit>. (See L<SPOPS> for details about what is
returned.)

 [% desc = OI.object_description( news ) %]
 [% IF news.tmp_security_level >= OI.security_level.write %]
   <a href="[% desc.url_edit %]">Edit</a>
 [% END %]

B<class_isa( $class|$object, $isa_class )>

Returns a true value if C<$class> or C<$object> is a C<$isa_class>.

Example:

 [% IF OI.class_isa( news, 'MySite::NewsCustom' ) %]
   [% news.display_custom_news() %]
 [% ELSE %]
   [% news.display_news() %]
 [% END %]

(Of course, this is a bad example since you would deal with this
through your normal OO methods.)

B<date_format( $date_string[, $format ] )>

Formats the date from string C<$string> using the strftime format
C<$format>. If you do not supply C<$format>, a default of

 %Y-%m-%e %l:%M %p

is used.

Examples:

  [% mydate = '2000-5-1 5:45 PM' %]
  Date [% mydate %] is day number [% OI.date_format( mydate, '%j' ) %] of the year.

displays:

  Date 2000-5-1 5:45 PM is day number 122 of the year.

and

  Today is day number [% OI.date_format( 'now', '%j' ) %] of the year.

displays:

  Today is day number 206 of the year.

For reference, here are C<strftime> formatting sequences (cribbed from
L<Date::Format|Date::Format>):

  %%      PERCENT
  %a      day of the week abbr
  %A      day of the week
  %b      month abbr
  %B      month
  %c      MM/DD/YY HH:MM:SS
  %C      ctime format: Sat Nov 19 21:05:57 1994
  %d      numeric day of the month, with leading zeros (eg 01..31)
  %e      numeric day of the month, without leading zeros (eg 1..31)
  %D      MM/DD/YY
  %h      month abbr
  %H      hour, 24 hour clock, leading 0)
  %I      hour, 12 hour clock, leading 0)
  %j      day of the year
  %k      hour
  %l      hour, 12 hour clock
  %m      month number, starting with 1
  %M      minute, leading 0
  %n      NEWLINE
  %o      ornate day of month -- "1st", "2nd", "25th", etc.
  %p      AM or PM 
  %q      Quarter number, starting with 1
  %r      time format: 09:05:57 PM
  %R      time format: 21:05
  %s      seconds since the Epoch, UCT
  %S      seconds, leading 0
  %t      TAB
  %T      time format: 21:05:57
  %U      week number, Sunday as first day of week
  %w      day of the week, numerically, Sunday == 0
  %W      week number, Monday as first day of week
  %x      date format: 11/19/94
  %X      time format: 21:05:57
  %y      year (2 digits)
  %Y      year (4 digits)
  %Z      timezone in ascii. eg: PST
  %z      timezone in format -/+0000

B<date_into_object( $date_string )>

Takes apart C<$date_string> and returns a L<Class::Date> object. You
can call a number of methods on this object to get individual pieces
of a date. (See the docs for L<Class::Date> for a complete list.)

Note that you can pass 'now' or 'today' as C<$date_string> and get the
current time.

Example:

  [% mydate = '2000-5-1 5:45 PM' %]
  [% dt = OI.date_into_object( mydate ) %]
  Date: [% mydate %]
  Year: [% dt.year %]
  Month Num/Name: [% dt.month %] / [% dt.monthname %]
  Day/Name/of Year:  [% dt.day %] / [% dt.wdayname %] / [% dt.day_of_year %]
  Hour: [% dt.hour %]
  Minute: [% dt.minute %]

displays:

  Date: 2000-5-1 5:45 PM
  Year: 2000
  Month Num/Name: 5 / May
  Day/Name/of Year:  1 / Monday / 121
  Hour: 5
  Minute: 45

B<limit_string( $string, $length )>

Returns a string of max length C<$length>. If the function removes
information from the string, it appends '...' to the string. Note that
we currently do not try to be nice with word endings.

Example:

 [% string = 'This is a really long news title and we have strict space constraints' %]
 [% OI.limit_string( string, 25 ) %]

displays:

 This is a really long new...

B<javascript_quote( $string )>

Performs necessary quoting to use C<$string> as Javascript
code. Currently this only involves escaping the "'" character, but it
can easily expand as necessary.

Example:

 [% book_title = "it's nothing" %]
 var newArray = new Array( '[% OI.javascript_quote( book_title ) %]' );

displays:

 var newArray = new Array( 'it\'s nothing' );

We could probably use a filter for this.

B<regex_chunk( $string, $match )>

Tries to match C<$match> in C<$string> and returns the matching text.

Example:

  Matching text: ([% OI.regex_chunk( 'This is the text', 'This (.*)' ) %])

displays:

  Matching text: (is the text)

B<limit_sentences( $string, $num_sentences )>

Limits C<$string> to C<$num_sentences> sentences. If the resulting
text is different -- if the function actually removes one or more
sentences -- we append '...' to the resulting text.

Example:

  [% sentence_text = 'This is the first. This is the second. This is the third. This is the fourth.' %]
  Sentences: [% OI.limit_sentences( sentence_text, 2 ) %]

displays:

  Sentences: This is the first. This is the second. ...

B<percent_format( $number[, $places ] )>

Formats C<$number> as a percentage to C<$places>. If not specified
C<$places> defaults to '2'.

Example:

 [% grade = 44 / 66 %]
 Grade: [% OI.percent_format( grade, 2 ) %]

displays:

 Grade: 66.67%

B<money_format( $number[, $places ] )>

Displays C<$number> as US dollars to C<$places>. If not specified,
C<$places> defaults to 2.

Example:

  [% monthly_salary = 3000 %]
  [% yearly_salary = monthly_salary * 12 %]
  Your yearly salary: [% OI.money_format( yearly_salary, 0 ) %]

displays:

  Your yearly salary: $36000

B<byte_format( $number )>

Displays C<$number> as a number of bytes. If the number is less than
1024 it displays directly, between 1024 and 1024**2 as KB, between
1024**2 and 1024**3 as MB and greater than that as GB.

Example:

 The file sizes are:
   [% OI.byte_format( 989 ) %]
   [% OI.byte_format( 2589 ) %]
   [% OI.byte_format( 9019 ) %]
   [% OI.byte_format( 2920451 ) %]
   [% OI.byte_format( 920294857 ) %]
   [% OI.byte_format( 3211920294857 ) %]

displays:

 The file sizes are:
   989 bytes
   2.5 KB
   8.8 KB
   2.8 MB
   877.7 MB
   2991.3 GB

B<uc_first( $text )>

Simply upper-case the first letter of the text passed in. Note that we
do not do every word, just the first.

Example:

  [% first_name = 'yahoo' %]
  Hi there, [% OI.uc_first( first_name ) %]

displays:

  Hi there, Yahoo

B<html_encode( $text )>

Encodes C<$text> so that it can be displayed in a TEXTAREA or in other
widgets.

Example:

 [% news_item = "<p>This is the first paragraph</p>" %]
 <textarea name="news_item" cols="50" rows="4"
           wrap="virtual">[% OI.html_encode( news_item ) %]</textarea>

displays:

 <textarea name="news_item" cols="50" rows="4"
           wrap="virtual">&lt;p&gt;This is the first paragraph&lt;/p&gt;</textarea>

B<html_decode( $text )>

Decodes C<$text> with HTML entities to be displayed normally.

Example:

 [% news_item = '&lt;p&gt;This is the first paragraph&lt;/p&gt;' %]
 [% OI.html_decode( news_item ) %]

displays:

 <p>This is the first paragraph</p>

B<make_url( \%params )>

Creates a URL given a number of parameters, taking care to perform any
necessary transformations.

Parameters:

All parameters except those listed below are assumed to be used as GET
keys and values and will be appended to the URL appropriately.

=over 4

=item *

B<base>: The base for the URL. This is normally what gets transformed
with a location prepended to it or a session tag appended (or
whatever).

=back

Example:

 [% user_show_url = OI.make_url( base = '/User/show/',
                                 user_id = user.user_id ) %]
 <a href="[% user_show_url %]">blah</a>

displays (when under the normal location of '/'):

 <a href="/User/show/?user_id=5">blah</a>

displays (when under a different location '/oi'):

 <a href="/oi/User/show/?user_id=5">blah</a>

B<page_title( $title )>

Tell OpenInteract to use C<$title> for the page title.

Example:

 [% OI.page_title( 'My Favorite Quotes from Douglas Adams' ) %]

B<use_main_template( $template_name )>

Tell OpenInteract to use a particular main template. The
C<$template_name> should be in 'package::name' format.

Example:

  [% OI.use_main_template( 'mypkg::main' ) -%]

B<theme_fetch( $new_theme_spec, \%params )>

Retrieves the properties for theme C<$new_theme_spec>, which can be an
ID (normal) or a name listed in the 'default_objects' of your server
configuration. If the latter we'll use the ID associated with that
name.

If the key C<set_for_request> is set to 'yes' in C<\%params> then this
new theme will be used for the remainder of the request. This includes
the main template along with all graphical elements.

Returns: hashref with all properties of the given theme.

Examples:

 [% new_theme = OI.theme_fetch( 5 ) %]
 Background color of page from other theme: [% new_theme.bgcolor %]
 
 [% new_theme = OI.theme_fetch( 5, set_for_request = 'yes' ) %]
 Background color of page from other theme: [% new_theme.bgcolor %]
 Hey, the new theme is now set for the rest of the request!

=head2 PROPERTIES

B<theme_properties()>

A hashref with all the properties of The current theme. You will
probably use this a lot.

Example:

 [% theme = OI.theme_properties %]
 <tr bgcolor="[% theme.head_bgcolor %]">

The exact properties in the theme depend on the theme. See the
'base_theme' package for more information.

B<theme()>

Alias for 'theme_properties'

B<login()>

The user object representing the user who is currently logged in.

Example:

 [% login = OI.login %]
 <p>Hi [% login.full_name %]! Anything new?</p>

B<login_group()>

An arrayref of groups the currently logged-in user belongs to.

Example:

 [% login_group = OI.login_group %]
 <p>You are a member of groups:
 [% FOREACH group = login_group %]
   [% th.bullet %] [% group.name %]<br>
 [% END %]
 </p>

B<logged_in()>

True/false determining whether the user is logged in or not.

Example:

 [% IF OI.logged_in %]
   <p>You are very special, logged-in user!</p>
 [% END %]

B<is_admin()>

True/false depending on whether the user is an administrator. The
definition of 'is an administrator' depends on the authentication
class being used -- by default it means that the user is the superuser
or a member of the 'site admin' group. But you can modify this based
on your needs, and make the result available to all templates with
this property.

Example:

 [% IF OI.is_admin %]
   <p>You are an administrator -- you have the power! It feels great,
   eh?</p>
 [% END %]

B<session()>

Contains all information currently held in the session. Note that
other handlers may during the request process have modified the
session. Therefore, what is in this variable is not guaranteed to be
already saved in the database. However, as the request progresses
OpenInteract will sync up any changes to the session database.

Note that this information is B<read-only>. You will not get an error
if you try to set or change a value from the template, but the
information will persist only for that template.

Example:

 [% session = OI.session %]
 <p>Number of items in your shopping cart:
    [% session.num_shopping_cart_items %]</p>

B<return_url()>

What the 'return url' is currently set to. The return url is what we
come back to if we have to do something like logout.

<a href="[% OI.return_url %]">Logout and return to this page</a>

B<error_hold()>

A hashref representing a container with all error messages as
generated by error handlers. The error handler and the template need
to coordinate on a naming scheme so you know where to find your
messages.

Note that future work may restrict this to the errors for your
template only.

Example:

 [% error_messages = OI.error_hold %]
 <p>User [% error_messages.loginbox.login_name %] does not exist in
 the system.</p>

B<security_level()>

A hashref with keys of 'none', 'read', and 'write' which gives you the
value used by the system to represent the security levels.

Example:

 [% IF obj.tmp_security_level < OI.security_level.write %]
  ... do stuff ...
 [% END %]

B<security_scope()>

A hashref with the keys of 'user', 'group' and 'world' which gives you
the value used by the system to represent the security scopes. This
will rarely be used but exists for completeness with
C<security_level>.

 [% security_scope = OI.security_scope %]
 [% FOREACH scope = security_scope.keys %]
   OI defines [% scope %] as [% security_scope.$scope %]
 [% END %]

B<server_config()>

Returns the server configuration object (or hashref) -- whatever is
returned by calling in normal code:

 $R->CONFIG;

 The ID of the site admin group is: 
  [% OI.server_config.default_objects.site_admin_group %]

=head1 NOTICE

The following were removed from the old module
L<OpenInteract::Template::Toolkit>:

=over 4

=item *

B<now>

Removed. Use:

 [% date_format( 'now' ) %]

For the default format, or use your own format:

 [% date_format( 'now', '%Y-%m-%d' ) %]

=item *

B<simulate_sprintf>

Instead, use the built-in 'format' plugin:

  [% USE format %]
  [% score_line = format( 'Place: %02d  Score: %5.2f' ) %]
  [% FOREACH finisher = score_list -%]
    [%- score_line( finisher.place, finisher.score ) -%]
  [% END -%]

See C<Template::Plugin::Format> for more info.

=item *

B<dump_it>

Instead, use the built-in 'Dumper' plugin:

  [% USE Dumper %]
  [% Dumper.dump( my_complex structure ) %]

And you also get:

  [% Dumper.dump_html( my_complex structure ) %]

See C<Template::Plugin::Dumper> for more info.

=back

=head1 BUGS

None known.

=head1 TO DO

B<Custom plugins>

Make it easy for websites to create their own plugins that can be
accessed through the 'OI.' plugin. For instance, a package owner could
define a set of additional behaviors to go along with a package. In a
file distributed with the package, the plugins could be listed:

 conf/template_plugins.dat:
 ------------------------------
 OpenInteract::Plugin::MyPackage1
 OpenInteract::Plugin::MyPackage2
 ------------------------------

And stored within the server-wide configuration object. Then when we
call C<load()> in this plugin, we could do something similar to the
C<_populate> method in C<Slash::Display::Plugin::Plugin> where we peek
into the C<@EXPORT_OK> array and copy the code refs into a hash which
we can then check via C<AUTOLOAD>.

One problem with that is name collision -- two packages might both
define a 'do_stuff' action, and in this case the last one would
win. No good.

Maybe we prepend the package name to the action? Also no good -- the
whole idea is to make the template environment transparent....

=head1 SEE ALSO

L<Template::Plugins>

L<Template::Plugin::URL> for borrowed code

Slashcode (http://www.slashcode.com) for inspiration

=head1 COPYRIGHT

Copyright (c) 2001-2002 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters <chris@cwinters.com>
