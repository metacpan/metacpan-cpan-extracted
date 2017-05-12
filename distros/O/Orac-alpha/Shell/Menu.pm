#
# Handles the creation of the menus.
#

package Shell::Menu;
use Tk;
use Tk::Pretty;

use strict;
use Carp;

use Exporter ();
use vars qw(@ISA $VERSION);
$VERSION = $VERSION = q{1.0};
@ISA=('Exporter');

sub menu_bar {
   my ($self, $menus_ref) = @_;

	 $menus_ref = $self->menus unless $menus_ref;
   #$dbistatus = "Creating menu bar";

   my $f = $self->dbiwd->Frame( -relief => 'ridge', -borderwidth => 2 );

   $f->pack( -side => 'top', -anchor => 'n', -expand => 0, -fill => 'x' );
   
   # Create a menu bar.


   foreach (@{$menus_ref->{order}}) {
      $menus_ref->{lc $_ } = $f->Menubutton( -text => $_ , -tearoff => 0 );
			if (m/help/i) {
   			$menus_ref->{lc $_}->pack(-side => 'right' ); # Help
			} else {
   			$menus_ref->{lc $_}->pack(-side => 'left' );  # File
			}
			my $m = qq{menu_} . lc $_;
   		$self->$m($menus_ref->{lc $_}->menu);
   }
}


sub menu_file {
   my ($self, $menus_ref) = @_;

	 $menus_ref = $self->menus->{file}->menu unless $menus_ref;
   #
   # Add some options to the menus.
   #
   # File menu

   $menus_ref->AddItems(
         [ "command" => "Load", -command => sub { $self->load } ],
         [ "command" => "Save", -command => sub { $self->save( 0 ) } ],
         [ "command" => "Save buffer", -command => sub { $self->save(1) } ],
         "-",
         [ "command" => "Properties", -command => sub { $self->properties->display() } ],
         "-",
         [ "command" => "Exit", -command => sub { $self->exit } ],

                      );
	 #
	 # If Properties state (able to load Storable) is false (0),
	 # disable this menu option.
	 #
	 $menus_ref->entryconfigure( qq{Properties}, 
	 	-state => q{disabled} ) unless $self->properties->state;
}

sub menu_edit {
   my ($self, $menus_ref) = @_;
   $menus_ref->AddItems(
         [ "command" => qq/External Editor/, -command => sub { 
					my $f = $self->edit->external_edit($self->get_all_text_buffer);
					$self->replace_buffer($f);
					} ],
				 "-",
         [ "command" => qq/Clear All/, -command => sub { $self->clear_all } ],
         [ "command" => qq/Clear Entry/, -command => sub { $self->clear_entry } ],
         [ "command" => qq/Clear Result/, -command => sub { $self->clear_result } ],
				 "-",
		);
}

sub menu_meta {
   my ($self, $menus_ref) = @_;
   $menus_ref->AddItems(
         [ "command" => "All Tables", -command => sub { $self->meta(q{all_tables}) } ],
				 "-",
		);
}

sub menu_options {
   my ($self, $menus_ref) = @_;

   # Options menu

	 my $menu_ref =$self->menus->{options}->menu unless $menus_ref;

	 # Autoexecute:  When autoexec is on, statements ending in [;/] will
	 # execute when the enter/return is pressed.

	 $menus_ref->AddItems(
         [ "checkbutton" => " Autoexec", 
					-variable => \$self->options->{autoexec}],
         [ "checkbutton" => " Debug",
    			-variable => \$self->options->{debug} ],
         [ "checkbutton" => " Stop on Error",
    			-variable => \$self->options->{stop_on_error} ],
         [ "checkbutton" => " Ignore Comments",
    			-variable => \$self->options->{ignore_comments} ],
         [ "checkbutton" => " Write Error to Results",
    			-variable => \$self->options->{write_error_rslt} ],
         [ "checkbutton" => " Minimize Main Window",
    			-variable => \$self->options->{mini_main_wd} ],
				 "-",
	);
   my $opt_disp = $menus_ref->Menu;
   my @formats = $self->load_formats;
      
		my $_f;
   foreach (@formats) {
      $opt_disp->radiobutton( -label => $_, 
         -variable => \$self->options->{display_format},
         -value => $_,
         );
   }

   $menus_ref->cascade( -label => qq{Display format...}); 
   $menus_ref->entryconfigure( 
	 	qq{Display format...}, -menu => $opt_disp,
	 	-state => q{normal});

   # Create the entries for rows returned.

   my $opt_row = $menus_ref->Menu;

   foreach (qw/1 10 25 50 100 all/) {

      $opt_row->radiobutton( -label => $_, -variable => \$self->options->{rows},
         -value => $_ );
   }

   $menus_ref->cascade( -label => qq{Rows return...} );
   $menus_ref->entryconfigure( qq{Rows return...}, 
	 	-menu => $opt_row,
		-state => q{disabled});

}

sub menu_help {
   my ($self, $menus_ref) = @_;

	 my $menu_ref =$self->menus->{help}->menu unless $menus_ref;

   # Help menu
   $menus_ref->AddItems(
      [ "command" => "Index", -command => sub { $self->tba } ],
      "-",
      [ "command" => "About", -command => sub { $self->tba } ],
   );
}

sub menu_button {

   my $self = shift;

   # Create a button bar.
   #$dbistatus = "Creating menu button bar";

   my $bf = $self->dbiwd->Frame( -relief => 'ridge', -borderwidth => 2 );
   $bf->pack( -side => 'top', -anchor => 'n', -expand => 0, -fill => 'x' );

   # need to invoke the execute in other parts of the application.

	$self->buttons({q{exec} =>
   $bf->Button( -text=> 'Execute',
			-image => $self->icon(q{exec}),
			-command=> sub{ $self->doit() }
		)->pack(side=>'left')});


   $self->buttons(
		{q{execall} => $bf->Button( -text=> 'Execute All',
			-image => $self->icon(q{execall}),
			-command=> sub{ $self->execute_all_buffer() }
			)->pack(side=>'left'),
		q{clear} => $bf->Button( -text=> q{Clear},
			-image => $self->icon(q{clear}),
			-command=>sub{ $self->clear_all(); }
		)->pack(side=>q{left}),
		q{commit} => $bf->Button( -text=> q{Commit},
			-image => $self->icon(q{commit}),
			-command=> sub{ $self->commit() },
			-state => q{disabled}
		)->pack(side=> q{left}),
		q{rollback} => $bf->Button( -text=> q{Rollback},
			-image => $self->icon(q{rollback}),
			-command=> sub{ $self->rollback() },
			-state => q{disabled}
		)->pack(side=> q{left})});


   # Put the logo on this bar.

   my $orac_logo = $self->icon( { q{logo} => q{orac.gif} });

   $bf->Label(-image=> $self->icon(q{logo}), 
              -borderwidth=> 2,
              -relief=> 'flat'

             )->pack(  -side=> 'right', 
                       -anchor=>'e', 
                       -expand => 0, 
                       -fill => 'x'
                    );
   
   #$dbistatus = "Creating Close button";
   
   $self->buttons({ q{close} => $bf->Button( -text => qq{Close},
								-image => $self->icon(q{back}),
               -command => sub { 
                 $self->dbiwd->withdraw;
                 $self->{mw}->deiconify();
								} 
              )->pack( -side => qq{right} )});


	$self->bind_message( $self->buttons(q{exec}),
	 q{Execute the current statement.} );
	$self->bind_message( $self->buttons(q{execall}),
	 q{Execute all the statements in the current entry window.} );
	$self->bind_message( $self->buttons(q{clear}),
	 q{Clear entry and results windows.} );
	$self->bind_message( $self->buttons(q{commit}),
	 q{Commit results to the database.} );
	$self->bind_message( $self->buttons(q{rollback}),
	 q{Rollback results from database.} );
	$self->bind_message( $self->buttons(q{close}), q{Close current shell});

}

sub AUTOLOAD {
	my $self = shift;
	my $type = ref($self) || croak "$self is not an object";
	use vars qw($AUTOLOAD);
	my $option = $AUTOLOAD;
	$option =~ s/.*:://;
	
	unless (exists $self->{$option}) {
		croak "Can't access '$option' field in object of class $type";
	}
	if (@_) {
		return $self->{$option} = shift;
	} else {
		return $self->{$option};
	}
	croak qq{This line shouldn't ever be seen}; #'
}
1;
