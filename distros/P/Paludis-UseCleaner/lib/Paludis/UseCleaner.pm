use strict;
use warnings;

package Paludis::UseCleaner;
BEGIN {
  $Paludis::UseCleaner::VERSION = '0.01000307';
}

# ABSTRACT: Remove cruft from your use.conf


use Moose;
use MooseX::Types::Moose qw( :all );
use MooseX::Types::Perl qw( :all );
use Cave::Wrapper;
use namespace::autoclean -also => qr/^__/;
use IO::Handle;
use Class::Load 0.06 qw( load_class );
use Moose::Util::TypeConstraints qw( class_type );
use MooseX::Has::Sugar;


has 'input' => ( isa => GlobRef, rw, required );


has 'output' => ( isa => GlobRef, rw, required );


has 'rejects' => ( isa => GlobRef, rw, required );


has 'debug' => ( isa => GlobRef, rw, required );


has 'dot_trace' => ( isa => GlobRef, rw, required );


has 'display_ui' => ( isa => Object, rw, lazy_build );


has 'display_ui_class' => ( isa => ModuleName, rw, lazy_build );


has 'display_ui_generator' => ( isa => CodeRef, rw, lazy_build );


sub do_work {

  my ($self) = shift;
  my $cave = Cave::Wrapper->new();

  $self->dot_trace->autoflush(1);

  while ( defined( my $line = $self->input->getline ) ) {

    my $lineno = $self->input->input_line_number;

    my (@tokens) = __tokenize($line);

    if ( __is_empty_line(@tokens) ) {
      $self->output->print($line);
      $self->display_ui->skip_empty( $lineno, $line );
      next;
    }
    if ( __is_star_rule(@tokens) ) {
      $self->output->print($line);
      $self->display_ui->skip_star( $lineno, $line );
      next;
    }
    $self->display_ui->dot_trace();

    my ( $spec, $use, $extras ) = __tokenparse(@tokens);

    $self->display_ui->full_rule( $spec, $use, $extras );

    my @packages = $cave->print_ids( '-m', $spec );

    if ( not @packages ) {
      $self->display_ui->nomatch( $lineno, $line );
      $self->rejects->print($line);
      next;
    }

    $self->output->print($line);
  }
  return;
}


sub __tokenize {
  my $line = shift;
  $line =~ s/#.*$//;
  return split /\s+/, $line;
}


## no critic (RequireArgUnpacking)

sub __is_empty_line {
  return not @_;
}


## no critic (RequireArgUnpacking)

sub __is_star_rule {
  return $_[0] =~ /\*/;
}


sub __tokenparse {
  my @tokens   = @_;
  my $spec     = shift @tokens;
  my @useflags = __extract_flags( \@tokens );
  my %extras;
  while ( defined( my $current = __extract_label( \@tokens ) ) ) {
    $extras{$current} = [ __extract_flags( \@tokens ) ];
  }
  return ( $spec, \@useflags, \%extras );
}


## no critic (ProhibitDoubleSigils)

sub __extract_flags {
  my $in = shift;
  my @out;
  while ( exists $in->[0] && $in->[0] !~ /^([A-Z_]+):$/ ) {
    push @out, shift @$in;
  }
  return @out;
}


## no critic (ProhibitDoubleSigils)
sub __extract_label {
  my $in = shift;
  return if not exists $in->[0];
  return if not $in->[0] =~ /^([A-Z_]+):$/;
  my $result = $1;
  shift @$in;
  return $result;
}


sub _build_display_ui_class {
  return 'Paludis::UseCleaner::ConsoleUI';
}


sub _build_display_ui_generator {
  my $self = shift;
  return sub {
    load_class( $self->display_ui_class );
    return $self->display_ui_class->new(
      fd_debug     => $self->debug,
      fd_dot_trace => $self->dot_trace,
    );
  };
}


sub _build_display_ui {
  my $self = shift;
  return $self->display_ui_generator()->($self);
}

no Moose;
no Moose::Util::TypeConstraints;

__PACKAGE__->meta->make_immutable;

1;

__END__
=pod

=head1 NAME

Paludis::UseCleaner - Remove cruft from your use.conf

=head1 VERSION

version 0.01000307

=head1 SYNOPSIS

This module handles the core behaviour of the Use Cleaner, to be consumed inside other applications.

For a "Just Use it" interface, you want L<paludis-usecleaner.pl> and L<Paludis::UseCleaner::App>

    my $cleaner = Paludis::UseCleaner->new(
        input     => somefd,
        output    => somefd,
        rejects   => somefd,
        debug     => fd_for_debugging
        dot_trace => fd_for_dot_traces,
      ( # Optional
        display_ui => $object_to_handle_debug_messages
        display_ui_class => $classname_to_construct_a_display_ui
        display_ui_generator => $coderef_to_generate_object_for_display_ui
      )
    );

    $cleaner->do_work();

=head1 METHODS

=head2 do_work

    $cleaner->do_work();

Executes the various transformations and produces the cleaned output from the input.

=head1 ATTRIBUTES

=head2 input

    $cleaner->input( \*STDIN );
    $cleaner->input( $read_fh );

=head2 output

    $cleaner->output( \*STDOUT );
    $cleaner->output( $write_fh );

=head2 rejects

    $cleaner->rejects( \*STDOUT );
    $cleaner->rejects( $write_fh );

=head2 debug

    $cleaner->debug( \*STDERR );
    $cleaner->debug( $write_fh );

=head2 dot_trace

    $cleaner->dot_trace( \*STDERR );
    $cleaner->dot_trace( $write_fh );

=head2 display_ui

    $cleaner->display_ui( $object );

=head2 display_ui_class

    $cleaner->display_ui_class( 'Some::Class::Name' );

=head2 display_ui_generator

    $cleaner->display_ui_generator( sub {
        my $self = shift;
        ....
        return $object;
    });

=head1 PRIVATE METHODS

=head2 __tokenize

    my @line = __tokenize( $line );

B<STRIPPED>: This method is made invisible to outside code after compile.

=head2 __is_empty_line

    if( __is_empty_line(@line) ){ }

B<STRIPPED>: This method is made invisible to outside code after compile.

=head2 __is_star_rule

    if( __is_star_rule(@line) ){ }

B<STRIPPED>: This method is made invisible to outside code after compile.

=head2 __tokenparse

    my ( $spec, $use, $extras ) = __tokenparse( @line );

B<STRIPPED>: This method is made invisible to outside code after compile.

=head2 __extract_flags

    my ( @flags ) = __extract_flags( \@tokens );

B<STRIPPED>: This method is made invisible to outside code after compile.

=head2 __extract_label

    my ( $label ) = __extract_label( \@tokens );

B<STRIPPED>: This method is made invisible to outside code after compile.

=head2 _build_display_ui_class

    my $class = $cleaner->_build_display_ui_class();

=head2 _build_display_ui_generator

    my $generator  $cleaner->_build_display_ui_generator();

=head2 _build_display_ui

    my $object = $cleaner->_build_display_ui();

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

