package Padre::Plugin::Shell::Filter;
use base 'Padre::Plugin::Shell::Base';

use 5.008;
use strict;
use warnings;
use Padre::Constant ();
use Padre::Current  ();
use Padre::Wx       ();

our $VERSION = '0.1';

########################################################################
#
sub plugin_menu {
    my ($self) = @_;
    my @menu   = ();
    my %config = $self->get_config();
    my @accel_keys = ( 0 .. 9, 'A' .. 'Z' );
    foreach my $filter ( sort keys %config ) {
        my $accel = '';
        if (@accel_keys) {
            my $a = shift @accel_keys;
            $accel = '&' . $a . ' - ';
        }
        push @menu, "$accel$filter" => sub { $self->run_filter($filter) };
    }
    push @menu, '---' => undef;
    push @menu, Wx::gettext("&Configure Filters") => sub { $self->edit_config_file() },;

    return @menu;
}

sub example_config {
    my ($self) = @_;
    my $config = <<'EOT';
---
Sort:
  command: 'sort [% IN %] > [% OUT %]'
  description: Sort the selected text
  input: either
  output: replace
Sort Numeric:
  command: 'sort -n [% IN %] > [% OUT %]'
  description: Numerically sort the selected text
  input: either
  output: replace
Sort Unique:
  command: 'sort -u [% IN %] > [% OUT %]'
  description: Uniquely sort the selected text
  input: either
  output: replace

EOT
    return $config;
}

sub run_filter {
    my ( $self, $filter ) = @_;
    my %config = $self->get_config();
    if ( exists $config{$filter} ) {

        my $editor = Padre::Current->editor or return;

        # TODO complain if no editor?

        ################################################################
        # Setup the environment
        $self->update_environment_vars();

        ################################################################
        # Resolve/obtain the input text
        my $input         = $config{$filter}{input} || 'either';
        my $input_text    = '';
        my $selected_text = $editor->GetSelectedText() || '';
        if ( $input =~ m/selection/i && length($selected_text) > 0 ) {
            $input_text = $selected_text;
        }
        elsif ( $input =~ m/document/i ) {
            $editor->SelectAll();
            $input_text = $editor->GetText();
        }
        elsif ( $input =~ m/line/i ) {
            my $pos  = $editor->GetCurrentPos();
            my $line = $editor->LineFromPosition($pos);
            $editor->SetSelection( $editor->PositionFromLine($line), $editor->GetLineEndPosition($line) );
            $input_text = $editor->GetSelectedText();
        }
        elsif ( $input =~ m/none/i ) {
            $input_text = '';
        }
        else {
            $self->notify_of_error( Wx::gettext("Unknown input specified for filter.") );
            return;
        }

        ################################################################
        # Run the filter
        # Note that we could use STDIN and STDOUT, except...
        #       - long/large inputs
        #       - not all commands support STDIN/STDOUT?
        #       - Concerns regarding MS Windows
        my $command = $config{$filter}{command};

        my $in_filename = $self->get_temp_file();
        my $IN;
        if ( open $IN, '>', $in_filename ) {
            print $IN $input_text;
            close $IN;
        }

        my $out_filename = $self->get_temp_file();

        $command =~ s/\[\% IN \%\]/$in_filename/;
        $command =~ s/\[\% OUT \%\]/$out_filename/;

        my $rc = system($command);
        if ( $rc == -1 ) {
            $self->notify_of_error( Wx::gettext("Failed to run filter.\n") . $! );
            return;
        }

        ################################################################
        #
        my $output = $config{$filter}{output} || 'append';

        if ( $output =~ m/new/i ) {
            $self->new_document_from_file( $out_filename, 'text/plain' );
        }
        elsif ( $output =~ m/replace/i ) {
            $self->replace_selection_from_file($out_filename);
        }
        elsif ( $output =~ m/append/i ) {
            $self->append_selection_from_file($out_filename);
        }
        else {
            $self->notify_of_error( Wx::gettext("Unknown output specified for filter.") );
            return;
        }

        $self->delete_temp_file($in_filename);
        $self->delete_temp_file($out_filename);
    }
}

1;

=pod

=head1 NAME

Padre::Plugin::Shell::Filter - Unix-like external filters in Padre.

=head1 DESCRIPTION

This plug-in enables the use of Unix-like external filtering 
commands/scripts to transform part or all of the current document.

The output of the filter can either replace the input, be appended to 
the input, or be inserted into a new document.

Unlike Unix filters, the filter mechanism in this plug-in 
is designed to use input and output files rather than STDIN and STDOUT. 

=head1 CONFIGURATION

Filter definitions are stored in a YAML formatted configuration file
in the user's Padre configuration directory (C<~/.padre>).
Each filter is labeled with the name that is to be displayed in the 
filter menu. In addition to the name there are four attributes for 
each filter definition:

=over

=item B<command> -- The command to run to perform the filtering. There 
are two placeholders in the command string C<[% IN %]> and C<[% OUT %]>
for the input and output filenames used in running the filter. 

=item B<description> A description of what the filter does (optional).

=item B<input> The source of the text to filter. Valid values are 
I<selection>, I<document>, I<line>, and I<none>. I<Selection> may be 
combined with either I<document>, I<line>, or I<none>.
The default value is I<selection,document>.

=over

=item B<selection> -- There needs to be a text selection for the filter 
to run, and the filter is run using the selected text as input. 

=item B<document> -- The filter uses the entire document as input 
whether there is selected text or not. 

=item B<line> -- The filter uses the current line as input 
whether there is selected text or not. 

=item B<none> -- Do not use any text as the input to the filter.

=item B<selection,(document|line|none)> -- If there is a text selection 
then the filter uses the selected text as input. 
If there is no selected text then the filter falls back to using the other 
specified source (document, line, or none) as input.

=back

=item B<output> The action to take with the output. Valid values are 
I<replace>, I<append>, and I<new>. The default value is I<append>.

=over

=item B<append> -- Appends the filter results after the input.

=item B<replace> -- Replaces the input with the filter results.

=item B<new> -- Creates a new document with the filter results.

=back

=back

=head1 ENVIRONMENT VARIABLES

To provide additional information for the filters, various
environment variables are set prior to running the filter.  
These environment variables are covered in the 
L<Padre::Plugin::Shell::Base> documentation.

=head1 METHODS

=head2 plugin_menu

Generates and returns a menu of the defined filters.

=head2 example_config

Returns an example configuration. This is the initial configuration 
that gets created the first time that this plugin is used.

=head2 run_filter($filter_name)

Searches the filter configuration for a filter definition that 
matches the supplied $filter_name. If a matching filter is found 
then that filter is run.

=head1 ISSUES

When adding entries to the configuration file it appears to be necessary 
to have an empty line at the end of the file in order for the configuration 
to properly load. No properly loaded configuration results in no menu 
for the plug-in.

=head1 AUTHOR

Gregory Siems E<lt>gsiems@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Gregory Siems

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
