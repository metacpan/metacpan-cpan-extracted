package Padre::Plugin::Snippet::Document;

use 5.008;
use Moose;
use Padre::Wx ();

our $VERSION = '0.01';

use Moose::Util::TypeConstraints;

class_type 'SnippetPerlDocument', { class => 'Padre::Document::Perl' };
class_type 'SnippetEditor',       { class => 'Padre::Wx::Editor' };

has 'config'   => ( is => 'rw', isa => 'HashRef',             required => 1 );
has 'document' => ( is => 'rw', isa => 'SnippetPerlDocument', required => 1 );
has 'editor'   => ( is => 'rw', isa => 'SnippetEditor',       required => 1 );

# Called when the document is created
sub BUILD {
	my $self = shift;

	# Register events for the editor
	$self->_register_events;

	return;
}

# Called when the document is destroyed
sub cleanup {
	my $self   = shift;
	my $editor = $self->editor;

	Wx::Event::EVT_KEY_DOWN( $editor, undef );
	Wx::Event::EVT_CHAR( $editor, undef );
	Wx::Event::EVT_LEFT_UP( $editor, undef );

	return;
}

# Register key down and character typed and mouse up events
sub _register_events {
	my $self   = shift;
	my $editor = $self->editor;

	Wx::Event::EVT_KEY_DOWN(
		$editor,
		sub {
			if ( $self->can('_on_key_down') ) {
				$self->_on_key_down(@_);
			} else {

				# Method not found, document mimetype change
				# so that padre does not crash :)
				$_[1]->Skip(1);
				Wx::Event::EVT_KEY_DOWN( $editor, undef );
			}
		}
	);
	Wx::Event::EVT_CHAR(
		$editor,
		sub {
			if ( $self->can('_on_char') ) {
				$self->_on_char(@_);
			} else {

				# Method not found, document mimetype change
				# so that padre does not crash :)
				$_[1]->Skip(1);
				Wx::Event::EVT_CHAR( $editor, undef );
			}
		}
	);

	# Called by when a mouse up event occurs
	Wx::Event::EVT_LEFT_UP(
		$editor,
		sub {
			$self->_end_snippet_mode($editor);

			# Keep processing
			$_[1]->Skip(1);
		},
	);

	return;
}

# Called when the a key is pressed
sub _on_key_down {
	my $self   = shift;
	my $editor = shift;
	my $event  = shift;

	my $config = $self->config;

	# Shortcut if snippets feature is disabled
	unless ( $config->{feature_snippets} ) {

		# Keep processing and exit
		$event->Skip(1);
		return;
	}

	# Load snippets everything since it be changed by the user at runtime
	$self->_load_snippets($config);

	if ( $self->_can_end_snippet_mode($event) ) {
		$self->_end_snippet_mode($editor);
	} elsif ( defined $self->{_snippets} && $event->GetKeyCode == Wx::WXK_TAB ) {
		my $result =
			  $event->ShiftDown()
			? $self->_previous_variable($editor)
			: $self->_start_snippet_mode($editor);
		if ( defined $result ) {

			# Consume the <TAB>-triggerred snippet event
			return;
		}
	} elsif ( defined $self->{variables}
		&& $event->GetKeyCode == Wx::WXK_BACK
		&& $self->can('_on_char') )
	{
		$self->_on_char( $editor, $event );
		return;
	}

	# Keep processing events
	$event->Skip(1);

	return;
}

# Called when a printable character is typed
sub _on_char {
	my $self   = shift;
	my $editor = shift;
	my $event  = shift;

	unless ( defined $self->{variables} ) {

		# Keep processing
		$event->Skip(1);
		return;
	}

	my $pos            = $self->{_pos};
	my $start_position = $pos - length( $self->{_trigger} );
	my $new_pos;
	for my $var ( @{ $self->{variables} } ) {
		if ( $self->{selected_index} == $var->{index} ) {
			my $key = $event->GetKeyCode;
			if ( $key == Wx::WXK_BACK && length( $var->{value} ) == 1 ) {
				$self->_end_snippet_mode($editor);
				$event->Skip(1);
				return;
			}
			if ( defined $self->{pristine} ) {

				$var->{value}     = chr($key);
				$self->{pristine} = undef;

			} else {
				if ( $key == Wx::WXK_BACK ) {
					$var->{value} = substr( $var->{value}, 0, -1 );
				} else {
					$var->{value} .= chr($key);
				}
			}
			$new_pos = $start_position + $var->{start} + length( $var->{value} );
			last;
		}
	}

	# Expand the snippet
	my ( $text, $cursor ) = $self->_expand_snippet( $self->{_snippet} );

	$editor->SetTargetStart($start_position);
	$editor->SetTargetEnd( $start_position + length( $self->{_text} ) );
	$editor->ReplaceTarget($text);
	$editor->GotoPos($new_pos);

	$self->{_text} = $text;

	return;
}

sub _end_snippet_mode {
	my $self   = shift;
	my $editor = shift;

	if ( defined $self->{variables} ) {

		# Stop snippet mode
		$self->{variables} = undef;

		# Clear the selected text
		my $current_pos = $editor->GetCurrentPos;
		$editor->SetSelection( $current_pos, $current_pos );
	}
}

# Load snippets from file according to code generation type
sub _load_snippets {
	my $self   = shift;
	my $config = shift;

	eval {
		require YAML;
		require File::ShareDir;
		require File::Spec;

		# Determine the snippets filename
		my $file;
		my $type = $config->{type};
		if ( $type eq 'Mouse' ) {

			# Mouse snippets
			$file = 'mouse.yml';
		} elsif ( $type eq 'MooseX::Declare' ) {

			# MooseX::Declare snippets
			$file = 'moosex_declare.yml';
		} else {

			# Moose by default
			$file = 'moose.yml';
		}

		# Shortcut if that snippet type is already loaded in memory
		return
			if defined( $self->{_snippets_type} )
				and ( $type eq $self->{_snippets_type} );

		# Determine the full share/${snippets_filename}
		my $filename = File::ShareDir::dist_file(
			'Padre-Plugin-Snippet',
			File::Spec->catfile( 'snippets', $file )
		);

		# Read the dialect snippet file
		my $dialect_snippets = YAML::LoadFile($filename);

		# Workaround: Load perl snippets :)
		# TODO add automatic parent snippet support
		my $perl_filename = File::ShareDir::dist_file(
			'Padre-Plugin-Snippet',
			File::Spec->catfile( 'snippets', 'perl.yml' )
		);
		my $snippets = YAML::LoadFile($perl_filename);
		for my $trigger ( keys %{$dialect_snippets} ) {
			if ( defined $snippets->{$trigger} ) {
				warn "Trigger: $trigger is already in parent snippet file\n";
			}
			$snippets->{$trigger} = $dialect_snippets->{$trigger};
		}

		# The final merged snippet file
		$self->{_snippets} = $snippets;

		# Record loaded snippet type
		$self->{_snippets_type} = $type;
	};

	# Report error to padre logger
	warn "Unable to load snippet. Reason: $@\n"
		if $@;

	return;
}

# Returns whether the key can end snippet mode or not
sub _can_end_snippet_mode {
	my $self  = shift;
	my $event = shift;

	my $key = $event->GetKeyCode;
	return
		   $event->ControlDown && $key != Wx::WXK_TAB
		|| $event->AltDown
		|| ( $key == Wx::WXK_ESCAPE
		|| $key == Wx::WXK_UP
		|| $key == Wx::WXK_DOWN
		|| $key == Wx::WXK_RIGHT
		|| $key == Wx::WXK_LEFT
		|| $key == Wx::WXK_HOME
		|| $key == Wx::WXK_END
		|| $key == Wx::WXK_DELETE
		|| $key == Wx::WXK_PAGEUP
		|| $key == Wx::WXK_PAGEDOWN
		|| $key == Wx::WXK_NUMPAD_UP
		|| $key == Wx::WXK_NUMPAD_DOWN
		|| $key == Wx::WXK_NUMPAD_RIGHT
		|| $key == Wx::WXK_NUMPAD_LEFT
		|| $key == Wx::WXK_NUMPAD_HOME
		|| $key == Wx::WXK_NUMPAD_END
		|| $key == Wx::WXK_NUMPAD_DELETE
		|| $key == Wx::WXK_NUMPAD_PAGEUP
		|| $key == Wx::WXK_NUMPAD_PAGEDOWN );
}

# Called when SHIFT-TAB is pressed
sub _previous_variable {
	my $self   = shift;
	my $editor = shift;

	# Only in snippet mode
	return unless defined $self->{variables};

	# Already in snippet mode
	$self->{selected_index}--;

	if ( $self->{selected_index} < 1 ) {

		# Shift-tabbing to traverse them in circular fashion
		$self->{selected_index} = $self->{last_index};
	}

	$self->{pristine} = 1;

	for my $var ( @{ $self->{variables} } ) {
		if ( $var->{index} == $self->{selected_index} ) {
			my $start = $self->{_pos} - length( $self->{_trigger} ) + $var->{start};
			$editor->GotoPos($start);
			$editor->SetSelection( $start, $start + length( $var->{value} ) );

			last;
		}
	}

	return 1;
}

# Starts snippet mode when TAB is pressed
sub _start_snippet_mode {
	my $self   = shift;
	my $editor = shift;

	my ( $pos, $snippet, $trigger ) = $self->_prepare_snippet_info($editor)
		or return;
	my ( $first_time, $last_time ) = $self->_build_variables_info($snippet);

	# Prepare to replace variables
	# Find the next cursor
	my ( $text, $cursor ) = $self->_expand_snippet($snippet);

	# We paste the snippet and position the cursor to
	$self->_insert_snippet( $editor, $cursor, $text, $first_time, $last_time );

	# Snippet inserted
	return 1;
}

sub _prepare_snippet_info {
	my $self   = shift;
	my $editor = shift;

	my ( $pos, $snippet, $trigger );
	if ( defined $self->{variables} ) {
		$pos     = $self->{_pos};
		$snippet = $self->{_snippet};
		$trigger = $self->{_trigger};
	} else {
		$pos = $editor->GetCurrentPos;
		my $line = $editor->GetTextRange(
			$editor->PositionFromLine( $editor->LineFromPosition($pos) ),
			$pos
		);

		my $o = $self->_find_snippet($line);
		return unless defined $o;

		$self->{_pos} = $pos;
		$snippet = $self->{_snippet} = $o->{snippet};
		$trigger = $self->{_trigger} = $o->{trigger};
	}

	return ( $pos, $snippet, $trigger );
}

# Collect and highlight all variables in the snippet
sub _build_variables_info {
	my $self    = shift;
	my $snippet = shift;
	my $vars;
	my $first_time;
	my $last_time;
	if ( defined $self->{variables} ) {

		# Already in snippet mode
		$vars = $self->{variables};
		$self->{selected_index}++;

		if ( $self->{selected_index} > $self->{last_index} ) {

			# exit snippet mode and position at end
			$self->{variables} = undef;
			$last_time = 1;
		}
		$self->{pristine} = 1;

	} else {

		# Not defined, create an empty one
		$vars = $self->{variables} = [];
		$self->{selected_index} = 1;
		$self->{pristine}       = 1;
		$first_time             = 1;

		# Build snippet variables array
		my $last_index = 0;
		while (
			$snippet =~ /
			(		# int is integer
			\${(\d+)(?: \:((?:[^\\]|\\.)*?))?}     # ${int:default value} or ${int}
			|  \$(\d+)              # $int
		)/gx
			)
		{
			my $index = defined $4 ? int($4) : int($2);
			if ( $last_index < $index ) {
				$last_index = $index;
			}
			my $value = $3;
			if ( defined $value ) {

				# expand escaped text
				$value =~ s/\\(.)/$1/g;
			} else {

				# Handle ${1}, ${2}... etc
				unless ( defined $4 ) {
					$value = '';
				}
			}
			my $start = pos($snippet) - length($1);
			my $var   = {
				index      => $index,
				text       => $1,
				value      => $value,
				orig_start => $start,
				start      => $start,
			};
			push @$vars, $var;
		}
		$self->{last_index} = $last_index;
	}

	return ( $first_time, $last_time );
}

# Returns the snippet template or undef
sub _find_snippet {
	my $self = shift;
	my $line = shift;

	my $indent = $line =~ /^(\s*)/ ? $1 : '';
	my %snippets = %{ $self->{_snippets} };
	for my $trigger ( keys %snippets ) {
		if ( $line =~ /\b\Q$trigger\E$/ ) {

			# Add indentation after the first line
			my $snippet    = '';
			my $first_time = 1;
			my $eol        = $self->document->newline;
			for my $line ( split /\n/, $snippets{$trigger} ) {
				if ($first_time) {
					$snippet .= $line . $eol;
					$first_time = 0;
				} else {
					$snippet .= $indent . $line . $eol;
				}
			}

			# chomp it from that last line!
			chomp $snippet;

			return {
				trigger => $trigger,
				snippet => $snippet,
			};
		}
	}

	return;
}

# Returns an expanded snippet with all the variables filled in
sub _expand_snippet {
	my $self = shift;
	my $text = shift;

	my $cursor;
	my $count = 0;
	my $vars  = $self->{variables};
	for my $var (@$vars) {
		unless ( defined $var->{value} ) {
			my $index = $var->{index};
			for my $v (@$vars) {
				my $value = $v->{value};
				if ( ( $v->{index} == $index ) && defined $value ) {
					( $text, $count ) = $self->_replace_value( $text, $var, $value, $count );
					last;
				}
			}
		} else {
			( $text, $count ) = $self->_replace_value( $text, $var, $var->{value}, $count );

			if ( $var->{index} == $self->{selected_index} ) {
				$cursor = $var;
			}
		}

	}

	return ( $text, $cursor );
}

sub _replace_value {
	my $self  = shift;
	my $text  = shift;
	my $var   = shift;
	my $value = shift;
	my $count = shift;

	my $length0 = length $text;
	$var->{start} = $var->{orig_start} + $count;
	substr( $text, $var->{start}, length $var->{text} ) = $value;
	$count += length($text) - $length0;

	return ( $text, $count );
}

sub _insert_snippet {
	my $self       = shift;
	my $editor     = shift;
	my $cursor     = shift;
	my $text       = shift;
	my $first_time = shift;
	my $last_time  = shift;

	my $pos            = $self->{_pos};
	my $start_position = $pos - length( $self->{_trigger} );
	if ($first_time) {
		$editor->SetTargetStart($start_position);
		$editor->SetTargetEnd($pos);
		$editor->ReplaceTarget($text);

		my $start = $start_position + $cursor->{start};
		$editor->GotoPos($start);
		$editor->SetSelection( $start, $start + length $cursor->{value} );
	} else {
		if ($last_time) {
			$editor->GotoPos( $start_position + length $text );
		} else {
			$editor->SetTargetStart($start_position);
			$editor->SetTargetEnd( $start_position + length $text );
			$editor->ReplaceTarget($text);

			my $start = $start_position + $cursor->{start};
			$editor->GotoPos($start);
			$editor->SetSelection( $start, $start + length $cursor->{value} );
		}
	}

	$self->{_text} = $text;
}

no Moose::Util::TypeConstraints;
no Moose;

1;

__END__

=pod

=head1 NAME

Padre::Plugin::Snippet::Document - A Perl document that understands Snippets

=cut
