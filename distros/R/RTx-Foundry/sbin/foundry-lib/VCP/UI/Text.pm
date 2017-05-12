package VCP::UI::Text ;

=head1 NAME

VCP::UI::Text - A textual user interface for VCP.

=head1 SYNOPSIS

    $ vcp        ## VCP::UI::Text is the current default

=head1 DESCRIPTION

This is a text-only user interface for VCP.  It prints out descriptions,
prompts the user, reads the responses, and validates input.

=head1 METHODS

=over

=for test_script 00uitext.t

=cut

$VERSION = 0.1 ;

use strict ;
use VCP::UIMachines;
use VCP::Debug qw( :debug );

use fields (
   'Source',            ## reference to the source plugin object
   'Dest',              ## reference to the destination plugin object
) ;


sub new {
   my $class = shift ;
   $class = ref $class || $class;

   my VCP::UI::Text $self = do {
      no strict 'refs' ;
      bless [ \%{"$class\::FIELDS"} ], $class;
   };

   return $self ;
}

=item ask

    $text_ui->ask( $description, $prompt, $answer_key );

Prompts the user, giving them the possibly lengthy description,
a blank line and a prompt.  Reads a single line of input and
returns it and a reference to the matching answer key.

The answer key looks like:
   
   [
      [ $suggested_answer_1, $validator_1, ... ],
      [ $suggested_answer_2, $validator_2, ... ],
      [ $suggested_answer_3, $validator_3, ... ],
      ...
   ]

The suggested answers are like "yes", "No", etc.  Leave this
as undef or "" to run a validator without an answer.

The validators are one of:

    undef             Entry is compared to the suggested answer, if defined
    'foo'             Answer must equal 'foo' (case sensitive)
    qr//              Answer must match the indicated regexp
    sub {...}, \&foo  The subroutine will validate.

Validation subroutines must return TRUE for valid input, FALSE for invalid
input but without a message, or die "...\n" with an error message for the
user if the input is not valid.  If no validators pass, an error message
will be printed and the user will be reprompted.  If multiple code
reference validators fail with different error messages, then these
will all be printed.

The answer to be validated is placed in $_ when calling a code ref.

=cut

sub _trim {
   ( @_ ? $_[0] : $_ ) =~ s/\A[\r\n\s]*(.*?)[\r\n\s]*\z/$1/s
       or warn "UGH '$_'";
}

sub ask {
   my VCP::UI::Text $self = shift;
   my ( $description, $prompt, $answer_key ) = @_;

   ## take a copy so we don't modify the original
   ## Throw away invisible possible answers.
   my @suggested_answers = grep defined, map $_->[0], @$answer_key;

   _trim
      for grep defined, $description, $prompt, @suggested_answers;

   $prompt = $self->build_prompt( $prompt, \@suggested_answers );

   my $try_count = 0;

   while ( 1 ) {
      $self->output( $try_count % 10 ? undef : $description, $prompt );

      my $answer = $self->input;

      _trim $answer;

      my @results = eval { $self->validate( $answer, $answer_key ) };

      return @results if @results > 1;

      warn @results ? "Invalid input\n" : $@;
   }
   continue {
      ++$try_count;
   }
}

=item input

    my $line = $text_ui->input;

Gets the user's input with or without surrounding whitespace and newline.

=cut

sub input {
   my VCP::UI::Text $self = shift;
   return scalar <STDIN>;
}

=item output

    $text_ui->output( $description, $prompt );

Outputs the parameters to the user; defaults to print()ing it with
stdout buffering off.

$description will be undef after the first call until ask() decides that
the user needs to see it again.

=cut

sub output {
   my VCP::UI::Text $self = shift;
   my ( $description, $prompt ) = @_;

   local $| = 1;

   if ( defined $description ) {
      $description =~ s/^/  /mg;
      print "\n$description\n\n";
   }

   print $prompt, " ";
}


=item build_prompt

    $text_ui->build_prompt( $prompt, \@suggested_answers );

Assembed $prompt and possibly the strings in \@suggested_answers in to
a single string fit for a user.

=cut

sub build_prompt {
   my VCP::UI::Text $self = shift;
   my ( $prompt, $suggested_answers ) = @_;

   my @s = grep length, @$suggested_answers;

   return join "",
      $prompt,
      @s
          ? ( " (", join( ",", @s ), ")" )
          : (),
      "?";
}

=item validate

    $text_ui->validate( $answer, $answer_key );

Returns a two element list ( $answer, $matching_answer_key_entry ) or
dies with an error message.

=cut

sub validate {
   my VCP::UI::Text $self = shift;
   my ( $answer, $answer_key ) = @_;

   my @msgs;

   for my $entry ( @$answer_key ) {
      debug "checking '$answer' against $entry->[1]" if debugging;
      return ( $answer, $entry )
         if ( ! defined $entry->[1]
               && ( ! defined $entry->[0]
                  || $answer eq $entry->[0]
               )
            )
            || ( ref $entry->[1] eq ""       && $answer eq $entry->[1] )
            || ( ref $entry->[1] eq "Regexp" && $answer =~ $entry->[1] )
            || ( ref $entry->[1] eq "CODE"  
                  && do {
                     local $_ = $answer;
                     my $ok = eval { $entry->[1]->() || 0 };
                     push @msgs, $@ unless defined $ok;
                     $ok;
                  }
               );
   }

   die join "", @msgs if @msgs;

   return 0;
}

sub run {
    my VCP::UI::Text $self = shift;

    my $m = VCP::UIMachines->new;
    $m->run( $self );
}

=back

=head1 COPYRIGHT

Copyright 2000, Perforce Software, Inc.  All Rights Reserved.

This module and the VCP::UI::Text package are licensed according to the terms given in
the file LICENSE accompanying this distribution, a copy of which is included in
L<vcp>.

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=cut

1
