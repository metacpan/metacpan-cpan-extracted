package Net::Gnats::PR;
use 5.010_000;
use utf8;
use strictures;

BEGIN {
  $Net::Gnats::PR::VERSION = '0.22';
}
use vars qw($VERSION);

use Carp;
use MIME::Base64;
use Net::Gnats::Constants qw(FROM_FIELD REPLYTO_FIELD TO_FIELD CC_FIELD SUBJECT_FIELD SENDPR_VER_FIELD NOTIFY_FIELD);

use Net::Gnats::FieldInstance;
use Net::Gnats::Attachment;

$| = 1;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( serialize deserialize parse_line);

# TODO: These came from gnatsweb.pl for the parsepr and unparsepr routines.
# should be done a better way?
my $UNFORMATTED_FIELD = 'Unformatted';
my $SYNOPSIS_FIELD = 'Synopsis';
my $ORIGINATOR_FIELD = 'Originator';
my $attachment_delimiter = "----gnatsweb-attachment----\n";
my $SENDINCLUDE  = 1;   # whether the send command should include the field
our $REVISION = '$Id: PR.pm,v 1.8 2014/08/16 23:40:56 thacker Exp $'; #'

#******************************************************************************
# Sub: new
# Description: Constructor
# Args: hash (parameter list)
# Returns: self
#******************************************************************************

=head1 CONSTRUCTOR

=head2 new

The new() constructor does not expect any options.  However, this may
change in the future when PR initialization is moved from Net::Gnats
to this class.

 my $pr = Net::Gnats::PR->new

=cut

sub new {
  my ( $class, %options ) = @_;
  my $self = bless {}, $class;
  $self->{number} = undef;
  $self->{fieldlist} = [];
  return $self if not %options;
  return $self;
}


=head1 ACCESSORS

=head2 asHash

Returns the PR formatted as a hash.  The returned hash contains field
names as keys, and the corresponding field values as hash values.

CHANGE ALERT: This method now returns all FieldInstance objects.

DEPRECATION NOTICE: This accessor will be removed in the near future.

=cut

sub asHash {
    my ( $self ) = shift;
    return %{$self->{fields}} if defined($self->{fields}); #XXX Deep copy?
    return undef;
}

=head2 asString

Returns the PR object formatted as a Gnats recongizable string.  The
result is suitable for submitting to Gnats.

 my $serialized_pr = $pr->asString;

DEPRECATION NOTICE: This accessor will be removed in the near future.
Instead, use:

 my $serialized_pr = $pr->serialize;

=cut

sub asString {
  my $self = shift;
  return Net::Gnats::PR->serialize($self,
                                   Net::Gnats->current_session->username);
}

=head2 getField

Returns the string value of a PR field.

 $pr->getField('field');

DEPRECATION NOTICE: this will be deprecated in the near future.  Use instead:

 $r->get_field('field')->value

=cut

sub getField {
    my ( $self, $field ) = @_;
    return $self->{fields}->{$field}->value;
}

=head2 getKeys

Returns the list of PR fields contained in the object.

=cut

sub getKeys {
    return keys %{shift->{fields}};
}

=head2 getNumber

Returns the gnats PR number. In previous versions of gnatsperl the
Number field was explicitly known to Net::Gnats::PR.  This method
remains for backwards compatibility.

DEPRECATION NOTICE: this will be deprecated in the near future.  Use
instead:

 $r->get_field('Number')->value

=cut

sub getNumber {
  return shift->{fields}->{'Number'}->value;
}

=head2 add_field

Adds a field instance to the fieldlist of a Nets::Gnats::PR object for fields that are not header fields.

=cut


sub add_field {
  my ($self, $field) = @_;
  $self->{fields}->{$field->name} = $field;
  # manage the list of fields in order only if it's not a header field.
  unless (_is_header_field($field->name)) {
    push @{ $self->{fieldlist} }, $field->name;
  }
  return;
}

=head2 get_field

Returns a field instance of an Nets::Gnats::PR object if field instance is defined.

=cut

sub get_field {
  my ($self, $fieldname) = @_;
  return $self->{fields}->{$fieldname} if defined $self->{fields}->{$fieldname};
  return undef;
}

=head2 get_field_from

Return an anonymous array of Nets::Gnats::PR object fields instances from a word part match.

=cut


sub get_field_from {
  my ( $self, $fieldname) = @_;
  my $result = [];

  foreach my $field ( sort keys %{ $self->{fields} } ) {
    push @$result, $field if $field =~ qr/^$fieldname/;
  }

  return $result;
}

=head2 replaceField

Sets a new value for an existing field.

If the field requires a Change Reason, and the field does not exist in
the PR, then the FieldInstance for the Change Reason is created.

Returns 0 if the field does not exist.

Returns 0 if the field requires a changeReason, but one was not provided.

Returns 0 if the change did not occur successfully.

Returns 1 if the field is set and flushed to Gnats.

=cut

sub replaceField {
  my ($self, $name, $value, $reason_value) = @_;
  return 0 if not defined $self->get_field($name);
  return 0 if not $self->setField($name, $value, $reason_value);

  my $f = $self->get_field($name);

  if ($f->schema->requires_change_reason) {
    return Net::Gnats
        ->current_session
        ->issue(Net::Gnats::Command->repl(
          pr_number => $self->get_field('Number')->value,
          field => $f,
          field_change_reason => $self->get_field($name . '-Changed-Why')))
        ->is_ok;
  }
  return Net::Gnats
    ->current_session
    ->issue(Net::Gnats::Command->repl(pr_number => $self->get_field('Number')->value,
                                      field => $f))->is_ok;
}


=head2 setField

Sets a Gnats field value.  Expects two arguments: the field name
followed by the field value.  If the field requires a change reason,
provide it as a third argument.

=cut

sub setField {
  my ($self, $name, $value, $reason_value) = @_;
  return 0 if not defined $self->get_field($name);
  my $f = $self->get_field($name);

  if ($f->schema->requires_change_reason) {
    return 0 if (not defined $reason_value);
    my $cr_instance =
      Net::Gnats::FieldInstance->new(
        schema => $f->schema->change_reason_field($name));
    $cr_instance->value($reason_value);
    $self->add_field($cr_instance);
  }

  $f->value($value);
  return 1;
}

=head2 submit

Submit this PR to Gnats.  It uses the currently active session to
perform the submit.

 $pr = $pr->submit;

After a successful submit, the PR with the PR Number is returned.

 say 'My new number is: ' . $pr->get_field('Number')->value;

By default, submit will not send a PR which already has a PR Number.
If your intent is to create a new PR based on this one, use the force
option (may change in the future).  This is useful when a series of
similar PRs need to be submitted.

 $pr = $pr->submit(1);

If the PR submission based on force was not successful, the PR will
return with the same PR Number.

=cut

sub submit {
  my ($self, $force) = @_;

  return $self if defined $self->get_field('Number') and not defined $force;

  my $command = Net::Gnats
      ->current_session
      ->issue(Net::Gnats::Command->subm(pr => $self));
  return $self if $command->is_ok == 0;

  # the number is in the second response item.  This should probably be in SUBM.pm.
  my $number = @{ $command->response->as_list }[1];
  if ( $self->get_field('Number') ) {
    $self->get_field('Number')->value($number);
  }
  else {
    my $field_schema = Net::Gnats->current_session->schema->field('Number');
    $self->add_field(Net::Gnats::FieldInstance->new( name => 'Number',
                                                     value => $number,
                                                     schema => $field_schema ));
  }
  return $self;
}

=head2 split_csl

 Split comma-separated list.
 Commas in quotes are not separators!

=cut

sub split_csl {
  my ($list) = @_;

  # Substitute commas in quotes with \002.
  while ($list =~ m~"([^"]*)"~g)
  {
    my $pos = pos($list);
    my $str = $1;
    $str =~ s~,~\002~g;
    $list =~ s~"[^"]*"~"$str"~;
		 pos($list) = $pos;
  }

  my @res;
  foreach my $person (split(/\s*,\s*/, $list))
  {
    $person =~ s/\002/,/g;
    push(@res, $person) if $person;
  }
  return @res;
}

=head2  fix_email_addrs

  Trim email addresses as they appear in an email From or Reply-To
  header into a comma separated list of just the addresses.

  Delete everything inside ()'s and outside <>'s, inclusive.

=cut

sub fix_email_addrs
{
  my $addrs = shift;
  my @addrs = split_csl ($addrs);
  my @trimmed_addrs;
  my $addr;
  foreach $addr (@addrs)
  {
    $addr =~ s/\(.*\)//;
    $addr =~ s/.*<(.*)>.*/$1/;
    $addr =~ s/^\s+//;
    $addr =~ s/\s+$//;
    push(@trimmed_addrs, $addr);
  }
  $addrs = join(', ', @trimmed_addrs);
  $addrs;
}

=head2 parse_line

Breaks down a Gnats query result.

=cut

sub parse_line {
  my ( $line, $known ) = @_;
  my $result = [];

  if (_is_header_line($line)) {
    my @found = $line =~ /^([\w\-\{\}]+):\s*(.*)$/;
    return \@found;
  }

  my @found = $line =~ /^>([\w\-\{\d\}]+):\s*(.*)$/;

  if ( not defined $found[0] ) {
    @{ $result }[1] = $line;
    return $result;
  }

  my $schemaname = _schema_fieldname($found[0]);

  my $schema_found = grep { $_ eq $schemaname } @{ $known };

  if ( $schema_found == 0 ) {
    @{ $result }[1] = $line;
    return $result;
  }

  @{ $result }[0] =  $found[0];
  $found[1] =~ s/\s+$//;
  @{ $result }[1] = $found[1];
  return $result;
}

sub _schema_fieldname {
  my ( $fieldname ) = @_;
  my $schemaname = $fieldname;
  $schemaname =~ s/{\d+}$//;
  return $schemaname;
}

sub _schema_fieldinstance {
  my ( $self, $fieldname ) = @_;
  return Net::Gnats->current_session
                   ->schema
                   ->field(_schema_fieldname($fieldname))
                   ->instance( for_name => $fieldname );
}

sub _clean {
  my ( $self, $line ) = @_;
  if ( not defined $line ) { return; }

  $line =~ s/\r|\n//gsm;
#  $line =~ s/^[.][.]/./gsm;
  return $line;
}

sub _is_header_line {
  my ( $line ) = @_;
  return 1 if $line =~ /^${\(FROM_FIELD)}:/;
  return 1 if $line =~ /^${\(REPLYTO_FIELD)}:/;
  return 1 if $line =~ /^${\(TO_FIELD)}:/;
  return 1 if $line =~ /^${\(CC_FIELD)}:/;
  return 1 if $line =~ /^${\(SUBJECT_FIELD)}:/;
  return 1 if $line =~ /^${\(SENDPR_VER_FIELD)}:/;
  return 1 if $line =~ /^${\(NOTIFY_FIELD)}:/;
  return 0;
}

sub _is_header_field {
  my ( $name ) = @_;
  return 1 if $name eq FROM_FIELD;
  return 1 if $name eq REPLYTO_FIELD;
  return 1 if $name eq TO_FIELD;
  return 1 if $name eq CC_FIELD;
  return 1 if $name eq SUBJECT_FIELD;
  return 1 if $name eq SENDPR_VER_FIELD;
  return 1 if $name eq NOTIFY_FIELD;
  return 0;
}

sub _is_first_line {
  my ( $line ) = @_;
  return 1 if $line =~ /^${\(FROM_FIELD)}:/;
  return 0;
}

=head2 deserialize

Deserializes a PR from Gnats and returns a hydrated PR.

 my $pr = Net::Gnats::PR->deserialize(raw => $c->response->raw,
                                      schema => $s->schema);

=cut

sub setFromString {
  my ($self, $data) = @_;
  # expects just a block of text, so we need to break it out
  $data =~ s/\r//g;
  my @lines = split /\n/, $data;
  return Net::Gnats::PR->deserialize(data => \@lines,
                                     schema => Net::Gnats->current_session->schema);
}

sub deserialize {
  my ($self, %options)  = @_;

  my $data = $options{data};
  my $schema = $options{schema};

  my $pr = Net::Gnats::PR->new();
  my $field;

  foreach my $line (@{$options{data}}) {
    $line = $self->_clean($line);
    next if $line eq '' or $line eq '.';

    my ( $name, $content ) = @{ parse_line( $line, $schema->fields ) };
    next if not defined $name and $content eq '';

    if ( defined $name and _is_first_line( $name . ':') ) {
      # put last PR in array, start new PR
    }

    if ( defined $name and _is_header_line( $name . ':' ) ) {
      $pr->add_field(
        Net::Gnats::FieldInstance->new( name => $name,
                                        value => $content,
                                        schema => $schema->field($name)));
      next;
    }

    # known header field found, save.
    if ( defined $name ) {
      $field = $self->_schema_fieldinstance($name);
      $field->value($content);
      $pr->add_field($field);
    }
    # known header field not found, append to last.
    else {
      $field->value( $field->value . "\n" . $content );
      $pr->setField($field);
    }
  }


  $pr->get_field('Reply-To')->value($pr->get_field('From'))
    if not defined $pr->get_field('Reply-To')->value;

  # create X-GNATS-Notify if we did not receive it.
  if (not defined $pr->get_field('X-GNATS-Notify')) {
      $pr->add_field(Net::Gnats::FieldInstance->new( name => 'X-GNATS-Notify',
                                                     value => '' ));
  }

  # Create an Unformatted field if it doesn't come in from Gnats.
  if (not $pr->get_field($UNFORMATTED_FIELD)) {
    $pr->add_field(Net::Gnats::FieldInstance->new( name => $UNFORMATTED_FIELD,
                                                   value => '' ));
  }

  my @attachments = split /$attachment_delimiter/,
                          $pr->get_field($UNFORMATTED_FIELD)->value;

  return $pr if scalar ( @attachments ) == 0;

  # First element is any random text which precedes delimited attachments.
  $pr->get_field($UNFORMATTED_FIELD)->value( shift @attachments );

  foreach my $attachment (@attachments) {
    # encoded PR always has a space in front of it
    push @{$pr->{attachments}},
         Net::Gnats::Attachment->new( payload => $attachment );
  }

  return $pr;
}

# unparse -
#     Turn PR fields hash into a multi-line string.
#
#     The $purpose arg controls how things are done.  The possible values
#     are:
#         'gnatsd'  - PR will be filed using gnatsd; proper '.' escaping done
#         'send'    - PR will be field using gnatsd, and is an initial PR.
#         'test'    - we're being called from the regression tests

# What is the user from the session?  Need to have user passed for originator.
sub serialize {
  my ( $self, $pr, $user ) = @_;
  my $purpose ||= 'gnatsd';
  $user ||= 'bugs';
  my ( $tmp, $text );
  my $debug = 0;

  # First create or reconstruct the Unformatted field containing the
  # attachments, if any.
  my %fields = %{$pr->{fields}};

  #if (not defined $pr->get_field('Unformatted')) {
  #  $pr->add_field(Net::Gnats::FieldInstance->new( name => $UNFORMATTED_FIELD,
  #                                                 value => '',
  #                                                 schema => ));
  #}

  # deal with attachment later
  # my $array_ref = $fields{'attachments'};
  # foreach my $hash_ref (@$array_ref) {
  #   my $attachment_data = $$hash_ref{'original_attachment'};
  #   # Deleted attachments leave empty hashes behind.
  #   next unless defined($attachment_data);
  #   $fields{$UNFORMATTED_FIELD} .= $attachment_delimiter . $attachment_data . "\n";
  # }
  # warn "unparsepr 2 =>$fields{$UNFORMATTED_FIELD}<=\n" if $debug;

  # Headers are necessary because Gnats expects it.
  $text .= FROM_FIELD . ': '     . $user . "\n";
  $text .= REPLYTO_FIELD . ': ' . $user . "\n";
  $text .= TO_FIELD . ': bugs' . "\n";
  $text .= CC_FIELD . ': ' . "\n";
  $text .= SUBJECT_FIELD . ': ' . $pr->get_field($SYNOPSIS_FIELD)->value . "\n";
  $text .= SENDPR_VER_FIELD . ': Net::Gnats ' . $Net::Gnats::VERSION . "\n";
  $text .= "\n";

  foreach my $fn (@{ $pr->{fieldlist} } ) {
    my $field = $pr->get_field($fn);
    #next if /^.$/;
    #next if (not defined($fields{$_})); # Don't send fields that aren't defined.
    # Do include Unformatted field in 'send' operation, even though
    # it's excluded.  We need it to hold the file attachment.
    # XXX ??? !!! FIXME

#    if(($purpose eq 'send')
#       && (! ($self->{__gnatsObj}->getFieldTypeInfo ($_, 'flags') & $SENDINCLUDE))
#       && ($_ ne $UNFORMATTED_FIELD))
#    {
#      next;
#    }

    if ($fn eq 'Unformatted') {
      next;
    }
#    $fields{$_} ||= ''; # Default to empty
    if ( $field->schema->type eq 'MultiText' ) {
      $tmp = $field->value;
      $tmp =~ s/\r//;
      $tmp =~ s/^[.]/../gm;
      chomp($tmp);
      $text .= sprintf(">%s:\n%s\n", $field->name, $tmp);
    }
    else {
      # Format string derived from gnats/pr.c.
      $text .= sprintf("%-16s %s\n", '>' . $field->name . ':', $field->value);
    }

    if ($pr->get_field($field->name . '-Changed-Why')) {
      # Lines which begin with a '.' need to be escaped by another '.'
      # if we're feeding it to gnatsd.
      $tmp = $pr->get_field($_ . '-Changed-Why')->value;
      $tmp =~ s/^[.]/../gm;
      $text .= sprintf(">%s-Changed-Why:\n%s\n", $field->name, $tmp);
    }
  }
  $text =~ s/\r//;
  return $text;
}


# preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Net::Gnats::PR - Represents a Gnats PR.

=head1 SYNOPSIS

  use Net::Gnats;
  my $g = Net::Gnats->new();
  $g->connect();
  my @dbNames = $g->getDBNames();
  $g->login("default","somedeveloper","password");
  my $PRtwo = $g->getPRByNumber(2);
  print $PRtwo->asString();
  my $newPR = Net::Gnats::PR->new();
  $newPR->setField("Submitter-Id","developer");
  $g->submitPR($newPR);
  $g->disconnect();


=head1 DESCRIPTION

Net::Gnats::PR models a GNU Gnats PR (Problem Report).  The module allows
proper formatting and parsing of PRs through an object oriented interface.

The current version of Net::Gnats (as well as related information) is
available at http://gnatsperl.sourceforge.net/

=head1 COMMON TASKS


=head2 CREATING A NEW PR

The Net::Gnats::PR object acts as a container object to store information
about a PR (new or otherwise).  A new PR is submitted to gnatsperl by
constructing a PR object.

  my $newPR = Net::Gnats::PR->new();
  $newPR->setField("Submitter-Id","developer");
  $newPR->setField("Originator","Doctor Wifflechumps");
  $newPR->setField("Organization","GNU");
  $newPR->setField("Synopsis","Some bug from perlgnats");
  $newPR->setField("Confidential","no");
  $newPR->setField("Severity","serious");
  $newPR->setField("Priority","low");
  $newPR->setField("Category","gnatsperl");
  $newPR->setField("Class","sw-bug");
  $newPR->setField("Description","Something terrible happened");
  $newPR->setField("How-To-Repeat","Like this.  Like this.");
  $newPR->setField("Fix","Who knows");

Obviously, fields are dependent on a specific gnats installation,
since Gnats administrators can rename fields and add constraints.


=head2 CREATING A NEW PR OBJECT FROM A PREFORMATTED PR STRING

Instead of setting each field of the PR individually, the
setFromString() method is available.  The string that is passed to it
must be formatted in the way Gnats handles the PRs (i.e. the '>Field:
Value' format.  You can see this more clearly by looking at the PR
files of your Gnats installation).  This is useful when handling a
Gnats email submission ($newPR->setFromString($email)) or when reading
a PR file directly from the database.

=head1 BUGS

Bug reports are very welcome.  Please submit to the project page
(noted below).


=head1 AUTHOR

Mike Hoolehan, <lt>mike@sycamore.us<gt>
Project hosted at sourceforge, at http://gnatsperl.sourceforge.net



=head1 COPYRIGHT

Copyright (c) 1997-2001, Mike Hoolehan. All Rights Reserved.
This module is free software. It may be used, redistributed,
and/or modified under the same terms as Perl itself.


=cut
