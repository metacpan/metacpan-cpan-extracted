package Pangloss::Shell;

use strict;
use warnings;

use YAML qw( LoadFile Dump );
use Pixie;
use Error qw( :try );
use Data::Dumper qw( Dumper );
use Term::ReadKey qw( ReadKey ReadMode GetControlChars );

use Pangloss::Application;
use Pangloss::Shell::Command;

use base qw( Pangloss::Object );

our %HELP = (
	     general => (
			 "General Help.\ntry:\n\thelp <topic>\n\n" .
			 "'help topics' will list available topics.\n"
			),
	     connect => (
			 "Connect Pangloss to Pixie store:\n" .
			 "\tconnect <dsn>, \%options\n" .
			 "see Pixie documentation for more details.\n"
			),
	     load    => (
			 "Load a YAML database:\n" .
			 "\tload '/path/to/terms.yml'\n" .
			 "see t/data/terms.yml for expected file format.\n"
			),
	     quit    => (
			 "Quit Pangloss shell.\n"
			),
	     save    => (
			 "Save objects into the Pixie store.\n" .
			 "\tsave loaded collections\n" .
			 "\tsave loaded <collection>\n" .
			 "\tsave loaded <item>\n" .
			 "By itself, 'save' defaults to 'save loaded collections'.\n"
			),
	     show    => (
			 "Show contents of an item or a collection of items.\n" .
			 "\tshow <collection>\n" .
			 "\tshow <item>\n" .
			 "\tshow loaded <collection>\n" .
			 "\tshow loaded <item>\n"
			),
	     create  => (
			 "Create and save objects into the Pixie store.\n" .
			 "\tcreate <item> [*]\n" .
			 "\tcreate admin\n" .
			 "\tcreate store <dsn>, \%options\n" .
			 "* currently only 'user' items can be created.\n"
			),
	     items   => (
			 "Items available:\n" .
			 "\tlanguages, users, categories, concepts, terms\n"
			),
	     collections => "See 'help items'.\n",
	    );
$HELP{h} = $HELP{help};
$HELP{exit} = $HELP{'q'} = $HELP{quit};

our %EDITOR = (
	       user       => 'user_editor',
	       users      => 'user_editor',
	       language   => 'language_editor',
	       languages  => 'language_editor',
	       concept    => 'concept_editor',
	       concepts   => 'concept_editor',
	       category   => 'category_editor',
	       categories => 'category_editor',
	       term       => 'term_editor',
	       terms      => 'term_editor',
	      );

our %SINGULAR = (
		 users      => 'user',
		 languages  => 'language',
		 concepts   => 'concept',
		 categories => 'category',
		 terms      => 'term',
		);


sub event_loop {
    my $self = shift;

    sub sig_handler {
	no warnings;
	my $sig = shift;
	warn "\ncaught sig $sig...\n";
	$self->quit(1);
    }

    my %old_SIG = %SIG;
    local $SIG{INT}     = \&sig_handler;
    local $SIG{HUP}     = \&sig_handler;
    local $SIG{QUIT}    = \&sig_handler;
    local $SIG{__DIE__} = \&sig_handler;

    local $| = 1;

    binmode( STDIN,  ':utf8' );
    ReadMode( 3 );

    $self->{app} = Pangloss::Application->new;
    $self->{cmd} = Pangloss::Shell::Command->new;

    print "\nWelcome to the Pangloss admin shell\n" .
          "type 'h' or 'help' for help,\n" .
          "'q', 'exit', 'quit' or Ctrl-C to quit.\n";

    while (1) {
	if (my $cmd = $self->{cmd}->get_command()) {
	    if (my ($method, $args) = $cmd =~ /\A(\w+)(?:\s+(.+))?\z/) {
		$args ||= '';
		# try quoting things to make typing strings easier...
		$args = "qw( $args )" if $args =~ /\A[\w\s]+\z/;
		$cmd = "\$self->$method( $args )" if $self->can( $method );
	    }

	    $self->emit( $cmd );
	    {
		no strict;
		no warnings;
		local $SIG{__DIE__} = $old_SIG{__DIE__};
		print eval $cmd;
	    }
	    print $@ if $@;
	    print "\n";
	}
    }

    $self->quit(0);
}

sub help {
    my $self  = shift;
    my $topic = shift || 'general';
    return "Topics available:\n\t" . join( "\n\t", keys %HELP ) if $topic =~ /topics/;
    return $HELP{$topic} || "there's no help for the '$topic' topic.";
}

sub h { shift->help( @_ ); }

sub hello {
    my $self = shift;
    return "hi there.";
}

sub connect {
    my $self  = shift;
    my $dsn   = shift || return "you must specify at least a DSN to connect Pixie to.";
    my %args  = @_;
    local $SIG{INT} = sub { die "cancelled connect to $dsn\n"; };
    print "connecting to Pixie store $dsn... ";
    my $pixie = Pixie->new->connect($dsn, %args);
    $self->{app}->store( $pixie );
    return "connected.";
}

sub load {
    my $self = shift;
    my $file = shift || return "you must specify a YAML file to load from.";
    local $SIG{INT} = sub { die "cancelled load $file\n"; };
    require Pangloss::IO::YAML;
    print "loading $file... ";
    $self->{yaml_io} = Pangloss::IO::YAML->new->load( $file );
    return "done.";
}

sub save {
    my $self   = shift;
    my $type   = shift || 'loaded';
    my $method = "save_$type";

    return "I don't know how to save '$type'." unless $self->can( $method );

    local $SIG{INT} = sub { die "cancelled save $type\n"; };

    return $self->$method( @_ );
}

sub save_loaded {
    my $self = shift;
    my $type = shift || 'objects';

    return "nothing has been loaded yet." unless $self->{yaml_io};

    return "not connected to a Pixie store." unless $self->{app}->store;

    return $self->save_loaded_collections if ($type =~ /obj(?:ect)?s/i);

    return $self->save_loaded_collection( 'users' )      if ($type =~ /users/i);
    return $self->save_loaded_collection( 'languages' )  if ($type =~ /lang(?:uage)?s/i);
    return $self->save_loaded_collection( 'concepts' )   if ($type =~ /concepts/i);
    return $self->save_loaded_collection( 'categories' ) if ($type =~ /cat(?:egorie)s/i);
    return $self->save_loaded_collection( 'terms' )      if ($type =~ /terms/i);

    return $self->save_loaded_item( 'users', @_ )      if ($type =~ /user/i);
    return $self->save_loaded_item( 'languages', @_ )  if ($type =~ /lang(?:uage)?/i);
    return $self->save_loaded_item( 'concepts', @_ )   if ($type =~ /concept/i);
    return $self->save_loaded_item( 'categories', @_ ) if ($type =~ /cat(?:egory)/i);
    return $self->save_loaded_item( 'terms', @_ )      if ($type =~ /term/i);

    return "don't know how to save loaded '$type'";
}

sub save_loaded_collections {
    my $self = shift;
    print "saving all loaded objects...\n";
    print $self->save_loaded_collection( 'languages' );
    print $self->save_loaded_collection( 'users' );
    print $self->save_loaded_collection( 'categories' );
    print $self->save_loaded_collection( 'concepts' );
    print $self->save_loaded_collection( 'terms' );
    return "done.";
}

sub save_loaded_collection {
    my $self   = shift;
    my $type   = shift;
    my $editor = $EDITOR{$type};

    print "saving loaded $type...\n";

    my $added = 0;
    my $ed    = $self->{app}->$editor;
    foreach my $item ($self->{yaml_io}->$type->values) {
	my $key  = $item->key;
	if ($ed->exists( $key )) {
	    print "\tskipping '$key' - already exists\n";
	    next;
	}
	my $view = $ed->add( $item );
	if (my $e = $view->{$SINGULAR{$type}}->{error}) {
	    print "error adding $SINGULAR{$type} '$key': ",
	          $e->isInvalid
		    ? join( "\n\t", '', keys %{ $e->invalid } )
		    : $e->flag,
		  "\n";
	} else {
	    print "\t$key\n";
	    $added++;
	}
    }

    return "added $added $type.\n";
}

sub save_loaded_item {
    my $self   = shift;
    my $type   = shift;
    my $key    = shift || return "no $type key specified.";
    my $editor = $EDITOR{$type};

    print "saving loaded $type: [$key]\n";
    my $item = $self->{yaml_io}->$type->get( $key );
    my $view = $self->{app}->$editor->add( $item );

    return Dump( $view );
}

sub show {
    my $self = shift;
    my $type = shift || return "show what?";

    return $self->show_loaded( @_ ) if ($type =~ /loaded/i);

    # the rest require a Pixie store
    return "not connected to a Pixie store." unless $self->{app}->store;

    return $self->show_collection( 'user' )     if ($type =~ /users/i);
    return $self->show_collection( 'language' ) if ($type =~ /lang(?:uage)?s/i);
    return $self->show_collection( 'concept' )  if ($type =~ /concepts/i);
    return $self->show_collection( 'category' ) if ($type =~ /cat(?:egorie)s/i);
    return $self->show_collection( 'term' )     if ($type =~ /terms/i);

    return $self->show_item( 'user', @_ )     if ($type =~ /user/i);
    return $self->show_item( 'language', @_ ) if ($type =~ /lang(?:uage)?/i);
    return $self->show_item( 'concept', @_ )  if ($type =~ /concept/i);
    return $self->show_item( 'category', @_ ) if ($type =~ /cat(?:egory)/i);
    return $self->show_item( 'term', @_ )     if ($type =~ /term/i);

    return "don't know how to show '$type'.";
}

sub show_collection {
    my $self = shift;
    my $type = shift;

    $self->emit( "showing $type" );
    my $editor = $EDITOR{$type};
    my $view   = $self->{app}->$editor->list;
    my @list   = @{ $view->{$type.'s'} };

    return @list . ' ' . $type.'s:', map { "\n\t" . $_->key } @list;
}

sub show_item {
    my $self = shift;
    my $type = shift;
    my $key  = shift || return "no $type key specified.";
    my $editor = $EDITOR{$type};
    $self->emit( "showing $type: [$key]" );
    return Dump( $self->{app}->$editor->get( $key ) );
}

sub show_loaded {
    my $self = shift;
    my $type = shift || return "show loaded what?";

    return "nothing has been loaded yet." unless $self->{yaml_io};

    return $self->show_loaded_collection( 'users' )      if ($type =~ /users/i);
    return $self->show_loaded_collection( 'languages' )  if ($type =~ /lang(?:uage)?s/i);
    return $self->show_loaded_collection( 'concepts' )   if ($type =~ /concepts/i);
    return $self->show_loaded_collection( 'categories' ) if ($type =~ /cat(?:egorie)s/i);
    return $self->show_loaded_collection( 'terms' )      if ($type =~ /terms/i);

    return $self->show_loaded_item( 'users', @_ )      if ($type =~ /user/i);
    return $self->show_loaded_item( 'languages', @_ )  if ($type =~ /lang(?:uage)?/i);
    return $self->show_loaded_item( 'concepts', @_ )   if ($type =~ /concept/i);
    return $self->show_loaded_item( 'categories', @_ ) if ($type =~ /cat(?:egory)/i);
    return $self->show_loaded_item( 'terms', @_ )      if ($type =~ /term/i);

    return "don't know how to show loaded '$type'.";
}

sub show_loaded_collection {
    my $self = shift;
    my $type = shift;
    $self->emit( "showing loaded $type\n" );
    my @list = @{ $self->{yaml_io}->$type->list };
    return @list . " $type:", map { "\n\t" . $_->key } @list;
}

sub show_loaded_item {
    my $self = shift;
    my $type = shift;
    my $key  = shift || return "no $type key specified.";
    $self->emit( "showing loaded $type: [$key]\n" );
    return Dump( $self->{yaml_io}->$type->get( $key ) );
}

sub create {
    my $self = shift;
    my $type = shift || return "create what?";
    my $method = "create_$type";

    return "I don't know how to create '$type'." unless $self->can( $method );

    local $SIG{INT} = sub { die "cancelled create $type\n"; };

    return $self->$method( @_ );
}

sub create_store {
    my $self = shift;
    my $dsn  = shift || return "create what kind of store?";
    my %args = @_;

    return "You don't need to create BerkeleyDB stores - just connect to them."
      if $dsn =~ /\Abdb:/;

    return "I only know how to create DBI-based stores."
      unless $dsn =~ /\Adbi:/;

    require Pixie::Store::DBI;
    Pixie::Store::DBI->deploy( $dsn, %args );

    return "done.";
}

sub create_user {
    my $self = shift;
    my $user = Pangloss::User->new->creator('admin')->date(time);

    return "not connected to a Pixie store." unless $self->{app}->store;

    print "creating new user...\n";
    while (! $user->id) {
	$user->id( $self->{cmd}->get_command('user id: ') );
    }

    while (! $user->name) {
	$user->name( $self->{cmd}->get_command('user name: ') );
    }

    return Dump( $self->{app}->user_editor->add( $user ) );
}

sub create_admin {
    my $self = shift;
    my $user = Pangloss::User->new->id('admin')->creator('admin')->date(time);
    $user->privileges->admin(1);

    return "not connected to a Pixie store." unless $self->{app}->store;

    print "creating admin user...\n";
    while (! $user->name) {
	$user->name( $self->{cmd}->get_command('user name: ') );
    }

    return Dump( $self->{app}->user_editor->add( $user ) );
}

sub quit {
    my $self = shift;
    my $code = shift || 0;
    warn "exitting pangloss admin shell.\n";
    undef $self->{app} if $self->{app};
    ReadMode( 0 );
    CORE::exit( $code );
}

sub exit { shift->quit(@_); }
sub q    { shift->quit(@_); }

1;
