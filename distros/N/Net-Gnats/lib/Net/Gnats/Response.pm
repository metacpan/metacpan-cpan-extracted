package Net::Gnats::Response;
use v5.10.00;
use strictures;
BEGIN {
  $Net::Gnats::Response::VERSION = '0.22';
}
use vars qw($VERSION);

use Net::Gnats qw(verbose_level);
use Net::Gnats::Constants qw(LF CODE_TEXT_READY CODE_PR_READY);

# {
#   my ($code, $raw, $type);

# # internally manage type
#   my $set_type = sub { $type = shift };
#   my $set_code = sub {
#     my $value = shift;
#     $code = -1 if $value !~ /\d\d\d/;
#     $code = $value;
#   };
#   my $set_raw = sub {
#     $raw = shift;
#   };
# }

=head1 NAME

Net::Gnats::Response - A Gnats payload class.

=head1 DESCRIPTION

For dealing with raw responses and error codes returned by
Gnatsd. Enables an easier payload method.

=head1 VERSION

0.15

=head1 SYNOPSIS

  use Net::Gnats::Reponse;

  # Compose payload via constructor
  my $response = Net::Gnats::Response->new({ raw => $data,
                                             code => $code});

  # Compose disparately
  my $response = Net::Gnats::Response->new;
  $response->raw($data);
  $response->code($code);


=head1 CONSTRUCTORS

There are two types of constructors available.

The first enables a 'shell' response which carries children responses.
The shell response does not require initialization data.

The second enables the capturing a full response. When initializing
the response, the code and raw data must be passed to initialization.

=head2 new

Constructor for the shell Response object.

 my $r = new(code => $code, raw => $raw)

=cut

sub new {
  my ($class, %opt) = @_;
  my $c = { trace => 0,
            delim => ' ',
            is_finished => 0,
            content => [],
            has_more => 0,
            type => 0,
          };
  my $self = bless $c, $class;

  if (%opt) {
    $c->{type} = $opt{type} if defined $opt{type};
    $c->{code} = $opt{code} if defined $opt{code};
    if (defined $opt{raw} and ref $opt{raw} eq 'ARRAY') {
      foreach my $r (@{$opt{raw}}) {
        $c->raw($r);
      }
    }
  }

  return $self;
}

=head1 ACCESSORS

The following public accessors are available.  All accessors are
readonly because the response class expects the raw data to be
submitted during instantiation.

=head2 raw

The readonly raw accessor retrieves raw result data for this particular
response.  If this is a parent response for a single payload, then it
will return an empty anonymous array.

 my $r = Net::Gnats::Response( code => $code, raw => $raw );

=cut

sub raw {
  my ( $self, $value ) = @_;
  _trace('start raw');
  $self->{raw} = []              if not defined $self->{raw};
  push @{ $self->{raw} }, $value if defined $value;
  $self->_process_line($value)   if defined $value;
  $self->_check_finish($value)   if defined $value;
  _trace('end raw');
  return $self->{raw};
}

=head2 code

The readonly code accessor for the result code.

 my $r = Net::Gnats::Response( code => $code, raw => $raw );
 return 1 if $r->code == Net::Gnats::CODE_OK;

=cut

sub code {
  my ( $self ) = @_;
  if ( $self->{type} == 1 ) { return 1; }
  return $self->{code};
}

=head2 inner_responses

The readonly accessor for fetching child responses.

=cut

sub inner_responses {
  my ( $self ) = @_;

  $self->{inner_responses} = [] if not defined $self->{inner_responses};
  return $self->{inner_responses};
}

=head2 is_finished

The response has completed processing.  Returns 1 if processing has
completed, returns 0 otherwise.

=cut

sub is_finished {
  return shift->{is_finished};
}

sub has_more { return shift->{has_more}; }

=head2 status

Retrieve the overall status of the response.  If this response, or all child responses,
resulted positively then returns 1.  Otherwise, it returns 0.

=cut

sub status {
  my ( $self ) = @_;
  if ( $self->type == 1 ) {
    foreach ( @{ $self->inner_responses } ) {
      return 0 if $_->status == 0;
    }
    return 1;
  }
  return 0 if $self->code;
}

=head1 METHODS

=begin

=item as_list

Assumes the Gnatsd payload response is a 'list' and parses it as so.

Returns: Anonymous array of list items from this response and all
children.

=cut

sub as_list {
  my ($self) = @_;

  # get children lists
  if ( $self->{type} == 1 ) {
    my $result = [];
    for ( @{ $self->inner_responses } ) {
      push @$result, @{ $_->as_list };
    }
    return $result;
  }

  return $self->{content};
}

=item as_string

=back

=cut

sub as_string {
  my ( $self ) = @_;
  if ( $self->{type} == 1 ) {
    my $result = '';
    my @responses = @{ $self->inner_responses };
    my $last_response = pop @responses;
    for ( @responses ) {
      $result .= $_->as_string . ', ';
    }
    $result .= defined $last_response ? $last_response->as_string : '';
    return $result;
  }
  return join ( $self->{delim}, @{ $self->{content} } );
}


sub add {
  my ( $self, $response ) = @_;
  if (ref $response eq 'ARRAY') {
    push @{$self->{inner_responses}}, @{$response};
  }
  elsif ( not $response->isa('Net::Gnats::Response') ) {
    warn "you tried adding a response that's not a response! Discarded.";
    return $self;
  }
  push @{$self->{inner_responses}}, $response;
  return $self;
}

sub _check_finish {
  my ( $self, $last ) = @_;
  if ( $last eq '.' and
       ($self->code == CODE_TEXT_READY or
        $self->code == CODE_PR_READY)) {
    $self->{is_finished} = 1;
    return;
  }
  elsif ($self->has_more == 1) {
    $self->{is_finished} = 0;
  }
  elsif ($self->code != CODE_TEXT_READY and
         $self->code != CODE_PR_READY) {
    $self->{is_finished} = 1;
  }
}

sub _process_line {
  my ( $self, $raw ) = @_;
  _trace('start _process_line');
  #list
  if ( defined $self->code and
       ($self->code == CODE_TEXT_READY or
        $self->code == CODE_PR_READY)) {
    return if $raw eq '.';
    push @{ $self->{content} }, $raw;
    return;
  }

  # this is a list and code has already been processed
  #return if defined $self->code;
  my @result = $raw =~ /^(\d\d\d)([- ]?)(.*$)/sxm;
  $self->{code} = $result[0];
  $self->{has_more} = 1 if $result[1] eq '-';
  $self->{has_more} = 0 if $result[1] eq ' ';
  push @{ $self->{content} }, $result[2]
    unless ( $self->code == CODE_TEXT_READY or
             $self->code == CODE_PR_READY );
  return;
}

sub _trace {
  my ( $message ) = @_;
  return if Net::Gnats->verbose_level() != 3;
  print 'TRACE(Response): [' . $message . ']' . LF;
  return;
}

1;


=head1 INCOMPATIBILITIES

None.

=head1 SUBROUTINES/METHODS

=over

=head1 BUGS AND LIMITATIONS

None.

=head1 CONFIGURATION AND ENVIRONMENT

None.

=head1 DEPENDENCIES

None.

=head1 DIAGNOSTICS

None.

=head1 AUTHOR

Richard Elberger, riche@cpan.org

=head1 LICENSE AND COPYRIGHT

License: GPL V3

(c) 2014 Richard Elberger

=cut
