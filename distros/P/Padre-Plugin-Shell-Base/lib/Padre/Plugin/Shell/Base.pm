package Padre::Plugin::Shell::Base;

use 5.008;
use strict;
use warnings;
use Padre::Constant ();
use Padre::Current  ();
use Padre::Wx       ();
use File::Temp qw/ tempfile /;
use YAML qw/DumpFile LoadFile/;

our $VERSION = '0.13';

########################################################################
#
sub new {
    my $class = shift;
    my $self = bless {}, $class;
    return $self;
}

sub plugin_menu {
    warn "sub plugin_menu is missing!\n";
    return undef;
}

sub notify_of_error {
    my ( $self, $message ) = @_;
    Padre::Current->main->message( $message, Wx::gettext("Error") );
}

########################################################################
#
sub update_environment_vars {
    my ($self) = @_;

    # Clear out the PE_* environment variables to ensure there are
    # no previous values hanging around.
    foreach my $var qw(PE_CURRENT_WORD
        PE_CURRENT_LINE
        PE_COLUMN_INDEX
        PE_COLUMN_NUMBER
        PE_LINE_INDEX
        PE_LINE_NUMBER
        PE_LINE_COUNT
        PE_FILEPATH
        PE_BASENAME
        PE_DIRECTORY
        PE_MIMETYPE
        PE_CONFIG_DIR
        PE_INDENT_TAB_WIDTH
        PE_INDENT_WIDTH
        PE_INDENT_TAB
        PE_DEF_PROJ_DIR
        ) {
        delete $ENV{$var};
        };

    # Configuration variables
    my $padre_config = Padre::Current->main->ide->config;
    if ($padre_config) {
        $ENV{PE_CONFIG_DIR}       = Padre::Constant::CONFIG_DIR;
        $ENV{PE_DEF_PROJ_DIR}     = $padre_config->default_projects_directory;
        $ENV{PE_INDENT_TAB_WIDTH} = $padre_config->editor_indent_tab_width;
        $ENV{PE_INDENT_WIDTH}     = $padre_config->editor_indent_width;
        $ENV{PE_INDENT_TAB}       = ( $padre_config->editor_indent_tab ) ? 'YES' : 'NO';
    }

    my $editor = Padre::Current->editor or return;

    # Document content/statistics information
    my $pos            = $editor->GetCurrentPos();
    my $line           = $editor->LineFromPosition($pos);
    my $line_start_pos = $editor->PositionFromLine($line);
    my $line_end_pos   = $editor->GetLineEndPosition($line);
    my $word_start_pos = $editor->WordStartPosition( $pos, 1 );
    my $word_end_pos   = $editor->WordEndPosition( $pos, 1 );
    $ENV{PE_CURRENT_WORD} = $editor->GetTextRange( $word_start_pos, $word_end_pos );
    $ENV{PE_CURRENT_LINE} = $editor->GetTextRange( $line_start_pos, $line_end_pos );
    $ENV{PE_COLUMN_INDEX} = $pos - $line_start_pos;
    $ENV{PE_COLUMN_NUMBER} = $pos - $line_start_pos + 1;
    $ENV{PE_LINE_INDEX}    = $line;
    $ENV{PE_LINE_NUMBER}   = $line + 1;
    $ENV{PE_LINE_COUNT}    = $editor->GetLineCount();

    # Document metadata
    # Ensure that the document has been saved before trying to access 
    # this information.
    my $document = $editor->{Document};
    if ( $document && !$document->is_new() ) {
        $ENV{PE_FILEPATH}  = $document->filename();
        $ENV{PE_BASENAME}  = $document->basename();
        $ENV{PE_DIRECTORY} = $document->dirname();
        $ENV{PE_MIMETYPE}  = $document->mimetype();
    }
}

########################################################################
# Document/file interaction
sub new_document_from_file {
    my ( $self, $file_name, $mimetype ) = @_;

    # Load up a new editor tab...
    my $main = Padre::Current->main;
    $main->on_new;

    # ...and insert the text into the tab.
    # (Mostly shamelessly copied from Padre::Wx::Main b.t.w.)
    my $new_editor = Padre::Current->editor or return;

    if ( $new_editor->insert_from_file($file_name) ) {
        my $document = $new_editor->{Document};
        $document->{original_content} = $document->text_get;
        $mimetype ||= $document->guess_mimetype;
        $document->set_mimetype($mimetype);
        $document->editor->padre_setup;
        $document->rebless;
        $document->colourize;
    }
}

sub replace_selection_from_file {
    my ( $self, $file_name ) = @_;
    my $editor = Padre::Current->editor or return;
    my $file_text = $self->slurp_file($file_name);
    $editor->ReplaceSelection($file_text);
}

sub append_selection_from_file {
    my ( $self, $file_name ) = @_;
    my $editor    = Padre::Current->editor or return;
    my $file_text = $self->slurp_file($file_name);
    my $sel_end   = $editor->GetSelectionEnd() || 0;
    $editor->GotoPos($sel_end);
    $editor->insert_text( "\n" . $file_text );
}

########################################################################
# File utility
sub slurp_file {
    my $self = shift;
    local ( *ARGV, $/ );
    @ARGV = shift;
    <>;
}

sub get_temp_file {
    my $self = shift;
    my ( $fh, $filename ) = tempfile( '.PF_XXXXXXXX', UNLINK => 1 );
    close $fh;
    return $filename;
}

sub delete_temp_file {
    my ( $self, $filename ) = @_;
    ( -f $filename ) && unlink $filename;
}

########################################################################
# Configuration files
sub config_file {
    my $class = ref $_[0] || $_[0];
    my $name = join '_', (split /\W+/, $class);
    my $file_name = $name . '.yml';
    return File::Spec->catfile( Padre::Constant::CONFIG_DIR, $file_name );
}

sub initialize_config_file {
    my ($self) = @_;
    my $config_file = $self->config_file();

    # Create a skeleton/example config if needed
    unless ( -f $config_file ) {
        my $OUT;
        if ( open( $OUT, '>', $config_file ) ) {
            my $config = $self->example_config();
            print $OUT $config;
            close $OUT;
        }
    }
}

sub example_config {
    warn "sub example_config is missing!\n";
    return '';
}

sub edit_config_file {
    my ($self) = @_;
    my $config_file = $self->config_file();

    ( -f $config_file ) || $self->initialize_config_file();

    if ( -f $config_file ) {
        my $main = Padre::Current->main or return;
        $main->setup_editors($config_file);
    }
}

sub get_config {
    my ($self) = @_;
    my $config_file = $self->config_file();
    ( -f $config_file ) || $self->initialize_config_file();
    my %config = %{ LoadFile($config_file) };
    return %config;
}

1;

=pod

=head1 NAME

Padre::Plugin::Shell::Base - A base class for Padre plugins.

=head1 DESCRIPTION

Base class for plugins that use the system shell to extend Padre.

=head2 Example

Subclass Padre::Plugin::Shell::Base to create a plugin.

    package Padre::Plugin::Shell::Foo;
    use base 'Padre::Plugin::Shell::Base';

    use 5.008;
    use strict;
    use warnings;
    use Padre::Wx       ();

    sub plugin_menu {
        my ($self) = @_;
        my @menu   = ();
        push @menu, "Do Foo" => sub {$self->do_foo()};
        push @menu, '---' => undef;
        push @menu, Wx::gettext("&Configure Foo") => sub { $self->edit_config_file() },;
        return @menu;
    }

    sub example_config {
        my ($self) = @_;
        my $config = "---\n";

        # additional config
        return $config;
    }

    sub do_foo {
        my ( $self ) = @_;
        my %config = $self->get_config();

        # additional foo
    }
    1;

Subclass Padre::Plugin to wrap the plugin.

    package Padre::Plugin::Foo;
    use base 'Padre::Plugin';

    use 5.008;
    use strict;
    use warnings;
    use Padre::Plugin ();
    use Padre::Plugin::Shell::Foo;

    our $VERSION = '0.01';

    my $foo_plugin;

    sub plugin_name {
        'Foo';
    }

    sub padre_interfaces {
        'Padre::Plugin' => 0.43;
    }

    sub menu_plugins_simple {
        my ($self) = @_;
        $foo_plugin = Padre::Plugin::Shell::Foo->new();
        'Foo' => [$plugin->plugin_menu()];
    }
    1;

=head1 ENVIRONMENT VARIABLES

To provide additional information for the plugins, the following 
environment variables are set prior to performing the plugin action:

=over

=over

=item B<PE_CURRENT_WORD> -- The I<word> at the caret position.

=item B<PE_CURRENT_LINE> -- The text of the current line.

=item B<PE_COLUMN_INDEX> -- The index of the position of the caret in the 
current line (counting from 0).

=item B<PE_COLUMN_NUMBER> -- The column number of the caret in the current 
line (counting from 1).

=item B<PE_LINE_INDEX> -- The index of the current line (counting from 0).

=item B<PE_LINE_NUMBER> -- The line number of the current line (counting from 1).

=item B<PE_LINE_COUNT> -- The count of lines in the document.

=item B<PE_BASENAME> -- The file name of the current document.

=item B<PE_DIRECTORY> -- The directory of the current document.

=item B<PE_FILEPATH> -- The full path and name of the current document.

=item B<PE_MIMETYPE> -- The mime-type of the current document.

=item B<PE_CONFIG_DIR> -- Location of the configuration directory (C<~/.padre>)

=item B<PE_DEF_PROJ_DIR> -- The default project directory.

=item B<PE_INDENT_TAB> -- Use tabs for indentation. 'YES' or 'NO'

=item B<PE_INDENT_TAB_WIDTH> -- Tab width/size.

=item B<PE_INDENT_WIDTH> -- Indentation width/size.

=back

=back

=head1 METHODS

=head2 Document/file interaction methods

=head4 append_selection_from_file ($file_pathname)

Takes the contents of C<$file_pathname> and appends it to after 
the selection in the current editor tab.

=head4 new_document_from_file ($file_pathname, $mimetype)

Creates a new document from the contents in C<$file_pathname>. 
The (optional) C<$mimetype> tells Padre what kind of document is 
being created. If no mimetype is specified the Padre will be attempt 
to guess the mimetype.

=head4 replace_selection_from_file ($file_pathname)

Takes the contents of C<$file_pathname> and uses it to replace 
the selection in the current editor tab.

=head2 File utility methods

=head4 get_temp_file 

Creates a temporary file and returns the pathname of the temporary file.

=head4 delete_temp_file ($file_pathname)

Deletes a temporary file.

=head4 slurp_file ($file_pathname)

Returns the contents of the specified file.

=head2 Configuration file methods

B<NOTE>: Plugin configurations are stored using YAML.

=head4 config_file 

Returns the pathname of a plugin configuration file.

=head4 edit_config_file  

Opens the configuration file for a plugin for editing.

=head4 example_config  

Returns an example configuration for a plugin. Is to be overwritten 
by plugins that subclass this package.

=head4 get_config  

Returns a hash containing the configuration for a plugin.

=head4 initialize_config_file  

Initializes a configuration file for a plugin using the return 
value from C<example_config>.

=head2 Environment variable methods

=head4 update_environment_vars  

Updates the environment variables supported by plugins that 
subclass this package. See the ENVIRONMENT VARIABLES section for details.

=head2 Other methods

=head4 new 

The cannonical new method.

=head4 plugin_menu  

Returns the menu for a plugin. Is to be overwritten by plugins that 
subclass this package.

=head4 notify_of_error 

Displays an error message.

=head1 AUTHOR

Gregory Siems E<lt>gsiems@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Gregory Siems

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
