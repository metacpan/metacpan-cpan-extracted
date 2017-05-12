package Runops::Recorder::Reader;

use strict;
use warnings;

use Fcntl qw(SEEK_CUR SEEK_END SEEK_SET);
use File::Spec;

use accessors::ro qw(identifiers_fh data_fh identifiers handler skip_keyframes);

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT = qw();
our @EXPORT_OK = qw(
    KEYFRAME SWITCH_FILE NEXT_STATEMENT DIE ENTER_SUB KEYFRAME_TZ
);

our %EXPORT_TAGS = (
    events => [@EXPORT_OK]
);

use constant {
    KEYFRAME        => 0,
    SWITCH_FILE     => 1,
    NEXT_STATEMENT  => 2,
    DIE             => 3,
    ENTER_SUB       => 4,
    KEYFRAME_TZ     => 5,
    PADSV           => 6,
    LEAVE_SUB       => 7,
    KEYFRAME_TZ_U   => 8,
};

sub new {
    my ($pkg, $path, $opts) = @_;
    
    $opts //= {};
    
    my $file = "main.data";
    if (-f $path) {
        (undef, $path, $file) = File::Spec->splitpath($path);
    }
    
    open my $data_fh, "<", File::Spec->catfile($path, $file) 
        or die "Can't read $path/$file because of: $!";
    open my $identifiers_fh, "<", File::Spec->catfile($path, "main.identifiers") 
        or die "Can't read $path/main.identifiers because of: $!";
    
    my $handler;
    if ($opts->{handler}) {
        $handler = _make_class_handler($opts->{handler});
    }
    elsif ($opts->{handlers}) {
        $handler = _make_callback_handler($opts->{handlers});
    }
    
    # This means that read_next will ignore keyframe commands
    my $skip_keyframes = $opts->{skip_keyframes} // 1;
    
    my $self = bless { 
        data_fh => $data_fh, 
        identifiers_fh => $identifiers_fh,
        identifiers => {},
        handler => $handler,
        skip_keyframes => $skip_keyframes,
    }, $pkg;

    $self->find_next_keyframe;
    $self->read_identifiers;
    
    return $self;
}

{
    my %CMD_TO_NAME = (
        0 => 'on_keyframe',
        1 => 'on_switch_file',
        2 => 'on_next_statement',
        3 => 'on_die',
        4 => 'on_enter_sub',
        5 => 'on_keyframe_timestamp',
        6 => 'on_padsv',
        7 => 'on_leave_sub',
        8 => 'on_keyframe_timestamp_usec',
    );
    
    my %CMD_DATA_TRANSFORMER = (
        0 => sub {},
        1 => sub { my ($file_no) = unpack("L", $_[0]); return ($file_no, $_[1]->get_identifier($file_no)) },
        2 => sub { my ($line_no) = unpack("L", $_[0]); return ($line_no) },
        3 => sub {},
        4 => sub { my ($identifier_no) = unpack("L", $_[0]); return ($identifier_no, $_[1]->get_identifier($identifier_no)) },
        5 => sub { my ($sec) = unpack("L", $_[0]); return ($sec); },
        6 => sub { my ($identifier_no) = unpack("L", $_[0]); return ($identifier_no, $_[1]->get_identifier($identifier_no)) },
        7 => sub { my ($identifier_no) = unpack("L", $_[0]); return ($identifier_no, $_[1]->get_identifier($identifier_no)) },
        8 => sub { my ($usec) = unpack("L", $_[0]); return ($usec); },
    );
    
    sub _make_class_handler {
        my ($target) = @_;
    
        my $handler = sub {
            my ($cmd, $data, $reader) = @_;
            my $cb = $target->can($CMD_TO_NAME{$cmd});
            $cb->($target, $CMD_DATA_TRANSFORMER{$cmd}->($data, $reader), $reader) if $cb;
            1;
        };
    
        return $handler;
    }
    
    sub _make_callback_handler {
        my ($target) = @_;
        
        my %callbacks = map { 
            my $name = $CMD_TO_NAME{$_};
            ($_, exists $target->{$name} ? $target->{$name} : sub {})
        } keys %CMD_TO_NAME;
        
        my $handler = sub {
            my ($cmd, $data, $reader) = @_;
            $callbacks{$cmd}->($CMD_DATA_TRANSFORMER{$cmd}->($data, $reader), $reader);
        };
    }
    
    sub decode {
        my ($self, $cmd, $data) = @_;
        return $CMD_DATA_TRANSFORMER{$cmd}->($data, $self);
    }
}

sub read_identifiers {
    my $self = shift;
    
    my $identifiers_fh = $self->identifiers_fh;
    
    # Reset that we're not at EOF
    $identifiers_fh->seek(0, SEEK_CUR);
    while (<$identifiers_fh>) {
        chomp;
        my ($id, $name) = split /:/, $_, 2;
        $self->{identifiers}->{$id} = $name;
    }
}

sub get_identifier {
    my ($self, $id) = @_;
    $self->read_identifiers();
    return $self->identifiers->{$id};
}

my @read_extra = (
    0, 
    0, 
    0, 
    0,
    0,
    0,
    0,
    0, 
);

sub read_next {
    my $self = shift;
    
    # Assume the file is synced
    my $buff;
    my $read = $self->data_fh->read($buff, 5);
    if ($read == 5) {
        # decode
        my ($cmd, $data) = unpack("Ca*", $buff);
        # This is a keyframe, return next instead
        return $self->read_next if $cmd == 0 && $self->skip_keyframes;
        if ($read_extra[$cmd]) {
            $self->data_fh->read($buff, $read_extra[$cmd]);
            $data .= $buff;
        }
        $self->handler->($cmd, $data, $self) if $self->handler;
        return ($cmd, $data);
    }
    elsif ($read) {
        $self->data_fh->seek(-$read, SEEK_CUR);
    }
    
    return;
}

sub read_all {
    my $self = shift;
    while ($self->read_next()) {
        # nop
    }
}

sub skip_until {
    my ($self, $target_cmd) = @_;
    
    my ($cmd, $data);
    do {
        ($cmd, $data) = $self->read_next();
        return unless defined $cmd;
    }
    until ($cmd == $target_cmd);

    $self->data_fh->seek(-5, SEEK_CUR);
}

sub find_next_keyframe {
    my $self = shift;
    
    my $data_fh = $self->data_fh;
    
    my $read_keyframe = 0;

    # TODO: also handle tail mode
    while ($read_keyframe < 5) {
        my $next = $data_fh->getc;
        last unless defined $next;
        $read_keyframe = 0, next if ord($next) != 0;
        $read_keyframe++;        
    }
    
    $data_fh->seek(-5, SEEK_CUR);

    1;
}

1;
__END__
=pod

=head1 NAME

Runops::Recorder::Reader - A class which can read the recording files

=head1 DESCRIPTION

Instances of this class reads a recording. It can work both as a stream-based 
reader where you ask for the next entry or as a event generator that calls 
your handlers for each type of item it reads.

=head1 SYNOPSIS

  # main script
  use Runops::Recorder::Reader;
  
  my $reader = Runops::Recorder::Reader->read("my-recording", { 
    handler => "MyRecordingHandler",
  });
  
  $reader->read();
  
  # MyRecordingHandler.pm
  package MyRecordingHandler;
  
  sub on_switch_file {
    my ($self, $id, $path) = @_;
    print "Now in file: $path\n";
  }
  
  sub on_next_statement {
    my ($self, $line_no) = @_;
    print "Executing line: $line_no\n";
  }
  
  1;
  
=head1 INTERFACE

=head2 CLASS METHODS

=over 4

=item new ( $path [, \%opts ] )

Creates a new instance of this class. Takes I<$path> which must be a path to a 
recording and an optional hashref with options. Valid options are

=over 4

=item handler

An package name or instance of a class which on which methods will be called when 
events occur. See L</EVENTS>

=item handlers

A hashref with event/callback pairs that are called when events occur. See L</EVENTS>

=item skip_keyframes

An boolean that indicates wheter keyframes should be skipped or not - ie, not 
generate an event or be returned from C<read_next>

=back

=back

=head2 INSTANCE METHODS

=over 4

=item read_next

Reads the next entry in the recording and returns a list with the numeric event and 
its decoded contents. See L</EVENTS>

=item read_all

Reads thru the recording generating events.

=item read_identifiers

Reads the identifiers, files etc that we saw during recording

=item skip_until ( $event )

Reads all events until the next of of type I<$event> occurs.

=item get_identifier ( $id ) 

Returns the identifier with the given I<$id>.

=item find_next_keyframe 

Searches for the next keyframe. This is to be used in the future when one can 
tail recordings being generated.

=item decode ( $event, $data )

Decodes the blob I<$data> according to the rules for the specific event and returns a list of values.

=back

=head1 EVENTS

The following events may occur in the recording. They can be returned by C<read_next> or cause a 
callback/method to be invoked.

The kind of events that can happen. Numeric code, constant and callback name within parenthesis for each item.

=over 4

=item Keyframe (0, C<KEYFRAME>, C<on_keyframe>)

A keyframe is an entry that we can wait for in tailing mode to know where we can start reading. These are 
inserted every 1024 events or so. No data/arguments.

=item Switch file (1, C<SWITCH_FILE>, C<on_switch_file>)

Happens when we execute a statement in another source file than the current one. No arguments.

=item Next statment (2, C<NEXT_STATEMENT>, C<on_next_statement>)

A statement has been executed. Data/argument is C<line number>.

=item Die (3, C<DIE>, C<on_die>)

The program threw an exception using C<die>. No data/arguments.

=item Enter subroutine (4, C<ENTER_SUB>, C<on_enter_sub>)

A subroutine was called. Data/arguments are C<identifier id> and C<identifier>.

=back

=head1 EXPORT

Nothing is exported by default. The tag I<events> export the event constants listed about in L</EVENTS>.

=cut


