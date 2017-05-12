=head1 NAME

RSH::Logging::TextTable - Extension of Text::SimpleTable to handle chunking.

=head1 SYNOPSIS

  use RSH::Logging::TextTable;
  my $table = RSH::Logging::TextTable->new();
  ...
  my $str = $table->draw(); # use original logic
  $table->draw($fh); # write to the filehandle
  my $code = sub {
      $logger->debug(@_);
  }
  $table->draw($code); # send lines/chunks to $code->($line);

=head1 DESCRIPTION

When sending the timing table to Log4Perl, if the table is too large, 
Log4Perl will generate an OOM error.  Chunking solves this.

=cut

package RSH::Logging::TextTable;

use 5.008;
use strict;
use warnings;

use base qw(Exporter Text::SimpleTable);

# use/imports go here
use Text::SimpleTable;
use Scalar::Util qw(blessed);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

=head2 EXPORT

None by default.

=cut

our @EXPORT_OK = qw(

				   );

our @EXPORT    = qw(
					
				   );

# ******************** Class Methods ********************

# ******************** Constructor Methods ********************

=head2 CONSTRUCTORS

=over

=cut

=item new(%ARGS)

Creates a new RSH::Logging::TextTable object.  C<%ARGS> contains
arguments to use in initializing the new instance.

B<Returns:> A new RSH::Logging::TextTable object.

=cut

sub new {
    my($class, @args) = @_;

	my $self = Text::SimpleTable->new(@args);

	bless $self, $class;

	return $self;
}

=back

=cut

# ******************** PUBLIC Instance Methods ********************

=head2 INSTANCE METHODS

=over

=cut

## ******************** Accessors ********************
#
#=back
#
#=head3 Accessors
#
#=over
#
#=cut
#
## place field accessors here
#
#
#=back
#
#=cut
#
# ******************** Functionality ********************

=back

=head3 Functionality

=over

=cut

=item draw([$io_handle | $code_ref ])

Override Text::SimpleTable::draw, allowing optional chunking.

I'm not tremendously wild about copy and pasting the original.  I should probably send
this method as a patch to Text::SimpleTable.

=cut

sub draw {
	my $self = shift;

    # if there are no parameters or they aren't what we expect, just do the original logic
    my ($target) = @_;
    unless ($target and ( (ref($target) eq 'CODE') or (blessed($target) and $target->isa('IO::Handle')) ) ) {
        return $self->SUPER::draw(@_);
    }
    
    # Otherwise, support chunking 
    # (below is copy and pasted from Text::SimpleTable, modified to chunk)
    # Shortcut
    return unless $self->{columns};

    my $out;
    if (ref($target) eq 'CODE') {
        $out = sub {
                $target->(@_);
            };
    }
    else {
        $out = sub {
                print $target @_;
            };
    }

    my $rows    = @{$self->{columns}->[0]->[1]} - 1;
    my $columns = @{$self->{columns}} - 1;
    my $output  = '';

    # Top border
    for my $j (0 .. $columns) {

        my $column = $self->{columns}->[$j];
        my $width  = $column->[0];
        my $text   = $Text::SimpleTable::TOP_BORDER x $width;

        if (($j == 0) && ($columns == 0)) {
            $text = $Text::SimpleTable::TOP_LEFT . $text . $Text::SimpleTable::TOP_RIGHT;
        }
        elsif ($j == 0)        { $text = $Text::SimpleTable::TOP_LEFT . $text . $Text::SimpleTable::TOP_SEPARATOR }
        elsif ($j == $columns) { $text = $text . $Text::SimpleTable::TOP_RIGHT }
        else                   { $text = $text . $Text::SimpleTable::TOP_SEPARATOR }

        $output .= $text;
    }
    $output .= "\n";
    $out->($output); $output = '';

    my $title = 0;
    for my $column (@{$self->{columns}}) {
        $title = @{$column->[2]} if $title < @{$column->[2]};
    }

    if ($title) {

        # Titles
        for my $i (0 .. $title - 1) {

            for my $j (0 .. $columns) {

                my $column = $self->{columns}->[$j];
                my $width  = $column->[0];
                my $text   = $column->[2]->[$i] || '';

                $text = sprintf "%-${width}s", $text;

                if (($j == 0) && ($columns == 0)) {
                    $text = $Text::SimpleTable::LEFT_BORDER . $text . $Text::SimpleTable::RIGHT_BORDER;
                }
                elsif ($j == 0) { $text = $Text::SimpleTable::LEFT_BORDER . $text . $Text::SimpleTable::SEPARATOR }
                elsif ($j == $columns) { $text = $text . $Text::SimpleTable::RIGHT_BORDER }
                else                   { $text = $text . $Text::SimpleTable::SEPARATOR }

                $output .= $text;
            }

            $output .= "\n";
            $out->($output); $output = '';
        }

        # Title separator
        $output .= $self->_draw_hr;
        $out->($output); $output = '';

    }

    # Rows
    for my $i (0 .. $rows) {

        # Check for hr
        if (!grep { defined $self->{columns}->[$_]->[1]->[$i] } 0 .. $columns)
        {
            $output .= $self->_draw_hr;
            $out->($output); $output = '';
            next;
        }

        for my $j (0 .. $columns) {

            my $column = $self->{columns}->[$j];
            my $width  = $column->[0];
            my $text = (defined $column->[1]->[$i]) ? $column->[1]->[$i] : '';

            $text = sprintf "%-${width}s", $text;

            if (($j == 0) && ($columns == 0)) {
                $text = $Text::SimpleTable::LEFT_BORDER . $text . $Text::SimpleTable::RIGHT_BORDER;
            }
            elsif ($j == 0)        { $text = $Text::SimpleTable::LEFT_BORDER . $text . $Text::SimpleTable::SEPARATOR }
            elsif ($j == $columns) { $text = $text . $Text::SimpleTable::RIGHT_BORDER }
            else                   { $text = $text . $Text::SimpleTable::SEPARATOR }

            $output .= $text;
        }

        $output .= "\n";
        $out->($output); $output = '';
    }

    # Bottom border
    for my $j (0 .. $columns) {

        my $column = $self->{columns}->[$j];
        my $width  = $column->[0];
        my $text   = $Text::SimpleTable::BOTTOM_BORDER x $width;

        if (($j == 0) && ($columns == 0)) {
            $text = $Text::SimpleTable::BOTTOM_LEFT . $text . $Text::SimpleTable::BOTTOM_RIGHT;
        }
        elsif ($j == 0) { $text = $Text::SimpleTable::BOTTOM_LEFT . $text . $Text::SimpleTable::BOTTOM_SEPARATOR }
        elsif ($j == $columns) { $text = $text . $Text::SimpleTable::BOTTOM_RIGHT }
        else                   { $text = $text . $Text::SimpleTable::BOTTOM_SEPARATOR }

        $output .= $text;
    }

    $output .= "\n";
    $out->($output); $output = '';

    return $output;
}

=back

=cut

# #################### RSH::Logging::TextTable.pm ENDS ####################
1;

=head1 SEE ALSO

L<Other::Module>

L<http://website/>

=head1 AUTHOR

Matt Luker, E<lt>mluker@rshtech.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2012 by Matt Luker

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

__END__
# TTGOG

# ---------------------------------------------------------------------
#  $Log$
# ---------------------------------------------------------------------