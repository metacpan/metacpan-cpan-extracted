use strict;
use warnings;

package Paludis::UseCleaner::ConsoleUI;
BEGIN {
  $Paludis::UseCleaner::ConsoleUI::VERSION = '0.01000307';
}

# ABSTRACT: SubSpace for handling progress formatting of the cleaner.

use Moose;
use MooseX::Types::Moose qw( :all );
use MooseX::Types::Perl qw( :all );
use MooseX::Has::Sugar;
use IO::Handle;
use Term::ANSIColor;


has show_skip_empty => ( isa => Bool, rw, default => 1 );


has show_skip_star => ( isa => Bool, rw, default => 1 );


has show_dot_trace => ( isa => Bool, rw, default => 0 );


has show_clean => ( isa => Bool, rw, default => 1 );


has show_rules => ( isa => Bool, rw, default => 1 );


has fd_debug => ( isa => GlobRef, rw, required );


has fd_dot_trace => ( isa => GlobRef, rw, required );

my $format = "%s%s\n >> %s\n >  %s%s\n";


sub _message {
  my ( $self, $colour, $label, $line, $reason ) = @_;
  $line =~ s/\n?$//;
  return $self->fd_debug->printf( $format, color($colour), $label, $line, $reason, color('reset') );

}


sub skip_empty {
  my ( $self, $lineno, $line ) = @_;
  $self->dot_trace('>');
  return unless $self->show_skip_empty;
  return $self->_message( 'red', "Skipping $lineno", $line, "Looks empty" );
}


sub skip_star {
  my ( $self, $lineno, $line ) = @_;
  $self->dot_trace('>');
  return unless $self->show_skip_star;
  return $self->_message( 'red', "Skipping $lineno", $line, "* rule" );
}


sub dot_trace {
  my ( $self, $symbol ) = @_;
  return unless $self->show_dot_trace;
  $symbol ||= q{.};
  return $self->fd_dot_trace->print($symbol);
}


sub nomatch {
  my ( $self, $lineno, $line ) = @_;
  $self->dot_trace(q{?});
  return unless $self->show_clean;
  return $self->_message( 'green', "Cleaning $lineno", $line, 'No matching specification' );
}


sub full_rule {
  my ( $self, $spec, $use, $extras ) = @_;
  return unless $self->show_rules;
  $extras->{'use'} = $use;
  my @extradata = map { ( sprintf "%s = [ %s ]", $_, ( join q{, }, @{ $extras->{$_} } ) ) } keys %{$extras};
  return $self->fd_debug->printf( "RULE: spec = $spec %s\n", ( join q{ }, @extradata ) );

}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__
=pod

=head1 NAME

Paludis::UseCleaner::ConsoleUI - SubSpace for handling progress formatting of the cleaner.

=head1 VERSION

version 0.01000307

=head1 METHODS

=head2 skip_empty

    $ui->skip_empty( $lineno, $line )

Notifies user a line has been skipped in the input due to it being empty.
This line has been copied to the output ( cleaned ) file.

=head2 skip_star

    $ui->skip_star( $lineno, $line )

Notifies user a line has been skipped in the input due to it being a * rule,
and thus having far too many possible matches to compute respectably.

This line has been copied to the output ( cleaned ) file.

=head2 dot_trace

    $ui->dot_trace( $symbol = '.' )

Prints a simple progress indicator when show_dot_trace is enabled.

=head2 nomatch

    $ui->nomatch( $lineno, $line )

Notifies use that a line appeared to contain a rule and that rule matched
no packages that exist, both uninstalled and installed, and is thus being removed from the output( cleaned ) file.

Just In case, this line is also copied to the rejects file.

=head2 full_rule

    $extrasmap{VIDEO_CARDS} = \@cardlist;

    $ui->full_rule( $spec, \@useflags, \%extrasmap )

Produces a debug tracing line showing the parsed result of the line as we perceive it internally.

=head1 ATTRIBUTES

=head2 show_skip_empty

    $ui->show_skip_empty( 1 ); # enable showing the empty-line debug
    $ui->show_skip_empty( 0 ); # disable ...

B<default> is C<true>

=head2 show_skip_star

    $ui->show_skip_star( 1 ); # enable showing the * rule debug
    $ui->show_skip_star( 0 ); # disable ...

B<default> is C<true>

=head2 show_dot_trace

    $ui->show_dot_trace( 1 ); # enable showing the dot_trace's
    $ui->show_dot_trace( 0 ); # disable ...

B<default> is C<false>

=head2 show_clean

    $ui->show_clean( 1 ); # enable showing the clean notice
    $ui->show_clean( 0 ); # disable ...

B<default> is C<true>

=head2 show_rules

    $ui->show_rules( 1 ); # enable showing the rule debug
    $ui->show_rules( 0 ); # disable ...

B<default> is C<true>

=head2 fd_debug

    $ui->fd_debug( \*STDOUT ); # debug to stdout
    $ui->fd_debug( $fh ); # debug to a filehandle

=head2 fd_dot_trace

    $ui->fd_dot_trace( \*STDOUT ); # debug to stdout
    $ui->fd_dot_trace( $fh ); # debug to a filehandle

=head1 PRIVATE METHODS

=head2 _message

   ->_message( $colour, $label, $line , $reason )

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

