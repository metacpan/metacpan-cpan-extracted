package NcFTPd::Log::Parse::Base;

use strict;
use warnings;

use IO::File;
use Carp;

my @TRANSFER_STATUSES = qw{OK ABOR INCOMPLETE PERM NOENT ERROR};
my %COMMON_REGEX = (
    time     => '\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2}(?:\.\d{1,3})?', # Date and time, optional millisecond precision
    process  => '\#u\d+|\([a-z]+\)',
    decimal  => '\d+(?:\.\d+)?',
    session  => '[+/0-9A-Za-z]+',
    status   => join '|', @TRANSFER_STATUSES
);

sub new
{
    my ($class, $file, %options) = @_;

    croak "usage: $class->new(\$file [, \%options ])" unless $file;
    croak "$file is a directory" if -d $file;  # On some platforms IO::File will gladly open a directory
    croak 'filter must be a CODE ref' if defined $options{filter} && ref $options{filter} ne 'CODE';

    my $log = IO::File->new($file, '<') || croak "Error opening file $file: $!";

    bless {
	log    => $log,
	error  => '',
	filter => $options{filter} || sub { 1 },
	expand => $options{expand}
    }, $class;
}

sub next
{
  my $self = shift;
  my $entry;

  while($entry = $self->_next_entry) {
    local $_ = $entry;
    last if $self->{filter}->();
  }

  $entry;
}

sub error
{
    (shift)->{error}
}

sub _next_entry
{
  my $self = shift;
  $self->{error} = '';

  my $line = $self->_next_line or return;
  my $entry = $self->_parse_line($line);

  # Don't squash an error message set by a subclass
  $self->{error} = 'Cannot parse line: unrecognized format'
    unless $entry or $self->{error};

  $entry;
}

sub _next_line
{
    my $self = shift;
    my $log  = $self->{log};
    my $line = $log->getline;

    $self->{error} = "Error reading log file: $!"
      unless defined $line or $log->eof;

    $line;
}

sub _parse_line
{
    my ($self, $line) = @_;

    return unless $line and
		  $line =~ m{^($COMMON_REGEX{time})\s($COMMON_REGEX{process})\s+\|\s(.+)};
    my $time = $1;
    my $pid  = $2;
    my $entry = $self->_parse_entry($3);

    if($entry) {
	$entry->{time}    = $time;
	$entry->{process} = $pid;

	if($self->{expand}) {
	    my @fields = ref($self->{expand}) eq 'ARRAY'
		? @{$self->{expand}}
		: keys %$entry;

	    for my $field (@fields) {
		$entry->{$field} = $self->_expand_field($field, $entry->{$field});
	    }
	}
    }

    $entry;
}

sub _expand_field
{
    my ($self, $name, $value) = @_;

    # Default behavior, subclasses might not expand anything
    $value;
}

sub _transfer_statuses
{
    @TRANSFER_STATUSES;
}

sub _common_regex
{
    %COMMON_REGEX;
}

sub _parse_entry
{
    croak __PACKAGE__, '->_parse_entry is abstract';
}

1;
